--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HotStreakConfig = require(ReplicatedStorage.Config.HotStreakConfig)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local HotStreakFx = {}

local function findGroup(gui: ScreenGui, name: string): CanvasGroup?
	local found = gui:FindFirstChild(name)
	if not found or not found:IsA("CanvasGroup") then
		warn(`[HotStreakFx] Missing CanvasGroup "{name}" in {gui:GetFullName()}`)
		return nil
	end
	return found
end

local function findLabel(group: CanvasGroup, name: string): TextLabel?
	local found = group:FindFirstChild(name)
	if not found or not found:IsA("TextLabel") then
		warn(`[HotStreakFx] Missing TextLabel "{name}" in {group:GetFullName()}`)
		return nil
	end
	return found
end

local function styleText(label: TextLabel, edge: Color3, center: Color3, stroke: Color3)
	local gradient = label:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, edge),
			ColorSequenceKeypoint.new(0.5, center),
			ColorSequenceKeypoint.new(1, edge),
		})
	end
	local outline = label:FindFirstChildWhichIsA("UIStroke")
	if outline then
		outline.Color = stroke
	end
end

function HotStreakFx.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local controller = context.Controllers.HotStreakController
	local vignette = findGroup(gui, "Vignette")
	local pop = findGroup(gui, "Pop")
	local down = findGroup(gui, "Down")
	local popText = if pop then findLabel(pop, "TierText") else nil
	local popShadow = if pop then findLabel(pop, "TierTextShadow") else nil
	local downText = if down then findLabel(down, "DownText") else nil
	local downShadow = if down then findLabel(down, "DownTextShadow") else nil
	local popScaleInstance = if pop then pop:FindFirstChild("PopScale") else nil
	local popScale = if popScaleInstance and popScaleInstance:IsA("UIScale") then popScaleInstance else nil
	local popToken = 0
	local downToken = 0
	local vignetteTween: Tween? = nil
	ViewportScale.Bind(gui, trove)

	local function showGroup(group: CanvasGroup, holdSeconds: number, token: () -> boolean)
		group.GroupTransparency = 0
		group.Visible = true
		task.delay(holdSeconds, function()
			if not token() then
				return
			end
			local fade = TweenService:Create(
				group,
				TweenInfo.new(HotStreakConfig.FadeOutSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ GroupTransparency = 1 }
			)
			fade.Completed:Once(function(state: Enum.PlaybackState)
				if state == Enum.PlaybackState.Completed and token() then
					group.Visible = false
				end
			end)
			fade:Play()
		end)
	end

	local function onTierUp(tier: number)
		local definition = HotStreakConfig.Tiers[tier]
		if not definition then
			return
		end
		if pop and popText and popShadow then
			popToken += 1
			local token = popToken
			local text = `{HotStreakConfig.PopText}{definition.Multiplier}`
			popText.Text = text
			popShadow.Text = text
			styleText(popText, definition.Main, definition.Light, definition.Dark)
			if popScale then
				popScale.Scale = HotStreakConfig.PopStartScale
				TweenService:Create(
					popScale,
					TweenInfo.new(
						HotStreakConfig.PopInSeconds,
						Enum.EasingStyle.Back,
						Enum.EasingDirection.Out
					),
					{ Scale = HotStreakConfig.PopPeakScale }
				):Play()
			end
			showGroup(pop, HotStreakConfig.PopInSeconds + HotStreakConfig.PopHoldSeconds, function(): boolean
				return token == popToken
			end)
		end
		if vignette then
			local strength = definition.VignetteStrength
				* (if LowGraphics.IsOn() then HotStreakConfig.LowGraphicsFxScale else 1)
			for _, child in vignette:GetChildren() do
				if child:IsA("Frame") then
					child.BackgroundColor3 = definition.Main
				end
			end
			if vignetteTween then
				vignetteTween:Cancel()
			end
			vignette.GroupTransparency = 1 - strength
			local fade = TweenService:Create(
				vignette,
				TweenInfo.new(
					HotStreakConfig.VignetteSeconds,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				),
				{ GroupTransparency = 1 }
			)
			vignetteTween = fade
			fade:Play()
		end
	end

	local function onDropped()
		if not (down and downText and downShadow) then
			return
		end
		downToken += 1
		local token = downToken
		downText.Text = HotStreakConfig.DownText
		downShadow.Text = HotStreakConfig.DownText
		styleText(
			downText,
			HotStreakConfig.DownColor,
			HotStreakConfig.DownLightColor,
			HotStreakConfig.DownDarkColor
		)
		showGroup(down, HotStreakConfig.DownHoldSeconds, function(): boolean
			return token == downToken
		end)
	end

	if controller then
		trove:Add(controller.TierUp:Connect(onTierUp))
		trove:Add(controller.Dropped:Connect(onDropped))
	else
		warn("[HotStreakFx] HotStreakController missing; effects disabled")
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
		end,
	}
end

return HotStreakFx
