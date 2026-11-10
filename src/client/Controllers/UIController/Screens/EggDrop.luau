--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local Packets = require(ReplicatedStorage.Packets)
local ToolbarConfig = require(ReplicatedStorage.Config.ToolbarConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Types = require(script.Parent.Parent.Types)

local EggDrop = {}

function EggDrop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local player = Players.LocalPlayer
	local dataController = context.Controllers.DataController
	local uiController = context.Controllers.UIController
	local found = gui:FindFirstChild("DropButton", true)
	local button: GuiButton? = if found and found:IsA("GuiButton") then found else nil
	if not button then
		warn(`[EggDrop] Missing GuiButton "DropButton" in {gui:GetFullName()}`)
	end

	local isShown = false
	local hidToolbar = false

	local function isHoldingEgg(): boolean
		local character = player.Character
		local tool = if character then character:FindFirstChildOfClass("Tool") else nil
		return tool ~= nil and type(tool:GetAttribute(GeodeConfig.ToolKeyAttribute)) == "string"
	end

	local function refresh()
		local step = Tutorial.StepOf(dataController:Get({ "Tutorial" }))
		local shouldShow = isHoldingEgg() and not Tutorial.IsActive(step)
		if shouldShow == isShown then
			return
		end
		isShown = shouldShow
		if shouldShow then
			context.Open("EggDrop")
			if uiController:IsOpen(ToolbarConfig.Screen) then
				hidToolbar = true
				context.Close(ToolbarConfig.Screen)
			end
		else
			context.Close("EggDrop")
			if hidToolbar then
				hidToolbar = false
				context.Open(ToolbarConfig.Screen)
			end
		end
	end

	if button then
		trove:Connect(button.Activated, function()
			Packets.EggDropHeld:Fire()
		end)
	end

	local characterTrove = trove:Extend()
	local function watch(character: Model?)
		characterTrove:Clean()
		if character then
			characterTrove:Connect(character.ChildAdded, refresh)
			characterTrove:Connect(character.ChildRemoved, refresh)
		end
		refresh()
	end
	trove:Connect(player.CharacterAdded, watch)
	task.defer(watch, player.Character)
	trove:Add(dataController:Observe({ "Tutorial", "Step" }, refresh))

	return {
		Modal = false,
		StartsOpen = false,
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

return EggDrop
