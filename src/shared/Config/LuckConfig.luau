--!strict

export type LuckSettings = {
	LuckyShareCap: number,
	GamepassMultiplier: number,
}

local LuckConfig: LuckSettings = {
	LuckyShareCap = 0.9,
	GamepassMultiplier = 2,
}

return table.freeze(LuckConfig)
