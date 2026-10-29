--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local RokModifier = require(ReplicatedStorage.RokModifier)
local RokSize = require(ReplicatedStorage.RokSize)
local RokValue = require(ReplicatedStorage.RokValue)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local Tools = require(script.Tools)

export type Grant = {
	Id: string,
	PetKey: string,
	IsNew: boolean,
	Trait: string?,
	TraitValue: number?,
	Modifier: string?,
	Size: string?,
}

local PetService = {
	Name = "PetService",
	HeldChanged = Signal.new() :: Signal.Signal<Player>,
	Granted = Signal.new() :: Signal.Signal<Player, number>,
	ModifierChanged = Signal.new() :: Signal.Signal<Player, string>,
}

local services: { [string]: any } = {}
local random = Random.new()
local trove = Trove.new()
local playerTroves: { [Player]: any } = {}
local lastPendingCheck = 0

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

local function isExclusive(petKey: string): boolean
	local pet = PetConfig.Pets[petKey]
	return pet ~= nil and pet.Exclusive == true
end

local function clearExclusiveModifiers(player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	for id, pet in data.Pets do
		if pet.Modifier ~= nil and isExclusive(pet.Key) then
			services.DataService:Set(player, { "Pets", id, "Modifier" }, nil)
		end
	end
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
	return PetService:Count(player) + amount <= services.PassService:GetBackpackSize(player)
end

function PetService.GetRate(_self: any, pet: PlayerData.Pet): number
	return RokModifier.Rate(pet.Key, pet.Modifier, pet.Income)
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

local function add(player: Player, petKey: string, modifier: string?, luck: number?): Grant?
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
		Modifier = if RokModifier.Get(modifier) and not isExclusive(petKey) then modifier else nil,
		Size = if isExclusive(petKey) then nil else RokSize.Roll(random, luck or 1),
	}
	replica:Set({ "NextPetId" }, data.NextPetId + 1)
	replica:Set({ "Pets", id }, record)
	local isNew = services.IndexService:RecordPet(player, petKey)
	return {
		Id = id,
		PetKey = petKey,
		IsNew = isNew,
		Trait = trait,
		TraitValue = traitValue,
		Modifier = record.Modifier,
		Size = record.Size,
	}
end

local function removePets(replica: any, pets: { [string]: any }, ids: { [string]: boolean })
	local kept = {}
	for id, pet in pets do
		if not ids[id] then
			kept[id] = pet
		end
	end
	replica:Set({ "Pets" }, kept)
end

local function updateIncome(player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	local best = 0
	for _, pet in data.Pets do
		local config = PetConfig.Pets[pet.Key]
		if config and not config.Exclusive then
			best = math.max(best, config.MoneyPerSecond)
		end
	end
	local changed = false
	for id, pet in data.Pets do
		local config = PetConfig.Pets[pet.Key]
		if config and config.IncomeRule == "BestTimes" then
			local income = math.max(config.MoneyPerSecond, best * (config.IncomeMultiplier or 1))
			if pet.Income ~= income then
				services.DataService:Set(player, { "Pets", id, "Income" }, income)
				changed = true
			end
		end
	end
	if changed then
		services.PedestalService:Refresh(player)
	end
end

local function granted(player: Player, equipDelay: number?)
	updateIncome(player)
	services.DataService:RequestSave(player)
	PetService:SyncTools(player)
	PetService.Granted:Fire(player, equipDelay or 0)
end

local function grantPending(player: Player)
	local data = services.DataService:GetData(player)
	if not data or next(data.PendingRoks) == nil then
		return
	end
	for petKey, count in data.PendingRoks do
		local left = count
		while left > 0 and PetService:CanAdd(player, 1) do
			if not PetService:Grant(player, petKey) then
				break
			end
			left -= 1
			local pet = PetConfig.Pets[petKey]
			services.NotificationService:Notify(
				player,
				"Purchase",
				`{if pet then pet.DisplayName else petKey} joined your Backpack!`
			)
		end
		if left ~= count then
			services.DataService:Set(player, { "PendingRoks", petKey }, if left > 0 then left else nil)
		end
	end
end

function PetService.GrantOrQueue(_self: any, player: Player, petKey: string): boolean
	local data = services.DataService:GetData(player)
	if not data or not PetConfig.Pets[petKey] then
		return false
	end
	if PetService:CanAdd(player, 1) and PetService:Grant(player, petKey) then
		return true
	end
	services.DataService:Set(player, { "PendingRoks", petKey }, (data.PendingRoks[petKey] or 0) + 1)
	return true
end

function PetService.Grant(
	_self: any,
	player: Player,
	petKey: string,
	modifier: string?,
	equipDelay: number?,
	luck: number?
): Grant?
	local grant = add(player, petKey, modifier, luck)
	if grant then
		granted(player, equipDelay)
	end
	return grant
end

function PetService.GrantMany(_self: any, player: Player, petKeys: { string }): { Grant }
	local grants: { Grant } = {}
	for _, petKey in petKeys do
		local grant = add(player, petKey, nil, nil)
		if not grant then
			break
		end
		table.insert(grants, grant)
	end
	if #grants > 0 then
		granted(player)
	end
	return grants
end

function PetService.NewestPetId(_self: any, player: Player): string?
	local data = services.DataService:GetData(player)
	if not data then
		return nil
	end
	local newest: string? = nil
	for id in data.Pets do
		if not newest or (tonumber(id) or 0) > (tonumber(newest) or 0) then
			newest = id
		end
	end
	return newest
end

function PetService.SetTrait(
	_self: any,
	player: Player,
	petId: string,
	trait: string?,
	value: number?
): boolean
	local data = services.DataService:GetData(player)
	local replica = services.DataService:GetReplica(player)
	local pet = if data then data.Pets[petId] else nil
	if not pet or not replica or (trait ~= nil and (not PetConfig.Traits[trait] or value == nil)) then
		return false
	end
	replica:Set({ "Pets", petId, "Trait" }, trait)
	replica:Set({ "Pets", petId, "TraitValue" }, if trait then value else nil)
	services.DataService:RequestSave(player)
	PetService:SyncTools(player)
	PetService.ModifierChanged:Fire(player, petId)
	return true
end

function PetService.SetSize(_self: any, player: Player, petId: string, size: string?): boolean
	local data = services.DataService:GetData(player)
	local pet = if data then data.Pets[petId] else nil
	if not pet or isExclusive(pet.Key) or (size ~= nil and not RokSize.IsShown(size)) then
		return false
	end
	services.DataService:Set(player, { "Pets", petId, "Size" }, size)
	services.DataService:RequestSave(player)
	PetService:SyncTools(player)
	PetService.ModifierChanged:Fire(player, petId)
	return true
end

function PetService.RemoveUnplaced(_self: any, player: Player): number
	local data = services.DataService:GetData(player)
	local replica = services.DataService:GetReplica(player)
	if not data or not replica then
		return 0
	end
	local ids: { [string]: boolean } = {}
	local count = 0
	for id, pet in data.Pets do
		if pet.Slot == nil then
			ids[id] = true
			count += 1
		end
	end
	if count > 0 then
		removePets(replica, data.Pets, ids)
		services.DataService:RequestSave(player)
		updateIncome(player)
		PetService:SyncTools(player)
	end
	return count
end

function PetService.CanTakeModifier(_self: any, petKey: string): boolean
	return PetConfig.Pets[petKey] ~= nil and not isExclusive(petKey)
end

function PetService.SetModifier(
	_self: any,
	player: Player,
	petId: string,
	modifier: string,
	isCatch: boolean
): boolean
	local data = services.DataService:GetData(player)
	local replica = services.DataService:GetReplica(player)
	local pet = if data then data.Pets[petId] else nil
	if not pet or not replica or not RokModifier.Get(modifier) or isExclusive(pet.Key) then
		return false
	end
	if isCatch and not RokModifier.IsBetter(modifier, pet.Modifier) then
		return false
	end
	local oldRate = RokModifier.Rate(pet.Key, pet.Modifier)
	replica:Set({ "Pets", petId, "Modifier" }, modifier)
	services.DataService:RequestSave(player)
	PetService:SyncTools(player)
	PetService.ModifierChanged:Fire(player, petId)
	local config = WeatherConfig.Modifiers[modifier]
	local petConfig = PetConfig.Pets[pet.Key]
	if petConfig then
		services.NotificationService:Notify(
			player,
			WeatherConfig.NoticeKindPrefix .. modifier,
			string.format(
				WeatherConfig.CatchText,
				petConfig.DisplayName,
				config.DisplayName,
				NumberFormat.Rate(oldRate),
				NumberFormat.Rate(RokModifier.Rate(pet.Key, modifier))
			)
		)
	end
	print(`[PetService] {player.Name}'s {pet.Key} ({petId}) is now {modifier}`)
	return true
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
		if PetConfig.Pets[pet.Key].Exclusive then
			continue
		end
		sold[petId] = true
		total += RokValue.Sell(pet.Key, pet.Modifier)
		count += 1
	end
	if count == 0 then
		return 0
	end
	removePets(replica, data.Pets, sold)
	services.DataService:AdjustCash(player, total, AnalyticsConfig.Sources.SellRoks)
	services.DataService:RequestSave(player)
	updateIncome(player)
	PetService:SyncTools(player)
	return total
end

function PetService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function PetService.Start(_self: any)
	services.DataService.PlayerLoaded:Connect(function(player: Player)
		track(player)
		clearExclusiveModifiers(player)
		updateIncome(player)
		PetService:SyncTools(player)
	end)
	lastPendingCheck = os.clock()
	trove:Connect(RunService.Heartbeat, function()
		local clock = os.clock()
		if clock - lastPendingCheck >= PetConfig.PendingCheckSeconds then
			lastPendingCheck = clock
			for _, player in Players:GetPlayers() do
				grantPending(player)
			end
		end
	end)
	trove:Connect(Players.PlayerRemoving, untrack)
	Packets.SellPets.OnServerInvoke = function(player: Player, petIds: { string }): number
		if
			type(petIds) ~= "table"
			or #petIds == 0
			or #petIds > services.PassService:GetBackpackSize(player)
		then
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
