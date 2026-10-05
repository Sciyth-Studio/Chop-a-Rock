--!strict

export type TrainingSettings = {
	StrengthUnit: string,
	StrengthPerChop: number,
	ChopIntervalSeconds: number,
	MaxLingerStuds: number,
	SnapDistanceStuds: number,
	SnapLeftShiftStuds: number,
	BoardRespawnSeconds: number,
	BoardPieceLifetimeSeconds: number,
	BoardSplitOutwardStuds: number,
	BoardSplitUpStuds: number,
	BoardSplitTorqueRadPerSec: number,
	BoardBurstEmitCount: number,
	BoardBurstLifetimeSeconds: number,
}

local TrainingConfig: TrainingSettings = {
	StrengthUnit = "N",
	StrengthPerChop = 1,
	ChopIntervalSeconds = 1.6,
	MaxLingerStuds = 15,
	SnapDistanceStuds = 4,
	SnapLeftShiftStuds = 2,
	BoardRespawnSeconds = 0.8,
	BoardPieceLifetimeSeconds = 2,
	BoardSplitOutwardStuds = 6,
	BoardSplitUpStuds = 6,
	BoardSplitTorqueRadPerSec = 5,
	BoardBurstEmitCount = 24,
	BoardBurstLifetimeSeconds = 1.5,
}

return table.freeze(TrainingConfig)
