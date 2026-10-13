--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopEffectConfig = require(ReplicatedStorage.Config.ChopEffectConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopStyleConfig = require(ReplicatedStorage.Config.ChopStyleConfig)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local LowGraphics = require(ReplicatedStorage.Utils.LowGraphics)
local SplitModel = require(ReplicatedStorage.Utils.SplitModel)
local VFXEmit = require(ReplicatedStorage.VFXEmit) :: any

local Effects = {}

local shakeSteps = 10
local shakeStepSeconds = 0.03
local shakeStuds = 0.5
local shakeDegrees = 3

local function anchorAt(position: Vector3, lifetimeSeconds: number): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = "RockEffect"
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain
	task.delay(lifetimeSeconds, function()
		if attachment.Parent then
			attachment:Destroy()
		end
	end)
	return attachment
end

local function playSound(key: string, parent: Instance, volumeMultiplier: number?, startSeconds: number?)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	if volumeMultiplier then
		asset.Volume *= volumeMultiplier
	end
	asset.Parent = parent
	if startSeconds then
		asset.TimePosition = startSeconds
	end
	asset:Play()
	task.delay(5, function()
		if asset.Parent then
			asset:Destroy()
		end
	end)
end

local function emit(key: string, parent: Instance, fallbackCount: number, lifetimeSeconds: number)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Attachment") then
		asset:Destroy()
		return
	end
	asset.Parent = parent
	for _, descendant in asset:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			local count = descendant:GetAttribute("EmitCount")
			descendant:Emit(if type(count) == "number" then count else fallbackCount)
		end
	end
	task.delay(lifetimeSeconds, function()
		if asset.Parent then
			asset:Destroy()
		end
	end)
end

local function qualitySoundKey(quality: number): string
	if quality == ChopQuality.Perfect then
		return "SFX_Chop_Perfect"
	elseif quality == ChopQuality.Great then
		return "SFX_Chop_Great"
	elseif quality == ChopQuality.Good then
		return "SFX_Chop_Good"
	elseif quality == ChopQuality.Mid then
		return "SFX_Chop_Mid"
	end
	return "SFX_Chop_Bad"
end

local function chunkCountFor(quality: number): number
	if quality == ChopQuality.Great then
		return ChopConfig.GreatChunkCount
	elseif quality == ChopQuality.Good then
		return ChopConfig.GoodChunkCount
	elseif quality == ChopQuality.Mid then
		return ChopConfig.MidChunkCount
	end
	return ChopConfig.BadChunkCount
end

type Tint = {
	Quality: number,
	Rock: Color3,
}

local white = Color3.new(1, 1, 1)
local templates: { [string]: Model } = {}
local missingTemplates: { [string]: true } = {}

local function templateFor(key: string): Model?
	local cached = templates[key]
	if cached or missingTemplates[key] then
		return cached
	end
	local asset = AssetRegistry.get(key)
	if asset:IsA("Model") then
		templates[key] = asset
		return asset
	end
	asset:Destroy()
	missingTemplates[key] = true
	return nil
end

local function scaleSequence(sequence: NumberSequence, scale: number): NumberSequence
	local keypoints = {}
	for _, keypoint in sequence.Keypoints do
		table.insert(
			keypoints,
			NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * scale, keypoint.Envelope * scale)
		)
	end
	return NumberSequence.new(keypoints)
end

local function qualityColor(quality: number): Color3
	return (ChopStyleConfig.Qualities[quality] or ChopStyleConfig.Fallback).Color
end

local function prepareEmitter(emitter: ParticleEmitter, scale: number, tint: Tint, countScale: number)
	local minQuality = emitter:GetAttribute(ChopEffectConfig.MinQualityAttribute)
	if type(minQuality) == "number" and tint.Quality < minQuality then
		emitter:Destroy()
		return
	end
	local kind = emitter:GetAttribute(ChopEffectConfig.TintAttribute)
	if kind == "Quality" then
		emitter.Color = ColorSequence.new(qualityColor(tint.Quality))
	elseif kind == "QualityHot" then
		local color = qualityColor(tint.Quality)
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, white),
			ColorSequenceKeypoint.new(0.35, color),
			ColorSequenceKeypoint.new(1, color),
		})
	elseif kind == "Rock" then
		emitter.Color = ColorSequence.new(tint.Rock)
	elseif kind == "Dust" then
		emitter.Color = ColorSequence.new(tint.Rock:Lerp(white, ChopEffectConfig.DustLightenAmount))
	end
	local count = emitter:GetAttribute("EmitCount")
	if type(count) == "number" and count > 1 and countScale ~= 1 then
		emitter:SetAttribute("EmitCount", math.max(1, math.floor(count * countScale + 0.5)))
	end
	if scale ~= 1 then
		emitter.Size = scaleSequence(emitter.Size, scale)
		emitter.Speed = NumberRange.new(emitter.Speed.Min * scale, emitter.Speed.Max * scale)
		emitter.Acceleration *= scale
	end
end

local function playEffect(key: string, cframe: CFrame, scale: number, tint: Tint, countScale: number?)
	local template = templateFor(key)
	if not template then
		return
	end
	local model = template:Clone()
	local root = model.PrimaryPart
	local origin = if root then root.CFrame else model:GetPivot()
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			prepareEmitter(descendant, scale, tint, (countScale or 1) * LowGraphics.EmitScale())
		elseif scale == 1 then
			continue
		elseif descendant:IsA("Attachment") then
			descendant.Position *= scale
		elseif descendant:IsA("PointLight") then
			descendant.Range *= scale
		elseif descendant:IsA("BasePart") and descendant ~= root then
			local offset = origin:ToObjectSpace(descendant.CFrame)
			descendant.Size *= scale
			descendant.CFrame = origin * (offset.Rotation + offset.Position * scale)
		end
	end
	model:PivotTo(cframe)
	model.Parent = workspace
	VFXEmit.emit(model, {
		onDone = function()
			model:Destroy()
		end,
	})
end

local function scaleFor(sizeX: number): number
	return math.max(ChopEffectConfig.MinScale, sizeX / ChopConfig.ReferenceRockSize)
end

local function impactCFrame(center: Vector3, sizeX: number): CFrame
	local camera = workspace.CurrentCamera
	local toward = if camera then camera.CFrame.Position - center else Vector3.zAxis
	local flat = Vector3.new(toward.X, 0, toward.Z)
	local direction = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.zAxis
	local point = center + direction * sizeX * ChopEffectConfig.ImpactInsetFraction
	return CFrame.lookAt(point, point + direction)
end

local function baseCFrame(center: Vector3, sizeY: number): CFrame
	return CFrame.new(center - Vector3.new(0, sizeY / 2, 0))
end

local function breakEffectKey(quality: number): string
	if quality == ChopQuality.Master then
		return ChopEffectConfig.MasterBurstKey
	elseif quality == ChopQuality.Perfect then
		return ChopEffectConfig.PerfectKey
	end
	return ChopEffectConfig.BreakKey
end

local function playBreakEffect(center: Vector3, size: Vector3, quality: number, rockColor: Color3)
	playEffect(
		breakEffectKey(quality),
		baseCFrame(center, size.Y),
		scaleFor(size.X),
		{ Quality = quality, Rock = rockColor },
		ChopEffectConfig.BreakCountScale[quality]
	)
end

local shakeOrigins: { [BasePart]: CFrame } = {}
local shakeIds: { [BasePart]: number } = {}

local function shake(part: BasePart)
	local origin = shakeOrigins[part] or part.CFrame
	shakeOrigins[part] = origin
	local id = (shakeIds[part] or 0) + 1
	shakeIds[part] = id
	local sizeScale = math.max(1, part.Size.X / ChopConfig.ReferenceRockSize)
	task.spawn(function()
		for step = 1, shakeSteps do
			if shakeIds[part] ~= id then
				return
			end
			if not part.Parent then
				shakeOrigins[part] = nil
				shakeIds[part] = nil
				return
			end
			local strength = 1 - (step - 1) / shakeSteps
			local studs = shakeStuds * sizeScale * strength
			local radians = math.rad(shakeDegrees) * strength
			part.CFrame = origin
				* CFrame.new((math.random() * 2 - 1) * studs, 0, (math.random() * 2 - 1) * studs)
				* CFrame.Angles((math.random() * 2 - 1) * radians, 0, (math.random() * 2 - 1) * radians)
			task.wait(shakeStepSeconds)
		end
		if shakeIds[part] ~= id then
			return
		end
		shakeOrigins[part] = nil
		shakeIds[part] = nil
		if part.Parent then
			part.CFrame = origin
		end
	end)
end

type ChunkLook = {
	Color: Color3,
	Material: Enum.Material,
	MaterialVariant: string,
}

local function spawnChunks(position: Vector3, size: Vector3, look: ChunkLook, chunkCount: number)
	local halfSize = size / 2
	local chunks: { BasePart } = {}
	local scale = ChopConfig.ChunkSpawnVelocityScale
	local sizeScale = math.max(1, size.X / ChopConfig.ReferenceRockSize)
	local scaledCount = math.floor(chunkCount * sizeScale * LowGraphics.EmitScale() + 0.5)
	for _ = 1, scaledCount do
		local chunk = Instance.new("Part")
		chunk.Name = "Rock_Chunk"
		chunk.Size = Vector3.new(
			0.7 + math.random() * 0.8,
			0.7 + math.random() * 0.8,
			0.7 + math.random() * 0.8
		) * sizeScale
		chunk.Position = position
			+ Vector3.new(
				(math.random() * 2 - 1) * halfSize.X * 0.5,
				(math.random() * 2 - 1) * halfSize.Y * 0.5,
				(math.random() * 2 - 1) * halfSize.Z * 0.5
			)
		chunk.Anchored = false
		chunk.CanCollide = true
		chunk.CanQuery = false
		chunk.Color = look.Color
		chunk.Material = look.Material
		chunk.MaterialVariant = look.MaterialVariant
		chunk.Parent = workspace
		chunk.AssemblyLinearVelocity = Vector3.new(
			(math.random() * 2 - 1) * scale,
			math.random() * scale * 0.7,
			(math.random() * 2 - 1) * scale
		)
		chunk.AssemblyAngularVelocity =
			Vector3.new((math.random() * 2 - 1) * 8, (math.random() * 2 - 1) * 8, (math.random() * 2 - 1) * 8)
		table.insert(chunks, chunk)
	end

	task.delay(ChopConfig.ChunkLifetimeSeconds, function()
		for _, chunk in chunks do
			if chunk.Parent then
				chunk:Destroy()
			end
		end
	end)
end

local function lookOf(part: BasePart): ChunkLook
	return { Color = part.Color, Material = part.Material, MaterialVariant = part.MaterialVariant }
end

local function hide(part: BasePart)
	part.Transparency = 1
	part.CanCollide = false
	for _, descendant in part:GetDescendants() do
		if descendant:IsA("BillboardGui") then
			descendant.Enabled = false
		elseif descendant:IsA("Highlight") then
			descendant.Enabled = false
		elseif descendant:IsA("BasePart") then
			descendant.Transparency = 1
		end
	end
end

local splitPush: SplitModel.Push = {
	OutwardStuds = ChopConfig.SplitPushXStuds,
	UpStuds = ChopConfig.SplitPushYStuds,
	TorqueRadPerSec = ChopConfig.SplitTorqueRadPerSec,
}

local function splitRock(part: BasePart, piecesSeconds: number)
	hide(part)

	local model = SplitModel.Spawn(part, splitPush)
	if model then
		task.delay(piecesSeconds, function()
			if model.Parent then
				model:Destroy()
			end
		end)
		return
	end

	local basePos = part.Position
	local originalSize = part.Size
	local halfSize = Vector3.new(originalSize.X / 2, originalSize.Y, originalSize.Z)
	local halfOffsetX = originalSize.X / 4

	local halves: { BasePart } = {}
	for _, offsetX in { -halfOffsetX, halfOffsetX } do
		local half = Instance.new("Part")
		half.Name = `{part.Name}_Half`
		half.Size = halfSize
		half.Position = basePos + Vector3.new(offsetX, 0, 0)
		half.Anchored = false
		half.CanCollide = true
		half.CanQuery = false
		half.Color = part.Color
		half.Material = part.Material
		half.MaterialVariant = part.MaterialVariant
		half.Parent = workspace
		table.insert(halves, half)

		local direction = if offsetX < 0 then -1 else 1
		half.AssemblyLinearVelocity =
			Vector3.new(direction * ChopConfig.SplitPushXStuds, ChopConfig.SplitPushYStuds, 0)
		half.AssemblyAngularVelocity = Vector3.new(0, 0, -direction * ChopConfig.SplitTorqueRadPerSec)
	end

	task.delay(piecesSeconds, function()
		for _, half in halves do
			if half.Parent then
				half:Destroy()
			end
		end
	end)
end

function Effects.Rise(part: BasePart, target: CFrame, onRisen: () -> ())
	local bottom = target.Position - Vector3.new(0, part.Size.Y / 2, 0)
	local anchor = anchorAt(bottom, RockSpawnConfig.DustLifetimeSeconds)
	emit(
		RockSpawnConfig.RiseDustKey,
		anchor,
		RockSpawnConfig.DustEmitCount,
		RockSpawnConfig.DustLifetimeSeconds
	)
	playSound(RockSpawnConfig.RiseSoundKey, anchor, nil, RockSpawnConfig.RiseSoundStartSeconds)
	local info = TweenInfo.new(RockSpawnConfig.RiseSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(part, info, { CFrame = target })
	tween.Completed:Once(function()
		if part.Parent then
			part.CFrame = target
			onRisen()
		end
	end)
	tween:Play()
end

function Effects.Sink(part: BasePart, seconds: number, onSunk: () -> ())
	local bottom = part.Position - Vector3.new(0, part.Size.Y / 2, 0)
	local anchor = anchorAt(bottom, RockSpawnConfig.DustLifetimeSeconds)
	emit(
		RockSpawnConfig.RiseDustKey,
		anchor,
		RockSpawnConfig.DustEmitCount,
		RockSpawnConfig.DustLifetimeSeconds
	)
	playSound(RockSpawnConfig.RiseSoundKey, anchor, nil, RockSpawnConfig.RiseSoundStartSeconds)
	local target = part.CFrame - Vector3.new(0, part.Size.Y + RockSpawnConfig.RiseDepthPaddingStuds, 0)
	local info = TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tween = TweenService:Create(part, info, { CFrame = target })
	tween.Completed:Once(onSunk)
	tween:Play()
end

function Effects.Crack(part: BasePart)
	playSound("SFX_Rock_Crack", part)
	shake(part)
	playEffect(
		ChopEffectConfig.CrackKey,
		impactCFrame(part.Position, part.Size.X),
		scaleFor(part.Size.X),
		{ Quality = ChopQuality.Crack, Rock = part.Color }
	)
end

function Effects.Hit(part: BasePart, quality: number)
	playSound(qualitySoundKey(quality), part)
	playSound("SFX_Rock_Break", part, ChopConfig.HitSoundVolumeMultiplier)
	shake(part)
	playEffect(
		ChopEffectConfig.HitKey,
		impactCFrame(part.Position, part.Size.X),
		scaleFor(part.Size.X),
		{ Quality = quality, Rock = part.Color }
	)
end

function Effects.MasterStart(part: BasePart)
	playSound(MasterChopConfig.SoundKey, part)
	playEffect(
		ChopEffectConfig.MasterWindUpKey,
		baseCFrame(part.Position, part.Size.Y),
		scaleFor(part.Size.X),
		{ Quality = ChopQuality.Master, Rock = part.Color }
	)
end

function Effects.Break(part: BasePart, quality: number, piecesSeconds: number)
	if quality ~= ChopQuality.Master then
		playSound(qualitySoundKey(quality), part)
	end
	playSound("SFX_Rock_Break", part)
	playBreakEffect(part.Position, part.Size, quality, part.Color)
	if quality == ChopQuality.Master or quality == ChopQuality.Perfect then
		splitRock(part, piecesSeconds)
		return
	end
	hide(part)
	spawnChunks(part.Position, part.Size, lookOf(part), chunkCountFor(quality))
end

function Effects.Shown(position: Vector3, sizeX: number, quality: number, isBroken: boolean)
	local anchor = anchorAt(position, math.max(RockSpawnConfig.DustLifetimeSeconds, 5))
	local size = Vector3.new(sizeX, sizeX, sizeX)
	local rockColor = RockSpawnConfig.OthersChunkColor
	local chunkLook: ChunkLook = { Color = rockColor, Material = Enum.Material.Slate, MaterialVariant = "" }
	local tint: Tint = { Quality = quality, Rock = rockColor }
	if quality == ChopQuality.Master then
		playSound(MasterChopConfig.SoundKey, anchor)
		playEffect(ChopEffectConfig.MasterWindUpKey, baseCFrame(position, sizeX), scaleFor(sizeX), tint)
		task.delay(MasterChopConfig.ImpactDelaySeconds, function()
			playSound("SFX_Rock_Break", anchor)
			playBreakEffect(position, size, quality, rockColor)
			spawnChunks(position, size, chunkLook, RockSpawnConfig.OthersChunkCount)
		end)
		return
	end
	if quality == ChopQuality.Crack then
		playSound("SFX_Rock_Crack", anchor)
		playEffect(ChopEffectConfig.CrackKey, impactCFrame(position, sizeX), scaleFor(sizeX), tint)
		return
	end
	playSound(qualitySoundKey(quality), anchor)
	playSound("SFX_Rock_Break", anchor, if isBroken then nil else ChopConfig.HitSoundVolumeMultiplier)
	if not isBroken then
		playEffect(ChopEffectConfig.HitKey, impactCFrame(position, sizeX), scaleFor(sizeX), tint)
		return
	end
	playBreakEffect(position, size, quality, rockColor)
	spawnChunks(position, size, chunkLook, RockSpawnConfig.OthersChunkCount)
end

return Effects
