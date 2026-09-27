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
	ShakeDurationSeconds: number,
	SloppyShakeIntensity: number,
	GoodShakeIntensity: number,
	PerfectShakeIntensity: number,
	DamageNumberRiseSeconds: number,
	DamageNumberRiseStuds: number,
	DamageNumberStartOffset: Vector3,
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
	ShakeDurationSeconds = 0.15,
	SloppyShakeIntensity = 0.25,
	GoodShakeIntensity = 0.7,
	PerfectShakeIntensity = 1.4,
	DamageNumberRiseSeconds = 0.9,
	DamageNumberRiseStuds = 5,
	DamageNumberStartOffset = Vector3.new(0, 2, 0),
}

return table.freeze(ChopConfig)
