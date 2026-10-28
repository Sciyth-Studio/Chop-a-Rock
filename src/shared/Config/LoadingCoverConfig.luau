--!strict

export type LoadingCoverSettings = {
	ScreenName: string,
	FadeSeconds: number,
	MinSeconds: number,
	MaxSeconds: number,
	BounceHeightPixels: number,
	BounceSeconds: number,
	Milestones: { [string]: number },
	StatusTexts: { [string]: string },
	CatchUpRate: number,
	CreepRate: number,
	CreepShare: number,
	FinishSeconds: number,
	FinishHoldSeconds: number,
	RibTilePixels: number,
	RibSpeedMin: number,
	RibSpeedMax: number,
}

local LoadingCoverConfig: LoadingCoverSettings = {
	ScreenName = "LoadingCover",
	FadeSeconds = 0.4,
	MinSeconds = 0.6,
	MaxSeconds = 20,
	BounceHeightPixels = 28,
	BounceSeconds = 0.7,
	Milestones = {
		Joined = 0.12,
		DataLoaded = 0.45,
		StageBuilt = 0.6,
		AnimationsLoaded = 0.75,
		Preloaded = 0.9,
	},
	StatusTexts = {
		Joined = "Loading...",
		DataLoaded = "Loading your save...",
		StageBuilt = "Setting the scene...",
		Preloaded = "Almost ready...",
	},
	CatchUpRate = 8,
	CreepRate = 0.4,
	CreepShare = 0.5,
	FinishSeconds = 0.25,
	FinishHoldSeconds = 0.15,
	RibTilePixels = 64,
	RibSpeedMin = 40,
	RibSpeedMax = 140,
}

return table.freeze(LoadingCoverConfig)
