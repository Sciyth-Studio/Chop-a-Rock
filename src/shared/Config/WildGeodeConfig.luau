--!strict

export type WildGeodeSettings = {
	MinSeconds: number,
	MaxSeconds: number,
	ActiveWindowSeconds: number,
	MinRarity: string,
	SpotName: string,
	CleanupPaddingSeconds: number,
}

local WildGeodeConfig: WildGeodeSettings = {
	MinSeconds = 240,
	MaxSeconds = 360,
	ActiveWindowSeconds = 8,
	MinRarity = "Uncommon",
	SpotName = "WildGeodeSpot",
	CleanupPaddingSeconds = 1,
}

return table.freeze(WildGeodeConfig)
