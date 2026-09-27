--!strict

export type TrainingSettings = {
	BaseStrengthPerRep: number,
	SloppyMultiplier: number,
	GoodMultiplier: number,
	PerfectMultiplier: number,
}

local TrainingConfig: TrainingSettings = {
	BaseStrengthPerRep = 1,
	SloppyMultiplier = 0.5,
	GoodMultiplier = 1.0,
	PerfectMultiplier = 1.5,
}

return table.freeze(TrainingConfig)
