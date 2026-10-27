--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CashPackConfig = require(ReplicatedStorage.Config.CashPackConfig)
local CashPack = require(ReplicatedStorage.Utils.CashPack)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)

export type Grant = (player: Player, services: { [string]: any }) -> boolean

local Products: { [number]: Grant } = {}

for _, pack in CashPackConfig.Packs do
	local productId = pack.ProductId
	if not productId then
		continue
	end
	Products[productId] = function(player: Player, services: { [string]: any }): boolean
		local data = services.DataService:GetData(player)
		if not data then
			return false
		end
		local amount = CashPack.Value(pack, data.Strength)
		if amount <= 0 then
			return false
		end
		return services.DataService:AdjustCash(player, amount)
	end
end

local starterProductId = MonetizationConfig.StarterPack.ProductId
if starterProductId then
	Products[starterProductId] = function(player: Player, services: { [string]: any }): boolean
		return services.OfferService:GrantStarterPack(player)
	end
end

for _, item in MonetizationConfig.Exclusives.Items do
	local productId = item.ProductId
	if productId then
		Products[productId] = function(player: Player, services: { [string]: any }): boolean
			return services.ExclusiveService:Grant(player, item.Key)
		end
	end
end

local offlineProductId = MonetizationConfig.OfflineClaim.ProductId
if offlineProductId then
	Products[offlineProductId] = function(player: Player, services: { [string]: any }): boolean
		return services.OfferService:GrantOfflineClaim(player)
	end
end

for _, boost in MonetizationConfig.Boosts do
	for _, product in boost.Products do
		local productId = product.ProductId
		if productId then
			Products[productId] = function(player: Player, services: { [string]: any }): boolean
				return services.BoostService:AddPersonal(player, boost.Key, product.Seconds)
			end
		end
	end
end

for _, product in MonetizationConfig.LuckyGeodeProducts do
	local productId = product.ProductId
	if productId then
		Products[productId] = function(player: Player, services: { [string]: any }): boolean
			local data = services.DataService:GetData(player)
			if not data or not services.GeodeService:GrantLucky(player, product.Count) then
				return false
			end
			if product.IsFirstOnly then
				services.DataService:Set(player, { "Offers", MonetizationConfig.FirstLuckyOfferKey }, true)
			end
			return true
		end
	end
end

for _, boost in MonetizationConfig.ServerBoosts do
	local productId = boost.ProductId
	if productId then
		Products[productId] = function(player: Player, services: { [string]: any }): boolean
			return services.BoostService:AddServer(boost.Key, boost.Seconds, player)
		end
	end
end

return Products
