--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Packets = require(ReplicatedStorage.Packets)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Session = require(script.Session)
local SpawnPoints = require(script.SpawnPoints)
local Spawner = require(script.Spawner)
local Types = require(script.Types)

local RockService = { Name = "RockService" }

local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}

local shapes: { [string]: Types.Shape } = {}
local spots: { [string]: { Types.Spot } } = {}
local owned: { [Player]: { [number]: Types.Rock } } = {}
local generations: { [Player]: number } = {}
local sessions: { [Player]: Types.Session } = {}
local forcedMasters: { [Player]: boolean } = {}
local spotViewers: { [Player]: true } = {}
local warned: { [string]: boolean } = {}
local nextId = 0

local function warnOnce(key: string, message: string)
	if warned[key] then
		return
	end
	warned[key] = true
	warn(message)
end

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function zoneRocks(rocks: { [number]: Types.Rock }, zone: string): { Types.Rock }
	local list: { Types.Rock } = {}
	for _, rock in rocks do
		if rock.Zone == zone then
			table.insert(list, rock)
		end
	end
	return list
end

local function spawnRock(player: Player, zone: string): boolean
	local rocks = owned[player]
	local zoneConfig = RockSpawnConfig.Zones[zone]
	if not rocks or not zoneConfig then
		return true
	end
	local existing = zoneRocks(rocks, zone)
	local key = Spawner.PickKey(random, zoneConfig.Weights, zoneConfig.RockCount, existing)
	local shape = if key then shapes[key] else nil
	local configs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	local config = if key then configs[key] else nil
	if not key or not shape or not config then
		return true
	end
	local spot = Spawner.PickSpot(random, spots[zone] or {}, shape, existing, rootPosition(player))
	if not spot then
		warnOnce(`{zone}/{key}`, `[RockService] No free spawn spot for {key} in {zone}`)
		return false
	end
	nextId += 1
	local rock: Types.Rock = {
		Id = nextId,
		Key = key,
		Config = config,
		Zone = zone,
		CFrame = shape.Rotation
			+ spot.Position
			+ Vector3.new(0, shape.Size.Y / 2 - RockSpawnConfig.SinkStuds, 0),
		Size = shape.Size,
		Modifier = nil,
		UpAt = os.clock() + RockSpawnConfig.RiseSeconds,
	}
	rocks[rock.Id] = rock
	Packets.RockSpawned:FireClient(player, rock.Id, key, rock.CFrame.Position, rock.Modifier or "")
	return true
end

local function scheduleSpawn(player: Player, zone: string, delaySeconds: number)
	local generation = generations[player]
	task.delay(delaySeconds, function()
		if generations[player] ~= generation then
			return
		end
		if not spawnRock(player, zone) then
			scheduleSpawn(player, zone, RockSpawnConfig.RespawnSeconds)
		end
	end)
end

local function retire(player: Player, rock: Types.Rock, delaySeconds: number)
	local rocks = owned[player]
	if not rocks or rocks[rock.Id] ~= rock then
		return
	end
	rocks[rock.Id] = nil
	scheduleSpawn(player, rock.Zone, delaySeconds)
end

local function showOthers(player: Player, rock: Types.Rock, quality: number, isBroken: boolean)
	local position = rock.CFrame.Position
	for _, other in Players:GetPlayers() do
		if other == player then
			continue
		end
		local otherPosition = rootPosition(other)
		if
			otherPosition
			and (otherPosition - position).Magnitude <= RockSpawnConfig.OthersEffectMaxDistance
		then
			Packets.RockChopShown:FireClient(other, position, rock.Size.X, quality, isBroken)
		end
	end
end

local function onReady(player: Player)
	if owned[player] then
		return
	end
	owned[player] = {}
	generations[player] = (generations[player] or 0) + 1
	for zone, zoneConfig in RockSpawnConfig.Zones do
		local zoneSpots = spots[zone]
		if not zoneSpots or #zoneSpots == 0 then
			warnOnce(zone, `[RockService] {zone} has no spawn spots`)
			continue
		end
		for _ = 1, zoneConfig.RockCount do
			if not spawnRock(player, zone) then
				scheduleSpawn(player, zone, RockSpawnConfig.RespawnSeconds)
			end
		end
	end
end

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

local function onChopRequest(player: Player, id: number)
	local rocks = owned[player]
	local rock = if rocks then rocks[id] else nil
	if not rock or sessions[player] or os.clock() < rock.UpAt - RockSpawnConfig.RiseSlackSeconds then
		return
	end
	if not services.DataService:GetData(player) then
		return
	end
	local position = rootPosition(player)
	local reach = ChopConfig.PromptRangeStuds + rock.Size.X / 2 + RockSpawnConfig.ChopRangeSlackStuds
	if not position or (position - rock.CFrame.Position).Magnitude > reach then
		return
	end
	local strength = services.StatsService:GetStrength(player)
	local canBreak = strength >= rock.Config.StrengthRequired
	local strengthRatio = strength / math.max(rock.Config.StrengthRequired, 1)
	local session = Session.New(rock, canBreak, strengthRatio, ChopZones.RandomCenter(random), os.clock())
	sessions[player] = session
	services.PetService:PutAway(player)
	Packets.RockMinigameStart:FireClient(
		player,
		rock.Id,
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
		Packets.RockChopped:FireClient(player, rock.Id, ChopQuality.Crack, false)
		showOthers(player, rock, ChopQuality.Crack, false)
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
		payout = services.IndexService:ApplyCashMultiplier(player, payout)
		services.DataService:AdjustCash(player, payout)
	end
	local isBroken = Session.IsBroken(session)
	if isBroken or quality == ChopQuality.Master then
		services.IndexService:RecordRock(player, rock.Key)
	end
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
		retire(player, rock, MasterChopConfig.ImpactDelaySeconds + RockSpawnConfig.RespawnSeconds)
		Packets.RockChopped:FireClient(player, rock.Id, quality, true)
		showOthers(player, rock, quality, true)
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
		retire(player, rock, RockSpawnConfig.RespawnSeconds)
		Packets.RockChopped:FireClient(player, rock.Id, quality, true)
		showOthers(player, rock, quality, true)
		return
	end

	Packets.RockChopped:FireClient(player, rock.Id, quality, false)
	showOthers(player, rock, quality, false)
	scheduleNextRound(player, session)
end

local function onLeave(player: Player)
	sessions[player] = nil
end

local function onPlayerRemoving(player: Player)
	forcedMasters[player] = nil
	spotViewers[player] = nil
	owned[player] = nil
	generations[player] = nil
	onLeave(player)
end

function RockService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function RockService.Start(_self: any)
	local configs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	for key in configs do
		local shape = SpawnPoints.Shape(key)
		if shape then
			shapes[key] = shape
		end
	end
	local started = os.clock()
	spots = SpawnPoints.Sample(shapes)
	for zone, zoneSpots in spots do
		print(
			`[RockService] {zone}: {#zoneSpots} spawn spots ({string.format(
				"%.0f",
				(os.clock() - started) * 1000
			)} ms)`
		)
	end

	trove:Add(Packets.RockReady.OnServerEvent:Connect(onReady))
	trove:Add(Packets.RockChop.OnServerEvent:Connect(onChopRequest))
	trove:Add(Packets.ChopRelease.OnServerEvent:Connect(onRelease))
	trove:Add(Packets.ChopLeave.OnServerEvent:Connect(onLeave))
	trove:Add(Players.PlayerRemoving:Connect(onPlayerRemoving))
end

function RockService.ToggleSpawnSpots(_self: any, player: Player): boolean
	local isShown = not spotViewers[player]
	if isShown then
		spotViewers[player] = true
	else
		spotViewers[player] = nil
	end
	local positions: { Vector3 } = {}
	local keys: { string } = {}
	if isShown then
		for _, zoneSpots in spots do
			for _, spot in zoneSpots do
				if spot.Largest then
					table.insert(positions, spot.Position)
					table.insert(keys, spot.Largest)
				end
			end
		end
	end
	Packets.RockSpawnSpots:FireClient(player, positions, keys)
	return isShown
end

function RockService.ForceNextMaster(_self: any, player: Player)
	forcedMasters[player] = true
end

function RockService.ConsumeForcedMaster(_self: any, player: Player): boolean
	local isForced = forcedMasters[player] == true
	forcedMasters[player] = nil
	return isForced
end

function RockService.RollMaster(_self: any, quality: number, strengthRatio: number): boolean
	return Session.IsMaster(random, quality, strengthRatio)
end

function RockService.HasSession(_self: any, player: Player): boolean
	return sessions[player] ~= nil
end

function RockService.Destroy(_self: any)
	trove:Clean()
	table.clear(owned)
	table.clear(generations)
	table.clear(sessions)
	table.clear(forcedMasters)
	table.clear(spotViewers)
end

return RockService
