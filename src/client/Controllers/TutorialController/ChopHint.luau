--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

export type State = {
	Gui: ScreenGui,
	Pointer: GuiObject,
	Pulse: UIScale?,
	Labels: { TextLabel },
	Arrows: { ImageLabel },
	Trove: TroveInstance,
	IsNow: boolean?,
	Clock: number,
}

local ChopHint = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	return if found and found:IsA(className) then found else nil
end

function ChopHint.new(): State?
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local gui = if playerGui then playerGui:FindFirstChild(TutorialConfig.ChopHintScreen) else nil
	local pointer = if gui then find(gui, "Pointer", "GuiObject") else nil
	if not gui or not gui:IsA("ScreenGui") or not pointer then
		warn(
			`[TutorialController] PlayerGui.{TutorialConfig.ChopHintScreen}.Pointer is missing; chop hint is off`
		)
		return nil
	end
	local trove = Trove.new()
	gui.ResetOnSpawn = false
	gui.Enabled = false
	Typography.Apply(gui)
	ViewportScale.Bind(gui, trove)
	local labels = {}
	for _, name in { "Label", "LabelShadow" } do
		local label = find(pointer, name, "TextLabel")
		if label then
			table.insert(labels, label)
		end
	end
	local arrow = find(pointer, "Arrow", "ImageLabel")
	return {
		Gui = gui,
		Pointer = pointer,
		Pulse = find(pointer, "Pulse", "UIScale"),
		Labels = labels,
		Arrows = if arrow then { arrow } else {},
		Trove = trove,
		IsNow = nil,
		Clock = 0,
	}
end

local function goodBand(chopController: any): ChopZones.Band?
	for _, band in ChopZones.Bands(chopController:GetZoneCenter(), chopController:GetStrengthRatio()) do
		if band.Quality == ChopQuality.Good then
			return band
		end
	end
	return nil
end

local function meterBar(): GuiObject?
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local meter = if playerGui then playerGui:FindFirstChild("ChopMeter") else nil
	local bar = if meter
			and meter:IsA("ScreenGui")
			and meter.Enabled
		then meter:FindFirstChild("Bar")
		else nil
	return if bar and bar:IsA("GuiObject") then bar else nil
end

local function setNow(state: State, isNow: boolean, key: string)
	if state.IsNow == isNow then
		return
	end
	state.IsNow = isNow
	local text = if isNow then `Now! {key}!` else `{key} here`
	for _, label in state.Labels do
		label.Text = text
		if label.Name == "Label" then
			Typography.ApplyTextStyle(
				label,
				if isNow then TutorialConfig.ChopHintNowStyle else TutorialConfig.ChopHintWaitStyle
			)
		end
	end
	for _, arrow in state.Arrows do
		arrow.ImageColor3 = if isNow then TutorialConfig.ChopHintNowColor else Color3.new(1, 1, 1)
	end
end

function ChopHint.Update(state: State, chopController: any, key: string?, dt: number)
	local bar = meterBar()
	local band = if key and bar and chopController:CanBreakRock() then goodBand(chopController) else nil
	if not key or not bar or not band or chopController:IsReleased() then
		state.Gui.Enabled = false
		state.IsNow = nil
		return
	end
	local cursor = chopController:GetCursorPosition()
	local isNow = cursor >= band.Low and cursor <= band.High
	setNow(state, isNow, key)
	local middle = 1 - (band.Low + band.High) / 2
	local top = bar.AbsolutePosition
	local size = bar.AbsoluteSize
	state.Pointer.Position =
		UDim2.fromOffset(top.X - TutorialConfig.ChopHintGapPixels, top.Y + size.Y * middle)
	state.Clock += dt
	if state.Pulse then
		state.Pulse.Scale = if isNow
			then TutorialConfig.ChopHintNowScale
			else 1 + math.sin(state.Clock * TutorialConfig.ChopHintBobSpeed) * TutorialConfig.ChopHintBobScale
	end
	state.Gui.Enabled = true
end

function ChopHint.Hide(state: State)
	state.Gui.Enabled = false
	state.IsNow = nil
end

function ChopHint.Destroy(state: State)
	ChopHint.Hide(state)
	state.Trove:Destroy()
end

return ChopHint
