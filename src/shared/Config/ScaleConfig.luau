--!strict

export type ScaleSettings = {
	ScaleName: string,
	ReferenceShortSidePixels: number,
	MinScale: number,
	UpscaleShortSidePixels: number,
	MaxScale: number,
	FitMarginPixels: number,
	FitAttribute: string,
}

local ScaleConfig: ScaleSettings = {
	ScaleName = "ScreenScale",
	ReferenceShortSidePixels = 600,
	MinScale = 0.5,
	UpscaleShortSidePixels = 1080,
	MaxScale = 2,
	FitMarginPixels = 12,
	FitAttribute = "FitToScreen",
}

return table.freeze(ScaleConfig)
