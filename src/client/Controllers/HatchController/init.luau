--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HatchRevealConfig = require(ReplicatedStorage.Config.HatchRevealConfig)
local HatchTiming = require(ReplicatedStorage.HatchTiming)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Scene = require(script.Scene)
local Types = require(script.Types)

type Reveal = {
	IsCancelled: boolean,
	IsFinished: boolean,
	IsOwn: boolean,
}

local HatchController = { Name = "HatchController" }

local trove = Trove.new()
local active: { [Attachment]: Reveal } = {}

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
		end
		local shown = Scene.ShowPet(scene, hatch)
		if shown then
			Scene.Animate(HatchRevealConfig.PetPopSeconds, isCancelled, function(alpha: number)
				Scene.SizePet(shown, backOut(alpha))
			end)
			pause(HatchRevealConfig.PetShowSeconds - HatchRevealConfig.PetPopSeconds, isCancelled)
			Scene.Animate(HatchRevealConfig.PetHideSeconds, isCancelled, function(alpha: number)
				Scene.SizePet(shown, 1 - alpha)
			end)
		else
			pause(HatchRevealConfig.PetShowSeconds, isCancelled)
		end
	end

	reveal.IsFinished = true
	if active[spot] == reveal then
		active[spot] = nil
	end
	Scene.Destroy(scene)
end

function HatchController.IsPlaying(_self: any): boolean
	for _, reveal in active do
		if reveal.IsOwn then
			return true
		end
	end
	return false
end

function HatchController.Init(_self: any, _registry: { [string]: any }) end

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
				size: string
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
end

return HatchController
