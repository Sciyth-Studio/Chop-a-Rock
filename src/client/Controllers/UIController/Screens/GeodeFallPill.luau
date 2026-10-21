--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GeodeFallConfig = require(ReplicatedStorage.Config.GeodeFallConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local GeodeFallPill = {}

local function numberAttribute(name: string): number
	local value = workspace:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function pillText(): string?
	local zone = workspace:GetAttribute(GeodeFallConfig.PillZoneAttribute)
	if type(zone) ~= "string" or zone == "" then
		return nil
	end
	local now = workspace:GetServerTimeNow()
	local untilLand = math.ceil(numberAttribute(GeodeFallConfig.PillLandsAtAttribute) - now)
	if untilLand > 0 then
		return string.format(GeodeFallConfig.PillWarningText, zone, untilLand)
	end
	local remaining = math.ceil(numberAttribute(GeodeFallConfig.PillEndsAtAttribute) - now)
	local left = numberAttribute(GeodeFallConfig.PillLeftAttribute)
	local total = numberAttribute(GeodeFallConfig.PillTotalAttribute)
	if remaining <= 0 or left <= 0 then
		return nil
	end
	return string.format(GeodeFallConfig.PillText, zone, left, total, remaining // 60, remaining % 60)
end

function GeodeFallPill.new(_context: Types.Context, gui: ScreenGui): Types.Screen
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
		warn(`[GeodeFallPill] Missing "Container" or "Label" in {gui:GetFullName()}`)
	end

	local shownText = ""
	local function refresh()
		if not container then
			return
		end
		local text = pillText()
		container.Visible = text ~= nil
		if not text or text == shownText then
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

return GeodeFallPill
