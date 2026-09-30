--!strict

export type MenuButton = {
	Name: string,
	Screen: string,
}

export type MenuButtonSettings = {
	ButtonSuffix: string,
	ClickButtonName: string,
	Buttons: { MenuButton },
}

local MenuButtonConfig: MenuButtonSettings = {
	ButtonSuffix = "Button",
	ClickButtonName = "Button",
	Buttons = {
		{ Name = "Shop", Screen = "Shop" },
		{ Name = "Bag", Screen = "Bag" },
		{ Name = "Rebirth", Screen = "Rebirth" },
	},
}

return table.freeze(MenuButtonConfig)
