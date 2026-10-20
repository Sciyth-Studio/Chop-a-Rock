--!strict

export type AuraTier = {
	Key: string,
	DisplayName: string,
	Price: number,
	TrainingGainMultiplier: number,
	WalkSpeedBonus: number,
	Color: Color3?,
}

export type AuraSettings = {
	SpeedSource: string,
	Attribute: string,
	AssetKey: string,
	TintAttribute: string,
	LimbParts: { string },
	BodyPart: string,
	LimbTemplate: string,
	BodyTemplate: string,
	SpinAttribute: string,
	Tiers: { AuraTier },
}

local AuraConfig: AuraSettings = {
	SpeedSource = "Aura",
	Attribute = "AuraTier",
	AssetKey = "VFX_Aura",
	TintAttribute = "Tint",
	LimbParts = { "LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg" },
	BodyPart = "HumanoidRootPart",
	LimbTemplate = "Limb",
	BodyTemplate = "Body",
	SpinAttribute = "SpinDegreesPerSecond",
	Tiers = {
		{
			Key = "None",
			DisplayName = "No Aura",
			Price = 0,
			TrainingGainMultiplier = 1.0,
			WalkSpeedBonus = 0,
		},
		{
			Key = "Silver",
			DisplayName = "Silver Aura",
			Price = 150,
			TrainingGainMultiplier = 1.25,
			WalkSpeedBonus = 2,
			Color = Color3.fromRGB(200, 205, 215),
		},
		{
			Key = "Green",
			DisplayName = "Green Aura",
			Price = 2400,
			TrainingGainMultiplier = 1.5,
			WalkSpeedBonus = 4,
			Color = Color3.fromRGB(0, 255, 0),
		},
		{
			Key = "Lime",
			DisplayName = "Lime Aura",
			Price = 19200,
			TrainingGainMultiplier = 2.0,
			WalkSpeedBonus = 6,
			Color = Color3.fromRGB(150, 255, 0),
		},
		{
			Key = "Yellow",
			DisplayName = "Yellow Aura",
			Price = 153600,
			TrainingGainMultiplier = 2.5,
			WalkSpeedBonus = 8,
			Color = Color3.fromRGB(255, 255, 0),
		},
	},
}

return table.freeze(AuraConfig)
