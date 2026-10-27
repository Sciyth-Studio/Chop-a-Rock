--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local RebirthStats = require(ReplicatedStorage.Utils.RebirthStats)
local TrainingStands = require(ReplicatedStorage.Utils.TrainingStands)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

type MeterColors = {
	Edge: Color3,
	Center: Color3,
	Studs: Color3,
}

local READY_COLORS: MeterColors = {
	Edge = Color3.fromRGB(0, 190, 40),
	Center = Color3.fromRGB(150, 255, 120),
	Studs = Color3.fromRGB(0, 120, 20),
}
local LOCKED_COLORS: MeterColors = {
	Edge = Color3.fromRGB(120, 120, 120),
	Center = Color3.fromRGB(215, 215, 215),
	Studs = Color3.fromRGB(70, 70, 70),
}

local Rebirth = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[Rebirth] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function setText(label: TextLabel?, text: string)
	if not label then
		return
	end
	label.Text = text
	local shadow = if label.Parent
		then label.Parent:FindFirstChild(label.Name .. HudConfig.ShadowSuffix)
		else nil
	if shadow and shadow:IsA("TextLabel") then
		shadow.Text = text
	end
end

function Rebirth.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local beforeTitle: TextLabel? = find(gui, "BeforeTitle", "TextLabel")
	local afterTitle: TextLabel? = find(gui, "AfterTitle", "TextLabel")
	local cashBefore: TextLabel? = find(gui, "CashBefore", "TextLabel")
	local cashAfter: TextLabel? = find(gui, "CashAfter", "TextLabel")
	local strengthBefore: TextLabel? = find(gui, "StrengthBefore", "TextLabel")
	local strengthAfter: TextLabel? = find(gui, "StrengthAfter", "TextLabel")
	local luckBefore: TextLabel? = find(gui, "LuckBefore", "TextLabel")
	local luckAfter: TextLabel? = find(gui, "LuckAfter", "TextLabel")
	local levelText: TextLabel? = find(gui, "LevelText", "TextLabel")
	local levelBar: Frame? = find(gui, "LevelBar", "Frame")
	local fill: Frame? = if levelBar then find(levelBar, "Fill", "Frame") else nil
	local rebirthButton: TextButton? = find(gui, "RebirthButton", "TextButton")
	local closeButton: TextButton? = find(gui, "CloseButton", "TextButton")
	local comingSoon: TextLabel? = find(gui, "ComingSoon", "TextLabel")
	local hiddenWhenMaxed: { GuiObject } = {}
	for _, name in { "Comparison", "Warning", "LevelBar", "Buttons" } do
		local object = find(gui, name, "GuiObject")
		if object then
			table.insert(hiddenWhenMaxed, object)
		end
	end

	local isReady = false
	local isBusy = false

	local function readNumber(key: string, fallback: number): number
		local value = dataController:Get({ key })
		return if type(value) == "number" then value else fallback
	end

	local function paint(button: TextButton, colors: MeterColors)
		BlockButton.Paint(button:FindFirstChild("Fill", true), colors)
	end

	local function refresh()
		local rebirths = readNumber("Rebirths", 0)
		local strength = readNumber("Strength", 0)
		local currentRebirth = RebirthStats.Get(rebirths)
		local nextRebirth = RebirthStats.Get(rebirths + 1)
		for _, object in hiddenWhenMaxed do
			object.Visible = true
		end
		if comingSoon then
			comingSoon.Visible = false
		end
		local cashNow = currentRebirth.CashMultiplier
		setText(luckBefore, `+{math.floor(currentRebirth.LuckBonus * 100 + 0.5)}% Luck`)
		setText(luckAfter, `+{math.floor(nextRebirth.LuckBonus * 100 + 0.5)}% Luck`)
		setText(beforeTitle, `Rebirth {rebirths}`)
		setText(afterTitle, `Rebirth {rebirths + 1}`)
		setText(cashBefore, `{NumberFormat.Multiplier(cashNow)} Cash`)
		setText(cashAfter, `{NumberFormat.Multiplier(nextRebirth.CashMultiplier)} Cash`)
		setText(strengthBefore, `{TrainingStands.ForRebirths(rebirths).DisplayName} Training`)
		setText(strengthAfter, `{TrainingStands.ForRebirths(rebirths + 1).DisplayName} Training`)
		local required = nextRebirth.StrengthRequired
		setText(
			levelText,
			`Strength: {NumberFormat.Compact(math.floor(math.min(strength, required)))}/{NumberFormat.Compact(
				required
			)} {TrainingConfig.StrengthUnit}`
		)
		if fill then
			fill.Size = UDim2.fromScale(math.clamp(strength / required, 0, 1), 1)
		end
		isReady = strength >= required
		if rebirthButton then
			rebirthButton:SetAttribute("Shimmer", isReady)
			if isReady then
				paint(rebirthButton, READY_COLORS)
			else
				paint(rebirthButton, LOCKED_COLORS)
			end
		end
	end

	if rebirthButton then
		trove:Add(rebirthButton.Activated:Connect(function()
			if isBusy then
				return
			end
			if not isReady then
				context.Feedback(rebirthButton, false)
				return
			end
			isBusy = true
			task.spawn(function()
				local isRebirthed = Packets.Rebirth:Fire() == true
				context.Feedback(rebirthButton, isRebirthed)
				isBusy = false
			end)
		end))
	end

	if closeButton then
		trove:Add(closeButton.Activated:Connect(function()
			context.Close("Rebirth")
		end))
	end

	trove:Add(dataController:Observe({ "Rebirths" }, refresh))
	trove:Add(dataController:Observe({ "Strength" }, refresh))
	refresh()

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			refresh()
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

return Rebirth
