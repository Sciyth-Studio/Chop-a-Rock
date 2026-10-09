--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArmConfig = require(ReplicatedStorage.Config.ArmConfig)
local Packets = require(ReplicatedStorage.Packets)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local DataService = require(script.Parent.DataService)
local NotificationService = require(script.Parent.NotificationService)

local trove = Trove.new()

local ArmService = {
	Name = "ArmService",
	TierChanged = Signal.new() :: Signal.Signal<(Player, number)>,
}

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
	DataService:Set(player, { "ArmTier" }, tierIndex)
	NotificationService:Notify(player, "Purchase", `Bought {tier.DisplayName}!`)
	ArmService.TierChanged:Fire(player, tierIndex)
	DataService:RequestSave(player)
	return true
end

function ArmService.SetTier(_self: any, player: Player, tierIndex: number): boolean
	if not DataService:GetData(player) or not ArmConfig.Tiers[tierIndex] then
		return false
	end
	DataService:Set(player, { "ArmTier" }, tierIndex)
	ArmService.TierChanged:Fire(player, tierIndex)
	DataService:RequestSave(player)
	return true
end

function ArmService.Init(_self: any, _services: { [string]: any }) end

function ArmService.Start(_self: any)
	trove:Add(DataService.PlayerLoaded:Connect(function(player: Player, data)
		ArmService.TierChanged:Fire(player, data.ArmTier)
	end))
	Packets.BuyArm.OnServerInvoke = function(player: Player, tierIndex: number): boolean
		return ArmService:BuyTier(player, tierIndex)
	end
end

function ArmService.Destroy(_self: any)
	Packets.BuyArm.OnServerInvoke = nil
	trove:Clean()
end

return ArmService
