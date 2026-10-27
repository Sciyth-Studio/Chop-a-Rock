--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CashPackConfig = require(ReplicatedStorage.Config.CashPackConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local CashPack = require(ReplicatedStorage.Utils.CashPack)

local Gifts = {}

local byKey: { [string]: MonetizationConfig.Gift } = {}
local byProductId: { [number]: MonetizationConfig.Gift } = {}
for _, gift in MonetizationConfig.Gifts do
	byKey[gift.Key] = gift
	if gift.ProductId then
		byProductId[gift.ProductId] = gift
	end
end

local function boostOf(gift: MonetizationConfig.Gift): MonetizationConfig.BoostProduct?
	for _, boost in MonetizationConfig.Boosts do
		if boost.Key == gift.Target then
			return boost.Products[gift.Index or 1]
		end
	end
	return nil
end

local function packOf(gift: MonetizationConfig.Gift): CashPackConfig.Pack?
	for _, pack in CashPackConfig.Packs do
		if pack.Key == gift.Target then
			return pack
		end
	end
	return nil
end

function Gifts.ByKey(key: string): MonetizationConfig.Gift?
	return byKey[key]
end

function Gifts.ByProductId(productId: number): MonetizationConfig.Gift?
	return byProductId[productId]
end

function Gifts.DisplayName(gift: MonetizationConfig.Gift): string
	if gift.Kind == "Pass" then
		for _, pass in MonetizationConfig.Passes do
			if pass.Key == gift.Target then
				return pass.DisplayName
			end
		end
	elseif gift.Kind == "Boost" then
		local product = boostOf(gift)
		local minutes = if product then math.floor(product.Seconds / 60) else 0
		return `2x {gift.Target} ({minutes} min)`
	elseif gift.Kind == "Lucky" then
		local product = MonetizationConfig.LuckyGeodeProducts[gift.Index or 2]
		local count = if product then product.Count else 1
		return if count == 1 then "a Lucky Geode" else `{count} Lucky Geodes`
	elseif gift.Kind == "CashPack" then
		return `a {gift.Target} cash pack`
	elseif gift.Kind == "Exclusive" then
		local pet = PetConfig.Pets[gift.Target]
		return if pet then pet.DisplayName else gift.Target
	end
	return gift.Key
end

function Gifts.CanReceive(
	services: { [string]: any },
	recipient: Player,
	gift: MonetizationConfig.Gift
): boolean
	local data = services.DataService:GetData(recipient)
	if not data then
		return false
	end
	if gift.Kind == "Pass" then
		return not services.PassService:Owns(recipient, gift.Target)
	elseif gift.Kind == "Lucky" then
		return not services.PassService:IsRandomItemsRestricted(recipient)
	elseif gift.Kind == "Exclusive" then
		return data.Exclusives[gift.Target] ~= true
	end
	return true
end

function Gifts.Apply(services: { [string]: any }, recipient: Player, gift: MonetizationConfig.Gift): boolean
	local data = services.DataService:GetData(recipient)
	if not data then
		return false
	end
	if gift.Kind == "Pass" then
		services.DataService:Set(recipient, { "Passes", gift.Target }, true)
		services.PassService:Refresh(recipient)
		return true
	elseif gift.Kind == "Boost" then
		local product = boostOf(gift)
		return product ~= nil and services.BoostService:AddPersonal(recipient, gift.Target, product.Seconds)
	elseif gift.Kind == "Lucky" then
		local product = MonetizationConfig.LuckyGeodeProducts[gift.Index or 2]
		return product ~= nil and services.GeodeService:GrantLucky(recipient, product.Count) ~= nil
	elseif gift.Kind == "CashPack" then
		local pack = packOf(gift)
		local amount = if pack then CashPack.Value(pack, data.Strength) else 0
		return amount > 0 and services.DataService:AdjustCash(recipient, amount)
	elseif gift.Kind == "Exclusive" then
		return services.ExclusiveService:Grant(recipient, gift.Target)
	end
	return false
end

function Gifts.Credit(services: { [string]: any }, player: Player, gift: MonetizationConfig.Gift): boolean
	local data = services.DataService:GetData(player)
	if not data then
		return false
	end
	services.DataService:Set(player, { "GiftCredits", gift.Key }, (data.GiftCredits[gift.Key] or 0) + 1)
	return true
end

function Gifts.Remember(data: any, purchaseId: string)
	local received = data.GiftsReceived
	received[purchaseId] = os.time()
	local ids = {}
	for id in received do
		table.insert(ids, id)
	end
	if #ids <= MonetizationConfig.MaxGiftsReceived then
		return
	end
	table.sort(ids, function(a, b)
		return received[a] < received[b]
	end)
	for index = 1, #ids - MonetizationConfig.MaxGiftsReceived do
		received[ids[index]] = nil
	end
end

return Gifts
