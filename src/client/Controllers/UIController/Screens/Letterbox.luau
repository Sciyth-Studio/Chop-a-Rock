--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Types = require(script.Parent.Parent.Types)

type Bar = { Frame: Frame, Size: UDim2 }

local Letterbox = {}

local BAR_NAMES = { "TopBar", "BottomBar" }

local function scaledHeight(size: UDim2, scale: number): UDim2
	return UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale * scale, math.floor(size.Y.Offset * scale))
end

function Letterbox.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local bars: { Bar } = {}
	for _, name in BAR_NAMES do
		local found = gui:FindFirstChild(name, true)
		if found and found:IsA("Frame") then
			table.insert(bars, { Frame = found, Size = found.Size })
			found.Size = scaledHeight(found.Size, 0)
		else
			warn(`[Letterbox] Missing Frame "{name}" in {gui:GetFullName()}`)
		end
	end

	local closeThread: thread? = nil

	local function tweenBars(scale: number, seconds: number)
		local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for _, bar in bars do
			TweenService:Create(bar.Frame, info, { Size = scaledHeight(bar.Size, scale) }):Play()
		end
	end

	local function cancelClose()
		local thread = closeThread
		if thread then
			closeThread = nil
			task.cancel(thread)
		end
	end

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			cancelClose()
			gui.Enabled = true
			tweenBars(1, MasterChopConfig.LetterboxInSeconds)
		end,
		Close = function(_self: Types.Screen)
			cancelClose()
			tweenBars(0, MasterChopConfig.LetterboxOutSeconds)
			closeThread = task.delay(MasterChopConfig.LetterboxOutSeconds, function()
				closeThread = nil
				gui.Enabled = false
			end)
		end,
		Destroy = function(_self: Types.Screen)
			cancelClose()
		end,
	}
end

return Letterbox
