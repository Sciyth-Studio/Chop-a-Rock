--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local RebirthConfig = require(ReplicatedStorage.Config.RebirthConfig)
local Level = require(ReplicatedStorage.Utils.Level)
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

local function formatMultiplier(value: number): string
	return if value % 1 == 0 then tostring(value) else string.format("%.1f", value)
end

function Rebirth.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local dataController = context.Controllers.DataController
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local count: TextLabel? = find(gui, "Count", "TextLabel")
	local beforeTitle: TextLabel? = find(gui, "BeforeTitle", "TextLabel")
	local afterTitle: TextLabel? = find(gui, "AfterTitle", "TextLabel")
	local cashBefore: TextLabel? = find(gui, "CashBefore", "TextLabel")
	local cashAfter: TextLabel? = find(gui, "CashAfter", "TextLabel")
	local strengthBefore: TextLabel? = find(gui, "StrengthBefore", "TextLabel")
	local strengthAfter: TextLabel? = find(gui, "StrengthAfter", "TextLabel")
	local levelText: TextLabel? = find(gui, "LevelText", "TextLabel")
	local levelBar: Frame? = find(gui, "LevelBar", "Frame")
	local fill: Frame? = if levelBar then find(levelBar, "Fill", "Frame") else nil
	local rebirthButton: TextButton? = find(gui, "RebirthButton", "TextButton")
	local closeButton: TextButton? = find(gui, "CloseButton", "TextButton")
	local skipPrice: TextLabel? = find(gui, "SkipPrice", "TextLabel")
	local comingSoon: TextLabel? = find(gui, "ComingSoon", "TextLabel")
	local hiddenWhenMaxed: { GuiObject } = {}
	for _, name in { "Comparison", "Warning", "LevelBar", "Buttons" } do
		local object = find(gui, name, "GuiObject")
		if object then
			table.insert(hiddenWhenMaxed, object)
		end
	end

	setText(skipPrice, tostring(RebirthConfig.SkipRobuxPrice))

	local isReady = false
	local isBusy = false

	local function readNumber(key: string, fallback: number): number
		local value = dataController:Get({ key })
		return if type(value) == "number" then value else fallback
	end

	local function paint(button: TextButton, colors: MeterColors)
		local buttonFill = button:FindFirstChild("Fill", true)
		if not buttonFill then
			return
		end
		local gradient = buttonFill:FindFirstChildWhichIsA("UIGradient")
		if gradient then
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, colors.Edge),
				ColorSequenceKeypoint.new(0.5, colors.Center),
				ColorSequenceKeypoint.new(1, colors.Edge),
			})
		end
		local studs = buttonFill:FindFirstChild("StudTexture")
		if studs and studs:IsA("ImageLabel") then
			studs.ImageColor3 = colors.Studs
		end
	end

	local function refresh()
		local rebirths = readNumber("Rebirths", 0)
		local level = Level.FromStrength(readNumber("Strength", 0)).Level
		local currentRebirth = RebirthConfig.Rebirths[rebirths]
		local nextRebirth = RebirthConfig.Rebirths[rebirths + 1]
		setText(count, tostring(rebirths))
		for _, object in hiddenWhenMaxed do
			object.Visible = nextRebirth ~= nil
		end
		if comingSoon then
			comingSoon.Visible = nextRebirth == nil
		end
		if not nextRebirth then
			isReady = false
			return
		end
		local cashNow = if currentRebirth then currentRebirth.CashMultiplier else 1
		local strengthNow = if currentRebirth then currentRebirth.StrengthMultiplier else 1
		setText(beforeTitle, `Rebirth {rebirths}`)
		setText(afterTitle, `Rebirth {rebirths + 1}`)
		setText(cashBefore, `x{formatMultiplier(cashNow)} Cash`)
		setText(cashAfter, `x{formatMultiplier(nextRebirth.CashMultiplier)} Cash`)
		setText(strengthBefore, `x{formatMultiplier(strengthNow)} Strength`)
		setText(strengthAfter, `x{formatMultiplier(nextRebirth.StrengthMultiplier)} Strength`)
		local required = nextRebirth.LevelRequired
		setText(levelText, `Level: {math.min(level, required)}/{required}`)
		if fill then
			fill.Size = UDim2.fromScale(math.clamp(level / required, 0, 1), 1)
		end
		isReady = level >= required
		if rebirthButton then
			if isReady then
				paint(rebirthButton, READY_COLORS)
			else
				paint(rebirthButton, LOCKED_COLORS)
			end
		end
	end

	if rebirthButton then
		trove:Add(rebirthButton.Activated:Connect(function()
			if not isReady or isBusy then
				return
			end
			isBusy = true
			task.spawn(function()
				Packets.Rebirth:Fire()
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
