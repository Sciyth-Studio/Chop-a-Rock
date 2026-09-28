--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)

local trove = Trove.new()
local strengths: { [Player]: number } = {}

local StatsService = {
	Name = "StatsService",
}

function StatsService.getStrength(player: Player): number
	return strengths[player] or 0
end

function StatsService.addStrength(player: Player, delta: number): number
	local next_ = (strengths[player] or 0) + delta
	strengths[player] = next_
	return next_
end

function StatsService.setStrength(player: Player, value: number)
	strengths[player] = value
end

function StatsService.Init(_self: any, _services: { [string]: any }) end

function StatsService.Start(_self: any)
	trove:Add(Players.PlayerAdded:Connect(function(player: Player)
		strengths[player] = strengths[player] or 0
	end))
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		strengths[player] = nil
	end))
	for _, player in Players:GetPlayers() do
		strengths[player] = strengths[player] or 0
	end
end

function StatsService.Destroy(_self: any)
	trove:Clean()
	table.clear(strengths)
end

return StatsService
