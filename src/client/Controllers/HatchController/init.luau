--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local HatchRevealConfig = require(ReplicatedStorage.Config.HatchRevealConfig)
local HatchTiming = require(ReplicatedStorage.HatchTiming)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local MovementLock = require(ReplicatedStorage.Utils.MovementLock)
local Packets = require(ReplicatedStorage.Packets)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Scene = require(script.Scene)
local Types = require(script.Types)

type Reveal = {
	IsCancelled: boolean,
	IsFinished: boolean,
	IsOwn: boolean,
}

local HatchController = {
	Name = "HatchController",
	Revealed = nil :: any,
}

local trove = Trove.new()
local controllers: { [string]: any } = {}
local active: { [Attachment]: Reveal } = {}
local backpackHolds = 0

local function setBackpackShown(isShown: boolean)
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, isShown)
end

local function holdBackpack(): () -> ()
	backpackHolds += 1
	if backpackHolds == 1 then
		setBackpackShown(false)
	end
	local released = false
	return function()
		if released then
			return
		end
		released = true
		backpackHolds -= 1
		if backpackHolds == 0 then
			setBackpackShown(true)
		end
	end
end

local function easeOut(alpha: number): number
	return 1 - (1 - alpha) * (1 - alpha)
end

local function backOut(alpha: number): number
	local overshoot = 1.70158
	local shifted = alpha - 1
	return 1 + (overshoot + 1) * shifted ^ 3 + overshoot * shifted ^ 2
end

local function pause(seconds: number, shouldStop: () -> boolean)
	local start = os.clock()
	while os.clock() - start < seconds and not shouldStop() do
		RunService.Heartbeat:Wait()
	end
end

local function flash()
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = "HatchFlash"
	effect.Brightness = HatchRevealConfig.FlashBrightness
	effect.Parent = Lighting
	local tween = TweenService:Create(
		effect,
		TweenInfo.new(HatchRevealConfig.FlashSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Brightness = 0 }
	)
	tween.Completed:Once(function()
		effect:Destroy()
	end)
	tween:Play()
end

local function holdOwner(scene: Types.Scene, reveal: Reveal): (() -> ())?
	local chopController = controllers.ChopController
	local start = os.clock()
	while chopController:IsMinigameActive() and os.clock() - start < HatchRevealConfig.MinigameWaitSeconds do
		if reveal.IsCancelled or reveal.IsFinished then
			return nil
		end
		RunService.Heartbeat:Wait()
	end
	if reveal.IsCancelled or reveal.IsFinished or chopController:IsMinigameActive() then
		return nil
	end
	local camera = workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local unlockMovement = if humanoid then MovementLock.Acquire(humanoid) else nil
	local function setHidden(isHidden: boolean)
		if not character then
			return
		end
		for _, descendant in character:GetDescendants() do
			if descendant:IsA("BasePart") or descendant:IsA("Decal") then
				descendant.LocalTransparencyModifier = if isHidden then 1 else 0
			end
		end
	end
	local hideConnection = RunService.RenderStepped:Connect(function()
		setHidden(true)
	end)
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
		local up = scene.Origin.UpVector
		local target = CFrame.lookAt(
			scene.Origin.Position
				+ scene.Origin.LookVector * HatchRevealConfig.CameraDistanceStuds
				+ up * HatchRevealConfig.CameraHeightStuds,
			scene.Origin.Position + up * HatchRevealConfig.CameraLookHeightStuds
		)
		local from = camera.CFrame
		task.spawn(Scene.Animate, HatchRevealConfig.CameraTransitionSeconds, function()
			return reveal.IsCancelled or reveal.IsFinished
		end, function(alpha: number)
			local eased = alpha * alpha * (3 - 2 * alpha)
			camera.CFrame = from:Lerp(target, eased)
		end)
	end
	return function()
		hideConnection:Disconnect()
		setHidden(false)
		if unlockMovement then
			unlockMovement()
		end
		if camera and not chopController:IsMinigameActive() then
			camera.CameraType = Enum.CameraType.Custom
		end
	end
end

local function play(spot: Attachment, hatch: Types.Hatch)
	local previous = active[spot]
	if previous then
		previous.IsCancelled = true
	end
	local reveal: Reveal =
		{ IsCancelled = false, IsFinished = false, IsOwn = hatch.Owner == Players.LocalPlayer }
	active[spot] = reveal
	local scene = Scene.Build(spot, hatch.GeodeKey)
	local rarity = RarityConfig.Rarities[hatch.Rarity]
	if not scene or not rarity then
		return
	end
	local function isCancelled(): boolean
		return reveal.IsCancelled
	end
	local isOwner = hatch.Owner == Players.LocalPlayer
	local release: (() -> ())? = nil
	local releaseBackpack = if isOwner then holdBackpack() else nil
	if isOwner then
		task.spawn(function()
			release = holdOwner(scene, reveal)
		end)
	end

	local pose: Types.Pose = { Height = 0, Scale = 1, Shake = 0, Spin = 0 }
	local start = os.clock()
	local totalSeconds = HatchTiming.RevealSeconds(hatch.Rarity)
	local poseConnection = RunService.Heartbeat:Connect(function(dt: number)
		local elapsed = os.clock() - start
		local progress = math.clamp(elapsed / totalSeconds, 0, 1)
		local speed = HatchRevealConfig.SpinStartDegreesPerSecond
			+ (HatchRevealConfig.SpinEndDegreesPerSecond - HatchRevealConfig.SpinStartDegreesPerSecond)
				* progress
				* progress
		pose.Spin += math.rad(speed * dt)
		Scene.Apply(scene, pose, elapsed)
	end)

	Scene.Animate(HatchRevealConfig.HoverSeconds, isCancelled, function(alpha: number)
		pose.Height = HatchRevealConfig.HoverStuds * easeOut(alpha)
	end)
	Scene.Animate(HatchRevealConfig.WhitenSeconds, isCancelled, function(alpha: number)
		scene.Highlight.FillTransparency = 1 - alpha
		scene.Highlight.OutlineTransparency = 1 - alpha
	end)
	pause(HatchRevealConfig.SpinUpSeconds, isCancelled)
	local previousColor = HatchRevealConfig.WhiteColor
	for step = 1, HatchTiming.Steps(hatch.Rarity) do
		if isCancelled() then
			break
		end
		local stepRarity = RarityConfig.Rarities[RarityConfig.Order[step]]
		local color = if stepRarity then stepRarity.Color else rarity.Color
		local from = 1 + HatchRevealConfig.StepGrowth * (step - 1)
		local to = from + HatchRevealConfig.StepGrowth
		local fromColor = previousColor
		if isOwner then
			LocalSound.Play(HatchRevealConfig.StepSoundKey)
		end
		Scene.Animate(HatchRevealConfig.StepSeconds, isCancelled, function(alpha: number)
			pose.Scale = from + (to - from) * backOut(alpha)
			pose.Shake = HatchRevealConfig.StepShakeDegrees * (1 - alpha)
			scene.Highlight.FillColor = fromColor:Lerp(color, alpha)
			scene.Highlight.OutlineColor = scene.Highlight.FillColor
		end)
		previousColor = color
		pause(HatchRevealConfig.StepPauseSeconds, isCancelled)
	end
	Scene.Animate(HatchRevealConfig.PopHoldSeconds, isCancelled, function(alpha: number)
		pose.Shake = HatchRevealConfig.PopShakeDegrees * alpha
	end)
	poseConnection:Disconnect()

	if not isCancelled() then
		Scene.Pop(scene, rarity.Color)
		if isOwner then
			LocalSound.Play(rarity.SoundKey)
			flash()
			local uiController = controllers.UIController
			local chopController = controllers.ChopController
			HatchController.Revealed:Fire(hatch)
			pause(HatchRevealConfig.ScreenTimeoutSeconds, function()
				return isCancelled()
					or not uiController:IsOpen(HatchRevealConfig.ScreenName)
					or chopController:IsMinigameActive()
			end)
			uiController:Close(HatchRevealConfig.ScreenName)
		end
	end

	reveal.IsFinished = true
	if active[spot] == reveal then
		active[spot] = nil
	end
	if release then
		release()
	end
	if releaseBackpack then
		releaseBackpack()
	end
	if isCancelled() then
		Scene.Destroy(scene)
	else
		task.delay(HatchRevealConfig.BurstLifetimeSeconds, Scene.Destroy, scene)
	end
end

function HatchController.IsPlaying(_self: any): boolean
	for _, reveal in active do
		if reveal.IsOwn then
			return true
		end
	end
	return false
end

function HatchController.Init(_self: any, registry: { [string]: any })
	controllers = registry
	HatchController.Revealed = Signal.new()
end

function HatchController.Start(_self: any)
	trove:Add(
		Packets.GeodeHatched.OnClientEvent:Connect(
			function(
				owner: Instance?,
				spot: Instance?,
				geodeKey: string,
				petKey: string,
				rarityIndex: number,
				isNew: boolean,
				trait: string,
				modifier: string,
				size: string,
				isPity: boolean
			)
				if not spot or not spot:IsA("Attachment") then
					return
				end
				local rarity = RarityConfig.Order[rarityIndex]
				if not rarity then
					return
				end
				task.spawn(play, spot, {
					Owner = if owner and owner:IsA("Player") then owner else nil,
					GeodeKey = geodeKey,
					PetKey = petKey,
					Rarity = rarity,
					IsNew = isNew,
					Trait = if trait ~= "" then trait else nil,
					Modifier = if modifier ~= "" then modifier else nil,
					Size = if size ~= "" then size else nil,
					IsPity = isPity,
				})
			end
		)
	)
end

function HatchController.Destroy(_self: any)
	for _, reveal in active do
		reveal.IsCancelled = true
	end
	trove:Destroy()
	if backpackHolds > 0 then
		backpackHolds = 0
		setBackpackShown(true)
	end
	if HatchController.Revealed then
		HatchController.Revealed:Destroy()
	end
end

return HatchController
