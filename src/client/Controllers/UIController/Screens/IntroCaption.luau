--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local IntroConfig = require(ReplicatedStorage.Config.IntroConfig)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local IntroCaption = {}

function IntroCaption.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local caption = gui:FindFirstChild("Caption", true)
	local shadow = gui:FindFirstChild("Caption" .. HudConfig.ShadowSuffix, true)
	local popScale = gui:FindFirstChild("PopScale", true)
	if not (caption and caption:IsA("TextLabel")) then
		warn(`[IntroCaption] Missing Caption label in {gui:GetFullName()}`)
		caption = nil
	end
	if not (shadow and shadow:IsA("TextLabel")) then
		shadow = nil
	end
	if not (popScale and popScale:IsA("UIScale")) then
		popScale = nil
	end

	local function show(text: string?, style: string?)
		for _, label in { caption, shadow } do
			if label and label:IsA("TextLabel") then
				label.Visible = text ~= nil
				label.Text = text or ""
			end
		end
		if text and style and caption and caption:IsA("TextLabel") then
			Typography.ApplyTextStyle(caption, style)
		end
		if text and popScale and popScale:IsA("UIScale") then
			popScale.Scale = 0.6
			TweenService:Create(
				popScale,
				TweenInfo.new(IntroConfig.CaptionPopSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
		end
	end

	show(nil, nil)
	local intro = context.Controllers.IntroController
	if intro and intro.CaptionChanged then
		trove:Connect(intro.CaptionChanged, show)
	end

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
			show(nil, nil)
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return IntroCaption
