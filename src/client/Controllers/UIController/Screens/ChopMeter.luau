--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopStyleConfig = require(ReplicatedStorage.Config.ChopStyleConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
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
	local ramp = findFrame(gui, "Ramp")
	local rampGradientInstance = if ramp then ramp:FindFirstChild("RampGradient") else nil
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

	local function applyStyleGradient(gradient: UIGradient, style: ChopStyleConfig.QualityStyle)
		if style.IsRainbow then
			gradient.Color = rainbowColor
			gradient.Rotation = rainbowRotation
			return
		end
		local dark = style.Color:Lerp(Color3.new(0, 0, 0), ChopStyleConfig.TextDarkenAmount)
		local light = style.Color:Lerp(Color3.new(1, 1, 1), ChopStyleConfig.TextLightenAmount)
		gradient.Rotation = ChopStyleConfig.TextGradientRotation
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, dark),
			ColorSequenceKeypoint.new(0.5, light),
			ColorSequenceKeypoint.new(1, dark),
		})
	end

	local function applyRamp(canBreak: boolean)
		if rampGradient then
			rampGradient.Color = if canBreak then rampColor else crackColor
		end
	end

	local function setLevel(level: number)
		if not fill or not ramp then
			return
		end
		local clamped = math.clamp(level, 0, 1)
		fill.Size = UDim2.new(1, 0, clamped, 0)
		ramp.Size = UDim2.new(1, 0, 1 / math.max(clamped, MIN_LEVEL), 0)
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
		resultLabel.TextColor3 = Color3.new(1, 1, 1)
		if resultStroke then
			resultStroke.Color = style.Color:Lerp(Color3.new(0, 0, 0), ChopStyleConfig.StrokeDarkenAmount)
		end
		if resultGradient then
			resultGradient.Enabled = true
			applyStyleGradient(resultGradient, style)
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
