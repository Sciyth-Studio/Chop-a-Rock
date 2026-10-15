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
	PhoneMaxShortSidePixels: number,
	PhoneRightMarginPixels: number,
	PhoneMenuClearancePixels: number,
	BarWidthScale: number,
	StreamTimeoutSeconds: number,
	PillGapPixels: number,
	PillScreenName: string,
	Destinations: { Destination },
}

local TeleportConfig: TeleportSettings = {
	CooldownSeconds = 0.2,
	PointsFolderName = "TeleportPoints",
	BaseSpawnName = "BaseSpawn",
	RevealingMessage = "Wait for the reveal to finish",
	ButtonSuffix = "Button",
	ClickButtonName = "Button",
	ContainerName = "Container",
	PhoneMaxShortSidePixels = 600,
	PhoneRightMarginPixels = 16,
	PhoneMenuClearancePixels = 12,
	BarWidthScale = 0.336,
	StreamTimeoutSeconds = 2,
	PillGapPixels = 8,
	PillScreenName = "DiamondRockPill",
	Destinations = {
		{ Id = "Base", Label = "Base", IsBase = true, Marker = "" },
		{ Id = "Shops", Label = "Shops", IsBase = false, Marker = "Shops" },
		{ Id = "Rocks", Label = "Rocks", IsBase = false, Marker = "Rocks" },
	},
}

return table.freeze(TeleportConfig)
