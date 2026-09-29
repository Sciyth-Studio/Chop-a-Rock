--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopStyleConfig = require(ReplicatedStorage.Config.ChopStyleConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local Types = require(script.Parent.Parent.Types)

local ChopMeter = {}

local MIN_LEVEL = 0.001

local function findFrame(root: Instance, name: string): Frame?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA("Frame") then
		return found
	end
	warn(`[ChopMeter] Missing Frame "{name}" in {root:GetFullName()}`)
	return nil
end

local function findLabel(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA("TextLabel") then
		return found
	end
	warn(`[ChopMeter] Missing TextLabel "{name}" in {root:GetFullName()}`)
	return nil
end

local function qualityColor(quality: number): Color3
	return ChopStyleConfig.Qualities[quality].Color
end

local function sampleSequence(sequence: ColorSequence, t: number): Color3
	local keypoints = sequence.Keypoints
	local clamped = math.clamp(t, 0, 1)
	for index = 1, #keypoints - 1 do
		local first = keypoints[index]
		local second = keypoints[index + 1]
		if clamped <= second.Time then
			local span = second.Time - first.Time
			local alpha = if span > 0 then (clamped - first.Time) / span else 0
			return first.Value:Lerp(second.Value, alpha)
		end
	end
	return keypoints[#keypoints].Value
end

local function buildRamp(): ColorSequence
	local stops = {
		{ Level = 0, Color = qualityColor(ChopQuality.Bad) },
		{ Level = ChopConfig.MidThreshold / 2, Color = qualityColor(ChopQuality.Bad) },
		{
			Level = (ChopConfig.MidThreshold + ChopConfig.GoodThreshold) / 2,
			Color = qualityColor(ChopQuality.Mid),
		},
		{
			Level = (ChopConfig.GoodThreshold + ChopConfig.GreatThreshold) / 2,
			Color = qualityColor(ChopQuality.Good),
		},
		{
			Level = (ChopConfig.GreatThreshold + ChopConfig.PerfectThreshold) / 2,
			Color = qualityColor(ChopQuality.Great),
		},
		{
			Level = (ChopConfig.PerfectThreshold + 1) / 2,
			Color = qualityColor(ChopQuality.Perfect),
		},
		{ Level = 1, Color = qualityColor(ChopQuality.Perfect) },
	}
	local keypoints: { ColorSequenceKeypoint } = {}
	for index = #stops, 1, -1 do
		local stop = stops[index]
		table.insert(keypoints, ColorSequenceKeypoint.new(1 - stop.Level, stop.Color))
	end
	return ColorSequence.new(keypoints)
end

function ChopMeter.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local openTrove = Trove.new()
	local chopController = context.Controllers.ChopController

	local fill = findFrame(gui, "Fill")
	local rampGradientInstance = if fill then fill:FindFirstChild("RampGradient") else nil
	local rampGradient: UIGradient? = if rampGradientInstance and rampGradientInstance:IsA("UIGradient")
		then rampGradientInstance
		else nil
	local resultLabel = findLabel(gui, "ResultLabel")
	local resultStroke = if resultLabel then resultLabel:FindFirstChildWhichIsA("UIStroke") else nil
	local gradientInstance = if resultLabel then resultLabel:FindFirstChild("RainbowGradient") else nil
	local resultGradient: UIGradient? = if gradientInstance and gradientInstance:IsA("UIGradient")
		then gradientInstance
		else nil
	local rainbowColor = if resultGradient
		then resultGradient.Color
		else ColorSequence.new(Color3.new(1, 1, 1))
	local rainbowRotation = if resultGradient then resultGradient.Rotation else 0

	local rampColor = buildRamp()
	local crackColor = ColorSequence.new(qualityColor(ChopQuality.Crack))

	local activeRamp = rampColor

	local function applyRamp(canBreak: boolean)
		activeRamp = if canBreak then rampColor else crackColor
	end

	local function updateRamp(level: number)
		if not rampGradient then
			return
		end
		local keypoints: { ColorSequenceKeypoint } = {
			ColorSequenceKeypoint.new(0, sampleSequence(activeRamp, 1 - level)),
		}
		for _, keypoint in activeRamp.Keypoints do
			local position = 1 - (1 - keypoint.Time) / level
			if position > 0.001 and position < 0.999 then
				table.insert(keypoints, ColorSequenceKeypoint.new(position, keypoint.Value))
			end
		end
		table.insert(keypoints, ColorSequenceKeypoint.new(1, sampleSequence(activeRamp, 1)))
		rampGradient.Color = ColorSequence.new(keypoints)
	end

	local function setLevel(level: number)
		if not fill then
			return
		end
		local clamped = math.clamp(level, 0, 1)
		fill.Size = UDim2.new(1, 0, clamped, 0)
		fill.Visible = clamped > MIN_LEVEL
		if fill.Visible then
			updateRamp(clamped)
		end
	end

	local function resetResult()
		if resultLabel then
			resultLabel.Text = ""
		end
		if resultGradient then
			resultGradient.Enabled = false
		end
	end

	local function showResult(quality: number)
		if not resultLabel then
			return
		end
		local style = ChopStyleConfig.Qualities[quality] or ChopStyleConfig.Fallback
		resultLabel.Text = style.DisplayText
		if style.IsRainbow then
			resultLabel.TextColor3 = Color3.new(1, 1, 1)
			if resultStroke then
				resultStroke.Color = style.Color:Lerp(Color3.new(0, 0, 0), ChopStyleConfig.StrokeDarkenAmount)
			end
			if resultGradient then
				resultGradient.Enabled = true
				resultGradient.Color = rainbowColor
				resultGradient.Rotation = rainbowRotation
			end
		else
			Typography.ApplyTextStyle(resultLabel, ChopStyleConfig.ResultTextStyle)
		end
	end

	if chopController then
		trove:Add(chopController.ResultShown:Connect(showResult))
	else
		warn("[ChopMeter] ChopController is not registered; the meter will not animate")
	end

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			resetResult()
			setLevel(0)
			applyRamp(if chopController then chopController:CanBreakRock() else true)
			if chopController then
				openTrove:Add(RunService.RenderStepped:Connect(function()
					setLevel(chopController:GetCursorPosition())
				end))
			end
		end,
		Close = function(_self: Types.Screen)
			openTrove:Clean()
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			openTrove:Destroy()
			trove:Destroy()
		end,
	}
end

return ChopMeter
