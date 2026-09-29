--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local Hud = {}

function Hud.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local player = Players.LocalPlayer
	local trove = Trove.new()

	local function bind(labelName: string, attribute: string, format: (number) -> string)
		local found = gui:FindFirstChild(labelName, true)
		if not found or not found:IsA("TextLabel") then
			warn(`[Hud] Missing TextLabel "{labelName}" in {gui:GetFullName()}`)
			return
		end
		local label: TextLabel = found

		local function refresh()
			local value = player:GetAttribute(attribute)
			label.Text = format(if type(value) == "number" then value else 0)
		end

		trove:Connect(player:GetAttributeChangedSignal(attribute), refresh)
		refresh()
	end

	bind("Money", "Cash", function(value: number): string
		return `${NumberFormat.Commas(value)}`
	end)
	bind("Strength", "Strength", function(value: number): string
		return `STR {NumberFormat.Commas(value)}`
	end)

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

return Hud
