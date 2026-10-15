--!strict

local BlockButtonConfig = {
	TrackName = "Track",
	LipName = "Lip",
	HighlightName = "Highlight",
	BevelName = "Bevel",
	ShadowSuffix = "Shadow",
	ShadowOffset = UDim2.fromOffset(2, 3),
	TopFromEdge = 0.4,
	OutlineDarken = 0.55,
	LipToEdge = 0.35,
	HighlightLighten = 0.1,
	BevelLighten = 0.45,
}

return table.freeze(BlockButtonConfig)
