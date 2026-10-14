--!strict

export type RokMotionSettings = {
	Tag: string,
	PlacedAtAttribute: string,
	EyePartSuffixes: { string },
	CullDistanceStuds: number,
	BreathePeriodSeconds: number,
	BreatheAmount: number,
	BlinkIntervalMinSeconds: number,
	BlinkIntervalMaxSeconds: number,
	BlinkSeconds: number,
	BlinkClosedScale: number,
	LandWindowSeconds: number,
	DropHeightStuds: number,
	DropSeconds: number,
	DropStretch: number,
	LandSquash: number,
	LandSeconds: number,
	LandBounces: number,
}

local RokMotionConfig: RokMotionSettings = {
	Tag = "IdleRok",
	PlacedAtAttribute = "PlacedAt",
	EyePartSuffixes = { "_Eyes", "_Pupils" },
	CullDistanceStuds = 100,
	BreathePeriodSeconds = 2.4,
	BreatheAmount = 0.04,
	BlinkIntervalMinSeconds = 2.5,
	BlinkIntervalMaxSeconds = 6,
	BlinkSeconds = 0.16,
	BlinkClosedScale = 0.1,
	LandWindowSeconds = 1,
	DropHeightStuds = 3,
	DropSeconds = 0.22,
	DropStretch = 0.15,
	LandSquash = 0.25,
	LandSeconds = 0.5,
	LandBounces = 1.5,
}

return table.freeze(RokMotionConfig)
