--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportConfig = require(ReplicatedStorage.Config.TeleportConfig)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

export type State = {
	Container: GuiObject?,
	Position: UDim2?,
}

local Layout = {}

local function screen(name: string): ScreenGui?
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local gui = if playerGui then playerGui:FindFirstChild(name) else nil
	return if gui and gui:IsA("ScreenGui") then gui else nil
end

local function isShown(item: GuiObject, root: Instance): boolean
	local current: Instance? = item
	while current and current ~= root do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		current = current.Parent
	end
	return item.AbsoluteSize.Y > 1
end

local function barBottom(): number?
	local bar = screen(TutorialConfig.TeleportBarScreen)
	local container = if bar and bar.Enabled then bar:FindFirstChild(TeleportConfig.ContainerName) else nil
	if not bar or not container or not container:IsA("GuiObject") then
		return nil
	end
	local bottom = container.AbsolutePosition.Y + container.AbsoluteSize.Y
	local fanSettings = TeleportConfig.ShopFan
	local fan = container:FindFirstChild(fanSettings.FanName, true)
	if fan and fan:IsA("GuiObject") and fan.Visible then
		for _, name in fanSettings.Options do
			local slot = fan:FindFirstChild(name .. fanSettings.OptionSuffix)
			if slot and slot:IsA("GuiObject") and isShown(slot, bar) then
				bottom = math.max(bottom, slot.AbsolutePosition.Y + slot.AbsoluteSize.Y)
			end
		end
	end
	return bottom
end

function Layout.new(): State
	return { Container = nil, Position = nil }
end

function Layout.Update(state: State, isAvoidingBar: boolean)
	local notifications = screen(TutorialConfig.NotificationsScreen)
	local container = if notifications then notifications:FindFirstChild("Container") else nil
	if not container or not container:IsA("GuiObject") then
		return
	end
	if not state.Container then
		state.Container = container
		state.Position = container.Position
	end
	local base = state.Position :: UDim2
	local added = container.Position.Y.Offset - base.Y.Offset
	local top = container.AbsolutePosition.Y - added
	local bottom = if isAvoidingBar then barBottom() else nil
	local wanted = if bottom
		then base + UDim2.fromOffset(0, math.max(0, bottom + TutorialConfig.NotificationGapPixels - top))
		else base
	if container.Position ~= wanted then
		container.Position = wanted
	end
end

function Layout.Restore(state: State)
	if state.Container and state.Position then
		state.Container.Position = state.Position
	end
	state.Container = nil
	state.Position = nil
end

return Layout
