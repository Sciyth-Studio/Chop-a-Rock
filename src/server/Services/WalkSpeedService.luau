--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WalkSpeedConfig = require(ReplicatedStorage.Config.WalkSpeedConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local WalkSpeedService = { Name = "WalkSpeedService" }

local trove = Trove.new()
local bonuses: { [Player]: { [string]: number } } = {}
local freezes: { [Player]: number } = {}

local function publish(player: Player)
	local sources = bonuses[player]
	if not sources or player.Parent ~= Players then
		return
	end
	local target = 0
	if (freezes[player] or 0) == 0 then
		target = WalkSpeedConfig.BaseWalkSpeed
		for _, amount in sources do
			target += amount
		end
	end
	player:SetAttribute(WalkSpeedConfig.TargetAttribute, math.max(0, target))
end

local function onPlayerAdded(player: Player)
	if bonuses[player] then
		return
	end
	bonuses[player] = {}
	freezes[player] = 0
	publish(player)
end

local function onPlayerRemoving(player: Player)
	bonuses[player] = nil
	freezes[player] = nil
end

function WalkSpeedService.SetBonus(_self: any, player: Player, source: string, amount: number)
	local sources = bonuses[player]
	if not sources then
		return
	end
	local stored = if amount == 0 then nil else amount
	if sources[source] == stored then
		return
	end
	if stored then
		sources[source] = stored
	else
		sources[source] = nil
	end
	publish(player)
end

function WalkSpeedService.Freeze(_self: any, player: Player): () -> ()
	if not freezes[player] then
		return function() end
	end
	freezes[player] += 1
	publish(player)
	local isReleased = false
	return function()
		if isReleased or not freezes[player] then
			return
		end
		isReleased = true
		freezes[player] -= 1
		publish(player)
	end
end

function WalkSpeedService.Init(_self: any, _registry: { [string]: any }) end

function WalkSpeedService.Start(_self: any)
	trove:Add(Players.PlayerAdded:Connect(onPlayerAdded))
	trove:Add(Players.PlayerRemoving:Connect(onPlayerRemoving))
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

function WalkSpeedService.Destroy(_self: any)
	trove:Clean()
	table.clear(bonuses)
	table.clear(freezes)
end

return WalkSpeedService
