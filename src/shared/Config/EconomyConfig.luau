--!strict

export type EconomySettings = {
	CurrencyName: string,
	StartingWallet: number,
	OfflineCapSeconds: number,
	MoneyGainColor: Color3,
	MoneyLossColor: Color3,
	MoneyDeltaTravelSeconds: number,
	MoneyDeltaGapPixels: number,
}

local EconomyConfig: EconomySettings = {
	CurrencyName = "Money",
	StartingWallet = 0,
	OfflineCapSeconds = 4 * 3600,
	MoneyGainColor = Color3.fromRGB(0, 255, 0),
	MoneyLossColor = Color3.fromRGB(255, 0, 0),
	MoneyDeltaTravelSeconds = 0.6,
	MoneyDeltaGapPixels = 12,
}

return table.freeze(EconomyConfig)
