--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopStyleConfig = require(ReplicatedStorage.Config.ChopStyleConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local ChopMeter = {}

local zoneLayout = {
	{ Name = "MidZone", Threshold = ChopConfig.MidThreshold, Quality = ChopQuality.Mid },
	{ Name = "GoodZone", Threshold = ChopConfig.GoodThreshold, Quality = ChopQuality.Good },
	{ Name = "GreatZone", Threshold = ChopConfig.GreatThreshold, Quality = ChopQuality.Great },
	{ Name = "PerfectZone", Threshold = ChopConfig.PerfectThreshold, Quality = ChopQuality.Perfect },
}

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

function ChopMeter.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local openTrove = Trove.new()
	local chopController = context.Controllers.ChopController

	local bar = findFrame(gui, "Bar")
	local cursor = findFrame(gui, "Cursor")
	local resultLabel = findLabel(gui, "ResultLabel")
	local rainbow = if resultLabel then resultLabel:FindFirstChild("RainbowGradient") else nil

	if bar then
		bar.BackgroundColor3 = ChopStyleConfig.Qualities[ChopQuality.Bad].Color
	end
	for _, zone in zoneLayout do
		local frame = findFrame(gui, zone.Name)
		if frame then
			frame.Size = UDim2.new(1, 0, 1 - zone.Threshold, 0)
			frame.BackgroundColor3 = ChopStyleConfig.Qualities[zone.Quality].Color
		end
	end

	local function resetResult()
		if resultLabel then
			resultLabel.Text = ""
		end
		if rainbow and rainbow:IsA("UIGradient") then
			rainbow.Enabled = false
		end
	end

	local function showResult(quality: number)
		if not resultLabel then
			return
		end
		local style = ChopStyleConfig.Qualities[quality] or ChopStyleConfig.Fallback
		resultLabel.Text = style.DisplayText
		resultLabel.TextColor3 = if style.IsRainbow then Color3.new(1, 1, 1) else style.Color
		if rainbow and rainbow:IsA("UIGradient") then
			rainbow.Enabled = style.IsRainbow
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
			if chopController and cursor then
				openTrove:Add(RunService.RenderStepped:Connect(function()
					cursor.Position = UDim2.new(0.5, 0, 1 - chopController:GetCursorPosition(), 0)
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
