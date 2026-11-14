--!strict

local ShopConfig = require(script.Parent.ShopConfig)

export type Tab = {
	Key: string,
	Title: string,
	Icon: string,
	EmptyText: string,
	NoMatchText: string,
}

export type PetsSettings = {
	Palette: {
		Affordable: ShopConfig.MeterColors,
		Unavailable: ShopConfig.MeterColors,
	},
	Preview: {
		CameraDirection: Vector3,
		FieldOfView: number,
		CameraPadding: number,
	},
	EmptyText: string,
	NoMatchText: string,
	TabsName: string,
	TabPrefix: string,
	ActiveColorAttribute: string,
	IdleTabColor: Color3,
	Tabs: { Tab },
	PotionCountFormat: string,
	PotionTimeText: string,
	PotionStack: string,
}

local PetsConfig: PetsSettings = {
	Palette = {
		Affordable = ShopConfig.Palette.Green,
		Unavailable = ShopConfig.Palette.Grey,
	},
	Preview = {
		CameraDirection = Vector3.new(0.35, 0.3, -1),
		FieldOfView = 30,
		CameraPadding = 0.85,
	},
	EmptyText = "No Pets yet! Hatch an egg",
	NoMatchText = "No Pets found",
	TabsName = "Tabs",
	TabPrefix = "Tab",
	ActiveColorAttribute = "ActiveColor",
	IdleTabColor = Color3.fromRGB(70, 70, 76),
	Tabs = {
		{
			Key = "Pets",
			Title = "Pets",
			Icon = "rbxassetid://105543628272239",
			EmptyText = "No Pets yet! Hatch an egg",
			NoMatchText = "No Pets found",
		},
		{
			Key = "Eggs",
			Title = "Eggs",
			Icon = "rbxassetid://88606902814397",
			EmptyText = "No eggs! Chop rocks to find them",
			NoMatchText = "No eggs found",
		},
		{
			Key = "Potions",
			Title = "Potions",
			Icon = "rbxassetid://136122184424656",
			EmptyText = "No potions! Beat a boss to get some",
			NoMatchText = "No potions found",
		},
	},
	PotionCountFormat = "Potions: %d",
	PotionTimeText = "Lasts 10 min",
	PotionStack = "potion:",
}

return table.freeze(PetsConfig)
