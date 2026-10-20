--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIFeelConfig = require(ReplicatedStorage.Config.UIFeelConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Typography = require(ReplicatedStorage.Utils.Typography)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WaitFor = require(ReplicatedStorage.Packages.WaitFor)
local ButtonFeel = require(script.ButtonFeel)
local PanelPop = require(script.PanelPop)
local Types = require(script.Types)

local modules: { [string]: Types.ScreenModule } = {
	Hud = require(script.Screens.Hud),
	MenuButtons = require(script.Screens.MenuButtons),
	ChopMeter = require(script.Screens.ChopMeter),
	TrainingHint = require(script.Screens.TrainingHint),
	TrainingMinigame = require(script.Screens.TrainingMinigame),
	Shop = require(script.Screens.Shop),
	CannonShop = require(script.Screens.CannonShop),
	GeodeStand = require(script.Screens.GeodeStand),
	Index = require(script.Screens.Index),
	Roks = require(script.Screens.Roks),
	SellShop = require(script.Screens.SellShop),
	RobuxShop = require(script.Screens.RobuxShop),
	HatchReveal = require(script.Screens.HatchReveal),
	Rebirth = require(script.Screens.Rebirth),
	Notifications = require(script.Screens.Notifications),
	Letterbox = require(script.Screens.Letterbox),
	Settings = require(script.Screens.Settings),
	AdminPanel = require(script.Screens.AdminPanel),
	AdminCommandBar = require(script.Screens.AdminCommandBar),
	HotStreakFx = require(script.Screens.HotStreakFx),
	HotStreakBar = require(script.Screens.HotStreakBar),
	DiamondRockPill = require(script.Screens.DiamondRockPill),
	WeatherPill = require(script.Screens.WeatherPill),
	TeleportBar = require(script.Screens.TeleportBar),
	TutorialHud = require(script.Screens.TutorialHud),
}

local UIController = { Name = "UIController" }
local registry: { [string]: any } = {}
local screens: { [string]: Types.Screen } = {}
local guis: { [string]: ScreenGui } = {}
local opened: { [string]: boolean } = {}
local pending: { any } = {}
local feelTrove = Trove.new()
local feel: ButtonFeel.ButtonFeel? = nil
local pop = PanelPop.new()
local destroyed = false

local function findPopScale(name: string): UIScale?
	local gui = guis[name]
	return if gui and gui.Enabled then pop.Find(gui) else nil
end

function UIController.Init(_self: any, controllers: { [string]: any })
	registry = controllers
end

function UIController.Open(_self: any, name: string, argument: any?)
	local screen = screens[name]
	if not screen or opened[name] then
		return
	end
	if screen.Modal then
		for otherName in opened do
			if screens[otherName].Modal then
				UIController:Close(otherName)
			end
		end
	end
	opened[name] = true
	screen:Open(argument)
	local popScale = findPopScale(name)
	if popScale then
		pop.Open(popScale)
	end
	local openSound = UIFeelConfig.OpenSounds[name] or if popScale then UIFeelConfig.PanelOpenSound else nil
	if openSound then
		LocalSound.Play(openSound)
	end
end

function UIController.Close(_self: any, name: string)
	local screen = screens[name]
	if not screen or not opened[name] then
		return
	end
	opened[name] = nil
	local popScale = findPopScale(name)
	if not popScale then
		screen:Close()
		return
	end
	LocalSound.Play(UIFeelConfig.PanelCloseSound)
	pop.Close(popScale, function()
		if not opened[name] and screens[name] == screen then
			screen:Close()
		end
	end)
end

function UIController.BindFeel(_self: any, gui: LayerCollector)
	if feel then
		feel.Bind(gui)
	end
end

function UIController.IsOpen(_self: any, name: string): boolean
	return opened[name] == true
end

function UIController.Start(_self: any)
	local context: Types.Context = {
		Controllers = registry,
		Open = function(name: string, argument: any?)
			UIController:Open(name, argument)
		end,
		Close = function(name: string)
			UIController:Close(name)
		end,
		Feedback = function(button: GuiButton?, isSuccess: boolean)
			if feel then
				feel.Feedback(button, isSuccess)
			end
		end,
	}
	local created = ButtonFeel.new(feelTrove)
	feel = created
	for name, module in modules do
		local promise = WaitFor.Child(Players.LocalPlayer, "PlayerGui", 15)
			:andThen(function(playerGui: Instance)
				return WaitFor.Child(playerGui, name, 15)
			end)
			:andThen(function(gui: Instance)
				if destroyed then
					return
				end
				if not gui:IsA("ScreenGui") then
					error(`{gui:GetFullName()} is a {gui.ClassName}, not a ScreenGui`)
				end
				gui.ResetOnSpawn = false
				Typography.Apply(gui)
				local screen = module.new(context, gui)
				screens[name] = screen
				guis[name] = gui
				created.Bind(gui)
				if screen.StartsOpen then
					UIController:Open(name)
				else
					screen:Close()
				end
			end)
			:catch(function(problem: any)
				warn(
					`[UIController] {name} screen disabled; needs a ScreenGui at PlayerGui.{name}: {tostring(
						problem
					)}`
				)
			end)
		table.insert(pending, promise)
	end
end

function UIController.Destroy(_self: any)
	destroyed = true
	for _, promise in pending do
		promise:cancel()
	end
	table.clear(pending)
	feelTrove:Destroy()
	feel = nil
	pop.Destroy()
	for _, screen in screens do
		screen:Destroy()
	end
	table.clear(screens)
	table.clear(guis)
	table.clear(opened)
end

return UIController
