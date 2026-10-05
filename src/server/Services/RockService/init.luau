--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Packets = require(ReplicatedStorage.Packets)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Effects = require(script.Effects)
local Rocks = require(script.Rocks)
local Session = require(script.Session)
local Types = require(script.Types)

local RockService: Lifecycle.System = { Name = "RockService" }

local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}

local rocks: { Types.Rock } = {}
local sessions: { [Player]: Types.Session } = {}
local forcedMasters: { [Player]: boolean } = {}

local function scheduleNextRound(player: Player, session: Types.Session)
	session.StartTime = nil
	session.Round += 1
	local round = session.Round
	task.delay(ChopConfig.RoundPauseSeconds, function()
		if sessions[player] ~= session or session.Round ~= round then
			return
		end
		session.Center = ChopZones.RandomCenter(random)
		session.StartTime = os.clock()
		Packets.ChopRoundStart:FireClient(player, session.Center)
	end)
end

local function onTriggered(rock: Types.Rock, player: Player)
	if not rock.Prompt.Enabled or sessions[player] or not services.DataService:GetData(player) then
		return
	end
	local strength = services.StatsService:GetStrength(player)
	local canBreak = strength >= rock.Config.StrengthRequired
	local strengthRatio = strength / math.max(rock.Config.StrengthRequired, 1)
	local session = Session.New(rock, canBreak, strengthRatio, ChopZones.RandomCenter(random), os.clock())
	sessions[player] = session
	rock.Prompt.Enabled = false
	Packets.ChopMinigameStart:FireClient(
		player,
		rock.Part,
		canBreak,
		strengthRatio,
		session.Center,
		session.Health,
		session.MaxHealth
	)
end

local function onRelease(player: Player)
	local session = sessions[player]
	if not session or not session.StartTime then
		return
	end
	if os.clock() - session.StartTime < ChopConfig.RoundInputDelaySeconds then
		return
	end
	local rock = session.Rock

	if not session.CanBreak then
		sessions[player] = nil
		Packets.ChopResult:FireClient(player, ChopQuality.Crack, 0, 0, session.Health)
		print(`[RockService] {player.Name} cracked {rock.Key} (too weak)`)
		Effects.Crack(rock)
		return
	end

	local elapsed = math.max(0, os.clock() - session.StartTime - ChopConfig.LatencyCompensationSeconds)
	local position = ChopZones.Position(elapsed)
	local quality = ChopZones.Classify(position, session.Center, session.StrengthRatio)
	local damage: number, payout: number
	local isForced = forcedMasters[player] == true
	if isForced or Session.IsMaster(random, quality, session.StrengthRatio) then
		forcedMasters[player] = nil
		quality = ChopQuality.Master
		damage, payout = Session.ApplyMaster(session)
	else
		damage, payout = Session.Apply(session, services.StatsService:GetStrength(player), quality)
	end
	if payout > 0 then
		payout = services.FriendBoostService:ApplyBoost(player, payout)
		payout = services.RebirthService:ApplyCashMultiplier(player, payout)
		services.DataService:AdjustCash(player, payout)
	end
	local isBroken = Session.IsBroken(session)
	local health = if isBroken then 0 else session.Health
	Packets.ChopResult:FireClient(player, quality, payout, damage, health)
	print(
		`[RockService] {player.Name} chopped {rock.Key}: quality={quality}, position={string.format(
			"%.3f",
			position
		)}, damage={string.format("%.2f", damage)}, health={string.format("%.2f", health)}, payout={payout}`
	)

	if quality == ChopQuality.Master then
		sessions[player] = nil
		rock.Prompt.Enabled = false
		Effects.MasterStart(rock)
		task.delay(MasterChopConfig.ImpactDelaySeconds, function()
			Effects.Break(rock, quality)
		end)
		for _, other in Players:GetPlayers() do
			services.NotificationService:Notify(
				other,
				MasterChopConfig.AnnouncementKind,
				`{player.DisplayName} landed a Master Chop!`
			)
		end
		return
	end

	if isBroken then
		sessions[player] = nil
		Effects.Break(rock, quality)
		return
	end

	Effects.Hit(rock, quality)
	scheduleNextRound(player, session)
end

local function onLeave(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	Effects.Restore(session.Rock)
end

local function onPlayerRemoving(player: Player)
	forcedMasters[player] = nil
	onLeave(player)
end

function RockService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function RockService.Start(_self: any)
	local rockConfigs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	for key, config in rockConfigs do
		local rock = Rocks.Spawn(function(instance: Instance)
			trove:Add(instance)
		end, key, config)
		table.insert(rocks, rock)
		trove:Add(rock.Prompt.Triggered:Connect(function(player: Player)
			onTriggered(rock, player)
		end))
	end

	trove:Add(Packets.ChopRelease.OnServerEvent:Connect(onRelease))
	trove:Add(Packets.ChopLeave.OnServerEvent:Connect(onLeave))
	trove:Add(Players.PlayerRemoving:Connect(onPlayerRemoving))

	if RunService:IsStudio() then
		trove:Add(Packets.DevForceMaster.OnServerEvent:Connect(function(player: Player)
			forcedMasters[player] = true
			services.NotificationService:Notify(player, "Info", "Next chop: MASTER")
		end))
	end
end

function RockService.Destroy(_self: any)
	trove:Clean()
	table.clear(rocks)
	table.clear(sessions)
	table.clear(forcedMasters)
end

return RockService
