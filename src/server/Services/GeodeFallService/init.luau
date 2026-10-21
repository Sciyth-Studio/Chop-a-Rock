--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopTiming = require(ServerScriptService.Utils.ChopTiming)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local GeodeFallConfig = require(ReplicatedStorage.Config.GeodeFallConfig)
local HatchOdds = require(ReplicatedStorage.HatchOdds)
local HatchTiming = require(ReplicatedStorage.HatchTiming)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Chopping = require(script.Chopping)
local Movement = require(script.Movement)
local Spawning = require(script.Spawning)
local Types = require(script.Types)

local GeodeFallService = { Name = "GeodeFallService" }

local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}

local current: Types.Fall? = nil
local sessions: { [Player]: Types.Session } = {}
local tracks: { [Player]: Types.Track } = {}
local timerGeneration = 0
local nextId = 0
local lastSweepAt = 0

local scheduleNext: (delaySeconds: number?) -> ()

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function inTutorial(player: Player): boolean
	local data = services.DataService:GetData(player)
	return data == nil or Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
end

local function notify(player: Player, kind: string, text: string)
	services.NotificationService:Notify(player, kind, text)
end

local function notifyAll(text: string)
	for _, player in Players:GetPlayers() do
		if not inTutorial(player) then
			notify(player, GeodeFallConfig.AnnouncementKind, text)
		end
	end
end

local function isClaimHeld(geode: Types.Geode): boolean
	local claimer = geode.ClaimedBy
	if not claimer or not claimer.Parent then
		return false
	end
	local session = sessions[claimer]
	if session and session.Geode == geode then
		return true
	end
	return geode.ClaimExpiresAt ~= nil and os.clock() < geode.ClaimExpiresAt
end

local function setClaim(geode: Types.Geode, player: Player?)
	geode.ClaimedBy = player
	geode.ClaimExpiresAt = nil
	Spawning.PublishClaim(geode)
end

local function setAuraHidden(player: Player, isHidden: boolean)
	player:SetAttribute(GeodeConfig.CrackingAttribute, if isHidden then true else nil)
end

local function endSession(player: Player, keepClaim: boolean)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	setAuraHidden(player, false)
	local geode = session.Geode
	if geode.ClaimedBy ~= player or geode.IsDone then
		return
	end
	if keepClaim then
		geode.ClaimExpiresAt = os.clock() + GeodeFallConfig.ClaimTimeoutSeconds
	else
		setClaim(geode, nil)
	end
end

local function kick(player: Player)
	if sessions[player] then
		endSession(player, false)
		Packets.ChopEnded:FireClient(player)
	end
end

local function removeGeode(fall: Types.Fall, geode: Types.Geode, delaySeconds: number)
	if fall.Geodes[geode.Id] == geode then
		fall.Geodes[geode.Id] = nil
	end
	services.RockService:ReleaseArea(geode.ReserveOwner)
	local model = geode.Model
	task.delay(delaySeconds, function()
		model:Destroy()
	end)
end

local function endFall(fall: Types.Fall)
	if fall.IsEnding then
		return
	end
	fall.IsEnding = true
	for player, session in sessions do
		if fall.Geodes[session.Geode.Id] == session.Geode then
			kick(player)
		end
	end
	for _, geode in table.clone(fall.Geodes) do
		geode.IsDone = true
		removeGeode(fall, geode, GeodeFallConfig.SinkSeconds)
	end
	if current == fall then
		current = nil
		Spawning.PublishFall(nil)
		scheduleNext()
	end
	print(`[GeodeFallService] Geode Fall in {fall.Zone} ended, {fall.Left} of {fall.Total} left`)
end

local expire: (fall: Types.Fall) -> ()

function expire(fall: Types.Fall)
	if current ~= fall or fall.IsEnding then
		return
	end
	local remaining = fall.EndsAt - os.clock()
	if remaining > 0.05 then
		task.delay(remaining, expire, fall)
		return
	end
	endFall(fall)
end

local function spawnGeode(fall: Types.Fall, landsAt: number): boolean
	local model, part = Spawning.Template(fall.GeodeKey)
	if not model or not part then
		return false
	end
	local taken: { Vector3 } = {}
	for _, other in fall.Geodes do
		table.insert(taken, other.Part.Position)
	end
	local standDistance = Spawning.StandDistance(part.Size)
	local position = services.RockService:FindRingSpot(
		fall.Zone,
		CFrame.identity,
		part.Size,
		standDistance,
		GeodeFallConfig.StandSlots,
		GeodeFallConfig.SpotTries,
		Spawning.SpotFilter(Spawning.KeepOutPoints(), taken)
	)
	if not position then
		model:Destroy()
		warn(`[GeodeFallService] No spot for a Falling Geode in {fall.Zone}`)
		return false
	end
	nextId = nextId % 65535 + 1
	local spot = Spawning.Place(model, part, position, random)
	local strength = GeodeConfig.Geodes[fall.GeodeKey].StrengthRequired
	local maxHealth = Chopping.MaxHealth(strength)
	local geode: Types.Geode = {
		Id = nextId,
		Model = model,
		Part = part,
		Spot = spot,
		Zone = fall.Zone,
		GeodeKey = fall.GeodeKey,
		Health = maxHealth,
		MaxHealth = maxHealth,
		StrengthRequired = strength,
		ReserveOwner = `{GeodeFallConfig.Tag}{nextId}`,
		LandsAt = landsAt,
		ClaimedBy = nil,
		ClaimExpiresAt = nil,
		IsDone = false,
	}
	fall.Geodes[geode.Id] = geode
	services.RockService:ReserveArea(
		geode.ReserveOwner,
		fall.Zone,
		position,
		standDistance + GeodeFallConfig.ReservePaddingStuds
	)
	Spawning.Publish(geode, fall.EndsAt)
	return true
end

local function finishOne(fall: Types.Fall)
	fall.Left -= 1
	Spawning.PublishFall(if current == fall then fall else nil)
	if fall.Left <= 0 then
		endFall(fall)
	end
end

local function crack(geode: Types.Geode, player: Player, quality: number)
	local fall = current
	geode.IsDone = true
	if not fall or fall.Geodes[geode.Id] ~= geode then
		return
	end
	local revealDelay = if quality == ChopQuality.Master
		then MasterChopConfig.ImpactDelaySeconds
		else ChopConfig.SlowMoPreImpactSeconds
	local petService = services.PetService
	local petKey = HatchOdds.RollAtLeast(random, geode.GeodeKey, GeodeFallConfig.MinRarity)
	local grant = if petKey and petService:CanAdd(player, 1)
		then petService:Grant(player, petKey, services.WeatherService:RollHatchModifier(player))
		else nil
	task.delay(revealDelay, Spawning.Hide, geode.Model)
	if not grant then
		setAuraHidden(player, false)
		notify(player, "Error", GeodeFallConfig.BackpackLostText)
		removeGeode(fall, geode, revealDelay + GeodeFallConfig.SinkSeconds)
		local isRespawned = fall.EndsAt - os.clock() > GeodeFallConfig.MarkerLeadSeconds
			and spawnGeode(fall, os.clock() + GeodeFallConfig.MarkerLeadSeconds)
		print(
			`[GeodeFallService] {player.Name} cracked a Falling Geode with a full Backpack, respawned={isRespawned}`
		)
		if not isRespawned then
			finishOne(fall)
		end
		return
	end
	removeGeode(fall, geode, GeodeFallConfig.RevealCleanupSeconds)
	local center = geode.Model:GetPivot().Position
	local position = rootPosition(player)
	local facing = if position then Vector3.new(position.X, center.Y, position.Z) else nil
	geode.Spot.WorldCFrame = if facing and (facing - center).Magnitude > 0.1
		then CFrame.lookAt(center, facing)
		else CFrame.new(center)
	local pet = PetConfig.Pets[grant.PetKey]
	local rarity = RarityConfig.Rarities[pet.Rarity]
	local strikeHold = if quality == ChopQuality.Master then MasterChopConfig.StrikeHoldSeconds else 0
	task.delay(revealDelay + math.max(strikeHold, HatchTiming.RevealSeconds(pet.Rarity)), function()
		if player.Parent and not sessions[player] then
			setAuraHidden(player, false)
		end
	end)
	task.delay(revealDelay, function()
		Packets.GeodeHatched:FireAllClients(
			player,
			geode.Spot,
			geode.GeodeKey,
			grant.PetKey,
			table.find(RarityConfig.Order, pet.Rarity) or 1,
			grant.IsNew,
			grant.Trait or "",
			grant.Modifier or ""
		)
	end)
	if GeodeFallConfig.AnnouncedRarities[pet.Rarity] then
		task.delay(revealDelay + HatchTiming.RevealSeconds(pet.Rarity), function()
			for _, other in Players:GetPlayers() do
				notify(
					other,
					GeodeConfig.AnnouncementKind,
					string.format(
						GeodeFallConfig.WinText,
						player.DisplayName,
						rarity.DisplayName,
						pet.DisplayName
					)
				)
			end
		end)
	end
	print(`[GeodeFallService] {player.Name} cracked a Falling Geode: pet={grant.PetKey}, new={grant.IsNew}`)
	finishOne(fall)
end

local function startFall(zone: string?, lifetimeSeconds: number?): (boolean, string)
	if current then
		return false, "a Geode Fall is already on"
	end
	local pickedZone = zone
		or Spawning.PickZone(random, services.RockService, function(player: Player): boolean
			return not inTutorial(player)
		end)
	if not pickedZone then
		return false, "no players in a zone"
	end
	if not GeodeConfig.Geodes[pickedZone] then
		return false, `{pickedZone} has no geode`
	end
	local eligible = 0
	for _, player in Players:GetPlayers() do
		if not inTutorial(player) then
			eligible += 1
		end
	end
	local now = os.clock()
	local landsAt = now + GeodeFallConfig.WarningSeconds
	local count = Spawning.Count(eligible)
	local fall: Types.Fall = {
		Zone = pickedZone,
		GeodeKey = pickedZone,
		Total = count,
		Left = count,
		LandsAt = landsAt,
		EndsAt = landsAt + (lifetimeSeconds or GeodeFallConfig.LifetimeSeconds),
		Geodes = {},
		IsEnding = false,
	}
	current = fall
	Spawning.PublishFall(fall)
	notifyAll(string.format(GeodeFallConfig.WarningText, pickedZone))
	for _, track in tracks do
		track.Position = nil
	end
	task.delay(GeodeFallConfig.WarningSeconds - GeodeFallConfig.MarkerLeadSeconds, function()
		if current ~= fall or fall.IsEnding then
			return
		end
		local spawned = 0
		for _ = 1, fall.Total do
			if spawnGeode(fall, fall.LandsAt) then
				spawned += 1
			end
		end
		fall.Total = spawned
		fall.Left = spawned
		if spawned == 0 then
			endFall(fall)
			return
		end
		Spawning.PublishFall(fall)
	end)
	task.delay(GeodeFallConfig.WarningSeconds, function()
		if current == fall and not fall.IsEnding then
			notifyAll(string.format(GeodeFallConfig.LandedText, fall.Left, fall.Zone))
		end
	end)
	task.delay(fall.EndsAt - now, expire, fall)
	print(`[GeodeFallService] Geode Fall in {pickedZone}: {count} geodes`)
	return true, `Geode Fall in the {pickedZone}`
end

local function isBlocked(): boolean
	local weather = services.WeatherService
	local needed = GeodeFallConfig.WarningSeconds
		+ GeodeFallConfig.LifetimeSeconds
		+ GeodeFallConfig.WeatherGapSeconds
	if weather:GetActive() or weather:SecondsUntilNext() < needed then
		return true
	end
	local diamond = services.DiamondRockService
	return diamond:IsActive() or diamond:SecondsSinceEnded() < GeodeFallConfig.DiamondGapSeconds
end

function scheduleNext(delaySeconds: number?)
	timerGeneration += 1
	local generation = timerGeneration
	local seconds = delaySeconds
		or random:NextNumber(GeodeFallConfig.IntervalMinSeconds, GeodeFallConfig.IntervalMaxSeconds)
	task.delay(seconds, function()
		if generation ~= timerGeneration or current then
			return
		end
		if isBlocked() or not startFall(nil, nil) then
			scheduleNext(GeodeFallConfig.RetrySeconds)
		end
	end)
end

local function scheduleNextRound(player: Player, session: Types.Session, isMaster: boolean)
	session.StartTime = nil
	session.Round += 1
	local round = session.Round
	local pause = if isMaster
		then MasterChopConfig.ImpactDelaySeconds
			+ MasterChopConfig.StrikeHoldSeconds
			+ ChopConfig.RoundPauseSeconds
		else ChopConfig.RoundPauseSeconds
	task.delay(pause, function()
		if sessions[player] ~= session or session.Round ~= round then
			return
		end
		session.Center = ChopZones.RandomCenter(random)
		session.StartTime = os.clock()
		Packets.ChopRoundStart:FireClient(player, session.Center)
	end)
end

local function onChopRequest(player: Player, id: number)
	local fall = current
	local geode = if fall and not fall.IsEnding then fall.Geodes[id] else nil
	if not geode or geode.IsDone or sessions[player] then
		return
	end
	if os.clock() < geode.LandsAt - GeodeFallConfig.RiseSlackSeconds then
		return
	end
	if
		services.RockService:HasSession(player)
		or services.DiamondRockService:HasSession(player)
		or inTutorial(player)
	then
		return
	end
	if Movement.IsFlagged(tracks[player]) then
		warn(`[GeodeFallService] Ignored a claim from {player.Name}: moved too far in one step`)
		return
	end
	local position = rootPosition(player)
	local size = geode.Part.Size
	local reach = ChopConfig.PromptRangeStuds
		+ math.max(size.X, size.Z) / 2
		+ GeodeFallConfig.ChopRangeSlackStuds
	if not position or (position - geode.Part.Position).Magnitude > reach then
		return
	end
	local strength = services.StatsService:GetStrength(player)
	if strength < geode.StrengthRequired then
		notify(
			player,
			"Error",
			string.format(GeodeFallConfig.TooWeakText, NumberFormat.Commas(geode.StrengthRequired))
		)
		return
	end
	local claimer = geode.ClaimedBy
	if claimer and claimer ~= player and isClaimHeld(geode) then
		notify(player, "Info", string.format(GeodeFallConfig.ClaimedText, claimer.DisplayName))
		return
	end
	setClaim(geode, player)
	if not services.PetService:CanAdd(player, 1) then
		notify(player, "Error", GeodeFallConfig.BackpackFullText)
	end
	local session: Types.Session = {
		Geode = geode,
		StrengthRatio = strength / math.max(geode.StrengthRequired, 1),
		Center = ChopZones.RandomCenter(random),
		StartTime = os.clock(),
		Round = 0,
	}
	sessions[player] = session
	setAuraHidden(player, true)
	services.PetService:PutAway(player)
	Packets.ChopMinigameStart:FireClient(
		player,
		geode.Part,
		true,
		session.StrengthRatio,
		session.Center,
		geode.Health,
		geode.MaxHealth
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
	local geode = session.Geode
	if geode.IsDone then
		return
	end
	local elapsed = ChopTiming.Elapsed(session.StartTime, claimed)
	local quality = ChopZones.Classify(ChopZones.Position(elapsed), session.Center, session.StrengthRatio)
	local rockService = services.RockService
	if rockService:ConsumeForcedMaster(player) or rockService:RollMaster(quality, session.StrengthRatio) then
		quality = ChopQuality.Master
	end
	local strength = services.StatsService:GetStrength(player)
	local applied = Chopping.Apply(
		geode,
		Chopping.Damage(strength, quality, rockService:DamageMultiplier(quality)),
		quality
	)
	services.HotStreakService:KeepAlive(player)
	local isBroken = Chopping.IsBroken(geode)
	local health = if isBroken then 0 else geode.Health
	geode.Part:SetAttribute(GeodeFallConfig.HealthAttribute, health)
	Packets.ChopResult:FireClient(player, quality, 0, applied, health, 1)
	Packets.GeodeFallChopped:FireAllClients(geode.Id, quality, isBroken)
	if isBroken then
		sessions[player] = nil
		crack(geode, player, quality)
		return
	end
	scheduleNextRound(player, session, quality == ChopQuality.Master)
end

local function sweep()
	local fall = current
	local now = os.clock()
	if not fall or now - lastSweepAt < GeodeFallConfig.MoveSampleSeconds then
		return
	end
	lastSweepAt = now
	for player, track in tracks do
		if Movement.Sample(track, player, services.CannonService:IsLaunching(player)) then
			warn(`[GeodeFallService] {player.Name} moved too far in one step; claims blocked`)
			kick(player)
		end
	end
	local idleSeconds = GeodeFallConfig.ClaimTimeoutSeconds + ChopConfig.RoundInputDelaySeconds
	for player, session in sessions do
		if session.StartTime and now - session.StartTime > idleSeconds then
			kick(player)
		end
	end
	for _, geode in fall.Geodes do
		if geode.ClaimedBy and not geode.IsDone and not isClaimHeld(geode) then
			setClaim(geode, nil)
		end
	end
end

local function track(player: Player)
	local playerTrack = Movement.New()
	tracks[player] = playerTrack
	trove:Connect(player.CharacterAdded, function()
		Movement.Allow(playerTrack)
	end)
end

function GeodeFallService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function GeodeFallService.Start(_self: any)
	Spawning.PublishFall(nil)
	for _, player in Players:GetPlayers() do
		track(player)
	end
	trove:Connect(Players.PlayerAdded, track)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		endSession(player, false)
		tracks[player] = nil
	end)
	trove:Add(services.CannonService.Landed:Connect(function(player: Player)
		GeodeFallService:AllowMove(player)
	end))
	trove:Add(Packets.GeodeFallChop.OnServerEvent:Connect(onChopRequest))
	trove:Add(Packets.ChopRelease.OnServerEvent:Connect(onRelease))
	trove:Add(Packets.ChopLeave.OnServerEvent:Connect(function(player: Player)
		endSession(player, true)
	end))
	trove:Connect(RunService.Heartbeat, sweep)
	scheduleNext()
end

function GeodeFallService.HasSession(_self: any, player: Player): boolean
	return sessions[player] ~= nil
end

function GeodeFallService.EndSession(_self: any, player: Player)
	endSession(player, true)
end

function GeodeFallService.AllowMove(_self: any, player: Player)
	local playerTrack = tracks[player]
	if playerTrack then
		Movement.Allow(playerTrack)
	end
end

function GeodeFallService.IsActive(_self: any): boolean
	return current ~= nil
end

function GeodeFallService.Spawn(_self: any, player: Player?): (boolean, string)
	local position = if player then rootPosition(player) else nil
	local zone = if position then services.RockService:GetZoneAt(position) else nil
	return startFall(if zone and GeodeConfig.Geodes[zone] then zone else nil, nil)
end

function GeodeFallService.SetTimeLeft(_self: any, seconds: number): boolean
	local fall = current
	if not fall or fall.IsEnding or os.clock() < fall.LandsAt then
		return false
	end
	fall.EndsAt = os.clock() + seconds
	Spawning.PublishFall(fall)
	for _, geode in fall.Geodes do
		geode.Part:SetAttribute(GeodeFallConfig.EndsAtAttribute, Spawning.ServerTime(fall.EndsAt))
	end
	task.delay(seconds, expire, fall)
	return true
end

function GeodeFallService.Destroy(_self: any)
	trove:Clean()
	timerGeneration += 1
	local fall = current
	if fall then
		for _, geode in fall.Geodes do
			geode.Model:Destroy()
		end
		current = nil
	end
	table.clear(sessions)
	table.clear(tracks)
end

return GeodeFallService
