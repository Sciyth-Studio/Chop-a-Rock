--!strict

local ShopConfig = require(script.Parent.ShopConfig)

export type Level = {
	Price: number,
	PenSlots: number,
	HatchMultiplier: number,
}

export type BaseUpgradeSettings = {
	Levels: { Level },
	PenLevelsName: string,
	PenLevelFormat: string,
	ActivePenName: string,
	StorageName: string,
	OwnerSpotName: string,
	OwnerSpotGapStuds: number,
	FloorPartName: string,
	Sign: {
		Tag: string,
		PlotTag: string,
		OwnerAttribute: string,
		TitleName: string,
		LevelsName: string,
		CashButtonName: string,
		CashLabelName: string,
		CashIconName: string,
		TitleText: string,
		LevelsFormat: string,
		MaxText: string,
		Palette: {
			Affordable: ShopConfig.MeterColors,
			Unavailable: ShopConfig.MeterColors,
		},
	},
	Messages: { [string]: string },
	UpgradedFormat: string,
	UpgradedKind: string,
	ErrorKind: string,
	UpgradedSound: string,
}

local BaseUpgradeConfig: BaseUpgradeSettings = {
	Levels = {
		{ Price = 0, PenSlots = 8, HatchMultiplier = 1 },
		{ Price = 500000, PenSlots = 9, HatchMultiplier = 0.95 },
		{ Price = 40000000, PenSlots = 10, HatchMultiplier = 0.9 },
		{ Price = 3000000000, PenSlots = 11, HatchMultiplier = 0.85 },
		{ Price = 200000000000, PenSlots = 12, HatchMultiplier = 0.8 },
		{ Price = 15000000000000, PenSlots = 13, HatchMultiplier = 0.75 },
		{ Price = 1e15, PenSlots = 14, HatchMultiplier = 0.7 },
		{ Price = 6e16, PenSlots = 15, HatchMultiplier = 0.65 },
	},
	PenLevelsName = "PenLevels",
	PenLevelFormat = "Level%d",
	ActivePenName = "Pen",
	StorageName = "BasePenLevels",
	OwnerSpotName = "OwnerSpot",
	OwnerSpotGapStuds = 0.5,
	FloorPartName = "BasePlot_Floor",
	Sign = {
		Tag = "BaseUpgradeSign",
		PlotTag = "BasePlot",
		OwnerAttribute = "OwnerUserId",
		TitleName = "Title",
		LevelsName = "Levels",
		CashButtonName = "CashButton",
		CashLabelName = "Label",
		CashIconName = "Icon",
		TitleText = "Upgrade Base",
		LevelsFormat = "Level %d > Level %d",
		MaxText = "Max Level",
		Palette = {
			Affordable = ShopConfig.Palette.Green,
			Unavailable = ShopConfig.Palette.Grey,
		},
	},
	Messages = {
		Cash = "Not enough cash",
		Max = "Base maxed!",
		Failed = "Try again!",
	},
	UpgradedFormat = "Base Level %d! Bigger pen, +1 Pet slot, faster hatching",
	UpgradedKind = "Unlock",
	ErrorKind = "Error",
	UpgradedSound = "SFX_Level_Up",
}

return table.freeze(BaseUpgradeConfig)
