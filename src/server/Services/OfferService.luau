--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local CashPack = require(ReplicatedStorage.Utils.CashPack)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)

local OfferService = { Name = "OfferService" }

local services: { [string]: any } = {}
local trove = Trove.new()

local starter = MonetizationConfig.StarterPack
local offline = MonetizationConfig.OfflineClaim

local function openStarterWindow(player: Player)
	local data = services.DataService:GetData(player)
	if not data or data.StarterPack.Bought then
		return
	end
	services.DataService:Set(player, { "StarterPack", "OfferEndsAt" }, os.time() + starter.OfferSeconds)
	player:SetAttribute(starter.DueAttribute, true)
end

local function recordOffline(player: Player, amount: number, seconds: number)
	local data = services.DataService:GetData(player)
	if not data or seconds < offline.MinAwaySeconds or Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
		return
	end
	if amount < CashPack.GeodeValue(offline.MinGeodes, data.PeakStrength) then
		return
	end
	services.DataService:Set(player, { "Offline" }, { LastAmount = amount, LastAt = os.time() })
	player:SetAttribute(offline.DueAttribute, amount)
end

function OfferService.GrantStarterPack(_self: any, player: Player): boolean
	local data = services.DataService:GetData(player)
	if not data then
		return false
	end
	local isRestricted = services.PassService:IsRandomItemsRestricted(player)
	local geodes = starter.Geodes + if isRestricted then starter.RestrictedExtraGeodes else 0
	local cash = CashPack.GeodeValue(geodes, data.PeakStrength)
	if cash > 0 then
		services.DataService:AdjustCash(player, cash, AnalyticsConfig.Sources.StarterPack)
	end
	services.BoostService:AddPersonal(player, starter.BoostKey, starter.BoostSeconds)
	if not isRestricted then
		services.GeodeService:GrantLucky(player, starter.LuckyGeodes)
	end
	if not data.StarterPack.Bought then
		services.DataService:Set(player, { "StarterPack", "Bought" }, true)
		services.PetService:GrantOrQueue(player, starter.RokKey)
	end
	return true
end

function OfferService.GrantOfflineClaim(_self: any, player: Player): boolean
	local data = services.DataService:GetData(player)
	if not data then
		return false
	end
	local amount = data.Offline.LastAmount * offline.ExtraMultiplier
	services.DataService:Set(player, { "Offline", "LastAmount" }, 0)
	player:SetAttribute(offline.DueAttribute, nil)
	services.PedestalService:CollectAll(player)
	if amount > 0 then
		services.DataService:AdjustCash(
			player,
			math.floor(amount + 0.5),
			AnalyticsConfig.Sources.OfflineClaim
		)
	end
	return true
end

function OfferService.IsStarterOfferOpen(_self: any, player: Player): boolean
	local data = services.DataService:GetData(player)
	return data ~= nil and not data.StarterPack.Bought and os.time() < data.StarterPack.OfferEndsAt
end

function OfferService.ResetStarterPack(_self: any, player: Player): boolean
	local data = services.DataService:GetData(player)
	if not data then
		return false
	end
	services.DataService:Set(
		player,
		{ "StarterPack" },
		{ Bought = false, OfferEndsAt = 0, SecondChanceUsed = false }
	)
	return true
end

function OfferService.OpenStarterWindow(_self: any, player: Player)
	openStarterWindow(player)
end

function OfferService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function OfferService.Start(_self: any)
	trove:Add(services.RockHintService.Finished:Connect(function(player: Player)
		local data = services.DataService:GetData(player)
		if data and data.StarterPack.OfferEndsAt == 0 then
			openStarterWindow(player)
		end
	end))
	trove:Add(services.RebirthService.Reborn:Connect(function(player: Player)
		local data = services.DataService:GetData(player)
		if not data or data.StarterPack.Bought or data.StarterPack.SecondChanceUsed then
			return
		end
		if data.StarterPack.OfferEndsAt == 0 or os.time() < data.StarterPack.OfferEndsAt then
			return
		end
		services.DataService:Set(player, { "StarterPack", "SecondChanceUsed" }, true)
		openStarterWindow(player)
	end))
	trove:Add(services.PedestalService.OfflineEarned:Connect(recordOffline))
	trove:Add(Packets.ClaimOffline.OnServerEvent:Connect(function(player: Player)
		services.PedestalService:CollectAll(player)
	end))
	trove:Add(Packets.StarterOfferShown.OnServerEvent:Connect(function(player: Player)
		player:SetAttribute(starter.DueAttribute, nil)
	end))
end

function OfferService.Destroy(_self: any)
	trove:Destroy()
end

return OfferService
