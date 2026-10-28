--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local TutorialComplete = {}

local function rewardText(): string
	for _, boost in MonetizationConfig.Boosts do
		if boost.Key == MonetizationConfig.TasteBoostKey then
			return `Free {boost.DisplayName}!`
		end
	end
	return ""
end

function TutorialComplete.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local function findLabels(name: string): { TextLabel }
		local found: { TextLabel } = {}
		for _, labelName in { name, name .. HudConfig.ShadowSuffix } do
			local label = gui:FindFirstChild(labelName, true)
			if label and label:IsA("TextLabel") then
				table.insert(found, label)
			end
		end
		if #found == 0 then
			warn(`[TutorialComplete] Missing {name} label in {gui:GetFullName()}`)
		end
		return found
	end

	local titles = findLabels("Title")
	local labels = findLabels("Reward")

	local function show(isReward: boolean)
		for _, label in titles do
			label.Visible = not isReward
		end
		for _, label in labels do
			label.Visible = isReward
		end
	end

	local token = 0

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			local text = rewardText()
			for _, label in labels do
				label.Text = text
			end
			show(false)
			gui.Enabled = true
			token += 1
			local current = token
			task.delay(TutorialConfig.CompleteSeconds / 2, function()
				if current == token then
					show(true)
				end
			end)
			task.delay(TutorialConfig.CompleteSeconds, function()
				if current == token then
					context.Close(TutorialConfig.CompleteScreen)
				end
			end)
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			token += 1
			trove:Destroy()
		end,
	}
end

return TutorialComplete
