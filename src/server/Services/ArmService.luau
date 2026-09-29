--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArmConfig = require(ReplicatedStorage.Config.ArmConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local DataService = require(script.Parent.DataService)

local trove = Trove.new()

local ArmService = {
	Name = "ArmService",
}

local function publish(player: Player)
	local data = DataService:GetData(player)
	if data then
		player:SetAttribute("ArmTier", data.ArmTier)
	end
end

function ArmService.GetTier(_self: any, player: Player): number
	local data = DataService:GetData(player)
	return if data then data.ArmTier else 1
end

function ArmService.GetTrainingMultiplier(_self: any, player: Player): number
	local tier = ArmConfig.Tiers[ArmService:GetTier(player)]
	return if tier then tier.TrainingGainMultiplier else 1
end

function ArmService.BuyTier(_self: any, player: Player, tierIndex: number): boolean
	local data = DataService:GetData(player)
	if not data or tierIndex ~= data.ArmTier + 1 then
		return false
	end
	local tier = ArmConfig.Tiers[tierIndex]
	if not tier or data.Cash < tier.Price then
		return false
	end
	if not DataService:AdjustCash(player, -tier.Price) then
		return false
	end
	data.ArmTier = tierIndex
	publish(player)
	DataService:RequestSave(player)
	return true
end

function ArmService.Init(_self: any, _services: { [string]: any }) end

function ArmService.Start(_self: any)
	trove:Add(DataService.PlayerLoaded:Connect(function(player: Player)
		publish(player)
	end))
	for _, player in Players:GetPlayers() do
		publish(player)
	end
	Packets.BuyArm.OnServerInvoke = function(player: Player, tierIndex: number): boolean
		return ArmService:BuyTier(player, tierIndex)
	end
end

function ArmService.Destroy(_self: any)
	Packets.BuyArm.OnServerInvoke = nil
	trove:Clean()
end

return ArmService
