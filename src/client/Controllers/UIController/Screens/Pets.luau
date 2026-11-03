--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Packets = require(ReplicatedStorage.Packets)
local PedestalSlots = require(ReplicatedStorage.PedestalSlots)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local RarityRibbon = require(ReplicatedStorage.Utils.RarityRibbon)
local PetModifier = require(ReplicatedStorage.PetModifier)
local PetSize = require(ReplicatedStorage.PetSize)
local PetsConfig = require(ReplicatedStorage.Config.PetsConfig)
local ToolbarConfig = require(ReplicatedStorage.Config.ToolbarConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local PetStacks = require(script.Parent.Parent.PetStacks)
local Types = require(script.Parent.Parent.Types)

type Stack = PetStacks.Stack

local Pets = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[Pets] Missing {className} "{name}" in {root:GetFullName()}`)
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

function Pets.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
	local player = Players.LocalPlayer
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local cardTrove = trove:Extend()

	local countLabel: TextLabel? = find(gui, "CountLabel", "TextLabel")
	local search: TextBox? = find(gui, "Search", "TextBox")
	local grid: GuiObject? = find(gui, "Grid", "GuiObject")
	local template: Frame? = find(gui, "CardTemplate", "Frame")
	local emptyLabel: TextLabel? = find(gui, "EmptyLabel", "TextLabel")
	local slotButton: TextButton? = find(gui, "SlotButton", "TextButton")
	local slotLabel: TextLabel? = if slotButton then find(slotButton, "Label", "TextLabel") else nil
	local slotFill = if slotButton then slotButton:FindFirstChild("Fill", true) else nil
	local equipBestButton: TextButton? = find(gui, "EquipBestButton", "TextButton")
	local closeButton: GuiButton? = find(gui, "CloseButton", "GuiButton")
	local panel: Frame? = find(gui, "Panel", "Frame")
	local detail: Frame? = find(gui, "Detail", "Frame")
	local detailPopInstance = if detail then detail:FindFirstChild("PopIn") else nil
	local detailPop: UIScale? = if detailPopInstance and detailPopInstance:IsA("UIScale")
		then detailPopInstance
		else nil
	local detailBorderFrame = if detail then detail:FindFirstChild("InnerBorder") else nil
	local detailBorder: UIStroke? = if detailBorderFrame
		then detailBorderFrame:FindFirstChildWhichIsA("UIStroke")
		else nil
	local detailName: TextLabel? = if detail then find(detail, "PetName", "TextLabel") else nil
	local detailTags: GuiObject? = if detail then find(detail, "Tags", "GuiObject") else nil
	local detailSize: TextLabel? = if detail then find(detail, "SizeLabel", "TextLabel") else nil
	local detailModifier: TextLabel? = if detail then find(detail, "ModifierLabel", "TextLabel") else nil
	local detailEarns: TextLabel? = if detail then find(detail, "Earns", "TextLabel") else nil
	local detailRarity: TextLabel? = if detail then find(detail, "Rarity", "TextLabel") else nil
	local detailRate: TextLabel? = if detail then find(detail, "Rate", "TextLabel") else nil
	local holdButton: GuiButton? = if detail then find(detail, "HoldButton", "GuiButton") else nil
	local holdLabel: TextLabel? = if holdButton then find(holdButton, "Label", "TextLabel") else nil

	if template then
		template.Visible = false
	end
	if detail then
		detail.Visible = false
	end

	local isBusy = false
	local function request(packet: any, ...: any)
		if isBusy then
			return
		end
		isBusy = true
		local arguments = table.pack(...)
		task.spawn(function()
			local ok = packet:Fire(table.unpack(arguments, 1, arguments.n))
			isBusy = false
			if packet == Packets.BuyPedestalSlot then
				if ok == true then
					LocalSound.Play("SFX_Money_Gain")
				end
				context.Feedback(slotButton, ok == true)
			end
		end)
	end

	local function refreshSlotButton()
		local slotCount = dataController:Get({ "PedestalSlots" })
		local cash = dataController:Get({ "Cash" })
		local price: number? = nil
		if type(slotCount) == "number" then
			local _, nextPrice = PedestalSlots.Next(slotCount)
			price = nextPrice
		end
		if slotButton then
			slotButton.Visible = price ~= nil
		end
		if price then
			setText(slotLabel, `+1 Slot ${NumberFormat.Compact(price)}`)
			local canAfford = type(cash) == "number" and cash >= price
			BlockButton.Paint(
				slotFill,
				if canAfford then PetsConfig.Palette.Affordable else PetsConfig.Palette.Unavailable
			)
		end
	end

	local selectedId: string? = nil
	local selectedStack: Stack? = nil
	local selectedCard: GuiObject? = nil
	local popTween: Tween? = nil

	local function strokeCard(card: GuiObject?, stack: Stack?, isSelected: boolean)
		if not card or not stack then
			return
		end
		PetStacks.PaintStroke(card, PetStacks.IsHeld(player, stack))
		local stroke = card:FindFirstChild("OuterStroke")
		if isSelected and stroke and stroke:IsA("UIStroke") then
			stroke.Color = ToolbarConfig.SelectedStroke.Color
			stroke.Thickness = ToolbarConfig.SelectedStroke.Thickness
		end
	end

	local function hideDetail()
		strokeCard(selectedCard, selectedStack, false)
		selectedId = nil
		selectedStack = nil
		selectedCard = nil
		if detail then
			detail.Visible = false
		end
	end

	local function placeDetail()
		if not detail or not panel or not selectedCard then
			return
		end
		local scale = panel.AbsoluteSize.X / math.max(panel.Size.X.Offset, 1)
		if scale <= 0 then
			return
		end
		local popScale = if detailPop then math.max(detailPop.Scale, 0.01) else 1
		local cardPosition = (selectedCard.AbsolutePosition - panel.AbsolutePosition) / scale
		local cardSize = selectedCard.AbsoluteSize / scale
		local width = detail.Size.X.Offset
		local height = detail.AbsoluteSize.Y / scale / popScale
		local gap = ToolbarConfig.DetailGapPixels
		local edge = ToolbarConfig.DetailEdgePixels
		local right = cardPosition.X + cardSize.X + gap
		local isRight = right + width <= panel.Size.X.Offset - edge
		local below = cardPosition.Y + cardSize.Y + gap
		local roomBelow = (gui.AbsoluteSize.Y - panel.AbsolutePosition.Y) / scale - edge
		local isBelow = below + height <= roomBelow
		detail.AnchorPoint = Vector2.new(if isRight then 0 else 1, if isBelow then 0 else 1)
		local x = if isRight then right else cardPosition.X - gap
		local y = if isBelow
			then below
			else math.max(cardPosition.Y - gap, height + edge - panel.AbsolutePosition.Y / scale)
		detail.Position = UDim2.fromOffset(x, y)
	end

	local function paintHold(stack: Stack)
		if holdLabel then
			BlockButton.SetText(
				holdLabel,
				if PetStacks.IsHeld(player, stack) then ToolbarConfig.PutAwayText else ToolbarConfig.HoldText
			)
		end
	end

	local function paintRarity(rarityKey: string, text: string)
		local rarity = RarityConfig.Rarities[rarityKey]
		if detailBorder and rarity then
			detailBorder.Color = rarity.Color
		end
		if not detailRarity then
			return
		end
		detailRarity.Text = text
		local gradient = detailRarity:FindFirstChildWhichIsA("UIGradient")
		if gradient then
			gradient.Color = RarityRibbon.Colors(rarityKey)
			gradient.Rotation = if rarity and rarity.RainbowLabel then 0 else 90
		end
		local stroke = detailRarity:FindFirstChildWhichIsA("UIStroke")
		if stroke and rarity then
			stroke.Color = rarity.Color:Lerp(Color3.new(0, 0, 0), RarityConfig.RibbonDarken)
		end
	end

	local function paintGeodeDetail(stack: Stack, geodeKey: string)
		local floor = GeodeConfig.Geodes[geodeKey].MinRarity
		setText(detailName, stack.FullName)
		if detailTags then
			detailTags.Visible = false
		end
		setText(detailEarns, ToolbarConfig.GeodeUseText)
		if floor then
			local rarity = RarityConfig.Rarities[floor]
			paintRarity(
				floor,
				string.format(
					ToolbarConfig.GeodeMinRarityFormat,
					if rarity then rarity.DisplayName else floor
				)
			)
		else
			paintRarity(RarityConfig.Order[1], ToolbarConfig.GeodeAnyRarityText)
		end
		setText(detailRate, PetStacks.HatchText(geodeKey))
		paintHold(stack)
	end

	local function paintDetail(stack: Stack)
		if stack.GeodeKey then
			paintGeodeDetail(stack, stack.GeodeKey)
			return
		end
		local pet = PetConfig.Pets[stack.Key]
		local rarity = RarityConfig.Rarities[pet.Rarity]
		paintRarity(pet.Rarity, if rarity then rarity.DisplayName else pet.Rarity)
		setText(detailName, stack.Name)
		if detailSize then
			local isSized = PetSize.IsShown(stack.Size)
			detailSize.Visible = isSized
			if isSized then
				local size = PetSize.Get(stack.Size)
				detailSize.Text = size.DisplayName
				Typography.ApplyTextStyle(detailSize, size.TextStyle)
			end
		end
		local modifier = PetModifier.Get(stack.Modifier)
		if detailModifier then
			detailModifier.Visible = modifier ~= nil
			if modifier then
				detailModifier.Text = modifier.DisplayName
				PetModifier.PaintLabel(detailModifier, stack.Modifier)
			end
		end
		if detailTags then
			detailTags.Visible = PetSize.IsShown(stack.Size) or modifier ~= nil
		end
		setText(detailEarns, ToolbarConfig.DetailEarnsText)
		setText(detailRate, `${NumberFormat.Rate(stack.Rate)}/s`)
		paintHold(stack)
	end

	local function showDetail(stack: Stack, card: GuiObject)
		if not detail then
			return
		end
		local isNew = not detail.Visible or selectedId ~= stack.Id
		if selectedCard ~= card then
			strokeCard(selectedCard, selectedStack, false)
		end
		selectedId = stack.Id
		selectedStack = stack
		selectedCard = card
		strokeCard(card, stack, true)
		paintDetail(stack)
		detail.Visible = true
		if isNew and detailPop then
			if popTween then
				popTween:Cancel()
			end
			detailPop.Scale = ToolbarConfig.DetailPopFromScale
			local tween = TweenService:Create(
				detailPop,
				TweenInfo.new(ToolbarConfig.DetailPopSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			popTween = tween
			tween:Play()
		end
		placeDetail()
	end

	local function refresh()
		local pets = dataController:Get({ "Pets" })
		local slotCount = dataController:Get({ "PedestalSlots" })
		if type(pets) ~= "table" or type(slotCount) ~= "number" then
			return
		end
		local stacks = PetStacks.Build(pets)
		local geodes = dataController:Get({ "Geodes" })
		local geodeStacks: { Stack } = if type(geodes) == "table" then PetStacks.BuildGeodes(geodes) else {}
		local geodeTotal = 0
		for _, stack in geodeStacks do
			geodeTotal += stack.Count
		end
		local total = 0
		local placedCount = 0
		for _, stack in stacks do
			total += #stack.PetIds
			if stack.IsPlaced then
				placedCount += #stack.PetIds
			end
		end
		setText(
			countLabel,
			`{string.format(ToolbarConfig.CountFormat, total)}   {string.format(
				ToolbarConfig.GeodeCountFormat,
				geodeTotal
			)}   {string.format(
				ToolbarConfig.PlacedFormat,
				placedCount,
				#PedestalSlots.Unlocked(slotCount)
			)}`
		)
		refreshSlotButton()

		cardTrove:Clean()
		if not grid or not template then
			return
		end
		local filter = if search then string.lower(search.Text) else ""
		local shownCount = 0
		local selected: Stack? = nil
		local cardStacks = table.move(stacks, 1, #stacks, #geodeStacks + 1, table.clone(geodeStacks))
		for order, stack in cardStacks do
			if stack.IsPlaced then
				continue
			end
			if filter ~= "" and not string.find(string.lower(stack.FullName), filter, 1, true) then
				continue
			end
			shownCount += 1
			local card = template:Clone()
			card.Name = `Card{order}`
			card.LayoutOrder = order
			card.Visible = true
			PetStacks.Paint(card, stack)
			PetStacks.PaintStroke(card, PetStacks.IsHeld(player, stack))
			local select = card:FindFirstChild("Select", true)
			if select and select:IsA("GuiButton") then
				cardTrove:Connect(select.Activated, function()
					showDetail(stack, card)
				end)
			end
			card.Parent = grid
			cardTrove:Add(card)
			if stack.Id == selectedId then
				selected = stack
				selectedCard = card
			end
		end
		if selected and selectedCard then
			showDetail(selected, selectedCard)
		else
			hideDetail()
		end
		if emptyLabel then
			emptyLabel.Visible = shownCount == 0
			emptyLabel.Text = if total == placedCount and geodeTotal == 0
				then PetsConfig.EmptyText
				else PetsConfig.NoMatchText
		end
	end

	if slotButton then
		trove:Connect(slotButton.Activated, function()
			local slotCount = dataController:Get({ "PedestalSlots" })
			local cash = dataController:Get({ "Cash" })
			if type(slotCount) == "number" and type(cash) == "number" then
				local _, price = PedestalSlots.Next(slotCount)
				if price and price > cash then
					context.Feedback(slotButton, false)
					context.Controllers.CashPackController:Prompt(price - cash)
					return
				end
			end
			request(Packets.BuyPedestalSlot)
		end)
	end
	if equipBestButton then
		trove:Connect(equipBestButton.Activated, function()
			request(Packets.EquipBestPets)
		end)
	end
	if closeButton then
		trove:Connect(closeButton.Activated, function()
			context.Close(ToolbarConfig.PanelScreen)
		end)
	end

	if holdButton then
		trove:Connect(holdButton.Activated, function()
			if selectedStack then
				PetStacks.Toggle(player, selectedStack)
			end
		end)
	end
	if detail then
		trove:Connect(detail:GetPropertyChangedSignal("AbsoluteSize"), placeDetail)
		trove:Connect(UserInputService.InputBegan, function(input: InputObject)
			if
				not detail.Visible
				or (
					input.UserInputType ~= Enum.UserInputType.MouseButton1
					and input.UserInputType ~= Enum.UserInputType.Touch
				)
			then
				return
			end
			local inset = if gui.IgnoreGuiInset then Vector2.zero else GuiService:GetGuiInset()
			local point = Vector2.new(input.Position.X, input.Position.Y) - inset
			local corner = detail.AbsolutePosition
			local far = corner + detail.AbsoluteSize
			if point.X < corner.X or point.Y < corner.Y or point.X > far.X or point.Y > far.Y then
				hideDetail()
			end
		end)
	end
	if grid and grid:IsA("ScrollingFrame") then
		trove:Connect(grid:GetPropertyChangedSignal("CanvasPosition"), hideDetail)
	end

	local isOpen = false
	local function refreshIfOpen()
		if isOpen then
			refresh()
		end
	end
	if search then
		trove:Connect(search:GetPropertyChangedSignal("Text"), refreshIfOpen)
	end
	trove:Add(dataController:Observe({ "Cash" }, function()
		if isOpen then
			refreshSlotButton()
		end
	end))
	for _, path in { { "Pets" }, { "Geodes" }, { "PedestalSlots" } } do
		trove:Add(dataController:Observe(path, refreshIfOpen))
	end

	local characterTrove = trove:Extend()
	local function watchCharacter(character: Model?)
		characterTrove:Clean()
		if not character then
			return
		end
		for _, signal in { character.ChildAdded, character.ChildRemoved } do
			characterTrove:Connect(signal, function(child: Instance)
				if child:IsA("Tool") then
					refreshIfOpen()
				end
			end)
		end
	end
	trove:Connect(player.CharacterAdded, watchCharacter)
	watchCharacter(player.Character)

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = true
			refresh()
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			isOpen = false
			hideDetail()
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Pets
