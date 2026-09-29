--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local DataService = require(script.Parent.DataService)

local trove = Trove.new()

local StatsService = {
	Name = "StatsService",
}

local function publish(player: Player)
	local data = DataService:GetData(player)
	if data then
		player:SetAttribute("Strength", data.Strength)
	end
end

function StatsService.GetStrength(_self: any, player: Player): number
	local data = DataService:GetData(player)
	return if data then data.Strength else 0
end

function StatsService.AddStrength(_self: any, player: Player, delta: number): number
	local data = DataService:GetData(player)
	if not data then
		return 0
	end
	data.Strength += math.max(0, math.floor(delta))
	publish(player)
	return data.Strength
end

function StatsService.Init(_self: any, _services: { [string]: any }) end

function StatsService.Start(_self: any)
	trove:Add(DataService.PlayerLoaded:Connect(function(player: Player)
		publish(player)
	end))
	for _, player in Players:GetPlayers() do
		publish(player)
	end
end

function StatsService.Destroy(_self: any)
	trove:Clean()
end

return StatsService
