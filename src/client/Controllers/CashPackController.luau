--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CashPackConfig = require(ReplicatedStorage.Config.CashPackConfig)
local CashPack = require(ReplicatedStorage.Utils.CashPack)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Trove = require(ReplicatedStorage.Packages.Trove)

local CashPackController = { Name = "CashPackController" }
local controllers: { [string]: any } = {}
local trove = Trove.new()

local function strength(): number
	local value = controllers.DataController:Get({ "Strength" })
	return if type(value) == "number" then value else 0
end

function CashPackController.Prompt(_self: any, shortfall: number)
	if shortfall <= 0 then
		return
	end
	local pack = CashPackConfig.Packs[CashPack.Covering(shortfall, strength())]
	if pack then
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, pack.ProductId)
	end
end

function CashPackController.Init(_self: any, registry: { [string]: any })
	controllers = registry
end

function CashPackController.Start(_self: any)
	trove:Connect(
		MarketplaceService.PromptProductPurchaseFinished,
		function(userId: number, productId: number, isPurchased: boolean)
			if not isPurchased or userId ~= Players.LocalPlayer.UserId then
				return
			end
			local pack = CashPack.ByProductId(productId)
			if not pack then
				return
			end
			LocalSound.Play(CashPackConfig.BoughtSound)
			local notifications = controllers.NotificationController
			if notifications then
				notifications:Notify(
					CashPackConfig.BoughtKind,
					string.format(
						CashPackConfig.BoughtFormat,
						NumberFormat.Compact(CashPack.Value(pack, strength()), 1e3)
					)
				)
			end
		end
	)
end

function CashPackController.Destroy(_self: any)
	trove:Destroy()
end

return CashPackController
