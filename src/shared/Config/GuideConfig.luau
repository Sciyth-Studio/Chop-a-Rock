--!strict

export type GuideSettings = {
	LabelTemplateKey: string,
	LabelMaxDistance: number,
	LabelHeightAboveRock: number,
	ArrowImageKey: string,
	ArrowSize: Vector3,
	ArrowCount: number,
	ArrowSpacing: number,
	ArrowScrollSpeed: number,
	ArrowChestHeight: number,
	ArrowStartDistance: number,
	ArrowStopDistance: number,
	ArrowYawDegrees: number,
	ArrowFallbackColor: Color3,
	GrindDistance: number,
	ArrivalDistance: number,
	ShopArrivalDistance: number,
	HighlightColor: Color3,
	HighlightFillTransparency: number,
	HighlightOutlineTransparency: number,
	HighlightFadeSeconds: number,
}

local GuideConfig: GuideSettings = {
	LabelTemplateKey = "UI_RockLabel",
	LabelMaxDistance = 120,
	LabelHeightAboveRock = 3,
	ArrowImageKey = "Image_GuideArrow",
	ArrowSize = Vector3.new(3, 0.2, 3),
	ArrowCount = 6,
	ArrowSpacing = 5,
	ArrowScrollSpeed = 4,
	ArrowChestHeight = 1,
	ArrowStartDistance = 5,
	ArrowStopDistance = 8,
	ArrowYawDegrees = 180,
	ArrowFallbackColor = Color3.fromRGB(255, 255, 0),
	GrindDistance = 18,
	ArrivalDistance = 25,
	ShopArrivalDistance = 14,
	HighlightColor = Color3.fromRGB(255, 255, 255),
	HighlightFillTransparency = 0.6,
	HighlightOutlineTransparency = 0,
	HighlightFadeSeconds = 0.5,
}

return table.freeze(GuideConfig)
