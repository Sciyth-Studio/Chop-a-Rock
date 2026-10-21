--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopTiming = require(ServerScriptService.Utils.ChopTiming)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Packets = require(ReplicatedStorage.Packets)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local RushRockConfig = require(ReplicatedStorage.Config.RushRockConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Rush = require(script.Rush)
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
local forcedQualities: { [Player]: number } = {}
local cheats: { [Player]: { [string]: boolean } } = {}
local rushStates: { [Player]: Types.RushState } = {}
local spotViewers: { [Player]: true } = {}
local warned: { [string]: boolean } = {}
local areas: { BasePart } = {}
local reserved: { [string]: Types.Reserved } = {}
local nextId = 0

local cheatNames: { [string]: boolean } = {
	AlwaysPerfect = true,
	OneHit = true,
	IgnoreStrength = true,
	InstantRespawn = true,
}

local function hasCheat(player: Player, name: string): boolean
	local playerCheats = cheats[player]
	return playerCheats ~= nil and playerCheats[name] == true
end

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

local expireRush: (player: Player, rock: Types.Rock) -> ()

function expireRush(player: Player, rock: Types.Rock)
	local rocks = owned[player]
	if not rocks or rocks[rock.Id] ~= rock or rock.Modifier ~= RushRockConfig.Modifier then
		return
	end
	local session = sessions[player]
	if session and session.Rock == rock then
		task.delay(RushRockConfig.ExpiryRecheckSeconds, expireRush, player, rock)
		return
	end
	rock.Modifier = nil
	local state = rushStates[player]
	if state and state.ActiveId == rock.Id then
		state.ActiveId = nil
	end
	Packets.RockRushEnded:FireClient(player, rock.Id)
end

local function spawnRock(player: Player, zone: string, isRush: boolean, forcedKey: string?): boolean
	local rocks = owned[player]
	local zoneConfig = RockSpawnConfig.Zones[zone]
	if not rocks or not zoneConfig then
		return true
	end
	local existing = zoneRocks(rocks, zone)
	local key = forcedKey or Spawner.PickKey(random, zoneConfig.Weights, zoneConfig.RockCount, existing)
	local rushState = rushStates[player]
	if isRush and rushState then
		local rushKey =
			Rush.PickKey(zoneConfig.Weights, shapes, services.StatsService:GetStrength(player), key)
		if rushKey then
			key = rushKey
		else
			isRush = false
			rushState.IsScheduled = false
		end
	end
	local shape = if key then shapes[key] else nil
	local configs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	local config = if key then configs[key] else nil
	if not key or not shape or not config then
		return true
	end
	local position = rootPosition(player)
	local blocked: { Types.Reserved } = {}
	for _, area in reserved do
		if area.Zone == zone then
			table.insert(blocked, area)
		end
	end
	local spot = if isRush or forcedKey
		then Spawner.PickSpotNear(
			random,
			spots[zone] or {},
			shape,
			existing,
			position,
			RushRockConfig.SpawnRadiusStuds,
			blocked
		)
		else Spawner.PickSpot(random, spots[zone] or {}, shape, existing, position, blocked)
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
		Modifier = if isRush then RushRockConfig.Modifier else nil,
		Weather = services.WeatherService:RollStormRock(player),
		UpAt = os.clock() + RockSpawnConfig.RiseSeconds,
	}
	rocks[rock.Id] = rock
	if isRush and rushState then
		Rush.Started(rushState, rock.Id)
		task.delay(RockSpawnConfig.RiseSeconds + RushRockConfig.CountdownSeconds, expireRush, player, rock)
	end
	Packets.RockSpawned:FireClient(
		player,
		rock.Id,
		key,
		rock.CFrame.Position,
		rock.Modifier or "",
		rock.Weather or ""
	)
	return true
end

local function scheduleSpawn(player: Player, zone: string, delaySeconds: number, isRush: boolean)
	local generation = generations[player]
	task.delay(delaySeconds, function()
		if generations[player] ~= generation then
			return
		end
		if not spawnRock(player, zone, isRush) then
			scheduleSpawn(player, zone, RockSpawnConfig.RespawnSeconds, isRush)
		end
	end)
end

local function retire(player: Player, rock: Types.Rock, delaySeconds: number)
	local rocks = owned[player]
	if not rocks or rocks[rock.Id] ~= rock then
		return
	end
	rocks[rock.Id] = nil
	local state = rushStates[player]
	if state and state.ActiveId == rock.Id then
		state.ActiveId = nil
	end
	local data = services.DataService:GetData(player)
	local isRush = state ~= nil
		and Rush.IsDue(state)
		and not Tutorial.IsActive(Tutorial.StepOf(if data then data.Tutorial else nil))
	if state and isRush then
		state.IsScheduled = true
	end
	if hasCheat(player, "InstantRespawn") then
		delaySeconds += RockSpawnConfig.AdminRespawnSeconds - RockSpawnConfig.RespawnSeconds
	end
	scheduleSpawn(player, rock.Zone, delaySeconds, isRush)
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
	rushStates[player] = Rush.New()
	generations[player] = (generations[player] or 0) + 1
	for zone, zoneConfig in RockSpawnConfig.Zones do
		local zoneSpots = spots[zone]
		if not zoneSpots or #zoneSpots == 0 then
			warnOnce(zone, `[RockService] {zone} has no spawn spots`)
			continue
		end
		for _ = 1, zoneConfig.RockCount do
			if not spawnRock(player, zone, false) then
				scheduleSpawn(player, zone, RockSpawnConfig.RespawnSeconds, false)
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
	if services.DiamondRockService:HasSession(player) or services.GeodeFallService:HasSession(player) then
		return
	end
	local data = services.DataService:GetData(player)
	if not data or not Tutorial.CanChop(Tutorial.StepOf(data.Tutorial)) then
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
	if hasCheat(player, "IgnoreStrength") then
		canBreak = true
		strengthRatio = math.max(strengthRatio, 1)
	end
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

local function onRelease(player: Player, claimed: number)
	local session = sessions[player]
	if not session or not session.StartTime then
		return
	end
	if os.clock() - session.StartTime < ChopConfig.RoundInputDelaySeconds then
		return
	end
	local rock = session.Rock
	local rushState = rushStates[player]
	if rushState then
		Rush.RecordChop(rushState, os.clock())
	end

	if not session.CanBreak then
		sessions[player] = nil
		Packets.ChopResult:FireClient(player, ChopQuality.Crack, 0, 0, session.Health, 1)
		print(`[RockService] {player.Name} cracked {rock.Key} (too weak)`)
		Packets.RockChopped:FireClient(player, rock.Id, ChopQuality.Crack, false)
		showOthers(player, rock, ChopQuality.Crack, false)
		return
	end

	local elapsed = ChopTiming.Elapsed(session.StartTime, claimed)
	local position = ChopZones.Position(elapsed)
	local quality = ChopZones.Classify(position, session.Center, session.StrengthRatio)
	local data = services.DataService:GetData(player)
	local isTutorial = data ~= nil and Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
	local isTutorialPerfect = data ~= nil and Tutorial.ForcesPerfect(Tutorial.StepOf(data.Tutorial), data)
	if isTutorialPerfect then
		quality = ChopQuality.Perfect
	end
	local forcedQuality = forcedQualities[player]
	forcedQualities[player] = nil
	if forcedQuality then
		quality = forcedQuality
	elseif hasCheat(player, "AlwaysPerfect") then
		quality = ChopQuality.Perfect
	end
	local damage: number, payout: number
	local isForced = forcedMasters[player] == true
	if not isTutorial and (isForced or Session.IsMaster(random, quality, session.StrengthRatio)) then
		forcedMasters[player] = nil
		quality = ChopQuality.Master
		damage, payout = Session.ApplyMaster(session)
	else
		local chopStrength = services.StatsService:GetStrength(player)
		if hasCheat(player, "OneHit") then
			chopStrength = session.MaxHealth / math.max(Session.DamageMultiplier(quality), 1e-6)
		elseif hasCheat(player, "IgnoreStrength") then
			chopStrength = math.max(chopStrength, rock.Config.StrengthRequired)
		end
		damage, payout = Session.Apply(session, chopStrength, quality)
	end
	if not isTutorial then
		services.StatsService:RecordChop(player, quality)
	end
	local streakMultiplier = if isTutorial
		then 1
		else services.HotStreakService:RecordChop(player, quality, session.StrengthRatio)
	services.WeatherService:RecordHit(player, rock.Weather)
	if payout > 0 then
		local rockBonus = Rush.PayoutMultiplier(rock)
			+ services.WeatherService:GetRockMultiplier(rock.Weather)
			- 1
		payout = math.floor(payout * rockBonus + 0.5)
		payout = services.HotStreakService:ApplyCashMultiplier(payout, streakMultiplier)
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
	Packets.ChopResult:FireClient(player, quality, payout, damage, health, streakMultiplier)
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
	forcedQualities[player] = nil
	cheats[player] = nil
	spotViewers[player] = nil
	rushStates[player] = nil
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
	for _, tagged in CollectionService:GetTagged(RockSpawnConfig.AreaTag) do
		if tagged:IsA("BasePart") and tagged:IsDescendantOf(workspace) then
			table.insert(areas, tagged)
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

function RockService.ForceNextQuality(_self: any, player: Player, quality: number)
	forcedQualities[player] = quality
end

function RockService.ToggleCheat(_self: any, player: Player, name: string): boolean?
	if not cheatNames[name] then
		return nil
	end
	local playerCheats = cheats[player] or {}
	cheats[player] = playerCheats
	local isOn = playerCheats[name] ~= true
	if isOn then
		playerCheats[name] = true
	else
		playerCheats[name] = nil
	end
	return isOn
end

function RockService.SpawnNear(_self: any, player: Player, key: string): (boolean, string)
	local rocks = owned[player]
	local zone: string? = nil
	for zoneKey, zoneConfig in RockSpawnConfig.Zones do
		if zoneConfig.Weights[key] then
			zone = zoneKey
		end
	end
	if not rocks or not zone or not shapes[key] then
		return false, `no rock called {key}`
	end
	local position = rootPosition(player)
	local session = sessions[player]
	local farthest: Types.Rock? = nil
	local farthestDistance = -1
	for _, rock in zoneRocks(rocks, zone) do
		if rock.Modifier ~= nil or (session and session.Rock == rock) then
			continue
		end
		local distance = if position then (rock.CFrame.Position - position).Magnitude else 0
		if distance > farthestDistance then
			farthest = rock
			farthestDistance = distance
		end
	end
	if farthest then
		rocks[farthest.Id] = nil
		Packets.RockRemoved:FireClient(player, farthest.Id)
	end
	if not spawnRock(player, zone, false, key) then
		scheduleSpawn(player, zone, RockSpawnConfig.RespawnSeconds, false)
		return false, `no free spot for {key} in {zone}`
	end
	local configs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	return true, `{configs[key].DisplayName} spawned in {zone}`
end

function RockService.GetZoneAt(_self: any, position: Vector3): string?
	for _, area in areas do
		local relative = area.CFrame:PointToObjectSpace(position)
		local half = area.Size / 2
		if math.abs(relative.X) <= half.X and math.abs(relative.Z) <= half.Z then
			local zone = area:GetAttribute(RockSpawnConfig.ZoneAttribute)
			if type(zone) == "string" then
				return zone
			end
		end
	end
	return nil
end

function RockService.FindRingSpot(
	_self: any,
	zone: string,
	rotation: CFrame,
	size: Vector3,
	standDistance: number,
	slots: number,
	tries: number,
	isAllowed: ((position: Vector3) -> boolean)?
): Vector3?
	local zoneSpots = spots[zone]
	if not zoneSpots or #zoneSpots == 0 then
		return nil
	end
	local excluded: { Instance } = table.clone(areas) :: { any }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(excluded, player.Character)
		end
	end
	for _ = 1, math.min(tries, #zoneSpots) do
		local spot = zoneSpots[random:NextInteger(1, #zoneSpots)]
		if isAllowed and not isAllowed(spot.Position) then
			continue
		end
		if SpawnPoints.FitsRing(spot.Position, rotation, size, standDistance, slots, excluded) then
			return spot.Position
		end
	end
	return nil
end

function RockService.ReserveArea(_self: any, owner: string, zone: string, position: Vector3, radius: number)
	reserved[owner] = { Zone = zone, Position = position, Radius = radius }
	for player, rocks in owned do
		for id, rock in rocks do
			local session = sessions[player]
			if rock.Zone ~= zone or rock.Modifier ~= nil or (session and session.Rock == rock) then
				continue
			end
			local rockRadius = math.max(rock.Size.X, rock.Size.Z) / 2
			local offset = rock.CFrame.Position - position
			if Vector3.new(offset.X, 0, offset.Z).Magnitude >= radius + rockRadius then
				continue
			end
			rocks[id] = nil
			Packets.RockRemoved:FireClient(player, id)
			scheduleSpawn(player, zone, RockSpawnConfig.RespawnSeconds, false)
		end
	end
end

function RockService.ReleaseArea(_self: any, owner: string)
	reserved[owner] = nil
end

function RockService.DamageMultiplier(_self: any, quality: number): number
	return Session.DamageMultiplier(quality)
end

function RockService.ForceRush(_self: any, player: Player): boolean
	local state = rushStates[player]
	if not state or state.ActiveId or state.IsScheduled then
		return false
	end
	state.ChopSeconds = RushRockConfig.IntervalSeconds
	return true
end

function RockService.ConsumeForcedMaster(_self: any, player: Player): boolean
	local isForced = forcedMasters[player] == true
	forcedMasters[player] = nil
	return isForced
end

function RockService.RollMaster(_self: any, quality: number, strengthRatio: number): boolean
	return Session.IsMaster(random, quality, strengthRatio)
end

function RockService.EndSession(_self: any, player: Player)
	onLeave(player)
end

function RockService.HasSession(_self: any, player: Player): boolean
	return sessions[player] ~= nil
end

function RockService.StartStorm(_self: any, weather: string, perZone: number)
	for player, rocks in owned do
		local data = services.DataService:GetData(player)
		if Tutorial.IsActive(Tutorial.StepOf(if data then data.Tutorial else nil)) then
			continue
		end
		local byZone: { [string]: { Types.Rock } } = {}
		for _, rock in rocks do
			if rock.Weather ~= weather then
				local list = byZone[rock.Zone] or {}
				byZone[rock.Zone] = list
				table.insert(list, rock)
			end
		end
		for _, list in byZone do
			for _ = 1, math.min(perZone, #list) do
				local rock = table.remove(list, random:NextInteger(1, #list)) :: Types.Rock
				rock.Weather = weather
				Packets.RockWeatherSet:FireClient(player, rock.Id, weather)
			end
		end
	end
end

function RockService.Destroy(_self: any)
	trove:Clean()
	table.clear(owned)
	table.clear(generations)
	table.clear(sessions)
	table.clear(forcedMasters)
	table.clear(forcedQualities)
	table.clear(cheats)
	table.clear(spotViewers)
	table.clear(rushStates)
	table.clear(areas)
	table.clear(reserved)
end

return RockService
