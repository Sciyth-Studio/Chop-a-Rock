--!strict

export type TextStyle = {
	LightColor: Color3,
	DarkColor: Color3,
	StrokeColor: Color3,
}

export type EconomySettings = {
	CurrencyName: string,
	StartingWallet: number,
	OfflineCapSeconds: number,
	MoneyGainStyle: TextStyle,
	MoneyLossStyle: TextStyle,
	MoneyDeltaTravelSeconds: number,
	MoneyDeltaGapPixels: number,
}

local EconomyConfig: EconomySettings = {
	CurrencyName = "Money",
	StartingWallet = 0,
	OfflineCapSeconds = 2 * 3600,
	MoneyGainStyle = {
		LightColor = Color3.fromRGB(150, 255, 120),
		DarkColor = Color3.fromRGB(0, 190, 40),
		StrokeColor = Color3.fromRGB(0, 90, 20),
	},
	MoneyLossStyle = {
		LightColor = Color3.fromRGB(255, 150, 130),
		DarkColor = Color3.fromRGB(230, 0, 0),
		StrokeColor = Color3.fromRGB(110, 0, 0),
	},
	MoneyDeltaTravelSeconds = 0.6,
	MoneyDeltaGapPixels = 12,
}

return table.freeze(EconomyConfig)
