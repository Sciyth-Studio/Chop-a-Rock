--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

local CannonHint = {
	Locked = 0,
	Save = 1,
	Buy = 2,
	Fire = 3,
	Done = 4,
}

local settings = TutorialConfig.CannonHint

function CannonHint.Cannon(): CannonConfig.Cannon?
	for _, cannon in CannonConfig.Cannons do
		if cannon.Key == settings.Cannon then
			return cannon
		end
	end
	return nil
end

local function hints(data: any): { [string]: any }
	local value = if type(data) == "table" then data.Hints else nil
	return if type(value) == "table" then value else {}
end

function CannonHint.StageOf(data: any): number
	local stage = hints(data)[settings.Key]
	return if type(stage) == "number" then stage else CannonHint.Locked
end

function CannonHint.FurthestOf(data: any): number
	local furthest = hints(data)[settings.FurthestKey]
	return if type(furthest) == "number" then furthest else CannonHint.Locked
end

function CannonHint.IsActive(stage: number): boolean
	return stage > CannonHint.Locked and stage < CannonHint.Done
end

function CannonHint.Decide(data: any): number
	local stage = CannonHint.StageOf(data)
	local cannon = CannonHint.Cannon()
	if stage == CannonHint.Done or not cannon or type(data) ~= "table" then
		return stage
	end
	if Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
		return stage
	end
	local strong = (data.Strength or 0) >= cannon.StrengthRequired
	if stage == CannonHint.Locked and ((data.Rebirths or 0) < settings.MinRebirths or not strong) then
		return stage
	end
	if type(data.Cannons) == "table" and data.Cannons[cannon.Key] then
		return CannonHint.Fire
	end
	return if (data.Cash or 0) >= cannon.Price then CannonHint.Buy else CannonHint.Save
end

function CannonHint.IsShown(data: any): boolean
	local stage = CannonHint.StageOf(data)
	local cannon = CannonHint.Cannon()
	if not CannonHint.IsActive(stage) or not cannon or type(data) ~= "table" then
		return false
	end
	if Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
		return false
	end
	return stage == CannonHint.Fire or (data.Strength or 0) >= cannon.StrengthRequired
end

return table.freeze(CannonHint)
