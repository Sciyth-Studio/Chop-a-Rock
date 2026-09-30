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
	ButtonSizePixels: number,
	ButtonGapPixels: number,
	Buttons: { MenuButton },
}

local MenuButtonConfig: MenuButtonSettings = {
	ButtonSuffix = "Button",
	ClickButtonName = "Button",
	ContainerName = "Container",
	LayoutStoreName = "LayoutStore",
	PhoneLayoutName = "PhoneLayout",
	PhoneMaxShortSidePixels = 600,
	PhoneColumns = 2,
	ButtonSizePixels = 96,
	ButtonGapPixels = 12,
	Buttons = {
		{ Name = "Shop", Screen = "Shop" },
		{ Name = "Bag", Screen = "Bag" },
		{ Name = "Index", Screen = "Index" },
		{ Name = "Rebirth", Screen = "Rebirth" },
	},
}

return table.freeze(MenuButtonConfig)
