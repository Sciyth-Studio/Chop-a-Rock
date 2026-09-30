--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MenuButtonConfig = require(ReplicatedStorage.Config.MenuButtonConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local MenuButtons = {}

function MenuButtons.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()

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
