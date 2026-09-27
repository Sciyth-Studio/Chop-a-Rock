--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Packets = require(ReplicatedStorage.Packets)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local ROCK_TAG = "ChopRock"

local RockService: Lifecycle.System = { Name = "RockService" }

local trove = Trove.new()
local rockPart: BasePart? = nil
local rockPrompt: ProximityPrompt? = nil

type ChopState = { StartTime: number }
local chops: { [Player]: ChopState } = {}

local function computePosition(elapsed: number): number
	local phase = (elapsed / ChopConfig.CycleSeconds) % 1
	return 1 - math.abs(2 * phase - 1)
end

local function classify(position: number): (number, number)
	local quality: number
	local multiplier: number
	if position >= ChopConfig.PerfectThreshold then
		quality = ChopQuality.Perfect
		multiplier = ChopConfig.PerfectPayoutMultiplier
	elseif position >= ChopConfig.GoodThreshold then
		quality = ChopQuality.Good
		multiplier = ChopConfig.GoodPayoutMultiplier
	else
		quality = ChopQuality.Sloppy
		multiplier = ChopConfig.SloppyPayoutMultiplier
	end
	local payout = math.max(0, math.floor(RockConfig.Rocks.Basic.BasePayout * multiplier + 0.5))
	return quality, payout
end

local function breakRock()
	local part = rockPart
	local prompt = rockPrompt
	if not part or not prompt then
		return
	end
	part.Transparency = 1
	part.CanCollide = false
	prompt.Enabled = false
	task.delay(RockConfig.Rocks.Basic.RespawnSeconds, function()
		if part.Parent and prompt.Parent then
			part.Transparency = 0
			part.CanCollide = true
			prompt.Enabled = true
		end
	end)
end

function RockService.Init(_self: any, _services: { [string]: any }) end

function RockService.Start(_self: any)
	local part = Instance.new("Part")
	part.Name = "Rock_Basic"
	part.Size = Vector3.new(6, 6, 6)
	part.Position = Vector3.new(0, 3, 0)
	part.Anchored = true
	part.CanCollide = true
	part.Color = Color3.fromRGB(120, 120, 120)
	part.Material = Enum.Material.Slate
	part.Parent = workspace
	trove:Add(part)
	CollectionService:AddTag(part, ROCK_TAG)
	rockPart = part

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Chop"
	prompt.ObjectText = RockConfig.Rocks.Basic.DisplayName
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	rockPrompt = prompt

	trove:Add(prompt.Triggered:Connect(function(player: Player)
		if not prompt.Enabled or chops[player] then
			return
		end
		chops[player] = { StartTime = os.clock() }
		prompt.Enabled = false
		Packets.ChopMinigameStart:FireClient(player)
	end))

	trove:Add(Packets.ChopRelease.OnServerEvent:Connect(function(player: Player)
		local state = chops[player]
		if not state then
			return
		end
		chops[player] = nil
		local elapsed = math.max(0, os.clock() - state.StartTime - ChopConfig.LatencyCompensationSeconds)
		local position = computePosition(elapsed)
		local quality, payout = classify(position)
		Packets.ChopResult:FireClient(player, quality, payout)
		print(
			`[RockService] {player.Name} chopped: quality={quality}, position={string.format("%.3f", position)}, payout={payout}`
		)
		breakRock()
	end))

	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		chops[player] = nil
	end))
end

function RockService.Destroy(_self: any)
	trove:Clean()
	rockPart = nil
	rockPrompt = nil
	table.clear(chops)
end

return RockService
