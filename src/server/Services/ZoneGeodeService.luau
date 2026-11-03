--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local ZoneGeodeConfig = require(ReplicatedStorage.Config.ZoneGeodeConfig)
local ZoneRings = require(ReplicatedStorage.Utils.ZoneRings)
local ZoneScale = require(ReplicatedStorage.Utils.ZoneScale)

type Geode = {
	Id: number,
	Zone: string,
	Position: Vector3,
	IsFighting: boolean,
}

local ZoneGeodeService = { Name = "ZoneGeodeService" }

local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}

local owned: { [Player]: { [number]: Geode } } = {}
local generations: { [Player]: number } = {}
local waiting: { [Player]: true } = {}
local warned: { [string]: boolean } = {}
local nextId = 0

local function warnOnce(key: string, message: string)
	if warned[key] then
		return
	end
	warned[key] = true
	warn(message)
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root else nil
end

local function zoneGeodes(geodes: { [number]: Geode }, zone: string): { Geode }
	local list: { Geode } = {}
	for _, geode in geodes do
		if geode.Zone == zone then
			table.insert(list, geode)
		end
	end
	return list
end

local function hasBagRoom(player: Player, data: any): boolean
	local held = services.PetService:Count(player)
	for _, count in data.Geodes do
		held += count
	end
	for _ in data.HatchPads or {} do
		held += 1
	end
	return held < services.PassService:GetBackpackSize(player)
end

local function pickSpot(player: Player, zone: string, geodes: { Geode }): Vector3?
	local rings = services.RockService:GetRings()
	local scale = ZoneScale.Of(zone)
	local root = rootOf(player)
	local valid: { Vector3 } = {}
	for _, position in services.RockService:GetRingSpots(zone) do
		local ring = ZoneRings.Containing(rings, zone, position)
		if
			not ring
			or flatDistance(position, ring.Center) < ring.Radius * ZoneGeodeConfig.CentreClearRatio
		then
			continue
		end
		if root and flatDistance(position, root.Position) < ZoneGeodeConfig.PlayerClearanceStuds then
			continue
		end
		local isFree = true
		for _, geode in geodes do
			if flatDistance(position, geode.Position) < ZoneGeodeConfig.GeodeGapStuds * scale then
				isFree = false
				break
			end
		end
		if isFree then
			table.insert(valid, position)
		end
	end
	return if #valid > 0 then valid[random:NextInteger(1, #valid)] else nil
end

local function place(player: Player, zone: string, position: Vector3)
	local geodes = owned[player]
	local zoneConfig = ZoneGeodeConfig.Zones[zone]
	if not geodes or not zoneConfig then
		return
	end
	nextId += 1
	geodes[nextId] = { Id = nextId, Zone = zone, Position = position, IsFighting = false }
	Packets.ZoneGeodeSpawned:FireClient(
		player,
		nextId,
		zone,
		random:NextInteger(1, #zoneConfig.Looks),
		position,
		random:NextNumber(0, math.pi * 2)
	)
end

local function spawnGeode(player: Player, zone: string): boolean
	local geodes = owned[player]
	if not geodes then
		return true
	end
	local existing = zoneGeodes(geodes, zone)
	if #existing >= ZoneGeodeConfig.GeodesPerZone then
		return true
	end
	local position = pickSpot(player, zone, existing)
	if not position then
		warnOnce(zone, `[ZoneGeodeService] No free ring spot in {zone}`)
		return false
	end
	place(player, zone, position)
	return true
end

local function scheduleSpawn(player: Player, zone: string, delaySeconds: number)
	local generation = generations[player]
	task.delay(delaySeconds, function()
		if generations[player] == generation and not spawnGeode(player, zone) then
			scheduleSpawn(player, zone, ZoneGeodeConfig.RetrySeconds)
		end
	end)
end

local function grant(player: Player, geode: Geode)
	local geodes = owned[player]
	local data = services.DataService:GetData(player)
	if not geodes or geodes[geode.Id] ~= geode or not data then
		return
	end
	if not hasBagRoom(player, data) then
		services.NotificationService:Notify(player, "Error", ZoneGeodeConfig.BagFullText, IconConfig.Backpack)
		return
	end
	if not services.GeodeService:GrantGeodes(player, geode.Zone, 1) then
		return
	end
	geodes[geode.Id] = nil
	Packets.ZoneGeodeRemoved:FireClient(player, geode.Id)
	services.NotificationService:Notify(player, "Purchase", `+1 {GeodeConfig.Geodes[geode.Zone].DisplayName}`)
	scheduleSpawn(player, geode.Zone, ZoneGeodeConfig.RespawnSeconds)
end

local function isBusy(player: Player): boolean
	return services.RockService:HasSession(player)
		or services.DiamondRockService:HasSession(player)
		or services.GeodeFallService:HasSession(player)
end

local function onTake(player: Player, id: number)
	local geodes = owned[player]
	local geode = if geodes then geodes[id] else nil
	local data = services.DataService:GetData(player)
	if not geode or geode.IsFighting or not data or isBusy(player) then
		return
	end
	if Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
		return
	end
	local root = rootOf(player)
	local reach = ZoneGeodeConfig.PromptRangeStuds
		+ ZoneGeodeConfig.PromptRangeSlackStuds
		+ ZoneGeodeConfig.ClearanceSize.X / 2 * ZoneScale.Of(geode.Zone)
	if not root or (root.Position - geode.Position).Magnitude > reach then
		return
	end
	if services.StatsService:GetStrength(player) < GeodeConfig.Geodes[geode.Zone].StrengthRequired then
		services.NotificationService:Notify(player, "Error", ZoneGeodeConfig.TooWeakText)
		return
	end
	if not hasBagRoom(player, data) then
		services.NotificationService:Notify(player, "Error", ZoneGeodeConfig.BagFullText, IconConfig.Backpack)
		return
	end
	local enemies = services.EnemyService
	if not enemies then
		if ZoneGeodeConfig.GrantWithoutEnemyService then
			grant(player, geode)
		else
			warnOnce("EnemyService", "[ZoneGeodeService] EnemyService is missing; geodes can't be taken")
		end
		return
	end
	geode.IsFighting = true
	local isStarted = enemies:RequestFight(player, geode.Zone, function(result: string)
		geode.IsFighting = false
		if result == "Won" or result == "Fled" then
			grant(player, geode)
		end
	end)
	if not isStarted then
		geode.IsFighting = false
	end
end

local function fill(player: Player)
	if owned[player] then
		return
	end
	owned[player] = {}
	generations[player] = (generations[player] or 0) + 1
	for zone in ZoneGeodeConfig.Zones do
		if not GeodeConfig.Geodes[zone] then
			warnOnce(`{zone}/geode`, `[ZoneGeodeService] {zone} has no entry in GeodeConfig`)
			continue
		end
		for _ = 1, ZoneGeodeConfig.GeodesPerZone do
			if not spawnGeode(player, zone) then
				scheduleSpawn(player, zone, ZoneGeodeConfig.RetrySeconds)
			end
		end
	end
end

local function onReady(player: Player)
	if services.RockService:IsSampled() then
		fill(player)
	else
		waiting[player] = true
	end
end

local function onPlayerRemoving(player: Player)
	owned[player] = nil
	generations[player] = nil
	waiting[player] = nil
end

function ZoneGeodeService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function ZoneGeodeService.Start(_self: any)
	trove:Add(services.RockService.Sampled:Connect(function()
		for player in waiting do
			waiting[player] = nil
			if player.Parent then
				fill(player)
			end
		end
	end))
	trove:Add(Packets.ZoneGeodeReady.OnServerEvent:Connect(onReady))
	trove:Add(Packets.ZoneGeodeTake.OnServerEvent:Connect(onTake))
	trove:Add(Players.PlayerRemoving:Connect(onPlayerRemoving))
end

function ZoneGeodeService.SpawnNear(_self: any, player: Player): (boolean, string)
	local root = rootOf(player)
	if not root or not owned[player] then
		return false, "not ready yet"
	end
	local zone = services.RockService:GetZoneAt(root.Position)
	if not zone or not ZoneGeodeConfig.Zones[zone] or not GeodeConfig.Geodes[zone] then
		return false, "stand in a zone with geodes"
	end
	local look = root.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z)
	local column = root.Position
		+ (if forward.Magnitude > 1e-3 then forward.Unit else Vector3.zAxis)
			* ZoneGeodeConfig.AdminSpawnStuds
			* ZoneScale.Of(zone)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { root.Parent :: any }
	params.RespectCanCollide = true
	local ground =
		workspace:Raycast(column, Vector3.new(0, -ZoneGeodeConfig.AdminGroundDepthStuds, 0), params)
	if not ground then
		return false, "no ground in front of you"
	end
	place(player, zone, ground.Position)
	return true, `{GeodeConfig.Geodes[zone].DisplayName} spawned`
end

function ZoneGeodeService.Destroy(_self: any)
	trove:Clean()
	table.clear(owned)
	table.clear(generations)
	table.clear(waiting)
end

return ZoneGeodeService
