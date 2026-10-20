--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RokModifier = require(ReplicatedStorage.RokModifier)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local WeatherClock = require(ReplicatedStorage.WeatherClock)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)

type Window = {
	Key: string,
	StartsAt: number,
	EndsAt: number,
}

local WeatherService = { Name = "WeatherService" }

local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}

local override: Window? = nil
local pending: Window? = nil
local suppressedUntil = 0
local active: Window? = nil
local warnedFor = 0
local lastCatchAt = 0
local stormHits: { [Player]: number } = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function window(key: string, startsAt: number): Window
	return { Key = key, StartsAt = startsAt, EndsAt = startsAt + WeatherConfig.DurationSeconds }
end

local function current(time: number): Window?
	if pending and time >= pending.StartsAt then
		override = pending
		pending = nil
	end
	if override then
		if time < override.EndsAt then
			return override
		end
		suppressedUntil = math.max(suppressedUntil, override.EndsAt)
		override = nil
	end
	local slot = WeatherClock.At(time)
	if time >= slot.StartsAt and time < slot.EndsAt and slot.EndsAt > suppressedUntil then
		return window(slot.Key, slot.StartsAt)
	end
	return nil
end

local function nextStart(time: number): (number, string)
	local slot = WeatherClock.Next(time)
	if pending and pending.StartsAt < slot.StartsAt then
		return pending.StartsAt, pending.Key
	end
	return slot.StartsAt, slot.Key
end

local function inTutorial(player: Player): boolean
	local data = services.DataService:GetData(player)
	return Tutorial.IsActive(Tutorial.StepOf(if data then data.Tutorial else nil))
end

local function notifyAll(event: WeatherConfig.Event, text: string)
	for _, player in Players:GetPlayers() do
		if not inTutorial(player) then
			services.NotificationService:Notify(
				player,
				WeatherConfig.NoticeKindPrefix .. event.Modifier,
				text
			)
		end
	end
end

local function multiplierText(value: number): string
	return if value % 1 == 0 then tostring(value) else string.format("%.1f", value)
end

local function publish(time: number)
	local event = if active then WeatherClock.Event(active.Key) else nil
	workspace:SetAttribute(WeatherConfig.WeatherAttribute, if active and event then active.Key else "")
	workspace:SetAttribute(WeatherConfig.StartedAtAttribute, if active then active.StartsAt else 0)
	workspace:SetAttribute(WeatherConfig.EndsAtAttribute, if active then active.EndsAt else 0)
	workspace:SetAttribute(WeatherConfig.NextAtAttribute, (nextStart(time)))
end

local function rollCatches(event: WeatherConfig.Event)
	for _, player in Players:GetPlayers() do
		local hits = stormHits[player] or 0
		stormHits[player] = nil
		local data = services.DataService:GetData(player)
		if not data or Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
			continue
		end
		local candidates: { string } = {}
		for petId, pet in data.Pets do
			if pet.Slot ~= nil and RokModifier.IsBetter(event.Modifier, pet.Modifier) then
				table.insert(candidates, petId)
			end
		end
		local chance = math.min(
			WeatherConfig.MaxCatchChance,
			WeatherConfig.CatchChance + hits * WeatherConfig.StormHitCatchChance
		)
		if #candidates > 0 and random:NextNumber() < chance then
			local petId = candidates[random:NextInteger(1, #candidates)]
			services.PetService:SetModifier(player, petId, event.Modifier, true)
		end
	end
end

local function tick()
	local time = now()
	local previous = active
	active = current(time)
	if previous and (not active or active.StartsAt ~= previous.StartsAt) then
		local event = WeatherClock.Event(previous.Key)
		if event then
			notifyAll(event, string.format(WeatherConfig.EndText, event.DisplayName))
		end
		print(`[WeatherService] {previous.Key} ended`)
	end
	if active and (not previous or previous.StartsAt ~= active.StartsAt) then
		local event = WeatherClock.Event(active.Key)
		local modifier = if event then RokModifier.Get(event.Modifier) else nil
		if event and modifier then
			notifyAll(
				event,
				string.format(
					WeatherConfig.StartText,
					event.DisplayName,
					modifier.DisplayName,
					multiplierText(modifier.Multiplier)
				)
			)
		end
		lastCatchAt = time
		table.clear(stormHits)
		services.RockService:StartStorm(active.Key, WeatherConfig.StartStormRocksPerZone)
		print(`[WeatherService] {active.Key} started, ends in {math.floor(active.EndsAt - time)}s`)
	end
	local startsAt, key = nextStart(time)
	if
		not active
		and startsAt - time <= WeatherConfig.WarningSeconds
		and startsAt - time > 0
		and warnedFor ~= startsAt
	then
		warnedFor = startsAt
		local event = WeatherClock.Event(key)
		if event then
			notifyAll(event, string.format(WeatherConfig.WarningText, event.DisplayName))
		end
	end
	if active and time - lastCatchAt >= WeatherConfig.CatchIntervalSeconds then
		lastCatchAt = time
		local event = WeatherClock.Event(active.Key)
		if event then
			rollCatches(event)
		end
	end
	publish(time)
end

function WeatherService.GetActive(_self: any): WeatherConfig.Event?
	return if active then WeatherClock.Event(active.Key) else nil
end

function WeatherService.RollStormRock(_self: any, player: Player?): string?
	if player and inTutorial(player) then
		return nil
	end
	if active and random:NextNumber() < WeatherConfig.StormRockChance then
		return active.Key
	end
	return nil
end

function WeatherService.RecordHit(_self: any, player: Player, weather: string?)
	if active and weather == active.Key then
		stormHits[player] = (stormHits[player] or 0) + 1
	end
end

function WeatherService.GetRockMultiplier(_self: any, weather: string?): number
	local event = WeatherService:GetActive()
	return if event and weather == event.Key then event.RockMultiplier else 1
end

function WeatherService.RollHatchModifier(_self: any, player: Player?): string?
	if player and inTutorial(player) then
		return nil
	end
	local event = WeatherService:GetActive()
	if event and random:NextNumber() < WeatherConfig.HatchChance then
		return event.Modifier
	end
	return nil
end

function WeatherService.Start(_self: any)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		stormHits[player] = nil
	end)
	trove:Add(task.spawn(function()
		while true do
			tick()
			task.wait(1)
		end
	end))
end

function WeatherService.Force(_self: any, key: string): boolean
	if not WeatherClock.Event(key) then
		return false
	end
	pending = nil
	override = window(key, now())
	tick()
	return true
end

function WeatherService.EndActive(_self: any): boolean
	if not active then
		return false
	end
	suppressedUntil = math.max(suppressedUntil, active.EndsAt)
	override = nil
	tick()
	return true
end

function WeatherService.StartIn(_self: any, seconds: number): string
	local key = WeatherClock.Pick(random)
	pending = window(key, now() + seconds)
	override = nil
	if active then
		suppressedUntil = math.max(suppressedUntil, active.EndsAt)
	end
	tick()
	return key
end

function WeatherService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function WeatherService.Destroy(_self: any)
	trove:Clean()
end

return WeatherService
