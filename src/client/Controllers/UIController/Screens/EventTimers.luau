--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local EventClockConfig = require(ReplicatedStorage.Config.EventClockConfig)
local EventTimerConfig = require(ReplicatedStorage.Config.EventTimerConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeatherClock = require(ReplicatedStorage.WeatherClock)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)
local Types = require(script.Parent.Parent.Types)

type Status = {
	Image: string,
	Remaining: number,
	Key: string,
	IsActive: boolean,
	IsSleeping: boolean,
}

type Tile = {
	Clock: EventClockConfig.Clock,
	Frame: GuiObject,
	Icons: { ImageLabel },
	Labels: { TextLabel },
	Image: string,
	Text: string,
	Status: Status?,
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

local function runningBoss(now: number): Status?
	local boss = workspace:FindFirstChild(EventTimerConfig.BossModelName)
	if boss then
		local phase = number(boss:GetAttribute(BossConfig.PhaseAttribute))
		if phase ~= BossConfig.Phases.Defeated and phase ~= BossConfig.Phases.Leaving then
			local key = text(boss:GetAttribute(BossConfig.BossAttribute))
			return {
				Image = EventTimerConfig.Icons[key] or "",
				Remaining = number(boss:GetAttribute(BossConfig.EndsAtAttribute)) - now,
				Key = key,
				IsActive = true,
				IsSleeping = phase == BossConfig.Phases.Sleeping,
			}
		end
	end
	local diamond = workspace:FindFirstChild(EventTimerConfig.DiamondModelName)
	local rock = if diamond then diamond:FindFirstChild(EventTimerConfig.DiamondPartName) else nil
	if rock then
		local remaining = number(rock:GetAttribute(DiamondRockConfig.EndsAtAttribute)) - now
		if remaining > 0 then
			return {
				Image = EventTimerConfig.Icons.DiamondRock,
				Remaining = remaining,
				Key = "DiamondRock",
				IsActive = true,
				IsSleeping = false,
			}
		end
	end
	return nil
end

local function status(clock: EventClockConfig.Clock, now: number): Status
	if clock.Name == EventTimerConfig.BossClock then
		local running = runningBoss(now)
		if running then
			return running
		end
	end
	if clock.Name == EventTimerConfig.WeatherClock then
		local active = text(workspace:GetAttribute(WeatherConfig.WeatherAttribute))
		if active ~= "" then
			return {
				Image = weatherIcon(active),
				Remaining = number(workspace:GetAttribute(WeatherConfig.EndsAtAttribute)) - now,
				Key = active,
				IsActive = true,
				IsSleeping = false,
			}
		end
	end
	local key = text(workspace:GetAttribute(clock.KeyAttribute))
	local remaining = number(workspace:GetAttribute(clock.AtAttribute)) - now
	if key == "Weather" then
		local nextKey = text(workspace:GetAttribute(WeatherConfig.NextKeyAttribute))
		return {
			Image = weatherIcon(nextKey),
			Remaining = remaining,
			Key = if nextKey ~= "" then nextKey else key,
			IsActive = false,
			IsSleeping = false,
		}
	end
	return {
		Image = EventTimerConfig.Icons[key] or "",
		Remaining = remaining,
		Key = key,
		IsActive = false,
		IsSleeping = false,
	}
end

local function describe(current: Status): (string, string, string)
	local seconds = math.max(0, math.ceil(current.Remaining))
	local footer = if current.IsActive
		then string.format(EventTimerConfig.EndsFormat, seconds // 60, seconds % 60)
		else string.format(EventTimerConfig.NextFormat, seconds // 60, seconds % 60)
	local weather = WeatherClock.Event(current.Key)
	if weather then
		local modifier = WeatherConfig.Modifiers[weather.Modifier]
		local body = string.format(
			EventTimerConfig.WeatherBodyFormat,
			tostring(weather.RockMultiplier),
			if modifier then modifier.DisplayName else weather.Modifier
		)
		return weather.DisplayName, body, footer
	end
	local boss = BossConfig.Bosses[current.Key]
	if boss then
		local body = if current.IsSleeping
			then EventTimerConfig.BossSleepingText
			else EventTimerConfig.BossBodyText
		return boss.DisplayName, body, footer
	end
	local info = EventTimerConfig.Info[current.Key]
	if info then
		return info.Title, info.Body, footer
	end
	return current.Key, "", footer
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
	return {
		Clock = clock,
		Frame = frame,
		Icons = icons,
		Labels = labels,
		Image = "",
		Text = "",
		Status = nil,
	}
end

local function setText(label: TextLabel?, value: string)
	if not label then
		return
	end
	label.Text = value
	local shadow = if label.Parent
		then label.Parent:FindFirstChild(label.Name .. HudConfig.ShadowSuffix)
		else nil
	if shadow and shadow:IsA("TextLabel") then
		shadow.Text = value
	end
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
	local cardInstance = gui:FindFirstChild(EventTimerConfig.CardName)
	local card: GuiObject? = if cardInstance and cardInstance:IsA("GuiObject") then cardInstance else nil
	if not card then
		warn(`[EventTimers] Missing "{EventTimerConfig.CardName}" in {gui:GetFullName()}; no event info`)
	end
	local function cardLabel(name: string): TextLabel?
		local found = if card then card:FindFirstChild(name, true) else nil
		return if found and found:IsA("TextLabel") then found else nil
	end
	local cardTitle = cardLabel(EventTimerConfig.CardTitleName)
	local cardBody = cardLabel(EventTimerConfig.CardBodyName)
	local cardFooter = cardLabel(EventTimerConfig.CardFooterName)
	if card then
		card.Visible = false
	end

	local tiles: { Tile } = {}
	local hovered: Tile? = nil
	local pinned: Tile? = nil
	local pinnedUntil = 0

	if template then
		template.Visible = false
		for index, clock in EventClockConfig.Clocks do
			local tile = buildTile(template, clock, index)
			table.insert(tiles, tile)
			local hit = tile.Frame:FindFirstChild(EventTimerConfig.HitName)
			if hit and hit:IsA("GuiButton") then
				trove:Connect(hit.MouseEnter, function()
					hovered = tile
				end)
				trove:Connect(hit.MouseLeave, function()
					if hovered == tile then
						hovered = nil
					end
				end)
				trove:Connect(hit.Activated, function()
					if pinned == tile then
						pinned = nil
					else
						pinned = tile
						pinnedUntil = os.clock() + EventTimerConfig.PinSeconds
					end
				end)
			end
		end
	end

	local function paintCard()
		if not card then
			return
		end
		if pinned and os.clock() > pinnedUntil then
			pinned = nil
		end
		local shown = hovered or pinned
		local current = if shown and shown.Frame.Visible then shown.Status else nil
		card.Visible = current ~= nil
		if current then
			local title, body, footer = describe(current)
			setText(cardTitle, title)
			setText(cardBody, body)
			setText(
				cardFooter,
				if current.IsActive and current.Remaining <= 0 then EventTimerConfig.NowText else footer
			)
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
			local current = status(tile.Clock, now)
			tile.Status = current
			tile.Frame.Visible = current.Remaining > 0
			if current.Image ~= tile.Image then
				tile.Image = current.Image
				for _, icon in tile.Icons do
					icon.Image = current.Image
					icon.Visible = current.Image ~= ""
				end
			end
			local seconds = math.max(0, math.ceil(current.Remaining))
			local label = string.format(EventTimerConfig.TimeText, seconds // 60, seconds % 60)
			if label ~= tile.Text then
				tile.Text = label
				for _, textLabel in tile.Labels do
					textLabel.Text = label
				end
			end
		end
		paintCard()
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
