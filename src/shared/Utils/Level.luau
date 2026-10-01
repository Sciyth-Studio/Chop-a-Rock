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

function Level.StrengthFor(level: number): number
	return LevelConfig.LevelBaseStrength * LevelConfig.LevelGrowth ^ (level - 1)
end

function Level.FromStrength(strength: number): Progress
	local level = 1
	if strength >= LevelConfig.LevelBaseStrength then
		level = math.floor(math.log(strength / LevelConfig.LevelBaseStrength, LevelConfig.LevelGrowth)) + 1
		while Level.StrengthFor(level + 1) <= strength do
			level += 1
		end
		while level > 1 and Level.StrengthFor(level) > strength do
			level -= 1
		end
	end
	local lower = if level == 1 then 0 else Level.StrengthFor(level)
	local upper = Level.StrengthFor(level + 1)
	return {
		Level = level,
		Ratio = math.clamp((strength - lower) / (upper - lower), 0, 1),
		Current = strength - lower,
		Needed = upper - lower,
	}
end

return Level
