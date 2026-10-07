--!strict

export type LevelSettings = {
	LevelBaseStrength: number,
	LevelGrowth: number,
	LevelWord: string,
	FillTweenSeconds: number,
	LevelUpEffectKey: string,
	LevelUpSoundKey: string,
	LevelUpSoundStartSeconds: number,
}

local LevelConfig: LevelSettings = {
	LevelBaseStrength = 2,
	LevelGrowth = 1.35,
	LevelWord = "Lvl",
	FillTweenSeconds = 0.25,
	LevelUpEffectKey = "VFX_LevelUp",
	LevelUpSoundKey = "SFX_Level_Up",
	LevelUpSoundStartSeconds = 0.3,
}

return table.freeze(LevelConfig)
