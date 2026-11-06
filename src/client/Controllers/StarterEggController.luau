--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local FallEffects = require(ReplicatedStorage.Utils.FallEffects)
local GeodeFallConfig = require(ReplicatedStorage.Config.GeodeFallConfig)
local PetModifier = require(ReplicatedStorage.PetModifier)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local StarterEggConfig = require(ReplicatedStorage.Config.StarterEggConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)

type TroveInstance = typeof(Trove.new())

local StarterEggController = { Name = "StarterEggController" }

local trove = Trove.new()
local actives: { [Model]: TroveInstance } = {}

local function numberAttribute(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function findLabel(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name, true)
	return if found and found:IsA("TextLabel") then found else nil
end

local function rainbowAt(alpha: number): Color3
	local keypoints = RarityConfig.Rainbow.Keypoints
	for index = 1, #keypoints - 1 do
		local from, to = keypoints[index], keypoints[index + 1]
		if alpha <= to.Time then
			local span = to.Time - from.Time
			return from.Value:Lerp(to.Value, if span > 0 then (alpha - from.Time) / span else 0)
		end
	end
	return keypoints[#keypoints].Value
end

local function addOutline(eggTrove: TroveInstance, model: Model)
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = model
	highlight.Parent = model
	eggTrove:Add(highlight)
	eggTrove:Connect(RunService.RenderStepped, function()
		highlight.OutlineColor = rainbowAt((os.clock() / StarterEggConfig.OutlineSeconds) % 1)
	end)
end

local function addLabel(eggTrove: TroveInstance, part: BasePart)
	local asset = AssetRegistry.get(GeodeFallConfig.LabelKey)
	if not asset:IsA("BillboardGui") then
		asset:Destroy()
		return
	end
	local nameLabel = findLabel(asset, "NameLabel")
	local timeLabel = findLabel(asset, "TimeLabel")
	local bar = asset:FindFirstChild("Bar")
	if bar and bar:IsA("GuiObject") then
		bar.Visible = false
	end
	Typography.Apply(asset)
	asset.Adornee = part
	asset.MaxDistance = StarterEggConfig.LabelMaxDistance
	asset.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + StarterEggConfig.LabelHeightStuds, 0)
	FallEffects.PaintLabel(nameLabel, StarterEggConfig.Color)
	FallEffects.PaintLabel(timeLabel, StarterEggConfig.Color)
	if nameLabel then
		nameLabel.Text = StarterEggConfig.DisplayName
	end
	asset.Parent = part
	eggTrove:Add(asset)

	local shown = ""
	eggTrove:Connect(RunService.Heartbeat, function()
		local now = workspace:GetServerTimeNow()
		local text: string
		if numberAttribute(part, StarterEggConfig.LandsAtAttribute) > now then
			text = StarterEggConfig.MysteryText
		else
			local remaining =
				math.max(0, math.ceil(numberAttribute(part, StarterEggConfig.EndsAtAttribute) - now))
			text = if remaining > 0
				then string.format("%d:%02d", remaining // 60, remaining % 60)
				else StarterEggConfig.ReadyText
		end
		if timeLabel and text ~= shown then
			shown = text
			timeLabel.Text = text
		end
	end)
end

local function addIdle(eggTrove: TroveInstance, model: Model, base: CFrame, ground: CFrame)
	FallEffects.AddIdle(eggTrove, ground, StarterEggConfig.Color, StarterEggConfig.EffectScale, false)
	local started = os.clock()
	eggTrove:Connect(RunService.RenderStepped, function()
		local elapsed = os.clock() - started
		local spin = (elapsed / StarterEggConfig.SpinSecondsPerTurn) * math.pi * 2
		local bob = (1 - math.cos(elapsed / StarterEggConfig.BobSeconds * math.pi * 2)) / 2
		model:PivotTo(base * CFrame.new(0, bob * StarterEggConfig.BobStuds, 0) * CFrame.Angles(0, spin, 0))
	end)
	eggTrove:Add(function()
		if model.Parent then
			model:PivotTo(base)
		end
	end)
end

local function setup(instance: Instance)
	if not instance:IsA("Model") or actives[instance] then
		return
	end
	local model = instance
	local found = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not found then
		return
	end
	local part = found
	local eggTrove = Trove.new()
	actives[model] = eggTrove

	local base = model:GetPivot()
	local boxCFrame, boxSize = model:GetBoundingBox()
	local ground = CFrame.new(boxCFrame.Position - Vector3.new(0, boxSize.Y / 2, 0))
	addOutline(eggTrove, model)
	PetModifier.Tint(model, StarterEggConfig.ModifierKey)
	PetModifier.AddVFX(part, StarterEggConfig.ModifierKey, eggTrove)
	addLabel(eggTrove, part)

	local untilLand = numberAttribute(part, StarterEggConfig.LandsAtAttribute) - workspace:GetServerTimeNow()
	if untilLand <= 0 then
		addIdle(eggTrove, model, base, ground)
		return
	end
	local sky = base + Vector3.new(0, StarterEggConfig.FallHeightStuds, 0)
	model:PivotTo(sky)
	FallEffects.Play(GeodeFallConfig.MarkerKey, ground, StarterEggConfig.Color, StarterEggConfig.EffectScale)
	local waitStart = os.clock()
	local fallSeconds = math.min(StarterEggConfig.FallSeconds, untilLand)
	local stopTrail: (() -> ())? = nil
	local fallStart: number? = nil
	local connection: RBXScriptConnection? = nil
	connection = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if not fallStart and now - waitStart >= untilLand - fallSeconds then
			fallStart = now
			stopTrail = FallEffects.AddMeteor(eggTrove, part)
			FallEffects.SoundAt(GeodeFallConfig.FallSoundKey, base.Position)
		end
		local started = fallStart
		if not started then
			return
		end
		local progress = math.clamp((now - started) / math.max(fallSeconds, 0.05), 0, 1)
		model:PivotTo(sky:Lerp(base, progress * progress))
		if progress < 1 then
			return
		end
		if connection then
			connection:Disconnect()
		end
		if stopTrail then
			stopTrail()
		end
		model:PivotTo(base)
		FallEffects.Play(
			GeodeFallConfig.ImpactKey,
			ground,
			StarterEggConfig.Color,
			StarterEggConfig.EffectScale
		)
		FallEffects.SoundAt(GeodeFallConfig.LandSoundKey, base.Position)
		FallEffects.ShakeCamera(base.Position, StarterEggConfig.ShakeStuds, StarterEggConfig.ShakeSeconds)
		addIdle(eggTrove, model, base, ground)
	end)
	if connection then
		eggTrove:Add(connection)
	end
end

local function teardown(instance: Instance)
	local eggTrove = if instance:IsA("Model") then actives[instance] else nil
	if not eggTrove then
		return
	end
	actives[instance :: Model] = nil
	eggTrove:Destroy()
end

function StarterEggController.Init(_self: any, _registry: { [string]: any }) end

function StarterEggController.Start(_self: any)
	for _, tagged in CollectionService:GetTagged(StarterEggConfig.Tag) do
		task.spawn(setup, tagged)
	end
	trove:Connect(CollectionService:GetInstanceAddedSignal(StarterEggConfig.Tag), setup)
	trove:Connect(CollectionService:GetInstanceRemovedSignal(StarterEggConfig.Tag), teardown)
end

function StarterEggController.Destroy(_self: any)
	for model in table.clone(actives) do
		teardown(model)
	end
	trove:Destroy()
end

return StarterEggController
