--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Packets = require(ReplicatedStorage.Packets)
local PedestalSlots = require(ReplicatedStorage.PedestalSlots)
local RobuxButton = require(ReplicatedStorage.Utils.RobuxButton)
local RoksConfig = require(ReplicatedStorage.Config.RoksConfig)
local ToolbarConfig = require(ReplicatedStorage.Config.ToolbarConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local RokStacks = require(script.Parent.Parent.RokStacks)
local Types = require(script.Parent.Parent.Types)

local Roks = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[Roks] Missing {className} "{name}" in {root:GetFullName()}`)
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

function Roks.new(context: Types.Context, gui: ScreenGui): Types.Screen
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
	local slotRobuxInstance = if slotButton then slotButton:FindFirstChild("RobuxButton") else nil
	local slotRobux: GuiButton? = if slotRobuxInstance and slotRobuxInstance:IsA("GuiButton")
		then slotRobuxInstance
		else nil
	local equipBestButton: TextButton? = find(gui, "EquipBestButton", "TextButton")
	local closeButton: GuiButton? = find(gui, "CloseButton", "GuiButton")

	if template then
		template.Visible = false
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
			local shortfall = price - (if type(cash) == "number" then cash else 0)
			local pack = if shortfall > 0
				then context.Controllers.PurchaseController:CoveringPack(shortfall)
				else nil
			RobuxButton.Show(slotRobux, if pack and pack.ProductId then pack.RobuxPrice else nil)
			BlockButton.Paint(
				slotFill,
				if canAfford then RoksConfig.Palette.Affordable else RoksConfig.Palette.Unavailable
			)
		end
	end

	local function refresh()
		local pets = dataController:Get({ "Pets" })
		local slotCount = dataController:Get({ "PedestalSlots" })
		if type(pets) ~= "table" or type(slotCount) ~= "number" then
			return
		end
		local stacks = RokStacks.Build(pets)
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
		local held = RokStacks.HeldPetId(player)
		local shownCount = 0
		for order, stack in stacks do
			if filter ~= "" and not string.find(string.lower(stack.FullName), filter, 1, true) then
				continue
			end
			shownCount += 1
			local card = template:Clone()
			card.Name = `Card{order}`
			card.LayoutOrder = order
			card.Visible = true
			RokStacks.Paint(card, stack)
			RokStacks.PaintStroke(card, RokStacks.Contains(stack, held), stack.IsPlaced)
			local placedBadge = card:FindFirstChild("PlacedBadge")
			local placedLabel = card:FindFirstChild("PlacedLabel", true)
			if placedBadge and placedBadge:IsA("GuiObject") then
				placedBadge.Visible = stack.IsPlaced
			end
			if placedLabel and placedLabel:IsA("TextLabel") then
				placedLabel.Text = ToolbarConfig.PlacedText
			end
			local select = card:FindFirstChild("Select", true)
			if select and select:IsA("GuiButton") then
				cardTrove:Connect(select.Activated, function()
					if stack.IsPlaced then
						request(Packets.UnequipPet, stack.Slots[1])
					else
						RokStacks.Toggle(player, stack)
					end
				end)
			end
			card.Parent = grid
			cardTrove:Add(card)
		end
		if emptyLabel then
			emptyLabel.Visible = shownCount == 0
			emptyLabel.Text = if total == 0 then RoksConfig.EmptyText else RoksConfig.NoMatchText
		end
	end

	if slotRobux then
		trove:Connect(slotRobux.Activated, function()
			local slotCount = dataController:Get({ "PedestalSlots" })
			local cash = dataController:Get({ "Cash" })
			if type(slotCount) == "number" and type(cash) == "number" then
				local _, price = PedestalSlots.Next(slotCount)
				if price and price > cash then
					context.Controllers.PurchaseController:PromptCash(price - cash)
				end
			end
		end)
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
	for _, path in { { "Pets" }, { "PedestalSlots" } } do
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
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Roks
