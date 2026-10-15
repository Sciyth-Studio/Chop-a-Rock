--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeatherClock = require(ReplicatedStorage.WeatherClock)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)
local Types = require(script.Parent.Parent.Types)

local WeatherPill = {}

local function number(value: any): number
	return if type(value) == "number" then value else 0
end

local function paint(label: TextLabel?, top: Color3, bottom: Color3, dark: Color3)
	if not label then
		return
	end
	local gradient = label:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(top, bottom)
		gradient.Rotation = 90
	end
	local stroke = label:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Color = dark
	end
end

function WeatherPill.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

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
	if not container or not label then
		warn(`[WeatherPill] Missing "Container" or "Label" in {gui:GetFullName()}`)
	end

	local icons: { ImageLabel } = {}
	if container then
		for _, child in container:GetChildren() do
			if child:IsA("ImageLabel") and string.sub(child.Name, 1, 4) == "Icon" then
				table.insert(icons, child)
			end
		end
	end
	local labelGap = if label then label.Size.X.Offset else 0
	local function setIcon(image: string, dark: Color3)
		local gap = if image ~= "" then labelGap else 0
		for _, text in { label, shadow } do
			if text then
				text.Size = UDim2.new(text.Size.X.Scale, gap, text.Size.Y.Scale, text.Size.Y.Offset)
			end
		end
		for _, icon in icons do
			icon.Image = image
			icon.Visible = image ~= ""
			if string.find(icon.Name, "Outline", 1, true) then
				icon.ImageColor3 = dark
			end
		end
	end

	local shownText = ""
	local shownKey: string? = nil
	local function refresh()
		if not container then
			return
		end
		local now = workspace:GetServerTimeNow()
		local value = workspace:GetAttribute(WeatherConfig.WeatherAttribute)
		local event = if type(value) == "string" and value ~= "" then WeatherClock.Event(value) else nil
		local remaining = if event
			then number(workspace:GetAttribute(WeatherConfig.EndsAtAttribute)) - now
			else number(workspace:GetAttribute(WeatherConfig.NextAtAttribute)) - now
		local seconds = math.max(0, math.ceil(remaining))
		container.Visible = event ~= nil or remaining > 0
		local key = if event then event.Key else ""
		if key ~= shownKey then
			shownKey = key
			local modifier = if event then WeatherConfig.Modifiers[event.Modifier] else nil
			local top = if modifier then modifier.LabelTop else WeatherConfig.PillIdleTop
			local bottom = if modifier then modifier.LabelBottom else WeatherConfig.PillIdleBottom
			local dark = if modifier
				then modifier.LabelBottom:Lerp(Color3.new(0, 0, 0), WeatherConfig.PillDarkAlpha)
				else WeatherConfig.PillIdleDark
			paint(label, top, bottom, dark)
			setIcon(if event then event.Icon else WeatherConfig.PillIdleIcon, dark)
		end
		local text = if event
			then string.format(WeatherConfig.PillActiveText, event.DisplayName, seconds // 60, seconds % 60)
			else string.format(WeatherConfig.PillNextText, seconds // 60, seconds % 60)
		if text == shownText then
			return
		end
		shownText = text
		if label then
			label.Text = text
		end
		if shadow then
			shadow.Text = text
		end
	end

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			trove:Connect(RunService.Heartbeat, refresh)
			refresh()
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return WeatherPill
