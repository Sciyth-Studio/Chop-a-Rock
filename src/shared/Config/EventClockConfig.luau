--!strict

export type Event = {
	Key: string,
	Weight: number,
}

export type Clock = {
	Name: string,
	PeriodSeconds: number,
	OffsetSeconds: number,
	Events: { Event },
	KeyAttribute: string,
	AtAttribute: string,
}

export type EventClockSettings = {
	Clocks: { Clock },
}

local EventClockConfig: EventClockSettings = {
	Clocks = {
		{
			Name = "Weather",
			PeriodSeconds = 300,
			OffsetSeconds = 0,
			Events = {
				{ Key = "Weather", Weight = 60 },
				{ Key = "GeodeFall", Weight = 40 },
			},
			KeyAttribute = "WeatherClockEvent",
			AtAttribute = "WeatherClockAt",
		},
		{
			Name = "Boss",
			PeriodSeconds = 900,
			OffsetSeconds = 150,
			Events = {
				{ Key = "DiamondRock", Weight = 100 },
			},
			KeyAttribute = "BossClockEvent",
			AtAttribute = "BossClockAt",
		},
	},
}

return table.freeze(EventClockConfig)
