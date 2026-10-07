--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local RokValue = require(ReplicatedStorage.RokValue)
local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Tools = require(script.Tools)

export type Grant = {
	Id: string,
	PetKey: string,
	IsNew: boolean,
	Trait: string?,
	TraitValue: number?,
}

local PetService = {
	Name = "PetService",
	HeldChanged = Signal.new() :: Signal.Signal<Player>,
	Granted = Signal.new() :: Signal.Signal<Player>,
}

local services: { [string]: any } = {}
local random = Random.new()
local trove = Trove.new()
local playerTroves: { [Player]: any } = {}

local function rollTrait(rarity: string): (string?, number?)
	if not PetConfig.TraitRarities[rarity] or random:NextNumber() >= PetConfig.TraitChance then
		return nil, nil
	end
	local keys: { string } = {}
	for key in PetConfig.Traits do
		table.insert(keys, key)
	end
	if #keys == 0 then
		return nil, nil
	end
	table.sort(keys)
	local key = keys[random:NextInteger(1, #keys)]
	local trait = PetConfig.Traits[key]
	local value = math.floor(random:NextNumber(trait.MinValue, trait.MaxValue) * 100 + 0.5) / 100
	return key, value
end

local function watchCharacter(player: Player, character: Model, characterTrove: any)
	characterTrove:Clean()
	local function changed(child: Instance)
		if Tools.PetIdOf(child) then
			PetService.HeldChanged:Fire(player)
		end
	end
	characterTrove:Connect(character.ChildAdded, changed)
	characterTrove:Connect(character.ChildRemoved, changed)
	PetService.HeldChanged:Fire(player)
end

local function track(player: Player)
	if playerTroves[player] then
		return
	end
	local playerTrove = Trove.new()
	playerTroves[player] = playerTrove
	local characterTrove = playerTrove:Extend()
	playerTrove:Connect(player.ChildAdded, function(child: Instance)
		if child:IsA("Backpack") then
			task.defer(PetService.SyncTools, PetService, player)
		end
	end)
	playerTrove:Connect(player.CharacterAdded, function(character: Model)
		watchCharacter(player, character, characterTrove)
	end)
	if player.Character then
		watchCharacter(player, player.Character, characterTrove)
	end
end

local function untrack(player: Player)
	local playerTrove = playerTroves[player]
	playerTroves[player] = nil
	if playerTrove then
		playerTrove:Destroy()
	end
end

function PetService.Count(_self: any, player: Player): number
	local data = services.DataService:GetData(player)
	if not data then
		return 0
	end
	local count = 0
	for _ in data.Pets do
		count += 1
	end
	return count
end

function PetService.CanAdd(_self: any, player: Player, amount: number): boolean
	if not services.DataService:GetData(player) then
		return false
	end
	return PetService:Count(player) + amount <= PetConfig.MaxPets
end

function PetService.GetRate(_self: any, pet: PlayerData.Pet): number
	local config = PetConfig.Pets[pet.Key]
	return if config then config.MoneyPerSecond else 0
end

function PetService.GetHeldPetId(_self: any, player: Player): string?
	return Tools.Held(player)
end

function PetService.PutAway(_self: any, player: Player)
	Tools.PutAway(player)
end

function PetService.SyncTools(_self: any, player: Player)
	local data = services.DataService:GetData(player)
	if data and player.Parent == Players then
		Tools.Sync(player, data.Pets)
	end
end

function PetService.Grant(_self: any, player: Player, petKey: string): Grant?
	local pet = PetConfig.Pets[petKey]
	local data = services.DataService:GetData(player)
	local replica = services.DataService:GetReplica(player)
	if not pet or not data or not replica or not PetService:CanAdd(player, 1) then
		return nil
	end
	local id = tostring(data.NextPetId)
	local trait, traitValue = rollTrait(pet.Rarity)
	local record: PlayerData.Pet = {
		Key = petKey,
		HatchedAt = os.time(),
		Trait = trait,
		TraitValue = traitValue,
	}
	replica:Set({ "NextPetId" }, data.NextPetId + 1)
	replica:Set({ "Pets", id }, record)
	local isNew = services.IndexService:RecordPet(player, petKey)
	services.DataService:RequestSave(player)
	PetService:SyncTools(player)
	PetService.Granted:Fire(player)
	return {
		Id = id,
		PetKey = petKey,
		IsNew = isNew,
		Trait = trait,
		TraitValue = traitValue,
	}
end

function PetService.Sell(_self: any, player: Player, petIds: { string }): number
	local data = services.DataService:GetData(player)
	local replica = services.DataService:GetReplica(player)
	if not data or not replica then
		return 0
	end
	local sold: { [string]: boolean } = {}
	local total = 0
	local count = 0
	for _, petId in petIds do
		local pet = data.Pets[petId]
		if sold[petId] or not pet or pet.Slot ~= nil or not PetConfig.Pets[pet.Key] then
			return 0
		end
		sold[petId] = true
		total += RokValue.Sell(pet.Key)
		count += 1
	end
	if count == 0 then
		return 0
	end
	for petId in sold do
		replica:Set({ "Pets", petId }, nil)
	end
	services.DataService:AdjustCash(player, total)
	services.DataService:RequestSave(player)
	PetService:SyncTools(player)
	return total
end

function PetService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function PetService.Start(_self: any)
	services.DataService.PlayerLoaded:Connect(function(player: Player)
		track(player)
		PetService:SyncTools(player)
	end)
	trove:Connect(Players.PlayerRemoving, untrack)
	Packets.SellPets.OnServerInvoke = function(player: Player, petIds: { string }): number
		if type(petIds) ~= "table" or #petIds == 0 or #petIds > PetConfig.MaxPets then
			return 0
		end
		for _, petId in petIds do
			if type(petId) ~= "string" or #petId == 0 or #petId > 12 then
				return 0
			end
		end
		return PetService:Sell(player, petIds)
	end
end

function PetService.Destroy(_self: any)
	Packets.SellPets.OnServerInvoke = nil
	trove:Clean()
	for player in playerTroves do
		untrack(player)
	end
end

return PetService
