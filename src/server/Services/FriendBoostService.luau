--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FriendBoostConfig = require(ReplicatedStorage.Config.FriendBoostConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local FriendBoostService = { Name = "FriendBoostService" }

local trove = Trove.new()
local friends: { [Player]: { [Player]: boolean } } = {}

local function percentFor(count: number): number
	if count <= 0 then
		return 0
	end
	return FriendBoostConfig.FirstFriendPercent + (count - 1) * FriendBoostConfig.AdditionalFriendPercent
end

local function friendCount(player: Player): number
	local set = friends[player]
	local count = 0
	if set then
		for _ in set do
			count += 1
		end
	end
	return count
end

local function publish(player: Player)
	if player.Parent == Players then
		player:SetAttribute("FriendBoost", percentFor(friendCount(player)))
	end
end

local function link(first: Player, second: Player)
	local ok, isFriend = pcall(function()
		return first:IsFriendsWithAsync(second.UserId)
	end)
	local firstSet = friends[first]
	local secondSet = friends[second]
	if not ok or not isFriend or not firstSet or not secondSet then
		return
	end
	firstSet[second] = true
	secondSet[first] = true
	publish(first)
	publish(second)
end

local function onPlayerAdded(player: Player)
	if friends[player] then
		return
	end
	friends[player] = {}
	publish(player)
	for _, other in Players:GetPlayers() do
		if other ~= player and friends[other] then
			task.spawn(link, player, other)
		end
	end
end

local function onPlayerRemoving(player: Player)
	local set = friends[player]
	friends[player] = nil
	if not set then
		return
	end
	for other in set do
		local otherSet = friends[other]
		if otherSet then
			otherSet[player] = nil
			publish(other)
		end
	end
end

function FriendBoostService.GetPercent(_self: any, player: Player): number
	return percentFor(friendCount(player))
end

function FriendBoostService.ApplyBoost(_self: any, player: Player, amount: number): number
	return math.floor(amount * (1 + percentFor(friendCount(player)) / 100) + 0.5)
end

function FriendBoostService.Init(_self: any, _registry: { [string]: any }) end

function FriendBoostService.Start(_self: any)
	trove:Add(Players.PlayerAdded:Connect(onPlayerAdded))
	trove:Add(Players.PlayerRemoving:Connect(onPlayerRemoving))
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

function FriendBoostService.Destroy(_self: any)
	trove:Clean()
	table.clear(friends)
end

return FriendBoostService
