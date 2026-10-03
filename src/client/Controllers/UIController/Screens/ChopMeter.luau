--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ChopZones = require(ReplicatedStorage.ChopZones)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopStyleConfig = require(ReplicatedStorage.Config.ChopStyleConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Types = require(script.Parent.Parent.Types)

local ChopMeter = {}

local HEALTH_TWEEN_SECONDS = 0.2

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

type Stop = { Level: number, Color: Color3 }

local MIN_PIECE = 0.0001

local function buildRamp(center: number, strengthRatio: number): ColorSequence
	local bands = ChopZones.Bands(center, strengthRatio)
	local stops: { Stop } = {}
	local function addPiece(low: number, high: number, quality: number)
		if high - low > MIN_PIECE then
			table.insert(stops, { Level = (low + high) / 2, Color = qualityColor(quality) })
		end
	end
	for index, band in bands do
		local inner = bands[index - 1]
		if inner then
			addPiece(band.Low, inner.Low, band.Quality)
			addPiece(inner.High, band.High, band.Quality)
		else
			addPiece(band.Low, band.High, band.Quality)
		end
	end
	local outer = bands[#bands]
	addPiece(0, outer.Low, ChopQuality.Bad)
	addPiece(outer.High, 1, ChopQuality.Bad)
	table.sort(stops, function(first: Stop, second: Stop)
		return first.Level < second.Level
	end)
	local spaced: { Stop } = {}
	for _, stop in stops do
		local previous = spaced[#spaced]
		if not previous or stop.Level - previous.Level > MIN_PIECE then
			table.insert(spaced, stop)
		end
	end
	local keypoints: { ColorSequenceKeypoint } = {}
	local last = spaced[#spaced]
	table.insert(keypoints, ColorSequenceKeypoint.new(0, last.Color))
	for index = #spaced, 1, -1 do
		local stop = spaced[index]
		table.insert(keypoints, ColorSequenceKeypoint.new(1 - stop.Level, stop.Color))
	end
	local first = spaced[1]
	table.insert(keypoints, ColorSequenceKeypoint.new(1, first.Color))
	return ColorSequence.new(keypoints)
end

function ChopMeter.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local openTrove = Trove.new()
	ViewportScale.Bind(gui, trove)
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

	local cursor = findFrame(gui, "Cursor")
	local healthBar = findFrame(gui, "HealthBar")
	local healthFillInstance = if healthBar then healthBar:FindFirstChild("HealthFill") else nil
	local healthFill: Frame? = if healthFillInstance and healthFillInstance:IsA("Frame")
		then healthFillInstance
		else nil
	if healthBar and not healthFill then
		warn(`[ChopMeter] Missing Frame "HealthFill" in {healthBar:GetFullName()}`)
	end
	local leaveInstance = gui:FindFirstChild("LeaveButton", true)
	local leaveButton: GuiButton? = if leaveInstance and leaveInstance:IsA("GuiButton")
		then leaveInstance
		else nil
	if not leaveButton then
		warn(`[ChopMeter] Missing GuiButton "LeaveButton" in {gui:GetFullName()}`)
	end

	local crackColor = ColorSequence.new(qualityColor(ChopQuality.Crack))
	local activeRamp = crackColor
	local activeCanBreak = true
	local healthTween: Tween? = nil

	local function applyRamp()
		activeCanBreak = if chopController then chopController:CanBreakRock() else true
		activeRamp = if activeCanBreak
			then buildRamp(
				if chopController then chopController:GetZoneCenter() else 0.5,
				if chopController then chopController:GetStrengthRatio() else 1
			)
			else crackColor
		if fill then
			fill.Size = UDim2.new(1, 0, 1, 0)
			fill.Visible = true
		end
		if rampGradient then
			rampGradient.Color = activeRamp
		end
	end

	local function setHealth(health: number, maxHealth: number, animate: boolean)
		if not healthFill then
			return
		end
		if healthTween then
			healthTween:Cancel()
			healthTween = nil
		end
		local ratio = if maxHealth > 0 then math.clamp(health / maxHealth, 0, 1) else 0
		local size = UDim2.new(ratio, 0, 1, 0)
		if animate then
			local tween =
				TweenService:Create(healthFill, TweenInfo.new(HEALTH_TWEEN_SECONDS), { Size = size })
			healthTween = tween
			tween:Play()
		else
			healthFill.Size = size
		end
	end

	local function setLevel(level: number)
		if not cursor then
			return
		end
		cursor.Position = UDim2.new(0.5, 0, 1 - math.clamp(level, 0, 1), 0)
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
		trove:Add(chopController.HealthChanged:Connect(function(health: number, maxHealth: number)
			setHealth(health, maxHealth, true)
		end))
		trove:Add(chopController.RoundStarted:Connect(function()
			applyRamp()
			resetResult()
			setLevel(0)
		end))
		if leaveButton then
			trove:Add(leaveButton.Activated:Connect(function()
				chopController:Leave()
			end))
		end
	else
		warn("[ChopMeter] ChopController is not registered; the meter will not animate")
	end

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			applyRamp()
			resetResult()
			setLevel(0)
			if chopController then
				setHealth(chopController:GetHealth(), chopController:GetMaxHealth(), false)
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
