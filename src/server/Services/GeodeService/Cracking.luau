--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local HatchOdds = require(ReplicatedStorage.HatchOdds)
local HatchTiming = require(ReplicatedStorage.HatchTiming)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Effects = require(script.Parent.Effects)
local Luck = require(script.Parent.Luck)
local Types = require(script.Parent.Types)

local Cracking = {}

function Cracking.PickGeode(data: any): string?
	local keys = GeodeOrder.Sorted()
	for index = #keys, 1, -1 do
		local key = keys[index]
		if (data.Geodes[key] or 0) > 0 then
			return key
		end
	end
	return nil
end

function Cracking.Begin(
	context: Types.Context,
	player: Player,
	geodeKey: string,
	spot: Attachment,
	pit: Types.Pit,
	random: Random
): Types.Session?
	local data = context.Services.DataService:GetData(player)
	local geode = GeodeConfig.Geodes[geodeKey]
	if not data or not geode or (data.Geodes[geodeKey] or 0) < 1 then
		return nil
	end
	if not context.Services.PetService:CanAdd(player, 1) then
		context.Services.NotificationService:Notify(player, "Error", "Bag full! Sell some Roks")
		return nil
	end
	Effects.Show(pit.Model)
	local part = pit.Part
	local session: Types.Session = {
		GeodeKey = geodeKey,
		Spot = spot,
		Model = pit.Model,
		Part = part,
		CanBreak = data.Strength >= geode.StrengthRequired,
		StrengthRatio = GeodeConfig.ZoneStrengthRatio,
		Center = ChopZones.RandomCenter(random),
		StartTime = os.clock(),
	}
	context.Services.PetService:PutAway(player)
	Packets.ChopMinigameStart:FireClient(
		player,
		part,
		session.CanBreak,
		session.StrengthRatio,
		session.Center,
		1,
		1
	)
	return session
end

function Cracking.IsReady(session: Types.Session): boolean
	return os.clock() - session.StartTime >= ChopConfig.RoundInputDelaySeconds
end

local function forcedPet(context: Types.Context, player: Player, geodeKey: string): string?
	local rarity = context.ForcedRarities[player]
	context.ForcedRarities[player] = nil
	if not rarity then
		return nil
	end
	for _, entry in GeodeConfig.Geodes[geodeKey].Pets do
		local pet = PetConfig.Pets[entry.PetKey]
		if pet and pet.Rarity == rarity then
			return entry.PetKey
		end
	end
	return nil
end

local function tooWeak(context: Types.Context, player: Player, session: Types.Session)
	local geode = GeodeConfig.Geodes[session.GeodeKey]
	Packets.ChopResult:FireClient(player, ChopQuality.Crack, 0, 0, 1, 1)
	Effects.Crack(session.Part)
	Effects.Hide(session.Model, GeodeConfig.TooWeakClearSeconds)
	context.Services.NotificationService:Notify(
		player,
		"Error",
		`Get stronger! Need {NumberFormat.Commas(geode.StrengthRequired)} Strength`
	)
	print(`[GeodeService] {player.Name} too weak for {session.GeodeKey}`)
end

function Cracking.Release(
	context: Types.Context,
	player: Player,
	session: Types.Session,
	random: Random
): number
	if not session.CanBreak then
		tooWeak(context, player, session)
		return GeodeConfig.TooWeakClearSeconds + GeodeConfig.RecrackDelaySeconds
	end
	local services = context.Services
	local elapsed = math.max(0, os.clock() - session.StartTime - ChopConfig.LatencyCompensationSeconds)
	local quality = ChopZones.Classify(ChopZones.Position(elapsed), session.Center, session.StrengthRatio)
	if
		services.RockService:ConsumeForcedMaster(player)
		or services.RockService:RollMaster(quality, session.StrengthRatio)
	then
		quality = ChopQuality.Master
	end
	local luck = Luck.Total(context, player, quality)
	local petKey = forcedPet(context, player, session.GeodeKey)
		or HatchOdds.Roll(random, session.GeodeKey, luck)
	local data = services.DataService:GetData(player)
	local owned = if data then data.Geodes[session.GeodeKey] or 0 else 0
	if not petKey or owned < 1 or not services.PetService:CanAdd(player, 1) then
		Packets.ChopResult:FireClient(player, ChopQuality.Crack, 0, 0, 1, 1)
		Effects.Hide(session.Model, 0)
		return GeodeConfig.RecrackDelaySeconds
	end
	services.DataService:Set(player, { "Geodes", session.GeodeKey }, owned - 1)
	local grant = services.PetService:Grant(player, petKey)
	if not grant then
		services.DataService:Set(player, { "Geodes", session.GeodeKey }, owned)
		Packets.ChopResult:FireClient(player, ChopQuality.Crack, 0, 0, 1, 1)
		Effects.Hide(session.Model, 0)
		return GeodeConfig.RecrackDelaySeconds
	end
	local pet = PetConfig.Pets[grant.PetKey]
	local rarity = RarityConfig.Rarities[pet.Rarity]
	local isMaster = quality == ChopQuality.Master
	Packets.ChopResult:FireClient(player, quality, 0, 1, 0, 1)
	print(
		`[GeodeService] {player.Name} cracked {session.GeodeKey}: quality={quality}, luck={string.format(
			"%.2f",
			luck
		)}, pet={grant.PetKey}, new={grant.IsNew}`
	)
	if isMaster then
		Effects.MasterStart(session.Part)
		for _, other in Players:GetPlayers() do
			services.NotificationService:Notify(
				other,
				MasterChopConfig.AnnouncementKind,
				`{player.DisplayName} landed a Master Chop!`
			)
		end
	else
		Effects.Hit(session.Part, quality)
	end
	local revealDelay = if isMaster
		then MasterChopConfig.ImpactDelaySeconds
		else ChopConfig.SlowMoPreImpactSeconds
	Effects.Hide(session.Model, revealDelay)
	task.delay(revealDelay, function()
		Packets.GeodeHatched:FireAllClients(
			player,
			session.Spot,
			session.GeodeKey,
			grant.PetKey,
			table.find(RarityConfig.Order, pet.Rarity) or 1,
			grant.IsNew,
			grant.Trait or ""
		)
	end)
	if rarity.Announce then
		task.delay(revealDelay + HatchTiming.RevealSeconds(pet.Rarity), function()
			for _, other in Players:GetPlayers() do
				services.NotificationService:Notify(
					other,
					GeodeConfig.AnnouncementKind,
					`{player.DisplayName} hatched a {rarity.DisplayName} {pet.DisplayName}!`
				)
			end
		end)
	end
	local strikeHold = if isMaster then MasterChopConfig.StrikeHoldSeconds else 0
	return revealDelay
		+ math.max(strikeHold, HatchTiming.RevealSeconds(pet.Rarity))
		+ GeodeConfig.RecrackDelaySeconds
end

return Cracking
