--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local Input = require(ReplicatedStorage.Packages.Input)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Types = require(script.Parent.Parent.Types)

local EnemyFight = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[EnemyFight] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function setPair(gui: Instance, label: TextLabel?, text: string)
	if not label then
		return
	end
	label.Text = text
	local copy = gui:FindFirstChild(label.Name .. HudConfig.ShadowSuffix, true)
	if copy and copy:IsA("TextLabel") then
		copy.Text = text
	end
end

function EnemyFight.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controller = context.Controllers.EnemyController
	ViewportScale.Bind(gui, trove)

	local nameLabel: TextLabel? = find(gui, "EnemyName", "TextLabel")
	local timeLabel: TextLabel? = find(gui, "TimeLeft", "TextLabel")
	local hintLabel: TextLabel? = find(gui, "Hint", "TextLabel")
	local fill: Frame? = find(gui, "Fill", "Frame")
	BlockButton.Paint(fill, {
		Edge = EnemyConfig.HealthEdge,
		Center = EnemyConfig.HealthCenter,
		Studs = EnemyConfig.HealthStuds,
	})

	local fillTween: Tween? = nil
	local shownSeconds = -1
	local isWarning = false

	local function setHealth(health: number, maxHealth: number)
		local bar = fill
		if not bar then
			return
		end
		if fillTween then
			fillTween:Cancel()
		end
		local ratio = if maxHealth > 0 then math.clamp(health / maxHealth, 0, 1) else 0
		local tween = TweenService:Create(
			bar,
			TweenInfo.new(EnemyConfig.HealthTweenSeconds),
			{ Size = UDim2.fromScale(ratio, 1) }
		)
		fillTween = tween
		tween:Play()
	end

	local function setWarning(warning: boolean)
		isWarning = warning
		if timeLabel then
			local style = if warning then EnemyConfig.TimeWarningStyle else EnemyConfig.TimeNormalStyle
			Typography.ApplyTextStyle(timeLabel, style)
		end
	end

	trove:Add(controller.HealthChanged:Connect(setHealth))
	trove:Add(controller.FightChanged:Connect(function(view: any)
		if not view then
			return
		end
		setPair(gui, nameLabel, view.Name)
		shownSeconds = -1
		setWarning(false)
		if fillTween then
			fillTween:Cancel()
		end
		if fill then
			fill.Size = UDim2.fromScale(1, 1)
		end
	end))
	trove:Add(Input.PreferredInput.observe(function(preferred: Enum.PreferredInput)
		local hint = if preferred == Enum.PreferredInput.Touch
			then EnemyConfig.HintTouch
			elseif preferred == Enum.PreferredInput.Gamepad then EnemyConfig.HintGamepad
			else EnemyConfig.HintMouse
		setPair(gui, hintLabel, hint)
		return nil
	end))
	trove:Add(RunService.Heartbeat:Connect(function()
		local view = if gui.Enabled then controller:GetFight() else nil
		if not view then
			return
		end
		local remaining = math.max(view.EndsAt - os.clock(), 0)
		local seconds = math.ceil(remaining)
		if seconds == shownSeconds then
			return
		end
		shownSeconds = seconds
		setPair(gui, timeLabel, `{seconds}s`)
		local warning = remaining <= EnemyConfig.TimeWarningSeconds
		if warning ~= isWarning then
			setWarning(warning)
		end
	end))

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			if fillTween then
				fillTween:Cancel()
			end
			trove:Destroy()
		end,
	}
end

return EnemyFight
