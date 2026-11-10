--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Types = require(script.Parent.Parent.Types)

local TrainingHint = {}

function TrainingHint.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local isOpen = false
	local isModalOpen = false

	local function refresh()
		gui.Enabled = isOpen and not isModalOpen
	end

	trove:Add(context.Controllers.UIController.ModalChanged:Connect(function(isOpenNow: boolean)
		isModalOpen = isOpenNow
		refresh()
	end))

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = true
			refresh()
		end,
		Close = function(_self: Types.Screen)
			isOpen = false
			refresh()
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return TrainingHint
