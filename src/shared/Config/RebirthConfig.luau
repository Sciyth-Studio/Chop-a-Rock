--!strict

export type Rebirth = {
	StrengthRequired: number,
	CashMultiplier: number,
	LuckBonus: number,
}

export type RebirthSettings = {
	BaseStrengthRequired: number,
	StrengthGrowth: number,
	BaseMultiplier: number,
	MultiplierPerRebirth: number,
	MaxAdminRebirths: number,
	ResetCash: boolean,
	ResetStrength: boolean,
	ResetAuraTier: boolean,
	RebirthEffectKey: string,
	RebirthSoundKey: string,
	RebirthSoundStartSeconds: number,
}

local RebirthConfig: RebirthSettings = {
	BaseStrengthRequired = 100,
	StrengthGrowth = 125,
	BaseMultiplier = 1,
	MultiplierPerRebirth = 0.25,
	MaxAdminRebirths = 100,
	ResetCash = true,
	ResetStrength = true,
	ResetAuraTier = false,
	RebirthEffectKey = "VFX_LevelUp",
	RebirthSoundKey = "SFX_Level_Up",
	RebirthSoundStartSeconds = 0.3,
}

return table.freeze(RebirthConfig)
