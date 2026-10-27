--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local RobuxShopConfig = require(ReplicatedStorage.Config.RobuxShopConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local ShopCards = require(script.Parent.Parent.ShopCards)
local ShopPrices = require(script.Parent.Parent.ShopPrices)
local Types = require(script.Parent.Parent.Types)

local SCREEN_NAME = "StarterOffer"
local BLOCKING_SCREENS = { "HatchReveal", "ChopMeter", "TrainingMinigame" }

local StarterOffer = {}

function StarterOffer.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local player = Players.LocalPlayer
	local starter = MonetizationConfig.StarterPack
	local dataController = context.Controllers.DataController
	local uiController = context.Controllers.UIController
	local panel = gui:FindFirstChild("Panel", true)
	local tray = if panel then panel:FindFirstChild("StarterCard") else nil
	local inner = if tray then tray:FindFirstChild("Card") else nil
	if not panel or not tray or not inner or not tray:IsA("Frame") or not inner:IsA("Frame") then
		warn(`[StarterOffer] Missing Panel.StarterCard.Card in {gui:GetFullName()}`)
	end
	local isOpen = false

	local function readNumber(path: { string }): number
		local value = dataController:Get(path)
		return if type(value) == "number" then value else 0
	end

	if tray and inner and tray:IsA("Frame") and inner:IsA("Frame") then
		ShopCards.Paint(tray, inner, RobuxShopConfig.Palettes.Sky)
		ShopCards.SetText(inner, "Title", RobuxShopConfig.Texts.StarterTitle)
		local buy = ShopCards.Find(inner, "BuyButton")
		ShopPrices.Watch("Product", starter.ProductId, starter.RobuxPrice, function(price: number)
			ShopCards.SetButton(buy, ShopPrices.Format(price), RobuxShopConfig.BuyColors)
		end)
		if buy then
			trove:Connect(buy.Activated, function()
				context.Controllers.PurchaseController:PromptStarterPack()
			end)
		end
	end
	local later = if panel then ShopCards.Find(panel, "LaterButton") else nil
	ShopCards.SetButton(later, "Maybe later", RobuxShopConfig.PillColors)
	local close = if panel then panel:FindFirstChild("CloseButton", true) else nil
	for _, button: Instance? in { later :: Instance?, close } do
		if button and button:IsA("GuiButton") then
			trove:Connect(button.Activated, function()
				context.Close(SCREEN_NAME)
			end)
		end
	end

	local function isFree(): boolean
		if
			uiController:IsModalOpen()
			or Tutorial.IsActive(Tutorial.StepOf(dataController:Get({ "Tutorial" })))
		then
			return false
		end
		for _, name in BLOCKING_SCREENS do
			if uiController:IsOpen(name) then
				return false
			end
		end
		return true
	end

	local lastCheck = 0
	trove:Connect(RunService.Heartbeat, function()
		local now = workspace:GetServerTimeNow()
		local endsAt = readNumber({ "StarterPack", "OfferEndsAt" })
		local isBought = dataController:Get({ "StarterPack", "Bought" }) == true
		if isOpen then
			if inner then
				ShopCards.SetText(inner, "Timer", ShopCards.Clock(endsAt - now))
			end
			if isBought or now >= endsAt then
				context.Close(SCREEN_NAME)
			end
			return
		end
		if os.clock() - lastCheck < 1 then
			return
		end
		lastCheck = os.clock()
		if
			player:GetAttribute(starter.DueAttribute) == true
			and not isBought
			and now < endsAt
			and isFree()
		then
			Packets.StarterOfferShown:Fire()
			context.Open(SCREEN_NAME)
		end
	end)

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = true
			if inner then
				local isRestricted = player:GetAttribute(MonetizationConfig.RandomItemsRestrictedAttribute)
					== true
				ShopCards.FillStarter(inner, readNumber({ "Strength" }), isRestricted)
			end
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			isOpen = false
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return StarterOffer
