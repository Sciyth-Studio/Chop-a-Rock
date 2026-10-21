--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CashPackConfig = require(ReplicatedStorage.Config.CashPackConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)

local CashPack = {}

function CashPack.Value(pack: CashPackConfig.Pack, strength: number): number
	local key = GeodeOrder.ForStrength(strength)
	local geode = if key then GeodeConfig.Geodes[key] else nil
	return if geode then geode.Price * pack.Geodes else 0
end

function CashPack.Covering(shortfall: number, strength: number): number
	for index, pack in CashPackConfig.Packs do
		if CashPack.Value(pack, strength) >= shortfall then
			return index
		end
	end
	return #CashPackConfig.Packs
end

function CashPack.ByProductId(productId: number): CashPackConfig.Pack?
	for _, pack in CashPackConfig.Packs do
		if pack.ProductId == productId then
			return pack
		end
	end
	return nil
end

return CashPack
