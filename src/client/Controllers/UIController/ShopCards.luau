--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CashPackConfig = require(ReplicatedStorage.Config.CashPackConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local ItemIconConfig = require(ReplicatedStorage.Config.ItemIconConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RobuxShopConfig = require(ReplicatedStorage.Config.RobuxShopConfig)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local CashPack = require(ReplicatedStorage.Utils.CashPack)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ShopPrices = require(script.Parent.ShopPrices)

local ShopCards = {}

local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

function ShopCards.Clone(templates: Instance, name: string): (Frame?, Frame?)
	local template = templates:FindFirstChild(name)
	if not template or not template:IsA("Frame") then
		warn(`[RobuxShop] Missing template "{name}" in {templates:GetFullName()}`)
		return nil, nil
	end
	local tray = template:Clone()
	tray.Visible = true
	local card = tray:FindFirstChild("Card")
	return tray, if card and card:IsA("Frame") then card else nil
end

function ShopCards.Paint(tray: Frame, card: Frame, palette: RobuxShopConfig.Palette)
	local base, light = palette.Base, palette.Light
	tray.BackgroundColor3 = base:Lerp(BLACK, 0.55)
	local gradient = card:FindFirstChild("Gradient")
	if gradient and gradient:IsA("UIGradient") then
		gradient.Color = ColorSequence.new(light, base)
	end
	local studs = card:FindFirstChild("StudTexture")
	if studs and studs:IsA("ImageLabel") then
		studs.ImageColor3 = base:Lerp(BLACK, 0.25)
	end
	local bevel = card:FindFirstChild("Bevel")
	local bevelStroke = if bevel then bevel:FindFirstChildOfClass("UIStroke") else nil
	if bevelStroke then
		bevelStroke.Color = light
	end
	local lip = card:FindFirstChild("Lip")
	if lip and lip:IsA("Frame") then
		lip.BackgroundColor3 = base:Lerp(BLACK, 0.3)
		local highlight = lip:FindFirstChild("Highlight")
		if highlight and highlight:IsA("Frame") then
			highlight.BackgroundColor3 = base:Lerp(WHITE, 0.15)
		end
	end
	local h, s = base:ToHSV()
	local edge = Color3.fromHSV(h, math.min(1, s * 1.1), 1)
	local glow = card:FindFirstChild("Glow")
	if glow then
		for _, strip in glow:GetChildren() do
			local stripGradient = strip:FindFirstChildOfClass("UIGradient")
			if stripGradient then
				stripGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, edge),
					ColorSequenceKeypoint.new(0.5, light),
					ColorSequenceKeypoint.new(1, light),
				})
			end
		end
	end
end

function ShopCards.SetText(parent: Instance, name: string, text: string)
	for _, labelName in { name, name .. HudConfig.ShadowSuffix } do
		local label = parent:FindFirstChild(labelName)
		if label and label:IsA("TextLabel") then
			label.Text = text
		end
	end
end

function ShopCards.SetVisible(parent: Instance, name: string, isVisible: boolean)
	for _, childName in { name, name .. HudConfig.ShadowSuffix } do
		local child = parent:FindFirstChild(childName)
		if child and child:IsA("GuiObject") then
			child.Visible = isVisible
		end
	end
end

function ShopCards.SetIcon(parent: Instance, image: string, hasOutline: boolean)
	for _, child in parent:GetChildren() do
		if child:IsA("ImageLabel") then
			if child.Name == "Icon" then
				child.Image = image
			elseif string.match(child.Name, "^IconOutline%d") or child.Name == "IconShadow" then
				child.Image = image
				child.Visible = hasOutline
			end
		end
	end
end

function ShopCards.Find(parent: Instance, name: string): GuiButton?
	local child = parent:FindFirstChild(name)
	return if child and child:IsA("GuiButton") then child else nil
end

function ShopCards.SetButton(button: GuiButton?, text: string, colors: RobuxShopConfig.MeterColors)
	if not button then
		return
	end
	ShopCards.SetText(button, "Label", text)
	BlockButton.Paint(button:FindFirstChild("Fill", true), colors)
end

function ShopCards.SetSub(button: GuiButton?, text: string)
	if button then
		ShopCards.SetText(button, "Sub", text)
	end
end

function ShopCards.Clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function ShopCards.PetIcon(petKey: string): string?
	local pets = (ItemIconConfig :: any).Pet
	return if type(pets) == "table" then pets[petKey] else nil
end

function ShopCards.FillStarter(inner: Instance, strength: number, isRestricted: boolean)
	local starter = MonetizationConfig.StarterPack
	local items = inner:FindFirstChild("Items")
	local itemTemplate = if items then items:FindFirstChild("ItemTemplate") else nil
	local plusTemplate = if items then items:FindFirstChild("PlusTemplate") else nil
	if not items or not itemTemplate or not plusTemplate then
		return
	end
	for _, child in items:GetChildren() do
		if child:GetAttribute("StarterItem") then
			child:Destroy()
		end
	end
	local geodes = starter.Geodes + if isRestricted then starter.RestrictedExtraGeodes else 0
	local cash = CashPack.GeodeValue(geodes, strength)
	local champ = PetConfig.Pets[starter.RokKey]
	local champIcon = ShopCards.PetIcon(starter.RokKey)
	local entries = {
		{ Icon = IconConfig.Cash3, Label = `+${NumberFormat.Compact(cash)}`, Income = "", Outline = true },
		{
			Icon = IconConfig.Strength,
			Label = `2x {starter.BoostSeconds // 60} min`,
			Income = "",
			Outline = true,
		},
	}
	if not isRestricted then
		table.insert(
			entries,
			{ Icon = IconConfig.LuckyGeode, Label = "Lucky Geode", Income = "", Outline = true }
		)
	end
	table.insert(entries, {
		Icon = champIcon or IconConfig.Crown,
		Label = if champ then champ.DisplayName else starter.RokKey,
		Income = if champ then `${NumberFormat.Rate(champ.MoneyPerSecond)}/s` else "",
		Outline = champIcon == nil,
	})
	local order = 0
	for index, entry in entries do
		if index > 1 then
			order += 1
			local plus = plusTemplate:Clone()
			plus:SetAttribute("StarterItem", true)
			if plus:IsA("GuiObject") then
				plus.Visible = true
				plus.LayoutOrder = order
			end
			plus.Parent = items
		end
		order += 1
		local item = itemTemplate:Clone()
		item:SetAttribute("StarterItem", true)
		if item:IsA("GuiObject") then
			item.Visible = true
			item.LayoutOrder = order
		end
		ShopCards.SetIcon(item, entry.Icon, entry.Outline)
		ShopCards.SetText(item, "Label", entry.Label)
		ShopCards.SetText(item, "Income", entry.Income)
		item.Parent = items
	end
	local medium = CashPackConfig.Packs[2]
	local worth = math.floor(medium.RobuxPrice / medium.Geodes * geodes)
		+ MonetizationConfig.Boosts[1].Products[1].RobuxPrice * (starter.BoostSeconds // 900)
		+ if isRestricted then 0 else MonetizationConfig.LuckyGeodeProducts[2].RobuxPrice
	ShopCards.SetText(inner, "Worth", ShopPrices.Format(worth))
end

export type GiftInfo = {
	Name: string,
	Icon: string,
	HasOutline: boolean,
	Price: number,
}

function ShopCards.GiftInfo(gift: MonetizationConfig.Gift): GiftInfo?
	if gift.Kind == "Pass" then
		for _, pass in MonetizationConfig.Passes do
			if pass.Key == gift.Target then
				return {
					Name = pass.DisplayName,
					Icon = RobuxShopConfig.PassIcons[pass.Key] or IconConfig.Shop,
					HasOutline = true,
					Price = pass.RobuxPrice,
				}
			end
		end
	elseif gift.Kind == "Boost" then
		for _, boost in MonetizationConfig.Boosts do
			local product = boost.Products[gift.Index or 1]
			if boost.Key == gift.Target and product then
				return {
					Name = `{boost.DisplayName} {product.Seconds // 60} min`,
					Icon = RobuxShopConfig.BoostIcons[boost.Key] or IconConfig.Clock,
					HasOutline = true,
					Price = product.RobuxPrice,
				}
			end
		end
	elseif gift.Kind == "Lucky" then
		local product = MonetizationConfig.LuckyGeodeProducts[gift.Index or 2]
		if product then
			return {
				Name = if product.Count == 1 then "Lucky Geode" else `{product.Count} Lucky Geodes`,
				Icon = IconConfig.LuckyGeode,
				HasOutline = true,
				Price = product.RobuxPrice,
			}
		end
	elseif gift.Kind == "CashPack" then
		for _, pack in CashPackConfig.Packs do
			if pack.Key == gift.Target then
				return {
					Name = `{pack.DisplayName} Cash`,
					Icon = RobuxShopConfig.CashIcons[pack.Key] or IconConfig.Money,
					HasOutline = true,
					Price = pack.RobuxPrice,
				}
			end
		end
	elseif gift.Kind == "Exclusive" then
		local pet = PetConfig.Pets[gift.Target]
		for _, item in MonetizationConfig.Exclusives.Items do
			if item.Key == gift.Target and pet then
				local icon = ShopCards.PetIcon(item.RokKey)
				return {
					Name = pet.DisplayName,
					Icon = icon or IconConfig.Crown,
					HasOutline = icon == nil,
					Price = item.RobuxPrice,
				}
			end
		end
	end
	return nil
end

return ShopCards
