--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local Input = require(ReplicatedStorage.Packages.Input)
local Trove = require(ReplicatedStorage.Packages.Trove)
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
	local youLabel: TextLabel? = find(gui, "YouName", "TextLabel")
	local hintLabel: TextLabel? = find(gui, "Hint", "TextLabel")
	local tapLeft: TextLabel? = find(gui, "TapLeft", "TextLabel")
	local tapRight: TextLabel? = find(gui, "TapRight", "TextLabel")
	local fill: Frame? = find(gui, "Fill", "Frame")
	local enemyFill: Frame? = find(gui, "EnemyFill", "Frame")
	local divider: Frame? = find(gui, "Divider", "Frame")
	local face: ImageLabel? = find(gui, "Face", "ImageLabel")
	BlockButton.Paint(fill, {
		Edge = EnemyConfig.YouEdge,
		Center = EnemyConfig.YouCenter,
		Studs = EnemyConfig.YouStuds,
	})
	BlockButton.Paint(enemyFill, {
		Edge = EnemyConfig.HealthEdge,
		Center = EnemyConfig.HealthCenter,
		Studs = EnemyConfig.HealthStuds,
	})
	setPair(gui, youLabel, EnemyConfig.YouText)
	if face then
		face.Image = `rbxthumb://type=AvatarHeadShot&id={Players.LocalPlayer.UserId}&w=150&h=150`
	end

	local shownShare = EnemyConfig.StartShare

	trove:Add(controller.FightChanged:Connect(function(view: any)
		if view then
			setPair(gui, nameLabel, view.Name)
			shownShare = EnemyConfig.StartShare
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
	trove:Add(RunService.Heartbeat:Connect(function(dt: number)
		local view = if gui.Enabled then controller:GetFight() else nil
		if not view then
			return
		end
		local target = 1 - math.clamp(view.Health / math.max(view.MaxHealth, 1e-9), 0, 1)
		shownShare += (target - shownShare) * math.min(dt * EnemyConfig.BarFollowSpeed, 1)
		if fill then
			fill.Size = UDim2.fromScale(shownShare, 1)
		end
		if divider then
			divider.Position = UDim2.fromScale(shownShare, 0.5)
		end
		local pulse = 1 + EnemyConfig.TapPulseAmount * math.sin(os.clock() * EnemyConfig.TapPulseSpeed)
		for _, tap in { tapLeft, tapRight } :: { TextLabel? } do
			local scale = if tap then tap:FindFirstChildOfClass("UIScale") else nil
			if scale then
				scale.Scale = pulse
			end
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
			trove:Destroy()
		end,
	}
end

return EnemyFight
