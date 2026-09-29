--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local trove = Trove.new()
local wallets: { [Player]: number } = {}

local WalletService = {
	Name = "WalletService",
}

local function publish(player: Player)
	player:SetAttribute("Money", wallets[player] or 0)
end

local function register(player: Player)
	wallets[player] = wallets[player] or EconomyConfig.StartingWallet
	publish(player)
end

function WalletService.getMoney(player: Player): number
	return wallets[player] or 0
end

function WalletService.addMoney(player: Player, delta: number): number
	local next_ = (wallets[player] or 0) + delta
	wallets[player] = next_
	publish(player)
	return next_
end

function WalletService.setMoney(player: Player, value: number)
	wallets[player] = value
	publish(player)
end

function WalletService.Init(_self: any, _services: { [string]: any }) end

function WalletService.Start(_self: any)
	trove:Add(Players.PlayerAdded:Connect(register))
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		wallets[player] = nil
	end))
	for _, player in Players:GetPlayers() do
		register(player)
	end
end

function WalletService.Destroy(_self: any)
	trove:Clean()
	table.clear(wallets)
end

return WalletService
