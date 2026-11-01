--!strict

export type ScaleSettings = {
	ScaleName: string,
	ReferenceWidthPixels: number,
	ReferenceHeightPixels: number,
	ScalePositionAttribute: string,
	MultiplierAttribute: string,
}

local ScaleConfig: ScaleSettings = {
	ScaleName = "ScreenScale",
	ReferenceWidthPixels = 1920,
	ReferenceHeightPixels = 1080,
	ScalePositionAttribute = "ScalePosition",
	MultiplierAttribute = "ScaleMultiplier",
}

return table.freeze(ScaleConfig)
