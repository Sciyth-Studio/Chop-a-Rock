--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local IndexConfig = require(ReplicatedStorage.Config.IndexConfig)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local PedestalSlots = require(ReplicatedStorage.PedestalSlots)
local TrainingStands = require(ReplicatedStorage.Utils.TrainingStands)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Types = require(script.Parent.Types)

local Presets = {}

function Presets.Find(presetId: string): AdminConfig.Preset?
	for _, preset in AdminConfig.Presets do
		if preset.Id == presetId then
			return preset
		end
	end
	return nil
end

local function buildPets(preset: AdminConfig.Preset, slotCount: number, index: { [string]: any })
	local pets: { [string]: any } = {}
	local unlocked = PedestalSlots.Unlocked(slotCount)
	local nextId = 1
	local petKeys: { string } = preset.Pets or {}
	for _, petKey in petKeys do
		if not PetConfig.Pets[petKey] then
			warn(`[AdminService] Preset {preset.Id} names unknown Rok {petKey}`)
			continue
		end
		pets[tostring(nextId)] = {
			Key = petKey,
			HatchedAt = os.time(),
			Slot = unlocked[nextId],
		}
		index.Pets[petKey] = (index.Pets[petKey] or 0) + 1
		nextId += 1
	end
	return pets, nextId
end

local function completeIndex(index: { [string]: any })
	for _, page in IndexConfig.Pages do
		local counts = index[page.Kind]
		for _, zone in page.Zones do
			for _, key in zone.Entries do
				counts[key] = math.max(counts[key] or 0, 1)
			end
		end
	end
end

function Presets.Apply(context: Types.Context, player: Player, preset: AdminConfig.Preset): boolean
	local slotCount =
		math.clamp(preset.PedestalSlots or PedestalConfig.StartingSlots, 1, PedestalSlots.Total())
	local index = { Pets = {}, Rocks = {}, Claimed = { Pets = {}, Rocks = {}, Zones = {} } }
	local pets, nextPetId = buildPets(preset, slotCount, index)
	if preset.CompleteIndex then
		completeIndex(index)
	end
	local strength = preset.Strength
	local overrides: { [string]: any } = {
		PedestalSlots = slotCount,
		Pets = pets,
		NextPetId = nextPetId,
		Index = index,
		Geodes = table.clone(preset.Geodes or {}),
	}
	overrides.Cash = preset.Cash
	overrides.Strength = strength
	overrides.Rebirths = preset.Rebirths
	overrides.AuraTier = preset.AuraTier
	overrides.TrainingTier = TrainingStands.IndexForRebirths(preset.Rebirths or 0)
	local isFresh = (preset.Cash or 0) <= 0
		and (strength or 0) <= 0
		and (preset.Rebirths or 0) <= 0
		and (preset.AuraTier or 1) <= 1
		and next(pets) == nil
	overrides.Tutorial = if isFresh
		then Tutorial.NewState()
		else { Step = Tutorial.Done, Taps = 0, Furthest = Tutorial.LastMilestone }
	return context.Services.DataService:ResetData(player, overrides)
end

return Presets
