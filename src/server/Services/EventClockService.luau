--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventClockConfig = require(ReplicatedStorage.Config.EventClockConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local EventClockService = { Name = "EventClockService" }

local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}

local nextAt = math.huge
local nextKey = ""
local lastKey: string? = nil

local function now(): number
	return workspace:GetServerTimeNow()
end

local function roll(exclude: string?): string
	local total = 0
	for _, event in EventClockConfig.Events do
		if event.Key ~= exclude then
			total += event.Weight
		end
	end
	local pick = random:NextNumber(0, total)
	for _, event in EventClockConfig.Events do
		if event.Key ~= exclude then
			pick -= event.Weight
			if pick < 0 then
				return event.Key
			end
		end
	end
	return EventClockConfig.Events[1].Key
end

local function plan(time: number)
	nextAt = (math.floor(time / EventClockConfig.PeriodSeconds) + 1) * EventClockConfig.PeriodSeconds
	nextKey = roll(lastKey)
	if nextKey == "Weather" then
		services.WeatherService:Schedule(nextAt)
	end
	print(`[EventClockService] Next event: {nextKey} in {math.floor(nextAt - time)}s`)
end

local function fire()
	lastKey = nextKey
	local isStarted, message = true, "weather"
	if nextKey == "GeodeFall" then
		isStarted, message = services.GeodeFallService:Spawn(nil)
	elseif nextKey == "DiamondRock" then
		isStarted, message = services.DiamondRockService:Spawn(nil)
	end
	print(`[EventClockService] {nextKey}: started={isStarted}, {message}`)
end

local function tick()
	local time = now()
	if time >= nextAt then
		fire()
		plan(time)
	end
end

function EventClockService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function EventClockService.Start(_self: any)
	plan(now())
	trove:Add(task.spawn(function()
		while true do
			task.wait(1)
			tick()
		end
	end))
end

function EventClockService.Destroy(_self: any)
	trove:Clean()
end

return EventClockService
