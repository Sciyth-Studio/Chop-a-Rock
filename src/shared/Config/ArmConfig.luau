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
		{
			Key = "Tier3",
			DisplayName = "Iron Arms",
			Price = 800,
			TrainingGainMultiplier = 4.0,
			Visual = {
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(190, 195, 210),
				EffectColor = Color3.fromRGB(180, 220, 255),
				EffectRate = 20,
			},
		},
		{
			Key = "Tier4",
			DisplayName = "Crystal Arms",
			Price = 6400,
			TrainingGainMultiplier = 8.0,
			Visual = {
				Material = Enum.Material.Glass,
				Color = Color3.fromRGB(0, 255, 255),
				EffectColor = Color3.fromRGB(0, 255, 255),
				EffectRate = 30,
			},
		},
		{
			Key = "Tier5",
			DisplayName = "Molten Arms",
			Price = 51200,
			TrainingGainMultiplier = 16.0,
			Visual = {
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 80, 0),
				EffectColor = Color3.fromRGB(255, 0, 0),
				EffectRate = 45,
			},
		},
	} :: { ArmTier },
}

return table.freeze(ArmConfig)
