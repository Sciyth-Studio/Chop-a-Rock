--!strict

export type Rebirth = {
	LevelRequired: number,
	CashMultiplier: number,
	StrengthMultiplier: number,
	LuckBonus: number,
}

export type RebirthSettings = {
	BaseLevelRequired: number,
	LevelStep: number,
	BaseMultiplier: number,
	MultiplierPerRebirth: number,
	MaxAdminRebirths: number,
	ResetCash: boolean,
	ResetStrength: boolean,
	ResetArmTier: boolean,
	SkipRobuxPrice: number,
}

local RebirthConfig: RebirthSettings = {
	BaseLevelRequired = 12,
	LevelStep = 4,
	BaseMultiplier = 1,
	MultiplierPerRebirth = 1,
	MaxAdminRebirths = 100,
	ResetCash = true,
	ResetStrength = true,
	ResetArmTier = false,
	SkipRobuxPrice = 25,
}

return table.freeze(RebirthConfig)
