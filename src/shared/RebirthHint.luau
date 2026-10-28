--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RebirthStats = require(ReplicatedStorage.Utils.RebirthStats)
local RockHint = require(ReplicatedStorage.RockHint)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

local RebirthHint = {
	Locked = 0,
	Ready = 1,
	Done = 2,
}

local settings = TutorialConfig.RebirthHint

local function hints(data: any): { [string]: any }
	local value = if type(data) == "table" then data.Hints else nil
	return if type(value) == "table" then value else {}
end

function RebirthHint.StageOf(data: any): number
	local stage = hints(data)[settings.Key]
	return if type(stage) == "number" then stage else RebirthHint.Locked
end

function RebirthHint.FurthestOf(data: any): number
	local furthest = hints(data)[settings.FurthestKey]
	return if type(furthest) == "number" then furthest else RebirthHint.Locked
end

function RebirthHint.IsActive(stage: number): boolean
	return stage > RebirthHint.Locked and stage < RebirthHint.Done
end

function RebirthHint.Decide(data: any): number
	local stage = RebirthHint.StageOf(data)
	if stage == RebirthHint.Done or type(data) ~= "table" then
		return stage
	end
	if Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
		return stage
	end
	if (data.Rebirths or 0) > 0 then
		return RebirthHint.Done
	end
	if stage == RebirthHint.Locked and RockHint.StageOf(data) ~= RockHint.Done then
		return stage
	end
	if (data.Strength or 0) >= RebirthStats.Get(1).StrengthRequired then
		return RebirthHint.Ready
	end
	return stage
end

function RebirthHint.IsShown(data: any): boolean
	if not RebirthHint.IsActive(RebirthHint.StageOf(data)) or type(data) ~= "table" then
		return false
	end
	return not Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
end

return table.freeze(RebirthHint)
