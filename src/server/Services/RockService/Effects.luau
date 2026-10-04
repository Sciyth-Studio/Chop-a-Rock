--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local SplitModel = require(script.Parent.Parent.Parent.Utils.SplitModel)
local Types = require(script.Parent.Types)

local Effects = {}

local shakeSteps = 10
local shakeStepSeconds = 0.03
local shakeStuds = 0.5
local shakeDegrees = 3

local function playSound(key: string, part: BasePart, volumeMultiplier: number?)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
	end
	if volumeMultiplier then
		asset.Volume *= volumeMultiplier
	end
	asset.Parent = part
	asset:Play()
	task.delay(5, function()
		if asset.Parent then
			asset:Destroy()
		end
	end)
end

local function playBurst(part: BasePart)
	local asset = AssetRegistry.get(MasterChopConfig.BurstKey)
	if not asset:IsA("Attachment") then
		asset:Destroy()
		return
	end
	asset.Parent = part
	for _, descendant in asset:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			local count = descendant:GetAttribute("EmitCount")
			descendant:Emit(if type(count) == "number" then count else MasterChopConfig.BurstEmitCount)
		end
	end
	task.delay(MasterChopConfig.BurstLifetimeSeconds, function()
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

local function spawnChunks(part: BasePart, chunkCount: number)
	local basePos = part.Position
	local halfSize = part.Size / 2
	local color = part.Color
	local material = part.Material
	local materialVariant = part.MaterialVariant
	local chunks: { BasePart } = {}
	local scale = ChopConfig.ChunkSpawnVelocityScale
	local sizeScale = math.max(1, part.Size.X / ChopConfig.ReferenceRockSize)
	local scaledCount = math.floor(chunkCount * sizeScale + 0.5)
	for _ = 1, scaledCount do
		local chunk = Instance.new("Part")
		chunk.Name = "Rock_Chunk"
		chunk.Size = Vector3.new(
			0.7 + math.random() * 0.8,
			0.7 + math.random() * 0.8,
			0.7 + math.random() * 0.8
		) * sizeScale
		chunk.Position = basePos
			+ Vector3.new(
				(math.random() * 2 - 1) * halfSize.X * 0.5,
				(math.random() * 2 - 1) * halfSize.Y * 0.5,
				(math.random() * 2 - 1) * halfSize.Z * 0.5
			)
		chunk.Anchored = false
		chunk.CanCollide = true
		chunk.CanQuery = false
		chunk.Color = color
		chunk.Material = material
		chunk.MaterialVariant = materialVariant
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

function Effects.Hide(rock: Types.Rock)
	rock.Part.Transparency = 1
	rock.Part.CanCollide = false
	rock.Prompt.Enabled = false
end

function Effects.Restore(rock: Types.Rock)
	if rock.Part.Parent and rock.Prompt.Parent then
		rock.Part.Transparency = 0
		rock.Part.CanCollide = true
		rock.Prompt.Enabled = true
	end
end

function Effects.Crack(rock: Types.Rock)
	rock.Prompt.Enabled = false
	playSound("SFX_Rock_Crack", rock.Part)
	shake(rock.Part)
	task.delay(rock.Config.RespawnSeconds, function()
		Effects.Restore(rock)
	end)
end

function Effects.Hit(rock: Types.Rock, quality: number)
	playSound(qualitySoundKey(quality), rock.Part)
	playSound("SFX_Rock_Break", rock.Part, ChopConfig.HitSoundVolumeMultiplier)
	shake(rock.Part)
end

local splitPush: SplitModel.Push = {
	OutwardStuds = ChopConfig.SplitPushXStuds,
	UpStuds = ChopConfig.SplitPushYStuds,
	TorqueRadPerSec = ChopConfig.SplitTorqueRadPerSec,
}

local function splitRock(rock: Types.Rock)
	local part = rock.Part
	Effects.Hide(rock)

	local model = SplitModel.Spawn(part, splitPush)
	if model then
		task.delay(rock.Config.RespawnSeconds, function()
			if model.Parent then
				model:Destroy()
			end
			Effects.Restore(rock)
		end)
		return
	end

	local basePos = part.Position
	local originalSize = part.Size
	local halfSize = Vector3.new(originalSize.X / 2, originalSize.Y, originalSize.Z)
	local halfOffsetX = originalSize.X / 4
	local color = part.Color
	local material = part.Material
	local materialVariant = part.MaterialVariant

	local halves: { BasePart } = {}
	for _, offsetX in { -halfOffsetX, halfOffsetX } do
		local half = Instance.new("Part")
		half.Name = `Rock_{rock.Key}_Half`
		half.Size = halfSize
		half.Position = basePos + Vector3.new(offsetX, 0, 0)
		half.Anchored = false
		half.CanCollide = true
		half.CanQuery = false
		half.Color = color
		half.Material = material
		half.MaterialVariant = materialVariant
		half.Parent = workspace
		table.insert(halves, half)

		local direction = if offsetX < 0 then -1 else 1
		half.AssemblyLinearVelocity =
			Vector3.new(direction * ChopConfig.SplitPushXStuds, ChopConfig.SplitPushYStuds, 0)
		half.AssemblyAngularVelocity = Vector3.new(0, 0, -direction * ChopConfig.SplitTorqueRadPerSec)
	end

	task.delay(rock.Config.RespawnSeconds, function()
		for _, half in halves do
			if half.Parent then
				half:Destroy()
			end
		end
		Effects.Restore(rock)
	end)
end

function Effects.MasterStart(rock: Types.Rock)
	playSound(MasterChopConfig.SoundKey, rock.Part)
end

function Effects.Break(rock: Types.Rock, quality: number)
	if quality ~= ChopQuality.Master then
		playSound(qualitySoundKey(quality), rock.Part)
	end
	playSound("SFX_Rock_Break", rock.Part)
	if quality == ChopQuality.Master then
		playBurst(rock.Part)
		splitRock(rock)
		return
	end
	if quality == ChopQuality.Perfect then
		splitRock(rock)
		return
	end
	Effects.Hide(rock)
	spawnChunks(rock.Part, chunkCountFor(quality))
	task.delay(rock.Config.RespawnSeconds, function()
		Effects.Restore(rock)
	end)
end

return Effects
