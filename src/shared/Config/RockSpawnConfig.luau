--!strict

export type Zone = {
	RockCount: number,
	Weights: { [string]: number },
}

export type RockSpawnSettings = {
	AreaTag: string,
	ZoneAttribute: string,
	Zones: { [string]: Zone },
	SampleSpacingStuds: number,
	MaxSlopeDegrees: number,
	MaxGroundLayers: number,
	GroundStepStuds: number,
	ClearanceLiftStuds: number,
	SinkStuds: number,
	StandClearanceSize: Vector3,
	StandMaxStepStuds: number,
	RockGapStuds: number,
	PlayerClearanceStuds: number,
	RespawnSeconds: number,
	RiseSeconds: number,
	RiseDepthPaddingStuds: number,
	RiseSlackSeconds: number,
	RiseDustKey: string,
	RiseSoundKey: string,
	DustKey: string,
	DustEmitCount: number,
	DustLifetimeSeconds: number,
	ChopRangeSlackStuds: number,
	OthersEffectMaxDistance: number,
	OthersChunkCount: number,
	OthersChunkColor: Color3,
	SpotDotSize: number,
	SpotColors: { [string]: Color3 },
}

local RockSpawnConfig: RockSpawnSettings = {
	AreaTag = "RockSpawnArea",
	ZoneAttribute = "Zone",
	Zones = {
		Forest = {
			RockCount = 10,
			Weights = { Basic = 50, Second = 30, Third = 20 },
		},
	},
	SampleSpacingStuds = 4,
	MaxSlopeDegrees = 25,
	MaxGroundLayers = 8,
	GroundStepStuds = 1.5,
	ClearanceLiftStuds = 0.5,
	SinkStuds = 0.2,
	StandClearanceSize = Vector3.new(3, 5, 3),
	StandMaxStepStuds = 2,
	RockGapStuds = 8,
	PlayerClearanceStuds = 6,
	RespawnSeconds = 2,
	RiseSeconds = 0.6,
	RiseDepthPaddingStuds = 0.5,
	RiseSlackSeconds = 0.2,
	RiseDustKey = "VFX_Rock_Dust",
	RiseSoundKey = "SFX_Rock_Rise",
	DustKey = "VFX_Rock_Dust",
	DustEmitCount = 12,
	DustLifetimeSeconds = 2,
	ChopRangeSlackStuds = 6,
	OthersEffectMaxDistance = 150,
	OthersChunkCount = 4,
	OthersChunkColor = Color3.fromRGB(110, 110, 110),
	SpotDotSize = 0.8,
	SpotColors = {
		Basic = Color3.fromRGB(160, 160, 160),
		Second = Color3.fromRGB(0, 120, 255),
		Third = Color3.fromRGB(0, 255, 0),
	},
}

return table.freeze(RockSpawnConfig)
