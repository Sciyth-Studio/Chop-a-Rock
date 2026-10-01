--!strict

export type LevelSettings = {
	LevelBaseStrength: number,
	LevelGrowth: number,
	LevelWord: string,
	FillTweenSeconds: number,
}

local LevelConfig: LevelSettings = {
	LevelBaseStrength = 1,
	LevelGrowth = 1.5,
	LevelWord = "LVL",
	FillTweenSeconds = 0.25,
}

return table.freeze(LevelConfig)
