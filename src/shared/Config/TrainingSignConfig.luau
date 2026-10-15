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
	RebirthIconName: string,
	RobuxButtonName: string,
	RobuxLabelName: string,
	RobuxIconName: string,
	TitleText: string,
	MaxText: string,
	LevelsFormat: string,
	LockedFormat: string,
	Palette: {
		Affordable: ShopConfig.MeterColors,
		Unavailable: ShopConfig.MeterColors,
		Robux: ShopConfig.MeterColors,
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
	RebirthIconName = "RebirthIcon",
	RobuxButtonName = "RobuxButton",
	RobuxLabelName = "Label",
	RobuxIconName = "RobuxIcon",
	TitleText = "Upgrade",
	MaxText = "Max Level",
	LevelsFormat = "%s > %s",
	LockedFormat = "Rebirth %d",
	Palette = {
		Affordable = ShopConfig.Palette.Green,
		Unavailable = ShopConfig.Palette.Grey,
		Robux = {
			Edge = Color3.fromRGB(150, 0, 255),
			Center = Color3.fromRGB(220, 150, 255),
			Studs = Color3.fromRGB(90, 0, 160),
		},
	},
	Messages = {
		Cash = "Not enough cash",
		Locked = "Rebirth %d to unlock %s Training",
		Max = "Your training is maxed out",
		RobuxSoon = "Robux upgrades are coming soon",
		Failed = "Upgrade failed, try again",
	},
	UpgradedFormat = "%s Training unlocked!",
	UpgradedKind = "Unlock",
	ErrorKind = "Error",
	UpgradedSound = "SFX_Level_Up",
}

return table.freeze(TrainingSignConfig)
