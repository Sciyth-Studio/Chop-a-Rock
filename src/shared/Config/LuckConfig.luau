--!strict

local ChopQuality = require(script.Parent.Parent.ChopQuality)

export type LuckSettings = {
	TimingBonusByQuality: { [number]: number },
	PerRebirthBonus: number,
	LuckyShareCap: number,
	GamepassId: number?,
	GamepassMultiplier: number,
}

local LuckConfig: LuckSettings = {
	TimingBonusByQuality = {
		[ChopQuality.Bad] = 0,
		[ChopQuality.Mid] = 0,
		[ChopQuality.Good] = 0.05,
		[ChopQuality.Great] = 0.15,
		[ChopQuality.Perfect] = 0.25,
		[ChopQuality.Master] = 1,
	},
	PerRebirthBonus = 0.1,
	LuckyShareCap = 0.9,
	GamepassId = nil,
	GamepassMultiplier = 2,
}

return table.freeze(LuckConfig)
