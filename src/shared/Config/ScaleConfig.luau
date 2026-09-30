--!strict

export type ScaleSettings = {
	ScaleName: string,
	ReferenceShortSidePixels: number,
	MinScale: number,
}

local ScaleConfig: ScaleSettings = {
	ScaleName = "ScreenScale",
	ReferenceShortSidePixels = 600,
	MinScale = 0.5,
}

return table.freeze(ScaleConfig)
