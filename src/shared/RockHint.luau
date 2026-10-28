--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AuraHint = require(ReplicatedStorage.AuraHint)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

local RockHint = {
	Locked = 0,
	Train = 1,
	Chop = 2,
	Done = 3,
}

local settings = TutorialConfig.RockHint

function RockHint.Rock(): RockConfig.Rock?
	return RockConfig.Rocks[settings.RockKey]
end

function RockHint.PayoutMultiple(): number
	local rock = RockHint.Rock()
	local first = RockConfig.Rocks[TutorialConfig.FirstChopRockKey]
	if not rock or not first or first.BasePayout <= 0 then
		return 1
	end
	return math.floor(rock.BasePayout / first.BasePayout + 0.5)
end

local function hints(data: any): { [string]: any }
	local value = if type(data) == "table" then data.Hints else nil
	return if type(value) == "table" then value else {}
end

local function hasBroken(data: any): boolean
	local index = data.Index
	local rocks = if type(index) == "table" then index.Rocks else nil
	return type(rocks) == "table" and rocks[settings.RockKey] ~= nil
end

function RockHint.StageOf(data: any): number
	local stage = hints(data)[settings.Key]
	return if type(stage) == "number" then stage else RockHint.Locked
end

function RockHint.FurthestOf(data: any): number
	local furthest = hints(data)[settings.FurthestKey]
	return if type(furthest) == "number" then furthest else RockHint.Locked
end

function RockHint.IsActive(stage: number): boolean
	return stage > RockHint.Locked and stage < RockHint.Done
end

function RockHint.Decide(data: any): number
	local stage = RockHint.StageOf(data)
	local rock = RockHint.Rock()
	if stage == RockHint.Done or not rock or type(data) ~= "table" then
		return stage
	end
	if Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
		return stage
	end
	if (data.Rebirths or 0) > 0 or hasBroken(data) then
		return RockHint.Done
	end
	if (data.Strength or 0) >= rock.StrengthRequired then
		return RockHint.Chop
	end
	if stage == RockHint.Locked and AuraHint.StageOf(data) ~= AuraHint.Done then
		return stage
	end
	return RockHint.Train
end

function RockHint.IsShown(data: any): boolean
	if not RockHint.IsActive(RockHint.StageOf(data)) or type(data) ~= "table" then
		return false
	end
	return not Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
end

return table.freeze(RockHint)
