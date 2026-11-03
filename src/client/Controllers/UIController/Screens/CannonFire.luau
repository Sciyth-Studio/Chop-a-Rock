--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local BlockButton = require(ReplicatedStorage.Utils.BlockButton)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local CannonFire = {}

local style = CannonConfig.FireButton

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[CannonFire] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

function CannonFire.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local button: TextButton? = find(gui, "Button", "TextButton")
	local timer: Frame? = find(gui, "Timer", "Frame")
	local timerFill: Frame? = if timer then find(timer, "Fill", "Frame") else nil
	local deadline = 0
	local duration = 0
	local isBusy = false

	if button then
		BlockButton.Paint(button:FindFirstChild("Fill", true), style.Colors)
		local label = button:FindFirstChild("Label")
		if label then
			BlockButton.SetText(label, style.Text)
		end
	end
	if timerFill then
		local gradient = timerFill:FindFirstChildOfClass("UIGradient")
		if gradient then
			gradient.Color = ColorSequence.new(style.Colors.Center, style.Colors.Edge)
		end
	end

	local function hide()
		deadline = 0
		context.Close(style.ScreenName)
	end

	local function show(seconds: number)
		duration = seconds
		deadline = os.clock() + seconds
		if timerFill then
			timerFill.Size = UDim2.fromScale(1, 1)
		end
		context.Open(style.ScreenName)
	end

	trove:Add(Packets.CannonWindow.OnClientEvent:Connect(function(key: string, seconds: number)
		if key == "" or seconds <= 0 then
			hide()
		else
			show(seconds)
		end
	end))

	trove:Connect(RunService.Heartbeat, function()
		if deadline == 0 then
			return
		end
		local remaining = deadline - os.clock()
		if remaining <= 0 then
			hide()
		elseif timerFill then
			timerFill.Size = UDim2.fromScale(remaining / duration, 1)
		end
	end)

	if button then
		trove:Connect(button.Activated, function()
			if isBusy or deadline == 0 then
				return
			end
			isBusy = true
			task.spawn(function()
				local isDone = Packets.FireCannon:Fire() == true
				isBusy = false
				if not isDone then
					context.Feedback(button, false)
				end
				hide()
			end)
		end)
	end

	return {
		Modal = false,
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

return CannonFire
