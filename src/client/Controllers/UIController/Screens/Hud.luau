--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local EconomyConfig = require(ReplicatedStorage.Config.EconomyConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local DELTA_TEMPLATE = "MoneyDelta"

local Hud = {}

local function formatMoney(value: number): string
	return `${NumberFormat.Compact(value)}`
end

function Hud.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local player = Players.LocalPlayer
	local trove = Trove.new()
	local isDestroyed = false
	ViewportScale.Bind(gui, trove)

	local function readAttribute(attribute: string): number
		local value = player:GetAttribute(attribute)
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

		local lastTarget = readAttribute("Cash")
		setText(label, formatMoney(lastTarget))

		local function playDelta(delta: number, target: number)
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
			local startX = label.TextBounds.X + EconomyConfig.MoneyDeltaGapPixels
			floating.Position = UDim2.new(0, startX, 0, 0)
			floating.Visible = true
			floating.Parent = label

			local info = TweenInfo.new(
				EconomyConfig.MoneyDeltaTravelSeconds,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.In
			)
			local slide = TweenService:Create(floating, info, {
				Position = UDim2.new(0, label.TextBounds.X / 2, 0, 0),
				TextTransparency = 1,
			})
			local stroke = floating:FindFirstChildWhichIsA("UIStroke")
			if stroke then
				TweenService:Create(stroke, info, { Transparency = 1 }):Play()
			end
			slide.Completed:Once(function()
				floating:Destroy()
				if not isDestroyed then
					setText(label, formatMoney(target))
				end
			end)
			slide:Play()
		end

		trove:Connect(player:GetAttributeChangedSignal("Cash"), function()
			local target = readAttribute("Cash")
			local delta = target - lastTarget
			lastTarget = target
			if delta == 0 then
				return
			end
			if template then
				playDelta(delta, target)
			else
				setText(label, formatMoney(target))
			end
		end)
	end

	local function trackBackdrop(labelName: string)
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
				bleed + label.Position.X.Offset + label.TextBounds.X + HudConfig.BackdropPaddingPixels
			)
			backdrop.Position = UDim2.new(0, -bleed, 0, 0)
			backdrop.Size = UDim2.new(0, width, 1, 0)
		end
		trove:Connect(label:GetPropertyChangedSignal("TextBounds"), resize)
		resize()
	end

	bindMoney()
	bind("Strength", "Strength", function(value: number): string
		return `{NumberFormat.Compact(value)} {TrainingConfig.StrengthUnit}`
	end)
	bind("FriendBoost", "FriendBoost", function(value: number): string
		return `+{NumberFormat.Compact(value)}% [Friends]`
	end)
	trackBackdrop("Strength")
	trackBackdrop("Money")
	trackBackdrop("FriendBoost")

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
