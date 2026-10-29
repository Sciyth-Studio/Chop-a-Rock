--!strict

export type CashFlow = {
	Type: string,
	Sku: string,
}

export type Funnel = {
	Name: string,
	Steps: { [string]: number },
	StepNames: { string },
}

export type AnalyticsSettings = {
	Currency: string,
	SkuSeparator: string,
	Sources: { [string]: CashFlow },
	Sinks: { [string]: CashFlow },
	RobuxShopFunnel: Funnel,
	PromptKinds: { string },
}

local gameplay = Enum.AnalyticsEconomyTransactionType.Gameplay.Name
local shop = Enum.AnalyticsEconomyTransactionType.Shop.Name
local purchase = Enum.AnalyticsEconomyTransactionType.IAP.Name
local reward = Enum.AnalyticsEconomyTransactionType.TimedReward.Name

local AnalyticsConfig: AnalyticsSettings = {
	Currency = "Cash",
	SkuSeparator = ":",
	Sources = {
		Chop = table.freeze({ Type = gameplay, Sku = "Chop" }),
		StormRock = table.freeze({ Type = gameplay, Sku = "StormRock" }),
		RushRock = table.freeze({ Type = gameplay, Sku = "RushRock" }),
		DiamondRock = table.freeze({ Type = gameplay, Sku = "DiamondRock" }),
		Pad = table.freeze({ Type = gameplay, Sku = "Pad" }),
		Offline = table.freeze({ Type = reward, Sku = "Offline" }),
		SellRoks = table.freeze({ Type = shop, Sku = "SellRoks" }),
		IndexClaim = table.freeze({ Type = gameplay, Sku = "IndexClaim" }),
		CashPack = table.freeze({ Type = purchase, Sku = "CashPack" }),
		GiftCashPack = table.freeze({ Type = purchase, Sku = "GiftCashPack" }),
		StarterPack = table.freeze({ Type = purchase, Sku = "StarterPack" }),
		OfflineClaim = table.freeze({ Type = purchase, Sku = "OfflineClaim" }),
		FreeGift = table.freeze({ Type = reward, Sku = "FreeGift" }),
	},
	Sinks = {
		Aura = table.freeze({ Type = shop, Sku = "Aura" }),
		Geode = table.freeze({ Type = shop, Sku = "Geode" }),
		Cannon = table.freeze({ Type = shop, Sku = "Cannon" }),
		PedestalSlot = table.freeze({ Type = shop, Sku = "PedestalSlot" }),
		TrainingUpgrade = table.freeze({ Type = shop, Sku = "TrainingUpgrade" }),
		Rebirth = table.freeze({ Type = gameplay, Sku = "Rebirth" }),
	},
	RobuxShopFunnel = {
		Name = "RobuxShop",
		Steps = table.freeze({ Opened = 1, Prompted = 2, Purchased = 3 }),
		StepNames = table.freeze({ "Opened", "Prompted", "Purchased" }),
	},
	PromptKinds = { "Product", "Pass" },
}

table.freeze(AnalyticsConfig.Sources)
table.freeze(AnalyticsConfig.Sinks)
table.freeze(AnalyticsConfig.RobuxShopFunnel)
table.freeze(AnalyticsConfig.PromptKinds)

return table.freeze(AnalyticsConfig)
