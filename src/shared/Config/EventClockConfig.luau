--!strict

export type Event = {
	Key: string,
	Weight: number,
}

export type EventClockSettings = {
	PeriodSeconds: number,
	Events: { Event },
}

local EventClockConfig: EventClockSettings = {
	PeriodSeconds = 300,
	Events = {
		{ Key = "GeodeFall", Weight = 40 },
		{ Key = "DiamondRock", Weight = 35 },
		{ Key = "Weather", Weight = 25 },
	},
}

return EventClockConfig
