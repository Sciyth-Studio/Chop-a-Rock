--!strict

export type CelebrationSettings = {
	EffectKey: string,
	SoundKey: string,
	SoundStartSeconds: number,
}

local CelebrationConfig: CelebrationSettings = {
	EffectKey = "VFX_LevelUp",
	SoundKey = "SFX_Level_Up",
	SoundStartSeconds = 0.3,
}

return table.freeze(CelebrationConfig)
