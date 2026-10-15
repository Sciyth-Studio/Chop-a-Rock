--!strict

export type Aura = {
	Key: string,
	DisplayName: string,
	Price: number,
	RebirthsRequired: number,
	WalkSpeedBonus: number,
	Color: Color3,
	AssetKey: string,
	Icon: string,
}

export type AuraSettings = {
	SpeedSource: string,
	Attribute: string,
	LimbParts: { string },
	BodyPart: string,
	LimbTemplate: string,
	BodyTemplate: string,
	SpinAttribute: string,
	Auras: { Aura },
}

local AuraConfig: AuraSettings = {
	SpeedSource = "Aura",
	Attribute = "Aura",
	LimbParts = { "LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg" },
	BodyPart = "HumanoidRootPart",
	LimbTemplate = "Limb",
	BodyTemplate = "Body",
	SpinAttribute = "SpinDegreesPerSecond",
	Auras = {
		{
			Key = "Leaf",
			DisplayName = "Leaf Aura",
			Price = 10000,
			RebirthsRequired = 1,
			WalkSpeedBonus = 10,
			Color = Color3.fromRGB(40, 255, 0),
			AssetKey = "VFX_Aura_Leaf",
			Icon = "rbxassetid://126076653128655",
		},
		{
			Key = "Wind",
			DisplayName = "Wind Aura",
			Price = 75000,
			RebirthsRequired = 2,
			WalkSpeedBonus = 20,
			Color = Color3.fromRGB(0, 230, 255),
			AssetKey = "VFX_Aura_Wind",
			Icon = "rbxassetid://127419173561611",
		},
		{
			Key = "Thunder",
			DisplayName = "Thunder Aura",
			Price = 400000,
			RebirthsRequired = 3,
			WalkSpeedBonus = 30,
			Color = Color3.fromRGB(255, 235, 0),
			AssetKey = "VFX_Aura_Thunder",
			Icon = "rbxassetid://127926369516073",
		},
		{
			Key = "Spirit",
			DisplayName = "Spirit Aura",
			Price = 2000000,
			RebirthsRequired = 4,
			WalkSpeedBonus = 40,
			Color = Color3.fromRGB(255, 0, 220),
			AssetKey = "VFX_Aura_Spirit",
			Icon = "rbxassetid://79636488922235",
		},
		{
			Key = "Dragon",
			DisplayName = "Dragon Aura",
			Price = 10000000,
			RebirthsRequired = 5,
			WalkSpeedBonus = 50,
			Color = Color3.fromRGB(255, 190, 0),
			AssetKey = "VFX_Aura_Dragon",
			Icon = "rbxassetid://98307052478401",
		},
	},
}

return table.freeze(AuraConfig)
