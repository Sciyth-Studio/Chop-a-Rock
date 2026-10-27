--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local RobuxShopConfig = require(ReplicatedStorage.Config.RobuxShopConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local ShopCards = require(script.Parent.Parent.ShopCards)
local ShopPrices = require(script.Parent.Parent.ShopPrices)
local Types = require(script.Parent.Parent.Types)

local ROTATE_SECONDS = 5
local PROMPT_SECONDS = 8
local CHAIN_SECONDS = 60
local MAX_PROMPTS = 2
local SINGLE_BUTTON_HEIGHT = 244

type Offer = {
	Key: string,
	Title: string,
	Icon: string,
	Palette: string,
	ProductId: number?,
	Price: number,
	EndsAt: () -> number,
	Buy: () -> (),
}

type Prompt = {
	Tray: Frame,
	Trove: any,
	ExpiresAt: number?,
	IsDone: (() -> boolean)?,
}

local OfferRail = {}

function OfferRail.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local dataController = context.Controllers.DataController
	local purchases = context.Controllers.PurchaseController
	local uiController = context.Controllers.UIController
	local container = gui:FindFirstChild("Container")
	local offerTemplate = if container then container:FindFirstChild("OfferTemplate") else nil
	local promptTemplate = if container then container:FindFirstChild("PromptTemplate") else nil
	if not container or not container:IsA("GuiObject") or not offerTemplate or not promptTemplate then
		warn(`[OfferRail] Missing Container.OfferTemplate / PromptTemplate in {gui:GetFullName()}`)
		return {
			Modal = false,
			StartsOpen = false,
			Open = function(_self: Types.Screen) end,
			Close = function(_self: Types.Screen) end,
			Destroy = function(_self: Types.Screen)
				trove:Destroy()
			end,
		}
	end

	local function readNumber(path: { string }): number
		local value = dataController:Get(path)
		return if type(value) == "number" then value else 0
	end

	local starter = MonetizationConfig.StarterPack

	local offers: { Offer } = {
		{
			Key = "Starter",
			Title = RobuxShopConfig.Texts.StarterTitle,
			Icon = IconConfig.Gift,
			Palette = "Sky",
			ProductId = starter.ProductId,
			Price = starter.RobuxPrice,
			EndsAt = function(): number
				if dataController:Get({ "StarterPack", "Bought" }) == true then
					return 0
				end
				return readNumber({ "StarterPack", "OfferEndsAt" })
			end,
			Buy = function()
				purchases:PromptStarterPack()
			end,
		},
	}

	local function starterIcons(): { { Icon: string, HasOutline: boolean } }
		local icons = {
			{ Icon = IconConfig.Cash3, HasOutline = true },
			{ Icon = IconConfig.Strength, HasOutline = true },
		}
		if Players.LocalPlayer:GetAttribute(MonetizationConfig.RandomItemsRestrictedAttribute) ~= true then
			table.insert(icons, { Icon = IconConfig.LuckyGeode, HasOutline = true })
		end
		local champIcon = ShopCards.PetIcon(starter.RokKey)
		if champIcon then
			table.insert(icons, { Icon = champIcon, HasOutline = false })
		end
		return icons
	end

	local prompts: { Prompt } = {}
	local slot = offerTemplate:Clone()
	slot.Name = "Offer"
	slot.Parent = container
	local slotButton = ShopCards.Find(slot, "Button")
	local current: Offer? = nil
	local index = 0
	local lastRotate = -math.huge

	local function showOffer(offer: Offer?)
		current = offer
		if not slot:IsA("GuiObject") then
			return
		end
		slot.Visible = offer ~= nil and #prompts == 0
		if not offer then
			return
		end
		local stack = slot:FindFirstChild("Stack")
		local icons = if stack and offer.Key == "Starter" then starterIcons() else {}
		ShopCards.SetIcon(slot, if #icons > 0 then "" else offer.Icon, #icons == 0)
		if stack then
			for index, frame in stack:GetChildren() do
				local slotIndex = tonumber(string.match(frame.Name, "^Slot(%d+)$"))
				local entry = if slotIndex then icons[slotIndex] else nil
				ShopCards.SetIcon(frame, if entry then entry.Icon else "", entry ~= nil and entry.HasOutline)
			end
		end
		ShopCards.SetText(slot, "Title", offer.Title)
		ShopPrices.Watch("Product", offer.ProductId, offer.Price, function(price: number)
			if current == offer then
				ShopCards.SetText(slot, "Price", ShopPrices.Format(price))
			end
		end)
	end
	if slotButton then
		trove:Connect(slotButton.Activated, function()
			if current then
				current.Buy()
			end
		end)
	end

	local boosts = container:FindFirstChild("Boosts")
	if boosts then
		for _, boost in MonetizationConfig.Boosts do
			local name = boost.Key .. "Button"
			local button = ShopCards.Find(boosts, name)
			local product = boost.Products[1]
			for _, child in boosts:GetChildren() do
				if child:IsA("ImageLabel") and string.sub(child.Name, 1, #name) == name then
					child.Image = RobuxShopConfig.BoostIcons[boost.Key] or IconConfig.Clock
				end
			end
			if button then
				ShopCards.SetButton(
					button,
					`x2 {boost.Key}`,
					RobuxShopConfig.RailBoostColors[boost.Key] or RobuxShopConfig.BuyColors
				)
				local fill = button:FindFirstChild("Fill", true)
				local gradient = if fill then fill:FindFirstChildOfClass("UIGradient") else nil
				if gradient and boost.Key == RobuxShopConfig.RailRainbowBoost then
					gradient.Color = RarityConfig.Rainbow
					gradient.Rotation = 0
				end
				trove:Connect(button.Activated, function()
					purchases:PromptBoost(boost.Key, 1)
				end)
			end
			ShopPrices.Watch("Product", product.ProductId, product.RobuxPrice, function(price: number)
				ShopCards.SetText(boosts, name .. "Only", `Only {ShopPrices.Format(price)}`)
			end)
		end
	end

	local function rotate(now: number)
		for _ = 1, #offers do
			index = index % #offers + 1
			local offer = offers[index]
			if offer.EndsAt() > now then
				showOffer(offer)
				return
			end
		end
		showOffer(nil)
	end

	local function removePrompt(prompt: Prompt)
		local position = table.find(prompts, prompt)
		if position then
			table.remove(prompts, position)
		end
		prompt.Trove:Destroy()
	end

	local function addPrompt(
		title: string,
		body: string,
		icon: string,
		palette: string,
		buyText: string?,
		onBuy: (() -> ())?,
		altText: string?,
		onAlt: (() -> ())?,
		lifetime: number?,
		isDone: (() -> boolean)?
	)
		while #prompts >= MAX_PROMPTS do
			removePrompt(prompts[1])
		end
		local tray = promptTemplate:Clone()
		local inner = tray:FindFirstChild("Card")
		if not tray:IsA("Frame") or not inner or not inner:IsA("Frame") then
			tray:Destroy()
			return
		end
		local promptTrove = trove:Extend()
		promptTrove:Add(tray)
		local prompt: Prompt = {
			Tray = tray,
			Trove = promptTrove,
			ExpiresAt = if lifetime then os.clock() + lifetime else nil,
			IsDone = isDone,
		}
		tray.Name = "Prompt"
		tray.Visible = true
		tray.LayoutOrder = #prompts
		ShopCards.Paint(tray, inner, RobuxShopConfig.Palettes[palette])
		ShopCards.SetIcon(inner, icon, true)
		ShopCards.SetText(inner, "Title", title)
		ShopCards.SetText(inner, "Body", body)
		ShopCards.SetText(inner, "Ribbon", "")
		local function setup(name: string, text: string?, callback: (() -> ())?)
			local button = ShopCards.Find(inner, name)
			if not button then
				return
			end
			button.Visible = text ~= nil
			if text and callback then
				ShopCards.SetButton(button, text, RobuxShopConfig.BuyColors)
				promptTrove:Connect(button.Activated, function()
					callback()
					removePrompt(prompt)
				end)
			end
		end
		setup("BuyButton", buyText, onBuy)
		setup("AltButton", altText, onAlt)
		if not altText then
			tray.Size = UDim2.new(tray.Size.X.Scale, tray.Size.X.Offset, 0, SINGLE_BUTTON_HEIGHT)
		end
		local close = ShopCards.Find(inner, "CloseButton")
		ShopCards.SetButton(close, "X", RobuxShopConfig.PillColors)
		if close then
			promptTrove:Connect(close.Activated, function()
				removePrompt(prompt)
			end)
		end
		tray.Parent = container
		table.insert(prompts, prompt)
	end

	local function priceText(prefix: string, price: number): string
		return `{prefix}{ShopPrices.Format(price)}`
	end

	local endedShown: { [string]: boolean } = {}
	trove:Add(Packets.BoostEnded.OnClientEvent:Connect(function(key: string)
		if endedShown[key] then
			return
		end
		for _, boost in MonetizationConfig.Boosts do
			if boost.Key == key then
				endedShown[key] = true
				local short, long = boost.Products[1], boost.Products[2]
				addPrompt(
					`{boost.DisplayName} ran out!`,
					"Keep it going?",
					RobuxShopConfig.BoostIcons[key] or IconConfig.Clock,
					if key == "Cash" then "Green" else "Orange",
					priceText(`{RobuxShopConfig.Texts.ShortButton}  `, short.RobuxPrice),
					function()
						purchases:PromptBoost(key, 1)
					end,
					priceText(`{RobuxShopConfig.Texts.LongButton}  `, long.RobuxPrice),
					function()
						purchases:PromptBoost(key, 2)
					end,
					PROMPT_SECONDS,
					nil
				)
			end
		end
	end))

	trove:Add(
		Packets.GiftReceived.OnClientEvent:Connect(function(from: string, item: string, fromUserId: number)
			addPrompt(
				`{from} gifted you`,
				`{item}!`,
				IconConfig.Gift,
				"Magenta",
				if fromUserId > 0 then "Thank!" else nil,
				function()
					Packets.ThankGift:Fire(fromUserId)
				end,
				nil,
				nil,
				PROMPT_SECONDS * 2,
				nil
			)
		end)
	)

	local chainShown: { [string]: number } = {}
	local function checkChains(now: number)
		for _, boost in MonetizationConfig.ServerBoosts do
			local endsAt =
				workspace:GetAttribute(MonetizationConfig.ServerBoostEndsAttributePrefix .. boost.Key)
			if type(endsAt) ~= "number" then
				continue
			end
			local left = endsAt - now
			if left > 0 and left <= CHAIN_SECONDS and chainShown[boost.Key] ~= endsAt then
				chainShown[boost.Key] = endsAt
				addPrompt(
					boost.DisplayName,
					"Ends soon! Keep it going?",
					RobuxShopConfig.ServerBoostIcons[boost.Key] or IconConfig.ServerBadge,
					"Lime",
					priceText("+15 min  ", boost.RobuxPrice),
					function()
						purchases:PromptServerBoost(boost.Key)
					end,
					nil,
					nil,
					nil,
					function(): boolean
						local latest = workspace:GetAttribute(
							MonetizationConfig.ServerBoostEndsAttributePrefix .. boost.Key
						)
						return latest ~= endsAt or workspace:GetServerTimeNow() >= endsAt
					end
				)
			end
		end
	end

	local lastSecond = 0
	trove:Connect(RunService.Heartbeat, function()
		local container = gui:FindFirstChild("Container")
		if container and container:IsA("GuiObject") then
			local isTutorial = Tutorial.IsActive(Tutorial.StepOf(dataController:Get({ "Tutorial" })))
			container.Visible = not isTutorial and not uiController:IsModalOpen()
		end
		local clock = os.clock()
		for position = #prompts, 1, -1 do
			local prompt = prompts[position]
			if (prompt.ExpiresAt and clock >= prompt.ExpiresAt) or (prompt.IsDone and prompt.IsDone()) then
				removePrompt(prompt)
			end
		end
		if clock - lastSecond < 1 then
			return
		end
		lastSecond = clock
		local now = workspace:GetServerTimeNow()
		if clock - lastRotate >= ROTATE_SECONDS or (current and current.EndsAt() <= now) then
			lastRotate = clock
			rotate(now)
		end
		if current then
			local endsAt = current.EndsAt()
			ShopCards.SetText(slot, "Timer", if endsAt < math.huge then ShopCards.Clock(endsAt - now) else "")
		end
		if slot:IsA("GuiObject") then
			slot.Visible = current ~= nil and #prompts == 0
		end
		checkChains(now)
	end)

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
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

return OfferRail
