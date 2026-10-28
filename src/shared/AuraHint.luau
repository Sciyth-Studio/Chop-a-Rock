--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraConfig = require(ReplicatedStorage.Config.AuraConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

local AuraHint = {
	Locked = 0,
	Save = 1,
	Buy = 2,
	Train = 3,
	Done = 4,
}

local settings = TutorialConfig.AuraHint

function AuraHint.Aura(): AuraConfig.AuraTier?
	return AuraConfig.Tiers[settings.Tier]
end

local function hints(data: any): { [string]: any }
	local value = if type(data) == "table" then data.Hints else nil
	return if type(value) == "table" then value else {}
end

function AuraHint.StageOf(data: any): number
	local stage = hints(data)[settings.Key]
	return if type(stage) == "number" then stage else AuraHint.Locked
end

function AuraHint.FurthestOf(data: any): number
	local furthest = hints(data)[settings.FurthestKey]
	return if type(furthest) == "number" then furthest else AuraHint.Locked
end

function AuraHint.RepsOf(data: any): number
	local reps = hints(data)[settings.RepsKey]
	return if type(reps) == "number" then reps else 0
end

function AuraHint.IsActive(stage: number): boolean
	return stage > AuraHint.Locked and stage < AuraHint.Done
end

function AuraHint.Decide(data: any): number
	local stage = AuraHint.StageOf(data)
	local aura = AuraHint.Aura()
	if stage == AuraHint.Done or not aura or type(data) ~= "table" then
		return stage
	end
	if Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
		return stage
	end
	if (data.Rebirths or 0) > 0 then
		return AuraHint.Done
	end
	if (data.AuraTier or 1) >= settings.Tier then
		if stage == AuraHint.Locked then
			return AuraHint.Done
		end
		return if AuraHint.RepsOf(data) >= settings.TrainReps then AuraHint.Done else AuraHint.Train
	end
	return if (data.Cash or 0) >= aura.Price then AuraHint.Buy else AuraHint.Save
end

function AuraHint.IsShown(data: any): boolean
	if not AuraHint.IsActive(AuraHint.StageOf(data)) or type(data) ~= "table" then
		return false
	end
	return not Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
end

return table.freeze(AuraHint)
