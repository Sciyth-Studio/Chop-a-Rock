--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local RobuxShop = {}

function RobuxShop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)

	local closeButton = gui:FindFirstChild("CloseButton", true)
	if closeButton and closeButton:IsA("TextButton") then
		trove:Add(closeButton.Activated:Connect(function()
			context.Close("RobuxShop")
		end))
	else
		warn(`[RobuxShop] Missing TextButton "CloseButton" in {gui:GetFullName()}`)
	end

	return {
		Modal = true,
		StartsOpen = false,
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

return RobuxShop
