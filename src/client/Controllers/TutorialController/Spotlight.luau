--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

export type State = {
	Spotlight: any,
	Target: GuiObject?,
}

local Spotlight = {}

local zoneName = "TutorialGoodZone"

function Spotlight.new(): State?
	local module = ReplicatedStorage:FindFirstChild("SpotlightUI")
	if not module or not module:IsA("ModuleScript") then
		warn("[TutorialController] ReplicatedStorage.SpotlightUI is missing; UI spotlights are off")
		return nil
	end
	local ok, result = pcall(function()
		local SpotlightUI = (require :: any)(module)
		local spotlight = SpotlightUI.new():SetShape(TutorialConfig.SpotlightShape)
		spotlight.gui.DisplayOrder = TutorialConfig.SpotlightDisplayOrder
		return spotlight
	end)
	if not ok then
		warn(`[TutorialController] SpotlightUI failed to start: {result}`)
		return nil
	end
	return { Spotlight = result, Target = nil }
end

local function isShown(button: GuiObject): boolean
	local screen = button:FindFirstAncestorOfClass("ScreenGui")
	if not screen or not screen.Enabled then
		return false
	end
	local current: Instance? = button
	while current and current ~= screen do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		current = current.Parent
	end
	return button.AbsoluteSize.X > 1 and button.AbsoluteSize.Y > 1
end

local function find(screenName: string, path: { string }): GuiObject?
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local current: Instance? = if playerGui then playerGui:FindFirstChild(screenName) else nil
	for _, name in path do
		current = if current then current:FindFirstChild(name, true) else nil
	end
	return if current and current:IsA("GuiObject") then current else nil
end

local function goodZone(chopController: any): GuiObject?
	local bar = find("ChopMeter", { "Bar" })
	if not bar then
		return nil
	end
	local zone = bar:FindFirstChild(zoneName)
	if not zone or not zone:IsA("Frame") then
		local created = Instance.new("Frame")
		created.Name = zoneName
		created.BackgroundTransparency = 1
		created.Active = false
		created.Parent = bar
		zone = created
	end
	local frame = zone :: Frame
	local good: ChopZones.Band? = nil
	for _, band in ChopZones.Bands(chopController:GetZoneCenter(), chopController:GetStrengthRatio()) do
		if band.Quality == ChopQuality.Good then
			good = band
		end
	end
	if not good then
		return nil
	end
	frame.Position = UDim2.fromScale(0, 1 - good.High)
	frame.Size = UDim2.fromScale(1, good.High - good.Low)
	return frame
end

function Spotlight.TargetFor(step: number, data: any, chopController: any): GuiObject?
	local button: GuiObject? = nil
	if chopController:IsMinigameActive() and Tutorial.ForcesPerfect(step, data) then
		button = goodZone(chopController)
	elseif step == Tutorial.BuyArms then
		button = find("Shop", { "Tier2", "BuyButton" })
	elseif step == Tutorial.BuyGeode then
		button = find("GeodeStand", { "BuyOne" })
	end
	return if button and isShown(button) then button else nil
end

function Spotlight.Update(state: State, target: GuiObject?)
	if state.Target == target then
		return
	end
	state.Target = target
	if target then
		state.Spotlight
			:FocusUI(target, TutorialConfig.SpotlightPadding)
			:Show()
			:EnablePulse(TutorialConfig.SpotlightPulse)
	else
		state.Spotlight:Hide()
	end
end

function Spotlight.Destroy(state: State)
	state.Spotlight:Destroy()
	local bar = find("ChopMeter", { "Bar" })
	local zone = if bar then bar:FindFirstChild(zoneName) else nil
	if zone then
		zone:Destroy()
	end
end

return Spotlight
