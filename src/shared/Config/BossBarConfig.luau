--!strict

local DiamondRockConfig = require(script.Parent.DiamondRockConfig)

export type TitleColors = {
	Color: ColorSequence,
	Stroke: Color3,
}

local function title(top: Color3, center: Color3, bottom: Color3, stroke: Color3): TitleColors
	return table.freeze({
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, top),
			ColorSequenceKeypoint.new(0.45, center),
			ColorSequenceKeypoint.new(1, bottom),
		}),
		Stroke = stroke,
	})
end

local function fill(edge: Color3, center: Color3, low: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, center),
		ColorSequenceKeypoint.new(0.5, edge),
		ColorSequenceKeypoint.new(1, low),
	})
end

local titles: { [string]: TitleColors } = {
	BigCroc = title(
		Color3.fromRGB(70, 150, 20),
		Color3.fromRGB(170, 235, 50),
		Color3.fromRGB(20, 95, 35),
		Color3.fromRGB(10, 45, 10)
	),
	BoulderCrab = title(
		Color3.fromRGB(255, 175, 0),
		Color3.fromRGB(255, 100, 0),
		Color3.fromRGB(215, 0, 0),
		Color3.fromRGB(85, 0, 0)
	),
	FrostYeti = title(
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(160, 225, 255),
		Color3.fromRGB(0, 120, 255),
		Color3.fromRGB(0, 40, 120)
	),
}

local BossBarConfig = table.freeze({
	ScreenName = "BossBar",
	FloorName = "Floor",
	DiamondPartName = "Rock",
	BottomAttribute = "CoverBottom",
	NotificationGapPixels = 8,
	ArenaMarginStuds = 6,
	ArenaOffsetPixels = 124,
	ChopOffsetPixels = 18,
	BarScale = 1.25,
	MoveSeconds = 0.25,
	Titles = table.freeze(titles),
	DefaultTitle = title(
		Color3.fromRGB(255, 120, 0),
		Color3.fromRGB(255, 220, 0),
		Color3.fromRGB(230, 100, 0),
		Color3.fromRGB(90, 30, 0)
	),
	DiamondTitle = title(
		Color3.fromRGB(190, 255, 255),
		DiamondRockConfig.TextMain,
		Color3.fromRGB(0, 145, 220),
		DiamondRockConfig.TextDark
	),
	EnragedTitle = title(
		Color3.fromRGB(255, 110, 70),
		Color3.fromRGB(255, 0, 0),
		Color3.fromRGB(150, 0, 0),
		Color3.fromRGB(60, 0, 0)
	),
	EnragedText = "Enraged",
	EnragedGapPixels = 22,
	EnragedLabelName = "EnragedTitle",
	EnragedShadowName = "EnragedTitleShadow",
	NormalFill = fill(Color3.fromRGB(235, 0, 0), Color3.fromRGB(255, 40, 40), Color3.fromRGB(170, 0, 0)),
	MadFill = fill(Color3.fromRGB(190, 0, 20), Color3.fromRGB(255, 0, 40), Color3.fromRGB(120, 0, 10)),
	DiamondFill = fill(Color3.fromRGB(0, 190, 255), Color3.fromRGB(0, 235, 255), Color3.fromRGB(0, 110, 230)),
	FinishFill = fill(Color3.fromRGB(255, 190, 0), Color3.fromRGB(255, 235, 0), Color3.fromRGB(230, 140, 0)),
	PulseSpeed = 4,
	MadPulseTransparency = 0.8,
	FinishPulseTransparency = 0.6,
	GhostDelaySeconds = 0.5,
	GhostDrainSpeed = 6,
	FlashSeconds = 0.15,
	FlashTransparency = 0.35,
	BigHitRatio = 0.03,
	HitShakePixels = 6,
	MadShakePixels = 16,
	ShakeSeconds = 0.35,
	EnterPopSeconds = 0.35,
	EnterFillSeconds = 0.8,
	DefeatDrainSeconds = 0.6,
	ExitSeconds = 0.4,
	TimerWarnColor = Color3.fromRGB(255, 40, 40),
	TimerPulseScale = 1.25,
	TimerPulseSeconds = 0.25,
	HeartHealth = 20,
	HeartPopScale = 1.5,
	HeartPopSeconds = 0.45,
	HeartRisePixels = 18,
	HeartHitScale = 1.25,
	HeartHitSeconds = 0.2,
	LastHeartFlashSpeed = 6,
	LastHeartFlashTransparency = 0.55,
	LastHeartPulseScale = 0.12,
})

return BossBarConfig
