--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local NotificationConfig = require(ReplicatedStorage.Config.NotificationConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)
local Types = require(script.Parent.Parent.Types)

type Entry = {
	Kind: string,
	Message: string,
	Count: number,
	Frame: Frame,
	Label: TextLabel,
	Stroke: UIStroke?,
	Token: number,
}

local Notifications = {}

local function findChild(root: Instance, name: string, className: string): Instance?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[Notifications] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function style(label: TextLabel, stroke: UIStroke?, kind: string)
	local textStyle = NotificationConfig.KindStyles[kind]
	if textStyle then
		if not label:FindFirstChildWhichIsA("UIGradient") then
			Instance.new("UIGradient").Parent = label
		end
		Typography.ApplyTextStyle(label, textStyle)
		return
	end
	local prefix = WeatherConfig.NoticeKindPrefix
	if string.sub(kind, 1, #prefix) ~= prefix then
		return
	end
	local modifier = WeatherConfig.Modifiers[string.sub(kind, #prefix + 1)]
	if not modifier then
		return
	end
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(modifier.LabelTop, modifier.LabelBottom)
	gradient.Parent = label
	if stroke then
		stroke.Color = modifier.LabelBottom:Lerp(Color3.new(0, 0, 0), WeatherConfig.LabelDarkAlpha)
	end
end

function Notifications.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local container = findChild(gui, "Container", "Frame")
	local template = findChild(gui, "Template", "Frame")
	local controller = context.Controllers.NotificationController
	if not container or not template or not controller then
		warn("[Notifications] Screen disabled; missing Container, Template or NotificationController")
		return {
			Modal = false,
			StartsOpen = false,
			Open = function(_self: Types.Screen) end,
			Close = function(_self: Types.Screen) end,
			Destroy = function(_self: Types.Screen) end,
		}
	end
	local templateFrame = template :: Frame
	templateFrame.Visible = false

	local entries: { Entry } = {}
	local nextOrder = 0

	local function fade(entry: Entry, transparency: number, seconds: number)
		local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(entry.Frame, info, { BackgroundTransparency = transparency }):Play()
		TweenService:Create(entry.Label, info, { TextTransparency = transparency }):Play()
		if entry.Stroke then
			TweenService:Create(entry.Stroke, info, { Transparency = transparency }):Play()
		end
	end

	local function remove(entry: Entry)
		local index = table.find(entries, entry)
		if not index then
			return
		end
		table.remove(entries, index)
		entry.Token += 1
		fade(entry, 1, NotificationConfig.FadeOutSeconds)
		task.delay(NotificationConfig.FadeOutSeconds, function()
			entry.Frame:Destroy()
		end)
	end

	local function schedule(entry: Entry)
		entry.Token += 1
		local token = entry.Token
		local holdSeconds = NotificationConfig.KindHoldSeconds[entry.Kind] or NotificationConfig.HoldSeconds
		task.delay(NotificationConfig.FadeInSeconds + holdSeconds, function()
			if entry.Token == token then
				remove(entry)
			end
		end)
	end

	local function render(entry: Entry)
		if entry.Count > 1 then
			entry.Label.Text = `{entry.Message}{NotificationConfig.RepeatSuffix}{entry.Count}`
		else
			entry.Label.Text = entry.Message
		end
	end

	local function show(kind: string, message: string)
		LocalSound.Play(NotificationConfig.SoundKey)
		for _, entry in entries do
			if entry.Kind == kind and entry.Message == message then
				entry.Count += 1
				render(entry)
				fade(entry, 0, NotificationConfig.FadeInSeconds)
				schedule(entry)
				return
			end
		end

		local frame = templateFrame:Clone()
		local label = frame:FindFirstChild("Message", true)
		if not label or not label:IsA("TextLabel") then
			warn("[Notifications] Template needs a TextLabel named Message")
			frame:Destroy()
			return
		end
		local stroke = label:FindFirstChildWhichIsA("UIStroke")
		style(label, stroke, kind)
		nextOrder += 1
		frame.Name = `Notification{nextOrder}`
		frame.LayoutOrder = nextOrder
		frame.BackgroundTransparency = 1
		label.TextTransparency = 1
		if stroke then
			stroke.Transparency = 1
		end
		frame.Visible = true
		frame.Parent = container

		local entry: Entry = {
			Kind = kind,
			Message = message,
			Count = 1,
			Frame = frame,
			Label = label,
			Stroke = stroke,
			Token = 0,
		}
		table.insert(entries, entry)
		render(entry)
		fade(entry, 0, NotificationConfig.FadeInSeconds)
		schedule(entry)

		while #entries > NotificationConfig.MaxVisible do
			remove(entries[1])
		end
	end

	local pinned: { [string]: Entry } = {}

	local function pop(entry: Entry)
		local scale = entry.Frame:FindFirstChildWhichIsA("UIScale") or Instance.new("UIScale")
		scale.Parent = entry.Frame
		scale.Scale = NotificationConfig.PinPopFromScale
		TweenService:Create(
			scale,
			TweenInfo.new(NotificationConfig.PinPopSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
	end

	local function pin(id: string, kind: string, message: string, order: number)
		local existing = pinned[id]
		if existing then
			if existing.Message ~= message then
				existing.Message = message
				render(existing)
				pop(existing)
			end
			return
		end
		local frame = templateFrame:Clone()
		local label = frame:FindFirstChild("Message", true)
		if not label or not label:IsA("TextLabel") then
			warn("[Notifications] Template needs a TextLabel named Message")
			frame:Destroy()
			return
		end
		local stroke = label:FindFirstChildWhichIsA("UIStroke")
		frame.Name = `Pinned{id}`
		frame.LayoutOrder = NotificationConfig.PinnedLayoutOrder + order
		frame.Visible = true
		frame.Parent = container
		local entry: Entry = {
			Kind = kind,
			Message = message,
			Count = 1,
			Frame = frame,
			Label = label,
			Stroke = stroke,
			Token = 0,
		}
		pinned[id] = entry
		render(entry)
		pop(entry)
	end

	local function unpin(id: string)
		local entry = pinned[id]
		if not entry then
			return
		end
		pinned[id] = nil
		fade(entry, 1, NotificationConfig.FadeOutSeconds)
		task.delay(NotificationConfig.FadeOutSeconds, function()
			entry.Frame:Destroy()
		end)
	end

	trove:Connect(controller.Notified, show)
	trove:Connect(controller.Pinned, pin)
	trove:Connect(controller.Unpinned, unpin)
	for id, current in controller:GetPins() do
		pin(id, current.Kind, current.Message, current.Order)
	end

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
			for _, entry in entries do
				entry.Frame:Destroy()
			end
			table.clear(entries)
			for _, entry in pinned do
				entry.Frame:Destroy()
			end
			table.clear(pinned)
		end,
	}
end

return Notifications
