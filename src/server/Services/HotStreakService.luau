--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local HotStreakConfig = require(ReplicatedStorage.Config.HotStreakConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type State = {
	Count: number,
	Tier: number,
	LastChopAt: number,
}

local HotStreakService = { Name = "HotStreakService" }

local trove = Trove.new()
local services: { [string]: any } = {}
local states: { [Player]: State } = {}
local characterConnections: { [Player]: RBXScriptConnection } = {}

local function tierForCount(count: number): number
	local tier = 0
	for index, definition in HotStreakConfig.Tiers do
		if count >= definition.Chops then
			tier = index
		end
	end
	return tier
end

local function multiplierFor(tier: number): number
	local definition = HotStreakConfig.Tiers[tier]
	return if definition then definition.Multiplier else 1
end

local function publish(player: Player)
	local state = states[player]
	if not state or player.Parent ~= Players then
		return
	end
	local definition = HotStreakConfig.Tiers[state.Tier]
	player:SetAttribute(HotStreakConfig.TierAttribute, state.Tier)
	player:SetAttribute(HotStreakConfig.CountAttribute, state.Count)
	player:SetAttribute(
		HotStreakConfig.ExpiresAtAttribute,
		if state.Count > 0 then workspace:GetServerTimeNow() + HotStreakConfig.FadeSeconds else 0
	)
	services.WalkSpeedService:SetBonus(
		player,
		HotStreakConfig.SpeedSource,
		if definition then definition.WalkSpeedBonus else 0
	)
end

local function reset(player: Player)
	local state = states[player]
	if not state then
		return
	end
	state.Count = 0
	state.Tier = 0
	publish(player)
end

local function onPlayerAdded(player: Player)
	if states[player] then
		return
	end
	states[player] = { Count = 0, Tier = 0, LastChopAt = 0 }
	publish(player)
	characterConnections[player] = player.CharacterAdded:Connect(function()
		reset(player)
	end)
end

local function onPlayerRemoving(player: Player)
	local connection = characterConnections[player]
	if connection then
		connection:Disconnect()
	end
	characterConnections[player] = nil
	states[player] = nil
end

local function tick()
	local now = os.clock()
	for player, state in states do
		if state.Count > 0 and now - state.LastChopAt >= HotStreakConfig.FadeSeconds then
			reset(player)
		end
	end
end

function HotStreakService.KeepAlive(_self: any, player: Player)
	local state = states[player]
	if not state or state.Count <= 0 then
		return
	end
	state.LastChopAt = os.clock()
	publish(player)
end

function HotStreakService.RecordChop(
	_self: any,
	player: Player,
	quality: number,
	strengthRatio: number
): number
	local state = states[player]
	if not state or quality <= ChopQuality.Crack or strengthRatio > HotStreakConfig.MaxStrengthRatio then
		return 1
	end
	local multiplier = multiplierFor(state.Tier)
	if quality >= HotStreakConfig.BuildMinQuality then
		state.Count += 1
		state.Tier = tierForCount(state.Count)
		multiplier = multiplierFor(state.Tier)
	elseif quality <= HotStreakConfig.DropMaxQuality and state.Tier > 0 then
		local definition = HotStreakConfig.Tiers[math.max(state.Tier - 1, 1)]
		state.Count = definition.Chops
		state.Tier = tierForCount(state.Count)
	end
	state.LastChopAt = os.clock()
	publish(player)
	return multiplier
end

function HotStreakService.ApplyCashMultiplier(_self: any, amount: number, multiplier: number): number
	return math.floor(amount * multiplier + 0.5)
end

function HotStreakService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function HotStreakService.Start(_self: any)
	trove:Add(Players.PlayerAdded:Connect(onPlayerAdded))
	trove:Add(Players.PlayerRemoving:Connect(onPlayerRemoving))
	trove:Add(RunService.Heartbeat:Connect(tick))
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

function HotStreakService.Destroy(_self: any)
	trove:Clean()
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
	table.clear(states)
end

return HotStreakService
