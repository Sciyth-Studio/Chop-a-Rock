--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local GeodeFallConfig = require(ReplicatedStorage.Config.GeodeFallConfig)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Movement = require(script.Movement)
local Spawning = require(script.Spawning)
local Types = require(script.Types)

local GeodeFallService = { Name = "GeodeFallService" }

local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}

local current: Types.Fall? = nil
local tracks: { [Player]: Types.Track } = {}
local nextId = 0
local lastSweepAt = 0

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function inTutorial(player: Player): boolean
	local data = services.DataService:GetData(player)
	return data == nil or Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
end

local function notify(player: Player, kind: string, text: string, icon: string?)
	services.NotificationService:Notify(player, kind, text, icon)
end

local function notifyAll(text: string)
	for _, player in Players:GetPlayers() do
		if not inTutorial(player) then
			notify(player, GeodeFallConfig.AnnouncementKind, text)
		end
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
	for _, geode in table.clone(fall.Geodes) do
		geode.IsDone = true
		removeGeode(fall, geode, GeodeFallConfig.SinkSeconds)
	end
	if current == fall then
		current = nil
	end
	print(`[GeodeFallService] Geode Fall in {fall.Label} ended, {fall.Left} of {fall.Total} left`)
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

local function spawnGeode(fall: Types.Fall, zone: string, landsAt: number): boolean
	local model, part = Spawning.Template(zone)
	if not model or not part then
		return false
	end
	local taken: { Vector3 } = {}
	for _, other in fall.Geodes do
		table.insert(taken, other.Part.Position)
	end
	local standDistance = Spawning.StandDistance(part.Size)
	local position = services.RockService:FindRingSpot(
		zone,
		CFrame.identity,
		part.Size,
		standDistance,
		GeodeFallConfig.StandSlots,
		GeodeFallConfig.SpotTries,
		Spawning.SpotFilter(Spawning.KeepOutPoints(), taken)
	)
	if not position then
		model:Destroy()
		warn(`[GeodeFallService] No spot for a Falling Geode in {zone}`)
		return false
	end
	nextId = nextId % 65535 + 1
	Spawning.Place(model, part, position, random)
	local geode: Types.Geode = {
		Id = nextId,
		Model = model,
		Part = part,
		Zone = zone,
		StrengthRequired = GeodeConfig.Geodes[zone].StrengthRequired,
		ReserveOwner = `{GeodeFallConfig.Tag}{nextId}`,
		LandsAt = landsAt,
		IsDone = false,
	}
	fall.Geodes[geode.Id] = geode
	services.RockService:ReserveArea(
		geode.ReserveOwner,
		zone,
		position,
		standDistance + GeodeFallConfig.ReservePaddingStuds
	)
	Spawning.Publish(geode, fall.EndsAt)
	return true
end

local function finishOne(fall: Types.Fall)
	fall.Left -= 1
	if fall.Left <= 0 then
		endFall(fall)
	end
end

local function startFall(zone: string?, lifetimeSeconds: number?): (boolean, string)
	if current then
		return false, "a Geode Fall is already on"
	end
	if zone and not GeodeConfig.Geodes[zone] then
		return false, `{zone} has no geode`
	end
	local peaks: { number } = {}
	for _, player in Players:GetPlayers() do
		local data = services.DataService:GetData(player)
		if data and not Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
			table.insert(peaks, data.PeakStrength)
		end
	end
	local zones = if zone then { zone } else Spawning.EligibleZones(peaks)
	if #zones == 0 then
		return false, "no players have reached a zone"
	end
	local picks: { string } = {}
	for _ = 1, Spawning.Count(#Players:GetPlayers()) do
		table.insert(picks, zones[random:NextInteger(1, #zones)])
	end
	local now = os.clock()
	local landsAt = now + GeodeFallConfig.WarningSeconds
	local fall: Types.Fall = {
		Label = Spawning.Label(picks),
		Zones = picks,
		Total = #picks,
		Left = #picks,
		LandsAt = landsAt,
		EndsAt = landsAt + (lifetimeSeconds or GeodeFallConfig.LifetimeSeconds),
		Geodes = {},
		IsEnding = false,
	}
	current = fall
	for _, pick in picks do
		notifyAll(string.format(GeodeFallConfig.WarningText, pick))
	end
	for _, track in tracks do
		track.Position = nil
	end
	task.delay(GeodeFallConfig.WarningSeconds - GeodeFallConfig.MarkerLeadSeconds, function()
		if current ~= fall or fall.IsEnding then
			return
		end
		local spawned = 0
		for _, pick in fall.Zones do
			if spawnGeode(fall, pick, fall.LandsAt) then
				spawned += 1
			end
		end
		fall.Total = spawned
		fall.Left = spawned
		if spawned == 0 then
			endFall(fall)
			return
		end
	end)
	task.delay(GeodeFallConfig.WarningSeconds, function()
		if current == fall and not fall.IsEnding then
			for _, geode in fall.Geodes do
				notifyAll(string.format(GeodeFallConfig.LandedText, geode.Zone))
			end
		end
	end)
	task.delay(fall.EndsAt - now, expire, fall)
	print(`[GeodeFallService] Geode Fall in {fall.Label}: {#picks} geodes`)
	return true, `Geode Fall in {fall.Label}`
end

local function onTake(player: Player, id: number)
	local fall = current
	local geode = if fall and not fall.IsEnding then fall.Geodes[id] else nil
	if not fall or not geode or geode.IsDone then
		return
	end
	if os.clock() < geode.LandsAt - GeodeFallConfig.RiseSlackSeconds then
		return
	end
	if
		services.RockService:HasSession(player)
		or services.DiamondRockService:HasSession(player)
		or services.EnemyService:HasFight(player)
		or inTutorial(player)
	then
		return
	end
	if Movement.IsFlagged(tracks[player]) then
		warn(`[GeodeFallService] Ignored a pickup from {player.Name}: moved too far in one step`)
		return
	end
	local position = rootPosition(player)
	local size = geode.Part.Size
	local reach = ChopConfig.PromptRangeStuds
		+ math.max(size.X, size.Z) / 2
		+ GeodeFallConfig.PromptRangeSlackStuds
	if not position or (position - geode.Part.Position).Magnitude > reach then
		return
	end
	if services.StatsService:GetStrength(player) < geode.StrengthRequired then
		notify(
			player,
			"Error",
			string.format(GeodeFallConfig.TooWeakText, NumberFormat.Commas(geode.StrengthRequired))
		)
		return
	end
	if not services.GeodeService:HasBagRoom(player) then
		notify(player, "Error", GeodeFallConfig.BackpackFullText, IconConfig.Backpack)
		return
	end
	local geodeKey = GeodeOrder.FallingKey(geode.Zone)
	if not geodeKey or not services.GeodeService:GrantGeodes(player, geodeKey, 1) then
		return
	end
	geode.IsDone = true
	removeGeode(fall, geode, GeodeFallConfig.SinkSeconds)
	Packets.GeodeFallTaken:FireAllClients(id)
	notify(player, "Purchase", `+1 {GeodeConfig.Geodes[geodeKey].DisplayName}`)
	print(`[GeodeFallService] {player.Name} took a {geodeKey}`)
	finishOne(fall)
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
			warn(`[GeodeFallService] {player.Name} moved too far in one step; pickups blocked`)
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
	for _, player in Players:GetPlayers() do
		track(player)
	end
	trove:Connect(Players.PlayerAdded, track)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		tracks[player] = nil
	end)
	trove:Add(services.CannonService.Landed:Connect(function(player: Player)
		GeodeFallService:AllowMove(player)
	end))
	trove:Add(Packets.GeodeFallTake.OnServerEvent:Connect(onTake))
	trove:Connect(RunService.Heartbeat, sweep)
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
	for _, geode in fall.Geodes do
		geode.Part:SetAttribute(GeodeFallConfig.EndsAtAttribute, Spawning.ServerTime(fall.EndsAt))
	end
	task.delay(seconds, expire, fall)
	return true
end

function GeodeFallService.Destroy(_self: any)
	trove:Clean()
	local fall = current
	if fall then
		for _, geode in fall.Geodes do
			geode.Model:Destroy()
		end
		current = nil
	end
	table.clear(tracks)
end

return GeodeFallService
