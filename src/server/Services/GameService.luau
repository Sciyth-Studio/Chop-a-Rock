--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Packets = require(ReplicatedStorage.Packets)

local GameService: Lifecycle.System = { Name = "GameService" }

local playerAdded: RBXScriptConnection? = nil

local function applyShiftLock(player: Player)
	player.DevEnableMouseLock = GameConfig.AllowShiftLock
end

function GameService.Init(_self: Lifecycle.System, _services: { [string]: any }) end

function GameService.Start(_self: Lifecycle.System)
	StarterPlayer.EnableMouseLockOption = GameConfig.AllowShiftLock
	playerAdded = Players.PlayerAdded:Connect(applyShiftLock)
	for _, player in Players:GetPlayers() do
		applyShiftLock(player)
	end
	Packets.Ping.OnServerInvoke = function(_player: Player)
		return workspace:GetServerTimeNow()
	end
	print(`[{GameConfig.Name}] Server services ready`)
end

function GameService.Destroy(_self: Lifecycle.System)
	if playerAdded then
		playerAdded:Disconnect()
		playerAdded = nil
	end
	Packets.Ping.OnServerInvoke = nil
end

return GameService
