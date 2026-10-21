--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaClient = require(ReplicatedStorage.ReplicaClient)
local Signal = require(ReplicatedStorage.Packages.Signal)

type Connection = { Disconnect: (self: any) -> () }

local LeaderboardController = {
	Name = "LeaderboardController",
	Changed = Signal.new() :: Signal.Signal<>,
}

local replica: ReplicaClient.Replica? = nil
local connections: { Connection } = {}

function LeaderboardController.Init(_self: any, _controllers: { [string]: any }) end

function LeaderboardController.Start(_self: any)
	table.insert(
		connections,
		ReplicaClient.OnNew("Leaderboards", function(newReplica: ReplicaClient.Replica)
			replica = newReplica
			table.insert(
				connections,
				newReplica:OnChange(function()
					LeaderboardController.Changed:Fire()
				end) :: any
			)
			LeaderboardController.Changed:Fire()
		end) :: any
	)
end

function LeaderboardController.Get(_self: any): { [string]: any }?
	local current = replica
	return if current then current.Data else nil
end

function LeaderboardController.Destroy(_self: any)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return LeaderboardController
