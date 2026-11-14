--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopTiming = require(ServerScriptService.Utils.ChopTiming)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local EnemyRules = require(ReplicatedStorage.Utils.EnemyRules)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Fight = require(script.Fight)
local Homes = require(script.Homes)
local Types = require(script.Types)

local EnemyService = { Name = "EnemyService" }

local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}
local homes: { [string]: Homes.Home } = {}
local fights: { [Player]: Types.Fight } = {}
local readied: { [Player]: true } = {}
local knockouts: { [Player]: { [string]: number } } = {}
local sinceCheck = 0

local function publishKnockout(player: Player, zone: string)
	local zones = knockouts[player]
	local untilClock = if zones then zones[zone] else nil
	local paused = services.BossService:HasSession(player)
	local wakesAt = if untilClock then workspace:GetServerTimeNow() + (untilClock - os.clock()) else nil
	player:SetAttribute(EnemyConfig.KnockedOutAttributePrefix .. zone, wakesAt)
	local pill = EnemyConfig.FreeEggsPillKey
	player:SetAttribute(MonetizationConfig.BoostEndsAttributePrefix .. pill, wakesAt)
	player:SetAttribute(
		MonetizationConfig.BoostPausedAttributePrefix .. pill,
		if wakesAt and paused then math.ceil(untilClock :: number - os.clock()) else nil
	)
end

local function knockOut(player: Player, fight: Types.Fight)
	local seconds = math.min(
		EnemyConfig.KnockoutSeconds + fight.Perfects * EnemyConfig.KnockoutPerPerfectSeconds,
		EnemyConfig.KnockoutMaxSeconds
	)
	local zones: { [string]: number } = knockouts[player] or {}
	knockouts[player] = zones
	for zone in zones do
		if zone ~= fight.Zone then
			zones[zone] = nil
			player:SetAttribute(EnemyConfig.KnockedOutAttributePrefix .. zone, nil)
		end
	end
	zones[fight.Zone] = os.clock() + seconds
	player:SetAttribute(EnemyConfig.KnockoutTotalAttribute, seconds)
	publishKnockout(player, fight.Zone)
end

local function tickKnockouts(elapsed: number)
	local now = os.clock()
	for player, zones in knockouts do
		for zone, untilClock in zones do
			if services.BossService:HasSession(player) then
				zones[zone] = untilClock + elapsed
				publishKnockout(player, zone)
			elseif now >= untilClock then
				zones[zone] = nil
				publishKnockout(player, zone)
				services.NotificationService:Notify(
					player,
					"Error",
					string.format(EnemyConfig.WokeUpText, string.format(EnemyConfig.GuardianText, zone))
				)
			elseif
				player:GetAttribute(
					MonetizationConfig.BoostPausedAttributePrefix .. EnemyConfig.FreeEggsPillKey
				)
			then
				publishKnockout(player, zone)
			end
		end
	end
end

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil
	end
	return root.Position
end

local function showOthers(player: Player, kind: string)
	local position = rootPosition(player)
	if not position then
		return
	end
	for _, other in Players:GetPlayers() do
		if other == player then
			continue
		end
		local otherPosition = rootPosition(other)
		if otherPosition and (otherPosition - position).Magnitude <= EnemyConfig.OthersEffectMaxDistance then
			Packets.EnemyFightShown:FireClient(other, position, kind)
		end
	end
end

local function finish(player: Player, fight: Types.Fight, result: Types.Result, delaySeconds: number?)
	if fights[player] ~= fight or fight.IsOver then
		return
	end
	fight.IsOver = true
	fight.RoundStart = nil
	print(
		`[EnemyService] {player.Name} fight in {fight.Zone}: {result}, hits left {fight.Health}/{fight.MaxHealth}`
	)
	local function close()
		if fights[player] ~= fight then
			return
		end
		fights[player] = nil
		if player.Parent then
			if result ~= "Won" then
				Packets.ChopEnded:FireClient(player)
			end
			if result == "Won" and not fight.IsGentle then
				knockOut(player, fight)
			end
			Packets.EnemyFightEnded:FireClient(player, fight.Zone, result)
			if result == "Won" or result == "Lost" then
				showOthers(player, result)
			end
			if result == "Lost" then
				services.GeodeFallService:AllowMove(player)
			end
		end
		task.defer(fight.OnResult, result)
	end
	if delaySeconds and delaySeconds > 0 then
		task.delay(delaySeconds, close)
	else
		close()
	end
end

local function startRound(player: Player, fight: Types.Fight)
	fight.Center = ChopZones.RandomCenter(random)
	fight.RoundStart = os.clock()
end

local function beginRounds(player: Player, fight: Types.Fight)
	if fights[player] ~= fight or fight.IsOver then
		return
	end
	startRound(player, fight)
	Packets.EnemyChopStart:FireClient(
		player,
		fight.Zone,
		fight.StrengthRatio,
		fight.Center,
		fight.Health,
		fight.MaxHealth,
		if fight.Deadline == math.huge then 0 else fight.Deadline - os.clock()
	)
end

local function scheduleNextRound(player: Player, fight: Types.Fight)
	fight.Round += 1
	local round = fight.Round
	task.delay(ChopConfig.RoundPauseSeconds, function()
		if fights[player] ~= fight or fight.IsOver or fight.Round ~= round then
			return
		end
		startRound(player, fight)
		Packets.ChopRoundStart:FireClient(player, fight.Center)
	end)
end

local function onRelease(player: Player, claimed: number)
	local fight = fights[player]
	local started = if fight then fight.RoundStart else nil
	if not fight or not started or fight.IsOver then
		return
	end
	if os.clock() - started < ChopConfig.RoundInputDelaySeconds then
		return
	end
	fight.RoundStart = nil
	local isTouch = ChopZones.IsTouch(player)
	local position =
		ChopZones.Position(ChopTiming.Elapsed(started, claimed), isTouch, EnemyRules.SweepSpeed(fight.Round))
	local quality = Fight.Quality(
		fight,
		ChopZones.Classify(
			position,
			fight.Center,
			fight.StrengthRatio,
			isTouch,
			services.PotionService:FocusScale(player)
		)
	)
	if quality >= ChopQuality.Perfect then
		fight.Perfects += 1
	end
	local damage, isDead = Fight.Hit(fight, quality)
	Packets.ChopResult:FireClient(player, quality, 0, damage, fight.Health, 1)
	if damage > 0 and Fight.TakeShown(fight, os.clock()) then
		showOthers(player, "Hit")
	end
	if isDead then
		finish(player, fight, "Won", EnemyConfig.WinResultDelaySeconds)
	else
		scheduleNextRound(player, fight)
	end
end

local function onLeave(player: Player)
	local fight = fights[player]
	if fight and Fight.HasStarted(fight, os.clock()) then
		finish(player, fight, "Lost")
	end
end

local function onReady(player: Player)
	if readied[player] then
		return
	end
	readied[player] = true
	for zone, home in homes do
		Packets.EnemySpawned:FireClient(
			player,
			zone,
			EnemyRules.PetKey(zone),
			home.Position,
			EnemyRules.ModelScale(zone),
			home.AreaMin,
			home.AreaMax
		)
	end
end

local function checkFights(dt: number)
	sinceCheck += dt
	if sinceCheck < EnemyConfig.CheckSeconds then
		return
	end
	tickKnockouts(sinceCheck)
	sinceCheck = 0
	local now = os.clock()
	for player, fight in fights do
		if fight.IsOver then
			continue
		end
		if not Fight.HasStarted(fight, now) and Fight.HasLeft(fight, rootPosition(player)) then
			finish(player, fight, "Left")
		elseif Fight.IsOutOfTime(fight, now) then
			finish(player, fight, "Lost")
		end
	end
end

function EnemyService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function EnemyService.Start(_self: any)
	homes = Homes.Find()
	trove:Add(Packets.EnemyReady.OnServerEvent:Connect(onReady))
	trove:Add(Packets.ChopRelease.OnServerEvent:Connect(onRelease))
	trove:Add(Packets.ChopLeave.OnServerEvent:Connect(onLeave))
	trove:Add(RunService.Heartbeat:Connect(checkFights))
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		readied[player] = nil
		knockouts[player] = nil
		local fight = fights[player]
		if fight then
			finish(player, fight, "Left")
		end
	end))
end

function EnemyService.RequestFight(
	_self: any,
	player: Player,
	zone: string,
	onResult: (result: Types.Result) -> ()
): boolean
	if fights[player] or not EnemyRules.IsZone(zone) or services.CannonService:IsLaunching(player) then
		return false
	end
	local position = rootPosition(player)
	local strength = services.StatsService:GetStrength(player)
	if not position or not EnemyRules.CanFight(strength, zone) then
		return false
	end
	if EnemyRules.Flees(strength, zone) then
		Packets.EnemyFled:FireClient(player, zone)
		task.defer(function()
			onResult("Fled")
		end)
		return true
	end
	local data = services.DataService:GetData(player)
	local isGentle = data ~= nil and Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
	services.TeleportService:EndActivities(player)
	services.PetService:PutAway(player)
	local fight =
		Fight.New(zone, position, os.clock(), strength, ChopZones.IsTouch(player), isGentle, onResult)
	fights[player] = fight
	Packets.EnemyFightStarted:FireClient(
		player,
		zone,
		fight.MaxHealth,
		fight.Health,
		EnemyRules.IntroSeconds()
	)
	task.delay(EnemyRules.IntroSeconds(), beginRounds, player, fight)
	return true
end

function EnemyService.HasFight(_self: any, player: Player): boolean
	return fights[player] ~= nil
end

function EnemyService.IsKnockedOut(_self: any, player: Player, zone: string): boolean
	local zones = knockouts[player]
	return zones ~= nil and zones[zone] ~= nil
end

function EnemyService.Destroy(_self: any)
	trove:Clean()
	table.clear(fights)
	table.clear(readied)
	table.clear(homes)
end

return EnemyService
