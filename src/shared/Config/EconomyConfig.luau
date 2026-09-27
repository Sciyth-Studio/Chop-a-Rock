--!strict

export type EconomySettings = {
	CurrencyName: string,
	StartingWallet: number,
	OfflineCapSeconds: number,
}

local EconomyConfig: EconomySettings = {
	CurrencyName = "Money",
	StartingWallet = 0,
	OfflineCapSeconds = 4 * 3600,
}

return table.freeze(EconomyConfig)
