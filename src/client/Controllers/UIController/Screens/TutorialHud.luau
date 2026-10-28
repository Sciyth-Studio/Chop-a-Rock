--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonHint = require(ReplicatedStorage.CannonHint)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local TutorialHud = {}

local confirmSeconds = 3

local function setLabel(root: Instance, text: string)
	for _, name in { "Label", "LabelShadow" } do
		local label = root:FindFirstChild(name)
		if label and label:IsA("TextLabel") then
			label.Text = text
		end
	end
end

function TutorialHud.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local skip = gui:FindFirstChild("SkipButton", true)
	local hitbox = if skip then skip:FindFirstChild("Button") else nil
	if not skip or not hitbox or not hitbox:IsA("GuiButton") then
		warn(`[TutorialHud] Missing SkipButton.Button in {gui:GetFullName()}`)
	end

	local isConfirming = false
	local confirmToken = 0

	local function reset()
		isConfirming = false
		confirmToken += 1
		if skip then
			setLabel(skip, "Skip")
		end
	end

	local function isHinting(): boolean
		local data = context.Controllers.DataController:Get()
		return CannonHint.IsShown(data) and CannonHint.StageOf(data) >= CannonHint.Buy
	end

	local function refresh()
		local isShown = isHinting()
		if gui.Enabled ~= isShown then
			gui.Enabled = isShown
		end
		if not isShown then
			reset()
		end
	end

	if skip and hitbox and hitbox:IsA("GuiButton") then
		trove:Connect(hitbox.Activated, function()
			if not isConfirming then
				isConfirming = true
				confirmToken += 1
				local token = confirmToken
				setLabel(skip, "Sure?")
				task.delay(confirmSeconds, function()
					if token == confirmToken then
						reset()
					end
				end)
				return
			end
			reset()
			if isHinting() then
				Packets.CannonHintSkip:Fire()
			end
		end)
	end

	for _, path in { { "Tutorial", "Step" }, { "Hints" }, { "Strength" } } do
		trove:Add(context.Controllers.DataController:Observe(path, refresh))
	end

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			refresh()
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return TutorialHud
