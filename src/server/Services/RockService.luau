--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Packets = require(ReplicatedStorage.Packets)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local DataService = require(script.Parent.DataService)
local StatsService = require(script.Parent.StatsService)

local ROCK_TAG = "ChopRock"
local CRACK_SHAKE_STEPS = 4
local CRACK_SHAKE_STUDS = 0.3

local RockService: Lifecycle.System = { Name = "RockService" }

local trove = Trove.new()

type RockState = {
	Key: string,
	Config: RockConfig.Rock,
	Part: BasePart,
	Prompt: ProximityPrompt,
}
type ChopState = { StartTime: number, Rock: RockState, CanBreak: boolean }

local rocks: { RockState } = {}
local chops: { [Player]: ChopState } = {}

local function computePosition(elapsed: number): number
	local phase = (elapsed / ChopConfig.CycleSeconds) % 1
	return 1 - math.abs(2 * phase - 1)
end

local function classify(position: number, config: RockConfig.Rock): (number, number)
	local quality: number
	local multiplier: number
	if position >= ChopConfig.PerfectThreshold then
		quality = ChopQuality.Perfect
		multiplier = ChopConfig.PerfectPayoutMultiplier
	elseif position >= ChopConfig.GreatThreshold then
		quality = ChopQuality.Great
		multiplier = ChopConfig.GreatPayoutMultiplier
	elseif position >= ChopConfig.GoodThreshold then
		quality = ChopQuality.Good
		multiplier = ChopConfig.GoodPayoutMultiplier
	elseif position >= ChopConfig.MidThreshold then
		quality = ChopQuality.Mid
		multiplier = ChopConfig.MidPayoutMultiplier
	else
		quality = ChopQuality.Bad
		multiplier = ChopConfig.BadPayoutMultiplier
	end
	local payout = math.max(0, math.floor(config.BasePayout * multiplier + 0.5))
	return quality, payout
end

local function playSoundOnPart(key: string, part: BasePart)
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

local function hideRock(rock: RockState)
	rock.Part.Transparency = 1
	rock.Part.CanCollide = false
	rock.Prompt.Enabled = false
end

local function restoreRock(rock: RockState)
	if rock.Part.Parent and rock.Prompt.Parent then
		rock.Part.Transparency = 0
		rock.Part.CanCollide = true
		rock.Prompt.Enabled = true
	end
end

local function crackRock(rock: RockState)
	local part = rock.Part
	local origin = part.CFrame
	rock.Prompt.Enabled = false
	playSoundOnPart("SFX_Rock_Crack", part)
	task.spawn(function()
		for _ = 1, CRACK_SHAKE_STEPS do
			if not part.Parent then
				return
			end
			part.CFrame = origin
				* CFrame.new(
					(math.random() * 2 - 1) * CRACK_SHAKE_STUDS,
					0,
					(math.random() * 2 - 1) * CRACK_SHAKE_STUDS
				)
			task.wait(0.04)
		end
		if part.Parent then
			part.CFrame = origin
		end
	end)
	task.delay(rock.Config.RespawnSeconds, function()
		restoreRock(rock)
	end)
end

local function breakRockWithDebris(rock: RockState, chunkCount: number)
	local part = rock.Part
	local basePos = part.Position
	local halfSize = part.Size / 2
	local color = part.Color
	local material = part.Material
	hideRock(rock)

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

	task.delay(rock.Config.RespawnSeconds, function()
		restoreRock(rock)
	end)
end

local function splitRock(rock: RockState)
	local part = rock.Part
	local basePos = part.Position
	local originalSize = part.Size
	local halfSize = Vector3.new(originalSize.X / 2, originalSize.Y, originalSize.Z)
	local halfOffsetX = originalSize.X / 4
	local color = part.Color
	local material = part.Material
	hideRock(rock)

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
		restoreRock(rock)
	end)
end

local function findAuthoredRock(key: string): BasePart?
	for _, tagged in CollectionService:GetTagged(ROCK_TAG) do
		if
			tagged:IsA("BasePart")
			and tagged:GetAttribute("RockKey") == key
			and tagged:IsDescendantOf(workspace)
		then
			return tagged
		end
	end
	return nil
end

local function spawnRock(key: string, config: RockConfig.Rock): RockState
	local part = findAuthoredRock(key)
	if not part then
		local created = Instance.new("Part")
		created.Name = `Rock_{key}`
		created.Size = config.PlaceholderSize
		created.Position = config.PlaceholderPosition
		created.Color = config.PlaceholderColor
		created.Material = Enum.Material.Slate
		created.Parent = workspace
		trove:Add(created)
		CollectionService:AddTag(created, ROCK_TAG)
		created:SetAttribute("RockKey", key)
		part = created
	end
	local rockPart = part :: BasePart
	rockPart.Anchored = true
	rockPart.CanCollide = true

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Chop"
	prompt.ObjectText = config.DisplayName
	prompt.HoldDuration = ChopConfig.PromptHoldSeconds
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = ChopConfig.PromptRangeStuds + rockPart.Size.X / 2
	prompt.RequiresLineOfSight = false
	prompt.Parent = rockPart
	trove:Add(prompt)

	return { Key = key, Config = config, Part = rockPart, Prompt = prompt }
end

local function onTriggered(rock: RockState, player: Player)
	if not rock.Prompt.Enabled or chops[player] or player:GetAttribute("DataLoaded") ~= true then
		return
	end
	local canBreak = StatsService:GetStrength(player) >= rock.Config.StrengthRequired
	chops[player] = { StartTime = os.clock(), Rock = rock, CanBreak = canBreak }
	rock.Prompt.Enabled = false
	Packets.ChopMinigameStart:FireClient(player, rock.Part, canBreak)
end

local function onRelease(player: Player)
	local state = chops[player]
	if not state then
		return
	end
	chops[player] = nil
	local rock = state.Rock

	if not state.CanBreak then
		Packets.ChopResult:FireClient(player, ChopQuality.Crack, 0)
		print(`[RockService] {player.Name} cracked {rock.Key} (too weak)`)
		crackRock(rock)
		return
	end

	local elapsed = math.max(0, os.clock() - state.StartTime - ChopConfig.LatencyCompensationSeconds)
	local position = computePosition(elapsed)
	local quality, payout = classify(position, rock.Config)
	if payout > 0 then
		DataService:AdjustCash(player, payout)
	end
	Packets.ChopResult:FireClient(player, quality, payout)
	print(
		`[RockService] {player.Name} chopped {rock.Key}: quality={quality}, position={string.format(
			"%.3f",
			position
		)}, payout={payout}`
	)

	local part = rock.Part
	if quality == ChopQuality.Perfect then
		playSoundOnPart("SFX_Chop_Perfect", part)
		playSoundOnPart("SFX_Rock_Break", part)
		splitRock(rock)
	elseif quality == ChopQuality.Great then
		playSoundOnPart("SFX_Chop_Great", part)
		playSoundOnPart("SFX_Rock_Break", part)
		breakRockWithDebris(rock, ChopConfig.GreatChunkCount)
	elseif quality == ChopQuality.Good then
		playSoundOnPart("SFX_Chop_Good", part)
		playSoundOnPart("SFX_Rock_Break", part)
		breakRockWithDebris(rock, ChopConfig.GoodChunkCount)
	elseif quality == ChopQuality.Mid then
		playSoundOnPart("SFX_Chop_Mid", part)
		playSoundOnPart("SFX_Rock_Break", part)
		breakRockWithDebris(rock, ChopConfig.MidChunkCount)
	else
		playSoundOnPart("SFX_Chop_Bad", part)
		playSoundOnPart("SFX_Rock_Break", part)
		breakRockWithDebris(rock, ChopConfig.BadChunkCount)
	end
end

function RockService.Init(_self: any, _services: { [string]: any }) end

function RockService.Start(_self: any)
	local rockConfigs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	for key, config in rockConfigs do
		local rock = spawnRock(key, config)
		table.insert(rocks, rock)
		trove:Add(rock.Prompt.Triggered:Connect(function(player: Player)
			onTriggered(rock, player)
		end))
	end

	trove:Add(Packets.ChopRelease.OnServerEvent:Connect(onRelease))

	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		local state = chops[player]
		chops[player] = nil
		if state then
			restoreRock(state.Rock)
		end
	end))
end

function RockService.Destroy(_self: any)
	trove:Clean()
	table.clear(rocks)
	table.clear(chops)
end

return RockService
