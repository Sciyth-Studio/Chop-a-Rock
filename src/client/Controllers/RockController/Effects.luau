--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local SplitModel = require(ReplicatedStorage.Utils.SplitModel)

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

local function playSound(key: string, parent: Instance, volumeMultiplier: number?)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	if volumeMultiplier then
		asset.Volume *= volumeMultiplier
	end
	asset.Parent = parent
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
	local scaledCount = math.floor(chunkCount * sizeScale + 0.5)
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
	playSound(RockSpawnConfig.RiseSoundKey, anchor)
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

function Effects.Crack(part: BasePart)
	playSound("SFX_Rock_Crack", part)
	shake(part)
end

function Effects.Hit(part: BasePart, quality: number)
	playSound(qualitySoundKey(quality), part)
	playSound("SFX_Rock_Break", part, ChopConfig.HitSoundVolumeMultiplier)
	shake(part)
end

function Effects.MasterStart(part: BasePart)
	playSound(MasterChopConfig.SoundKey, part)
end

function Effects.Break(part: BasePart, quality: number, piecesSeconds: number)
	if quality ~= ChopQuality.Master then
		playSound(qualitySoundKey(quality), part)
	end
	playSound("SFX_Rock_Break", part)
	if quality == ChopQuality.Master then
		emit(
			MasterChopConfig.BurstKey,
			part,
			MasterChopConfig.BurstEmitCount,
			MasterChopConfig.BurstLifetimeSeconds
		)
		splitRock(part, piecesSeconds)
		return
	end
	if quality == ChopQuality.Perfect then
		splitRock(part, piecesSeconds)
		return
	end
	hide(part)
	spawnChunks(part.Position, part.Size, lookOf(part), chunkCountFor(quality))
end

function Effects.Shown(position: Vector3, sizeX: number, quality: number, isBroken: boolean)
	local anchor = anchorAt(position, math.max(RockSpawnConfig.DustLifetimeSeconds, 5))
	if quality == ChopQuality.Master then
		playSound(MasterChopConfig.SoundKey, anchor)
		task.delay(MasterChopConfig.ImpactDelaySeconds, function()
			Effects.Shown(position, sizeX, ChopQuality.Perfect, true)
		end)
		return
	end
	emit(RockSpawnConfig.DustKey, anchor, RockSpawnConfig.DustEmitCount, RockSpawnConfig.DustLifetimeSeconds)
	if quality == ChopQuality.Crack then
		playSound("SFX_Rock_Crack", anchor)
		return
	end
	playSound(qualitySoundKey(quality), anchor)
	playSound("SFX_Rock_Break", anchor, if isBroken then nil else ChopConfig.HitSoundVolumeMultiplier)
	if isBroken then
		spawnChunks(position, Vector3.new(sizeX, sizeX, sizeX), {
			Color = RockSpawnConfig.OthersChunkColor,
			Material = Enum.Material.Slate,
			MaterialVariant = "",
		}, RockSpawnConfig.OthersChunkCount)
	end
end

return Effects
