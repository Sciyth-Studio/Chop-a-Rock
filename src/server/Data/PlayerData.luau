--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local TrainingStands = require(ReplicatedStorage.Utils.TrainingStands)
local Tutorial = require(ReplicatedStorage.Tutorial)

export type Pet = {
	Key: string,
	HatchedAt: number,
	Trait: string?,
	TraitValue: number?,
	Modifier: string?,
	Slot: number?,
}

export type Data = {
	SchemaVersion: number,
	Cash: number,
	Strength: number,
	AuraTier: number,
	Cannons: { [string]: boolean },
	EquippedCannon: string,
	TrainingTier: number,
	TrainingMinigameBest: number,
	Rebirths: number,
	Geodes: { [string]: number },
	Pets: { [string]: Pet },
	NextPetId: number,
	PedestalSlots: number,
	PedestalEarnings: { [string]: number },
	Index: {
		Pets: { [string]: number },
		Rocks: { [string]: number },
		Claimed: {
			Pets: { [string]: boolean },
			Rocks: { [string]: boolean },
			Zones: { [string]: boolean },
		},
	},
	Settings: { [string]: boolean | number },
	Tutorial: Tutorial.State,
	LastSeenAt: number,
	Receipts: { [string]: number },
}

local PlayerData = {}

PlayerData.Template = {
	SchemaVersion = 1,
	Cash = 0,
	Strength = 0,
	AuraTier = 1,
	Cannons = {},
	EquippedCannon = "",
	TrainingTier = 1,
	TrainingMinigameBest = 0,
	Rebirths = 0,
	Geodes = {},
	Pets = {},
	NextPetId = 1,
	PedestalSlots = PedestalConfig.StartingSlots,
	PedestalEarnings = {},
	Index = {
		Pets = {},
		Rocks = {},
		Claimed = {
			Pets = {},
			Rocks = {},
			Zones = {},
		},
	},
	Settings = {
		Volume = 1,
		Music = true,
		SoundEffects = true,
		LowGraphics = false,
		Notifications = true,
		AutoEquip = true,
	},
	Tutorial = Tutorial.NewState(),
	LastSeenAt = 0,
	Receipts = {},
} :: Data

local function natural(value: any): boolean
	return type(value) == "number"
		and value == value
		and math.abs(value) < math.huge
		and value >= 0
		and value % 1 == 0
end

local function finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function counts(value: any): boolean
	if type(value) ~= "table" then
		return false
	end
	for key, count in value do
		if type(key) ~= "string" or #key == 0 or not natural(count) then
			return false
		end
	end
	return true
end

local function flags(value: any): boolean
	if type(value) ~= "table" then
		return false
	end
	for key, flag in value do
		if type(key) ~= "string" or #key == 0 or flag ~= true then
			return false
		end
	end
	return true
end

local function validPet(pet: any): boolean
	return type(pet) == "table"
		and type(pet.Key) == "string"
		and #pet.Key > 0
		and natural(pet.HatchedAt)
		and (pet.Trait == nil or type(pet.Trait) == "string")
		and (pet.TraitValue == nil or finite(pet.TraitValue))
		and (pet.Modifier == nil or type(pet.Modifier) == "string")
		and (pet.Slot == nil or (natural(pet.Slot) and pet.Slot >= 1))
end

function PlayerData.Validate(data: any): boolean
	if type(data) ~= "table" or (data.SchemaVersion ~= nil and data.SchemaVersion ~= 1) then
		return false
	end
	for _, key in { "Cash", "Strength", "Rebirths", "TrainingMinigameBest", "LastSeenAt" } do
		if data[key] ~= nil and not natural(data[key]) then
			return false
		end
	end
	if data.TrainingTier ~= nil and (not natural(data.TrainingTier) or data.TrainingTier < 1) then
		return false
	end
	for _, key in { "ArmTier", "AuraTier" } do
		if data[key] ~= nil and (not natural(data[key]) or data[key] < 1) then
			return false
		end
	end
	if data.Cannons ~= nil and not flags(data.Cannons) then
		return false
	end
	if data.EquippedCannon ~= nil and type(data.EquippedCannon) ~= "string" then
		return false
	end
	if data.Geodes ~= nil and not counts(data.Geodes) then
		return false
	end
	if data.Pets ~= nil then
		if type(data.Pets) ~= "table" then
			return false
		end
		for id, pet in data.Pets do
			if type(id) ~= "string" or #id == 0 or not validPet(pet) then
				return false
			end
		end
	end
	if data.NextPetId ~= nil and (not natural(data.NextPetId) or data.NextPetId < 1) then
		return false
	end
	if data.PedestalSlots ~= nil and (not natural(data.PedestalSlots) or data.PedestalSlots < 1) then
		return false
	end
	if data.PedestalEarnings ~= nil then
		if type(data.PedestalEarnings) ~= "table" then
			return false
		end
		for slot, amount in data.PedestalEarnings do
			if type(slot) ~= "string" or #slot == 0 or not finite(amount) or amount < 0 then
				return false
			end
		end
	end
	if data.Index ~= nil then
		local index = data.Index
		if type(index) ~= "table" then
			return false
		end
		for _, key in { "Pets", "Rocks" } do
			if index[key] ~= nil and not counts(index[key]) then
				return false
			end
		end
		if index.Claimed ~= nil then
			if type(index.Claimed) ~= "table" then
				return false
			end
			for _, key in { "Pets", "Rocks", "Zones" } do
				if index.Claimed[key] ~= nil and not flags(index.Claimed[key]) then
					return false
				end
			end
		end
	end
	if data.Settings ~= nil then
		if type(data.Settings) ~= "table" then
			return false
		end
		for name, value in data.Settings do
			local isVolume = finite(value) and value >= 0 and value <= 1
			if type(name) ~= "string" or (type(value) ~= "boolean" and not isVolume) then
				return false
			end
		end
	end
	if data.Tutorial ~= nil and not Tutorial.IsValid(data.Tutorial) then
		return false
	end
	if data.Receipts ~= nil then
		if type(data.Receipts) ~= "table" then
			return false
		end
		for purchaseId, grantedAt in data.Receipts do
			if type(purchaseId) ~= "string" or #purchaseId == 0 or not natural(grantedAt) then
				return false
			end
		end
	end
	return true
end

local function hasProgress(data: any): boolean
	return (type(data.Cash) == "number" and data.Cash > 0)
		or (type(data.Strength) == "number" and data.Strength > 0)
		or (type(data.AuraTier) == "number" and data.AuraTier > 1)
		or (type(data.Rebirths) == "number" and data.Rebirths > 0)
		or (type(data.Pets) == "table" and next(data.Pets) ~= nil)
end

function PlayerData.Migrate(data: any)
	if data.AuraTier == nil and data.ArmTier ~= nil then
		data.AuraTier = data.ArmTier
	end
	data.ArmTier = nil
	data.Auras = nil
	data.EquippedAura = nil
	if data.Tutorial == nil and hasProgress(data) then
		data.Tutorial = { Step = Tutorial.Done, Taps = 0, Furthest = Tutorial.FirstRebirth }
	end
	if data.TrainingTier == nil and natural(data.Rebirths) then
		data.TrainingTier = TrainingStands.IndexForRebirths(data.Rebirths)
	end
	local settings = data.Settings
	if type(settings) == "table" and type(settings.Music) == "number" then
		if settings.Volume == nil and settings.Music > 0 then
			settings.Volume = settings.Music
		end
		settings.Music = settings.Music > 0
	end
end

return PlayerData
