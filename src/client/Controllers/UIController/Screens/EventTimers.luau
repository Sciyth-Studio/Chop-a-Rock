--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EventClockConfig = require(ReplicatedStorage.Config.EventClockConfig)
local EventTimerConfig = require(ReplicatedStorage.Config.EventTimerConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeatherClock = require(ReplicatedStorage.WeatherClock)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)
local Types = require(script.Parent.Parent.Types)

type Tile = {
	Clock: EventClockConfig.Clock,
	Frame: GuiObject,
	Icons: { ImageLabel },
	Labels: { TextLabel },
	Image: string,
	Text: string,
}

local EventTimers = {}

local function number(value: any): number
	return if type(value) == "number" then value else 0
end

local function text(value: any): string
	return if type(value) == "string" then value else ""
end

local function weatherIcon(key: string): string
	local event = if key ~= "" then WeatherClock.Event(key) else nil
	return if event and event.Icon ~= "" then event.Icon else EventTimerConfig.WeatherIdleIcon
end

local function status(clock: EventClockConfig.Clock, now: number): (string, number)
	if clock.Name == EventTimerConfig.WeatherClock then
		local active = text(workspace:GetAttribute(WeatherConfig.WeatherAttribute))
		if active ~= "" then
			return weatherIcon(active), number(workspace:GetAttribute(WeatherConfig.EndsAtAttribute)) - now
		end
	end
	local key = text(workspace:GetAttribute(clock.KeyAttribute))
	local remaining = number(workspace:GetAttribute(clock.AtAttribute)) - now
	if key == "Weather" then
		return weatherIcon(text(workspace:GetAttribute(WeatherConfig.NextKeyAttribute))), remaining
	end
	return EventTimerConfig.Icons[key] or "", remaining
end

local function buildTile(template: GuiObject, clock: EventClockConfig.Clock, order: number): Tile
	local frame = template:Clone()
	frame.Name = clock.Name
	frame.LayoutOrder = order
	frame.Visible = false
	local icons: { ImageLabel } = {}
	local labels: { TextLabel } = {}
	for _, child in frame:GetChildren() do
		if child:IsA("ImageLabel") and child.Name == EventTimerConfig.IconName then
			table.insert(icons, child)
		elseif
			child:IsA("TextLabel")
			and (child.Name == EventTimerConfig.TimeName or child.Name == EventTimerConfig.TimeShadowName)
		then
			table.insert(labels, child)
		end
	end
	frame.Parent = template.Parent
	return { Clock = clock, Frame = frame, Icons = icons, Labels = labels, Image = "", Text = "" }
end

function EventTimers.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local container = gui:FindFirstChild(EventTimerConfig.ContainerName)
	local templateInstance = if container
		then container:FindFirstChild(EventTimerConfig.TemplateName)
		else nil
	local template: GuiObject? = if templateInstance and templateInstance:IsA("GuiObject")
		then templateInstance
		else nil
	if not template then
		warn(`[EventTimers] Missing "{EventTimerConfig.TemplateName}" in {gui:GetFullName()}`)
	end

	local tiles: { Tile } = {}
	if template then
		template.Visible = false
		for index, clock in EventClockConfig.Clocks do
			table.insert(tiles, buildTile(template, clock, index))
		end
	end

	local elapsed = math.huge
	local function refresh(dt: number)
		elapsed += dt
		if elapsed < EventTimerConfig.RefreshSeconds then
			return
		end
		elapsed = 0
		local now = workspace:GetServerTimeNow()
		for _, tile in tiles do
			local image, remaining = status(tile.Clock, now)
			tile.Frame.Visible = remaining > 0
			if image ~= tile.Image then
				tile.Image = image
				for _, icon in tile.Icons do
					icon.Image = image
					icon.Visible = image ~= ""
				end
			end
			local seconds = math.max(0, math.ceil(remaining))
			local label = string.format(EventTimerConfig.TimeText, seconds // 60, seconds % 60)
			if label ~= tile.Text then
				tile.Text = label
				for _, textLabel in tile.Labels do
					textLabel.Text = label
				end
			end
		end
	end

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			trove:Connect(RunService.Heartbeat, refresh)
			refresh(math.huge)
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return EventTimers
