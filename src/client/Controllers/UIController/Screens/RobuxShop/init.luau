--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CashPackConfig = require(ReplicatedStorage.Config.CashPackConfig)
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local RobuxShopConfig = require(ReplicatedStorage.Config.RobuxShopConfig)
local HatchOdds = require(ReplicatedStorage.HatchOdds)
local RokModifier = require(ReplicatedStorage.RokModifier)
local CashPack = require(ReplicatedStorage.Utils.CashPack)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)
local Cards = require(script.Parent.Parent.ShopCards)
local Motion = require(script.Motion)
local Prices = require(script.Parent.Parent.ShopPrices)

local texts = RobuxShopConfig.Texts
local palettes = RobuxShopConfig.Palettes
local buyColors = RobuxShopConfig.BuyColors

local RobuxShop = {}

function RobuxShop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local openTrove = trove:Extend()
	ViewportScale.Bind(gui, trove)

	local player = Players.LocalPlayer
	local dataController = context.Controllers.DataController
	local purchases = context.Controllers.PurchaseController
	local panel = gui:FindFirstChild("Panel", true)
	local pages = if panel then panel:FindFirstChild("Pages") else nil
	local templates = if panel then panel:FindFirstChild("Templates") else nil
	if not panel or not pages or not templates then
		warn(`[RobuxShop] Missing Panel, Pages or Templates in {gui:GetFullName()}`)
	end

	local refreshers: { () -> () } = {}
	local timers: { (number) -> () } = {}
	local motion = Motion.New()

	local function readNumber(path: { string }): number
		local value = dataController:Get(path)
		return if type(value) == "number" then value else 0
	end

	local function notify(message: string)
		local notifications = context.Controllers.NotificationController
		if notifications then
			notifications:Notify("Info", message)
		end
	end

	local function onClick(button: GuiButton?, callback: () -> ())
		if button then
			trove:Connect(button.Activated, callback)
		end
	end

	local function price(
		button: GuiButton?,
		kind: "Product" | "Pass",
		id: number?,
		fallback: number,
		prefix: string?
	)
		Prices.Watch(kind, id, fallback, function(value: number)
			Cards.SetButton(button, `{prefix or ""}{Prices.Format(value)}`, buyColors)
		end)
	end

	local page: ScrollingFrame? = nil
	if pages and templates then
		for _, child in pages:GetChildren() do
			child:Destroy()
		end
		local pageTemplate = templates:FindFirstChild("PageTemplate")
		if pageTemplate and pageTemplate:IsA("ScrollingFrame") then
			local created = pageTemplate:Clone()
			created.Name = "Page"
			created.Visible = true
			created.Parent = pages
			page = created
		end
	end

	local order = 0
	local function add(object: GuiObject?)
		if object and page then
			order += 1
			object.LayoutOrder = order
			object.Visible = true
			object.Parent = page
		end
	end

	local function card(name: string, paletteName: string, sparkles: boolean): (Frame?, Frame?)
		if not templates then
			return nil, nil
		end
		local tray, inner = Cards.Clone(templates, name)
		if tray and inner then
			Cards.Paint(tray, inner, palettes[paletteName])
			Motion.AddCard(motion, inner, sparkles)
		end
		return tray, inner
	end

	local function details(inner: Frame, message: string)
		local button = Cards.Find(inner, "DetailsButton")
		Cards.SetButton(button, texts.Details, RobuxShopConfig.PillColors)
		onClick(button, function()
			notify(message)
		end)
	end

	local function zoneLuckyKey(): (string?, string?)
		local baseKey = GeodeOrder.ForStrength(readNumber({ "Strength" }))
		return baseKey, if baseKey then GeodeOrder.LuckyKey(baseKey) else nil
	end

	local function buildLucky()
		local tray, inner = card("LuckyCard", "Lucky", true)
		if not tray or not inner then
			return
		end
		Cards.SetText(inner, "Title", texts.LuckyTitle)
		Cards.SetText(inner, "Subtitle", texts.LuckySubtitle)
		Cards.SetText(inner, "Ribbon", texts.LuckyRibbon)
		Cards.SetIcon(inner, IconConfig.LuckyGeode, true)
		Cards.SetVisible(inner, "OddsButton", false)
		local items = inner:FindFirstChild("Items")
		local itemTemplate = if items then items:FindFirstChild("ItemTemplate") else nil
		local tiles: { Instance } = {}
		local products = MonetizationConfig.LuckyGeodeProducts
		local buttons = {
			{ Button = Cards.Find(inner, "BuyOne"), Index = 2 },
			{ Button = Cards.Find(inner, "BuyThree"), Index = 3 },
			{ Button = Cards.Find(inner, "BuyTen"), Index = 4 },
		}
		for _, entry in buttons do
			local product = products[entry.Index]
			Cards.SetSub(entry.Button, `Buy {product.Count}`)
			onClick(entry.Button, function()
				local baseKey = zoneLuckyKey()
				local isFirst = entry.Index == 2
					and dataController:Get({ "Offers", MonetizationConfig.FirstLuckyOfferKey }) ~= true
				purchases:PromptLucky(if isFirst then 1 else entry.Index, baseKey)
			end)
		end
		local function refresh()
			tray.Visible = player:GetAttribute(MonetizationConfig.RandomItemsRestrictedAttribute) ~= true
			local isFirst = dataController:Get({ "Offers", MonetizationConfig.FirstLuckyOfferKey }) ~= true
			for _, entry in buttons do
				local index = if entry.Index == 2 and isFirst then 1 else entry.Index
				local product = products[index]
				price(entry.Button, "Product", product.ProductId, product.RobuxPrice)
				Cards.SetSub(entry.Button, if index == 1 then "First one!" else `Buy {product.Count}`)
			end
			for _, tile in tiles do
				tile:Destroy()
			end
			table.clear(tiles)
			local _, luckyKey = zoneLuckyKey()
			if not luckyKey or not items or not itemTemplate then
				return
			end
			local tileOrder = 0
			for _, chance in HatchOdds.Chances(luckyKey, 1) do
				local pet = PetConfig.Pets[chance.PetKey]
				if chance.Chance <= 0 or not pet then
					continue
				end
				tileOrder += 1
				local tile = itemTemplate:Clone()
				tile.Name = `Item{tileOrder}`
				if tile:IsA("Frame") then
					tile.Visible = true
					tile.LayoutOrder = tileOrder
					local rarity = RarityConfig.Rarities[pet.Rarity]
					local rank = table.find(RarityConfig.Order, pet.Rarity) or 1
					if rarity and rank >= 5 then
						tile.BackgroundColor3 = rarity.Color
						tile.BackgroundTransparency = 0.1
					end
				end
				Cards.SetIcon(tile, Cards.PetIcon(chance.PetKey) or "", false)
				Cards.SetText(tile, "Odds", NumberFormat.Percent(chance.Chance))
				Cards.SetText(tile, "Income", `${NumberFormat.Rate(RokModifier.Rate(chance.PetKey, nil))}/s`)
				tile.Parent = items
				table.insert(tiles, tile)
			end
		end
		table.insert(refreshers, refresh)
		add(tray)
	end

	local function buildServerBoosts()
		local serverBoosts = table.clone(MonetizationConfig.ServerBoosts)
		table.sort(serverBoosts, function(a, b)
			return (table.find(RobuxShopConfig.ServerBoostOrder, a.Key) or 99)
				< (table.find(RobuxShopConfig.ServerBoostOrder, b.Key) or 99)
		end)
		for _, boost in serverBoosts do
			local paletteName = if boost.Key == "Luck"
				then "Lime"
				elseif boost.Key == "Cash" then "Green"
				else "Orange"
			local tray, inner = card("WideCard", paletteName, false)
			if not tray or not inner then
				continue
			end
			Cards.SetText(inner, "Title", string.format(texts.ServerTitle, boost.Key))
			Cards.SetText(inner, "Big", string.format(texts.ServerBig, boost.Seconds // 60))
			Cards.SetText(inner, "Blurb", string.format(texts.ServerBlurb, string.lower(boost.Key)))
			Cards.SetText(inner, "Headline", "")
			Cards.SetText(inner, "Ribbon", "")
			Cards.SetIcon(inner, RobuxShopConfig.ServerBoostIcons[boost.Key] or IconConfig.ServerBadge, true)
			Cards.SetVisible(inner, "Perks", false)
			Cards.SetVisible(inner, "AltButton", false)
			Cards.SetVisible(inner, "Worth", false)
			details(
				inner,
				boost.DisplayName .. ": " .. string.format(texts.ServerBlurb, string.lower(boost.Key))
			)
			local buy = Cards.Find(inner, "BuyButton")
			price(buy, "Product", boost.ProductId, boost.RobuxPrice)
			onClick(buy, function()
				purchases:PromptServerBoost(boost.Key)
			end)
			table.insert(timers, function(now: number)
				local endsAt =
					workspace:GetAttribute(MonetizationConfig.ServerBoostEndsAttributePrefix .. boost.Key)
				local left = if type(endsAt) == "number" then endsAt - now else 0
				Cards.SetText(
					inner,
					"Timer",
					if left > 0 then string.format(texts.BoostTimer, Cards.Clock(left)) else ""
				)
			end)
			add(tray)
		end
	end

	local function buildStarter()
		local starter = MonetizationConfig.StarterPack
		local tray, inner = card("StarterCard", "Sky", true)
		if not tray or not inner then
			return
		end
		Cards.SetText(inner, "Title", texts.StarterTitle)
		local buy = Cards.Find(inner, "BuyButton")
		price(buy, "Product", starter.ProductId, starter.RobuxPrice)
		onClick(buy, function()
			purchases:PromptStarterPack()
		end)
		local function refresh()
			local offerEndsAt = readNumber({ "StarterPack", "OfferEndsAt" })
			local isBought = dataController:Get({ "StarterPack", "Bought" }) == true
			tray.Visible = not isBought and workspace:GetServerTimeNow() < offerEndsAt
			local isRestricted = player:GetAttribute(MonetizationConfig.RandomItemsRestrictedAttribute)
				== true
			Cards.FillStarter(inner, readNumber({ "Strength" }), isRestricted)
		end
		table.insert(refreshers, refresh)
		table.insert(timers, function(now: number)
			local left = readNumber({ "StarterPack", "OfferEndsAt" }) - now
			Cards.SetText(inner, "Timer", Cards.Clock(left))
			if left <= 0 and tray.Visible then
				tray.Visible = false
			end
		end)
		add(tray)
	end

	local function buildBoosts()
		for _, boost in MonetizationConfig.Boosts do
			local paletteName = if boost.Key == "Cash" then "Green" else "Orange"
			local tray, inner = card("WideCard", paletteName, false)
			if not tray or not inner then
				continue
			end
			Cards.SetText(inner, "Title", string.format(texts.BoostTitle, boost.Key))
			Cards.SetText(inner, "Big", texts.BoostBig)
			Cards.SetText(
				inner,
				"Blurb",
				if boost.OnlyWhileTraining then texts.TrainingBoostBlurb else texts.BoostBlurb
			)
			Cards.SetText(inner, "Headline", "")
			Cards.SetText(inner, "Ribbon", "")
			Cards.SetIcon(inner, RobuxShopConfig.BoostIcons[boost.Key] or IconConfig.Clock, true)
			Cards.SetVisible(inner, "Perks", false)
			Cards.SetVisible(inner, "Worth", false)
			Cards.SetVisible(inner, "DetailsButton", false)
			local short = Cards.Find(inner, "AltButton")
			local long = Cards.Find(inner, "BuyButton")
			if short and long then
				short.Visible = true
				short.AnchorPoint = long.AnchorPoint
				short.Size = long.Size
				short.Position = long.Position
					- UDim2.fromOffset(0, long.Size.Y.Offset + RobuxShopConfig.BoostButtonGapPixels)
				Cards.SetVisible(short, "Sub", false)
				for _, name in { "Label", "LabelShadow" } do
					local label = short:FindFirstChild(name)
					local reference = long:FindFirstChild(name)
					if label and reference and label:IsA("GuiObject") and reference:IsA("GuiObject") then
						label.AnchorPoint = reference.AnchorPoint
						label.Position = reference.Position
						label.Size = reference.Size
					end
				end
			end
			local shortProduct, longProduct = boost.Products[1], boost.Products[2]
			price(short, "Product", shortProduct.ProductId, shortProduct.RobuxPrice, `{texts.ShortButton}  `)
			price(long, "Product", longProduct.ProductId, longProduct.RobuxPrice, `{texts.LongButton}  `)
			onClick(short, function()
				purchases:PromptBoost(boost.Key, 1)
			end)
			onClick(long, function()
				purchases:PromptBoost(boost.Key, 2)
			end)
			table.insert(timers, function(now: number)
				local endsAt = player:GetAttribute(MonetizationConfig.BoostEndsAttributePrefix .. boost.Key)
				local left = if type(endsAt) == "number" then endsAt - now else 0
				Cards.SetText(
					inner,
					"Timer",
					if left > 0 then string.format(texts.BoostTimer, Cards.Clock(left)) else ""
				)
			end)
			add(tray)
		end
	end

	local function findPass(key: string): MonetizationConfig.Pass?
		for _, pass in MonetizationConfig.Passes do
			if pass.Key == key then
				return pass
			end
		end
		return nil
	end

	local function buildVip()
		local pass = findPass("VIP")
		local tray, inner = card("WideCard", "Gold", true)
		if not pass or not tray or not inner then
			return
		end
		Cards.SetText(inner, "Title", texts.VipTitle)
		Cards.SetText(inner, "Headline", texts.VipHeadline)
		Cards.SetText(inner, "Ribbon", "")
		Cards.SetText(inner, "Timer", "")
		Cards.SetIcon(inner, IconConfig.Crown, true)
		Cards.SetVisible(inner, "Big", false)
		Cards.SetVisible(inner, "Blurb", false)
		Cards.SetVisible(inner, "AltButton", false)
		Cards.SetVisible(inner, "DetailsButton", false)
		local perks = inner:FindFirstChild("Perks")
		local perkTemplate = if perks then perks:FindFirstChild("PerkTemplate") else nil
		if perks and perks:IsA("GuiObject") and perkTemplate then
			perks.Visible = true
			for index, perk in RobuxShopConfig.VipPerks do
				local row = perkTemplate:Clone()
				if row:IsA("GuiObject") then
					row.Visible = true
					row.LayoutOrder = index
				end
				Cards.SetText(row, "Label", perk.Text)
				Cards.SetIcon(row, perk.Icon, true)
				row.Parent = perks
			end
		end
		local separate = 0
		local includes: { string } = pass.Includes or {}
		for _, included in includes do
			local includedPass = findPass(included)
			separate += if includedPass then includedPass.RobuxPrice else 0
		end
		Cards.SetText(inner, "Worth", Prices.Format(separate))
		local buy = Cards.Find(inner, "BuyButton")
		onClick(buy, function()
			purchases:PromptPass(pass.Key)
		end)
		table.insert(refreshers, function()
			local isOwned = purchases:OwnsPass(pass.Key)
			Cards.SetVisible(inner, "Worth", not isOwned)
			if isOwned then
				Cards.SetButton(buy, texts.Owned, RobuxShopConfig.OwnedColors)
			else
				price(buy, "Pass", pass.GamepassId, pass.RobuxPrice)
			end
		end)
		add(tray)
	end

	local function buildExclusives()
		for _, item in MonetizationConfig.Exclusives.Items do
			local pet = PetConfig.Pets[item.RokKey]
			local tray, inner = card("WideCard", "Purple", true)
			if not tray or not inner or not pet then
				continue
			end
			Cards.SetText(inner, "Title", pet.DisplayName)
			Cards.SetText(inner, "Big", texts.ExclusiveBig)
			Cards.SetText(inner, "Blurb", texts.ExclusiveBlurb)
			Cards.SetText(inner, "Ribbon", texts.ExclusiveRibbon)
			Cards.SetText(inner, "Headline", "")
			Cards.SetText(inner, "Timer", "")
			local icon = Cards.PetIcon(item.RokKey)
			Cards.SetIcon(inner, icon or IconConfig.Crown, icon == nil)
			Cards.SetVisible(inner, "Perks", false)
			Cards.SetVisible(inner, "AltButton", false)
			Cards.SetVisible(inner, "Worth", false)
			details(inner, item.Pitch)
			local buy = Cards.Find(inner, "BuyButton")
			onClick(buy, function()
				purchases:PromptExclusive(item.Key)
			end)
			table.insert(refreshers, function()
				if dataController:Get({ "Exclusives", item.Key }) == true then
					Cards.SetButton(buy, texts.Owned, RobuxShopConfig.OwnedColors)
				else
					price(buy, "Product", item.ProductId, item.RobuxPrice)
				end
			end)
			add(tray)
		end
	end

	local function buildPasses()
		if not templates then
			return
		end
		local gridTemplate = templates:FindFirstChild("PassGrid")
		if not gridTemplate or not gridTemplate:IsA("GuiObject") then
			return
		end
		local grid = gridTemplate:Clone()
		for index, pass in MonetizationConfig.Passes do
			if pass.Includes then
				continue
			end
			local tray, inner = card("PassCard", RobuxShopConfig.PassPalettes[pass.Key] or "Sky", false)
			if not tray or not inner then
				continue
			end
			tray.LayoutOrder = index
			Cards.SetText(inner, "Title", pass.DisplayName)
			Cards.SetText(inner, "Blurb", pass.Blurb)
			Cards.SetText(inner, "Ribbon", RobuxShopConfig.PassRibbons[pass.Key] or "")
			Cards.SetIcon(inner, RobuxShopConfig.PassIcons[pass.Key] or IconConfig.Shop, true)
			details(inner, `{pass.DisplayName}: {pass.Blurb}`)
			local buy = Cards.Find(inner, "BuyButton")
			onClick(buy, function()
				purchases:PromptPass(pass.Key)
			end)
			table.insert(refreshers, function()
				local isOwned = purchases:OwnsPass(pass.Key)
				if buy then
					buy.Visible = not isOwned
				end
				Cards.SetVisible(inner, "Owned", isOwned)
				Cards.SetText(inner, "Owned", texts.Owned)
				if not isOwned then
					price(buy, "Pass", pass.GamepassId, pass.RobuxPrice)
				end
			end)
			tray.Parent = grid
		end
		add(grid)
	end

	local function buildCash()
		if not templates then
			return
		end
		local section = templates:FindFirstChild("SectionTitle")
		if section and section:IsA("GuiObject") then
			local title = section:Clone()
			Cards.SetText(title, "Label", texts.CashSection)
			add(title)
		end
		local gridTemplate = templates:FindFirstChild("CashGrid")
		if not gridTemplate or not gridTemplate:IsA("GuiObject") then
			return
		end
		local grid = gridTemplate:Clone()
		for index, pack in CashPackConfig.Packs do
			local tray, inner = card("CashCard", "Green", false)
			if not tray or not inner then
				continue
			end
			tray.LayoutOrder = index
			Cards.SetIcon(inner, RobuxShopConfig.CashIcons[pack.Key] or IconConfig.Money, true)
			Cards.SetText(inner, "Ribbon", RobuxShopConfig.CashRibbons[pack.Key] or "")
			local buy = Cards.Find(inner, "BuyButton")
			price(buy, "Product", pack.ProductId, pack.RobuxPrice)
			onClick(buy, function()
				local productId = pack.ProductId
				if productId then
					game:GetService("MarketplaceService"):PromptProductPurchase(player, productId)
				else
					notify(texts.ComingSoon)
				end
			end)
			table.insert(refreshers, function()
				local amount = CashPack.Value(pack, readNumber({ "Strength" }))
				Cards.SetText(inner, "Title", string.format(texts.CashTitle, NumberFormat.Compact(amount)))
			end)
			tray.Parent = grid
		end
		add(grid)
	end

	buildLucky()
	buildServerBoosts()
	buildStarter()
	buildBoosts()
	buildVip()
	buildExclusives()
	buildPasses()
	buildCash()

	local function refreshAll()
		for _, refresh in refreshers do
			refresh()
		end
	end

	if panel then
		local gift = Cards.Find(panel, "GiftButton")
		Cards.SetButton(gift, texts.Gift, buyColors)
		onClick(gift, function()
			context.Open("GiftPicker")
		end)
		local close = panel:FindFirstChild("CloseButton", true)
		if close and close:IsA("GuiButton") then
			trove:Connect(close.Activated, function()
				context.Close(RobuxShopConfig.ScreenName)
			end)
		end
	end

	for _, path in { { "Strength" }, { "StarterPack" }, { "Offers" }, { "Exclusives" } } do
		trove:Add(dataController:Observe(path, refreshAll))
	end
	trove:Connect(player.AttributeChanged, function(name: string)
		if
			string.sub(name, 1, #MonetizationConfig.PassAttributePrefix)
				== MonetizationConfig.PassAttributePrefix
			or name == MonetizationConfig.RandomItemsRestrictedAttribute
		then
			refreshAll()
		end
	end)
	refreshAll()

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			refreshAll()
			openTrove:Connect(RunService.RenderStepped, function()
				local now = workspace:GetServerTimeNow()
				for _, timer in timers do
					timer(now)
				end
				Motion.Step(motion, os.clock())
			end)
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
			openTrove:Clean()
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return RobuxShop
