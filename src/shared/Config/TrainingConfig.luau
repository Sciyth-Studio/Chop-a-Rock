--!strict

export type TrainingSettings = {
	StrengthUnit: string,
	StrengthPerChop: number,
	ChopIntervalSeconds: number,
	MaxLingerStuds: number,
	SnapDistanceStuds: number,
}

local TrainingConfig: TrainingSettings = {
	StrengthUnit = "N",
	StrengthPerChop = 1,
	ChopIntervalSeconds = 1.2,
	MaxLingerStuds = 15,
	SnapDistanceStuds = 4,
}

return table.freeze(TrainingConfig)
