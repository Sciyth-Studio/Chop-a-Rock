--!strict

local ChopQuality = require(script.Parent.Parent.ChopQuality)

export type QualityStyle = {
	Name: string,
	DisplayText: string,
	Color: Color3,
	IsRainbow: boolean,
}

export type ChopStyleSettings = {
	Qualities: { [number]: QualityStyle },
	Fallback: QualityStyle,
	TextEdgeColor: Color3,
	TextCenterColor: Color3,
	StrokeDarkenAmount: number,
	TextGradientRotation: number,
}

local crack: QualityStyle = {
	Name = "Crack",
	DisplayText = "Crack!",
	Color = Color3.fromRGB(255, 0, 0),
	IsRainbow = false,
}

local ChopStyleConfig: ChopStyleSettings = {
	Qualities = {
		[ChopQuality.Crack] = crack,
		[ChopQuality.Bad] = {
			Name = "Bad",
			DisplayText = "Bad..",
			Color = Color3.fromRGB(255, 0, 0),
			IsRainbow = false,
		},
		[ChopQuality.Mid] = {
			Name = "Mid",
			DisplayText = "Mid..",
			Color = Color3.fromRGB(255, 140, 0),
			IsRainbow = false,
		},
		[ChopQuality.Good] = {
			Name = "Good",
			DisplayText = "Good!",
			Color = Color3.fromRGB(0, 255, 0),
			IsRainbow = false,
		},
		[ChopQuality.Great] = {
			Name = "Great",
			DisplayText = "Great!",
			Color = Color3.fromRGB(0, 120, 255),
			IsRainbow = false,
		},
		[ChopQuality.Perfect] = {
			Name = "Perfect",
			DisplayText = "PERFECT!",
			Color = Color3.fromRGB(170, 0, 255),
			IsRainbow = true,
		},
	},
	Fallback = crack,
	TextEdgeColor = Color3.fromRGB(190, 190, 190),
	TextCenterColor = Color3.fromRGB(255, 255, 255),
	StrokeDarkenAmount = 0.6,
	TextGradientRotation = 90,
}

return table.freeze(ChopStyleConfig)
