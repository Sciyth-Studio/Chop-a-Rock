--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())
type Spot = {
	Index: number,
	Part: BasePart,
	Color: Color3,
	Material: Enum.Material,
	MaterialVariant: string,
	Prompt: ProximityPrompt,
}

local Phases = BossConfig.Phases

local BossController = {
	Name = "BossController",
	_trove = nil :: TroveInstance?,
}

local chopController: any = nil

local function numberAttribute(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function canChop(phase: number): boolean
	return phase == Phases.Fighting or phase == Phases.Mad or phase == Phases.Finish
end

local function setupEyes(trove: TroveInstance, model: Model, skinColor: Color3)
	local eyes = model:FindFirstChild(BossConfig.EyesName)
	local pupils = model:FindFirstChild(BossConfig.PupilsName)
	if not eyes or not eyes:IsA("BasePart") then
		return
	end
	local openSize = eyes.Size
	local closedSize = Vector3.new(openSize.X, openSize.Y * BossConfig.SleepEyeScale, openSize.Z)
	local lidColor = skinColor:Lerp(Color3.new(0, 0, 0), BossConfig.LidShade)
	local pupilPart: BasePart? = if pupils and pupils:IsA("BasePart") then pupils else nil
	local pupilTransparency = if pupilPart then pupilPart.Transparency else 0
	local isClosed: boolean? = nil
	local openColor = eyes.Color
	local function apply()
		local closed = numberAttribute(model, BossConfig.PhaseAttribute) == Phases.Sleeping
		if closed == isClosed then
			return
		end
		local firstTime = isClosed == nil
		isClosed = closed
		local info = TweenInfo.new(
			if firstTime then 0 else BossConfig.EyeOpenSeconds,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		)
		if closed then
			openColor = eyes.Color
			eyes.Color = lidColor
		else
			eyes.Color = openColor
		end
		TweenService:Create(eyes, info, { Size = if closed then closedSize else openSize }):Play()
		if pupilPart then
			pupilPart.Transparency = if closed then 1 else pupilTransparency
		end
	end
	apply()
	trove:Connect(model:GetAttributeChangedSignal(BossConfig.PhaseAttribute), apply)
end

local function setupBoss(trove: TroveInstance, model: Model)
	local root = model.PrimaryPart or model:WaitForChild("Root", 10)
	if not root or not root:IsA("BasePart") or not model.Parent then
		return
	end
	local key = model:GetAttribute(BossConfig.BossAttribute)
	local boss = if type(key) == "string" then BossConfig.Bosses[key] else nil
	local displayName = if boss then boss.DisplayName else "Boss"
	local skinColor = if boss then boss.SkinColor else Color3.new(1, 1, 1)
	setupEyes(trove, model, skinColor)
	local spots: { Spot } = {}
	for _, child in model:GetChildren() do
		local index = child:GetAttribute(BossConfig.SpotIndexAttribute)
		if not child:IsA("BasePart") or type(index) ~= "number" then
			continue
		end
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Chop"
		prompt.ObjectText = displayName
		prompt.HoldDuration = ChopConfig.PromptHoldSeconds
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.MaxActivationDistance = ChopConfig.PromptRangeStuds
			+ math.max(child.Size.X, child.Size.Y, child.Size.Z) / 2
			+ BossConfig.ChopRangeSlackStuds / 2
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = child
		trove:Add(prompt)
		trove:Connect(prompt.Triggered, function()
			Packets.BossChop:Fire(index)
		end)
		table.insert(spots, {
			Index = index,
			Part = child,
			Color = child.Color,
			Material = child.Material,
			MaterialVariant = child.MaterialVariant,
			Prompt = prompt,
		})
	end

	local player = Players.LocalPlayer
	local function refresh()
		local phase = numberAttribute(model, BossConfig.PhaseAttribute)
		local gold = numberAttribute(model, BossConfig.GoldSpotAttribute)
		local isOpen = canChop(phase)
			and phase ~= Phases.Mad
			and numberAttribute(model, BossConfig.AttackAttribute) == BossConfig.Attacks.None
			and not chopController:IsMinigameActive()
			and player:GetAttribute(BossConfig.KnockedOutAttribute) ~= true
		for _, spot in spots do
			spot.Prompt.Enabled = isOpen
			local isWeak = canChop(phase) and (phase == Phases.Finish or spot.Index == gold)
			spot.Part.Color = if isWeak then spot.Color else skinColor
			spot.Part.Material = if isWeak then spot.Material else BossConfig.SkinMaterial
			spot.Part.MaterialVariant = if isWeak
				then spot.MaterialVariant
				else BossConfig.SkinMaterialVariant
		end
	end
	refresh()
	for _, name in { BossConfig.PhaseAttribute, BossConfig.GoldSpotAttribute, BossConfig.AttackAttribute } do
		trove:Connect(model:GetAttributeChangedSignal(name), refresh)
	end
	trove:Connect(player:GetAttributeChangedSignal(BossConfig.KnockedOutAttribute), refresh)
	trove:Connect(chopController.ActiveChanged, refresh)
end

function BossController.Init(self: any, registry: { [string]: any })
	self._trove = Trove.new()
	chopController = registry.ChopController
end

function BossController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local active: { [Instance]: TroveInstance } = {}
	local function add(instance: Instance)
		if not instance:IsA("Model") or active[instance] then
			return
		end
		local bossTrove = Trove.new()
		active[instance] = bossTrove
		task.spawn(setupBoss, bossTrove, instance)
	end
	local function remove(instance: Instance)
		local bossTrove = active[instance]
		if bossTrove then
			active[instance] = nil
			bossTrove:Destroy()
		end
	end
	trove:Connect(CollectionService:GetInstanceAddedSignal(BossConfig.Tag), add)
	trove:Connect(CollectionService:GetInstanceRemovedSignal(BossConfig.Tag), remove)
	for _, instance in CollectionService:GetTagged(BossConfig.Tag) do
		add(instance)
	end
	trove:Add(function()
		for instance in active do
			remove(instance)
		end
	end)
end

function BossController.Destroy(self: any)
	local trove = self._trove :: TroveInstance?
	if trove then
		trove:Destroy()
	end
end

local _lifecycleCheck: Lifecycle.System = BossController

return BossController
