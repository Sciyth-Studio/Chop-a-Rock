--!strict

export type MenuButton = {
	Name: string,
	Screen: string,
}

export type MenuButtonSettings = {
	ButtonSuffix: string,
	ClickButtonName: string,
	ContainerName: string,
	LayoutStoreName: string,
	PhoneLayoutName: string,
	PhoneMaxShortSidePixels: number,
	PhoneColumns: number,
	PhoneTopPixels: number,
	ButtonSizePixels: number,
	ButtonGapPixels: number,
	Buttons: { MenuButton },
	IndexBadge: {
		Button: string,
		BadgeName: string,
		LabelName: string,
		Symbol: string,
		WiggleEverySeconds: number,
		WiggleDegrees: { number },
		WiggleStepSeconds: number,
	},
}

local MenuButtonConfig: MenuButtonSettings = {
	ButtonSuffix = "Button",
	ClickButtonName = "Button",
	ContainerName = "Container",
	LayoutStoreName = "LayoutStore",
	PhoneLayoutName = "PhoneLayout",
	PhoneMaxShortSidePixels = 600,
	PhoneColumns = 4,
	PhoneTopPixels = 8,
	ButtonSizePixels = 96,
	ButtonGapPixels = 16,
	Buttons = {
		{ Name = "Shop", Screen = "RobuxShop" },
		{ Name = "Roks", Screen = "Roks" },
		{ Name = "Index", Screen = "Index" },
		{ Name = "Rebirth", Screen = "Rebirth" },
	},
	IndexBadge = {
		Button = "Index",
		BadgeName = "Badge",
		LabelName = "Mark",
		Symbol = "!",
		WiggleEverySeconds = 3,
		WiggleDegrees = { -16, 14, -10, 6, 0 },
		WiggleStepSeconds = 0.08,
	},
}

return table.freeze(MenuButtonConfig)
