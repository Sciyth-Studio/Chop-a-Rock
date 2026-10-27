--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GiftPickerConfig = require(ReplicatedStorage.Config.GiftPickerConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local RobuxShopConfig = require(ReplicatedStorage.Config.RobuxShopConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ShopCards = require(script.Parent.Parent.ShopCards)
local ShopPrices = require(script.Parent.Parent.ShopPrices)
local Types = require(script.Parent.Parent.Types)

local GiftPicker = {}

local function findGift(key: any): MonetizationConfig.Gift?
	for _, gift in MonetizationConfig.Gifts do
		if gift.Key == key then
			return gift
		end
	end
	return nil
end

function GiftPicker.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local stepTrove = trove:Extend()
	ViewportScale.Bind(gui, trove)

	local player = Players.LocalPlayer
	local dataController = context.Controllers.DataController
	local purchases = context.Controllers.PurchaseController
	local panel = gui:FindFirstChild("Panel", true)
	local itemsInstance = if panel then panel:FindFirstChild("Items") else nil
	local playersInstance = if panel then panel:FindFirstChild("Players") else nil
	local items: GuiObject? = if itemsInstance and itemsInstance:IsA("GuiObject") then itemsInstance else nil
	local playerList: GuiObject? = if playersInstance and playersInstance:IsA("GuiObject")
		then playersInstance
		else nil
	local itemTemplate = if items then items:FindFirstChild("ItemTemplate") else nil
	local playerTemplate = if playerList then playerList:FindFirstChild("PlayerTemplate") else nil
	local back = if panel then ShopCards.Find(panel, "BackButton") else nil
	local empty = if panel then panel:FindFirstChild("Empty") else nil
	if not panel or not items or not playerList or not itemTemplate or not playerTemplate then
		warn(`[GiftPicker] Missing Items/Players templates in {gui:GetFullName()}`)
	end
	ShopCards.SetButton(back, "Back", RobuxShopConfig.PillColors)

	local function credits(key: string): number
		local value = dataController:Get({ "GiftCredits", key })
		return if type(value) == "number" then value else 0
	end

	local function setStep(text: string)
		if panel then
			ShopCards.SetText(panel, "Step", text)
		end
	end

	local function clear(list: Instance?)
		if not list then
			return
		end
		for _, child in list:GetChildren() do
			if child:GetAttribute("GiftRow") then
				child:Destroy()
			end
		end
	end

	local showItems: () -> ()

	local function canReceive(other: Player, gift: MonetizationConfig.Gift): (boolean, string?)
		if gift.Kind == "Pass" then
			if other:GetAttribute(MonetizationConfig.PassAttributePrefix .. gift.Target) == true then
				return false, GiftPickerConfig.OwnedText
			end
		elseif gift.Kind == "Lucky" then
			if other:GetAttribute(MonetizationConfig.RandomItemsRestrictedAttribute) == true then
				return false, GiftPickerConfig.CantReceiveText
			end
		end
		return true, nil
	end

	local function showPlayers(gift: MonetizationConfig.Gift)
		stepTrove:Clean()
		local info = ShopCards.GiftInfo(gift)
		if not info or not items or not playerList or not playerTemplate then
			return
		end
		setStep(string.format(GiftPickerConfig.PickPlayerText, info.Name))
		items.Visible = false
		playerList.Visible = true
		if back then
			back.Visible = true
		end
		clear(playerList)
		local count = 0
		for _, other in Players:GetPlayers() do
			if other == player then
				continue
			end
			count += 1
			local tray = playerTemplate:Clone()
			tray:SetAttribute("GiftRow", true)
			local inner = tray:FindFirstChild("Card")
			if tray:IsA("Frame") and inner and inner:IsA("Frame") then
				tray.Visible = true
				tray.LayoutOrder = count
				ShopCards.Paint(tray, inner, RobuxShopConfig.Palettes.Sky)
				ShopCards.SetText(inner, "Title", other.DisplayName)
				ShopCards.SetText(inner, "Ribbon", "")
				task.spawn(function()
					local ok, image = pcall(
						Players.GetUserThumbnailAsync,
						Players,
						other.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size150x150
					)
					if ok and tray.Parent then
						ShopCards.SetIcon(inner, image, false)
					end
				end)
				local send = ShopCards.Find(inner, "BuyButton")
				local isAllowed, reason = canReceive(other, gift)
				local free = credits(gift.Key)
				if not isAllowed then
					ShopCards.SetButton(send, reason or "", RobuxShopConfig.OwnedColors)
				elseif free > 0 then
					ShopCards.SetButton(
						send,
						string.format(GiftPickerConfig.FreeText, free),
						RobuxShopConfig.BuyColors
					)
				else
					ShopPrices.Watch("Product", gift.ProductId, info.Price, function(price: number)
						ShopCards.SetButton(
							send,
							`{GiftPickerConfig.SendText} {ShopPrices.Format(price)}`,
							RobuxShopConfig.BuyColors
						)
					end)
				end
				if send then
					stepTrove:Connect(send.Activated, function()
						if not isAllowed then
							context.Feedback(send, false)
							return
						end
						if credits(gift.Key) > 0 then
							task.spawn(function()
								local isSent = Packets.SendGiftCredit:Fire(other.UserId, gift.Key) == true
								context.Feedback(send, isSent)
								if isSent then
									LocalSound.Play(MonetizationConfig.BoughtSound)
									context.Close(GiftPickerConfig.ScreenName)
								end
							end)
						else
							if purchases:Gift(gift.Key, other.UserId) then
								context.Close(GiftPickerConfig.ScreenName)
							end
						end
					end)
				end
			end
			tray.Parent = playerList
		end
		if empty and empty:IsA("GuiObject") then
			empty.Visible = count == 0
		end
	end

	showItems = function()
		stepTrove:Clean()
		if not items or not playerList or not itemTemplate then
			return
		end
		setStep(GiftPickerConfig.PickGiftText)
		items.Visible = true
		playerList.Visible = false
		if back then
			back.Visible = false
		end
		if empty and empty:IsA("GuiObject") then
			empty.Visible = false
		end
		clear(items)
		local isRestricted = player:GetAttribute(MonetizationConfig.RandomItemsRestrictedAttribute) == true
		for index, gift in MonetizationConfig.Gifts do
			local info = ShopCards.GiftInfo(gift)
			if not info or (gift.Kind == "Lucky" and isRestricted) then
				continue
			end
			local tray = itemTemplate:Clone()
			tray:SetAttribute("GiftRow", true)
			local inner = tray:FindFirstChild("Card")
			if tray:IsA("Frame") and inner and inner:IsA("Frame") then
				tray.Visible = true
				tray.LayoutOrder = index
				local paletteName = GiftPickerConfig.PaletteByKind[gift.Kind] or "Sky"
				if gift.Kind == "Pass" then
					paletteName = RobuxShopConfig.PassPalettes[gift.Target] or paletteName
				end
				ShopCards.Paint(tray, inner, RobuxShopConfig.Palettes[paletteName])
				ShopCards.SetIcon(inner, info.Icon, info.HasOutline)
				ShopCards.SetText(inner, "Title", info.Name)
				local free = credits(gift.Key)
				ShopCards.SetText(inner, "Ribbon", if free > 0 then `Free x{free}!` else "")
				local pick = ShopCards.Find(inner, "BuyButton")
				ShopPrices.Watch("Product", gift.ProductId, info.Price, function(price: number)
					ShopCards.SetButton(pick, ShopPrices.Format(price), RobuxShopConfig.BuyColors)
				end)
				if pick then
					stepTrove:Connect(pick.Activated, function()
						showPlayers(gift)
					end)
				end
			end
			tray.Parent = items
		end
	end

	if back then
		trove:Connect(back.Activated, function()
			showItems()
		end)
	end
	local close = if panel then panel:FindFirstChild("CloseButton", true) else nil
	if close and close:IsA("GuiButton") then
		trove:Connect(close.Activated, function()
			context.Close(GiftPickerConfig.ScreenName)
		end)
	end

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen, argument: any?)
			gui.Enabled = true
			local gift = findGift(argument)
			if gift then
				showPlayers(gift)
			else
				showItems()
			end
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
			stepTrove:Clean()
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return GiftPicker
