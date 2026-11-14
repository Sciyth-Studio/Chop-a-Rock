--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local EggDropConfig = require(ReplicatedStorage.Config.EggDropConfig)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local ItemIcons = require(ReplicatedStorage.Utils.ItemIcons)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Tutorial = require(ReplicatedStorage.Tutorial)
local ZoneGeodeConfig = require(ReplicatedStorage.Config.ZoneGeodeConfig)
local ZoneScale = require(ReplicatedStorage.Utils.ZoneScale)
local Roll = require(script.Roll)

type State = "Ground" | "Fighting" | "Retry"

type Geode = {
	Id: number,
	Zone: string,
	Key: string,
	Luck: number,
	Position: Vector3,
	State: State,
	Generation: number,
	RetryEndsAt: number,
	PausedLeft: number?,
	IsFree: boolean,
}

local ZoneGeodeService = { Name = "ZoneGeodeService" }

local trove = Trove.new()
local random = Random.new()
local services: { [string]: any } = {}

local owned: { [Player]: { [number]: Geode } } = {}
local nextId = 0

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root else nil
end

local function geodesOf(player: Player): { [number]: Geode }
	local geodes = owned[player]
	if not geodes then
		geodes = {}
		owned[player] = geodes
	end
	return geodes
end

local function remove(player: Player, geode: Geode, isShattered: boolean)
	local geodes = owned[player]
	if not geodes or geodes[geode.Id] ~= geode then
		return
	end
	geodes[geode.Id] = nil
	geode.Generation += 1
	if player.Parent then
		Packets.ZoneGeodeRemoved:FireClient(player, geode.Id, isShattered)
	end
end

local function notifyRolledAway(player: Player, geode: Geode)
	local config = GeodeConfig.Geodes[geode.Key]
	local name = if config then config.DisplayName else EggDropConfig.EggFallbackName
	services.NotificationService:Notify(
		player,
		"Error",
		string.format(EggDropConfig.ExpiredFormat, name),
		ItemIcons.Get("Geode", geode.Key)
	)
end

local function scheduleExpiry(player: Player, geode: Geode, seconds: number?)
	geode.Generation += 1
	local generation = geode.Generation
	task.delay(seconds or EggDropConfig.GroundSeconds, function()
		if geode.Generation ~= generation then
			return
		end
		local data = services.DataService:GetData(player)
		if data and Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
			scheduleExpiry(player, geode)
			return
		end
		if services.EnemyService:HasFight(player) then
			scheduleExpiry(player, geode, EggDropConfig.FightGraceSeconds)
			return
		end
		if geode.State == "Ground" then
			remove(player, geode, false)
			notifyRolledAway(player, geode)
		end
	end)
end

local function oldestOnGround(geodes: { [number]: Geode }): (Geode?, number)
	local oldest: Geode? = nil
	local count = 0
	for _, geode in geodes do
		if geode.State == "Ground" then
			count += 1
			if not oldest or geode.Id < oldest.Id then
				oldest = geode
			end
		end
	end
	return oldest, count
end

local function drop(
	player: Player,
	zone: string,
	key: string,
	luck: number,
	position: Vector3,
	origin: Vector3,
	isFree: boolean?
)
	local geodes = geodesOf(player)
	local oldest, count = oldestOnGround(geodes)
	if oldest and count >= EggDropConfig.MaxOnGround then
		remove(player, oldest, false)
		notifyRolledAway(player, oldest)
	end
	local zoneConfig = ZoneGeodeConfig.Zones[zone]
	local look = if zoneConfig then table.find(zoneConfig.Looks, key) or 1 else 1
	nextId += 1
	local geode: Geode = {
		Id = nextId,
		Zone = zone,
		Key = key,
		Luck = luck,
		Position = position,
		State = "Ground",
		Generation = 0,
		RetryEndsAt = 0,
		PausedLeft = nil,
		IsFree = isFree == true,
	}
	geodes[nextId] = geode
	scheduleExpiry(player, geode)
	Packets.ZoneGeodeSpawned:FireClient(
		player,
		geode.Id,
		zone,
		look,
		position,
		random:NextNumber(0, math.pi * 2),
		origin,
		luck,
		not isFree
	)
end

local function landingSpot(player: Player, ground: Vector3, size: number): Vector3
	local root = rootOf(player)
	local away = if root
		then Vector3.new(root.Position.X - ground.X, 0, root.Position.Z - ground.Z)
		else Vector3.zero
	local direction = if away.Magnitude > 1e-3 then away.Unit else Vector3.xAxis
	local distance = size / 2 + EggDropConfig.LandDistanceStuds
	return ground + direction * distance
end

local function onRockBroken(player: Player, broken: any)
	local data = services.DataService:GetData(player)
	local zoneConfig = ZoneGeodeConfig.Zones[broken.Zone]
	if not data or not zoneConfig or #zoneConfig.Looks == 0 then
		return
	end
	local isTutorial = Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
	local isRare = not isTutorial and #zoneConfig.Looks > 1 and Roll.IsRare(random, broken.Skill)
	local key = zoneConfig.Looks[if isRare then 2 else 1]
	if not GeodeConfig.Geodes[key] then
		return
	end
	local luck = if isTutorial
		then EggDropConfig.TutorialLuckHundredths
		else Roll.Luck(random, broken.Skill, broken.HadMaster, broken.IsGolden)
	local delaySeconds = if broken.Quality == ChopQuality.Master
		then MasterChopConfig.ImpactDelaySeconds + MasterChopConfig.StrikeHoldSeconds
		else ChopConfig.SlowMoPreImpactSeconds
	task.delay(delaySeconds, function()
		if player.Parent then
			drop(
				player,
				broken.Zone,
				key,
				luck,
				landingSpot(player, broken.Ground, broken.Size),
				broken.Origin
			)
		end
	end)
end

local function grant(player: Player, geode: Geode)
	if not services.GeodeService:HasBagRoom(player) then
		geode.State = "Ground"
		scheduleExpiry(player, geode)
		services.NotificationService:Notify(player, "Error", EggDropConfig.BagFullText, IconConfig.Backpack)
		return
	end
	if not services.GeodeService:GrantGeodes(player, geode.Key, 1, geode.Luck) then
		geode.State = "Ground"
		scheduleExpiry(player, geode)
		return
	end
	remove(player, geode, false)
	services.GeodeService:Equip(player, geode.Key)
end

local function hasFreeRetry(data: any): boolean
	return os.time() - (data.FreeRetryAt or 0) >= EggDropConfig.FreeRetryCooldownSeconds
end

local startFight: (player: Player, geode: Geode) -> boolean

local function shatter(player: Player, geode: Geode)
	if geode.State ~= "Retry" then
		return
	end
	Packets.EggRetryClosed:FireClient(player, geode.Id)
	remove(player, geode, true)
	services.NotificationService:Notify(player, "Error", EggDropConfig.LostText)
end

local function scheduleRetryTimeout(player: Player, geode: Geode, seconds: number)
	geode.Generation += 1
	local generation = geode.Generation
	geode.RetryEndsAt = os.clock() + seconds
	task.delay(seconds, function()
		if geode.Generation == generation and geode.State == "Retry" and not geode.PausedLeft then
			shatter(player, geode)
		end
	end)
end

local function offerRetry(player: Player, geode: Geode)
	local data = services.DataService:GetData(player)
	if not data then
		remove(player, geode, true)
		return
	end
	geode.State = "Retry"
	geode.PausedLeft = nil
	scheduleRetryTimeout(player, geode, EggDropConfig.RetrySeconds)
	Packets.EggRetryOffer:FireClient(
		player,
		geode.Id,
		data.RetryCredits or 0,
		hasFreeRetry(data),
		EggDropConfig.RetrySeconds
	)
end

local function retry(player: Player, geode: Geode)
	Packets.EggRetryClosed:FireClient(player, geode.Id)
	geode.Generation += 1
	geode.PausedLeft = nil
	if not startFight(player, geode) then
		geode.State = "Ground"
		scheduleExpiry(player, geode)
	end
end

local function pendingRetry(player: Player): Geode?
	local geodes = owned[player]
	if not geodes then
		return nil
	end
	for _, geode in geodes do
		if geode.State == "Retry" then
			return geode
		end
	end
	return nil
end

local function isInZone(player: Player, geode: Geode): boolean
	local root = rootOf(player)
	if root and services.RockService:GetZoneAt(root.Position) == geode.Zone then
		return true
	end
	services.NotificationService:Notify(player, "Error", EggDropConfig.GoBackText)
	return false
end

local function reoffer(player: Player, geode: Geode)
	local data = services.DataService:GetData(player)
	local left = geode.PausedLeft or math.max(geode.RetryEndsAt - os.clock(), 1)
	if geode.PausedLeft then
		geode.PausedLeft = nil
		scheduleRetryTimeout(player, geode, left)
	end
	Packets.EggRetryOffer:FireClient(
		player,
		geode.Id,
		if data then data.RetryCredits or 0 else 0,
		data ~= nil and hasFreeRetry(data),
		left
	)
end

local function useCredit(player: Player): boolean
	local data = services.DataService:GetData(player)
	local geode = pendingRetry(player)
	if not data or not geode or (data.RetryCredits or 0) < 1 then
		return false
	end
	if not isInZone(player, geode) then
		reoffer(player, geode)
		return false
	end
	services.DataService:Set(player, { "RetryCredits" }, data.RetryCredits - 1)
	retry(player, geode)
	return true
end

startFight = function(player: Player, geode: Geode): boolean
	local enemies = services.EnemyService
	if not enemies then
		grant(player, geode)
		return true
	end
	geode.State = "Fighting"
	geode.Generation += 1
	local isStarted = enemies:RequestFight(player, geode.Zone, function(result: string)
		if owned[player] == nil or owned[player][geode.Id] ~= geode then
			return
		end
		if result == "Won" or result == "Fled" then
			grant(player, geode)
		elseif result == "Lost" then
			offerRetry(player, geode)
		else
			geode.State = "Ground"
			scheduleExpiry(player, geode)
		end
	end)
	if not isStarted then
		geode.State = "Ground"
		scheduleExpiry(player, geode)
	end
	return isStarted
end

local function isBusy(player: Player): boolean
	return services.RockService:HasSession(player)
		or services.DiamondRockService:HasSession(player)
		or services.BossService:HasSession(player)
end

local function onTake(player: Player, id: number)
	local geodes = owned[player]
	local geode = if geodes then geodes[id] else nil
	local data = services.DataService:GetData(player)
	if not geode or geode.State ~= "Ground" or not data or isBusy(player) then
		return
	end
	if not Tutorial.CanTakeGeode(Tutorial.StepOf(data.Tutorial)) then
		return
	end
	local root = rootOf(player)
	local reach = EggDropConfig.PromptRangeStuds
		+ EggDropConfig.PromptRangeSlackStuds
		+ ZoneGeodeConfig.ClearanceSize.X / 2 * ZoneScale.Of(geode.Zone)
	if not root or (root.Position - geode.Position).Magnitude > reach then
		return
	end
	if services.StatsService:GetStrength(player) < GeodeConfig.Geodes[geode.Zone].StrengthRequired then
		services.NotificationService:Notify(player, "Error", EggDropConfig.TooWeakText)
		return
	end
	if not services.GeodeService:HasBagRoom(player) then
		services.NotificationService:Notify(player, "Error", EggDropConfig.BagFullText, IconConfig.Backpack)
		return
	end
	if geode.IsFree or services.EnemyService:IsKnockedOut(player, geode.Zone) then
		grant(player, geode)
	else
		startFight(player, geode)
	end
end

local function onDropHeld(player: Player, isBehind: boolean?)
	local data = services.DataService:GetData(player)
	if not data or Tutorial.IsActive(Tutorial.StepOf(data.Tutorial)) then
		return
	end
	local key = services.GeodeService:GetHeldKey(player)
	local geode = if key then GeodeConfig.Geodes[key] else nil
	local root = rootOf(player)
	if not key or not geode or not root or isBusy(player) then
		return
	end
	local look = root.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z)
	local column = root.Position
		+ (if forward.Magnitude > 1e-3 then forward.Unit else Vector3.zAxis)
			* (if isBehind then -EggDropConfig.DropBehindStuds else EggDropConfig.DropAheadStuds)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { root.Parent :: any }
	params.RespectCanCollide = true
	local ground =
		workspace:Raycast(column, Vector3.new(0, -ZoneGeodeConfig.AdminGroundDepthStuds, 0), params)
	if not ground then
		return
	end
	local luck = services.GeodeService:TakeOne(player, key)
	if not luck then
		return
	end
	drop(player, geode.TabName, key, luck, ground.Position, ground.Position, true)
end

local function onChoose(player: Player, id: number, choice: string)
	local geodes = owned[player]
	local geode = if geodes then geodes[id] else nil
	local data = services.DataService:GetData(player)
	if not geode or geode.State ~= "Retry" or not data then
		return
	end
	if (choice == "Free" or choice == "Credit") and not isInZone(player, geode) then
		return
	elseif choice == "Free" and hasFreeRetry(data) then
		services.DataService:Set(player, { "FreeRetryAt" }, os.time())
		retry(player, geode)
	elseif choice == "Credit" then
		useCredit(player)
	elseif choice == "Buying" and not geode.PausedLeft then
		geode.PausedLeft = math.max(geode.RetryEndsAt - os.clock(), 1)
		geode.Generation += 1
	elseif choice == "Decline" then
		shatter(player, geode)
	end
end

local function onPurchaseFinished(userId: number, productId: number, isPurchased: boolean)
	local player = Players:GetPlayerByUserId(userId)
	if not player or productId ~= MonetizationConfig.RetryFight.ProductId or isPurchased then
		return
	end
	local geode = pendingRetry(player)
	local left = if geode then geode.PausedLeft else nil
	if geode and left then
		geode.PausedLeft = nil
		scheduleRetryTimeout(player, geode, left)
		local data = services.DataService:GetData(player)
		Packets.EggRetryOffer:FireClient(
			player,
			geode.Id,
			if data then data.RetryCredits or 0 else 0,
			data ~= nil and hasFreeRetry(data),
			left
		)
	end
end

function ZoneGeodeService.GrantRetry(_self: any, player: Player): boolean
	local data = services.DataService:GetData(player)
	if not data then
		return false
	end
	services.DataService:Set(player, { "RetryCredits" }, (data.RetryCredits or 0) + 1)
	task.defer(useCredit, player)
	return true
end

function ZoneGeodeService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function ZoneGeodeService.Start(_self: any)
	trove:Add(services.RockService.RockBroken:Connect(onRockBroken))
	trove:Add(Packets.ZoneGeodeTake.OnServerEvent:Connect(onTake))
	trove:Add(Packets.EggDropHeld.OnServerEvent:Connect(onDropHeld))
	trove:Add(Packets.EggRetryChoose.OnServerEvent:Connect(onChoose))
	trove:Connect(MarketplaceService.PromptProductPurchaseFinished, onPurchaseFinished)
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		owned[player] = nil
	end))
end

function ZoneGeodeService.DropHeld(_self: any, player: Player)
	onDropHeld(player, true)
end

function ZoneGeodeService.SpawnNear(_self: any, player: Player): (boolean, string)
	local root = rootOf(player)
	if not root then
		return false, "not ready yet"
	end
	local zone = services.RockService:GetZoneAt(root.Position)
	local zoneConfig = if zone then ZoneGeodeConfig.Zones[zone] else nil
	if not zone or not zoneConfig or not GeodeConfig.Geodes[zone] then
		return false, "stand in a zone with eggs"
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
	local isRare = Roll.IsRare(random, 0)
	local key = zoneConfig.Looks[if isRare and #zoneConfig.Looks > 1 then 2 else 1]
	drop(
		player,
		zone,
		key,
		Roll.Luck(random, 0, false, false),
		ground.Position,
		ground.Position + Vector3.yAxis * 6
	)
	return true, `{GeodeConfig.Geodes[key].DisplayName} dropped`
end

function ZoneGeodeService.Destroy(_self: any)
	trove:Clean()
	table.clear(owned)
end

return ZoneGeodeService
