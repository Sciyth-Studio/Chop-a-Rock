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
	ResetArmTier: boolean,
	SkipRobuxPrice: number,
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
	ResetArmTier = false,
	SkipRobuxPrice = 25,
	RebirthEffectKey = "VFX_LevelUp",
	RebirthSoundKey = "SFX_Level_Up",
	RebirthSoundStartSeconds = 0.3,
}

return table.freeze(RebirthConfig)
