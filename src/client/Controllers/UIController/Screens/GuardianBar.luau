--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local GuardianBarConfig = require(ReplicatedStorage.Config.GuardianBarConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local ZoneBannerConfig = require(ReplicatedStorage.Config.ZoneBannerConfig)
local ZoneAt = require(ReplicatedStorage.Utils.ZoneAt)
local Types = require(script.Parent.Parent.Types)

local GuardianBar = {}

local function find(root: Instance, name: string, class: string): Instance?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(class) then
		return found
	end
	warn(`[GuardianBar] Missing {class} "{name}" in {root:GetFullName()}`)
	return nil
end

local function setText(label: TextLabel?, text: string)
	if not label then
		return
	end
	label.Text = text
	local shadow = if label.Parent
		then label.Parent:FindFirstChild(label.Name .. HudConfig.ShadowSuffix)
		else nil
	if shadow and shadow:IsA("TextLabel") then
		shadow.Text = text
	end
end

local function stageFor(share: number): GuardianBarConfig.Stage
	for _, stage in GuardianBarConfig.Stages do
		if share > stage.Above then
			return stage
		end
	end
	return GuardianBarConfig.Stages[#GuardianBarConfig.Stages]
end

function GuardianBar.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local player = Players.LocalPlayer

	local root = find(gui, "Root", "Frame") :: Frame?
	local body = find(gui, "Body", "Frame") :: Frame?
	local title = find(gui, "Title", "TextLabel") :: TextLabel?
	local fill = find(gui, "Fill", "Frame") :: Frame?
	local ghost = gui:FindFirstChild("Ghost", true)
	local flash = gui:FindFirstChild("Flash", true)
	local timer = find(gui, "Timer", "TextLabel") :: TextLabel?
	local popScale = if body then body:FindFirstChild("PopScale") else nil
	local fillGradient = if fill then fill:FindFirstChildWhichIsA("UIGradient") else nil
	if ghost and ghost:IsA("GuiObject") then
		ghost.Visible = false
	end
	if root then
		root.Visible = false
	end

	local lastZone = ""
	local enteredAt = 0
	local bannerSeconds = ZoneBannerConfig.FadeInSeconds
		+ ZoneBannerConfig.HoldSeconds
		+ ZoneBannerConfig.FadeOutSeconds
	local shownZone = ""
	local exiting = false
	local stage: GuardianBarConfig.Stage? = nil
	local flashUntil = 0
	local timerText = ""

	local function pop(target: number, seconds: number, direction: Enum.EasingDirection): Tween?
		if popScale and popScale:IsA("UIScale") then
			local tween = TweenService:Create(
				popScale,
				TweenInfo.new(seconds, Enum.EasingStyle.Back, direction),
				{ Scale = target }
			)
			tween:Play()
			return tween
		end
		return nil
	end

	local function show(zone: string)
		shownZone = zone
		exiting = false
		stage = nil
		timerText = ""
		if root then
			root.Visible = true
		end
		if popScale and popScale:IsA("UIScale") then
			popScale.Scale = 0
		end
		pop(1, GuardianBarConfig.EnterPopSeconds, Enum.EasingDirection.Out)
		setText(title, string.format(GuardianBarConfig.TitleFormat, zone))
	end

	local function hide()
		if shownZone == "" or exiting then
			return
		end
		exiting = true
		local tween = pop(0, GuardianBarConfig.ExitSeconds, Enum.EasingDirection.In)
		local function finish()
			if exiting then
				exiting = false
				shownZone = ""
				if root then
					root.Visible = false
				end
			end
		end
		if tween then
			tween.Completed:Once(finish)
		else
			finish()
		end
	end

	local function currentZone(): string
		local character = player.Character
		local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
		return if rootPart and rootPart:IsA("BasePart") then ZoneAt(rootPart.Position) else ""
	end

	local function step()
		local zone = currentZone()
		if zone ~= lastZone then
			lastZone = zone
			enteredAt = os.clock()
		end
		local wakesAt = if zone ~= ""
			then player:GetAttribute(EnemyConfig.KnockedOutAttributePrefix .. zone)
			else nil
		if type(wakesAt) ~= "number" then
			hide()
			return
		end
		if shownZone ~= zone and os.clock() - enteredAt < bannerSeconds then
			hide()
			return
		end
		if shownZone ~= zone or exiting then
			show(zone)
		end
		local paused =
			player:GetAttribute(MonetizationConfig.BoostPausedAttributePrefix .. EnemyConfig.FreeEggsPillKey)
		local left = if type(paused) == "number"
			then paused
			else math.max(0, wakesAt - workspace:GetServerTimeNow())
		local total = player:GetAttribute(EnemyConfig.KnockoutTotalAttribute)
		local share = if type(total) == "number" and total > 0 then math.clamp(left / total, 0, 1) else 1
		if fill then
			fill.Size = UDim2.fromScale(share, 1)
		end
		local nextStage = stageFor(share)
		if nextStage ~= stage then
			if stage then
				flashUntil = os.clock() + GuardianBarConfig.FlashSeconds
			end
			stage = nextStage
			if fillGradient then
				fillGradient.Color = nextStage.Fill
			end
			if title then
				Typography.ApplyTextStyle(title, nextStage.TitleStyle)
			end
		end
		if flash and flash:IsA("GuiObject") then
			flash.BackgroundTransparency = if os.clock() < flashUntil
				then GuardianBarConfig.FlashTransparency
				else 1
		end
		local whole = math.ceil(left)
		local text = string.format(GuardianBarConfig.TimerFormat, whole // 60, whole % 60)
		if text ~= timerText then
			timerText = text
			setText(timer, text)
		end
		local isWarning = left <= EnemyConfig.SleepWarnSeconds
		if timer then
			timer.TextColor3 = if isWarning
				then GuardianBarConfig.TimerWarnColor
				else GuardianBarConfig.TimerColor
		end
		if body then
			if isWarning then
				local urgency = 1 - left / EnemyConfig.SleepWarnSeconds
				local amount = GuardianBarConfig.ShakeMinPixels
					+ (GuardianBarConfig.ShakeMaxPixels - GuardianBarConfig.ShakeMinPixels) * urgency
				body.Position =
					UDim2.new(0.5, (math.random() * 2 - 1) * amount, 0.5, (math.random() * 2 - 1) * amount)
			else
				body.Position = UDim2.fromScale(0.5, 0.5)
			end
		end
	end

	local openTrove = trove:Extend()

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			openTrove:Connect(RunService.Heartbeat, step)
		end,
		Close = function(_self: Types.Screen)
			openTrove:Clean()
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return GuardianBar
