--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local EggLuck = require(ReplicatedStorage.Utils.EggLuck)
local GeodeFallConfig = require(ReplicatedStorage.Config.GeodeFallConfig)
local Packets = require(ReplicatedStorage.Packets)
local PromptStat = require(ReplicatedStorage.Utils.PromptStat)
local PromptStatConfig = require(ReplicatedStorage.Config.PromptStatConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local Typography = require(ReplicatedStorage.Utils.Typography)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FallEffects = require(ReplicatedStorage.Utils.FallEffects)
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

local function numberAttribute(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function groundOf(target: CFrame): CFrame
	return CFrame.new(target.Position + Vector3.new(0, RockSpawnConfig.SinkStuds, 0))
end

local function luckText(part: BasePart): string?
	local luck = part:GetAttribute(GeodeFallConfig.LuckAttribute)
	return if type(luck) == "number" then EggLuck.Text(luck) else nil
end

local function findLabel(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name, true)
	return if found and found:IsA("TextLabel") then found else nil
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
	local bar = asset:FindFirstChild("Bar")
	if bar and bar:IsA("GuiObject") then
		bar.Visible = false
	end
	Typography.Apply(asset)
	asset.Adornee = part
	asset.MaxDistance = GeodeFallConfig.LabelMaxDistance
	asset.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + GeodeFallConfig.LabelHeightAboveGeode, 0)
	FallEffects.PaintLabel(nameLabel, state.Color)
	FallEffects.PaintLabel(timeLabel, state.Color)
	if nameLabel then
		local luck = luckText(part)
		nameLabel.Text = if luck then `{GeodeFallConfig.DisplayName} {luck}` else GeodeFallConfig.DisplayName
	end
	asset.Parent = part
	trove:Add(asset)

	local shownTime = -1
	trove:Connect(RunService.Heartbeat, function()
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
		state.Prompt.Enabled = state.IsUp and not state.IsDone and not chopController:IsMinigameActive()
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
		FallEffects.AddIdle(state.LandTrove, ground, state.Color)
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
		prompt.ActionText = GeodeFallConfig.PromptText
		prompt.ObjectText = PromptStat.Text(
			luckText(part) or PromptStatConfig.FallingEggStat,
			"Luck",
			GeodeFallConfig.DisplayName
		)
		prompt.HoldDuration = GeodeFallConfig.PromptHoldSeconds
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
				Packets.GeodeFallTake:Fire(id)
			end
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
		FallEffects.Play(GeodeFallConfig.MarkerKey, ground, color)
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
				stopTrail = FallEffects.AddMeteor(geodeTrove, part)
				FallEffects.SoundAt(GeodeFallConfig.FallSoundKey, target.Position)
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
			FallEffects.Play(GeodeFallConfig.ImpactKey, ground, color)
			FallEffects.SoundAt(GeodeFallConfig.LandSoundKey, target.Position)
			FallEffects.ShakeCamera(target.Position)
			land(state, ground)
		end)
		if connection then
			geodeTrove:Add(connection)
		end
	end

	local function onTaken(id: number)
		local state = byId[id]
		if state and not state.IsDone then
			finish(state)
			Effects.Sink(state.Part, GeodeFallConfig.SinkSeconds, function() end)
		end
	end

	for _, tagged in CollectionService:GetTagged(GeodeFallConfig.Tag) do
		task.spawn(setup, tagged)
	end
	trove:Connect(CollectionService:GetInstanceAddedSignal(GeodeFallConfig.Tag), setup)
	trove:Connect(CollectionService:GetInstanceRemovedSignal(GeodeFallConfig.Tag), teardown)
	trove:Add(Packets.GeodeFallTaken.OnClientEvent:Connect(onTaken))
	trove:Connect(chopController.ActiveChanged, refreshAll)
	trove:Add(function()
		for model in table.clone(actives) do
			teardown(model)
		end
	end)
end

return GeodeFall
