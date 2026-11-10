--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EventClockConfig = require(ReplicatedStorage.Config.EventClockConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type State = {
	Clock: EventClockConfig.Clock,
	NextAt: number,
	NextKey: string,
	LastKey: string?,
}

local EventClockService = { Name = "EventClockService" }

local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}
local states: { State } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function roll(events: { EventClockConfig.Event }, exclude: string?): string
	local excluded = if #events > 1 then exclude else nil
	local total = 0
	for _, event in events do
		if event.Key ~= excluded then
			total += event.Weight
		end
	end
	local pick = random:NextNumber(0, total)
	for _, event in events do
		if event.Key ~= excluded then
			pick -= event.Weight
			if pick < 0 then
				return event.Key
			end
		end
	end
	return events[1].Key
end

local function plan(state: State, time: number)
	local clock = state.Clock
	local slot = math.floor((time - clock.OffsetSeconds) / clock.PeriodSeconds) + 1
	state.NextAt = slot * clock.PeriodSeconds + clock.OffsetSeconds
	state.NextKey = roll(clock.Events, state.LastKey)
	if state.NextKey == "Weather" then
		services.WeatherService:Schedule(state.NextAt)
	end
	workspace:SetAttribute(clock.KeyAttribute, state.NextKey)
	workspace:SetAttribute(clock.AtAttribute, state.NextAt)
	print(`[EventClockService] {clock.Name} clock: {state.NextKey} in {math.floor(state.NextAt - time)}s`)
end

local function fire(state: State)
	local key = state.NextKey
	state.LastKey = key
	local isStarted, message = true, "weather"
	if key == "GeodeFall" then
		isStarted, message = services.GeodeFallService:Spawn(nil)
	elseif key == "DiamondRock" then
		isStarted, message = services.DiamondRockService:Spawn(nil)
	end
	print(`[EventClockService] {key}: started={isStarted}, {message}`)
end

local function tick()
	local time = now()
	for _, state in states do
		if time >= state.NextAt then
			fire(state)
			plan(state, time)
		end
	end
end

function EventClockService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function EventClockService.Start(_self: any)
	local time = now()
	for _, clock in EventClockConfig.Clocks do
		local state: State = { Clock = clock, NextAt = math.huge, NextKey = "", LastKey = nil }
		table.insert(states, state)
		plan(state, time)
	end
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
