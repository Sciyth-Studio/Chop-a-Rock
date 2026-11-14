--!strict

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local OutlinedIcon = require(ReplicatedStorage.Utils.OutlinedIcon)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)

type TroveInstance = typeof(Trove.new())
type ActivePrompt = {
	Gui: BillboardGui,
	HoldFill: Frame,
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
	entry.HoldFill.Size = UDim2.fromScale(1, math.clamp(progress, 0, 1))
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
		return "Tap"
	end
	return "Click"
end

local function keyIcon(inputType: Enum.ProximityPromptInputType): string?
	if inputType == Enum.ProximityPromptInputType.Touch then
		return IconConfig.Tap
	elseif inputType == Enum.ProximityPromptInputType.Keyboard then
		return IconConfig.Click
	end
	return nil
end

local function clickRoot(prompt: ProximityPrompt): Instance?
	local adornee = prompt.Parent
	if adornee and adornee:IsA("Attachment") then
		adornee = adornee.Parent
	end
	if not adornee then
		return nil
	end
	local model = adornee:FindFirstAncestorWhichIsA("Model")
	if model and model ~= workspace then
		return model
	end
	return adornee
end

local function promptUnderMouse(): ProximityPrompt?
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local character = Players.LocalPlayer.Character
	params.FilterDescendantsInstances = if character then { character } else {}
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	if not result then
		return nil
	end
	for prompt in active do
		local root = clickRoot(prompt)
		if root and prompt.Enabled and (result.Instance == root or result.Instance:IsDescendantOf(root)) then
			return prompt
		end
	end
	return nil
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
	local holdFill = findChild(template, "HoldFill", "Frame")
	local hit = findChild(template, "Hit", "TextButton")
	if not (objectLabel and actionLabel and keyLabel and holdFill and hit) then
		template:Destroy()
		return
	end

	local entryTrove = Trove.new()
	entryTrove:Add(template)
	local entry: ActivePrompt = {
		Gui = template,
		HoldFill = holdFill :: Frame,
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
	local icon = keyIcon(inputType)
	local keyImage = template:FindFirstChild("KeyIcon", true)
	if keyImage and keyImage:IsA("ImageLabel") then
		keyImage.Visible = icon ~= nil
		keyText.Visible = icon == nil
		if icon then
			keyImage.Image = OutlinedIcon.For(keyImage, icon)
		end
	end
	entry.HoldFill.BackgroundTransparency = ChopConfig.PromptFillTransparency
	setProgress(entry, 0)
	entryTrove:Connect(prompt:GetPropertyChangedSignal("ObjectText"), function()
		objectText.Text = prompt.ObjectText
	end)
	entryTrove:Connect(prompt:GetPropertyChangedSignal("ActionText"), function()
		actionText.Text = prompt.ActionText
	end)

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
	ViewportScale.ApplyToBillboard(template)
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
	local clickedPrompt: ProximityPrompt? = nil
	trove:Connect(UserInputService.InputBegan, function(input: InputObject, isProcessed: boolean)
		if isProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local prompt = promptUnderMouse()
		if prompt then
			clickedPrompt = prompt
			prompt:InputHoldBegin()
		end
	end)
	trove:Connect(UserInputService.InputEnded, function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local prompt = clickedPrompt
		clickedPrompt = nil
		if prompt then
			prompt:InputHoldEnd()
		end
	end)
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
