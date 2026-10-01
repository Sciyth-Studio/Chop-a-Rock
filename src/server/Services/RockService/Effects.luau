--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Types = require(script.Parent.Types)

local Effects = {}

local shakeSteps = 4
local shakeStuds = 0.3
local splitModelAttribute = "SplitModel"

local function playSound(key: string, part: BasePart)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Sound") then
		asset:Destroy()
		return
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

local function shake(part: BasePart)
	local origin = part.CFrame
	task.spawn(function()
		for _ = 1, shakeSteps do
			if not part.Parent then
				return
			end
			part.CFrame = origin
				* CFrame.new((math.random() * 2 - 1) * shakeStuds, 0, (math.random() * 2 - 1) * shakeStuds)
			task.wait(0.04)
		end
		if part.Parent then
			part.CFrame = origin
		end
	end)
end

local function spawnChunks(part: BasePart, chunkCount: number, isOnSurface: boolean)
	local basePos = if isOnSurface then part.Position + Vector3.new(0, part.Size.Y, 0) else part.Position
	local halfSize = part.Size / 2
	local color = part.Color
	local material = part.Material
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
	shake(rock.Part)
	spawnChunks(rock.Part, ChopConfig.BadChunkCount, true)
end

local function spawnSplitModel(part: BasePart): Model?
	local key = part:GetAttribute(splitModelAttribute)
	if type(key) ~= "string" then
		return nil
	end
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Model") then
		asset:Destroy()
		return nil
	end
	local model = asset :: Model
	local boxCFrame, boxSize = model:GetBoundingBox()
	model.WorldPivot = boxCFrame
	model:ScaleTo(model:GetScale() * part.Size.X / boxSize.X)
	model:PivotTo(part.CFrame)

	local pieces: { BasePart } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = true
			descendant.CanQuery = false
			descendant.Color = part.Color
			descendant.Material = part.Material
			table.insert(pieces, descendant)
		end
	end
	model.Parent = workspace

	local up = part.CFrame.UpVector
	for _, piece in pieces do
		local offset = piece.Position - part.Position
		local outward = offset - up * offset:Dot(up)
		local direction = if outward.Magnitude > 1e-3 then outward.Unit else part.CFrame.RightVector
		piece.AssemblyLinearVelocity = direction * ChopConfig.SplitPushXStuds
			+ up * ChopConfig.SplitPushYStuds
		piece.AssemblyAngularVelocity = up:Cross(direction) * ChopConfig.SplitTorqueRadPerSec
	end
	return model
end

local function splitRock(rock: Types.Rock)
	local part = rock.Part
	Effects.Hide(rock)

	local model = spawnSplitModel(part)
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
	spawnChunks(rock.Part, chunkCountFor(quality), false)
	task.delay(rock.Config.RespawnSeconds, function()
		Effects.Restore(rock)
	end)
end

return Effects
