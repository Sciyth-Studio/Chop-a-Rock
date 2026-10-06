--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local PlayerData = require(script.Parent.Parent.Data.PlayerData)

export type Grant = {
	Id: string,
	PetKey: string,
	IsNew: boolean,
	Trait: string?,
	TraitValue: number?,
}

local PetService = { Name = "PetService" }

local services: { [string]: any } = {}
local random = Random.new()

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
	return {
		Id = id,
		PetKey = petKey,
		IsNew = isNew,
		Trait = trait,
		TraitValue = traitValue,
	}
end

function PetService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function PetService.Start(_self: any) end

function PetService.Destroy(_self: any) end

return PetService
