--!strict

export type EventTimerSettings = {
	TemplateName: string,
	ContainerName: string,
	IconName: string,
	TimeName: string,
	TimeShadowName: string,
	TimeText: string,
	RefreshSeconds: number,
	WeatherClock: string,
	WeatherIdleIcon: string,
	Icons: { [string]: string },
}

local EventTimerConfig: EventTimerSettings = {
	TemplateName = "TimerTemplate",
	ContainerName = "Container",
	IconName = "Icon",
	TimeName = "Time",
	TimeShadowName = "TimeShadow",
	TimeText = "%02d:%02d",
	RefreshSeconds = 0.2,
	WeatherClock = "Weather",
	WeatherIdleIcon = "rbxassetid://132638548613590",
	Icons = {
		GeodeFall = "rbxassetid://107449519840351",
		DiamondRock = "rbxassetid://88370777803925",
		Golem = "rbxassetid://103613630342041",
	},
}

return table.freeze(EventTimerConfig)
