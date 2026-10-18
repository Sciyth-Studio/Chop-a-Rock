--!strict

export type ArmVisual = {
	Material: Enum.Material?,
	Color: Color3?,
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
			},
		},
		{
			Key = "Wood",
			DisplayName = "Wood Arms",
			Price = 150,
			TrainingGainMultiplier = 1.25,
			Visual = {
				Material = Enum.Material.Wood,
				Color = Color3.fromRGB(170, 100, 40),
			},
		},
		{
			Key = "Stone",
			DisplayName = "Stone Arms",
			Price = 2400,
			TrainingGainMultiplier = 1.5,
			Visual = {
				Material = Enum.Material.Granite,
				Color = Color3.fromRGB(160, 160, 170),
			},
		},
		{
			Key = "Iron",
			DisplayName = "Iron Arms",
			Price = 19200,
			TrainingGainMultiplier = 2.0,
			Visual = {
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(190, 195, 210),
			},
		},
		{
			Key = "Crystal",
			DisplayName = "Crystal Arms",
			Price = 153600,
			TrainingGainMultiplier = 2.5,
			Visual = {
				Material = Enum.Material.Glass,
				Color = Color3.fromRGB(0, 255, 255),
			},
		},
	} :: { ArmTier },
}

return table.freeze(ArmConfig)
