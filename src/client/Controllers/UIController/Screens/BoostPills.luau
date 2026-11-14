--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local PotionConfig = require(ReplicatedStorage.Config.PotionConfig)
local TextStyleConfig = require(ReplicatedStorage.Config.TextStyleConfig)
local OutlinedIcon = require(ReplicatedStorage.Utils.OutlinedIcon)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local settings = MonetizationConfig.BoostPill

type Pill = {
	Entry: MonetizationConfig.BoostPillEntry,
	Frame: GuiObject,
	Labels: { TextLabel },
	LabelSizes: { [TextLabel]: UDim2 },
	PauseParts: { GuiObject },
	Text: string,
	IsPaused: boolean?,
}

local BoostPills = {}

local entries: { MonetizationConfig.BoostPillEntry } = table.clone(settings.Pills)
for _, potion in PotionConfig.Sorted() do
	table.insert(entries, {
		Source = "Personal",
		Key = PotionConfig.BoostKey(potion.Key),
		Text = potion.PillText,
		TextStyle = potion.TextStyle,
		Icon = potion.Icon,
	})
end

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

local function paintPauseBar(bar: GuiObject, styleName: string)
	local style = TextStyleConfig.Styles[styleName]
	if not style then
		return
	end
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	local gradient = bar:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Rotation = style.GradientRotation
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, style.EdgeColor),
			ColorSequenceKeypoint.new(0.5, style.CenterColor),
			ColorSequenceKeypoint.new(1, style.EdgeColor),
		})
	end
	local stroke = bar:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Color = style.StrokeColor
	end
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
	if template and not template:FindFirstChild(settings.PauseIconName) then
		warn(
			`[BoostPills] Missing "{settings.PauseIconName}" in {template:GetFullName()}; paused shows no icon`
		)
	end

	local pills: { Pill } = {}
	if stack and template then
		template.Visible = false
		for index, entry in entries do
			local frame = template:Clone()
			frame.Name = `{entry.Source}{entry.Key}`
			frame.LayoutOrder = index
			frame.Parent = stack
			trove:Add(frame)
			local labels: { TextLabel } = {}
			local labelSizes: { [TextLabel]: UDim2 } = {}
			for _, name in { "Label", "Label" .. HudConfig.ShadowSuffix } do
				local label = frame:FindFirstChild(name)
				if label and label:IsA("TextLabel") then
					table.insert(labels, label)
					labelSizes[label] = label.Size
				end
			end
			local label = frame:FindFirstChild("Label")
			if label and label:IsA("TextLabel") then
				Typography.ApplyTextStyle(label, entry.TextStyle)
			end
			for _, child in frame:GetChildren() do
				if child:IsA("ImageLabel") and string.sub(child.Name, 1, 4) == "Icon" then
					child.Image = OutlinedIcon.For(child, entry.Icon)
				end
			end
			local pauseParts: { GuiObject } = {}
			for _, name in { settings.PauseIconName, settings.PauseIconName .. HudConfig.ShadowSuffix } do
				local part = frame:FindFirstChild(name)
				if part and part:IsA("GuiObject") then
					part.Visible = false
					table.insert(pauseParts, part)
				end
			end
			local pauseIcon = frame:FindFirstChild(settings.PauseIconName)
			if pauseIcon then
				for _, bar in pauseIcon:GetChildren() do
					if bar:IsA("GuiObject") then
						paintPauseBar(bar, entry.TextStyle)
					end
				end
			end
			table.insert(pills, {
				Entry = entry,
				Frame = frame,
				Labels = labels,
				LabelSizes = labelSizes,
				PauseParts = pauseParts,
				Text = "",
				IsPaused = nil,
			})
		end
	end

	local function place()
		if not stack then
			return
		end
		local scale = if screenScale then screenScale.Scale else 1
		local edge = settings.EdgeOffsetPixels * scale
		local offset = edge + (settings.EventTimersHeightPixels + settings.GapPixels) * scale
		stack.Position = UDim2.new(1, -edge, 1, -offset)
	end

	local function setPaused(pill: Pill, isPaused: boolean)
		if pill.IsPaused == isPaused then
			return
		end
		pill.IsPaused = isPaused
		local hasIcon = isPaused and #pill.PauseParts > 0
		for _, part in pill.PauseParts do
			part.Visible = hasIcon
		end
		for label, size in pill.LabelSizes do
			label.Size = if hasIcon then size - UDim2.fromOffset(settings.PauseIconGapPixels, 0) else size
		end
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
				setPaused(pill, paused)
				local text = format(pill.Entry.Text, seconds)
				if paused and #pill.PauseParts == 0 then
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
