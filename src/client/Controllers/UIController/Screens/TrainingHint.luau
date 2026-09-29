--!strict

local Types = require(script.Parent.Parent.Types)

local TrainingHint = {}

function TrainingHint.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen) end,
	}
end

return TrainingHint
