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
			Key = "Grass",
			DisplayName = "Grass Arms",
			Price = 0,
			TrainingGainMultiplier = 1.0,
			Visual = {
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(60, 200, 0),
				EffectRate = 0,
			},
		},
		{
			Key = "Wood",
			DisplayName = "Wood Arms",
			Price = 100,
			TrainingGainMultiplier = 2.0,
			Visual = {
				Material = Enum.Material.Wood,
				Color = Color3.fromRGB(170, 100, 40),
				EffectRate = 0,
			},
		},
		{
			Key = "Stone",
			DisplayName = "Stone Arms",
			Price = 800,
			TrainingGainMultiplier = 4.0,
			Visual = {
				Material = Enum.Material.Granite,
				Color = Color3.fromRGB(160, 160, 170),
				EffectColor = Color3.fromRGB(255, 140, 0),
				EffectRate = 14,
			},
		},
		{
			Key = "Iron",
			DisplayName = "Iron Arms",
			Price = 6400,
			TrainingGainMultiplier = 8.0,
			Visual = {
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(190, 195, 210),
				EffectColor = Color3.fromRGB(180, 220, 255),
				EffectRate = 22,
			},
		},
		{
			Key = "Crystal",
			DisplayName = "Crystal Arms",
			Price = 51200,
			TrainingGainMultiplier = 16.0,
			Visual = {
				Material = Enum.Material.Glass,
				Color = Color3.fromRGB(0, 255, 255),
				EffectColor = Color3.fromRGB(0, 255, 255),
				EffectRate = 35,
			},
		},
	} :: { ArmTier },
}

return table.freeze(ArmConfig)
