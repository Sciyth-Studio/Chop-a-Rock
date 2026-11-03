--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local IndexRewards = require(ReplicatedStorage.IndexRewards)
local MenuButtonConfig = require(ReplicatedStorage.Config.MenuButtonConfig)
local RebirthStats = require(ReplicatedStorage.Utils.RebirthStats)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local MenuButtons = {}

function MenuButtons.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	for _, entry in MenuButtonConfig.Buttons do
		local frameName = entry.Name .. MenuButtonConfig.ButtonSuffix
		local frame = gui:FindFirstChild(frameName, true)
		local click = if frame then frame:FindFirstChild(MenuButtonConfig.ClickButtonName) else nil
		if not click or not click:IsA("GuiButton") then
			warn(`[MenuButtons] Missing button "{frameName}" in {gui:GetFullName()}`)
			continue
		end
		trove:Connect(click.Activated, function()
			local uiController = context.Controllers.UIController
			if uiController and uiController:IsOpen(entry.Screen) then
				context.Close(entry.Screen)
			else
				context.Open(entry.Screen)
			end
		end)
	end

	local badgeSettings = MenuButtonConfig.Badge
	local dataController = context.Controllers.DataController

	local function readNumber(key: string): number
		local value = dataController:Get({ key })
		return if type(value) == "number" then value else 0
	end

	local badgeRules: { [string]: { Paths: { { string } }, IsShown: () -> boolean } } = {
		Index = {
			Paths = { { "Index" } },
			IsShown = function()
				return #IndexRewards.Claimable(dataController:Get({ "Index" })) > 0
			end,
		},
		Rebirth = {
			Paths = { { "Rebirths" }, { "Strength" } },
			IsShown = function()
				return readNumber("Strength") >= RebirthStats.Get(readNumber("Rebirths") + 1).StrengthRequired
			end,
		},
	}

	local wiggleInfo = TweenInfo.new(badgeSettings.WiggleStepSeconds, Enum.EasingStyle.Sine)
	for _, buttonName in badgeSettings.Buttons do
		local badgeButton = gui:FindFirstChild(buttonName .. MenuButtonConfig.ButtonSuffix, true)
		local badge = if badgeButton then badgeButton:FindFirstChild(badgeSettings.BadgeName) else nil
		local badgeLabel = if badge then badge:FindFirstChild(badgeSettings.LabelName, true) else nil
		local rule = badgeRules[buttonName]
		if not (badge and badge:IsA("GuiObject") and badgeLabel and badgeLabel:IsA("TextLabel") and rule) then
			warn(`[MenuButtons] Missing {buttonName} badge in {gui:GetFullName()}`)
			continue
		end
		badge.Visible = false
		badgeLabel.Text = badgeSettings.Symbol
		for _, path in rule.Paths do
			trove:Add(dataController:Observe(path, function()
				badge.Visible = rule.IsShown()
			end))
		end
		trove:Add(task.spawn(function()
			while true do
				task.wait(badgeSettings.WiggleEverySeconds)
				if badge.Visible then
					for _, degrees in badgeSettings.WiggleDegrees do
						local tween = TweenService:Create(badge, wiggleInfo, { Rotation = degrees })
						tween:Play()
						tween.Completed:Wait()
					end
				end
			end
		end))
	end

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return MenuButtons
