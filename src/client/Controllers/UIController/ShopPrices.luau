--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)

local ShopPrices = {}

local cache: { [string]: number } = {}
local pending: { [string]: { (number) -> () } } = {}

function ShopPrices.Format(price: number): string
	return `{MonetizationConfig.RobuxGlyph} {NumberFormat.Commas(price)}`
end

function ShopPrices.Watch(kind: "Product" | "Pass", id: number?, fallback: number, apply: (number) -> ())
	if not id then
		apply(fallback)
		return
	end
	local key = `{kind}{id}`
	local known = cache[key]
	if known then
		apply(known)
		return
	end
	apply(fallback)
	local waiting = pending[key]
	if waiting then
		table.insert(waiting, apply)
		return
	end
	pending[key] = { apply }
	task.spawn(function()
		local infoType = if kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		local price = if ok
				and type(info) == "table"
				and type(info.PriceInRobux) == "number"
			then info.PriceInRobux
			else nil
		local callbacks: { (number) -> () } = pending[key] or {}
		pending[key] = nil
		if price then
			cache[key] = price
			for _, callback in callbacks do
				callback(price)
			end
		end
	end)
end

return ShopPrices
