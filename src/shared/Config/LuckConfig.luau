--!strict

export type LuckSettings = {
	LuckyShareCap: number,
	GamepassMultiplier: number,
	LuckAttribute: string,
}

local LuckConfig: LuckSettings = {
	LuckyShareCap = 0.9,
	GamepassMultiplier = 2,
	LuckAttribute = "HatchLuck",
}

return table.freeze(LuckConfig)
