--!strict

export type UpgradeAlertSettings = {
	Image: string,
	SizeStuds: number,
	HeightStuds: number,
	MaxDistance: number,
	WiggleDegrees: number,
	WiggleSpeed: number,
	BobStuds: number,
	BobSpeed: number,
	CheckSeconds: number,
	NotifyKind: string,
	AuraShopName: string,
	CannonShopName: string,
	CannonScreen: string,
	AuraText: string,
	TrainingText: string,
}

local UpgradeAlertConfig: UpgradeAlertSettings = {
	Image = "rbxassetid://77562065252330",
	SizeStuds = 4,
	HeightStuds = 2.5,
	MaxDistance = 250,
	WiggleDegrees = 12,
	WiggleSpeed = 9,
	BobStuds = 0.4,
	BobSpeed = 3,
	CheckSeconds = 0.25,
	NotifyKind = "Unlock",
	AuraShopName = "AuraShop",
	CannonShopName = "CannonShop",
	CannonScreen = "CannonShop",
	AuraText = "%s ready to buy!",
	TrainingText = "%s stand ready!",
}

return table.freeze(UpgradeAlertConfig)
