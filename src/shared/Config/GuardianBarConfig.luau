--!strict

local function fill(edge: Color3, center: Color3, low: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, center),
		ColorSequenceKeypoint.new(0.5, edge),
		ColorSequenceKeypoint.new(1, low),
	})
end

export type Stage = {
	Above: number,
	Fill: ColorSequence,
	TitleStyle: string,
}

local GuardianBarConfig = {
	ScreenName = "GuardianBar",
	TitleFormat = "%s Guardian",
	TimerFormat = "Free eggs! %d:%02d",
	Stages = {
		{
			Above = 0.5,
			Fill = fill(Color3.fromRGB(0, 200, 40), Color3.fromRGB(110, 255, 90), Color3.fromRGB(0, 130, 30)),
			TitleStyle = "Green",
		},
		{
			Above = 0.2,
			Fill = fill(
				Color3.fromRGB(255, 180, 0),
				Color3.fromRGB(255, 235, 60),
				Color3.fromRGB(220, 120, 0)
			),
			TitleStyle = "Gold",
		},
		{
			Above = -1,
			Fill = fill(Color3.fromRGB(235, 0, 0), Color3.fromRGB(255, 60, 60), Color3.fromRGB(160, 0, 0)),
			TitleStyle = "Red",
		},
	} :: { Stage },
	TimerColor = Color3.fromRGB(255, 255, 255),
	TimerWarnColor = Color3.fromRGB(255, 50, 50),
	EnterPopSeconds = 0.35,
	ExitSeconds = 0.25,
	ShakeMinPixels = 2,
	ShakeMaxPixels = 9,
	FlashSeconds = 0.15,
	FlashTransparency = 0.4,
}

return table.freeze(GuardianBarConfig)
