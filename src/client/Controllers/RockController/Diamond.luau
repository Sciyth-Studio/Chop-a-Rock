--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Packets = require(ReplicatedStorage.Packets)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Typography = require(ReplicatedStorage.Utils.Typography)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFXEmit) :: any
local Effects = require(script.Parent.Effects)

type TroveInstance = typeof(Trove.new())
type Active = {
	Model: Model,
	Part: BasePart,
	Trove: TroveInstance,
	Prompt: ProximityPrompt,
	IsUp: boolean,
	HasEnded: boolean,
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
	SoundService:PlayLocalSound(sound)
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

local function baseCFrame(part: BasePart): CFrame
	return CFrame.new(part.Position - Vector3.new(0, part.Size.Y / 2, 0))
end

local function numberAttribute(instance: Instance, name: string): number
	local value = instance:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

local function paint(label: TextLabel, main: Color3, light: Color3, dark: Color3)
	local gradient = label:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, main),
			ColorSequenceKeypoint.new(0.5, light),
			ColorSequenceKeypoint.new(1, main),
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

local function setText(main: TextLabel?, shadow: TextLabel?, text: string)
	if main then
		main.Text = text
	end
	if shadow then
		shadow.Text = text
	end
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
	local base = target.Position - Vector3.new(0, part.Size.Y / 2 - DiamondRockConfig.GlowBaseLiftStuds, 0)
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

local function makeLabel(trove: TroveInstance, part: BasePart, isEnded: () -> boolean)
	local asset = AssetRegistry.get(DiamondRockConfig.LabelKey)
	if not asset:IsA("BillboardGui") then
		asset:Destroy()
		return
	end
	local nameLabel = findLabel(asset, "NameLabel")
	local nameShadow = findLabel(asset, "NameLabelShadow")
	local timeLabel = findLabel(asset, "TimeLabel")
	local timeShadow = findLabel(asset, "TimeLabelShadow")
	local fillInstance = asset:FindFirstChild("Fill", true)
	local fill: GuiObject? = if fillInstance and fillInstance:IsA("GuiObject") then fillInstance else nil
	local scale = if timeLabel then timeLabel:FindFirstChildWhichIsA("UIScale") else nil
	Typography.Apply(asset)
	asset.Adornee = part
	asset.MaxDistance = DiamondRockConfig.LabelMaxDistance
	asset.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + DiamondRockConfig.LabelHeightAboveRock, 0)
	setText(nameLabel, nameShadow, DiamondRockConfig.DisplayName)
	if nameLabel then
		paint(nameLabel, DiamondRockConfig.TextMain, DiamondRockConfig.TextLight, DiamondRockConfig.TextDark)
	end
	if timeLabel then
		paint(timeLabel, DiamondRockConfig.TextMain, DiamondRockConfig.TextLight, DiamondRockConfig.TextDark)
	end
	asset.Parent = part
	trove:Add(asset)

	local shown = -1
	local isWarning = false
	trove:Connect(RunService.Heartbeat, function()
		local maxHealth = numberAttribute(part, DiamondRockConfig.MaxHealthAttribute)
		if fill and maxHealth > 0 then
			local ratio =
				math.clamp(numberAttribute(part, DiamondRockConfig.HealthAttribute) / maxHealth, 0, 1)
			fill.Size = UDim2.fromScale(ratio, 1)
		end
		local remaining = if isEnded()
			then 0
			else math.max(
				0,
				math.ceil(
					numberAttribute(part, DiamondRockConfig.EndsAtAttribute) - workspace:GetServerTimeNow()
				)
			)
		if remaining == shown then
			return
		end
		shown = remaining
		setText(timeLabel, timeShadow, string.format("%d:%02d", remaining // 60, remaining % 60))
		if remaining > 0 and remaining <= DiamondRockConfig.WarningSeconds then
			playOnce(DiamondRockConfig.TickSoundKey)
		end
		if remaining > DiamondRockConfig.WarningSeconds or remaining <= 0 or not timeLabel then
			return
		end
		if not isWarning then
			isWarning = true
			paint(
				timeLabel,
				DiamondRockConfig.WarningMain,
				DiamondRockConfig.WarningLight,
				DiamondRockConfig.WarningDark
			)
		end
		if scale then
			scale.Scale = DiamondRockConfig.PulseScale
			TweenService
				:Create(
					scale,
					TweenInfo.new(
						DiamondRockConfig.PulseSeconds,
						Enum.EasingStyle.Quad,
						Enum.EasingDirection.Out
					),
					{ Scale = 1 }
				)
				:Play()
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
		}
		active = state
		diamondTrove:Connect(prompt.Triggered, function()
			if state.IsUp and not state.HasEnded then
				Packets.DiamondChop:Fire()
			end
		end)

		local beacon = makeBeacon(diamondTrove, target)
		addGlow(diamondTrove, part, beacon, target)
		startLoop(diamondTrove, state.Loops, DiamondRockConfig.BeaconSoundKey, beacon)
		local function startShimmer()
			if not state.HasEnded and part.Parent then
				startLoop(diamondTrove, state.Loops, DiamondRockConfig.ShimmerSoundKey, part)
			end
		end
		makeLabel(diamondTrove, part, function(): boolean
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
		playModel(DiamondRockConfig.RingKey, CFrame.new(target.Position - Vector3.new(0, part.Size.Y / 2, 0)))
		diamondTrove:Add(task.delay(DiamondRockConfig.ArrivalDelaySeconds, function()
			if active ~= state or not part.Parent then
				return
			end
			shakeCamera(target.Position)
			Effects.Rise(part, target, function()
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
		local function land()
			if not part.Parent then
				return
			end
			playModel(DiamondRockConfig.ShardsKey, baseCFrame(part) + Vector3.new(0, part.Size.Y / 2, 0))
			if isBroken then
				playOnce(DiamondRockConfig.ShatterSoundKey)
				playModel(DiamondRockConfig.BurstKey, baseCFrame(part))
				Effects.Break(part, quality, DiamondRockConfig.BreakCleanupSeconds)
				return
			end
			LocalSound.Play(DiamondRockConfig.HitSoundKey)
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
