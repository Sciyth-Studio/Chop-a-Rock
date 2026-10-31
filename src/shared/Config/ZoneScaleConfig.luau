--!strict

export type ZoneScaleSettings = {
	Growth: number,
	Order: { string },
}

local ZoneScaleConfig: ZoneScaleSettings = {
	Growth = 1.15,
	Order = {
		"Forest",
		"Desert",
		"Jungle",
		"Ocean",
		"Snow",
		"Swamp",
		"Savanna",
		"Bamboo",
		"Volcano",
		"Ruins",
	},
}

return table.freeze(ZoneScaleConfig)
