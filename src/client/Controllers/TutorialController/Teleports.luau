--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportConfig = require(ReplicatedStorage.Config.TeleportConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local Targets = require(script.Parent.Targets)

export type Hint = {
	Button: GuiObject,
	Text: string,
}

local Teleports = {}

local function destinationFor(step: number): string?
	if Tutorial.IsTraining(step) or step == Tutorial.Crack or step == Tutorial.Collect then
		return "Base"
	elseif Tutorial.IsChopping(step) then
		return "Rocks"
	elseif step == Tutorial.BuyAura then
		return "Aura"
	elseif step == Tutorial.BuyGeode then
		return "Geode"
	end
	return nil
end

local function landingFor(id: string): CFrame?
	if id == "Base" then
		local plot = Targets.OwnPlot()
		local spawn = if plot then plot:FindFirstChild(TeleportConfig.BaseSpawnName, true) else nil
		return if spawn and spawn:IsA("BasePart") then spawn.CFrame else nil
	end
	for _, destination in TeleportConfig.Destinations do
		if destination.Id == id then
			local folder = workspace:FindFirstChild(TeleportConfig.PointsFolderName)
			local marker = if folder then folder:FindFirstChild(destination.Marker) else nil
			return if marker and marker:IsA("BasePart") then marker.CFrame else nil
		end
	end
	return nil
end

local function isBehind(position: Vector3, landing: CFrame): boolean
	return (position - landing.Position):Dot(landing.LookVector) < 0
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
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

local function barButton(name: string): GuiObject?
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local bar = if playerGui then playerGui:FindFirstChild(TutorialConfig.TeleportBarScreen) else nil
	local button = if bar then bar:FindFirstChild(name, true) else nil
	return if button and button:IsA("GuiObject") and isShown(button) then button else nil
end

local function shopsFanOpen(): boolean
	local fanSettings = TeleportConfig.ShopFan
	local shops = barButton(fanSettings.Button .. TeleportConfig.ButtonSuffix)
	local fan = if shops then shops:FindFirstChild(fanSettings.FanName) else nil
	return fan ~= nil and fan:IsA("GuiObject") and fan.Visible
end

function Teleports.For(step: number, target: Targets.Target?, verb: string): Hint?
	local id = destinationFor(step)
	return if id then Teleports.ForDestination(id, target, verb) else nil
end

function Teleports.ForDestination(id: string?, target: Targets.Target?, verb: string): Hint?
	local from = Targets.RootPosition()
	local landing = if id then landingFor(id) else nil
	if not id or not target or not from or not landing then
		return nil
	end
	local saved = flatDistance(from, target.Position) - flatDistance(landing.Position, target.Position)
	local isOutsideZone = id == TutorialConfig.ZoneTeleport and isBehind(from, landing)
	if saved < TutorialConfig.TeleportSavingStuds and not isOutsideZone then
		return nil
	end
	local fanSettings = TeleportConfig.ShopFan
	if table.find(fanSettings.Options, id) then
		if shopsFanOpen() then
			local option = barButton(id .. fanSettings.OptionSuffix)
			return if option then { Button = option, Text = `{verb} {id} to teleport there!` } else nil
		end
		local shops = barButton(fanSettings.Button .. TeleportConfig.ButtonSuffix)
		return if shops then { Button = shops, Text = `{verb} Shops at the top!` } else nil
	end
	local button = barButton(id .. TeleportConfig.ButtonSuffix)
	return if button then { Button = button, Text = `{verb} {id} to teleport there!` } else nil
end

return Teleports
