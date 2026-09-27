--!strict

export type ChopSettings = {
	CycleSeconds: number,
	GoodThreshold: number,
	PerfectThreshold: number,
	LatencyCompensationSeconds: number,
	SloppyPayoutMultiplier: number,
	GoodPayoutMultiplier: number,
	PerfectPayoutMultiplier: number,
	CameraOffsetFromRock: Vector3,
	CameraLookOffset: Vector3,
	PlayerSnapOffsetFromRock: Vector3,
}

local ChopConfig: ChopSettings = {
	CycleSeconds = 1.5,
	GoodThreshold = 0.70,
	PerfectThreshold = 0.94,
	LatencyCompensationSeconds = 0.05,
	SloppyPayoutMultiplier = 0.4,
	GoodPayoutMultiplier = 1.0,
	PerfectPayoutMultiplier = 1.75,
	CameraOffsetFromRock = Vector3.new(0, 8, -14),
	CameraLookOffset = Vector3.new(0, 0, 0),
	PlayerSnapOffsetFromRock = Vector3.new(0, 0, -8),
}

return table.freeze(ChopConfig)
