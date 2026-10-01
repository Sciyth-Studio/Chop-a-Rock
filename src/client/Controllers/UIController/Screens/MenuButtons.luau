--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MenuButtonConfig = require(ReplicatedStorage.Config.MenuButtonConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Input = require(ReplicatedStorage.Packages.Input)
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

	local container = gui:FindFirstChild(MenuButtonConfig.ContainerName)
	local listLayout = if container then container:FindFirstChildWhichIsA("UIListLayout") else nil
	local layoutStore = gui:FindFirstChild(MenuButtonConfig.LayoutStoreName)
	local phoneLayout = if layoutStore
		then layoutStore:FindFirstChild(MenuButtonConfig.PhoneLayoutName)
		else nil
	if
		layoutStore
		and container
		and container:IsA("Frame")
		and listLayout
		and phoneLayout
		and phoneLayout:IsA("UIGridLayout")
	then
		local desktopSize = container.Size
		local desktopPosition = container.Position

		local isPhoneLayout = false
		local isTouch = false

		local function applyLayout()
			local camera = workspace.CurrentCamera
			if not camera then
				return
			end
			local viewport = camera.ViewportSize
			local shortSide = math.min(viewport.X, viewport.Y)
			if shortSide <= 0 then
				return
			end
			local isPhone = isTouch or shortSide < MenuButtonConfig.PhoneMaxShortSidePixels
			if isPhone == isPhoneLayout then
				return
			end
			isPhoneLayout = isPhone
			if isPhone then
				local columns = MenuButtonConfig.PhoneColumns
				local rows = math.ceil(#MenuButtonConfig.Buttons / columns)
				local cell = MenuButtonConfig.ButtonSizePixels
				local gap = MenuButtonConfig.ButtonGapPixels
				phoneLayout.FillDirectionMaxCells = columns
				listLayout.Parent = layoutStore
				phoneLayout.Parent = container
				container.Size =
					UDim2.fromOffset(columns * cell + (columns - 1) * gap, rows * cell + (rows - 1) * gap)
				container.Position = UDim2.new(
					desktopPosition.X.Scale,
					desktopPosition.X.Offset,
					desktopPosition.Y.Scale,
					MenuButtonConfig.PhoneTopPixels
				)
			else
				phoneLayout.Parent = layoutStore
				listLayout.Parent = container
				container.Size = desktopSize
				container.Position = desktopPosition
			end
		end

		local function watchCamera()
			local camera = workspace.CurrentCamera
			if camera then
				trove:Connect(camera:GetPropertyChangedSignal("ViewportSize"), applyLayout)
			end
			applyLayout()
		end

		trove:Add(Input.PreferredInput.observe(function(preferred: Enum.PreferredInput)
			isTouch = preferred == Enum.PreferredInput.Touch
			applyLayout()
			return nil
		end))
		trove:Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), watchCamera)
		watchCamera()
	else
		warn(
			`[MenuButtons] Phone layout disabled; needs Container, UIListLayout and PhoneLayout in {gui:GetFullName()}`
		)
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
