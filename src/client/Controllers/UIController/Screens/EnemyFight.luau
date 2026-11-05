--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopStyleConfig = require(ReplicatedStorage.Config.ChopStyleConfig)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local EnemyRules = require(ReplicatedStorage.Utils.EnemyRules)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local Input = require(ReplicatedStorage.Packages.Input)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Types = require(script.Parent.Parent.Types)

local EnemyFight = {}

local random = Random.new()

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

local function setShown(gui: Instance, label: GuiObject?, isShown: boolean)
	if not label then
		return
	end
	label.Visible = isShown
	local copy = gui:FindFirstChild(label.Name .. HudConfig.ShadowSuffix, true)
	if copy and copy:IsA("GuiObject") then
		copy.Visible = isShown
	end
end

local function pop(label: GuiObject?)
	local scale = if label then label:FindFirstChild("Pop") else nil
	if scale and scale:IsA("UIScale") then
		scale.Scale = EnemyConfig.PopScale
		TweenService:Create(
			scale,
			TweenInfo.new(EnemyConfig.PopSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
	end
end

function EnemyFight.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controller = context.Controllers.EnemyController
	ViewportScale.Bind(gui, trove)

	local bar: Frame? = find(gui, "Container", "Frame")
	local nameLabel: TextLabel? = find(gui, "EnemyName", "TextLabel")
	local youLabel: TextLabel? = find(gui, "YouName", "TextLabel")
	local hintLabel: TextLabel? = find(gui, "Hint", "TextLabel")
	local tapLeft: TextLabel? = find(gui, "TapLeft", "TextLabel")
	local tapRight: TextLabel? = find(gui, "TapRight", "TextLabel")
	local fill: Frame? = find(gui, "Fill", "Frame")
	local enemyFill: Frame? = find(gui, "EnemyFill", "Frame")
	local divider: Frame? = find(gui, "Divider", "Frame")
	local face: ImageLabel? = find(gui, "Face", "ImageLabel")
	local banner: TextLabel? = find(gui, "Banner", "TextLabel")
	local count: TextLabel? = find(gui, "Count", "TextLabel")
	local result: TextLabel? = find(gui, "Result", "TextLabel")
	local words: Frame? = find(gui, "Words", "Frame")
	local wordTemplate: TextLabel? = find(gui, "WordTemplate", "TextLabel")
	if fill then
		fill.BackgroundColor3 = ChopStyleConfig.Qualities[ChopQuality.Good].Color
	end
	if enemyFill then
		enemyFill.BackgroundColor3 = ChopStyleConfig.Qualities[ChopQuality.Bad].Color
	end
	setPair(gui, youLabel, EnemyConfig.YouText)
	setPair(gui, banner, EnemyConfig.BannerText)
	if face then
		face.Image = `rbxthumb://type=AvatarHeadShot&id={Players.LocalPlayer.UserId}&w=150&h=150`
	end

	local shownShare = EnemyConfig.StartShare
	local shownPhase = ""
	local shownCount = 0
	local isFaster = false

	local function setFaster(faster: boolean)
		isFaster = faster
		local text = if faster then EnemyConfig.FasterText else EnemyConfig.TapText
		local style = if faster then EnemyConfig.FasterStyle else EnemyConfig.TapStyle
		for _, tap in { tapLeft, tapRight } :: { TextLabel? } do
			if tap then
				tap.Text = text
				Typography.ApplyTextStyle(tap, style)
			end
		end
	end

	local function resetStage()
		shownShare = EnemyConfig.StartShare
		shownPhase = ""
		shownCount = 0
		setFaster(false)
		setShown(gui, banner, false)
		setShown(gui, count, false)
		setShown(gui, result, false)
		if bar then
			bar.Visible = false
		end
	end

	local function showWord()
		local template = wordTemplate
		if not template or not words or random:NextNumber() > EnemyConfig.WordChance then
			return
		end
		local word = template:Clone()
		word.Name = "Word"
		word.Text = EnemyConfig.ClickWords[random:NextInteger(1, #EnemyConfig.ClickWords)]
		word.Position = UDim2.fromScale(random:NextNumber(0.15, 0.85), random:NextNumber(0.2, 0.8))
		word.Rotation = random:NextNumber(-12, 12)
		word.Visible = true
		Typography.ApplyTextStyle(
			word,
			EnemyConfig.WordStyles[random:NextInteger(1, #EnemyConfig.WordStyles)]
		)
		word.Parent = words
		pop(word)
		local info = TweenInfo.new(EnemyConfig.WordSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local rise = UDim2.fromOffset(0, -EnemyConfig.WordRisePixels)
		TweenService:Create(word, info, { Position = word.Position + rise, TextTransparency = 1 }):Play()
		local stroke = word:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(stroke, info, { Transparency = 1 }):Play()
		end
		task.delay(EnemyConfig.WordSeconds, function()
			word:Destroy()
		end)
	end

	trove:Add(controller.FightChanged:Connect(function(view: any)
		if view then
			setPair(gui, nameLabel, view.Name)
			resetStage()
		else
			setShown(gui, banner, false)
			setShown(gui, count, false)
			if bar then
				bar.Visible = false
			end
		end
	end))
	trove:Add(controller.ResultShown:Connect(function(outcome: string)
		local isWin = outcome == "Won"
		setPair(gui, result, if isWin then EnemyConfig.WinText else EnemyConfig.LoseText)
		if result then
			Typography.ApplyTextStyle(result, if isWin then EnemyConfig.WinStyle else EnemyConfig.LoseStyle)
		end
		setShown(gui, result, true)
		pop(result)
	end))
	trove:Add(controller.Clicked:Connect(showWord))
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
		local phase, number = EnemyRules.IntroPhase(os.clock() - view.StartedAt)
		if phase ~= shownPhase or number ~= shownCount then
			shownPhase = phase
			shownCount = number
			setShown(gui, banner, phase == "Banner")
			setShown(gui, count, phase == "Count")
			if phase == "Banner" then
				pop(banner)
			elseif phase == "Count" then
				setPair(gui, count, tostring(number))
				pop(count)
			end
			if bar then
				bar.Visible = phase == "Fight" or number == 1
			end
		end
		local target = 1 - math.clamp(view.Health / math.max(view.MaxHealth, 1e-9), 0, 1)
		shownShare += (target - shownShare) * math.min(dt * EnemyConfig.BarFollowSpeed, 1)
		if fill then
			fill.Size = UDim2.fromScale(shownShare, 1)
		end
		if divider then
			divider.Position = UDim2.fromScale(shownShare, 0.5)
		end
		local faster = phase == "Fight" and shownShare < EnemyConfig.FasterShare
		if faster ~= isFaster then
			setFaster(faster)
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
			resetStage()
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
			resetStage()
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return EnemyFight
