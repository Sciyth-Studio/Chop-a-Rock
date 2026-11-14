--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Packets = require(ReplicatedStorage.Packets)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFX.Emit) :: any
local Effects = require(script.Parent.Effects)

type TroveInstance = typeof(Trove.new())
type Active = {
	Model: Model,
	Part: BasePart,
	Trove: TroveInstance,
	Prompt: ProximityPrompt,
	IsUp: boolean,
	HasEnded: boolean,
	Animator: Animator?,
	Loops: { Sound },
}

local Diamond = {}

local warnedSounds: { [string]: true } = {}

local function loadSound(key: string): Sound?
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return nil
	end
	if asset.SoundId == "" then
		if not warnedSounds[key] then
			warnedSounds[key] = true
			warn(`[Diamond] {key} has no SoundId; skipping`)
		end
		asset:Destroy()
		return nil
	end
	return asset
end

local function playOnce(key: string)
	local sound = loadSound(key)
	if not sound then
		return
	end
	LocalSound.PlayInstance(sound)
	task.delay(5, function()
		sound:Destroy()
	end)
end

local function startLoop(trove: TroveInstance, loops: { Sound }, key: string, parent: Instance)
	local sound = loadSound(key)
	if not sound then
		return
	end
	sound.Looped = true
	sound.Parent = parent
	sound:Play()
	trove:Add(sound)
	table.insert(loops, sound)
end

local function stopLoops(loops: { Sound })
	for _, sound in loops do
		sound:Stop()
		sound:Destroy()
	end
	table.clear(loops)
end

local function playModel(key: string, cframe: CFrame)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	asset:PivotTo(cframe)
	asset.Parent = workspace
	VFXEmit.emit(asset, {
		onDone = function()
			asset:Destroy()
		end,
	})
end

local function groundCFrame(part: BasePart): CFrame
	return CFrame.new(part.Position - Vector3.new(0, part.Size.Y / 2 - DiamondRockConfig.SinkStuds, 0))
end

type Animator = {
	Kick: () -> (),
	Charge: () -> (),
}

local function numberAttribute(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function childPart(part: BasePart, name: string): BasePart?
	local found = part:FindFirstChild(name)
	return if found and found:IsA("BasePart") then found else nil
end

local function attachTemplate(trove: TroveInstance, key: string, target: BasePart?, placed: { Instance })
	if not target then
		return
	end
	local asset = AssetRegistry.get(key)
	local root = asset:FindFirstChild("Root")
	if root then
		for _, child in root:GetChildren() do
			local instance: Instance = child
			if instance.ClassName == "Attachment" or instance.ClassName == "ParticleEmitter" then
				instance.Parent = target
				trove:Add(instance)
				table.insert(placed, instance)
			end
		end
	end
	asset:Destroy()
end

local function findIn(placed: { Instance }, name: string): { Instance }
	local found = {}
	for _, instance in placed do
		if instance.Name == name then
			table.insert(found, instance)
		end
		for _, descendant in instance:GetDescendants() do
			if descendant.Name == name then
				table.insert(found, descendant)
			end
		end
	end
	return found
end

local function setEmitters(emitters: { Instance }, enabled: boolean?, rate: number?)
	for _, instance in emitters do
		if instance:IsA("ParticleEmitter") then
			if enabled ~= nil then
				instance.Enabled = enabled
			end
			if rate then
				instance.Rate = rate
			end
		end
	end
end

local function animateParts(trove: TroveInstance, part: BasePart): Animator
	local spin = part:FindFirstChild(DiamondRockConfig.ShardSpinName, true)
	local spinWeld: Weld? = if spin and spin:IsA("Weld") then spin else nil
	local corePart = childPart(part, DiamondRockConfig.CoreName)
	local veinsPart = childPart(part, DiamondRockConfig.VeinsName)
	local shardPart: BasePart? = if spinWeld and spinWeld.Part1 then spinWeld.Part1 else nil
	local shardSize = if shardPart then shardPart.Size else Vector3.one
	local baseC0 = if spinWeld then spinWeld.C0 else CFrame.identity
	local coreColor = if corePart then corePart.Color else Color3.new(1, 1, 1)
	local veinColor = if veinsPart then veinsPart.Color else Color3.new(1, 1, 1)
	local placed: { Instance } = {}
	attachTemplate(trove, DiamondRockConfig.HeartKey, corePart, placed)
	attachTemplate(trove, DiamondRockConfig.VeinsKey, veinsPart, placed)
	attachTemplate(
		trove,
		DiamondRockConfig.CrumbleKey,
		childPart(part, DiamondRockConfig.CrystalsName),
		placed
	)
	attachTemplate(trove, DiamondRockConfig.ShardTrailsKey, shardPart, placed)
	local lightFound = findIn(placed, DiamondRockConfig.HeartLightName)[1]
	local light: PointLight? = if lightFound and lightFound:IsA("PointLight") then lightFound else nil
	local haze = findIn(placed, DiamondRockConfig.HazeName)
	local firstHaze = haze[1]
	local hazeRate = if firstHaze and firstHaze:IsA("ParticleEmitter") then firstHaze.Rate else 0
	local crumble = findIn(placed, DiamondRockConfig.CrumbleName)
	local lastTime = os.clock()
	local angle = 0
	local phase = 0
	local isLow = false
	local kickedAt = -math.huge
	local chargedAt: number? = nil
	trove:Connect(RunService.RenderStepped, function()
		local now = os.clock()
		local dt = now - lastTime
		lastTime = now
		local maxHealth = numberAttribute(part, DiamondRockConfig.MaxHealthAttribute)
		local low = maxHealth > 0
			and numberAttribute(part, DiamondRockConfig.HealthAttribute) / maxHealth
				< DiamondRockConfig.LowHealthRatio
		if low ~= isLow and not chargedAt then
			isLow = low
			setEmitters(crumble, low)
			setEmitters(
				haze,
				nil,
				if low then hazeRate * DiamondRockConfig.LowHazeRateMultiplier else hazeRate
			)
			if veinsPart and not low then
				veinsPart.Color = veinColor
			end
		end
		local sinceKick = now - kickedAt
		local boost = 1
			+ (DiamondRockConfig.KickSpinMultiplier - 1)
				* math.clamp(1 - sinceKick / DiamondRockConfig.KickSeconds, 0, 1)
		local charge = if chargedAt
			then math.clamp((now - chargedAt) / DiamondRockConfig.ChargeSeconds, 0, 1)
			else 0
		angle += dt * DiamondRockConfig.ShardSpinRadPerSec * (boost + charge * DiamondRockConfig.KickSpinMultiplier * 2)
		if spinWeld then
			spinWeld.C0 = CFrame.Angles(0, angle, 0) * baseC0
		end
		if shardPart and chargedAt then
			shardPart.Size = shardSize * (1 - charge * (1 - DiamondRockConfig.ChargeShardScale))
		end
		phase += dt / (if isLow then DiamondRockConfig.LowPulseSeconds else DiamondRockConfig.CorePulseSeconds)
		local wave = (math.sin(phase * math.pi * 2) + 1) / 2
		local flash = math.max(charge, math.clamp(1 - sinceKick / DiamondRockConfig.FlashSeconds, 0, 1))
		if corePart then
			corePart.Color = coreColor
				:Lerp(DiamondRockConfig.CoreDimColor, wave * DiamondRockConfig.CorePulseDepth)
				:Lerp(DiamondRockConfig.FlashColor, flash)
		end
		if veinsPart and isLow then
			local flicker =
				math.clamp(math.noise(now * DiamondRockConfig.VeinFlickerSpeed, 0.5) * 2 + 0.3, 0, 1)
			veinsPart.Color =
				veinColor:Lerp(DiamondRockConfig.VeinDimColor, flicker * DiamondRockConfig.VeinFlickerDepth)
		end
		if light then
			light.Brightness = DiamondRockConfig.HeartLightMin
				+ (DiamondRockConfig.HeartLightMax - DiamondRockConfig.HeartLightMin)
					* math.max(1 - wave, flash)
		end
	end)
	return {
		Kick = function()
			kickedAt = os.clock()
		end,
		Charge = function()
			chargedAt = os.clock()
			setEmitters(crumble, false)
			trove:Add(task.delay(DiamondRockConfig.ChargeSeconds, function()
				for _, instance in placed do
					instance:Destroy()
				end
				light = nil
			end))
		end,
	}
end

local function hitCFrame(part: BasePart): CFrame
	local camera = workspace.CurrentCamera
	local core = part:FindFirstChild(DiamondRockConfig.CoreName)
	local center = if core and core:IsA("BasePart") then core.Position else part.Position
	local from = if camera then camera.CFrame.Position else center + Vector3.zAxis * 100
	local aim = Vector3.new(center.X, math.min(from.Y, center.Y), center.Z)
	local toward = aim - from
	local direction = if toward.Magnitude > 1e-3 then toward.Unit else -Vector3.zAxis
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { part }
	local result = workspace:Raycast(from, direction * DiamondRockConfig.HitRayStuds, params)
	local point = if result then result.Position else aim - direction * part.Size.X / 2
	return CFrame.lookAt(point, point - direction)
end

local function makeBeacon(trove: TroveInstance, target: CFrame): BasePart
	local beacon = Instance.new("Part")
	beacon.Name = "DiamondBeacon"
	beacon.Shape = Enum.PartType.Cylinder
	beacon.Material = Enum.Material.Neon
	beacon.Color = DiamondRockConfig.BeaconColor
	beacon.Transparency = DiamondRockConfig.BeaconTransparency
	beacon.Size = Vector3.new(
		DiamondRockConfig.BeaconHeight,
		DiamondRockConfig.BeaconWidth,
		DiamondRockConfig.BeaconWidth
	)
	beacon.CFrame = CFrame.new(target.Position + Vector3.new(0, DiamondRockConfig.BeaconHeight / 2, 0))
		* CFrame.Angles(0, 0, math.rad(90))
	beacon.Anchored = true
	beacon.CanCollide = false
	beacon.CanQuery = false
	beacon.CanTouch = false
	beacon.CastShadow = false
	beacon.Parent = workspace
	trove:Add(beacon)
	return beacon
end

local function addGlow(trove: TroveInstance, part: BasePart, beacon: BasePart, target: CFrame)
	local glow = AssetRegistry.get(DiamondRockConfig.GlowKey)
	local base = target.Position
		- Vector3.new(
			0,
			part.Size.Y / 2 - DiamondRockConfig.SinkStuds - DiamondRockConfig.GlowBaseLiftStuds,
			0
		)
	for _, child in glow:GetChildren() do
		if child:IsA("ParticleEmitter") then
			child.Parent = if child.Name == "Column" then beacon else part
			trove:Add(child)
		elseif child:IsA("Attachment") then
			local height = if child.Name == "Top" then DiamondRockConfig.BeaconHeight else 0
			child.Parent = beacon
			child.WorldCFrame = CFrame.new(base + Vector3.new(0, height, 0))
			trove:Add(child)
		end
	end
	glow:Destroy()
end

local function tickWarnings(trove: TroveInstance, part: BasePart, isEnded: () -> boolean)
	local shown = -1
	trove:Connect(RunService.Heartbeat, function()
		if isEnded() then
			return
		end
		local remaining = math.max(
			0,
			math.ceil(numberAttribute(part, DiamondRockConfig.EndsAtAttribute) - workspace:GetServerTimeNow())
		)
		if remaining == shown then
			return
		end
		shown = remaining
		if remaining > 0 and remaining <= DiamondRockConfig.WarningSeconds then
			playOnce(DiamondRockConfig.TickSoundKey)
		end
	end)
end

local function shakeCamera(position: Vector3)
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not root or not root:IsA("BasePart") or not humanoid then
		return
	end
	if (root.Position - position).Magnitude > DiamondRockConfig.ShakeDistance then
		return
	end
	local started = os.clock()
	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local progress = (os.clock() - started) / DiamondRockConfig.ShakeSeconds
		if progress >= 1 or not humanoid.Parent then
			connection:Disconnect()
			humanoid.CameraOffset = Vector3.zero
			return
		end
		local studs = DiamondRockConfig.ShakeStuds * (1 - progress)
		humanoid.CameraOffset = Vector3.new(
			(math.random() * 2 - 1) * studs,
			(math.random() * 2 - 1) * studs,
			(math.random() * 2 - 1) * studs
		)
	end)
end

function Diamond.Start(trove: TroveInstance, chopController: any)
	local active: Active? = nil

	local function refreshPrompt()
		local current = active
		if current then
			current.Prompt.Enabled = current.IsUp
				and not current.HasEnded
				and not chopController:IsMinigameActive()
		end
	end

	local function teardown(model: Instance)
		local current = active
		if not current or current.Model ~= model then
			return
		end
		active = nil
		current.Trove:Destroy()
	end

	local function setup(model: Instance)
		if not model:IsA("Model") or (active and active.Model == model) then
			return
		end
		local found = model:WaitForChild("Rock", 10)
		if not found or not found:IsA("BasePart") or not model.Parent then
			return
		end
		local part = found
		if active then
			teardown(active.Model)
		end
		local diamondTrove = Trove.new()
		local target = part.CFrame
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Chop"
		prompt.ObjectText = DiamondRockConfig.DisplayName
		prompt.HoldDuration = ChopConfig.PromptHoldSeconds
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.MaxActivationDistance = ChopConfig.PromptRangeStuds + math.max(part.Size.X, part.Size.Z) / 2
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = part
		diamondTrove:Add(prompt)
		local state: Active = {
			Model = model,
			Part = part,
			Trove = diamondTrove,
			Prompt = prompt,
			IsUp = false,
			HasEnded = false,
			Loops = {},
			Animator = nil,
		}
		active = state
		diamondTrove:Connect(prompt.Triggered, function()
			if state.IsUp and not state.HasEnded then
				Packets.DiamondChop:Fire()
			end
		end)

		state.Animator = animateParts(diamondTrove, part)
		local beacon = makeBeacon(diamondTrove, target)
		addGlow(diamondTrove, part, beacon, target)
		startLoop(diamondTrove, state.Loops, DiamondRockConfig.BeaconSoundKey, beacon)
		local function startShimmer()
			if not state.HasEnded and part.Parent then
				startLoop(diamondTrove, state.Loops, DiamondRockConfig.ShimmerSoundKey, part)
			end
		end
		tickWarnings(diamondTrove, part, function(): boolean
			return state.HasEnded
		end)

		local remaining = numberAttribute(part, DiamondRockConfig.EndsAtAttribute)
			- workspace:GetServerTimeNow()
		if remaining < DiamondRockConfig.CountdownSeconds then
			state.IsUp = true
			refreshPrompt()
			startShimmer()
			return
		end
		part.CFrame = target - Vector3.new(0, part.Size.Y + 1, 0)
		LocalSound.Play(DiamondRockConfig.AppearSoundKey)
		playModel(DiamondRockConfig.RingKey, groundCFrame(part) + (target.Position - part.Position))
		diamondTrove:Add(task.delay(DiamondRockConfig.ArrivalDelaySeconds, function()
			if active ~= state or not part.Parent then
				return
			end
			shakeCamera(target.Position)
			Effects.Rise(part, target, function()
				shakeCamera(target.Position)
				state.IsUp = true
				refreshPrompt()
				startShimmer()
			end)
		end))
	end

	local function onChopped(quality: number, isBroken: boolean)
		local current = active
		if not current then
			return
		end
		local part = current.Part
		if quality == ChopQuality.Crack then
			Effects.Crack(part)
			return
		end
		local animator = current.Animator
		local function land()
			if not part.Parent then
				return
			end
			if isBroken then
				if animator then
					animator.Charge()
				end
				playModel(DiamondRockConfig.BreakKey, groundCFrame(part))
				task.delay(DiamondRockConfig.ChargeSeconds, function()
					if not part.Parent then
						return
					end
					playOnce(DiamondRockConfig.ShatterSoundKey)
					shakeCamera(part.Position)
					Effects.Break(part, quality, DiamondRockConfig.BreakCleanupSeconds, nil, true)
				end)
				return
			end
			LocalSound.Play(DiamondRockConfig.HitSoundKey)
			if animator then
				animator.Kick()
			end
			local impact = hitCFrame(part)
			playModel(DiamondRockConfig.HitKey, impact)
			if quality == ChopQuality.Perfect or quality == ChopQuality.Master then
				playModel(DiamondRockConfig.BigHitKey, impact)
			end
			if quality == ChopQuality.Master then
				shakeCamera(part.Position)
			end
			Effects.Hit(part, quality)
		end
		if isBroken then
			current.HasEnded = true
			stopLoops(current.Loops)
			refreshPrompt()
		end
		if quality == ChopQuality.Master then
			Effects.MasterStart(part)
			task.delay(MasterChopConfig.ImpactDelaySeconds, land)
			return
		end
		land()
	end

	local function onEnded()
		local current = active
		if not current or current.HasEnded then
			return
		end
		current.HasEnded = true
		stopLoops(current.Loops)
		playOnce(DiamondRockConfig.DespawnSoundKey)
		refreshPrompt()
		Effects.Sink(current.Part, DiamondRockConfig.SinkSeconds, function() end)
	end

	for _, tagged in CollectionService:GetTagged(DiamondRockConfig.Tag) do
		task.spawn(setup, tagged)
	end
	trove:Connect(CollectionService:GetInstanceAddedSignal(DiamondRockConfig.Tag), setup)
	trove:Connect(CollectionService:GetInstanceRemovedSignal(DiamondRockConfig.Tag), teardown)
	trove:Add(Packets.DiamondChopped.OnClientEvent:Connect(onChopped))
	trove:Add(Packets.DiamondEnded.OnClientEvent:Connect(onEnded))
	trove:Add(Packets.Notify.OnClientEvent:Connect(function(kind: string, message: string)
		if
			kind == DiamondRockConfig.EarnedKind
			and string.sub(message, 1, #DiamondRockConfig.PayoutPrefix) == DiamondRockConfig.PayoutPrefix
		then
			playOnce(DiamondRockConfig.PayoutSoundKey)
		end
	end))
	trove:Connect(chopController.ActiveChanged, refreshPrompt)
	trove:Add(function()
		if active then
			active.Trove:Destroy()
			active = nil
		end
	end)
end

return Diamond
