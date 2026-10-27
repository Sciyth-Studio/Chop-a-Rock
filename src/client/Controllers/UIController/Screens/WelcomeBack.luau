--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local RobuxShopConfig = require(ReplicatedStorage.Config.RobuxShopConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local ShopCards = require(script.Parent.Parent.ShopCards)
local ShopPrices = require(script.Parent.Parent.ShopPrices)
local Types = require(script.Parent.Parent.Types)

local SCREEN_NAME = "WelcomeBack"
local BLOCKING_SCREENS = { "HatchReveal", "ChopMeter", "TrainingMinigame", "StarterOffer" }

local WelcomeBack = {}

function WelcomeBack.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local player = Players.LocalPlayer
	local offline = MonetizationConfig.OfflineClaim
	local uiController = context.Controllers.UIController
	local panel = gui:FindFirstChild("Panel", true)
	local body = if panel then panel:FindFirstChild("Body") else nil
	local inner = if body then body:FindFirstChild("Card") else nil
	if not body or not inner or not body:IsA("Frame") or not inner:IsA("Frame") then
		warn(`[WelcomeBack] Missing Panel.Body.Card in {gui:GetFullName()}`)
	end
	local hasShown = false
	local isOpen = false

	local claim = if inner then ShopCards.Find(inner, "ClaimButton") else nil
	local triple = if inner then ShopCards.Find(inner, "ClaimX3Button") else nil
	if body and inner and body:IsA("Frame") and inner:IsA("Frame") then
		ShopCards.Paint(body, inner, RobuxShopConfig.Palettes.Green)
		ShopCards.SetIcon(inner, IconConfig.Cash5, true)
		ShopCards.SetText(inner, "Ribbon", "")
	end
	ShopCards.SetButton(claim, "Claim!", RobuxShopConfig.BuyColors)
	ShopPrices.Watch("Product", offline.ProductId, offline.RobuxPrice, function(price: number)
		ShopCards.SetButton(triple, "Claim x3", RobuxShopConfig.PillColors)
		ShopCards.SetSub(triple, ShopPrices.Format(price))
	end)

	local function amount(): number
		local value = player:GetAttribute(offline.DueAttribute)
		return if type(value) == "number" then value else 0
	end

	if claim then
		trove:Connect(claim.Activated, function()
			Packets.ClaimOffline:Fire()
			LocalSound.Play(MonetizationConfig.BoughtSound)
			context.Close(SCREEN_NAME)
		end)
	end
	if triple then
		trove:Connect(triple.Activated, function()
			context.Controllers.PurchaseController:PromptOfflineClaim()
		end)
	end
	local close = if panel then panel:FindFirstChild("CloseButton", true) else nil
	if close and close:IsA("GuiButton") then
		trove:Connect(close.Activated, function()
			context.Close(SCREEN_NAME)
		end)
	end

	trove:Connect(player:GetAttributeChangedSignal(offline.DueAttribute), function()
		if isOpen and amount() <= 0 then
			LocalSound.Play(MonetizationConfig.BoughtSound)
			context.Close(SCREEN_NAME)
		end
	end)

	local lastCheck = 0
	trove:Connect(RunService.Heartbeat, function()
		if hasShown or os.clock() - lastCheck < 1 then
			return
		end
		lastCheck = os.clock()
		local step = Tutorial.StepOf(context.Controllers.DataController:Get({ "Tutorial" }))
		if amount() <= 0 or uiController:IsModalOpen() or Tutorial.IsActive(step) then
			return
		end
		for _, name in BLOCKING_SCREENS do
			if uiController:IsOpen(name) then
				return
			end
		end
		hasShown = true
		context.Open(SCREEN_NAME)
	end)

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = true
			if inner then
				ShopCards.SetText(inner, "Title", `+${NumberFormat.Compact(amount())}`)
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

return WelcomeBack
