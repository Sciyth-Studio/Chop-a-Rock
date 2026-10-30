--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)

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

return WeatherClock
