--!strict

export type ArmTier = {
	Key: string,
	DisplayName: string,
	Price: number,
	TrainingGainMultiplier: number,
	VisualAssetKey: string,
}

local ArmConfig = {
	Tiers = {
		{
			Key = "Base",
			DisplayName = "Base Arms",
			Price = 0,
			TrainingGainMultiplier = 1.0,
			VisualAssetKey = "Model_Arm_Base",
		},
		{
			Key = "Tier2",
			DisplayName = "Tier 2 Arms",
			Price = 100,
			TrainingGainMultiplier = 2.0,
			VisualAssetKey = "Model_Arm_Tier2",
		},
	} :: { ArmTier },
}

return table.freeze(ArmConfig)
