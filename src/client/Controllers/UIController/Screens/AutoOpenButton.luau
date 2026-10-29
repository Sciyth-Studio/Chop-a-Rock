--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AutoOpenConfig = require(ReplicatedStorage.Config.AutoOpenConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local AutoOpenButton = {}

function AutoOpenButton.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local player = Players.LocalPlayer

	local containerInstance = gui:FindFirstChild("Container")
	local container: GuiObject? = if containerInstance and containerInstance:IsA("GuiObject")
		then containerInstance
		else nil
	local labelInstance = gui:FindFirstChild("Label", true)
	local label: TextLabel? = if labelInstance and labelInstance:IsA("TextLabel") then labelInstance else nil
	local shadowInstance = gui:FindFirstChild("Label" .. HudConfig.ShadowSuffix, true)
	local shadow: TextLabel? = if shadowInstance and shadowInstance:IsA("TextLabel")
		then shadowInstance
		else nil
	local stopInstance = gui:FindFirstChild("Stop", true)
	local stop: GuiButton? = if stopInstance and stopInstance:IsA("GuiButton") then stopInstance else nil
	if not container or not label or not stop then
		warn(`[AutoOpenButton] Missing "Container", "Label" or "Stop" in {gui:GetFullName()}`)
	end

	local function refresh()
		local isRunning = player:GetAttribute(AutoOpenConfig.RunningAttribute) == true
		if container then
			container.Visible = isRunning
		end
		local count = player:GetAttribute(AutoOpenConfig.CountAttribute)
		local text = string.format(AutoOpenConfig.PillFormat, if type(count) == "number" then count else 0)
		if label then
			label.Text = text
		end
		if shadow then
			shadow.Text = text
		end
	end

	trove:Connect(player:GetAttributeChangedSignal(AutoOpenConfig.RunningAttribute), refresh)
	trove:Connect(player:GetAttributeChangedSignal(AutoOpenConfig.CountAttribute), refresh)
	if stop then
		trove:Connect(stop.Activated, function()
			Packets.StopAutoOpen:Fire()
		end)
	end
	trove:Connect(ProximityPromptService.PromptTriggered, function(prompt: ProximityPrompt)
		if not CollectionService:HasTag(prompt, AutoOpenConfig.PromptTag) then
			return
		end
		local purchases = context.Controllers.PurchaseController
		if not purchases:OwnsPass(AutoOpenConfig.PassKey) then
			purchases:PromptPass(AutoOpenConfig.PassKey)
		end
	end)
	refresh()

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

return AutoOpenButton
