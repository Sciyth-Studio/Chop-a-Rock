--!strict

export type ChopSettings = {
	WindupSeconds: number,
	PerfectWindowCenter: number,
	PerfectWindowWidth: number,
	GoodWindowWidth: number,
	LatencyCompensationSeconds: number,
	SloppyPayoutMultiplier: number,
	GoodPayoutMultiplier: number,
	PerfectPayoutMultiplier: number,
}

local ChopConfig: ChopSettings = {
	WindupSeconds = 1.2,
	PerfectWindowCenter = 0.75,
	PerfectWindowWidth = 0.06,
	GoodWindowWidth = 0.24,
	LatencyCompensationSeconds = 0.08,
	SloppyPayoutMultiplier = 0.4,
	GoodPayoutMultiplier = 1.0,
	PerfectPayoutMultiplier = 1.75,
}

return table.freeze(ChopConfig)
