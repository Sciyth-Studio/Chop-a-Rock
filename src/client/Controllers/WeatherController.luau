--!strict

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local SettingsConfig = require(ReplicatedStorage.Config.SettingsConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFXEmit) :: any
local WeatherClock = require(ReplicatedStorage.WeatherClock)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)

type TroveInstance = typeof(Trove.new())

local ROCK_TAG = "ChopRock"
local SUN_PART_NAME = "Sun"
local SUN_DISTANCE = 900

local WeatherController = {
	Name = "WeatherController",
	_trove = nil :: TroveInstance?,
}

local targets: { [string]: Instance } = {}
local baseline: { [Instance]: { [string]: any } } = {}
local currentKey = ""
local eventTrove: TroveInstance? = nil
local flash: ColorCorrectionEffect? = nil
local random = Random.new()

local function resolve(name: string): Instance?
	if name == "Lighting" then
		return Lighting
	end
	local found = Lighting:FindFirstChild(name)
	return found
end

local function captureBaseline()
	for _, event in WeatherConfig.Events do
		for name, values in event.Look do
			local instance = targets[name] or resolve(name)
			if not instance then
				warn(`[WeatherController] Lighting has no "{name}"; that part of the look is skipped`)
				continue
			end
			targets[name] = instance
			local saved = baseline[instance] or {}
			baseline[instance] = saved
			for property in values do
				if saved[property] == nil then
					saved[property] = (instance :: any)[property]
				end
			end
		end
	end
end

local function tweenLook(event: WeatherConfig.Event?)
	local info =
		TweenInfo.new(WeatherConfig.LookTweenSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	for name, instance in targets do
		local saved = baseline[instance]
		if not saved then
			continue
		end
		local overrides = if event then event.Look[name] else nil
		local goal: { [string]: any } = {}
		for property, value in saved do
			goal[property] = if overrides and overrides[property] ~= nil then overrides[property] else value
		end
		TweenService:Create(instance, info, goal):Play()
	end
end

local function setEmitters(root: Instance, isOn: boolean)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = isOn
		end
	end
end

local function startRig(trove: TroveInstance, key: string)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Model") and not asset:IsA("BasePart") then
		asset:Destroy()
		return
	end
	local rig = asset :: PVInstance
	rig.Name = WeatherConfig.CameraParticlesName
	for _, descendant in rig:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	local sunInstance = rig:FindFirstChild(SUN_PART_NAME, true)
	local sun: BasePart? = if sunInstance and sunInstance:IsA("BasePart") then sunInstance else nil
	local camera = workspace.CurrentCamera
	rig.Parent = camera
	trove:Add(rig)
	local function refreshGraphics()
		setEmitters(rig, not LowGraphics.IsOn())
	end
	refreshGraphics()
	local player = Players.LocalPlayer
	if player then
		trove:Connect(player:GetAttributeChangedSignal(SettingsConfig.LowGraphicsAttribute), refreshGraphics)
	end
	trove:Connect(RunService.RenderStepped, function()
		local position = workspace.CurrentCamera.CFrame.Position
		rig:PivotTo(CFrame.new(position + WeatherConfig.CameraParticlesOffset))
		if sun then
			local spot = position + Lighting:GetSunDirection() * SUN_DISTANCE
			sun.CFrame = CFrame.lookAt(spot, position)
		end
	end)
end

local function startSound(trove: TroveInstance, key: string)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") or asset.SoundId == "" then
		asset:Destroy()
		return
	end
	local sound = asset :: Sound
	local volume = sound.Volume
	sound.Looped = true
	sound.Volume = 0
	sound.Parent = workspace.CurrentCamera
	sound:Play()
	local fade = TweenInfo.new(WeatherConfig.SoundFadeSeconds)
	TweenService:Create(sound, fade, { Volume = volume }):Play()
	trove:Add(function()
		TweenService:Create(sound, fade, { Volume = 0 }):Play()
		task.delay(WeatherConfig.SoundFadeSeconds, function()
			sound:Destroy()
		end)
	end)
end

local function groundBelow(position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = { workspace.CurrentCamera }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(exclude, player.Character)
		end
	end
	params.FilterDescendantsInstances = exclude
	local origin = position + Vector3.new(0, 300, 0)
	local hit = workspace:Raycast(origin, Vector3.new(0, -800, 0), params)
	return if hit then hit.Position else position
end

local function strike()
	local camera = workspace.CurrentCamera
	if flash then
		flash.Brightness = WeatherConfig.LightningFlashBrightness
		TweenService:Create(flash, TweenInfo.new(WeatherConfig.LightningFlashSeconds), { Brightness = 0 })
			:Play()
	end
	local angle = random:NextNumber(0, math.pi * 2)
	local distance =
		random:NextNumber(WeatherConfig.LightningRadiusStuds * 0.3, WeatherConfig.LightningRadiusStuds)
	local position = groundBelow(
		camera.CFrame.Position + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
	)
	local asset = AssetRegistry.get(WeatherConfig.LightningBoltKey)
	if asset:IsA("Model") then
		asset:PivotTo(CFrame.new(position))
		asset.Parent = workspace
		VFXEmit.emit(asset, {
			onDone = function()
				asset:Destroy()
			end,
		})
	else
		asset:Destroy()
	end
	task.delay(WeatherConfig.ThunderDelaySeconds, LocalSound.Play, WeatherConfig.ThunderSoundKey)
end

local function startLightning(trove: TroveInstance)
	local isRunning = true
	trove:Add(function()
		isRunning = false
	end)
	task.spawn(function()
		while isRunning do
			task.wait(random:NextNumber(WeatherConfig.LightningMinSeconds, WeatherConfig.LightningMaxSeconds))
			if isRunning then
				strike()
			end
		end
	end)
end

local function decorateRock(trove: TroveInstance, modifier: WeatherConfig.Modifier, part: Instance)
	if not part:IsA("BasePart") then
		return
	end
	local template = AssetRegistry.get(modifier.VFXKey)
	local emitters: { ParticleEmitter } = {}
	for _, child in template:GetChildren() do
		if child:IsA("ParticleEmitter") then
			local emitter = child:Clone()
			emitter.Name = WeatherConfig.RockVFXName
			emitter.Parent = part
			table.insert(emitters, emitter)
		end
	end
	template:Destroy()
	trove:Add(function()
		for _, emitter in emitters do
			emitter:Destroy()
		end
	end)
end

local function startRocks(trove: TroveInstance, event: WeatherConfig.Event)
	local modifier = WeatherConfig.Modifiers[event.Modifier]
	if not modifier then
		return
	end
	local rockTroves: { [Instance]: TroveInstance } = {}
	local function added(part: Instance)
		if rockTroves[part] then
			return
		end
		local rockTrove = Trove.new()
		rockTroves[part] = rockTrove
		decorateRock(rockTrove, modifier, part)
	end
	local function removed(part: Instance)
		local rockTrove = rockTroves[part]
		rockTroves[part] = nil
		if rockTrove then
			rockTrove:Destroy()
		end
	end
	for _, part in CollectionService:GetTagged(ROCK_TAG) do
		added(part)
	end
	trove:Connect(CollectionService:GetInstanceAddedSignal(ROCK_TAG), added)
	trove:Connect(CollectionService:GetInstanceRemovedSignal(ROCK_TAG), removed)
	trove:Add(function()
		for part in rockTroves do
			removed(part)
		end
	end)
end

local function apply(isFresh: boolean)
	local value = workspace:GetAttribute(WeatherConfig.WeatherAttribute)
	local key = if type(value) == "string" then value else ""
	if key == currentKey then
		return
	end
	currentKey = key
	if eventTrove then
		eventTrove:Destroy()
		eventTrove = nil
	end
	local event = if key ~= "" then WeatherClock.Event(key) else nil
	tweenLook(event)
	if not event then
		return
	end
	local trove = Trove.new()
	eventTrove = trove
	startRig(trove, event.ParticlesKey)
	startSound(trove, event.SoundKey)
	startRocks(trove, event)
	if event.HasLightning then
		startLightning(trove)
	end
	if isFresh then
		LocalSound.Play(WeatherConfig.StartSoundKey)
	end
end

function WeatherController.GetActive(_self: any): WeatherConfig.Event?
	return if currentKey ~= "" then WeatherClock.Event(currentKey) else nil
end

function WeatherController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function WeatherController.Start(self: any)
	local trove = self._trove :: TroveInstance
	captureBaseline()
	local created = Instance.new("ColorCorrectionEffect")
	created.Name = "WeatherFlash"
	created.Brightness = 0
	created.Parent = Lighting
	flash = created
	trove:Add(created)
	trove:Connect(workspace:GetAttributeChangedSignal(WeatherConfig.WeatherAttribute), function()
		apply(true)
	end)
	apply(false)
	trove:Add(function()
		if eventTrove then
			eventTrove:Destroy()
			eventTrove = nil
		end
		currentKey = ""
		tweenLook(nil)
	end)
end

function WeatherController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return WeatherController
