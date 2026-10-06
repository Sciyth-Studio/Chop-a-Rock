--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Icon = require(ReplicatedStorage.Packages.TopbarPlus) :: any
local Types = require(script.Parent.Parent.Types)

local SCREEN_NAME = "AdminPanel"

local AdminPanel = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[AdminPanel] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

function AdminPanel.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local adminController = context.Controllers.AdminController
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local panel: Frame? = find(gui, "Panel", "Frame")
	local list: Frame? = find(gui, "List", "Frame")
	local template: TextButton? = find(gui, "CommandTemplate", "TextButton")
	local closeButton: TextButton? = find(gui, "CloseButton", "TextButton")

	if template then
		template.Visible = false
	end

	if list and template then
		for order, command in AdminConfig.Commands do
			local button = template:Clone()
			button.Name = command.Id
			button.LayoutOrder = order
			button.Visible = true
			local label = button:FindFirstChild("Label", true)
			if label and label:IsA("TextLabel") then
				label.Text = command.Label
			end
			trove:Add(button.Activated:Connect(function()
				adminController:Run(command.Id)
			end))
			button.Parent = list
		end
		local layout = list:FindFirstChildWhichIsA("UIListLayout")
		if panel and layout then
			local count = #AdminConfig.Commands
			local listHeight = count * template.Size.Y.Offset + math.max(count - 1, 0) * layout.Padding.Offset
			panel.Size = UDim2.new(panel.Size.X, UDim.new(0, list.Position.Y.Offset + listHeight + 24))
		end
	end

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
