--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local EnemyRules = require(ReplicatedStorage.Utils.EnemyRules)
local Packets = require(ReplicatedStorage.Packets)
local RateLimit = require(ReplicatedStorage.Utils.RateLimit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Fight = require(script.Fight)
local Homes = require(script.Homes)
local Types = require(script.Types)

local EnemyService = { Name = "EnemyService" }

local trove = Trove.new()
local services: { [string]: any } = {}
local homes: { [string]: Vector3 } = {}
local fights: { [Player]: Types.Fight } = {}
local readied: { [Player]: true } = {}
local sinceCheck = 0
local clickLimiter =
	RateLimit.new(EnemyConfig.ClickBurst, EnemyConfig.ClickBurst / EnemyConfig.ClicksPerSecond)

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

local function finish(player: Player, fight: Types.Fight, result: Types.Result)
	if fights[player] ~= fight then
		return
	end
	fights[player] = nil
	clickLimiter:Remove(player)
	print(
		`[EnemyService] {player.Name} fight in {fight.Zone}: {result}, health {fight.Health}/{fight.MaxHealth}`
	)
	if player.Parent then
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

local function onClick(player: Player)
	local fight = fights[player]
	if not fight or not clickLimiter:Allow(player) then
		return
	end
	local isDead = Fight.Hit(fight, services.StatsService:GetStrength(player))
	Packets.EnemyFightHit:FireClient(player, fight.Health)
	if isDead then
		finish(player, fight, "Won")
	elseif Fight.TakeShown(fight, os.clock()) then
		showOthers(player, "Hit")
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
			home,
			EnemyRules.ModelScale(zone)
		)
	end
end

local function checkFights(dt: number)
	sinceCheck += dt
	if sinceCheck < EnemyConfig.CheckSeconds then
		return
	end
	sinceCheck = 0
	local now = os.clock()
	for player, fight in fights do
		if Fight.HasLeft(fight, rootPosition(player)) then
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
	trove:Add(Packets.EnemyClick.OnServerEvent:Connect(onClick))
	trove:Add(RunService.Heartbeat:Connect(checkFights))
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		readied[player] = nil
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
	services.TeleportService:EndActivities(player)
	services.PetService:PutAway(player)
	local fight = Fight.New(zone, position, os.clock(), onResult)
	fights[player] = fight
	Packets.EnemyFightStarted:FireClient(player, zone, fight.MaxHealth, EnemyConfig.FightSeconds)
	return true
end

function EnemyService.HasFight(_self: any, player: Player): boolean
	return fights[player] ~= nil
end

function EnemyService.Destroy(_self: any)
	trove:Clean()
	table.clear(fights)
	table.clear(readied)
	table.clear(homes)
end

return EnemyService
