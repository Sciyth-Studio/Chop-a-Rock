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
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Input = require(ReplicatedStorage.Packages.Input)
local Trove = require(ReplicatedStorage.Packages.Trove)
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
		setText(label, format(0))
		trove:Add(dataController:Observe(path, function(value: any)
			setText(label, format(readNumber(value)))
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
		setText(label, formatMoney(lastTarget))

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
					setText(label, formatMoney(lastTarget))
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
				setText(label, formatMoney(target))
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

	local function bindTouchLift()
		local container = gui:FindFirstChild(HudConfig.ContainerName)
		if not container or not container:IsA("GuiObject") then
			warn(
				`[Hud] Missing Frame "{HudConfig.ContainerName}" in {gui:GetFullName()}; touch lift disabled`
			)
			return
		end
		local basePosition = container.Position
		local isTouch = false

		local function apply()
			local lift = 0
			local camera = workspace.CurrentCamera
			if isTouch and camera then
				local viewport = camera.ViewportSize
				local shortSide = math.min(viewport.X, viewport.Y)
				lift = if shortSide <= HudConfig.TouchSmallScreenMaxShortSidePixels
					then HudConfig.TouchLiftSmallPixels
					else HudConfig.TouchLiftLargePixels
			end
			container.Position = basePosition - UDim2.fromOffset(0, lift)
		end

		local function watchCamera()
			local camera = workspace.CurrentCamera
			if camera then
				trove:Connect(camera:GetPropertyChangedSignal("ViewportSize"), apply)
			end
			apply()
		end

		trove:Add(Input.PreferredInput.observe(function(preferred: Enum.PreferredInput)
			isTouch = preferred == Enum.PreferredInput.Touch
			apply()
			return nil
		end))
		trove:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
		watchCamera()
	end

	bindMoney()
	bindTouchLift()
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
