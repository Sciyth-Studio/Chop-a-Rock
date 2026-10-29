--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CashPackConfig = require(ReplicatedStorage.Config.CashPackConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local CashPack = require(ReplicatedStorage.Utils.CashPack)
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

local function strength(): number
	local value = controllers.DataController:Get({ "PeakStrength" })
	return if type(value) == "number" then value else 0
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

function PurchaseController.PromptBoost(_self: any, key: string, index: number): boolean
	for _, boost in MonetizationConfig.Boosts do
		if boost.Key == key then
			local product = boost.Products[index]
			return product ~= nil and promptProduct(product.ProductId)
		end
	end
	return false
end

function PurchaseController.PromptServerBoost(_self: any, key: string): boolean
	for _, boost in MonetizationConfig.ServerBoosts do
		if boost.Key == key then
			return promptProduct(boost.ProductId)
		end
	end
	return false
end

function PurchaseController.PromptLucky(_self: any, index: number, zoneKey: string?): boolean
	local product = MonetizationConfig.LuckyGeodeProducts[index]
	if not product then
		return false
	end
	if zoneKey then
		Packets.SetLuckyGeodeZone:Fire(zoneKey)
	end
	return promptProduct(product.ProductId)
end

function PurchaseController.PromptStarterPack(_self: any): boolean
	return promptProduct(MonetizationConfig.StarterPack.ProductId)
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

function PurchaseController.CoveringPack(_self: any, shortfall: number): CashPackConfig.Pack?
	if shortfall <= 0 then
		return nil
	end
	return CashPackConfig.Packs[CashPack.Covering(shortfall, strength())]
end

function PurchaseController.PromptCash(_self: any, shortfall: number)
	controllers.CashPackController:Prompt(shortfall)
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
