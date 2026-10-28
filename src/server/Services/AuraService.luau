--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local AuraConfig = require(ReplicatedStorage.Config.AuraConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local DataService = require(script.Parent.DataService)
local NotificationService = require(script.Parent.NotificationService)
local WalkSpeedService = require(script.Parent.WalkSpeedService)

local trove = Trove.new()

local AuraService = { Name = "AuraService" }

local function apply(player: Player)
	local tierIndex = AuraService:GetTier(player)
	local tier = AuraConfig.Tiers[tierIndex]
	WalkSpeedService:SetBonus(player, AuraConfig.SpeedSource, if tier then tier.WalkSpeedBonus else 0)
	player:SetAttribute(AuraConfig.Attribute, if tier and tier.Color then tierIndex else nil)
end

function AuraService.GetTier(_self: any, player: Player): number
	local data = DataService:GetData(player)
	return if data then data.AuraTier else 1
end

function AuraService.GetTrainingMultiplier(_self: any, player: Player): number
	local tier = AuraConfig.Tiers[AuraService:GetTier(player)]
	return if tier then tier.TrainingGainMultiplier else 1
end

function AuraService.BuyTier(_self: any, player: Player, tierIndex: number): boolean
	local data = DataService:GetData(player)
	if
		not data
		or tierIndex ~= data.AuraTier + 1
		or not Tutorial.CanBuyAura(Tutorial.StepOf(data.Tutorial))
	then
		return false
	end
	local tier = AuraConfig.Tiers[tierIndex]
	if not tier or data.Cash < tier.Price then
		return false
	end
	if not DataService:AdjustCash(player, -tier.Price, AnalyticsConfig.Sinks.Aura, tostring(tierIndex)) then
		return false
	end
	DataService:Set(player, { "AuraTier" }, tierIndex)
	apply(player)
	NotificationService:Notify(player, "Purchase", `Bought {tier.DisplayName}!`)
	DataService:RequestSave(player)
	return true
end

function AuraService.SetTier(_self: any, player: Player, tierIndex: number): boolean
	if not DataService:GetData(player) or not AuraConfig.Tiers[tierIndex] then
		return false
	end
	DataService:Set(player, { "AuraTier" }, tierIndex)
	apply(player)
	DataService:RequestSave(player)
	return true
end

function AuraService.Init(_self: any, _services: { [string]: any }) end

function AuraService.Start(_self: any)
	trove:Add(DataService.PlayerLoaded:Connect(function(player: Player)
		apply(player)
	end))
	for _, player in Players:GetPlayers() do
		if DataService:GetData(player) then
			apply(player)
		end
	end
	Packets.BuyAura.OnServerInvoke = function(player: Player, tierIndex: number): boolean
		return AuraService:BuyTier(player, tierIndex)
	end
end

function AuraService.Destroy(_self: any)
	Packets.BuyAura.OnServerInvoke = nil
	trove:Clean()
end

return AuraService
