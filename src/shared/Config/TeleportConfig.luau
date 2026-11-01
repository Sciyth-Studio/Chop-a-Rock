--!strict

export type Destination = {
	Id: string,
	Label: string,
	IsBase: boolean,
	Marker: string,
}

export type TeleportSettings = {
	CooldownSeconds: number,
	PointsFolderName: string,
	BaseSpawnName: string,
	RevealingMessage: string,
	ButtonSuffix: string,
	ClickButtonName: string,
	ContainerName: string,
	BarWidthPixels: number,
	StreamTimeoutSeconds: number,
	PillGapPixels: number,
	PillScreenName: string,
	Destinations: { Destination },
	ShopFan: {
		Button: string,
		FanName: string,
		OptionSuffix: string,
		PopScaleName: string,
		Options: { string },
		Columns: number,
		GapScale: number,
		SpacingScale: number,
		ColumnSpacingScale: number,
		StaggerSeconds: number,
		OpenSeconds: number,
		CloseSeconds: number,
	},
}

local TeleportConfig: TeleportSettings = {
	CooldownSeconds = 0.2,
	PointsFolderName = "TeleportPoints",
	BaseSpawnName = "BaseSpawn",
	RevealingMessage = "Wait for the reveal",
	ButtonSuffix = "Button",
	ClickButtonName = "Button",
	ContainerName = "Container",
	BarWidthPixels = 645,
	StreamTimeoutSeconds = 2,
	PillGapPixels = 8,
	PillScreenName = "DiamondRockPill",
	Destinations = {
		{ Id = "Base", Label = "Base", IsBase = true, Marker = "" },
		{ Id = "Aura", Label = "Aura", IsBase = false, Marker = "AuraShop" },
		{ Id = "Sell", Label = "Sell", IsBase = false, Marker = "SellShop" },
		{ Id = "Geode", Label = "Geode", IsBase = false, Marker = "GeodeShop" },
		{ Id = "Cannon", Label = "Cannon", IsBase = false, Marker = "CannonShop" },
		{ Id = "Rocks", Label = "Rocks", IsBase = false, Marker = "Rocks" },
	},
	ShopFan = {
		Button = "Shops",
		FanName = "ShopFan",
		OptionSuffix = "Option",
		PopScaleName = "PopScale",
		Options = { "Aura", "Cannon", "Sell", "Geode" },
		Columns = 2,
		GapScale = 0.15,
		SpacingScale = 0.95,
		ColumnSpacingScale = 1.08,
		StaggerSeconds = 0.04,
		OpenSeconds = 0.28,
		CloseSeconds = 0.14,
	},
}

return table.freeze(TeleportConfig)
