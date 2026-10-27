--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local settings = MonetizationConfig.BoostPill

type Pill = {
	Entry: MonetizationConfig.BoostPillEntry,
	Frame: GuiObject,
	Labels: { TextLabel },
	Text: string,
}

local BoostPills = {}

local function endsAt(entry: MonetizationConfig.BoostPillEntry): number
	local value = if entry.Source == "Personal"
		then Players.LocalPlayer:GetAttribute(MonetizationConfig.BoostEndsAttributePrefix .. entry.Key)
		else workspace:GetAttribute(MonetizationConfig.ServerBoostEndsAttributePrefix .. entry.Key)
	return if type(value) == "number" then value else 0
end

local function format(text: string, seconds: number): string
	if seconds >= 3600 then
		return string.format(
			settings.HoursFormat,
			text,
			seconds // 3600,
			(seconds % 3600) // 60,
			seconds % 60
		)
	end
	return string.format(settings.MinutesFormat, text, seconds // 60, seconds % 60)
end

function BoostPills.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local stackInstance = gui:FindFirstChild("Stack")
	local stack: GuiObject? = if stackInstance and stackInstance:IsA("GuiObject") then stackInstance else nil
	local templateInstance = if stack then stack:FindFirstChild("PillTemplate") else nil
	local template: GuiObject? = if templateInstance and templateInstance:IsA("GuiObject")
		then templateInstance
		else nil
	local scaleInstance = if stack then stack:FindFirstChild("ScreenScale") else nil
	local screenScale: UIScale? = if scaleInstance and scaleInstance:IsA("UIScale")
		then scaleInstance
		else nil
	if not stack or not template then
		warn(`[BoostPills] Missing "Stack" or "Stack.PillTemplate" in {gui:GetFullName()}`)
	end

	local pills: { Pill } = {}
	if stack and template then
		template.Visible = false
		for index, entry in settings.Pills do
			local frame = template:Clone()
			frame.Name = `{entry.Source}{entry.Key}`
			frame.LayoutOrder = index
			frame.Parent = stack
			trove:Add(frame)
			local labels: { TextLabel } = {}
			for _, name in { "Label", "Label" .. HudConfig.ShadowSuffix } do
				local label = frame:FindFirstChild(name)
				if label and label:IsA("TextLabel") then
					table.insert(labels, label)
				end
			end
			local label = frame:FindFirstChild("Label")
			if label and label:IsA("TextLabel") then
				Typography.ApplyTextStyle(label, entry.TextStyle)
			end
			for _, child in frame:GetChildren() do
				if child:IsA("ImageLabel") and string.sub(child.Name, 1, 4) == "Icon" then
					child.Image = entry.Icon
				end
			end
			table.insert(pills, { Entry = entry, Frame = frame, Labels = labels, Text = "" })
		end
	end

	local function place()
		if not stack then
			return
		end
		local scale = if screenScale then screenScale.Scale else 1
		local offset = settings.EdgeOffsetPixels + (settings.WeatherHeightPixels + settings.GapPixels) * scale
		stack.Position = UDim2.new(1, -settings.EdgeOffsetPixels, 1, -offset)
	end

	local function refresh()
		local now = workspace:GetServerTimeNow()
		for _, pill in pills do
			local pausedValue = if pill.Entry.Source == "Personal"
				then Players.LocalPlayer:GetAttribute(
					MonetizationConfig.BoostPausedAttributePrefix .. pill.Entry.Key
				)
				else nil
			local paused = type(pausedValue) == "number"
			local seconds = if paused
				then pausedValue :: number
				else math.max(0, math.ceil(endsAt(pill.Entry) - now))
			pill.Frame.Visible = seconds > 0
			if seconds > 0 then
				local text = format(pill.Entry.Text, seconds)
				if paused then
					text = `{text} {settings.PausedSuffix}`
				end
				if text ~= pill.Text then
					pill.Text = text
					for _, label in pill.Labels do
						label.Text = text
					end
				end
			end
		end
	end

	if screenScale then
		trove:Connect(screenScale:GetPropertyChangedSignal("Scale"), place)
	end
	place()

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

return BoostPills
