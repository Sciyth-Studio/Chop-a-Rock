--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local ShopConfig = require(ReplicatedStorage.Config.ShopConfig)
local AdminWarps = require(ReplicatedStorage.Utils.AdminWarps)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Icon = require(ReplicatedStorage.Packages.TopbarPlus) :: any
local Types = require(script.Parent.Parent.Types)

local SCREEN_NAME = "AdminPanel"
local WARP_ORDER_OFFSET = -10000

local AdminPanel = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[AdminPanel] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function paint(button: Instance, colors: ShopConfig.MeterColors)
	local fill = button:FindFirstChild("Fill", true)
	if not fill then
		return
	end
	local gradient = fill:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, colors.Edge),
			ColorSequenceKeypoint.new(0.5, colors.Center),
			ColorSequenceKeypoint.new(1, colors.Edge),
		})
	end
	local studs = fill:FindFirstChild("StudTexture")
	if studs and studs:IsA("ImageLabel") then
		studs.ImageColor3 = colors.Studs
	end
end

local function setText(root: Instance, name: string, text: string)
	local label = root:FindFirstChild(name, true)
	if label and (label:IsA("TextLabel") or label:IsA("TextBox")) then
		(label :: any).Text = text
	end
end

function AdminPanel.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local adminController = context.Controllers.AdminController
	local trove = Trove.new()
	local warpTrove = trove:Extend()
	ViewportScale.Bind(gui, trove)

	local tabsFrame: Frame? = find(gui, "Tabs", "Frame")
	local list: ScrollingFrame? = find(gui, "List", "ScrollingFrame")
	local tabTemplate: TextButton? = find(gui, "TabTemplate", "TextButton")
	local commandTemplate: TextButton? = find(gui, "CommandTemplate", "TextButton")
	local numberTemplate: Frame? = find(gui, "NumberTemplate", "Frame")
	local choiceTemplate: Frame? = find(gui, "ChoiceTemplate", "Frame")
	local closeButton: TextButton? = find(gui, "CloseButton", "TextButton")

	for _, template in { tabTemplate, commandTemplate, numberTemplate, choiceTemplate } :: { GuiObject? } do
		if template then
			template.Visible = false
		end
	end

	local activeTab = AdminConfig.Tabs[1]
	local rows: { [GuiObject]: string } = {}
	local tabButtons: { [string]: TextButton } = {}
	local nextOrder = 0

	local function addRow(tab: string, row: GuiObject, order: number?)
		if not list then
			row:Destroy()
			return
		end
		nextOrder += 1
		row.LayoutOrder = order or nextOrder
		row.Visible = tab == activeTab
		row.Parent = list
		rows[row] = tab
	end

	local function run(commandId: string, argument: string?)
		adminController:Run(commandId, argument)
	end

	local function addButton(
		tab: string,
		name: string,
		label: string,
		colors: ShopConfig.MeterColors,
		onActivated: () -> (),
		rowTrove: any,
		order: number?
	): TextButton?
		if not commandTemplate then
			return nil
		end
		local button = commandTemplate:Clone()
		button.Name = name
		setText(button, "Label", label)
		paint(button, colors)
		rowTrove:Add(button.Activated:Connect(onActivated))
		rowTrove:Add(button)
		addRow(tab, button, order)
		return button
	end

	local function addNumberRow(command: AdminConfig.Command)
		if not numberTemplate then
			return
		end
		local row = numberTemplate:Clone()
		row.Name = command.Id
		local input = row:FindFirstChild("Input", true)
		local runButton = row:FindFirstChild("Run")
		if not input or not input:IsA("TextBox") or not runButton or not runButton:IsA("TextButton") then
			warn(`[AdminPanel] NumberTemplate needs a TextBox "Input" and a TextButton "Run"`)
			row:Destroy()
			return
		end
		input.Text = command.Default or ""
		setText(runButton, "Label", command.Label)
		paint(runButton, AdminConfig.Palette.Command)
		trove:Add(runButton.Activated:Connect(function()
			run(command.Id, input.Text)
		end))
		trove:Add(input.FocusLost:Connect(function(enterPressed: boolean)
			if enterPressed then
				run(command.Id, input.Text)
			end
		end))
		addRow(command.Tab, row)
	end

	local function addChoiceRow(command: AdminConfig.Command)
		local choices = command.Choices
		if not choiceTemplate or not choices or #choices == 0 then
			return
		end
		local row = choiceTemplate:Clone()
		row.Name = command.Id
		local prev = row:FindFirstChild("Prev")
		local nextButton = row:FindFirstChild("Next")
		local runButton = row:FindFirstChild("Run")
		if
			not prev
			or not prev:IsA("TextButton")
			or not nextButton
			or not nextButton:IsA("TextButton")
			or not runButton
			or not runButton:IsA("TextButton")
		then
			warn(`[AdminPanel] ChoiceTemplate needs TextButtons "Prev", "Next" and "Run"`)
			row:Destroy()
			return
		end
		local index = 1
		local function show()
			setText(row, "Value", choices[index].Label)
		end
		local function step(delta: number)
			index = (index - 1 + delta) % #choices + 1
			show()
		end
		setText(runButton, "Label", command.Label)
		for _, button in { prev, nextButton, runButton } do
			paint(button, AdminConfig.Palette.Command)
		end
		trove:Add(prev.Activated:Connect(function()
			step(-1)
		end))
		trove:Add(nextButton.Activated:Connect(function()
			step(1)
		end))
		trove:Add(runButton.Activated:Connect(function()
			run(command.Id, choices[index].Value)
		end))
		show()
		addRow(command.Tab, row)
	end

	local function rebuildWarps()
		warpTrove:Clean()
		local function warpTo(label: string)
			return function()
				run("Warp", label)
			end
		end
		local labels = { AdminConfig.BaseWarpLabel }
		for _, warp in AdminWarps.List() do
			table.insert(labels, warp.Label)
		end
		for order, label in labels do
			local button = addButton(
				AdminConfig.WarpTab,
				`Warp_{label}`,
				label,
				AdminConfig.Palette.Warp,
				warpTo(label),
				warpTrove,
				WARP_ORDER_OFFSET + order
			)
			if button then
				warpTrove:Add(function()
					rows[button] = nil
				end)
			end
		end
	end

	local function selectTab(tab: string)
		activeTab = tab
		if tab == AdminConfig.WarpTab then
			rebuildWarps()
		end
		for row, rowTab in rows do
			row.Visible = rowTab == tab
		end
		for name, button in tabButtons do
			paint(button, if name == tab then AdminConfig.Palette.TabActive else AdminConfig.Palette.TabIdle)
		end
		if list then
			list.CanvasPosition = Vector2.zero
		end
	end

	if tabsFrame and tabTemplate then
		for order, tab in AdminConfig.Tabs do
			local button = tabTemplate:Clone()
			button.Name = tab
			button.LayoutOrder = order
			button.Visible = true
			setText(button, "Label", tab)
			trove:Add(button.Activated:Connect(function()
				selectTab(tab)
			end))
			button.Parent = tabsFrame
			tabButtons[tab] = button
		end
	end

	for _, preset in AdminConfig.Presets do
		addButton(
			AdminConfig.PresetTab,
			`Preset_{preset.Id}`,
			preset.Label,
			AdminConfig.Palette.Preset,
			function()
				run("ApplyPreset", preset.Id)
			end,
			trove
		)
	end

	for _, command in AdminConfig.Commands do
		if command.Kind == "Number" then
			addNumberRow(command)
		elseif command.Kind == "Choice" then
			addChoiceRow(command)
		else
			addButton(command.Tab, command.Id, command.Label, AdminConfig.Palette.Command, function()
				run(command.Id)
			end, trove)
		end
	end

	selectTab(activeTab)

	if closeButton then
		trove:Add(closeButton.Activated:Connect(function()
			context.Close(SCREEN_NAME)
		end))
	end

	local isOpen = false
	local icon: any = nil

	local function refreshIcon()
		local isAdmin = adminController:IsAdmin()
		if isAdmin and not icon then
			icon = Icon.new()
				:setName(SCREEN_NAME)
				:setLabel(AdminConfig.TopbarLabel)
				:oneClick()
				:bindEvent("selected", function()
					if isOpen then
						context.Close(SCREEN_NAME)
					else
						context.Open(SCREEN_NAME)
					end
				end)
		elseif not isAdmin and icon then
			icon:destroy()
			icon = nil
			context.Close(SCREEN_NAME)
		end
	end

	trove:Add(Players.LocalPlayer:GetAttributeChangedSignal(AdminConfig.AttributeName):Connect(refreshIcon))
	trove:Add(function()
		if icon then
			icon:destroy()
			icon = nil
		end
	end)
	refreshIcon()

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = adminController:IsAdmin()
			gui.Enabled = isOpen
			if isOpen and activeTab == AdminConfig.WarpTab then
				selectTab(activeTab)
			end
		end,
		Close = function(_self: Types.Screen)
			isOpen = false
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return AdminPanel
