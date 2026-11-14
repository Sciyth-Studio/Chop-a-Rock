--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonHint = require(ReplicatedStorage.CannonHint)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local PetKeyMigration = require(script.Parent.PetKeyMigration)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

local cannonHint = TutorialConfig.CannonHint

export type Pet = {
	Key: string,
	HatchedAt: number,
	Trait: string?,
	TraitValue: number?,
	Modifier: string?,
	Size: string?,
	Slot: number?,
	Income: number?,
	RevealAt: number?,
}

export type HatchPad = {
	GeodeKey: string,
	ReadyAt: number,
	Luck: number?,
}

export type Weekly = {
	Week: number,
	Strength: number,
	PerfectChops: number,
	Playtime: number,
	MoneyPerSecond: number,
}

export type StarterPack = {
	Bought: boolean,
	OfferEndsAt: number,
	SecondChanceUsed: boolean,
}

export type StarterEgg = {
	HasEgg: boolean,
	HasLanded: boolean,
	SecondsLeft: number,
	PadIndex: number,
	IsOpened: boolean,
}

export type Offline = {
	LastAmount: number,
	LastAt: number,
}

export type Data = {
	SchemaVersion: number,
	Cash: number,
	Strength: number,
	PeakStrength: number,
	AuraTier: number,
	Cannons: { [string]: boolean },
	EquippedCannon: string,
	TrainingTier: number,
	TrainingLadder: number,
	TrainingMinigameBest: number,
	PerfectChops: number,
	Playtime: number,
	Weekly: Weekly,
	Geodes: { [string]: number },
	HatchPads: { [string]: HatchPad },
	EggLuck: { [string]: { number } },
	FreeRetryAt: number,
	RetryCredits: number,
	Pets: { [string]: Pet },
	NextPetId: number,
	PedestalSlots: number,
	BaseLevel: number,
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
	Hints: { [string]: number },
	Passes: { [string]: boolean },
	Boosts: { [string]: number },
	Potions: { [string]: number },
	Offers: { [string]: boolean },
	StarterPack: StarterPack,
	StarterEgg: StarterEgg,
	Offline: Offline,
	PendingPets: { [string]: number },
	Exclusives: { [string]: boolean },
	GiftsReceived: { [string]: number },
	GiftCredits: { [string]: number },
	LastSeenAt: number,
	Receipts: { [string]: number },
}

local PlayerData = {}

PlayerData.Template = {
	SchemaVersion = 1,
	Cash = 0,
	Strength = TutorialConfig.StartStrength,
	PeakStrength = TutorialConfig.StartStrength,
	AuraTier = 1,
	Cannons = {},
	EquippedCannon = "",
	TrainingTier = 1,
	TrainingLadder = TrainingConfig.LadderVersion,
	TrainingMinigameBest = 0,
	PerfectChops = 0,
	Playtime = 0,
	Weekly = { Week = 0, Strength = 0, PerfectChops = 0, Playtime = 0, MoneyPerSecond = 0 },
	Geodes = {},
	HatchPads = {},
	EggLuck = {},
	FreeRetryAt = 0,
	RetryCredits = 0,
	Pets = {},
	NextPetId = 1,
	PedestalSlots = PedestalConfig.StartingSlots,
	BaseLevel = 1,
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
		MusicVolume = 1,
		SoundEffectsVolume = 1,
		LowGraphics = false,
		Notifications = true,
		AutoEquip = true,
	},
	Tutorial = Tutorial.NewState(),
	Hints = {},
	Passes = {},
	Boosts = {},
	Potions = {},
	Offers = {},
	StarterPack = { Bought = false, OfferEndsAt = 0, SecondChanceUsed = false },
	StarterEgg = { HasEgg = false, HasLanded = false, SecondsLeft = 0, PadIndex = 0, IsOpened = false },
	Offline = { LastAmount = 0, LastAt = 0 },
	PendingPets = {},
	Exclusives = {},
	GiftsReceived = {},
	GiftCredits = {},
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
		and (pet.Size == nil or type(pet.Size) == "string")
		and (pet.Slot == nil or (natural(pet.Slot) and pet.Slot >= 1))
		and (pet.Income == nil or (finite(pet.Income) and pet.Income >= 0))
		and (pet.RevealAt == nil or finite(pet.RevealAt))
end

function PlayerData.Validate(data: any): boolean
	if type(data) ~= "table" or (data.SchemaVersion ~= nil and data.SchemaVersion ~= 1) then
		return false
	end
	for _, key in
		{
			"Cash",
			"Strength",
			"PeakStrength",
			"PerfectChops",
			"Playtime",
			"TrainingMinigameBest",
			"TrainingLadder",
			"LastSeenAt",
		}
	do
		if data[key] ~= nil and not natural(data[key]) then
			return false
		end
	end
	if data.TrainingTier ~= nil and (not natural(data.TrainingTier) or data.TrainingTier < 1) then
		return false
	end
	if data.BaseLevel ~= nil and (not natural(data.BaseLevel) or data.BaseLevel < 1) then
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
	if data.Weekly ~= nil then
		local weekly = data.Weekly
		if type(weekly) ~= "table" then
			return false
		end
		for _, key in { "Week", "Strength", "PerfectChops", "Playtime" } do
			if weekly[key] ~= nil and not natural(weekly[key]) then
				return false
			end
		end
		if
			weekly.MoneyPerSecond ~= nil and (not finite(weekly.MoneyPerSecond) or weekly.MoneyPerSecond < 0)
		then
			return false
		end
	end
	if data.Geodes ~= nil and not counts(data.Geodes) then
		return false
	end
	if data.HatchPads ~= nil then
		if type(data.HatchPads) ~= "table" then
			return false
		end
		for padKey, record in data.HatchPads do
			if
				type(padKey) ~= "string"
				or type(record) ~= "table"
				or type(record.GeodeKey) ~= "string"
				or not natural(record.ReadyAt)
				or (record.Luck ~= nil and not natural(record.Luck))
			then
				return false
			end
		end
	end
	if data.EggLuck ~= nil then
		if type(data.EggLuck) ~= "table" then
			return false
		end
		for key, list in data.EggLuck do
			if type(key) ~= "string" or type(list) ~= "table" then
				return false
			end
			for _, value in list do
				if not natural(value) then
					return false
				end
			end
		end
	end
	if data.RetryCredits ~= nil and not natural(data.RetryCredits) then
		return false
	end
	if data.FreeRetryAt ~= nil and not natural(data.FreeRetryAt) then
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
	if data.Hints ~= nil and not counts(data.Hints) then
		return false
	end
	if data.Passes ~= nil and not flags(data.Passes) then
		return false
	end
	if data.Potions ~= nil and not counts(data.Potions) then
		return false
	end
	if data.Boosts ~= nil and not counts(data.Boosts) then
		return false
	end
	if data.Offers ~= nil and not flags(data.Offers) then
		return false
	end
	if data.StarterPack ~= nil then
		local starter = data.StarterPack
		if type(starter) ~= "table" then
			return false
		end
		for _, key in { "Bought", "SecondChanceUsed" } do
			if starter[key] ~= nil and type(starter[key]) ~= "boolean" then
				return false
			end
		end
		if starter.OfferEndsAt ~= nil and not natural(starter.OfferEndsAt) then
			return false
		end
	end
	if data.StarterEgg ~= nil then
		local egg = data.StarterEgg
		if type(egg) ~= "table" then
			return false
		end
		for _, key in { "HasEgg", "HasLanded", "IsOpened" } do
			if egg[key] ~= nil and type(egg[key]) ~= "boolean" then
				return false
			end
		end
		if egg.PadIndex ~= nil and not natural(egg.PadIndex) then
			return false
		end
		if egg.SecondsLeft ~= nil and not natural(egg.SecondsLeft) then
			return false
		end
	end
	if data.PendingPets ~= nil and not counts(data.PendingPets) then
		return false
	end
	if data.Exclusives ~= nil and not flags(data.Exclusives) then
		return false
	end
	if data.GiftsReceived ~= nil and not counts(data.GiftsReceived) then
		return false
	end
	if data.GiftCredits ~= nil and not counts(data.GiftCredits) then
		return false
	end
	if data.Offline ~= nil then
		local offline = data.Offline
		if type(offline) ~= "table" then
			return false
		end
		if offline.LastAmount ~= nil and (not finite(offline.LastAmount) or offline.LastAmount < 0) then
			return false
		end
		if offline.LastAt ~= nil and not natural(offline.LastAt) then
			return false
		end
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
		or (type(data.Pets) == "table" and next(data.Pets) ~= nil)
end

function PlayerData.Migrate(data: any)
	PetKeyMigration.Apply(data)
	if data.AuraTier == nil and data.ArmTier ~= nil then
		data.AuraTier = data.ArmTier
	end
	data.ArmTier = nil
	data.Auras = nil
	data.EquippedAura = nil
	if data.Tutorial == nil and hasProgress(data) then
		data.Tutorial = { Step = Tutorial.Done, Taps = 0, Furthest = Tutorial.LastMilestone }
	end
	if data.Hints == nil and type(data.Cannons) == "table" and next(data.Cannons) ~= nil then
		data.Hints = { [cannonHint.Key] = CannonHint.Done, [cannonHint.FurthestKey] = CannonHint.Done }
	end
	if data.PeakStrength == nil and natural(data.Strength) then
		data.PeakStrength = data.Strength
	end
	data.Rebirths = nil
	if data.TrainingLadder == nil then
		if natural(data.TrainingTier) then
			data.TrainingTier = TrainingConfig.OldTierMap[data.TrainingTier]
				or TrainingConfig.OldTierMap[#TrainingConfig.OldTierMap]
		end
		data.TrainingLadder = TrainingConfig.LadderVersion
	end
	if natural(data.PedestalSlots) and data.PedestalSlots < PedestalConfig.StartingSlots then
		data.PedestalSlots = PedestalConfig.StartingSlots
	end
	if type(data.PedestalEarnings) == "table" then
		local banked = 0
		for _, amount in data.PedestalEarnings do
			if finite(amount) and amount > 0 then
				banked += amount
			end
		end
		data.Cash = (if natural(data.Cash) then data.Cash else 0) + math.floor(banked)
	end
	data.PedestalEarnings = nil
	data.Pity = nil
	data.SelectedGeode = nil
	local settings = data.Settings
	if type(settings) == "table" and type(settings.Music) == "number" then
		if settings.Volume == nil and settings.Music > 0 then
			settings.Volume = settings.Music
		end
		settings.Music = settings.Music > 0
	end
	if type(settings) == "table" then
		local master = if type(settings.Volume) == "number" then math.clamp(settings.Volume, 0, 1) else 1
		if settings.MusicVolume == nil then
			settings.MusicVolume = if settings.Music == false then 0 else master
		end
		if settings.SoundEffectsVolume == nil then
			settings.SoundEffectsVolume = if settings.SoundEffects == false then 0 else master
		end
		settings.Volume = nil
		settings.Music = nil
		settings.SoundEffects = nil
	end
end

return PlayerData
