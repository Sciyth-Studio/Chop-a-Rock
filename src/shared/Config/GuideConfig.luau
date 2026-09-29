--!strict

export type GuideSettings = {
	LabelTemplateKey: string,
	LabelMaxDistance: number,
	LabelHeightAboveRock: number,
	LabelUnlockedColor: Color3,
	LabelLockedColor: Color3,
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
}

local GuideConfig: GuideSettings = {
	LabelTemplateKey = "UI_RockLabel",
	LabelMaxDistance = 120,
	LabelHeightAboveRock = 3,
	LabelUnlockedColor = Color3.fromRGB(0, 255, 0),
	LabelLockedColor = Color3.fromRGB(255, 0, 0),
	ArrowImageKey = "Image_GuideArrow",
	ArrowSize = Vector3.new(3, 0.2, 3),
	ArrowCount = 6,
	ArrowSpacing = 5,
	ArrowScrollSpeed = 4,
	ArrowChestHeight = 1,
	ArrowStartDistance = 5,
	ArrowStopDistance = 8,
	ArrowYawDegrees = 0,
	ArrowFallbackColor = Color3.fromRGB(255, 255, 0),
	GrindDistance = 18,
	ArrivalDistance = 25,
}

return table.freeze(GuideConfig)
