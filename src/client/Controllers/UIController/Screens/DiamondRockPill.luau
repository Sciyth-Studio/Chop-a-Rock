--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local DiamondRockPill = {}

local function findDiamond(): BasePart?
	for _, tagged in CollectionService:GetTagged(DiamondRockConfig.Tag) do
		local part = if tagged:IsA("Model") then tagged.PrimaryPart else nil
		if part then
			return part
		end
	end
	return nil
end

function DiamondRockPill.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local containerInstance = gui:FindFirstChild("Container")
	local container: GuiObject? = if containerInstance and containerInstance:IsA("GuiObject")
		then containerInstance
		else nil
	local labelInstance = gui:FindFirstChild("Label", true)
	local label: TextLabel? = if labelInstance and labelInstance:IsA("TextLabel") then labelInstance else nil
	local shadowInstance = gui:FindFirstChild("Label" .. HudConfig.ShadowSuffix, true)
	local shadow: TextLabel? = if shadowInstance and shadowInstance:IsA("TextLabel")
		then shadowInstance
		else nil
	if not container or not label then
		warn(`[DiamondRockPill] Missing "Container" or "Label" in {gui:GetFullName()}`)
	end

	local shownText = ""
	local function refresh()
		if not container then
			return
		end
		local part = findDiamond()
		local endsAt = if part then part:GetAttribute(DiamondRockConfig.EndsAtAttribute) else nil
		local health = if part then part:GetAttribute(DiamondRockConfig.HealthAttribute) else nil
		local zone = if part then part:GetAttribute(DiamondRockConfig.ZoneAttribute) else nil
		local remaining = if type(endsAt) == "number"
			then math.ceil(endsAt - workspace:GetServerTimeNow())
			else 0
		local isShown = remaining > 0 and type(health) == "number" and health > 0 and type(zone) == "string"
		container.Visible = isShown
		if not isShown then
			return
		end
		local text =
			string.format(DiamondRockConfig.PillText, zone :: string, remaining // 60, remaining % 60)
		if text == shownText then
			return
		end
		shownText = text
		if label then
			label.Text = text
		end
		if shadow then
			shadow.Text = text
		end
	end

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
			trove:Connect(RunService.Heartbeat, refresh)
			refresh()
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return DiamondRockPill
