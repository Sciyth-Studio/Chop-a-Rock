--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Packets = require(ReplicatedStorage.Packets)
local ScaleConfig = require(ReplicatedStorage.Config.ScaleConfig)
local TeleportConfig = require(ReplicatedStorage.Config.TeleportConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local TeleportBar = {}

local function placePill(container: GuiObject)
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local pillGui = if playerGui then playerGui:FindFirstChild(TeleportConfig.PillScreenName) else nil
	local pill = if pillGui then pillGui:FindFirstChild(TeleportConfig.ContainerName) else nil
	if not pill or not pill:IsA("GuiObject") then
		return
	end
	local pillScale = pill:FindFirstChild(ScaleConfig.ScaleName)
	local divisor = if pillScale and pillScale:IsA("UIScale") then pillScale.Scale else 1
	local bottom = container.AbsolutePosition.Y + container.AbsoluteSize.Y + TeleportConfig.PillGapPixels
	local position = pill.Position
	pill.Position = UDim2.new(position.X.Scale, position.X.Offset, 0, bottom / divisor)
end

function TeleportBar.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local fanSettings = TeleportConfig.ShopFan
	local fanButton = gui:FindFirstChild(fanSettings.Button .. TeleportConfig.ButtonSuffix, true)
	local fanInstance = if fanButton then fanButton:FindFirstChild(fanSettings.FanName) else nil
	local fan: GuiObject? = if fanInstance and fanInstance:IsA("GuiObject") then fanInstance else nil
	local fanSlots: { { Frame: GuiObject, Scale: UIScale } } = {}
	local isFanOpen = false
	local fanVersion = 0
	local fanCenter = UDim2.fromScale(0.5, 0.5)
	local fanCloseInfo =
		TweenInfo.new(fanSettings.CloseSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	local function setFan(isOpen: boolean)
		if not fan or isOpen == isFanOpen then
			return
		end
		isFanOpen = isOpen
		fanVersion += 1
		local version = fanVersion
		if isOpen then
			fan.Visible = true
		end
		for index, slot in fanSlots do
			local info = if isOpen
				then TweenInfo.new(
					fanSettings.OpenSeconds,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out,
					0,
					false,
					(index - 1) * fanSettings.StaggerSeconds
				)
				else fanCloseInfo
			local height = slot.Frame.Size.Y.Scale
			local column = (index - 1) % fanSettings.Columns
			local row = (index - 1) // fanSettings.Columns
			local position = if isOpen
				then UDim2.fromScale(
					0.5 + (column - (fanSettings.Columns - 1) / 2) * fanSettings.ColumnSpacingScale,
					1 + fanSettings.GapScale + height / 2 + row * fanSettings.SpacingScale
				)
				else fanCenter
			TweenService:Create(slot.Frame, info, { Position = position }):Play()
			TweenService:Create(slot.Scale, info, { Scale = if isOpen then 1 else 0 }):Play()
		end
		if not isOpen then
			trove:Add(task.delay(fanSettings.CloseSeconds, function()
				if fanVersion == version and fan then
					fan.Visible = false
				end
			end))
		end
	end

	if fan then
		fan.Visible = false
		for _, name in fanSettings.Options do
			local slot = fan:FindFirstChild(name .. fanSettings.OptionSuffix)
			local scale = if slot then slot:FindFirstChild(fanSettings.PopScaleName) else nil
			if not slot or not slot:IsA("GuiObject") or not scale or not scale:IsA("UIScale") then
				warn(`[TeleportBar] Missing shop option "{name}" in {fan:GetFullName()}`)
				continue
			end
			slot.Position = fanCenter
			scale.Scale = 0
			table.insert(fanSlots, { Frame = slot, Scale = scale })
		end
	end
	local fanClick = if fanButton then fanButton:FindFirstChild(TeleportConfig.ClickButtonName) else nil
	if fan and fanClick and fanClick:IsA("GuiButton") then
		trove:Connect(fanClick.Activated, function()
			setFan(not isFanOpen)
		end)
	else
		warn(`[TeleportBar] Shop fan disabled; needs {fanSettings.Button}Button.{fanSettings.FanName}`)
	end

	local lastClick = -math.huge
	for _, destination in TeleportConfig.Destinations do
		local frameName = destination.Id .. TeleportConfig.ButtonSuffix
		local frame = gui:FindFirstChild(frameName, true)
		local click = if frame then frame:FindFirstChild(TeleportConfig.ClickButtonName) else nil
		if not click or not click:IsA("GuiButton") then
			warn(`[TeleportBar] Missing button "{frameName}" in {gui:GetFullName()}`)
			continue
		end
		trove:Connect(click.Activated, function()
			setFan(false)
			local now = os.clock()
			if now - lastClick < TeleportConfig.CooldownSeconds then
				return
			end
			lastClick = now
			Packets.Teleport:Fire(destination.Id)
		end)
	end

	local containerInstance = gui:FindFirstChild(TeleportConfig.ContainerName)
	if containerInstance and containerInstance:IsA("GuiObject") then
		local container = containerInstance
		container.Size = UDim2.fromOffset(TeleportConfig.BarWidthPixels, 0)
		trove:Connect(container:GetPropertyChangedSignal("AbsoluteSize"), function()
			placePill(container)
		end)
		placePill(container)
	else
		warn(`[TeleportBar] Layout disabled; needs Container in {gui:GetFullName()}`)
	end

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			setFan(false)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return TeleportBar
