--!strict

local AvatarEditorService = game:GetService("AvatarEditorService")
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FreeGiftConfig = require(ReplicatedStorage.Config.FreeGiftConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local RobuxShopConfig = require(ReplicatedStorage.Config.RobuxShopConfig)
local CashPack = require(ReplicatedStorage.Utils.CashPack)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ShopCards = require(script.Parent.Parent.ShopCards)
local Types = require(script.Parent.Parent.Types)

local SCREEN_NAME = "FreeGift"

local FreeGift = {}

function FreeGift.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local dataController = context.Controllers.DataController
	local texts = FreeGiftConfig.Texts
	local results = FreeGiftConfig.Results
	local panel = gui:FindFirstChild("Panel", true)
	local body = if panel then panel:FindFirstChild("Body") else nil
	local inner = if body then body:FindFirstChild("Card") else nil
	if not body or not inner or not body:IsA("Frame") or not inner:IsA("Frame") then
		warn(`[FreeGift] Missing Panel.Body.Card in {gui:GetFullName()}`)
	end
	local claim = if inner then ShopCards.Find(inner, "ClaimButton") else nil
	local isBusy = false
	local hintThread: thread? = nil

	if body and inner and body:IsA("Frame") and inner:IsA("Frame") then
		ShopCards.Paint(body, inner, RobuxShopConfig.Palettes.Green)
		ShopCards.SetIcon(inner, FreeGiftConfig.RewardImage, true)
		ShopCards.SetText(inner, "Hint", "")
	end
	if panel then
		local header = panel:FindFirstChild("Header")
		if header then
			for _, name in { "Title", "TitleShadow" } do
				local label = header:FindFirstChild(name, true)
				if label and label:IsA("TextLabel") then
					label.Text = texts.Title
				end
			end
		end
	end

	local function isClaimed(): boolean
		return dataController:Get({ "Offers", FreeGiftConfig.OfferKey }) == true
	end

	local function showHint(text: string)
		if not inner then
			return
		end
		ShopCards.SetText(inner, "Hint", text)
		if hintThread then
			task.cancel(hintThread)
		end
		hintThread = task.delay(FreeGiftConfig.HintSeconds, function()
			hintThread = nil
			ShopCards.SetText(inner, "Hint", "")
		end)
	end

	local function refresh()
		if inner then
			local strength = dataController:Get({ "Strength" })
			local cash =
				CashPack.GeodeValue(FreeGiftConfig.Geodes, if type(strength) == "number" then strength else 0)
			ShopCards.SetText(inner, "Reward", string.format(texts.Reward, "$" .. NumberFormat.Commas(cash)))
		end
		if isClaimed() then
			ShopCards.SetButton(claim, texts.Claimed, RobuxShopConfig.OwnedColors)
		else
			ShopCards.SetButton(claim, texts.Claim, RobuxShopConfig.BuyColors)
		end
	end

	local actions: { [string]: () -> () } = {
		Favorite = function()
			pcall(
				AvatarEditorService.PromptSetFavorite,
				AvatarEditorService,
				game.PlaceId,
				Enum.AvatarItemType.Asset,
				true
			)
		end,
		Join = function()
			task.spawn(pcall, GroupService.PromptJoinAsync, GroupService, FreeGiftConfig.GroupId)
		end,
	}

	local steps = if inner then inner:FindFirstChild("Steps") else nil
	for index, step in FreeGiftConfig.Steps do
		local card = if steps then steps:FindFirstChild(`Step{index}`) else nil
		if not card then
			warn(`[FreeGift] Missing Steps.Step{index} in {gui:GetFullName()}`)
			continue
		end
		ShopCards.SetText(card, "Title", step.Title)
		local shot = card:FindFirstChild("Shot")
		if shot and shot:IsA("ImageLabel") and step.Image ~= "" then
			shot.Image = step.Image
		end
		local button = card:FindFirstChild("Button")
		local action = actions[step.Action]
		if button and button:IsA("GuiButton") then
			button.Active = action ~= nil
			if action then
				trove:Connect(button.Activated, action)
			end
		end
	end

	if claim then
		trove:Connect(claim.Activated, function()
			if isBusy then
				return
			end
			if isClaimed() then
				context.Feedback(claim, false)
				return
			end
			isBusy = true
			task.spawn(function()
				local result = Packets.ClaimFreeGift:Fire()
				isBusy = false
				if result == results.Claimed or result == results.AlreadyClaimed then
					LocalSound.Play(MonetizationConfig.BoughtSound)
					context.Feedback(claim, true)
					refresh()
					return
				end
				context.Feedback(claim, false)
				showHint(if result == results.NotInGroup then texts.JoinFirst else texts.TryAgain)
			end)
		end)
	end
	local close = if panel then panel:FindFirstChild("CloseButton", true) else nil
	if close and close:IsA("GuiButton") then
		trove:Connect(close.Activated, function()
			context.Close(SCREEN_NAME)
		end)
	end

	trove:Add(dataController:Observe({ "Offers", FreeGiftConfig.OfferKey }, refresh))
	trove:Add(function()
		if hintThread then
			task.cancel(hintThread)
		end
	end)

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			refresh()
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return FreeGift
