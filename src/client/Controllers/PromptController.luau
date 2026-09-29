--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)

type TroveInstance = typeof(Trove.new())
type ActivePrompt = {
	Gui: BillboardGui,
	FillGradient: UIGradient,
	HoldStart: number?,
	Trove: any,
}

local TEMPLATE_KEY = "UI_ChopPrompt"

local active: { [ProximityPrompt]: ActivePrompt } = {}

local PromptController = {
	Name = "PromptController",
	_trove = nil :: TroveInstance?,
}

local function findChild(root: Instance, name: string, className: string): Instance?
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[PromptController] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function setProgress(entry: ActivePrompt, progress: number)
	local boundary = 1 - math.clamp(progress, 0, 1)
	if boundary > 0.995 then
		boundary = 1
	end
	local filled = ChopConfig.PromptFillTransparency
	local keypoints = { NumberSequenceKeypoint.new(0, if boundary <= 0 then filled else 1) }
	if boundary > 0 and boundary < 1 then
		table.insert(keypoints, NumberSequenceKeypoint.new(boundary, 1))
		table.insert(keypoints, NumberSequenceKeypoint.new(math.min(1, boundary + 0.001), filled))
	end
	table.insert(keypoints, NumberSequenceKeypoint.new(1, if boundary >= 1 then 1 else filled))
	entry.FillGradient.Transparency = NumberSequence.new(keypoints)
end

local function hide(prompt: ProximityPrompt)
	local entry = active[prompt]
	if not entry then
		return
	end
	active[prompt] = nil
	entry.Trove:Destroy()
end

local function keyString(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Gamepad then
		return UserInputService:GetStringForKeyCode(prompt.GamepadKeyCode)
	elseif inputType == Enum.ProximityPromptInputType.Touch then
		return "TAP"
	end
	return UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
end

local function show(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom or active[prompt] then
		return
	end
	local adornee = prompt.Parent
	if not adornee or not (adornee:IsA("BasePart") or adornee:IsA("Attachment")) then
		return
	end

	local template = AssetRegistry.get(TEMPLATE_KEY)
	if not template:IsA("BillboardGui") then
		template:Destroy()
		return
	end
	local objectLabel = findChild(template, "ObjectLabel", "TextLabel")
	local actionLabel = findChild(template, "ActionLabel", "TextLabel")
	local keyLabel = findChild(template, "KeyLabel", "TextLabel")
	local fillGradient = findChild(template, "FillGradient", "UIGradient")
	local hit = findChild(template, "Hit", "TextButton")
	if not (objectLabel and actionLabel and keyLabel and fillGradient and hit) then
		template:Destroy()
		return
	end

	local entryTrove = Trove.new()
	entryTrove:Add(template)
	local entry: ActivePrompt = {
		Gui = template,
		FillGradient = fillGradient :: UIGradient,
		HoldStart = nil,
		Trove = entryTrove,
	}
	active[prompt] = entry

	local objectText = objectLabel :: TextLabel
	local actionText = actionLabel :: TextLabel
	local keyText = keyLabel :: TextLabel
	local hitButton = hit :: TextButton
	objectText.Text = prompt.ObjectText
	actionText.Text = prompt.ActionText
	keyText.Text = keyString(prompt, inputType)
	setProgress(entry, 0)

	entryTrove:Connect(hitButton.InputBegan, function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			prompt:InputHoldBegin()
		end
	end)
	entryTrove:Connect(hitButton.InputEnded, function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			prompt:InputHoldEnd()
		end
	end)

	template.Adornee = adornee
	Typography.Apply(template)
	template.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function beginHold(prompt: ProximityPrompt)
	local entry = active[prompt]
	if entry then
		entry.HoldStart = os.clock()
	end
end

local function endHold(prompt: ProximityPrompt)
	local entry = active[prompt]
	if entry then
		entry.HoldStart = nil
		setProgress(entry, 0)
	end
end

function PromptController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function PromptController.Start(self: any)
	local trove = self._trove :: TroveInstance
	trove:Connect(ProximityPromptService.PromptShown, show)
	trove:Connect(ProximityPromptService.PromptHidden, hide)
	trove:Connect(ProximityPromptService.PromptButtonHoldBegan, beginHold)
	trove:Connect(ProximityPromptService.PromptButtonHoldEnded, endHold)
	trove:Connect(RunService.RenderStepped, function()
		for prompt, entry in active do
			local holdStart = entry.HoldStart
			if holdStart and prompt.HoldDuration > 0 then
				setProgress(entry, (os.clock() - holdStart) / prompt.HoldDuration)
			end
		end
	end)
end

function PromptController.Destroy(self: any)
	for prompt in active do
		hide(prompt)
	end
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return PromptController
