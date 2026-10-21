--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local GeodeFallConfig = require(ReplicatedStorage.Config.GeodeFallConfig)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Packets = require(ReplicatedStorage.Packets)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local Typography = require(ReplicatedStorage.Utils.Typography)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFX.Emit) :: any
local Effects = require(script.Parent.Effects)

type TroveInstance = typeof(Trove.new())
type Active = {
	Id: number,
	Model: Model,
	Part: BasePart,
	Trove: any,
	LandTrove: any,
	Prompt: ProximityPrompt,
	Color: Color3,
	IsUp: boolean,
	IsDone: boolean,
}

local GeodeFall = {}

local soundSeconds = 8

local function numberAttribute(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function tintSequence(sequence: ColorSequence, color: Color3): ColorSequence
	local keypoints = {}
	for _, keypoint in sequence.Keypoints do
		local value = keypoint.Value
		local spread = math.max(value.R, value.G, value.B) - math.min(value.R, value.G, value.B)
		table.insert(
			keypoints,
			ColorSequenceKeypoint.new(
				keypoint.Time,
				if spread >= GeodeFallConfig.TintSaturation then color else value
			)
		)
	end
	return ColorSequence.new(keypoints)
end

local function tint(root: Instance, color: Color3)
	for _, item in root:GetDescendants() do
		if item:GetAttribute(GeodeFallConfig.TintAttribute) ~= true then
			continue
		end
		if item:IsA("ParticleEmitter") then
			item.Color = tintSequence(item.Color, color)
		elseif item:IsA("Trail") then
			item.Color = tintSequence(item.Color, color)
		elseif item:IsA("Beam") then
			item.Color = tintSequence(item.Color, color)
		elseif item:IsA("Light") then
			item.Color = color
		end
	end
end

local function playEffect(key: string, cframe: CFrame, color: Color3)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	tint(asset, color)
	VFXEmit.play(asset, cframe)
	asset:Destroy()
end

local function addMeteor(trove: TroveInstance, part: BasePart): () -> ()
	local asset = AssetRegistry.get(GeodeFallConfig.MeteorKey)
	local root = if asset:IsA("Model") then asset.PrimaryPart or asset:FindFirstChild("Root") else nil
	if not root then
		asset:Destroy()
		return function() end
	end
	local moved: { Instance } = {}
	for _, child in root:GetChildren() do
		child.Parent = part
		trove:Add(child)
		table.insert(moved, child)
		for _, item in child:GetDescendants() do
			if item:IsA("ParticleEmitter") then
				item.Enabled = true
			end
		end
	end
	asset:Destroy()
	return function()
		for _, child in moved do
			for _, item in child:GetDescendants() do
				if item:IsA("ParticleEmitter") then
					item.Enabled = false
				end
			end
		end
	end
end

local function soundAt(key: string, position: Vector3)
	local sound = AssetRegistry.get(key)
	if not sound:IsA("Sound") then
		sound:Destroy()
		return
	end
	local anchor = Instance.new("Attachment")
	anchor.WorldPosition = position
	anchor.Parent = workspace.Terrain
	sound.Parent = anchor
	sound:Play()
	task.delay(soundSeconds, function()
		anchor:Destroy()
	end)
end

local function shakeCamera(position: Vector3)
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not root or not root:IsA("BasePart") or not humanoid then
		return
	end
	if (root.Position - position).Magnitude > GeodeFallConfig.ShakeDistance then
		return
	end
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local progress = (os.clock() - started) / GeodeFallConfig.ShakeSeconds
		if progress >= 1 or not humanoid.Parent then
			connection:Disconnect()
			humanoid.CameraOffset = Vector3.zero
			return
		end
		local studs = GeodeFallConfig.ShakeStuds * (1 - progress)
		humanoid.CameraOffset = Vector3.new(
			(math.random() * 2 - 1) * studs,
			(math.random() * 2 - 1) * studs,
			(math.random() * 2 - 1) * studs
		)
	end)
end

local function groundOf(target: CFrame): CFrame
	return CFrame.new(target.Position + Vector3.new(0, RockSpawnConfig.SinkStuds, 0))
end

local function addIdle(trove: TroveInstance, ground: CFrame, color: Color3)
	local asset = AssetRegistry.get(GeodeFallConfig.IdleKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	tint(asset, color)
	local top = asset:FindFirstChild(GeodeFallConfig.PillarTopName, true)
	if top and top:IsA("Attachment") then
		top.Position = Vector3.new(0, GeodeFallConfig.PillarHeightStuds, 0)
	end
	asset:PivotTo(ground)
	asset.Parent = workspace
	trove:Add(asset)
end

local function paint(label: TextLabel?, color: Color3)
	if not label then
		return
	end
	local light = color:Lerp(Color3.new(1, 1, 1), GeodeFallConfig.LabelLightLerp)
	local dark = color:Lerp(Color3.new(0, 0, 0), GeodeFallConfig.LabelDarkLerp)
	local gradient = label:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color),
			ColorSequenceKeypoint.new(0.5, light),
			ColorSequenceKeypoint.new(1, color),
		})
	end
	local stroke = label:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Color = dark
	end
end

local function findLabel(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name, true)
	return if found and found:IsA("TextLabel") then found else nil
end

local function claimText(part: BasePart): string
	local name = part:GetAttribute(GeodeFallConfig.ClaimedNameAttribute)
	if type(name) == "string" and name ~= "" then
		return string.format(GeodeFallConfig.ClaimedLabelText, name)
	end
	return GeodeFallConfig.FreeText
end

local function makeLabel(trove: TroveInstance, state: Active)
	local asset = AssetRegistry.get(GeodeFallConfig.LabelKey)
	if not asset:IsA("BillboardGui") then
		asset:Destroy()
		return
	end
	local part = state.Part
	local nameLabel = findLabel(asset, "NameLabel")
	local timeLabel = findLabel(asset, "TimeLabel")
	local fillInstance = asset:FindFirstChild("Fill", true)
	local fill: GuiObject? = if fillInstance and fillInstance:IsA("GuiObject") then fillInstance else nil
	Typography.Apply(asset)
	asset.Adornee = part
	asset.MaxDistance = GeodeFallConfig.LabelMaxDistance
	asset.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + GeodeFallConfig.LabelHeightAboveGeode, 0)
	paint(nameLabel, state.Color)
	paint(timeLabel, state.Color)
	if fill then
		local gradient = fill:FindFirstChildWhichIsA("UIGradient")
		if gradient then
			gradient.Color = ColorSequence.new(state.Color)
		end
		fill.BackgroundColor3 = state.Color
	end
	asset.Parent = part
	trove:Add(asset)

	local shownName = ""
	local shownTime = -1
	trove:Connect(RunService.Heartbeat, function()
		local text = claimText(part)
		if nameLabel and text ~= shownName then
			shownName = text
			nameLabel.Text = text
		end
		local maxHealth = numberAttribute(part, GeodeFallConfig.MaxHealthAttribute)
		if fill and maxHealth > 0 then
			fill.Size = UDim2.fromScale(
				math.clamp(numberAttribute(part, GeodeFallConfig.HealthAttribute) / maxHealth, 0, 1),
				1
			)
		end
		local remaining = if state.IsDone
			then 0
			else math.max(
				0,
				math.ceil(
					numberAttribute(part, GeodeFallConfig.EndsAtAttribute) - workspace:GetServerTimeNow()
				)
			)
		if timeLabel and remaining ~= shownTime then
			shownTime = remaining
			timeLabel.Text = string.format("%d:%02d", remaining // 60, remaining % 60)
		end
	end)
end

function GeodeFall.Start(trove: TroveInstance, chopController: any)
	local actives: { [Model]: Active } = {}
	local byId: { [number]: Active } = {}

	local function refreshPrompt(state: Active)
		local claimedBy = numberAttribute(state.Part, GeodeFallConfig.ClaimedByAttribute)
		state.Prompt.Enabled = state.IsUp
			and not state.IsDone
			and not chopController:IsMinigameActive()
			and (claimedBy == 0 or claimedBy == Players.LocalPlayer.UserId)
	end

	local function refreshAll()
		for _, state in actives do
			refreshPrompt(state)
		end
	end

	local function teardown(model: Instance)
		local state = if model:IsA("Model") then actives[model] else nil
		if not state then
			return
		end
		actives[state.Model] = nil
		if byId[state.Id] == state then
			byId[state.Id] = nil
		end
		state.Trove:Destroy()
	end

	local function land(state: Active, ground: CFrame)
		if state.IsDone or not state.Part.Parent then
			return
		end
		state.IsUp = true
		addIdle(state.LandTrove, ground, state.Color)
		makeLabel(state.LandTrove, state)
		refreshPrompt(state)
	end

	local function finish(state: Active)
		state.IsDone = true
		state.LandTrove:Clean()
		refreshPrompt(state)
	end

	local function setup(model: Instance)
		if not model:IsA("Model") or actives[model] then
			return
		end
		local found = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		if not found then
			return
		end
		local part = found
		local id = numberAttribute(part, GeodeFallConfig.IdAttribute)
		local zone = part:GetAttribute(GeodeFallConfig.ZoneAttribute)
		local color = if type(zone) == "string"
			then GeodeFallConfig.ZoneColors[zone] or GeodeFallConfig.DefaultColor
			else GeodeFallConfig.DefaultColor
		local geodeTrove = Trove.new()
		local landTrove = geodeTrove:Extend()
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Chop"
		prompt.ObjectText = GeodeFallConfig.DisplayName
		prompt.HoldDuration = ChopConfig.PromptHoldSeconds
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.MaxActivationDistance = ChopConfig.PromptRangeStuds + math.max(part.Size.X, part.Size.Z) / 2
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = part
		geodeTrove:Add(prompt)
		local state: Active = {
			Id = id,
			Model = model,
			Part = part,
			Trove = geodeTrove,
			LandTrove = landTrove,
			Prompt = prompt,
			Color = color,
			IsUp = false,
			IsDone = false,
		}
		actives[model] = state
		byId[id] = state
		geodeTrove:Connect(prompt.Triggered, function()
			if state.IsUp and not state.IsDone then
				Packets.GeodeFallChop:Fire(id)
			end
		end)
		geodeTrove:Connect(part:GetAttributeChangedSignal(GeodeFallConfig.ClaimedByAttribute), function()
			refreshPrompt(state)
		end)
		local isSunk = false
		geodeTrove:Connect(RunService.Heartbeat, function()
			if isSunk or state.IsDone or not state.IsUp then
				return
			end
			if numberAttribute(part, GeodeFallConfig.EndsAtAttribute) - workspace:GetServerTimeNow() > 0 then
				return
			end
			isSunk = true
			finish(state)
			Effects.Sink(part, GeodeFallConfig.SinkSeconds, function() end)
		end)

		local target = model:GetPivot()
		local ground = groundOf(target)
		local untilLand = numberAttribute(part, GeodeFallConfig.LandsAtAttribute)
			- workspace:GetServerTimeNow()
		if untilLand <= 0 then
			land(state, ground)
			return
		end
		local sky = target + Vector3.new(0, GeodeFallConfig.FallHeightStuds, 0)
		model:PivotTo(sky)
		playEffect(GeodeFallConfig.MarkerKey, ground, color)
		local markerStart = os.clock()
		local markerSeconds = math.max(untilLand, 0.1)
		local fallSeconds = math.min(GeodeFallConfig.FallSeconds, untilLand)
		local stopTrail: (() -> ())? = nil
		local fallStart: number? = nil
		local connection: RBXScriptConnection? = nil
		connection = RunService.RenderStepped:Connect(function()
			local now = os.clock()
			if not fallStart and now - markerStart >= markerSeconds - fallSeconds then
				fallStart = now
				stopTrail = addMeteor(geodeTrove, part)
				soundAt(GeodeFallConfig.FallSoundKey, target.Position)
			end
			local started = fallStart
			if not started then
				return
			end
			local progress = math.clamp((now - started) / math.max(fallSeconds, 0.05), 0, 1)
			model:PivotTo(sky:Lerp(target, progress * progress))
			if progress < 1 then
				return
			end
			if connection then
				connection:Disconnect()
			end
			if stopTrail then
				stopTrail()
			end
			model:PivotTo(target)
			playEffect(GeodeFallConfig.ImpactKey, ground, color)
			soundAt(GeodeFallConfig.LandSoundKey, target.Position)
			shakeCamera(target.Position)
			land(state, ground)
		end)
		if connection then
			geodeTrove:Add(connection)
		end
	end

	local function onChopped(id: number, quality: number, isBroken: boolean)
		local state = byId[id]
		if not state then
			return
		end
		local part = state.Part
		if isBroken then
			finish(state)
		end
		if quality == ChopQuality.Crack then
			Effects.Crack(part)
			return
		end
		if quality == ChopQuality.Master then
			Effects.MasterStart(part)
			task.delay(MasterChopConfig.ImpactDelaySeconds, function()
				if part.Parent then
					Effects.Hit(part, quality)
				end
			end)
			return
		end
		Effects.Hit(part, quality)
	end

	for _, tagged in CollectionService:GetTagged(GeodeFallConfig.Tag) do
		task.spawn(setup, tagged)
	end
	trove:Connect(CollectionService:GetInstanceAddedSignal(GeodeFallConfig.Tag), setup)
	trove:Connect(CollectionService:GetInstanceRemovedSignal(GeodeFallConfig.Tag), teardown)
	trove:Add(Packets.GeodeFallChopped.OnClientEvent:Connect(onChopped))
	trove:Connect(chopController.ActiveChanged, refreshAll)
	trove:Add(function()
		for model in table.clone(actives) do
			teardown(model)
		end
	end)
end

return GeodeFall
