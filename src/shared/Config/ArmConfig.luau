--!strict

export type ArmVisual = {
	Material: Enum.Material?,
	Color: Color3?,
	EffectColor: Color3?,
	EffectRate: number,
}

export type ArmTier = {
	Key: string,
	DisplayName: string,
	Price: number,
	TrainingGainMultiplier: number,
	Visual: ArmVisual,
}

local ArmConfig = {
	Tiers = {
		{
			Key = "Base",
			DisplayName = "Base Arms",
			Price = 0,
			TrainingGainMultiplier = 1.0,
			Visual = {
				EffectRate = 0,
			},
		},
		{
			Key = "Tier2",
			DisplayName = "Tier 2 Arms",
			Price = 100,
			TrainingGainMultiplier = 2.0,
			Visual = {
				Material = Enum.Material.Granite,
				Color = Color3.fromRGB(160, 160, 170),
				EffectColor = Color3.fromRGB(255, 140, 0),
				EffectRate = 14,
			},
		},
	} :: { ArmTier },
}

return table.freeze(ArmConfig)
