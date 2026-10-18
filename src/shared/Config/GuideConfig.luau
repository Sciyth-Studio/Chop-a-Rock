--!strict

export type GuideSettings = {
	LabelTemplateKey: string,
	LabelMaxDistance: number,
	LabelHeightAboveRock: number,
}

local GuideConfig: GuideSettings = {
	LabelTemplateKey = "UI_RockLabel",
	LabelMaxDistance = 120,
	LabelHeightAboveRock = 3,
}

return table.freeze(GuideConfig)
