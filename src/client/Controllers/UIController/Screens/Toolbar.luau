--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local ToolbarConfig = require(ReplicatedStorage.Config.ToolbarConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local RokStacks = require(script.Parent.Parent.RokStacks)
local Types = require(script.Parent.Parent.Types)

local Toolbar = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[Toolbar] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

function Toolbar.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
	local player = Players.LocalPlayer
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false)

	local bar: Frame? = find(gui, "Bar", "Frame")
	local template: Frame? = find(gui, "SlotTemplate", "Frame")
	local toggle: GuiObject? = find(gui, "RoksToggle", "GuiObject")
	local toggleButton: GuiButton? = if toggle then find(toggle, "Button", "GuiButton") else nil

	local slots: { Frame } = {}
	local shown: { [number]: RokStacks.Stack } = {}

	local function refresh()
		local pets = dataController:Get({ "Pets" })
		local stacks: { RokStacks.Stack } = {}
		if type(pets) == "table" then
			for _, stack in RokStacks.Build(pets) do
				if not stack.IsPlaced then
					table.insert(stacks, stack)
				end
			end
		end
		local held = RokStacks.HeldPetId(player)
		table.clear(shown)
		for index, slot in slots do
			local stack = stacks[index]
			if stack then
				shown[index] = stack
			end
			RokStacks.Paint(slot, stack)
			RokStacks.PaintStroke(slot, stack ~= nil and RokStacks.Contains(stack, held), false)
		end
	end

	local function activate(index: number)
		local stack = shown[index]
		if stack then
			RokStacks.Toggle(player, stack)
		end
	end

	if template and bar then
		template.Visible = false
		for index = 1, ToolbarConfig.SlotCount do
			local slot = template:Clone()
			slot.Name = `Slot{index}`
			slot.LayoutOrder = index
			slot.Visible = true
			slot.Parent = bar
			trove:Add(slot)
			table.insert(slots, slot)
			local button = slot:FindFirstChild("Button")
			if button and button:IsA("GuiButton") then
				trove:Connect(button.Activated, function()
					activate(index)
				end)
			end
		end
	end

	if toggleButton then
		trove:Connect(toggleButton.Activated, function()
			if context.Controllers.UIController:IsOpen(ToolbarConfig.PanelScreen) then
				context.Close(ToolbarConfig.PanelScreen)
			else
				context.Open(ToolbarConfig.PanelScreen)
			end
		end)
	end

	trove:Connect(UserInputService.InputBegan, function(input: InputObject, isProcessed: boolean)
		if isProcessed or not gui.Enabled then
			return
		end
		local index = table.find(ToolbarConfig.SlotKeys, input.KeyCode)
		if index then
			activate(index)
		end
	end)

	local characterTrove = trove:Extend()
	local function watchCharacter(character: Model?)
		characterTrove:Clean()
		if character then
			characterTrove:Connect(character.ChildAdded, function(child: Instance)
				if child:IsA("Tool") then
					refresh()
				end
			end)
			characterTrove:Connect(character.ChildRemoved, function(child: Instance)
				if child:IsA("Tool") then
					refresh()
				end
			end)
		end
		refresh()
	end
	trove:Connect(player.CharacterAdded, watchCharacter)
	watchCharacter(player.Character)

	trove:Add(dataController:Observe({ "Pets" }, refresh))

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

return Toolbar
