--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SettingsConfig = require(ReplicatedStorage.Config.SettingsConfig)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
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

local SLIDER_SEND_INTERVAL = 0.1

local Settings = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[Settings] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function paintMeter(button: TextButton, colors: MeterColors)
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
		local isOn = false
		trove:Add(dataController:Observe({ "Settings", name }, function(value: any)
			isOn = value == true
			BlockButton.Paint(button:FindFirstChild("Fill", true), if isOn then ON_COLORS else OFF_COLORS)
			if label and label:IsA("TextLabel") then
				BlockButton.SetText(label, if isOn then "On" else "Off")
			end
		end))
		trove:Add(button.Activated:Connect(function()
			if dataController:IsLoaded() then
				Packets.SetSetting:Fire(name, not isOn)
			end
		end))
	end

	for _, name in SettingsConfig.Sliders do
		local slider: TextButton? = find(gui, name .. "Slider", "TextButton")
		if not slider then
			continue
		end
		local track: Frame? = slider:FindFirstChild("Track") :: any
		local fill: Frame? = if track then track:FindFirstChild("Fill") :: any else nil
		if not track or not fill then
			warn(`[Settings] {slider:GetFullName()} needs Track.Fill`)
			continue
		end
		local knob: Frame? = track:FindFirstChild("Knob") :: any
		local valueLabel: TextLabel? = find(gui, name .. "Value", "TextLabel")
		local minusButton: TextButton? = find(gui, name .. "Minus", "TextButton")
		local plusButton: TextButton? = find(gui, name .. "Plus", "TextButton")
		paintMeter(slider, ON_COLORS)

		local maxPercent = SettingsConfig.MaxVolumePercent
		local stepPercent = SettingsConfig.VolumeStepPercent
		local dragging = false
		local current = maxPercent
		local lastSent = -1
		local lastSentAt = 0

		local function show(percent: number)
			current = percent
			local alpha = percent / maxPercent
			fill.Size = UDim2.fromScale(alpha, 1)
			if knob then
				knob.Position = UDim2.fromScale(alpha, 0.5)
			end
			if valueLabel then
				valueLabel.Text = `{percent}%`
			end
		end

		local function send(percent: number, force: boolean)
			if percent == lastSent or not dataController:IsLoaded() then
				return
			end
			if not force and os.clock() - lastSentAt < SLIDER_SEND_INTERVAL then
				return
			end
			lastSent = percent
			lastSentAt = os.clock()
			Packets.SetVolume:Fire(name, percent)
		end

		local function update(input: InputObject, force: boolean)
			local width = track.AbsoluteSize.X
			if width <= 0 then
				return
			end
			local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / width, 0, 1)
			local percent = math.round(alpha * maxPercent)
			show(percent)
			send(percent, force)
		end

		local function step(direction: number)
			local snapped = if direction > 0
				then math.floor(current / stepPercent) * stepPercent + stepPercent
				else math.ceil(current / stepPercent) * stepPercent - stepPercent
			local percent = math.clamp(snapped, 0, maxPercent)
			show(percent)
			send(percent, true)
		end

		trove:Add(dataController:Observe({ "Settings", name }, function(value: any)
			if dragging then
				return
			end
			local level = if type(value) == "number" then value else 1
			show(math.round(math.clamp(level, 0, 1) * maxPercent))
		end))
		if minusButton then
			trove:Add(minusButton.Activated:Connect(function()
				step(-1)
			end))
		end
		if plusButton then
			trove:Add(plusButton.Activated:Connect(function()
				step(1)
			end))
		end
		trove:Add(slider.InputBegan:Connect(function(input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = true
				update(input, false)
			end
		end))
		trove:Add(UserInputService.InputChanged:Connect(function(input: InputObject)
			if
				dragging
				and (
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				)
			then
				update(input, false)
			end
		end))
		trove:Add(UserInputService.InputEnded:Connect(function(input: InputObject)
			if
				dragging
				and (
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				)
			then
				dragging = false
				update(input, true)
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
