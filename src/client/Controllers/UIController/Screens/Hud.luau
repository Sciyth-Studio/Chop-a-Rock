--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local ScaleConfig = require(ReplicatedStorage.Config.ScaleConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local NumberTicker = require(ReplicatedStorage.Utils.NumberTicker)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Input = require(ReplicatedStorage.Packages.Input)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WaitFor = require(ReplicatedStorage.Packages.WaitFor)
local Types = require(script.Parent.Parent.Types)

local DELTA_TEMPLATE = "MoneyDelta"

local Hud = {}

local function formatMoney(value: number): string
	return `${NumberFormat.Compact(value)}`
end

function Hud.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local player = Players.LocalPlayer
	local dataController = context.Controllers.DataController
	local trove = Trove.new()
	local isDestroyed = false
	ViewportScale.Bind(gui, trove)

	local scaleInstance = gui:FindFirstChild(ScaleConfig.ScaleName, true)
	local screenScale: UIScale? = if scaleInstance and scaleInstance:IsA("UIScale")
		then scaleInstance
		else nil

	local function textWidth(label: TextLabel): number
		local scale = if screenScale and screenScale.Scale > 0 then screenScale.Scale else 1
		return label.TextBounds.X / scale
	end

	local function readAttribute(attribute: string): number
		local value = player:GetAttribute(attribute)
		return if type(value) == "number" then value else 0
	end

	local function readNumber(value: any): number
		return if type(value) == "number" then value else 0
	end

	local function findLabel(labelName: string): TextLabel?
		local found = gui:FindFirstChild(labelName, true)
		if not found or not found:IsA("TextLabel") then
			warn(`[Hud] Missing TextLabel "{labelName}" in {gui:GetFullName()}`)
			return nil
		end
		return found
	end

	local function setText(label: TextLabel, text: string)
		label.Text = text
		local shadow = if label.Parent
			then label.Parent:FindFirstChild(label.Name .. HudConfig.ShadowSuffix)
			else nil
		if shadow and shadow:IsA("TextLabel") then
			shadow.Text = text
		end
	end

	local function bind(labelName: string, attribute: string, format: (number) -> string)
		local label = findLabel(labelName)
		if not label then
			return
		end
		local function refresh()
			setText(label, format(readAttribute(attribute)))
		end
		trove:Connect(player:GetAttributeChangedSignal(attribute), refresh)
		refresh()
	end

	local function bindData(labelName: string, path: { string }, format: (number) -> string)
		local label = findLabel(labelName)
		if not label then
			return
		end
		local ticker = NumberTicker.new(format, function(text: string)
			setText(label, text)
		end)
		trove:Add(ticker, "Destroy")
		local hasValue = false
		trove:Add(dataController:Observe(path, function(value: any)
			if hasValue then
				ticker:Set(readNumber(value))
			else
				hasValue = value ~= nil
				ticker:Snap(readNumber(value))
			end
		end))
	end

	local function bindMoney()
		local label = findLabel("Money")
		if not label then
			return
		end
		local template = label:FindFirstChild(DELTA_TEMPLATE)
		if template and not template:IsA("TextLabel") then
			template = nil
		end
		if not template then
			warn(`[Hud] Missing TextLabel "{DELTA_TEMPLATE}" under Money; wallet changes will not animate`)
		end

		local lastTarget = readNumber(dataController:Get({ "Cash" }))
		local ticker = NumberTicker.new(formatMoney, function(text: string)
			setText(label, text)
		end, lastTarget)
		trove:Add(ticker, "Destroy")

		local function playDelta(delta: number)
			local source = template :: TextLabel
			local floating = source:Clone()
			floating.Text = if delta > 0 then `+{formatMoney(delta)}` else `-{formatMoney(-delta)}`
			local style = if delta > 0 then EconomyConfig.MoneyGainStyle else EconomyConfig.MoneyLossStyle
			floating.TextColor3 = Color3.new(1, 1, 1)
			local gradient = floating:FindFirstChildWhichIsA("UIGradient")
			if gradient then
				gradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, style.DarkColor),
					ColorSequenceKeypoint.new(0.5, style.LightColor),
					ColorSequenceKeypoint.new(1, style.DarkColor),
				})
			end
			local floatingStroke = floating:FindFirstChildWhichIsA("UIStroke")
			if floatingStroke then
				floatingStroke.Color = style.StrokeColor
			end
			local startX = textWidth(label) + EconomyConfig.MoneyDeltaGapPixels
			floating.Position = UDim2.new(0, startX, 0, 0)
			floating.Visible = true
			floating.Parent = label

			local info = TweenInfo.new(
				EconomyConfig.MoneyDeltaTravelSeconds,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In
			)
			local slide = TweenService:Create(floating, info, {
				Position = UDim2.new(0, textWidth(label) / 2, 0, 0),
				TextTransparency = 1,
			})
			local stroke = floating:FindFirstChildWhichIsA("UIStroke")
			if stroke then
				TweenService:Create(stroke, info, { Transparency = 1 }):Play()
			end
			slide.Completed:Once(function()
				floating:Destroy()
				if not isDestroyed then
					ticker:Set(lastTarget)
				end
			end)
			slide:Play()
		end

		trove:Add(dataController:Observe({ "Cash" }, function(value: any)
			local target = readNumber(value)
			local delta = target - lastTarget
			lastTarget = target
			if delta == 0 then
				return
			end
			if template then
				playDelta(delta)
			else
				ticker:Set(target)
			end
		end))
	end

	local function trackBackdrop(labelName: string, extraPadding: number)
		local label = findLabel(labelName)
		local row = if label then label.Parent else nil
		local backdrop = if row then row:FindFirstChild(HudConfig.BackdropName) else nil
		if not label or not backdrop or not backdrop:IsA("Frame") then
			return
		end
		local function resize()
			local bleed = HudConfig.BackdropScreenBleedPixels
			local width = math.max(
				HudConfig.BackdropMinWidthPixels + bleed,
				bleed
					+ label.Position.X.Offset
					+ textWidth(label)
					+ HudConfig.BackdropPaddingPixels
					+ extraPadding
			)
			backdrop.Position = UDim2.new(0, -bleed, 0, 0)
			backdrop.Size = UDim2.new(0, width, 1, 0)
		end
		trove:Connect(label:GetPropertyChangedSignal("TextBounds"), resize)
		resize()
	end

	local function bindInvite()
		local label = findLabel("FriendBoost")
		local found = if label and label.Parent
			then label.Parent:FindFirstChild(HudConfig.InviteButtonName)
			else nil
		if not label or not found or not found:IsA("GuiButton") then
			warn(
				`[Hud] Missing GuiButton "{HudConfig.InviteButtonName}" next to FriendBoost in {gui:GetFullName()}`
			)
			return
		end
		local button = found
		local function place()
			local x = label.Position.X.Offset + textWidth(label) + HudConfig.InviteGapPixels
			local anchor = button.AnchorPoint.X
			button.Position =
				UDim2.new(button.Size.X.Scale * anchor, x + button.Size.X.Offset * anchor, 0.5, 0)
		end
		trove:Connect(label:GetPropertyChangedSignal("TextBounds"), place)
		place()
		trove:Connect(button.Activated, function()
			local ok, canInvite = pcall(function()
				return SocialService:CanSendGameInviteAsync(player)
			end)
			if ok and canInvite then
				pcall(function()
					SocialService:PromptGameInvite(player)
				end)
			end
		end)
	end

	local function bindTouchDock()
		local container = gui:FindFirstChild(HudConfig.ContainerName)
		if not container or not container:IsA("GuiObject") then
			warn(
				`[Hud] Missing Frame "{HudConfig.ContainerName}" in {gui:GetFullName()}; touch dock disabled`
			)
			return
		end
		local basePosition = container.Position
		local baseAnchor = container.AnchorPoint
		local isTouch = false
		local dock: GuiObject? = nil

		local function apply()
			if isTouch and dock and dock.Parent then
				local top = dock.AbsolutePosition.Y + dock.AbsoluteSize.Y - gui.AbsolutePosition.Y
				container.AnchorPoint = Vector2.zero
				container.Position = UDim2.new(
					basePosition.X.Scale,
					basePosition.X.Offset,
					0,
					top + HudConfig.TouchDockGapPixels
				)
			else
				container.AnchorPoint = baseAnchor
				container.Position = basePosition
			end
		end

		trove:AddPromise(WaitFor.Child(Players.LocalPlayer, "PlayerGui", 15)
			:andThen(function(playerGui: Instance)
				return WaitFor.Child(playerGui, HudConfig.TouchDockScreenName, 15)
			end)
			:andThen(function(dockGui: Instance)
				return WaitFor.Child(dockGui, HudConfig.TouchDockFrameName, 15)
			end)
			:andThen(function(frame: Instance)
				if not frame:IsA("GuiObject") then
					return
				end
				dock = frame
				trove:Connect(frame:GetPropertyChangedSignal("AbsolutePosition"), apply)
				trove:Connect(frame:GetPropertyChangedSignal("AbsoluteSize"), apply)
				apply()
			end)
			:catch(function(problem: any)
				warn(
					`[Hud] Touch dock disabled; needs PlayerGui.{HudConfig.TouchDockScreenName}.{HudConfig.TouchDockFrameName}: {tostring(
						problem
					)}`
				)
			end))

		trove:Add(Input.PreferredInput.observe(function(preferred: Enum.PreferredInput)
			isTouch = preferred == Enum.PreferredInput.Touch
			apply()
			return nil
		end))
		trove:Connect(gui:GetPropertyChangedSignal("AbsolutePosition"), apply)
	end

	bindMoney()
	bindTouchDock()
	bindData("Strength", { "Strength" }, function(value: number): string
		return `{NumberFormat.Compact(value)} {TrainingConfig.StrengthUnit}`
	end)
	bind("FriendBoost", "FriendBoost", function(value: number): string
		return `+{NumberFormat.Compact(value)}% [Friends]`
	end)
	bindInvite()
	trackBackdrop("Strength", 0)
	trackBackdrop("Money", 0)
	trackBackdrop("FriendBoost", HudConfig.InviteExtraPaddingPixels)

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
			isDestroyed = true
			trove:Destroy()
		end,
	}
end

return Hud
