--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local GeodeStandConfig = require(ReplicatedStorage.Config.GeodeStandConfig)
local HatchOdds = require(ReplicatedStorage.HatchOdds)
local HatchPity = require(ReplicatedStorage.HatchPity)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local LuckConfig = require(ReplicatedStorage.Config.LuckConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local RobuxButton = require(ReplicatedStorage.Utils.RobuxButton)
local ItemIcons = require(ReplicatedStorage.Utils.ItemIcons)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Types = require(script.Parent.Parent.Types)

local SCREEN_NAME = "GeodeStand"

local GeodeStand = {}

type Card = {
	PetKey: string,
	Odds: TextLabel?,
	Name: TextLabel?,
	Preview: ItemIcons.Visual?,
}

type Tab = {
	GeodeKey: string,
	Button: TextButton,
	Fill: Instance?,
}

type BuyButton = {
	Amount: number,
	Button: TextButton,
	Label: TextLabel?,
	Fill: Instance?,
}

type PityBar = {
	Rarity: string,
	Frame: GuiObject,
	Fill: GuiObject?,
	Label: TextLabel?,
}

local function find(root: Instance, name: string, className: string, recursive: boolean): any
	local found = root:FindFirstChild(name, recursive)
	if found and found:IsA(className) then
		return found
	end
	warn(`[GeodeStand] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function setText(label: TextLabel?, text: string)
	if not label then
		return
	end
	label.Text = text
	local shadow = if label.Parent
		then label.Parent:FindFirstChild(label.Name .. HudConfig.ShadowSuffix)
		else nil
	if shadow and shadow:IsA("TextLabel") then
		shadow.Text = text
	end
end

local function paint(fill: Instance?, colors: ShopConfig.MeterColors)
	BlockButton.Paint(fill, colors)
end

local function buildPreview(frame: ViewportFrame, modelKey: string)
	for _, child in frame:GetChildren() do
		if child:IsA("Model") or child:IsA("Camera") then
			child:Destroy()
		end
	end
	local model = AssetRegistry.get(modelKey)
	if not model:IsA("Model") then
		model:Destroy()
		warn(`[GeodeStand] Asset "{modelKey}" is not a Model`)
		return
	end
	local settings = GeodeStandConfig.Preview
	local camera = Instance.new("Camera")
	camera.FieldOfView = settings.FieldOfView
	camera.Parent = frame
	model.Parent = frame
	local center, size = model:GetBoundingBox()
	local distance = size.Magnitude / 2 / math.tan(math.rad(camera.FieldOfView / 2)) * settings.CameraPadding
	camera.CFrame = CFrame.lookAt(center.Position + settings.CameraDirection.Unit * distance, center.Position)
	frame.CurrentCamera = camera
end

function GeodeStand.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
	local trove = Trove.new()
	local cardTrove = trove:Extend()
	ViewportScale.Bind(gui, trove)

	local grid: GuiObject? = find(gui, "Grid", "GuiObject", true)
	local template: Frame? = find(gui, "CardTemplate", "Frame", true)
	local title: TextLabel? = find(gui, "Title", "TextLabel", true)
	local closeButton: TextButton? = find(gui, "CloseButton", "TextButton", true)
	local blocker: TextButton? = find(gui, "Blocker", "TextButton", true)
	local toggle: TextButton? = find(gui, "LuckToggle", "TextButton", true)
	local blockerLabel: TextLabel? = if blocker then find(blocker, "Label", "TextLabel", false) else nil
	local tabsFrame: GuiObject? = find(gui, "Tabs", "GuiObject", true)
	local tabTemplate: TextButton? = find(gui, "TabTemplate", "TextButton", true)
	local pityFrame: GuiObject? = find(gui, "Pity", "GuiObject", true)

	for _, hidden in { template, tabTemplate } :: { GuiObject? } do
		if hidden then
			hidden.Visible = false
		end
	end

	local geodeKey: string? = nil
	local showGamepassOdds = false
	local luckPrompted = false
	local isBuying = false
	local cards: { Card } = {}
	local buttons: { BuyButton } = {}
	local tabs: { Tab } = {}
	local pityBars: { PityBar } = {}

	local orderedKeys = GeodeOrder.Sorted()

	if pityFrame then
		for _, rarity in GeodeConfig.PityRarities do
			local frame: GuiObject? = find(pityFrame, rarity, "GuiObject", false)
			if not frame then
				continue
			end
			local fill: GuiObject? = find(frame, "Fill", "GuiObject", false)
			local gradient = if fill then fill:FindFirstChildWhichIsA("UIGradient") else nil
			local rarityConfig = RarityConfig.Rarities[rarity]
			if gradient and rarityConfig then
				if rarityConfig.RainbowLabel then
					gradient.Rotation = 0
					gradient.Color = RarityConfig.Rainbow
				else
					gradient.Rotation = 90
					gradient.Color = ColorSequence.new(
						rarityConfig.Color:Lerp(Color3.new(1, 1, 1), GeodeStandConfig.PityFillLighten),
						rarityConfig.Color
					)
				end
			end
			table.insert(pityBars, {
				Rarity = rarity,
				Frame = frame,
				Fill = fill,
				Label = find(frame, "Label", "TextLabel", false),
			})
		end
	end

	for _, entry in { { Name = "BuyOne", Amount = 1 }, { Name = "BuyThree", Amount = 3 } } do
		local button: TextButton? = find(gui, entry.Name, "TextButton", true)
		if button then
			table.insert(buttons, {
				Amount = entry.Amount,
				Button = button,
				Label = find(button, "Label", "TextLabel", false),
				Fill = button:FindFirstChild("Fill", true),
			})
		end
	end

	local function read(path: { string }): any
		return dataController:Get(path)
	end

	local function count(value: any): number
		local total = 0
		if type(value) == "table" then
			for _, item in value do
				total += if type(item) == "number" then item else 1
			end
		end
		return total
	end

	local function freeSlots(): number
		local hasBigBackpack = Players.LocalPlayer:GetAttribute(
			MonetizationConfig.PassAttributePrefix .. "Backpack"
		) == true
		local size = PetConfig.MaxPets + if hasBigBackpack then MonetizationConfig.BackpackBonus else 0
		return size - count(read({ "Pets" })) - count(read({ "Geodes" }))
	end

	local function refreshOdds()
		if not geodeKey then
			return
		end
		local luck = if showGamepassOdds then LuckConfig.GamepassMultiplier else 1
		local chances: { [string]: number } = {}
		for _, entry in HatchOdds.Chances(geodeKey, luck) do
			chances[entry.PetKey] = entry.Chance
		end
		for _, card in cards do
			setText(card.Odds, NumberFormat.Percent(chances[card.PetKey] or 0))
			if card.Odds then
				card.Odds.TextColor3 = if showGamepassOdds
					then GeodeStandConfig.GamepassOddsColor
					else GeodeStandConfig.OddsColor
			end
		end
		if toggle then
			paint(
				toggle:FindFirstChild("Fill", true),
				if showGamepassOdds then GeodeStandConfig.Palette.LuckOn else GeodeStandConfig.Palette.LuckOff
			)
		end
	end

	local function refreshCards()
		local index = read({ "Index", "Pets" })
		for _, card in cards do
			local pet = PetConfig.Pets[card.PetKey]
			local rarity = if pet then RarityConfig.Rarities[pet.Rarity] else nil
			local found = type(index) == "table"
				and type(index[card.PetKey]) == "number"
				and index[card.PetKey] > 0
			local hidden = rarity ~= nil and rarity.HiddenUntilFound and not found
			setText(card.Name, if hidden or not pet then GeodeStandConfig.HiddenName else pet.DisplayName)
			ItemIcons.Tint(card.Preview, if hidden then GeodeStandConfig.HiddenColor else Color3.new(1, 1, 1))
		end
	end

	local function refreshButtons()
		local geode = if geodeKey then GeodeConfig.Geodes[geodeKey] else nil
		if not geode then
			return
		end
		local cash = read({ "Cash" })
		local peakStrength = read({ "PeakStrength" })
		cash = if type(cash) == "number" then cash else 0
		peakStrength = if type(peakStrength) == "number" then peakStrength else 0
		local slots = freeSlots()
		local blockedText: string? = nil
		if peakStrength < geode.StrengthRequired then
			blockedText = string.format(
				GeodeStandConfig.NeedStrengthFormat,
				NumberFormat.Commas(geode.StrengthRequired)
			)
		elseif slots < 1 then
			blockedText = if context.Controllers.PurchaseController:OwnsPass("Backpack")
				then GeodeStandConfig.BagFullText
				else GeodeStandConfig.BagFullUpsellText
		end
		if blocker then
			blocker.Visible = blockedText ~= nil
		end
		setText(blockerLabel, blockedText or "")
		local showThree = false
		local step = Tutorial.StepOf(read({ "Tutorial" }))
		for _, button in buttons do
			local price = Tutorial.GeodeCost(step, geodeKey :: string, button.Amount)
			local canBuy = cash >= price and slots >= button.Amount
			if button.Amount > 1 then
				showThree = canBuy
			end
			button.Button:SetAttribute("Shimmer", canBuy and blockedText == nil)
			local robux = button.Button:FindFirstChild("RobuxButton")
			if robux and robux:IsA("GuiObject") then
				local shortfall = price - cash
				local pack = if blockedText == nil and shortfall > 0
					then context.Controllers.PurchaseController:CoveringPack(shortfall)
					else nil
				RobuxButton.Show(robux, if pack and pack.ProductId then pack.RobuxPrice else nil)
			end
			setText(button.Label, NumberFormat.Commas(price))
			paint(
				button.Fill,
				if canBuy then GeodeStandConfig.Palette.Affordable else GeodeStandConfig.Palette.Unavailable
			)
		end
		for _, button in buttons do
			local visible = blockedText == nil and (button.Amount == 1 or showThree)
			button.Button.Visible = visible
			if button.Amount == 1 then
				local offset = GeodeStandConfig.ButtonCenterOffsetPixels
					+ if showThree
						then -GeodeStandConfig.PairButtonOffsetPixels
						else GeodeStandConfig.SingleButtonOffsetPixels
				button.Button.Position =
					UDim2.new(0.5, offset, button.Button.Position.Y.Scale, button.Button.Position.Y.Offset)
			end
		end
	end

	local function refreshTabs()
		for _, tab in tabs do
			paint(
				tab.Fill,
				if tab.GeodeKey == geodeKey
					then GeodeStandConfig.Palette.TabActive
					else GeodeStandConfig.Palette.TabIdle
			)
		end
	end

	local function refreshPity()
		local key = geodeKey
		if not key then
			return
		end
		local counts = read({ "Pity", key })
		for _, bar in pityBars do
			local threshold = HatchPity.Threshold(key, bar.Rarity)
			local left = HatchPity.Left(key, counts, bar.Rarity)
			bar.Frame.Visible = threshold ~= nil and left ~= nil
			if not threshold or not left then
				continue
			end
			setText(
				bar.Label,
				string.format(
					GeodeStandConfig.PityFormat,
					RarityConfig.Rarities[bar.Rarity].DisplayName,
					NumberFormat.Commas(left)
				)
			)
			if bar.Fill then
				bar.Fill.Size = UDim2.fromScale((threshold - left) / threshold, 1)
			end
		end
	end

	local function refresh()
		refreshTabs()
		refreshCards()
		refreshOdds()
		refreshButtons()
		refreshPity()
	end

	local function defaultKey(): string?
		local strength = read({ "PeakStrength" })
		return GeodeOrder.ForStrength(if type(strength) == "number" then strength else 0)
	end

	local function buildCards(key: string)
		cardTrove:Clean()
		table.clear(cards)
		local geode = GeodeConfig.Geodes[key]
		if not geode or not grid or not template then
			return
		end
		setText(title, geode.DisplayName)
		for order, entry in geode.Pets do
			local pet = PetConfig.Pets[entry.PetKey]
			if not pet then
				warn(`[GeodeStand] Unknown pet "{entry.PetKey}" in geode "{key}"`)
				continue
			end
			local frame = template:Clone()
			frame.Name = entry.PetKey
			frame.LayoutOrder = order
			frame.Visible = true
			local preview = ItemIcons.Apply(frame, "Pet", entry.PetKey, function(viewport)
				buildPreview(viewport, pet.ModelKey)
			end)
			local glow = frame:FindFirstChild("ColorGlow")
			local gradient = if glow then glow:FindFirstChildWhichIsA("UIGradient") else nil
			local rarity = RarityConfig.Rarities[pet.Rarity]
			if gradient and rarity then
				gradient.Color = ColorSequence.new(rarity.Color)
			end
			table.insert(cards, {
				PetKey = entry.PetKey,
				Odds = find(frame, "Odds", "TextLabel", false),
				Name = find(frame, "PetName", "TextLabel", false),
				Preview = preview,
			})
			frame.Parent = grid
			cardTrove:Add(frame)
		end
	end

	local function selectGeode(key: string)
		if key == geodeKey then
			return
		end
		geodeKey = key
		showGamepassOdds = false
		luckPrompted = false
		buildCards(key)
	end

	if tabsFrame and tabTemplate then
		for order, key in orderedKeys do
			local geode = GeodeConfig.Geodes[key]
			local button = tabTemplate:Clone()
			button.Name = key
			button.LayoutOrder = order
			button.Visible = true
			setText(find(button, "Label", "TextLabel", true), geode.TabName)
			setText(
				find(button, "Count", "TextLabel", true),
				string.format(
					GeodeStandConfig.TabStrengthFormat,
					NumberFormat.Compact(geode.StrengthRequired)
				)
			)
			trove:Add(button.Activated:Connect(function()
				selectGeode(key)
				refresh()
			end))
			table.insert(tabs, {
				GeodeKey = key,
				Button = button,
				Fill = button:FindFirstChild("Fill", true),
			})
			button.Parent = tabsFrame
			trove:Add(button)
		end
	end

	for _, button in buttons do
		local robux = button.Button:FindFirstChild("RobuxButton")
		if robux and robux:IsA("GuiButton") then
			trove:Add(robux.Activated:Connect(function()
				local key = geodeKey
				if not key then
					return
				end
				local cash = read({ "Cash" })
				local price = Tutorial.GeodeCost(Tutorial.StepOf(read({ "Tutorial" })), key, button.Amount)
				context.Controllers.PurchaseController:PromptCash(
					price - (if type(cash) == "number" then cash else 0)
				)
			end))
		end
		trove:Add(button.Button.Activated:Connect(function()
			local key = geodeKey
			if isBuying or not key then
				return
			end
			local cash = read({ "Cash" })
			local price = Tutorial.GeodeCost(Tutorial.StepOf(read({ "Tutorial" })), key, button.Amount)
			local shortfall = price - (if type(cash) == "number" then cash else 0)
			if shortfall > 0 then
				context.Feedback(button.Button, false)
				context.Controllers.CashPackController:Prompt(shortfall)
				return
			end
			isBuying = true
			task.spawn(function()
				local isBought = Packets.BuyGeode:Fire(key, button.Amount) == true
				if isBought then
					LocalSound.Play("SFX_Money_Gain")
				end
				context.Feedback(button.Button, isBought)
				isBuying = false
			end)
		end))
	end

	if toggle then
		trove:Add(toggle.Activated:Connect(function()
			showGamepassOdds = not showGamepassOdds
			refreshOdds()
			local purchases = context.Controllers.PurchaseController
			if showGamepassOdds and not luckPrompted and not purchases:OwnsPass("Luck") then
				luckPrompted = true
				purchases:PromptPass("Luck")
			end
		end))
	end

	if blocker then
		trove:Add(blocker.Activated:Connect(function()
			local purchases = context.Controllers.PurchaseController
			if freeSlots() < 1 and not purchases:OwnsPass("Backpack") then
				purchases:PromptPass("Backpack")
			end
		end))
	end

	if closeButton then
		trove:Add(closeButton.Activated:Connect(function()
			context.Close(SCREEN_NAME)
		end))
	end

	for _, path in
		{ { "Cash" }, { "PeakStrength" }, { "Pets" }, { "Geodes" }, { "Index" }, { "Tutorial" }, { "Pity" } }
	do
		trove:Add(dataController:Observe(path, function()
			if geodeKey then
				refresh()
			end
		end))
	end

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			local key = defaultKey()
			if key then
				selectGeode(key)
			end
			if not geodeKey then
				return
			end
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

return GeodeStand
