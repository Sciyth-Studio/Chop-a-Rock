--!strict

local ShopConfig = require(script.Parent.ShopConfig)

export type TrainingSignSettings = {
	Tag: string,
	PlotTag: string,
	OwnerAttribute: string,
	TitleName: string,
	LevelsName: string,
	CashButtonName: string,
	CashLabelName: string,
	CashIconName: string,
	TitleText: string,
	MaxText: string,
	LevelsFormat: string,
	Palette: {
		Affordable: ShopConfig.MeterColors,
		Unavailable: ShopConfig.MeterColors,
	},
	Messages: { [string]: string },
	UpgradedFormat: string,
	UpgradedKind: string,
	ErrorKind: string,
	UpgradedSound: string,
}

local TrainingSignConfig: TrainingSignSettings = {
	Tag = "TrainingUpgradeSign",
	PlotTag = "BasePlot",
	OwnerAttribute = "OwnerUserId",
	TitleName = "Title",
	LevelsName = "Levels",
	CashButtonName = "CashButton",
	CashLabelName = "Label",
	CashIconName = "Icon",
	TitleText = "Upgrade",
	MaxText = "Max Level",
	LevelsFormat = "%s > %s",
	Palette = {
		Affordable = ShopConfig.Palette.Green,
		Unavailable = ShopConfig.Palette.Grey,
	},
	Messages = {
		Cash = "Not enough cash",
		Max = "Training maxed!",
		Failed = "Try again!",
	},
	UpgradedFormat = "%s Training unlocked!",
	UpgradedKind = "Unlock",
	ErrorKind = "Error",
	UpgradedSound = "SFX_Level_Up",
}

return table.freeze(TrainingSignConfig)
