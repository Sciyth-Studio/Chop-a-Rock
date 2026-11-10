--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local EnemyRules = require(ReplicatedStorage.Utils.EnemyRules)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
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
	local banner: TextLabel? = find(gui, "Banner", "TextLabel")
	local count: TextLabel? = find(gui, "Count", "TextLabel")
	local result: TextLabel? = find(gui, "Result", "TextLabel")
	setPair(gui, banner, EnemyConfig.BannerText)

	local shownPhase = ""
	local shownCount = 0

	local function resetStage()
		shownPhase = ""
		shownCount = 0
		setShown(gui, banner, false)
		setShown(gui, count, false)
		setShown(gui, result, false)
		if bar then
			bar.Visible = false
		end
	end

	trove:Add(controller.FightChanged:Connect(function(view: any)
		if view then
			resetStage()
		else
			setShown(gui, banner, false)
			setShown(gui, count, false)
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
	trove:Add(RunService.Heartbeat:Connect(function()
		local view = if gui.Enabled then controller:GetFight() else nil
		if not view then
			return
		end
		local phase, number = EnemyRules.IntroPhase(os.clock() - view.StartedAt)
		if phase == shownPhase and number == shownCount then
			return
		end
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
