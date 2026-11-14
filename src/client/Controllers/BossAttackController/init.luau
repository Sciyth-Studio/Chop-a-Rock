--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local BossFxConfig = require(ReplicatedStorage.Config.BossFxConfig)
local BossHazards = require(ReplicatedStorage.BossHazards)
local BossSoundConfig = require(ReplicatedStorage.Config.BossSoundConfig)
local Canvas = require(script.Canvas)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local MovementLock = require(ReplicatedStorage.Utils.MovementLock)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Visuals = require(script.Visuals)

type TroveInstance = typeof(Trove.new())

local Attacks = BossConfig.Attacks
local cameraSpec = BossFxConfig.AttackCamera

local BossAttackController = {
	Name = "BossAttackController",
	_trove = nil :: TroveInstance?,
}

local chopController: any = nil
local attackTrove: TroveInstance? = nil
local cameraOwned = false
local shakeUntil = 0
local resultText: string? = nil
local resultStyle: string? = nil
local currentKind = BossConfig.Attacks.None

local function rootPart(): BasePart?
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root else nil
end

local function flat(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function releaseCamera()
	if not cameraOwned then
		return
	end
	cameraOwned = false
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
	end
end

local function stopAttack()
	local trove = attackTrove
	attackTrove = nil
	if trove then
		trove:Destroy()
	end
	releaseCamera()
end

local function inArena(position: Vector3, center: Vector3): boolean
	local half = BossConfig.ArenaJudgeHalfStuds
	return math.abs(position.X - center.X) <= half and math.abs(position.Z - center.Z) <= half
end

local function watchLanding(trove: TroveInstance, boss: Model, set: Visuals.Set, landsAt: number)
	local key = boss:GetAttribute(BossConfig.BossAttribute)
	local definition = if type(key) == "string" then BossConfig.Bosses[key] else nil
	local animator = boss:FindFirstChildWhichIsA("Animator", true)
	if not definition or not animator then
		return
	end
	local asset = AssetRegistry.get(definition.AnimPrefix .. BossConfig.Clips.BigAttack)
	local animationId = if asset:IsA("Animation") then asset.AnimationId else ""
	asset:Destroy()
	if animationId == "" then
		return
	end
	local function hook(track: AnimationTrack)
		if not track.Animation or track.Animation.AnimationId ~= animationId then
			return
		end
		trove:Connect(track:GetMarkerReachedSignal(BossSoundConfig.HitMarker), function()
			if set.LandOffset == nil then
				set.LandOffset = workspace:GetServerTimeNow() - landsAt
			end
		end)
	end
	for _, track in (animator :: Animator):GetPlayingAnimationTracks() do
		hook(track)
	end
	trove:Connect((animator :: Animator).AnimationPlayed, hook)
end

local function startAttack(boss: Model)
	stopAttack()
	local kindValue = boss:GetAttribute(BossConfig.AttackAttribute)
	local kind = if type(kindValue) == "number" then kindValue else Attacks.None
	if kind == Attacks.None then
		return
	end
	local isBig = kind == Attacks.Big
	currentKind = kind
	local centerValue = boss:GetAttribute(BossConfig.AttackCenterAttribute)
	local landsAtValue = boss:GetAttribute(BossConfig.AttackLandsAtAttribute)
	if typeof(centerValue) ~= "Vector3" or type(landsAtValue) ~= "number" then
		return
	end
	local center: Vector3 = centerValue
	local landsAt: number = landsAtValue
	local radiusValue = boss:GetAttribute(BossConfig.SlamRadiusAttribute)
	local slamRadius = if type(radiusValue) == "number" then radiusValue else 0
	local hazard = if isBig then BossHazards.Read(boss) else nil
	if isBig and not hazard then
		return
	end
	local trove = Trove.new()
	attackTrove = trove
	resultText = nil
	resultStyle = nil
	local set = Visuals.Build(boss, kind, center, slamRadius, hazard)
	trove:Add(set.Folder)
	trove:Add(function()
		local cleanup = set.Cleanup
		if cleanup then
			cleanup()
		end
	end)
	if hazard and hazard.Style == BossConfig.BigStyles.IceSpikes then
		watchLanding(trove, boss, set, landsAt)
	end
	local floorY = center.Y + BossFxConfig.Arrow.LiftStuds
	local camera = workspace.CurrentCamera
	local cameraStart = os.clock()
	local fromFrame: CFrame? = nil
	local direction: Vector3? = nil
	local lastText = ""
	local landed = false
	local releaseAt = landsAt + set.HoldSeconds + cameraSpec.HoldAfterLandSeconds
	local hazardLook = BossFxConfig.Hazards
	local arrowTarget: Vector3? = nil
	local arrowCheckAt = 0
	trove:Connect(RunService.RenderStepped, function(dt: number)
		local now = workspace:GetServerTimeNow()
		local left = landsAt - now
		local root = rootPart()
		if left > 0 then
			local text = tostring(math.ceil(left))
			if text ~= lastText then
				lastText = text
				Visuals.SetCountdown(set, text, BossFxConfig.Countdown.TextStyle)
			end
			local urgency = 1
				- math.clamp(
					left / (if isBig then BossConfig.BigAttack.WarnSeconds else BossConfig.Slam.WarnSeconds),
					0,
					1
				)
			local speed = BossFxConfig.Floor.PulseSpeedMin
				+ (BossFxConfig.Floor.PulseSpeedMax - BossFxConfig.Floor.PulseSpeedMin) * urgency
			Visuals.Pulse(set, (math.sin(os.clock() * speed) + 1) / 2)
		else
			if not landed then
				landed = true
				Visuals.SetCountdown(set, resultText or "", resultStyle)
			elseif resultText and lastText ~= resultText then
				lastText = resultText
				Visuals.SetCountdown(set, resultText, resultStyle)
			end
			local alpha = math.clamp(-(left + set.HoldSeconds) / BossFxConfig.Floor.FadeSeconds, 0, 1)
			if alpha > 0 then
				Visuals.Fade(set, alpha)
			end
		end
		local animate = set.Animate
		if animate then
			animate(now - landsAt)
		end
		local arrow = set.Arrow
		if arrow and root and hazard then
			if os.clock() >= arrowCheckAt then
				arrowCheckAt = os.clock() + hazardLook.ArrowRefreshSeconds
				arrowTarget = BossHazards.NearestSafe(hazard, root.Position, hazardLook.ArrowSearchStuds)
			end
			local target = arrowTarget
			local offset = if target then flat(target - root.Position) else Vector3.zero
			if not target or offset.Magnitude < 1e-3 then
				arrow:PivotTo(CFrame.new(0, -500, 0))
			else
				local heading = offset.Unit
				local bob = (math.sin(os.clock() * BossFxConfig.Arrow.BobSpeed) + 1)
					/ 2
					* BossFxConfig.Arrow.BobStuds
				local base = Vector3.new(root.Position.X, floorY, root.Position.Z)
					+ heading * (BossFxConfig.Arrow.DistanceStuds + bob)
				arrow:PivotTo(CFrame.lookAt(base, base + heading) * Canvas.Facing)
			end
		end
		if not camera or chopController:IsMinigameActive() then
			return
		end
		if now >= releaseAt then
			releaseCamera()
			return
		end
		if not root or not inArena(root.Position, center) then
			releaseCamera()
			return
		end
		if not cameraOwned then
			cameraOwned = true
			cameraStart = os.clock()
			fromFrame = camera.CFrame
		end
		camera.CameraType = Enum.CameraType.Scriptable
		local wanted = flat(root.Position - center)
		if wanted.Magnitude < 1e-3 then
			wanted = flat(camera.CFrame.Position - center)
		end
		if wanted.Magnitude < 1e-3 then
			wanted = Vector3.zAxis
		end
		local currentDirection = direction or wanted.Unit
		direction = currentDirection:Lerp(wanted.Unit, math.clamp(dt * cameraSpec.FollowSmoothing, 0, 1)).Unit
		local distance = if isBig
			then cameraSpec.ArenaDistanceStuds
			else math.max(cameraSpec.SlamMinDistanceStuds, slamRadius * cameraSpec.SlamDistanceScale)
		local height = if isBig
			then cameraSpec.ArenaHeightStuds
			else math.max(cameraSpec.SlamMinDistanceStuds, slamRadius) * cameraSpec.SlamHeightScale
		local position = center + (direction :: Vector3) * distance + Vector3.yAxis * height
		local look = center:Lerp(root.Position, cameraSpec.FollowBlend)
		local frame = CFrame.lookAt(position, look)
		local alpha = math.clamp((os.clock() - cameraStart) / cameraSpec.MoveSeconds, 0, 1)
		local eased = alpha * alpha * (3 - 2 * alpha)
		if fromFrame and alpha < 1 then
			frame = fromFrame:Lerp(frame, eased)
		end
		if os.clock() < shakeUntil then
			local intensity = BossFxConfig.Results.ShakeIntensity
			frame = frame
				* CFrame.new(
					(math.random() * 2 - 1) * intensity,
					(math.random() * 2 - 1) * intensity,
					(math.random() * 2 - 1) * intensity
				)
		end
		camera.CFrame = frame
	end)
	trove:Add(releaseCamera)
end

local function flashCharacter(character: Model)
	local spec = BossFxConfig.Shield
	local highlight = Instance.new("Highlight")
	highlight.FillColor = spec.HitFlashColor
	highlight.FillTransparency = spec.HitFlashTransparency
	highlight.OutlineTransparency = 1
	highlight.Adornee = character
	highlight.Parent = character
	local tween =
		TweenService:Create(highlight, TweenInfo.new(spec.HitFlashSeconds), { FillTransparency = 1 })
	tween.Completed:Once(function()
		highlight:Destroy()
	end)
	tween:Play()
end

local function onResult(outcome: number, knock: Vector3)
	local results = BossFxConfig.Results
	if outcome == BossConfig.AttackOutcomes.Safe then
		resultText = BossConfig.SafeText
		resultStyle = results.SafeStyle
		LocalSound.Play("SFX_Chop_Perfect")
		return
	end
	resultText = BossConfig.OuchText
	resultStyle = results.HitStyle
	LocalSound.Play("SFX_Enemy_Hit")
	shakeUntil = os.clock() + results.ShakeSeconds
	local character = Players.LocalPlayer.Character
	local root = rootPart()
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if character then
		flashCharacter(character)
	end
	if not root or not humanoid or knock.Magnitude < 1e-3 then
		return
	end
	local release = MovementLock.Acquire(humanoid)
	humanoid.PlatformStand = true
	root.AssemblyLinearVelocity = Vector3.new(knock.X, 0, knock.Z) / results.AirSeconds
		+ Vector3.yAxis * results.KnockUpSpeed
	task.delay(results.AirSeconds, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
		end
	end)
	local isBig = currentKind == Attacks.Big
	task.delay(
		if isBig then BossConfig.BigAttack.DizzySeconds + results.AirSeconds else results.AirSeconds,
		release
	)
end

local function watch(trove: TroveInstance, boss: Model)
	local function refresh()
		local kind = boss:GetAttribute(BossConfig.AttackAttribute)
		if type(kind) == "number" and kind ~= Attacks.None then
			startAttack(boss)
		else
			stopAttack()
		end
	end
	trove:Connect(boss:GetAttributeChangedSignal(BossConfig.AttackAttribute), refresh)
	trove:Add(stopAttack)
	refresh()
end

function BossAttackController.Init(self: any, registry: { [string]: any })
	self._trove = Trove.new()
	chopController = registry.ChopController
end

function BossAttackController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local active: { [Instance]: TroveInstance } = {}
	local function add(instance: Instance)
		if not instance:IsA("Model") or active[instance] then
			return
		end
		local bossTrove = Trove.new()
		active[instance] = bossTrove
		watch(bossTrove, instance)
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
	trove:Add(Packets.BossAttackResult.OnClientEvent:Connect(onResult))
	trove:Add(function()
		for instance in active do
			remove(instance)
		end
	end)
end

function BossAttackController.Destroy(self: any)
	local trove = self._trove :: TroveInstance?
	if trove then
		trove:Destroy()
	end
end

local _lifecycleCheck: Lifecycle.System = BossAttackController

return BossAttackController
