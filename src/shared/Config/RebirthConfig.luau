--!strict

export type Rebirth = {
	LevelRequired: number,
	CashMultiplier: number,
	StrengthMultiplier: number,
}

export type RebirthSettings = {
	Rebirths: { Rebirth },
	ResetCash: boolean,
	ResetStrength: boolean,
	ResetArmTier: boolean,
	SkipRobuxPrice: number,
}

local RebirthConfig: RebirthSettings = {
	Rebirths = {
		{
			LevelRequired = 12,
			CashMultiplier = 2,
			StrengthMultiplier = 2,
		},
	},
	ResetCash = true,
	ResetStrength = true,
	ResetArmTier = false,
	SkipRobuxPrice = 25,
}

return table.freeze(RebirthConfig)
