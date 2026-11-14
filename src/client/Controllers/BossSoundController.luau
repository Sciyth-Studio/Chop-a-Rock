--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local BossSoundConfig = require(ReplicatedStorage.Config.BossSoundConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local Phases = BossConfig.Phases

local BossSoundController = {
	Name = "BossSoundController",
	_trove = nil :: TroveInstance?,
}

local random = Random.new()
local warned: { [string]: true } = {}

local function numberAttribute(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function isFightPhase(phase: number): boolean
	return phase == Phases.Fighting or phase == Phases.Mad or phase == Phases.Finish
end

local function loadSound(key: string): Sound?
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") or asset.SoundId == "" then
		if not warned[key] then
			warned[key] = true
			warn(`[BossSoundController] {key} is missing or has no SoundId; skipping`)
		end
		asset:Destroy()
		return nil
	end
	return asset
end

local function placeSound(key: string, parent: Instance): Sound?
	local sound = loadSound(key)
	if not sound then
		return nil
	end
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = BossSoundConfig.RollOffMinDistance
	sound.RollOffMaxDistance = BossSoundConfig.RollOffMaxDistance
	sound.Parent = parent
	return sound
end

local function playAt(key: string, parent: Instance, pitchSpread: number?): Sound?
	local sound = placeSound(key, parent)
	if not sound then
		return nil
	end
	if pitchSpread then
		sound.PlaybackSpeed *= 1 + random:NextNumber(-pitchSpread, pitchSpread)
	end
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	task.delay(sound.TimeLength / math.max(sound.PlaybackSpeed, 0.1) + 15, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
	return sound
end

local function playAtPosition(key: string, position: Vector3)
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain
	local sound = playAt(key, attachment)
	if not sound then
		attachment:Destroy()
		return
	end
	sound.Destroying:Once(function()
		attachment:Destroy()
	end)
end

local function startLoop(trove: TroveInstance, key: string, parent: Instance): Sound?
	local sound = placeSound(key, parent)
	if not sound then
		return nil
	end
	local volume = sound.Volume
	sound.Looped = true
	sound.Volume = 0
	sound:Play()
	TweenService:Create(sound, TweenInfo.new(BossSoundConfig.LoopFadeSeconds), { Volume = volume }):Play()
	trove:Add(sound)
	return sound
end

local function stopLoop(sound: Sound?)
	if not sound or not sound.Parent then
		return
	end
	local fade = TweenService:Create(sound, TweenInfo.new(BossSoundConfig.LoopFadeSeconds), { Volume = 0 })
	fade.Completed:Once(function()
		sound:Destroy()
	end)
	fade:Play()
end

local function isNear(root: BasePart): boolean
	local character = Players.LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return false
	end
	return (rootPart.Position - root.Position).Magnitude <= BossSoundConfig.HearDistance
end

local function clipIds(prefix: string): { [string]: string }
	local ids: { [string]: string } = {}
	for _, clip in { "Wake", "Attack", "Stomp", "BigAttack", "Defeat" } do
		local asset = AssetRegistry.get(prefix .. clip)
		if asset:IsA("Animation") and asset.AnimationId ~= "" then
			ids[asset.AnimationId] = clip
		end
		asset:Destroy()
	end
	return ids
end

local function onMarker(
	trove: TroveInstance,
	track: AnimationTrack,
	marker: string,
	fallbackSeconds: number,
	play: () -> ()
)
	local done = false
	local function fire()
		if done then
			return
		end
		done = true
		play()
	end
	trove:Add(track:GetMarkerReachedSignal(marker):Connect(fire))
	trove:Add(task.delay(fallbackSeconds / math.max(track.Speed, 0.1) + 0.2, fire))
end

local function setupBoss(trove: TroveInstance, model: Model)
	local root = model.PrimaryPart or model:WaitForChild("Root", 10)
	if not root or not root:IsA("BasePart") or not model.Parent then
		return
	end
	local key = model:GetAttribute(BossConfig.BossAttribute)
	local boss = if type(key) == "string" then BossConfig.Bosses[key] else nil
	local sounds = if type(key) == "string" then BossSoundConfig.Bosses[key] else nil
	local ids = if boss then clipIds(boss.AnimPrefix) else {}
	local lastPosition = root.Position

	local roared = false
	local function roar()
		if roared then
			return
		end
		roared = true
		playAt(BossSoundConfig.WakeRoar, root)
	end

	local function onTrack(track: AnimationTrack)
		local clip = ids[track.Animation and track.Animation.AnimationId or ""]
		if clip == "Wake" then
			onMarker(trove, track, BossSoundConfig.RoarMarker, BossSoundConfig.RoarFallbackSeconds, roar)
		elseif clip == "Attack" then
			trove:Add(
				task.delay(
					math.max(0, BossSoundConfig.AttackHitFallbackSeconds - BossSoundConfig.SwingLeadSeconds)
						/ math.max(track.Speed, 0.1),
					function()
						playAt(BossSoundConfig.Swing, root)
					end
				)
			)
			onMarker(
				trove,
				track,
				BossSoundConfig.HitMarker,
				BossSoundConfig.AttackHitFallbackSeconds,
				function()
					playAt(BossSoundConfig.AttackImpact, root, BossSoundConfig.HitPitchSpread)
				end
			)
		elseif clip == "Stomp" then
			onMarker(
				trove,
				track,
				BossSoundConfig.HitMarker,
				BossSoundConfig.StompHitFallbackSeconds,
				function()
					playAt(BossSoundConfig.StompImpact, root)
				end
			)
		elseif clip == "BigAttack" then
			onMarker(
				trove,
				track,
				BossSoundConfig.HitMarker,
				BossSoundConfig.BigAttackHitFallbackSeconds,
				function()
					playAt(BossSoundConfig.BigAttackLand, root)
				end
			)
		elseif clip == "Defeat" then
			onMarker(trove, track, BossSoundConfig.LandMarker, BossSoundConfig.LandFallbackSeconds, function()
				playAt(BossSoundConfig.DefeatThud, root)
			end)
		end
	end

	local animator = model:FindFirstChildWhichIsA("Animator", true)
	if animator then
		trove:Connect(animator.AnimationPlayed, onTrack)
	end

	local phase = numberAttribute(model, BossConfig.PhaseAttribute)
	local isMad = model:GetAttribute(BossConfig.MadAttribute) == true
	local gold = numberAttribute(model, BossConfig.GoldSpotAttribute)
	local health = numberAttribute(model, BossConfig.HealthAttribute)
	local snore: Sound? = nil
	local dizzy: Sound? = nil

	local function refreshLoops()
		if phase == Phases.Sleeping then
			snore = snore or startLoop(trove, BossSoundConfig.Snore, root)
		else
			stopLoop(snore)
			snore = nil
		end
		if phase == Phases.Finish then
			dizzy = dizzy or startLoop(trove, BossSoundConfig.Dizzy, root)
		else
			stopLoop(dizzy)
			dizzy = nil
		end
	end
	refreshLoops()

	trove:Connect(model:GetAttributeChangedSignal(BossConfig.PhaseAttribute), function()
		local nextPhase = numberAttribute(model, BossConfig.PhaseAttribute)
		if nextPhase == phase then
			return
		end
		phase = nextPhase
		refreshLoops()
		if phase == Phases.Waking then
			roared = false
			trove:Add(task.delay(BossSoundConfig.RoarFallbackSeconds + 0.4, roar))
		elseif phase == Phases.Defeated and isNear(root) then
			LocalSound.Play(BossSoundConfig.Win)
		end
	end)

	trove:Connect(model:GetAttributeChangedSignal(BossConfig.MadAttribute), function()
		local nextMad = model:GetAttribute(BossConfig.MadAttribute) == true
		if nextMad and not isMad then
			playAt(BossSoundConfig.MadRoar, root)
		end
		isMad = nextMad
	end)

	trove:Connect(model:GetAttributeChangedSignal(BossConfig.GoldSpotAttribute), function()
		local nextGold = numberAttribute(model, BossConfig.GoldSpotAttribute)
		if nextGold ~= gold and gold ~= 0 and isFightPhase(phase) and isNear(root) then
			LocalSound.Play(BossSoundConfig.SpotMoved)
		end
		gold = nextGold
	end)

	local lastHitAt = 0
	trove:Connect(model:GetAttributeChangedSignal(BossConfig.HealthAttribute), function()
		local nextHealth = numberAttribute(model, BossConfig.HealthAttribute)
		local now = os.clock()
		if
			sounds
			and nextHealth < health
			and isFightPhase(phase)
			and now - lastHitAt >= BossSoundConfig.HitMinGapSeconds
		then
			lastHitAt = now
			playAt(sounds.Hit, root, BossSoundConfig.HitPitchSpread)
		end
		health = nextHealth
	end)

	local lastTick = -1
	trove:Connect(RunService.Heartbeat, function()
		lastPosition = root.Position
		if not isFightPhase(phase) then
			lastTick = -1
			return
		end
		local remaining =
			math.ceil(numberAttribute(model, BossConfig.EndsAtAttribute) - workspace:GetServerTimeNow())
		if remaining >= 1 and remaining <= BossSoundConfig.TickSeconds and remaining ~= lastTick then
			lastTick = remaining
			if isNear(root) then
				LocalSound.Play(BossSoundConfig.TimerTick)
			end
		end
	end)

	trove:Add(function()
		if not model:IsDescendantOf(workspace) then
			playAtPosition(BossSoundConfig.Poof, lastPosition)
		end
	end)
end

function BossSoundController.Init(self: any, _registry: { [string]: any })
	self._trove = Trove.new()
end

function BossSoundController.Start(self: any)
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
	local player = Players.LocalPlayer
	trove:Connect(player:GetAttributeChangedSignal(BossConfig.KnockedOutAttribute), function()
		if player:GetAttribute(BossConfig.KnockedOutAttribute) == true then
			LocalSound.Play(BossSoundConfig.KnockOut)
		end
	end)
	trove:Add(function()
		for instance in active do
			remove(instance)
		end
	end)
end

function BossSoundController.Destroy(self: any)
	local trove = self._trove :: TroveInstance?
	if trove then
		trove:Destroy()
	end
end

local _lifecycleCheck: Lifecycle.System = BossSoundController

return BossSoundController
