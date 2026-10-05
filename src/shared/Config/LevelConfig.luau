--!strict

export type LevelSettings = {
	LevelBaseStrength: number,
	LevelGrowth: number,
	LevelWord: string,
	FillTweenSeconds: number,
}

local LevelConfig: LevelSettings = {
	LevelBaseStrength = 2,
	LevelGrowth = 1.35,
	LevelWord = "Lvl",
	FillTweenSeconds = 0.25,
}

return table.freeze(LevelConfig)
