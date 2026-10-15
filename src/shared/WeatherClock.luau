--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)

export type Slot = {
	Index: number,
	Key: string,
	StartsAt: number,
	EndsAt: number,
}

local WeatherClock = {}

function WeatherClock.Event(key: string): WeatherConfig.Event?
	for _, event in WeatherConfig.Events do
		if event.Key == key then
			return event
		end
	end
	return nil
end

function WeatherClock.Pick(random: Random): string
	local total = 0
	for _, event in WeatherConfig.Events do
		total += event.Weight
	end
	local roll = random:NextNumber(0, total)
	for _, event in WeatherConfig.Events do
		roll -= event.Weight
		if roll < 0 then
			return event.Key
		end
	end
	return WeatherConfig.Events[#WeatherConfig.Events].Key
end

function WeatherClock.Slot(index: number): Slot
	local startsAt = index * WeatherConfig.PeriodSeconds
	return {
		Index = index,
		Key = WeatherClock.Pick(Random.new(WeatherConfig.ClockSeed + index)),
		StartsAt = startsAt,
		EndsAt = startsAt + WeatherConfig.DurationSeconds,
	}
end

function WeatherClock.At(now: number): Slot
	return WeatherClock.Slot(math.floor(now / WeatherConfig.PeriodSeconds))
end

function WeatherClock.Next(now: number): Slot
	return WeatherClock.Slot(math.floor(now / WeatherConfig.PeriodSeconds) + 1)
end

return WeatherClock
