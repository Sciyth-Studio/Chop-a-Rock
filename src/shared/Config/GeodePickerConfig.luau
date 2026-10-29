--!strict

export type GeodePickerSettings = {
	ScreenName: string,
	StepText: string,
	ChooseText: string,
	ChosenText: string,
	CountFormat: string,
	ZonePalette: string,
	LuckyPalette: string,
}

local GeodePickerConfig: GeodePickerSettings = {
	ScreenName = "GeodePicker",
	StepText = "Pick a geode to crack",
	ChooseText = "Choose",
	ChosenText = "Chosen",
	CountFormat = "x%d",
	ZonePalette = "Sky",
	LuckyPalette = "Gold",
}

return table.freeze(GeodePickerConfig)
