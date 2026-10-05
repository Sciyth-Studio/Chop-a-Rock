--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SettingsConfig = require(ReplicatedStorage.Config.SettingsConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Icon = require(ReplicatedStorage.Packages.TopbarPlus) :: any
local Types = require(script.Parent.Parent.Types)

type MeterColors = {
	Edge: Color3,
	Center: Color3,
	Studs: Color3,
}

local ON_COLORS: MeterColors = {
	Edge = Color3.fromRGB(0, 190, 40),
	Center = Color3.fromRGB(150, 255, 120),
	Studs = Color3.fromRGB(0, 120, 20),
}
local OFF_COLORS: MeterColors = {
	Edge = Color3.fromRGB(120, 120, 120),
	Center = Color3.fromRGB(215, 215, 215),
	Studs = Color3.fromRGB(70, 70, 70),
}

local Settings = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[Settings] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function paint(button: TextButton, colors: MeterColors)
	local buttonFill = button:FindFirstChild("Fill", true)
	if not buttonFill then
		return
	end
	local gradient = buttonFill:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, colors.Edge),
			ColorSequenceKeypoint.new(0.5, colors.Center),
			ColorSequenceKeypoint.new(1, colors.Edge),
		})
	end
	local studs = buttonFill:FindFirstChild("StudTexture")
	if studs and studs:IsA("ImageLabel") then
		studs.ImageColor3 = colors.Studs
	end
end

function Settings.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	for _, name in SettingsConfig.Toggles do
		local button: TextButton? = find(gui, name .. "Toggle", "TextButton")
		if not button then
			continue
		end
		local label: TextLabel? = button:FindFirstChild("Label", true) :: any
		local isOn = true
		trove:Add(dataController:Observe({ "Settings", name }, function(value: any)
			isOn = value ~= false
			paint(button, if isOn then ON_COLORS else OFF_COLORS)
			if label and label:IsA("TextLabel") then
				label.Text = if isOn then "On" else "Off"
			end
		end))
		trove:Add(button.Activated:Connect(function()
			if dataController:IsLoaded() then
				Packets.SetSetting:Fire(name, not isOn)
			end
		end))
	end

	local closeButton: TextButton? = find(gui, "CloseButton", "TextButton")
	if closeButton then
		trove:Add(closeButton.Activated:Connect(function()
			context.Close("Settings")
		end))
	end

	local isOpen = false
	local icon = Icon.new()
		:setName("Settings")
		:setImage(SettingsConfig.TopbarImage)
		:setCaption(SettingsConfig.TopbarCaption)
		:oneClick()
		:bindEvent("selected", function()
			if isOpen then
				context.Close("Settings")
			else
				context.Open("Settings")
			end
		end)
	trove:Add(function()
		icon:destroy()
	end)

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = true
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

return Settings
