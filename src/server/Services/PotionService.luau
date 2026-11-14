--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Packets = require(ReplicatedStorage.Packets)
local PotionConfig = require(ReplicatedStorage.Config.PotionConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PotionService = { Name = "PotionService" }

local TICK_SECONDS = 1
local NOTICE_KIND = "Info"

local services: { [string]: any } = {}
local trove = Trove.new()
local hatchCarry: { [Player]: number } = {}
local random = Random.new()
local lastTick = 0

local function isActive(player: Player, potionKey: string): boolean
	return services.BoostService:GetPersonalSeconds(player, PotionConfig.BoostKey(potionKey)) > 0
end

local function isCounting(player: Player, potionKey: string): boolean
	return services.BoostService:IsCounting(player, PotionConfig.BoostKey(potionKey))
end

local function isChopping(player: Player): boolean
	return services.RockService:HasSession(player)
		or services.DiamondRockService:HasSession(player)
		or services.BossService:HasSession(player)
		or services.EnemyService:HasFight(player)
end

function PotionService.IsPaused(_self: any, player: Player, potionKey: string): boolean
	local potion = PotionConfig.Potions[potionKey]
	if not potion then
		return true
	end
	local rule = potion.CountsWhile
	if rule == "Training" then
		return not services.TrainingService:IsTraining(player)
	elseif rule == "InZone" then
		return services.ZonePresenceService:GetZone(player) == nil
	elseif rule == "Hatching" then
		return not services.GeodeService:IsHatching(player)
	elseif rule == "Chopping" then
		return not isChopping(player)
	end
	return false
end

function PotionService.GetCount(_self: any, player: Player, potionKey: string): number
	local data = services.DataService:GetData(player)
	return if data then data.Potions[potionKey] or 0 else 0
end

function PotionService.Grant(_self: any, player: Player, potionKey: string, amount: number): boolean
	local potion = PotionConfig.Potions[potionKey]
	local data = services.DataService:GetData(player)
	if not potion or not data or amount <= 0 then
		return false
	end
	local count = math.min((data.Potions[potionKey] or 0) + amount, PotionConfig.MaxCount)
	services.DataService:Set(player, { "Potions", potionKey }, count)
	services.NotificationService:Notify(
		player,
		NOTICE_KIND,
		string.format(PotionConfig.GotFormat, amount, potion.DisplayName),
		potion.Icon
	)
	return true
end

function PotionService.GrantRandom(_self: any, player: Player, amount: number): string?
	local list = PotionConfig.Sorted()
	local potion = list[random:NextInteger(1, #list)]
	if PotionService:Grant(player, potion.Key, amount) then
		return potion.Key
	end
	return nil
end

function PotionService.Clear(_self: any, player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	for key in data.Potions do
		services.DataService:Set(player, { "Potions", key }, nil)
	end
end

function PotionService.Drink(_self: any, player: Player, potionKey: string): boolean
	local potion = PotionConfig.Potions[potionKey]
	local data = services.DataService:GetData(player)
	local count = if data then data.Potions[potionKey] or 0 else 0
	if not potion or count < 1 then
		return false
	end
	if
		not services.BoostService:AddPersonal(player, PotionConfig.BoostKey(potionKey), PotionConfig.Seconds)
	then
		services.NotificationService:Notify(player, NOTICE_KIND, PotionConfig.FullText)
		return false
	end
	services.DataService:Set(player, { "Potions", potionKey }, if count > 1 then count - 1 else nil)
	services.NotificationService:Notify(
		player,
		NOTICE_KIND,
		string.format(PotionConfig.DrankFormat, potion.DisplayName, potion.Effect),
		potion.Icon
	)
	return true
end

function PotionService.StrengthBonus(_self: any, player: Player): number
	return if isActive(player, "Strength") then PotionConfig.StrengthBonus else 0
end

function PotionService.LuckMultiplier(_self: any, player: Player): number
	return if isActive(player, "Luck") then PotionConfig.LuckMultiplier else 1
end

function PotionService.FocusScale(_self: any, player: Player): number
	return if isActive(player, "Focus") then PotionConfig.FocusScale else 1
end

local function tick()
	local clock = os.clock()
	local elapsed = clock - lastTick
	if elapsed < TICK_SECONDS then
		return
	end
	lastTick = clock
	for _, player in Players:GetPlayers() do
		services.WalkSpeedService:SetBonus(
			player,
			PotionConfig.SpeedSource,
			if isActive(player, "Speed") then PotionConfig.SpeedBonus else 0
		)
		if isCounting(player, "Hatch") then
			local carry = (hatchCarry[player] or 0) + elapsed * (PotionConfig.HatchSpeed - 1)
			local whole = math.floor(carry)
			hatchCarry[player] = carry - whole
			if whole > 0 then
				services.GeodeService:AdvanceHatching(player, whole)
			end
		end
	end
end

function PotionService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function PotionService.Start(_self: any)
	Packets.DrinkPotion.OnServerInvoke = function(player: Player, potionKey: string): boolean
		return PotionService:Drink(player, potionKey)
	end
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		hatchCarry[player] = nil
	end)
	lastTick = os.clock()
	trove:Connect(RunService.Heartbeat, tick)
end

function PotionService.Destroy(_self: any)
	Packets.DrinkPotion.OnServerInvoke = nil
	trove:Destroy()
end

return PotionService
