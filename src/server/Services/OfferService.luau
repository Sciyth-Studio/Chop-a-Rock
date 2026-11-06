--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local CashPack = require(ReplicatedStorage.Utils.CashPack)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)

local OfferService = { Name = "OfferService" }

local services: { [string]: any } = {}
local trove = Trove.new()

local starter = MonetizationConfig.StarterPack
local offline = MonetizationConfig.OfflineClaim

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
		services.PetService:GrantOrQueue(player, starter.PetKey)
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
	if amount > 0 then
		services.DataService:AdjustCash(
			player,
			math.floor(amount + 0.5),
			AnalyticsConfig.Sources.OfflineClaim
		)
	end
	return true
end

function OfferService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function OfferService.Start(_self: any)
	trove:Add(services.PedestalService.OfflineEarned:Connect(recordOffline))
end

function OfferService.Destroy(_self: any)
	trove:Destroy()
end

return OfferService
