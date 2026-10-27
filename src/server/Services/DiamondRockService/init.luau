--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopTiming = require(ServerScriptService.Utils.ChopTiming)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Chopping = require(script.Chopping)
local Spawning = require(script.Spawning)
local Types = require(script.Types)

local DiamondRockService = { Name = "DiamondRockService" }

local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}

local current: Types.Diamond? = nil
local sessions: { [Player]: Types.Session } = {}
local timerGeneration = 0
local endedAt = -math.huge

local scheduleNext: (delaySeconds: number?) -> ()

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function endSession(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	if session.Diamond.Slots[session.Slot] == player then
		session.Diamond.Slots[session.Slot] = nil
	end
	player:SetAttribute(DiamondRockConfig.PlayerSlotAttribute, nil)
end

local function finish(diamond: Types.Diamond, isBroken: boolean, breaker: Player?)
	if diamond.IsEnding then
		return
	end
	diamond.IsEnding = true
	endedAt = os.clock()
	for player, session in sessions do
		if session.Diamond ~= diamond then
			continue
		end
		endSession(player)
		if player ~= breaker then
			Packets.ChopEnded:FireClient(player)
		end
	end
	for player, earned in diamond.Earned do
		if player.Parent and earned > 0 then
			services.NotificationService:Notify(
				player,
				DiamondRockConfig.EarnedKind,
				string.format(DiamondRockConfig.EarnedText, NumberFormat.CompactRock(earned))
			)
		end
	end
	if not isBroken then
		Packets.DiamondEnded:FireAllClients()
	end
	services.RockService:ReleaseArea(DiamondRockConfig.Tag)
	local cleanup = if isBroken then DiamondRockConfig.BreakCleanupSeconds else DiamondRockConfig.SinkSeconds
	task.delay(cleanup, function()
		diamond.Model:Destroy()
		if current == diamond then
			current = nil
			scheduleNext()
		end
	end)
	print(`[DiamondRockService] Diamond Rock in {diamond.Zone} {if isBroken then "broken" else "timed out"}`)
end

local expire: (diamond: Types.Diamond) -> ()

function expire(diamond: Types.Diamond)
	if current ~= diamond or diamond.IsEnding then
		return
	end
	local remaining = diamond.EndsAt - os.clock()
	if remaining > 0.05 then
		task.delay(remaining, expire, diamond)
		return
	end
	finish(diamond, false, nil)
end

local function spawnDiamond(zone: string?): (boolean, string)
	if current then
		return false, "a Diamond Rock is already out"
	end
	local pickedZone = zone or Spawning.PickZone(random, services.RockService)
	if not pickedZone then
		return false, "no players in a zone"
	end
	local stats = Spawning.ZoneStats(pickedZone)
	if not stats then
		return false, `{pickedZone} has no rocks`
	end
	local part = Spawning.Template()
	local standDistance = Spawning.StandDistance(part.Size)
	local position = services.RockService:FindRingSpot(
		pickedZone,
		part.CFrame.Rotation,
		part.Size,
		standDistance,
		DiamondRockConfig.Slots,
		DiamondRockConfig.SpotTries
	)
	if not position then
		part:Destroy()
		warn(`[DiamondRockService] No spot for a Diamond Rock in {pickedZone}`)
		return false, `no room in {pickedZone}`
	end
	local maxHealth = stats.TopStrength * ChopConfig.GoodDamageMultiplier * DiamondRockConfig.HealthChops
	local model = Spawning.Build(part, position)
	local now = os.clock()
	local diamond: Types.Diamond = {
		Model = model,
		Part = part,
		Zone = pickedZone,
		Health = maxHealth,
		MaxHealth = maxHealth,
		Value = stats.TopPayout * DiamondRockConfig.ValueMultiplier,
		StrengthRequired = stats.FirstRequirement,
		UpAt = now + DiamondRockConfig.RiseSeconds,
		EndsAt = now + DiamondRockConfig.RiseSeconds + DiamondRockConfig.CountdownSeconds,
		Slots = {},
		Earned = {},
		IsEnding = false,
	}
	current = diamond
	services.RockService:ReserveArea(
		DiamondRockConfig.Tag,
		pickedZone,
		position,
		standDistance + DiamondRockConfig.ReservePaddingStuds
	)
	Spawning.Publish(diamond)
	task.delay(diamond.EndsAt - now, expire, diamond)
	for _, player in Players:GetPlayers() do
		services.NotificationService:Notify(
			player,
			DiamondRockConfig.AnnouncementKind,
			string.format(DiamondRockConfig.AnnouncementText, pickedZone)
		)
	end
	print(`[DiamondRockService] Diamond Rock in {pickedZone}: health={maxHealth}, value={diamond.Value}`)
	return true, `Diamond Rock in the {pickedZone}`
end

function scheduleNext(delaySeconds: number?)
	timerGeneration += 1
	local generation = timerGeneration
	local seconds = delaySeconds
		or random:NextNumber(DiamondRockConfig.IntervalMinSeconds, DiamondRockConfig.IntervalMaxSeconds)
	task.delay(seconds, function()
		if generation ~= timerGeneration or current then
			return
		end
		local spawned = spawnDiamond(nil)
		if not spawned then
			scheduleNext(DiamondRockConfig.NoPlayersRetrySeconds)
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

local function onChopRequest(player: Player)
	local diamond = current
	if not diamond or diamond.IsEnding or sessions[player] then
		return
	end
	if os.clock() < diamond.UpAt - DiamondRockConfig.RiseSlackSeconds then
		return
	end
	if
		services.RockService:HasSession(player)
		or services.GeodeFallService:HasSession(player)
		or not services.DataService:GetData(player)
	then
		return
	end
	local position = rootPosition(player)
	local center = diamond.Part.Position
	local reach = ChopConfig.PromptRangeStuds
		+ math.max(diamond.Part.Size.X, diamond.Part.Size.Z) / 2
		+ DiamondRockConfig.ChopRangeSlackStuds
	if not position or (position - center).Magnitude > reach then
		return
	end
	local slot = Chopping.FreeSlot(diamond, center, position)
	if not slot then
		services.NotificationService:Notify(player, "Info", DiamondRockConfig.FullText)
		return
	end
	local strength = services.StatsService:GetStrength(player)
	local session: Types.Session = {
		Diamond = diamond,
		Slot = slot,
		CanBreak = strength >= diamond.StrengthRequired,
		StrengthRatio = strength / math.max(diamond.StrengthRequired, 1),
		Center = ChopZones.RandomCenter(random),
		StartTime = os.clock(),
		Round = 0,
	}
	sessions[player] = session
	diamond.Slots[slot] = player
	player:SetAttribute(DiamondRockConfig.PlayerSlotAttribute, slot)
	services.PetService:PutAway(player)
	Packets.ChopMinigameStart:FireClient(
		player,
		diamond.Part,
		session.CanBreak,
		session.StrengthRatio,
		session.Center,
		diamond.Health,
		diamond.MaxHealth
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
	local diamond = session.Diamond
	if diamond.IsEnding then
		return
	end

	if not session.CanBreak then
		endSession(player)
		Packets.ChopResult:FireClient(player, ChopQuality.Crack, 0, 0, diamond.Health, 1)
		Packets.DiamondChopped:FireAllClients(ChopQuality.Crack, false)
		return
	end

	local elapsed = ChopTiming.Elapsed(session.StartTime, claimed)
	local quality = ChopZones.Classify(ChopZones.Position(elapsed), session.Center, session.StrengthRatio)
	local rockService = services.RockService
	if rockService:ConsumeForcedMaster(player) or rockService:RollMaster(quality, session.StrengthRatio) then
		quality = ChopQuality.Master
	end
	services.StatsService:RecordChop(player, quality)
	local strength = services.StatsService:GetStrength(player)
	local damage = Chopping.Damage(strength, quality, rockService:DamageMultiplier(quality))
	local applied, payout = Chopping.Apply(diamond, damage)
	services.HotStreakService:KeepAlive(player)
	if payout > 0 then
		payout = services.FriendBoostService:ApplyBoost(player, payout)
		payout = services.RebirthService:ApplyCashMultiplier(player, payout)
		payout = services.IndexService:ApplyCashMultiplier(player, payout)
		payout = services.PassService:ApplyCashMultiplier(player, payout)
		services.DataService:AdjustCash(player, payout)
		diamond.Earned[player] = (diamond.Earned[player] or 0) + payout
	end
	local isBroken = Chopping.IsBroken(diamond)
	local health = if isBroken then 0 else diamond.Health
	diamond.Part:SetAttribute(DiamondRockConfig.HealthAttribute, health)
	Packets.ChopResult:FireClient(player, quality, payout, applied, health, 1)
	Packets.DiamondChopped:FireAllClients(quality, isBroken)
	print(
		`[DiamondRockService] {player.Name} hit the Diamond Rock: quality={quality}, damage={string.format(
			"%.1f",
			applied
		)}, health={string.format("%.1f", health)}, payout={payout}`
	)
	if isBroken then
		finish(diamond, true, player)
		return
	end
	scheduleNextRound(player, session, quality == ChopQuality.Master)
end

function DiamondRockService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function DiamondRockService.Start(_self: any)
	trove:Add(Packets.DiamondChop.OnServerEvent:Connect(onChopRequest))
	trove:Add(Packets.ChopRelease.OnServerEvent:Connect(onRelease))
	trove:Add(Packets.ChopLeave.OnServerEvent:Connect(endSession))
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		endSession(player)
		if current then
			current.Earned[player] = nil
		end
	end))
	scheduleNext()
end

function DiamondRockService.EndSession(_self: any, player: Player)
	endSession(player)
end

function DiamondRockService.HasSession(_self: any, player: Player): boolean
	return sessions[player] ~= nil
end

function DiamondRockService.IsActive(_self: any): boolean
	return current ~= nil
end

function DiamondRockService.SecondsSinceEnded(_self: any): number
	return os.clock() - endedAt
end

function DiamondRockService.Spawn(_self: any, player: Player?): (boolean, string)
	local position = if player then rootPosition(player) else nil
	local zone = if position then services.RockService:GetZoneAt(position) else nil
	return spawnDiamond(zone)
end

function DiamondRockService.SetTimeLeft(_self: any, seconds: number): boolean
	local diamond = current
	if not diamond or diamond.IsEnding then
		return false
	end
	diamond.EndsAt = os.clock() + seconds
	Spawning.PublishEndsAt(diamond)
	task.delay(seconds, expire, diamond)
	return true
end

function DiamondRockService.Destroy(_self: any)
	trove:Clean()
	timerGeneration += 1
	if current then
		current.Model:Destroy()
		current = nil
	end
	table.clear(sessions)
end

return DiamondRockService
