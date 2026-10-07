--!strict

local ChopQuality = require(script.Parent.Parent.ChopQuality)

export type ChopEffectSettings = {
	HitKey: string,
	CrackKey: string,
	BreakKey: string,
	PerfectKey: string,
	MasterWindUpKey: string,
	MasterBurstKey: string,
	BreakCountScale: { [number]: number },
	ImpactInsetFraction: number,
	DustLightenAmount: number,
	MinScale: number,
	TintAttribute: string,
	MinQualityAttribute: string,
}

local ChopEffectConfig: ChopEffectSettings = {
	HitKey = "VFX_Chop_Hit",
	CrackKey = "VFX_Chop_Crack",
	BreakKey = "VFX_Chop_Break",
	PerfectKey = "VFX_Perfect_Burst",
	MasterWindUpKey = "VFX_Master_WindUp",
	MasterBurstKey = "VFX_Master_Burst",
	BreakCountScale = {
		[ChopQuality.Bad] = 0.5,
		[ChopQuality.Mid] = 0.75,
		[ChopQuality.Good] = 1,
		[ChopQuality.Great] = 1.3,
	},
	ImpactInsetFraction = 0.4,
	DustLightenAmount = 0.35,
	MinScale = 0.6,
	TintAttribute = "Tint",
	MinQualityAttribute = "MinQuality",
}

return table.freeze(ChopEffectConfig)
