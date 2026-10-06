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
		MaxShown: number,
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
	ButtonGapPixels = 12,
	Buttons = {
		{ Name = "Shop", Screen = "Shop" },
		{ Name = "Roks", Screen = "Roks" },
		{ Name = "Index", Screen = "Index" },
		{ Name = "Rebirth", Screen = "Rebirth" },
	},
	IndexBadge = {
		Button = "Index",
		BadgeName = "Badge",
		LabelName = "Mark",
		MaxShown = 9,
	},
}

return table.freeze(MenuButtonConfig)
