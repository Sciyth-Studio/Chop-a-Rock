--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local AuraConfig = require(ReplicatedStorage.Config.AuraConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local DiamondRockConfig = require(ReplicatedStorage.Config.DiamondRockConfig)
local GeodeFallConfig = require(ReplicatedStorage.Config.GeodeFallConfig)
local HotStreakConfig = require(ReplicatedStorage.Config.HotStreakConfig)
local IndexConfig = require(ReplicatedStorage.Config.IndexConfig)
local MonetizationConfig = require(ReplicatedStorage.Config.MonetizationConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RebirthConfig = require(ReplicatedStorage.Config.RebirthConfig)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local WalkSpeedConfig = require(ReplicatedStorage.Config.WalkSpeedConfig)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)
local HatchOdds = require(ReplicatedStorage.HatchOdds)
local HatchPity = require(ReplicatedStorage.HatchPity)
local PedestalSlots = require(ReplicatedStorage.PedestalSlots)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Arguments = require(script.Parent.Arguments)
local Presets = require(script.Parent.Presets)
local Snapshots = require(script.Parent.Snapshots)
local Targets = require(script.Parent.Targets)
local Types = require(script.Parent.Types)
local Warps = require(script.Parent.Warps)

local random = Random.new()
local qualityNames = { "Perfect", "Great", "Good", "Mid", "Bad" }

local function sortedKeys(map: { [string]: any }): { string }
	local keys: { string } = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

local function notify(context: Types.Context, player: Player, message: string)
	context.Services.NotificationService:Notify(player, "Info", `Admin: {message}`)
end

local function zoneGeode(context: Types.Context, player: Player): string?
	local data = context.Services.DataService:GetData(player)
	local strength = if data and type(data.Strength) == "number" then data.Strength else 0
	return GeodeOrder.ForStrength(strength)
end

local function number(
	context: Types.Context,
	player: Player,
	argument: string,
	min: number,
	max: number
): number?
	local value = Arguments.Number(argument, min, max)
	if not value then
		notify(
			context,
			player,
			`enter a number from {NumberFormat.Compact(min)} to {NumberFormat.Compact(max)}`
		)
	end
	return value
end

local function targetRok(context: Types.Context, player: Player): string?
	local petService = context.Services.PetService
	return petService:GetHeldPetId(player) or petService:NewestPetId(player)
end

local function count(
	context: Types.Context,
	player: Player,
	text: string?,
	default: number,
	max: number
): number?
	if not text then
		return default
	end
	return number(context, player, text, 1, max)
end

local function rollZoneRoks(context: Types.Context, player: Player, amount: number): { string }
	local geodeKey = zoneGeode(context, player)
	local keys: { string } = {}
	if not geodeKey then
		return keys
	end
	for _ = 1, amount do
		local petKey = HatchOdds.Roll(random, geodeKey, 1)
		if petKey then
			table.insert(keys, petKey)
		end
	end
	return keys
end

local function indexZones(argument: string): { { Page: string, Zone: string } }?
	local zones: { { Page: string, Zone: string } } = {}
	local wantsAll = string.lower(argument) == string.lower(AdminConfig.IndexAllValue)
	for _, page in IndexConfig.Pages do
		for _, zone in page.Zones do
			local id = page.Key .. AdminConfig.IndexSeparator .. zone.Key
			if wantsAll or string.lower(id) == string.lower(argument) then
				table.insert(zones, { Page = page.Key, Zone = zone.Key })
			end
		end
	end
	return if #zones > 0 then zones else nil
end

local function setIndex(context: Types.Context, player: Player, argument: string, isFound: boolean)
	local zones = indexZones(argument)
	if not zones then
		notify(context, player, `no Index zone called {argument}`)
		return
	end
	for _, zone in zones do
		context.Services.IndexService:SetZoneFound(player, zone.Page, zone.Zone, isFound)
	end
	notify(context, player, `Index {argument} {if isFound then "complete" else "reset"}`)
end

local function cheat(name: string, label: string): Types.Handler
	return function(context: Types.Context, player: Player, _argument: string)
		local isOn = context.Services.RockService:ToggleCheat(player, name)
		if isOn ~= nil then
			notify(context, player, `{label} {if isOn then "on" else "off"}`)
		end
	end
end

local function snapshot(action: (Types.Context, Player, string) -> string): Types.Handler
	return function(context: Types.Context, player: Player, argument: string)
		notify(context, player, action(context, player, (string.gsub(argument, "^%s*(.-)%s*$", "%1"))))
	end
end

local tutorialServices: { [string]: string } = {
	Main = "TutorialService",
	Aura = "AuraHintService",
	Rock = "RockHintService",
	Rebirth = "RebirthHintService",
	Cannon = "CannonHintService",
}

local Commands: { [string]: Types.Handler } = {
	ApplyPreset = function(context: Types.Context, player: Player, argument: string)
		local preset = Presets.Find(argument)
		if preset and Presets.Apply(context, player, preset) then
			notify(context, player, `preset {preset.Label}`)
		end
	end,
	Warp = function(context: Types.Context, player: Player, argument: string)
		if not Warps.Teleport(context, player, argument) then
			notify(context, player, `no warp called {argument}`)
		end
	end,
	SetWalkSpeed = function(context: Types.Context, player: Player, argument: string)
		local speed = number(context, player, argument, 0, AdminConfig.Limits.WalkSpeed)
		if speed then
			local bonus = speed - WalkSpeedConfig.BaseWalkSpeed
			context.Services.WalkSpeedService:SetBonus(player, AdminConfig.WalkSpeedSource, bonus)
			notify(context, player, `walk speed {speed}`)
		end
	end,
	SetCash = function(context: Types.Context, player: Player, argument: string)
		local cash = number(context, player, argument, 0, AdminConfig.Limits.Cash)
		if cash and context.Services.DataService:Set(player, { "Cash" }, cash) then
			context.Services.DataService:RequestSave(player)
			notify(context, player, `cash {NumberFormat.Compact(cash)}`)
		end
	end,
	GrantCash = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.DataService:AdjustCash(player, AdminConfig.CashAmount) then
			notify(context, player, `+{AdminConfig.CashAmount} cash`)
		end
	end,
	SetStrength = function(context: Types.Context, player: Player, argument: string)
		local strength = number(context, player, argument, 0, AdminConfig.Limits.Strength)
		if strength and context.Services.StatsService:SetStrength(player, strength) then
			notify(context, player, `strength {NumberFormat.Compact(strength)}`)
		end
	end,
	SetRebirths = function(context: Types.Context, player: Player, argument: string)
		local rebirths = number(context, player, argument, 0, RebirthConfig.MaxAdminRebirths)
		if rebirths and context.Services.DataService:Set(player, { "Rebirths" }, rebirths) then
			context.Services.DataService:RequestSave(player)
			notify(context, player, `rebirths {rebirths}`)
		end
	end,
	SetAuraTier = function(context: Types.Context, player: Player, argument: string)
		local tier = number(context, player, argument, 1, #AuraConfig.Tiers)
		if tier and context.Services.AuraService:SetTier(player, tier) then
			notify(context, player, AuraConfig.Tiers[tier].DisplayName)
		end
	end,
	GrantCannons = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.CannonService:SetOwned(player, true) then
			notify(context, player, "all cannons")
		end
	end,
	ResetCannons = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.CannonService:SetOwned(player, false) then
			notify(context, player, "no cannons")
		end
	end,
	ToggleFakePass = function(context: Types.Context, player: Player, argument: string)
		local passService = context.Services.PassService
		local pass = passService:GetPass(argument)
		if not pass then
			notify(context, player, "choose a pass")
			return
		end
		local isOwned = not passService:Owns(player, pass.Key)
		if passService:SetFake(player, pass.Key, isOwned) then
			local state = if passService:Owns(player, pass.Key) then "on" else "off"
			notify(context, player, `{pass.DisplayName} {state} (fake)`)
		else
			notify(context, player, "fake passes are Studio only")
		end
	end,
	GiveBoost = function(context: Types.Context, player: Player, argument: string)
		for _, boost in MonetizationConfig.Boosts do
			local seconds = boost.Products[1].Seconds
			if
				boost.Key == argument
				and context.Services.BoostService:AddPersonal(player, boost.Key, seconds)
			then
				local total = context.Services.BoostService:GetPersonalSeconds(player, boost.Key)
				notify(context, player, `{boost.DisplayName}, {math.ceil(total / 60)} min left`)
				return
			end
		end
		notify(context, player, "choose a boost")
	end,
	GiveServerBoost = function(context: Types.Context, player: Player, argument: string)
		for _, boost in MonetizationConfig.ServerBoosts do
			if
				boost.Key == argument
				and context.Services.BoostService:AddServer(boost.Key, boost.Seconds, player)
			then
				notify(context, player, `{boost.DisplayName} +{math.floor(boost.Seconds / 60)} min`)
				return
			end
		end
		notify(context, player, "choose a server boost")
	end,
	GrantStarterPack = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.OfferService:GrantStarterPack(player) then
			notify(context, player, "starter pack granted")
		end
	end,
	ResetStarterPack = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.OfferService:ResetStarterPack(player) then
			context.Services.OfferService:OpenStarterWindow(player)
			notify(context, player, "starter pack reset, offer open for 24 h")
		end
	end,
	GrantExclusive = function(context: Types.Context, player: Player, argument: string)
		if context.Services.ExclusiveService:Grant(player, argument) then
			notify(context, player, `{argument} granted`)
		else
			notify(context, player, "choose an exclusive Rok")
		end
	end,
	ResetExclusive = function(context: Types.Context, player: Player, argument: string)
		if context.Services.ExclusiveService:ResetOwned(player, argument) then
			notify(context, player, `{argument} can be bought again`)
		else
			notify(context, player, "choose an exclusive Rok")
		end
	end,
	SimulateGift = function(context: Types.Context, player: Player, argument: string)
		notify(context, player, context.Services.PurchaseService:SimulateGift(player, argument))
	end,
	GrantOfflineClaim = function(context: Types.Context, player: Player, _argument: string)
		local data = context.Services.DataService:GetData(player)
		local amount = if data then data.Offline.LastAmount else 0
		if context.Services.OfferService:GrantOfflineClaim(player) then
			notify(context, player, `Claim x3: +{NumberFormat.Compact(amount * 2)}`)
		end
	end,
	ClearBoosts = function(context: Types.Context, player: Player, _argument: string)
		context.Services.BoostService:ClearPersonal(player)
		context.Services.BoostService:ClearServer()
		notify(context, player, "all boosts cleared")
	end,
	SetTrainingTier = function(context: Types.Context, player: Player, argument: string)
		local tier = number(context, player, argument, 1, #TrainingConfig.Stands)
		if tier and context.Services.TrainingService:SetTier(player, tier) then
			notify(context, player, `{TrainingConfig.Stands[tier].DisplayName} Training`)
		end
	end,
	SetPedestalSlots = function(context: Types.Context, player: Player, argument: string)
		local slots = number(context, player, argument, 1, PedestalSlots.Total())
		if slots and context.Services.PedestalService:SetSlots(player, slots) then
			notify(context, player, `{slots} slots`)
		end
	end,
	GrantPet = function(context: Types.Context, player: Player, _argument: string)
		local geodeKey = zoneGeode(context, player)
		local petKey = if geodeKey then HatchOdds.Roll(random, geodeKey, 1) else nil
		local grant = if petKey then context.Services.PetService:Grant(player, petKey) else nil
		if not grant then
			notify(context, player, "no Rok granted")
			return
		end
		local pet = PetConfig.Pets[grant.PetKey]
		local trait = if grant.Trait then ` + {grant.Trait} {grant.TraitValue}` else ""
		notify(context, player, `{pet.DisplayName} ({pet.Rarity}){trait}{if grant.IsNew then " New" else ""}`)
	end,
	GrantGeode = function(context: Types.Context, player: Player, _argument: string)
		local geodeKey = zoneGeode(context, player)
		if geodeKey and context.Services.GeodeService:GrantGeodes(player, geodeKey, 1) then
			notify(context, player, `+1 {GeodeConfig.Geodes[geodeKey].DisplayName}`)
		end
	end,
	GrantLuckyGeode = function(context: Types.Context, player: Player, _argument: string)
		local luckyKey = context.Services.GeodeService:GrantLucky(player, 1)
		if luckyKey then
			notify(context, player, `+1 {GeodeConfig.Geodes[luckyKey].DisplayName}`)
		end
	end,
	ForceSecret = function(context: Types.Context, player: Player, _argument: string)
		context.Services.GeodeService:ForceNextRarity(player, "Secret")
		notify(context, player, "next hatch is a Secret")
	end,
	ForceMaster = function(context: Types.Context, player: Player, _argument: string)
		context.Services.RockService:ForceNextMaster(player)
		notify(context, player, "next chop is a Master")
	end,
	ForceRush = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.RockService:ForceRush(player) then
			notify(context, player, "next broken rock comes back as a Rush Rock")
		else
			notify(context, player, "a Rush Rock is already out")
		end
	end,
	WeatherStart = function(context: Types.Context, player: Player, argument: string)
		if context.Services.WeatherService:Force(argument) then
			notify(context, player, `{argument} started`)
		else
			notify(context, player, `no weather called {argument}`)
		end
	end,
	WeatherEnd = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.WeatherService:EndActive() then
			notify(context, player, "weather ended")
		else
			notify(context, player, "no weather is on")
		end
	end,
	WeatherNext = function(context: Types.Context, player: Player, _argument: string)
		local seconds = WeatherConfig.AdminNextSeconds
		local key = context.Services.WeatherService:StartIn(seconds)
		notify(context, player, `{key} in {seconds}s`)
	end,
	GiveModifier = function(context: Types.Context, player: Player, argument: string)
		local petId = targetRok(context, player)
		if petId and context.Services.PetService:SetModifier(player, petId, argument, false) then
			notify(context, player, `Rok {petId} is now {argument}`)
		else
			notify(context, player, "hold a Rok or own one first")
		end
	end,
	SpawnDiamond = function(context: Types.Context, player: Player, _argument: string)
		local _spawned, message = context.Services.DiamondRockService:Spawn(player)
		notify(context, player, message)
	end,
	DiamondTimeLeft = function(context: Types.Context, player: Player, _argument: string)
		local seconds = DiamondRockConfig.AdminCountdownSeconds
		if context.Services.DiamondRockService:SetTimeLeft(seconds) then
			notify(context, player, `Diamond Rock ends in {seconds}s`)
		else
			notify(context, player, "no Diamond Rock out")
		end
	end,
	LeaderboardRefresh = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.LeaderboardService:Refresh() then
			notify(context, player, "leaderboards refreshing")
		else
			notify(context, player, "a refresh is already running")
		end
	end,
	LeaderboardWeek = function(context: Types.Context, player: Player, argument: string)
		if not RunService:IsStudio() then
			notify(context, player, "week offset is Studio only")
			return
		end
		local offset = number(context, player, argument, 0, 52)
		if offset then
			context.Services.StatsService:SetWeekOffset(offset)
			context.Services.LeaderboardService:Refresh()
			notify(context, player, `leaderboard week offset {offset}`)
		end
	end,
	StartGeodeFall = function(context: Types.Context, player: Player, _argument: string)
		local _started, message = context.Services.GeodeFallService:Spawn(player)
		notify(context, player, message)
	end,
	GeodeFallTimeLeft = function(context: Types.Context, player: Player, _argument: string)
		local seconds = GeodeFallConfig.AdminLifetimeSeconds
		if context.Services.GeodeFallService:SetTimeLeft(seconds) then
			notify(context, player, `Geode Fall ends in {seconds}s`)
		else
			notify(context, player, "no landed Geode Fall")
		end
	end,
	SpawnSpots = function(context: Types.Context, player: Player, _argument: string)
		local isShown = context.Services.RockService:ToggleSpawnSpots(player)
		notify(context, player, if isShown then "spawn spots shown" else "spawn spots hidden")
	end,
	ResetData = function(context: Types.Context, player: Player, _argument: string)
		if context.Services.DataService:ResetData(player) then
			notify(context, player, "data reset")
		end
	end,
	ResetTutorial = function(context: Types.Context, player: Player, argument: string)
		local keys = sortedKeys(tutorialServices)
		table.insert(keys, 1, "All")
		local key = Arguments.Match(argument, keys)
		if not key then
			notify(context, player, `no tutorial called {argument}`)
			return
		end
		for name, serviceName in tutorialServices do
			if key == "All" or key == name then
				context.Services[serviceName]:Reset(player)
			end
		end
		context.Services.DataService:Set(player, { "Offers", MonetizationConfig.TasteOfferKey }, nil)
		notify(context, player, `{key} tutorial reset`)
	end,
	SimulateOffline = function(context: Types.Context, player: Player, argument: string)
		local hours = Arguments.Decimal(argument, 0, AdminConfig.Limits.OfflineHours)
		if not hours then
			notify(context, player, `enter hours from 0 to {AdminConfig.Limits.OfflineHours}`)
			return
		end
		local earned = context.Services.PedestalService:SimulateOffline(player, hours * 3600)
		notify(context, player, `{hours}h offline: +{NumberFormat.Compact(earned)} on pads`)
	end,
	GrantRok = function(context: Types.Context, player: Player, argument: string)
		local words = Arguments.Words(argument)
		local petKey = Arguments.Match(words[1], sortedKeys(PetConfig.Pets))
		local amount = count(context, player, words[2], 1, PetConfig.MaxPets)
		if not petKey then
			notify(context, player, `no Rok called {words[1] or ""}`)
			return
		end
		if not amount then
			return
		end
		local keys: { string } = table.create(amount, petKey)
		local grants = context.Services.PetService:GrantMany(player, keys)
		notify(context, player, `+{#grants} {PetConfig.Pets[petKey].DisplayName}`)
	end,
	SetRokTrait = function(context: Types.Context, player: Player, argument: string)
		local words = Arguments.Words(argument)
		local isNone = words[1] ~= nil and string.lower(words[1]) == string.lower(AdminConfig.NoTraitValue)
		local trait = if isNone then nil else Arguments.Match(words[1], sortedKeys(PetConfig.Traits))
		if not isNone and not trait then
			notify(context, player, `no trait called {words[1] or ""}`)
			return
		end
		local definition = if trait then PetConfig.Traits[trait] else nil
		local value = if definition
			then (if words[2]
				then Arguments.Decimal(words[2], definition.MinValue, definition.MaxValue)
				else definition.MaxValue)
			else nil
		if definition and not value then
			notify(context, player, `enter a value from {definition.MinValue} to {definition.MaxValue}`)
			return
		end
		local petId = targetRok(context, player)
		if petId and context.Services.PetService:SetTrait(player, petId, trait, value) then
			notify(context, player, `Rok {petId} trait {if trait then `{trait} {value}` else "cleared"}`)
		else
			notify(context, player, "hold a Rok or own one first")
		end
	end,
	GrantGeodes = function(context: Types.Context, player: Player, argument: string)
		local words = Arguments.Words(argument)
		local geodeKey = Arguments.Match(words[1], GeodeOrder.Sorted())
		local amount =
			count(context, player, words[2], AdminConfig.GeodeGrantAmount, AdminConfig.Limits.GeodeGrant)
		if not geodeKey then
			notify(context, player, `no geode called {words[1] or ""}`)
			return
		end
		if amount and context.Services.GeodeService:GrantGeodes(player, geodeKey, amount) then
			notify(context, player, `+{amount} {GeodeConfig.Geodes[geodeKey].DisplayName}`)
		end
	end,
	ForceRarity = function(context: Types.Context, player: Player, argument: string)
		local rarity = Arguments.Match(argument, RarityConfig.Order)
		if not rarity then
			notify(context, player, `no rarity called {argument}`)
			return
		end
		context.Services.GeodeService:ForceNextRarity(player, rarity)
		notify(context, player, `next hatch is {rarity}`)
	end,
	PityDue = function(context: Types.Context, player: Player, argument: string)
		local rarity = Arguments.Match(argument, GeodeConfig.PityRarities)
		local geodeKey = zoneGeode(context, player)
		local threshold = if rarity and geodeKey then HatchPity.Threshold(geodeKey, rarity) else nil
		local data = context.Services.DataService:GetData(player)
		if not rarity or not geodeKey or not threshold or not data then
			notify(context, player, `no pity called {argument}`)
			return
		end
		local counts = table.clone(data.Pity[geodeKey] or {})
		counts[rarity] = threshold - 1
		context.Services.DataService:Set(player, { "Pity", geodeKey }, counts)
		notify(context, player, `next {geodeKey} Geode crack is a guaranteed {rarity}`)
	end,
	FillBackpack = function(context: Types.Context, player: Player, _argument: string)
		local room = context.Services.PassService:GetBackpackSize(player)
			- context.Services.PetService:Count(player)
		local grants = context.Services.PetService:GrantMany(player, rollZoneRoks(context, player, room))
		notify(context, player, `+{#grants} Roks (Backpack full)`)
	end,
	ClearBackpack = function(context: Types.Context, player: Player, _argument: string)
		local removed = context.Services.PetService:RemoveUnplaced(player)
		notify(context, player, `removed {removed} Roks`)
	end,
	FillPedestals = function(context: Types.Context, player: Player, _argument: string)
		local services = context.Services
		services.PedestalService:SetSlots(player, PedestalSlots.Total())
		services.PedestalService:EquipBest(player)
		local missing = services.PedestalService:EmptySlotCount(player)
		if missing > 0 then
			services.PetService:GrantMany(player, rollZoneRoks(context, player, missing))
			services.PedestalService:EquipBest(player)
		end
		notify(context, player, `{PedestalSlots.Total()} pedestals filled`)
	end,
	IndexComplete = function(context: Types.Context, player: Player, argument: string)
		setIndex(context, player, argument, true)
	end,
	IndexReset = function(context: Types.Context, player: Player, argument: string)
		setIndex(context, player, argument, false)
	end,
	IndexClaimAll = function(context: Types.Context, player: Player, _argument: string)
		local claimed = context.Services.IndexService:ClaimAll(player)
		notify(context, player, `claimed {claimed} Index rewards`)
	end,
	ForceQuality = function(context: Types.Context, player: Player, argument: string)
		local name = Arguments.Match(argument, qualityNames)
		local quality = if name then (ChopQuality :: any)[name] else nil
		if not name or type(quality) ~= "number" then
			notify(context, player, `no chop quality called {argument}`)
			return
		end
		context.Services.RockService:ForceNextQuality(player, quality)
		notify(context, player, `next chop is {name}`)
	end,
	CheatAlwaysPerfect = cheat("AlwaysPerfect", "always Perfect"),
	CheatOneHit = cheat("OneHit", "one-hit break"),
	CheatIgnoreStrength = cheat("IgnoreStrength", "ignore strength"),
	CheatInstantRespawn = cheat("InstantRespawn", "instant respawn"),
	SpawnRock = function(context: Types.Context, player: Player, argument: string)
		local key = Arguments.Match(argument, sortedKeys(RockConfig.Rocks :: any))
		if not key then
			notify(context, player, `no rock called {argument}`)
			return
		end
		local _spawned, message = context.Services.RockService:SpawnNear(player, key)
		notify(context, player, message)
	end,
	SetStreakTier = function(context: Types.Context, player: Player, argument: string)
		local tier = number(context, player, argument, 0, #HotStreakConfig.Tiers)
		if tier and context.Services.HotStreakService:SetTier(player, tier) then
			notify(context, player, if tier > 0 then `Hot Streak tier {tier}` else "Hot Streak off")
		end
	end,
	FreezeStreak = function(context: Types.Context, player: Player, _argument: string)
		local isFrozen = context.Services.HotStreakService:ToggleFreeze(player)
		notify(context, player, if isFrozen then "Hot Streak frozen" else "Hot Streak unfrozen")
	end,
	SaveSnapshot = snapshot(Snapshots.Save),
	LoadSnapshot = snapshot(Snapshots.Load),
	DeleteSnapshot = snapshot(Snapshots.Delete),
	ListSnapshots = function(context: Types.Context, player: Player, _argument: string)
		notify(context, player, Snapshots.List(context, player))
	end,
	ResetPlayerData = function(context: Types.Context, player: Player, argument: string)
		local target, problem = Targets.Resolve(argument)
		if not target then
			context.PendingResets[player] = nil
			notify(context, player, problem or "no player found")
			return
		end
		local where = if target.Player then "" else " (not in this server)"
		local pending = context.PendingResets[player]
		local now = os.clock()
		if not pending or pending.UserId ~= target.UserId or now > pending.ExpiresAt then
			context.PendingResets[player] =
				{ UserId = target.UserId, ExpiresAt = now + AdminConfig.ResetConfirmSeconds }
			notify(
				context,
				player,
				`run again within {AdminConfig.ResetConfirmSeconds}s to reset {target.Name}'s data{where}`
			)
			return
		end
		context.PendingResets[player] = nil
		local targetPlayer = target.Player
		if targetPlayer then
			if not context.Services.DataService:ResetData(targetPlayer) then
				notify(context, player, `{target.Name}'s data is not loaded yet`)
				return
			end
			if targetPlayer ~= player then
				notify(context, targetPlayer, `your data was reset by {player.Name}`)
			end
		else
			notify(context, player, `resetting {target.Name}'s save...`)
			local isReset, message = context.Services.DataService:ResetOfflineData(target.UserId)
			if not isReset then
				notify(context, player, `{target.Name}: {message}`)
				return
			end
		end
		print(`[AdminService] {player.Name} reset the data of {target.Name} ({target.UserId}){where}`)
		notify(context, player, `{target.Name}'s data reset`)
	end,
}

return Commands
