--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local HotStreakConfig = require(ReplicatedStorage.Config.HotStreakConfig)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

type CameraFx = {
	Start: number,
	BaseFov: number,
	FovDegrees: number,
	ShakeStuds: number,
	Applied: CFrame,
}

local CAMERA_STEP = "HotStreakCameraFx"

local HotStreakController = {
	Name = "HotStreakController",
	Changed = nil :: any,
	TierUp = nil :: any,
	Dropped = nil :: any,
	_trove = nil :: TroveInstance?,
}

local controllers: { [string]: any } = {}
local fireTemplate: Attachment? = nil
local fires: { [Player]: { Attachment: Attachment, Tier: number } } = {}
local playerTroves: { [Player]: TroveInstance } = {}
local warnedSounds: { [string]: true } = {}
local loopSound: Sound? = nil
local loopBaseVolume = 0
local loopTween: Tween? = nil
local lastTier = 0
local lastCount = 0
local expiresAt = 0
local isEvaluateQueued = false
local pendingTier = 0
local pendingDrop = false
local pendingToken = 0
local cameraFx: CameraFx? = nil

local function readNumber(player: Player, attribute: string): number
	local value = player:GetAttribute(attribute)
	return if type(value) == "number" then value else 0
end

local function fxScale(): number
	return if LowGraphics.IsOn() then HotStreakConfig.LowGraphicsFxScale else 1
end

local function loadSound(key: string): Sound?
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return nil
	end
	if asset.SoundId == "" then
		if not warnedSounds[key] then
			warnedSounds[key] = true
			warn(`[HotStreakController] {key} has no SoundId; skipping`)
		end
		asset:Destroy()
		return nil
	end
	return asset
end

local function scaleSequence(sequence: NumberSequence, scale: number): NumberSequence
	local keypoints: { NumberSequenceKeypoint } = {}
	for _, keypoint in sequence.Keypoints do
		table.insert(
			keypoints,
			NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * scale, keypoint.Envelope * scale)
		)
	end
	return NumberSequence.new(keypoints)
end

local function removeFire(player: Player)
	local fire = fires[player]
	if fire then
		fires[player] = nil
		fire.Attachment:Destroy()
	end
end

local function applyFire(player: Player)
	local tier = readNumber(player, HotStreakConfig.TierAttribute)
	local definition = HotStreakConfig.Tiers[tier]
	local character = player.Character
	local head = if character then character:FindFirstChild("Head") else nil
	local template = fireTemplate
	if not definition or not template or not head or not head:IsA("BasePart") then
		removeFire(player)
		return
	end
	local existing = fires[player]
	if existing and existing.Tier == tier and existing.Attachment.Parent == head then
		return
	end
	removeFire(player)
	local attachment = template:Clone()
	local scale = definition.FireScale
	local emitScale = if player == Players.LocalPlayer then 1 else LowGraphics.EmitScale()
	for _, descendant in attachment:GetDescendants() do
		if not descendant:IsA("ParticleEmitter") then
			continue
		end
		descendant.Size = scaleSequence(descendant.Size, scale)
		descendant.Speed = NumberRange.new(descendant.Speed.Min * scale, descendant.Speed.Max * scale)
		descendant.Rate = descendant.Rate * scale * emitScale
		if descendant.Name == HotStreakConfig.FlameEmitter then
			descendant.Color = ColorSequence.new(definition.Main)
		elseif descendant.Name == HotStreakConfig.FlameBackEmitter then
			descendant.Color = ColorSequence.new(definition.Dark)
		elseif descendant.Name == HotStreakConfig.EmbersEmitter then
			descendant.Color = ColorSequence.new(definition.Light)
		end
	end
	attachment.Position = Vector3.new(
		attachment.Position.X,
		HotStreakConfig.FireBaseHeight + HotStreakConfig.FireHeightPerScale * scale,
		attachment.Position.Z
	)
	attachment.Parent = head
	fires[player] = { Attachment = attachment, Tier = tier }
end

local function trackPlayer(player: Player)
	if playerTroves[player] then
		return
	end
	local trove = Trove.new()
	playerTroves[player] = trove
	trove:Connect(player:GetAttributeChangedSignal(HotStreakConfig.TierAttribute), function()
		applyFire(player)
	end)
	trove:Connect(player.CharacterAdded, function(character: Model)
		character:WaitForChild("Head", 10)
		applyFire(player)
	end)
	trove:Add(function()
		removeFire(player)
	end)
	task.spawn(applyFire, player)
end

local function untrackPlayer(player: Player)
	local trove = playerTroves[player]
	if trove then
		playerTroves[player] = nil
		trove:Destroy()
	end
end

local function updateLoop(tier: number)
	local definition = HotStreakConfig.Tiers[tier]
	if loopTween then
		loopTween:Cancel()
		loopTween = nil
	end
	if not definition then
		local ending = loopSound
		if ending then
			loopSound = nil
			local fade =
				TweenService:Create(ending, TweenInfo.new(HotStreakConfig.LoopFadeOutSeconds), { Volume = 0 })
			fade.Completed:Once(function()
				ending:Destroy()
			end)
			fade:Play()
		end
		return
	end
	if not loopSound then
		local created = loadSound(HotStreakConfig.LoopSoundKey)
		if not created then
			return
		end
		loopBaseVolume = created.Volume
		created.Looped = true
		created.Volume = 0
		created.Parent = SoundService
		created:Play()
		loopSound = created
	end
	local sound = loopSound :: Sound
	sound.PlaybackSpeed = definition.LoopPlaybackSpeed
	local fade = TweenService:Create(
		sound,
		TweenInfo.new(HotStreakConfig.LoopFadeInSeconds),
		{ Volume = loopBaseVolume * definition.LoopVolumeScale }
	)
	loopTween = fade
	fade:Play()
end

local function playUpSound()
	local sound = loadSound(HotStreakConfig.UpSoundKey)
	if not sound then
		return
	end
	SoundService:PlayLocalSound(sound)
	task.delay(5, function()
		sound:Destroy()
	end)
end

local function stopCameraFx()
	RunService:UnbindFromRenderStep(CAMERA_STEP)
	local fx = cameraFx
	cameraFx = nil
	local camera = workspace.CurrentCamera
	if fx and camera then
		camera.CFrame = camera.CFrame * fx.Applied:Inverse()
		camera.FieldOfView = fx.BaseFov
	end
end

local function stepCameraFx()
	local fx = cameraFx
	local camera = workspace.CurrentCamera
	if not fx or not camera then
		stopCameraFx()
		return
	end
	local elapsed = os.clock() - fx.Start
	local total = math.max(
		HotStreakConfig.FovPunchInSeconds + HotStreakConfig.FovPunchOutSeconds,
		HotStreakConfig.ShakeSeconds
	)
	if elapsed >= total then
		stopCameraFx()
		return
	end
	camera.CFrame = camera.CFrame * fx.Applied:Inverse()
	local curve = if elapsed < HotStreakConfig.FovPunchInSeconds
		then elapsed / HotStreakConfig.FovPunchInSeconds
		else math.max(
			0,
			1 - (elapsed - HotStreakConfig.FovPunchInSeconds) / HotStreakConfig.FovPunchOutSeconds
		)
	camera.FieldOfView = fx.BaseFov + fx.FovDegrees * curve
	local decay = math.max(0, 1 - elapsed / HotStreakConfig.ShakeSeconds) * fx.ShakeStuds
	fx.Applied = CFrame.new(
		(math.random() * 2 - 1) * decay,
		(math.random() * 2 - 1) * decay,
		(math.random() * 2 - 1) * decay
	)
	camera.CFrame = camera.CFrame * fx.Applied
end

local function playCameraFx(definition: HotStreakConfig.Tier)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local scale = fxScale()
	local active = cameraFx
	if active then
		active.Start = os.clock()
		active.FovDegrees = definition.FovPunchDegrees * scale
		active.ShakeStuds = definition.ShakeStuds * scale
		return
	end
	cameraFx = {
		Start = os.clock(),
		BaseFov = camera.FieldOfView,
		FovDegrees = definition.FovPunchDegrees * scale,
		ShakeStuds = definition.ShakeStuds * scale,
		Applied = CFrame.identity,
	}
	RunService:BindToRenderStep(CAMERA_STEP, Enum.RenderPriority.Camera.Value + 1, stepCameraFx)
end

local function flush(self: any)
	pendingToken += 1
	local tier = pendingTier
	local isDrop = pendingDrop
	pendingTier = 0
	pendingDrop = false
	local definition = HotStreakConfig.Tiers[tier]
	if definition then
		playUpSound()
		playCameraFx(definition)
		self.TierUp:Fire(tier)
	elseif isDrop then
		self.Dropped:Fire()
	end
end

local function evaluate(self: any)
	isEvaluateQueued = false
	local player = Players.LocalPlayer
	local tier = readNumber(player, HotStreakConfig.TierAttribute)
	local count = readNumber(player, HotStreakConfig.CountAttribute)
	expiresAt = readNumber(player, HotStreakConfig.ExpiresAtAttribute)
	local isUp = tier > lastTier
	local isDrop = count < lastCount and count > 0
	if tier ~= lastTier then
		updateLoop(tier)
	end
	lastTier = tier
	lastCount = count
	self.Changed:Fire(tier, count, expiresAt)
	if not isUp and not isDrop then
		return
	end
	if isUp then
		pendingTier = tier
		pendingDrop = false
	else
		pendingDrop = true
	end
	local chop = controllers.ChopController
	if chop and chop:IsMinigameActive() then
		pendingToken += 1
		local token = pendingToken
		task.delay(HotStreakConfig.PendingFallbackSeconds, function()
			if token == pendingToken and (pendingTier > 0 or pendingDrop) then
				flush(self)
			end
		end)
	else
		flush(self)
	end
end

local function queueEvaluate(self: any)
	if isEvaluateQueued then
		return
	end
	isEvaluateQueued = true
	task.defer(evaluate, self)
end

function HotStreakController.GetTier(_self: any): number
	return lastTier
end

function HotStreakController.GetCount(_self: any): number
	return lastCount
end

function HotStreakController.GetExpiresAt(_self: any): number
	return expiresAt
end

function HotStreakController.Init(self: any, registry: { [string]: any })
	controllers = registry
	self._trove = Trove.new()
	self.Changed = Signal.new()
	self.TierUp = Signal.new()
	self.Dropped = Signal.new()
end

function HotStreakController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local asset = AssetRegistry.get(HotStreakConfig.FireAssetKey)
	local attachment = asset:FindFirstChild(HotStreakConfig.FireAttachmentName, true)
	if attachment and attachment:IsA("Attachment") then
		fireTemplate = attachment
		trove:Add(asset)
	else
		asset:Destroy()
		warn(
			`[HotStreakController] {HotStreakConfig.FireAssetKey} has no {HotStreakConfig.FireAttachmentName}`
		)
	end

	local player = Players.LocalPlayer
	local watched =
		{ HotStreakConfig.TierAttribute, HotStreakConfig.CountAttribute, HotStreakConfig.ExpiresAtAttribute }
	for _, attribute in watched do
		trove:Connect(player:GetAttributeChangedSignal(attribute), function()
			queueEvaluate(self)
		end)
	end
	local chop = controllers.ChopController
	if chop then
		trove:Add(chop.ResultShown:Connect(function()
			if pendingTier > 0 or pendingDrop then
				flush(self)
			end
		end))
	else
		warn("[HotStreakController] ChopController missing; effects will not sync to the chop impact")
	end
	trove:Connect(Players.PlayerAdded, trackPlayer)
	trove:Connect(Players.PlayerRemoving, untrackPlayer)
	for _, other in Players:GetPlayers() do
		trackPlayer(other)
	end
	trove:Add(function()
		for tracked in playerTroves do
			untrackPlayer(tracked)
		end
		updateLoop(0)
		stopCameraFx()
	end)
	queueEvaluate(self)
end

function HotStreakController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
	for _, name in { "Changed", "TierUp", "Dropped" } do
		if self[name] then
			self[name]:Destroy()
			self[name] = nil
		end
	end
end

return HotStreakController
