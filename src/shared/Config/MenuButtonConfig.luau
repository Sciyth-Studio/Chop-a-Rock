--!strict

export type MenuButton = {
	Name: string,
	Screen: string,
}

export type MenuButtonSettings = {
	ButtonSuffix: string,
	ClickButtonName: string,
	Buttons: { MenuButton },
	Badge: {
		Buttons: { string },
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
	Buttons = {
		{ Name = "Shop", Screen = "RobuxShop" },
		{ Name = "Index", Screen = "Index" },
		{ Name = "Rebirth", Screen = "Rebirth" },
	},
	Badge = {
		Buttons = { "Index", "Rebirth" },
		BadgeName = "Badge",
		LabelName = "Mark",
		Symbol = "!",
		WiggleEverySeconds = 3,
		WiggleDegrees = { -16, 14, -10, 6, 0 },
		WiggleStepSeconds = 0.08,
	},
}

return table.freeze(MenuButtonConfig)
