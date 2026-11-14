--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActivePetsConfig = require(ReplicatedStorage.Config.ActivePetsConfig)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Packets = require(ReplicatedStorage.Packets)
local PedestalSlots = require(ReplicatedStorage.PedestalSlots)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local PetModifier = require(ReplicatedStorage.PetModifier)
local PetSize = require(ReplicatedStorage.PetSize)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local PetStacks = require(script.Parent.Parent.PetStacks)
local Types = require(script.Parent.Parent.Types)

local ActivePets = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[ActivePets] Missing {className} "{name}" in {root:GetFullName()}`)
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

local function paintTag(tag: TextLabel?, stack: PetStacks.Stack)
	if not tag then
		return
	end
	local modifier = PetModifier.Get(stack.Modifier)
	if modifier then
		tag.Visible = true
		tag.Text = if PetSize.IsShown(stack.Size)
			then `{PetSize.Get(stack.Size).DisplayName} {modifier.DisplayName}`
			else modifier.DisplayName
		PetModifier.PaintLabel(tag, stack.Modifier)
	elseif PetSize.IsShown(stack.Size) then
		local size = PetSize.Get(stack.Size)
		tag.Visible = true
		tag.Text = size.DisplayName
		Typography.ApplyTextStyle(tag, size.TextStyle)
	else
		tag.Visible = false
	end
end

function ActivePets.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local rowTrove = trove:Extend()
	local dataController = context.Controllers.DataController

	local title: TextLabel? = find(gui, "Title", "TextLabel")
	local stored: TextLabel? = find(gui, "StoredLabel", "TextLabel")
	local list: GuiObject? = find(gui, "List", "GuiObject")
	local template: Frame? = find(gui, "RowTemplate", "Frame")
	local slotButton: GuiButton? = find(gui, "SlotButton", "GuiButton")
	local slotLabel: TextLabel? = if slotButton then find(slotButton, "Label", "TextLabel") else nil
	local slotFill = if slotButton then slotButton:FindFirstChild("Fill", true) else nil
	local equipBest: GuiButton? = find(gui, "EquipBestButton", "GuiButton")
	local collapse: GuiButton? = find(gui, "CollapseButton", "GuiButton")
	if template then
		template.Visible = false
	end
	if equipBest then
		BlockButton.Paint(equipBest:FindFirstChild("Fill", true), ActivePetsConfig.EquipBest)
	end

	local isOpen = false
	local isBusy = false

	local function request(button: GuiButton?, packet: any, ...: any)
		if isBusy then
			return
		end
		isBusy = true
		local arguments = table.pack(...)
		task.spawn(function()
			local ok = packet:Fire(table.unpack(arguments, 1, arguments.n))
			isBusy = false
			if packet == Packets.BuyPedestalSlot and ok == true then
				LocalSound.Play("SFX_Money_Gain")
			end
			context.Feedback(button, ok == true)
		end)
	end

	local function refreshSlot()
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
			setText(slotLabel, string.format(ActivePetsConfig.SlotFormat, NumberFormat.Compact(price)))
			local canAfford = type(cash) == "number" and cash >= price
			BlockButton.Paint(
				slotFill,
				if canAfford then ActivePetsConfig.Affordable else ActivePetsConfig.Unavailable
			)
		end
	end

	local function refresh()
		local pets = dataController:Get({ "Pets" })
		local slotCount = dataController:Get({ "PedestalSlots" })
		if type(pets) ~= "table" or type(slotCount) ~= "number" then
			return
		end
		local placed: { { Stack: PetStacks.Stack, Slot: number } } = {}
		local storedCount = 0
		for _, stack in PetStacks.Build(pets) do
			if stack.IsPlaced then
				for _, slot in stack.Slots do
					table.insert(placed, { Stack = stack, Slot = slot })
				end
			else
				storedCount += #stack.PetIds
			end
		end
		table.sort(placed, function(a, b)
			if a.Stack.Rate ~= b.Stack.Rate then
				return a.Stack.Rate > b.Stack.Rate
			end
			return a.Slot < b.Slot
		end)
		local text = string.format(ActivePetsConfig.TitleFormat, #placed, #PedestalSlots.Unlocked(slotCount))
		setText(title, text)
		setText(stored, string.format(ActivePetsConfig.StoredFormat, storedCount))
		refreshSlot()

		rowTrove:Clean()
		if not list or not template then
			return
		end
		for order, entry in placed do
			local row = template:Clone()
			row.Name = `Row{order}`
			row.LayoutOrder = order
			row.Visible = true
			PetStacks.Paint(row, entry.Stack)
			local pet = PetConfig.Pets[entry.Stack.Key]
			local nameLabel = row:FindFirstChild("PetName")
			if pet and nameLabel and nameLabel:IsA("TextLabel") then
				nameLabel.Text = pet.DisplayName
			end
			paintTag(row:FindFirstChild("Tag") :: TextLabel?, entry.Stack)
			local button = row:FindFirstChild("UnequipButton")
			if button and button:IsA("GuiButton") then
				BlockButton.Paint(button:FindFirstChild("Fill", true), ActivePetsConfig.Unequip)
				local label = button:FindFirstChild("Label")
				if label then
					BlockButton.SetText(label, ActivePetsConfig.UnequipText)
				end
				local slot = entry.Slot
				rowTrove:Connect(button.Activated, function()
					request(button, Packets.UnequipPet, slot)
				end)
			end
			row.Parent = list
			rowTrove:Add(row)
		end
	end

	local function refreshIfOpen()
		if isOpen then
			refresh()
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
			request(slotButton, Packets.BuyPedestalSlot)
		end)
	end
	if equipBest then
		trove:Connect(equipBest.Activated, function()
			request(equipBest, Packets.EquipBestPets)
		end)
	end
	if collapse then
		trove:Connect(collapse.Activated, function()
			context.Close(ActivePetsConfig.Screen)
		end)
	end
	for _, path in { { "Pets" }, { "PedestalSlots" }, { "Cash" } } do
		trove:Add(dataController:Observe(path, refreshIfOpen))
	end

	return {
		Modal = false,
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

return ActivePets
