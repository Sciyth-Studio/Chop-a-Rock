--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local ToolbarConfig = require(ReplicatedStorage.Config.ToolbarConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local BaseLevels = require(ReplicatedStorage.Utils.BaseLevels)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local PetStacks = require(script.Parent.Parent.PetStacks)
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

	local isOpen = gui.Enabled

	local function isHoldingEgg(): boolean
		local character = player.Character
		local tool = if character then character:FindFirstChildOfClass("Tool") else nil
		if not tool or type(tool:GetAttribute(GeodeConfig.ToolKeyAttribute)) ~= "string" then
			return false
		end
		return not Tutorial.IsActive(Tutorial.StepOf(dataController:Get({ "Tutorial" })))
	end

	local function applyVisibility()
		gui.Enabled = isOpen and not isHoldingEgg()
	end

	local bar: Frame? = find(gui, "Bar", "Frame")
	local template: Frame? = find(gui, "SlotTemplate", "Frame")
	local bagButton: GuiObject? = find(gui, ToolbarConfig.BagButtonName, "GuiObject")
	local bagClick: GuiButton? = if bagButton then find(bagButton, "Button", "GuiButton") else nil

	local slots: { Frame } = {}
	local shown: { [number]: PetStacks.Stack } = {}

	local popupRoot: Frame? = find(gui, "PopupRoot", "Frame")
	local knownPets: { [string]: boolean }? = nil
	local popupQueue: { PetStacks.Stack } = {}
	local isPopping = false

	local function playPopups()
		if isPopping or not popupRoot or not template then
			return
		end
		local stack = table.remove(popupQueue, 1)
		if not stack then
			return
		end
		isPopping = true
		local card = template:Clone()
		card.Name = "NewPetPopup"
		card.Visible = true
		card.AnchorPoint = Vector2.new(0.5, 1)
		card.Position = UDim2.fromScale(0.5, 1)
		card.Size = UDim2.fromOffset(ToolbarConfig.PopupSizePixels, ToolbarConfig.PopupSizePixels)
		local button = card:FindFirstChild("Button")
		if button then
			button:Destroy()
		end
		local pop = Instance.new("UIScale")
		pop.Scale = 0
		pop.Parent = card
		card.Parent = popupRoot
		PetStacks.Paint(card, stack)
		local count = card:FindFirstChild("Count")
		if count and count:IsA("GuiObject") then
			count.Visible = false
		end
		local appear = TweenService:Create(
			pop,
			TweenInfo.new(ToolbarConfig.PopupInSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
		appear:Play()
		task.delay(ToolbarConfig.PopupInSeconds + ToolbarConfig.PopupHoldSeconds, function()
			local leave = TweenService:Create(
				pop,
				TweenInfo.new(ToolbarConfig.PopupOutSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.In),
				{ Scale = 0 }
			)
			leave.Completed:Once(function()
				card:Destroy()
				isPopping = false
				playPopups()
			end)
			leave:Play()
		end)
	end

	local function notePets(pets: any)
		if type(pets) ~= "table" then
			return
		end
		local now = workspace:GetServerTimeNow()
		local isFirst = knownPets == nil
		local known: { [string]: boolean } = knownPets or {}
		knownPets = known
		for id, record in pets do
			if known[id] or type(record) ~= "table" then
				continue
			end
			if type(record.RevealAt) == "number" and record.RevealAt > now then
				continue
			end
			known[id] = true
			if not isFirst then
				local built = PetStacks.Build({ [id] = record })
				if built[1] then
					table.insert(popupQueue, built[1])
				end
			end
		end
		playPopups()
	end

	local function refresh()
		local pets = dataController:Get({ "Pets" })
		notePets(pets)
		local revealIn = PetStacks.NextReveal(pets)
		if revealIn then
			task.delay(revealIn + 0.05, refresh)
		end
		local geodes = dataController:Get({ "Geodes" })
		local stacks: { PetStacks.Stack } = if type(geodes) == "table"
			then PetStacks.BuildGeodes(
				geodes,
				dataController:Get({ "EggLuck" }),
				BaseLevels.HatchMultiplier(dataController:Get({ "BaseLevel" }))
			)
			else {}
		if type(pets) == "table" then
			for _, stack in PetStacks.Build(pets) do
				if not stack.IsPlaced then
					table.insert(stacks, stack)
				end
			end
		end
		table.clear(shown)
		for index, slot in slots do
			local stack = stacks[index]
			if stack then
				shown[index] = stack
			end
			slot.Visible = stack ~= nil
			PetStacks.Paint(slot, stack)
			PetStacks.PaintStroke(slot, stack ~= nil and PetStacks.IsHeld(player, stack))
		end
	end

	local function activate(index: number)
		local stack = shown[index]
		if stack then
			PetStacks.Toggle(player, stack)
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

	local function togglePanel()
		if context.Controllers.UIController:IsOpen(ToolbarConfig.PanelScreen) then
			context.Close(ToolbarConfig.PanelScreen)
		else
			context.Open(ToolbarConfig.PanelScreen)
		end
	end

	if bagClick then
		trove:Connect(bagClick.Activated, togglePanel)
	end

	trove:Connect(UserInputService.InputBegan, function(input: InputObject, isProcessed: boolean)
		if isProcessed or not gui.Enabled then
			return
		end
		if input.KeyCode == ToolbarConfig.PanelKey then
			togglePanel()
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
					applyVisibility()
				end
			end)
			characterTrove:Connect(character.ChildRemoved, function(child: Instance)
				if child:IsA("Tool") then
					refresh()
					applyVisibility()
				end
			end)
		end
		refresh()
		applyVisibility()
	end
	trove:Connect(player.CharacterAdded, watchCharacter)
	watchCharacter(player.Character)

	trove:Add(dataController:Observe({ "Pets" }, refresh))
	trove:Add(dataController:Observe({ "Geodes" }, refresh))
	trove:Add(dataController:Observe({ "EggLuck" }, refresh))
	trove:Add(dataController:Observe({ "BaseLevel" }, refresh))
	trove:Add(dataController:Observe({ "Tutorial", "Step" }, applyVisibility))

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			isOpen = true
			applyVisibility()
		end,
		Close = function(_self: Types.Screen)
			isOpen = false
			applyVisibility()
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Toolbar
