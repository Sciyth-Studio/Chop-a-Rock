--!strict

export type NumberTickerSettings = {
	MinSeconds: number,
	MaxSeconds: number,
	SecondsPerDecade: number,
	EasePower: number,
}

local NumberTickerConfig: NumberTickerSettings = {
	MinSeconds = 0.3,
	MaxSeconds = 0.6,
	SecondsPerDecade = 0.1,
	EasePower = 3,
}

return table.freeze(NumberTickerConfig)
