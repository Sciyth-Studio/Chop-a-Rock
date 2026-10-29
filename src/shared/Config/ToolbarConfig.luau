--!strict

export type ToolbarSettings = {
	Screen: string,
	PanelScreen: string,
	SlotCount: number,
	SlotKeys: { Enum.KeyCode },
	IdleStroke: { Color: Color3, Thickness: number },
	HeldStroke: { Color: Color3, Thickness: number },
	PlacedStroke: { Color: Color3, Thickness: number },
	CountTextStyle: string,
	NameTextStyle: string,
	CountFormat: string,
	PlacedFormat: string,
	PlacedText: string,
}

local ToolbarConfig: ToolbarSettings = {
	Screen = "Toolbar",
	PanelScreen = "Roks",
	SlotCount = 7,
	SlotKeys = {
		Enum.KeyCode.One,
		Enum.KeyCode.Two,
		Enum.KeyCode.Three,
		Enum.KeyCode.Four,
		Enum.KeyCode.Five,
		Enum.KeyCode.Six,
		Enum.KeyCode.Seven,
	},
	IdleStroke = { Color = Color3.fromRGB(0, 0, 0), Thickness = 3 },
	HeldStroke = { Color = Color3.fromRGB(255, 255, 255), Thickness = 3 },
	PlacedStroke = { Color = Color3.fromRGB(0, 220, 60), Thickness = 3 },
	CountTextStyle = "Gold",
	NameTextStyle = "Green",
	CountFormat = "Roks: %d",
	PlacedFormat = "Placed: %d/%d",
	PlacedText = "Placed",
}

return table.freeze(ToolbarConfig)
