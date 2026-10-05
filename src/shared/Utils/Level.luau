--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelConfig = require(ReplicatedStorage.Config.LevelConfig)

export type Progress = {
	Level: number,
	Ratio: number,
	Current: number,
	Needed: number,
}

local Level = {}

function Level.NeededFor(level: number): number
	return math.round(LevelConfig.LevelBaseStrength * LevelConfig.LevelGrowth ^ (level - 1))
end

function Level.StrengthFor(level: number): number
	local total = 0
	for previous = 1, level - 1 do
		total += Level.NeededFor(previous)
	end
	return total
end

function Level.FromStrength(strength: number): Progress
	if strength ~= strength or strength == math.huge then
		strength = 0
	end
	local level = 1
	local lower = 0
	local needed = Level.NeededFor(level)
	while strength >= lower + needed do
		lower += needed
		level += 1
		needed = Level.NeededFor(level)
	end
	return {
		Level = level,
		Ratio = math.clamp((strength - lower) / needed, 0, 1),
		Current = strength - lower,
		Needed = needed,
	}
end

return Level
