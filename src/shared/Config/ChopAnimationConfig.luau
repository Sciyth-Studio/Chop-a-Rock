--!strict

export type ChopAnimationSettings = {
	StrikeStartSeconds: number,
	StrikeImpactSeconds: number,
	StrikeHoldSeconds: number,
	StrikeEndMarginSeconds: number,
	StrikeSpeed: number,
	WindUpSpeed: number,
	FadeSeconds: number,
}

local ChopAnimationConfig: ChopAnimationSettings = {
	StrikeStartSeconds = 0.12,
	StrikeImpactSeconds = 0.33,
	StrikeHoldSeconds = 0.35,
	StrikeEndMarginSeconds = 0.05,
	StrikeSpeed = 1,
	WindUpSpeed = 0.5,
	FadeSeconds = 0.12,
}

return table.freeze(ChopAnimationConfig)
