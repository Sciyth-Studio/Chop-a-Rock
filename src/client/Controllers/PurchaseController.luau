--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Packets = require(ReplicatedStorage.Packets)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PurchaseController = {
	Name = "PurchaseController",
	Prompted = Signal.new() :: Signal.Signal<(string, number)>,
}
local controllers: { [string]: any } = {}
local trove = Trove.new()

local function notify(message: string)
	local notifications = controllers.NotificationController
	if notifications then
		notifications:Notify("Info", message)
	end
end

local function promptProduct(productId: number?): boolean
	if not productId then
		notify(MonetizationConfig.ComingSoonText)
		return false
	end
	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
	PurchaseController.Prompted:Fire("Product", productId)
	return true
end

local function findPass(key: string): MonetizationConfig.Pass?
	for _, pass in MonetizationConfig.Passes do
		if pass.Key == key then
			return pass
		end
	end
	return nil
end

function PurchaseController.OwnsPass(_self: any, key: string): boolean
	return Players.LocalPlayer:GetAttribute(MonetizationConfig.PassAttributePrefix .. key) == true
end

function PurchaseController.PromptPass(_self: any, key: string): boolean
	local pass = findPass(key)
	if not pass or PurchaseController:OwnsPass(key) then
		return false
	end
	if not pass.GamepassId then
		notify(MonetizationConfig.ComingSoonText)
		return false
	end
	MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, pass.GamepassId)
	PurchaseController.Prompted:Fire("Pass", pass.GamepassId)
	return true
end

local function isOverCap(left: number, seconds: number, cap: number): boolean
	if left + seconds <= cap then
		return false
	end
	notify(string.format(MonetizationConfig.BoostFullText, cap // 3600))
	return true
end

function PurchaseController.GetBoostSecondsLeft(_self: any, key: string): number
	local player = Players.LocalPlayer
	local paused = player:GetAttribute(MonetizationConfig.BoostPausedAttributePrefix .. key)
	if type(paused) == "number" then
		return paused
	end
	local endsAt = player:GetAttribute(MonetizationConfig.BoostEndsAttributePrefix .. key)
	if type(endsAt) ~= "number" then
		return 0
	end
	return math.max(endsAt - workspace:GetServerTimeNow(), 0)
end

function PurchaseController.PromptBoost(_self: any, key: string, index: number): boolean
	for _, boost in MonetizationConfig.Boosts do
		if boost.Key == key then
			local product = boost.Products[index]
			if not product then
				return false
			end
			local left = PurchaseController:GetBoostSecondsLeft(key)
			if isOverCap(left, product.Seconds, MonetizationConfig.BoostCapSeconds) then
				return false
			end
			return promptProduct(product.ProductId)
		end
	end
	return false
end

function PurchaseController.PromptServerBoost(_self: any, key: string): boolean
	for _, boost in MonetizationConfig.ServerBoosts do
		if boost.Key == key then
			local endsAt = workspace:GetAttribute(MonetizationConfig.ServerBoostEndsAttributePrefix .. key)
			local left = if type(endsAt) == "number"
				then math.max(endsAt - workspace:GetServerTimeNow(), 0)
				else 0
			if isOverCap(left, boost.Seconds, MonetizationConfig.ServerBoostCapSeconds) then
				return false
			end
			return promptProduct(boost.ProductId)
		end
	end
	return false
end

function PurchaseController.PromptLucky(_self: any, index: number): boolean
	local product = MonetizationConfig.LuckyGeodeProducts[index]
	if not product then
		return false
	end
	return promptProduct(product.ProductId)
end

function PurchaseController.PromptOfflineClaim(_self: any): boolean
	return promptProduct(MonetizationConfig.OfflineClaim.ProductId)
end

function PurchaseController.PromptExclusive(_self: any, key: string): boolean
	for _, item in MonetizationConfig.Exclusives.Items do
		if item.Key == key then
			return promptProduct(item.ProductId)
		end
	end
	return false
end

function PurchaseController.Gift(_self: any, giftKey: string, userId: number): boolean
	for _, gift in MonetizationConfig.Gifts do
		if gift.Key == giftKey then
			Packets.SetGiftTarget:Fire(userId, giftKey)
			return promptProduct(gift.ProductId)
		end
	end
	return false
end

function PurchaseController.Init(_self: any, registry: { [string]: any })
	controllers = registry
end

function PurchaseController.Start(_self: any)
	trove:Connect(
		MarketplaceService.PromptGamePassPurchaseFinished,
		function(player: Player, gamepassId: number, wasPurchased: boolean)
			if not wasPurchased or player ~= Players.LocalPlayer then
				return
			end
			for _, pass in MonetizationConfig.Passes do
				if pass.GamepassId == gamepassId then
					LocalSound.Play(MonetizationConfig.BoughtSound)
					if controllers.NotificationController then
						controllers.NotificationController:Notify("Purchase", `{pass.DisplayName} unlocked!`)
					end
				end
			end
		end
	)
end

function PurchaseController.Destroy(_self: any)
	trove:Destroy()
end

return PurchaseController
