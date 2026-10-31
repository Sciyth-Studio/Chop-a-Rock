--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ItemIcons = require(ReplicatedStorage.Utils.ItemIcons)
local IconConfig = require(ReplicatedStorage.Config.IconConfig)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopTiming = require(ServerScriptService.Utils.ChopTiming)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local ChopZones = require(ReplicatedStorage.ChopZones)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local HatchOdds = require(ReplicatedStorage.HatchOdds)
local HatchPity = require(ReplicatedStorage.HatchPity)
local HatchTiming = require(ReplicatedStorage.HatchTiming)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local GeodeOrder = require(ReplicatedStorage.Utils.GeodeOrder)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local WildGeodeConfig = require(ReplicatedStorage.Config.WildGeodeConfig)
local Effects = require(script.Parent.Effects)
local Luck = require(script.Parent.Luck)
local Types = require(script.Parent.Types)

local Cracking = {}

function Cracking.PickGeode(data: any): string?
	return GeodeOrder.Pick(data.Geodes, data.SelectedGeode)
end

local function hide(session: Types.Session, delaySeconds: number)
	local model = session.Model
	if model then
		Effects.Hide(model, delaySeconds)
	end
end

local function rollModifier(context: Types.Context, player: Player, geodeKey: string): string?
	local weather = context.Services.WeatherService
	local modifier = weather:RollHatchModifier(player)
	if modifier or not GeodeConfig.Geodes[geodeKey].GuaranteedModifier then
		return modifier
	end
	return weather:RollAnyModifier()
end

function Cracking.Begin(
	context: Types.Context,
	player: Player,
	geodeKey: string,
	spot: Attachment,
	pit: Types.Pit,
	random: Random,
	isAuto: boolean
): Types.Session?
	local data = context.Services.DataService:GetData(player)
	local geode = GeodeConfig.Geodes[geodeKey]
	if not data or not geode or (data.Geodes[geodeKey] or 0) < 1 then
		return nil
	end
	if not context.Services.PetService:CanAdd(player, 1) then
		context.Services.NotificationService:Notify(
			player,
			"Error",
			"Bag full! Sell Pets",
			IconConfig.Backpack
		)
		return nil
	end
	Effects.Show(pit.Model)
	local part = pit.Part
	local session: Types.Session = {
		GeodeKey = geodeKey,
		Spot = spot,
		Model = pit.Model,
		Part = part,
		StrengthRatio = GeodeConfig.ZoneStrengthRatio,
		Center = ChopZones.RandomCenter(random),
		StartTime = os.clock(),
		IsAuto = isAuto,
		IsWild = false,
		IsCracked = false,
	}
	context.Services.PetService:PutAway(player)
	if isAuto then
		return session
	end
	Packets.ChopMinigameStart:FireClient(player, part, true, session.StrengthRatio, session.Center, 1, 1)
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

local function isFirstPet(data: any, geodeKey: string): boolean
	if Tutorial.StepOf(data.Tutorial) ~= Tutorial.Crack or next(data.Pets) ~= nil then
		return false
	end
	for _, entry in GeodeConfig.Geodes[geodeKey].Pets do
		if entry.PetKey == TutorialConfig.FirstPetKey then
			return true
		end
	end
	return false
end

function Cracking.Release(
	context: Types.Context,
	player: Player,
	session: Types.Session,
	random: Random,
	claimed: number
): number
	local services = context.Services
	local elapsed = ChopTiming.Elapsed(session.StartTime, claimed)
	local isTouch = ChopZones.IsTouch(player)
	local quality = ChopZones.Classify(
		ChopZones.Position(elapsed, isTouch),
		session.Center,
		session.StrengthRatio,
		isTouch
	)
	local tutorialData = services.DataService:GetData(player)
	local isTutorial = tutorialData ~= nil and Tutorial.IsActive(Tutorial.StepOf(tutorialData.Tutorial))
	if
		not isTutorial
		and (
			services.RockService:ConsumeForcedMaster(player)
			or services.RockService:RollMaster(quality, session.StrengthRatio)
		)
	then
		quality = ChopQuality.Master
	end
	if not isTutorial then
		services.StatsService:RecordChop(player, quality)
	end
	return Cracking.Finish(context, player, session, random, quality)
end

function Cracking.Finish(
	context: Types.Context,
	player: Player,
	session: Types.Session,
	random: Random,
	quality: number
): number
	local services = context.Services
	local luck = Luck.Total(context, player, quality)
	local data = services.DataService:GetData(player)
	local pityGeodeKey = GeodeConfig.Geodes[session.GeodeKey].BaseKey or session.GeodeKey
	local pityCounts = if data then data.Pity[pityGeodeKey] else nil
	local isFirst = data ~= nil and isFirstPet(data, session.GeodeKey)
	local forced = forcedPet(context, player, session.GeodeKey)
		or if isFirst then TutorialConfig.FirstPetKey else nil
	local due = if forced then nil else HatchPity.Due(pityGeodeKey, pityCounts)
	local pityKey = if due then HatchOdds.RollRarity(random, session.GeodeKey, due) else nil
	local minRarity = if session.IsWild then WildGeodeConfig.MinRarity else nil
	local petKey = forced or pityKey or HatchOdds.Roll(random, session.GeodeKey, luck, minRarity)
	local isPity = pityKey ~= nil
	local owned = if data then data.Geodes[session.GeodeKey] or 0 else 0
	if not petKey or (owned < 1 and not session.IsWild) or not services.PetService:CanAdd(player, 1) then
		if not session.IsWild then
			Packets.ChopResult:FireClient(player, ChopQuality.Crack, 0, 0, 1, 1)
		end
		hide(session, 0)
		return GeodeConfig.RecrackDelaySeconds
	end
	if not session.IsWild then
		services.DataService:Set(player, { "Geodes", session.GeodeKey }, owned - 1)
	end
	local hatchedPet = PetConfig.Pets[petKey]
	local equipDelay = (
		if quality == ChopQuality.Master
			then MasterChopConfig.ImpactDelaySeconds
			else ChopConfig.SlowMoPreImpactSeconds
	) + HatchTiming.RevealSeconds(if hatchedPet then hatchedPet.Rarity else RarityConfig.Order[1])
	local grant = services.PetService:Grant(
		player,
		petKey,
		rollModifier(context, player, session.GeodeKey),
		equipDelay,
		luck,
		if isFirst then TutorialConfig.FirstPetSize else nil
	)
	if not grant then
		if not session.IsWild then
			services.DataService:Set(player, { "Geodes", session.GeodeKey }, owned)
			Packets.ChopResult:FireClient(player, ChopQuality.Crack, 0, 0, 1, 1)
		end
		hide(session, 0)
		return GeodeConfig.RecrackDelaySeconds
	end
	session.IsCracked = true
	local pet = PetConfig.Pets[grant.PetKey]
	services.DataService:Set(
		player,
		{ "Pity", pityGeodeKey },
		HatchPity.After(pityGeodeKey, pityCounts, pet.Rarity)
	)
	local rarity = RarityConfig.Rarities[pet.Rarity]
	local isMaster = quality == ChopQuality.Master
	if not session.IsWild then
		Packets.ChopResult:FireClient(player, quality, 0, 1, 0, 1)
	end
	print(
		`[GeodeService] {player.Name} cracked {session.GeodeKey}: quality={quality}, luck={string.format(
			"%.2f",
			luck
		)}, pet={grant.PetKey}, new={grant.IsNew}, pity={if isPity then due else "none"}`
	)
	local part = session.Part
	if part and isMaster then
		Effects.MasterStart(part)
		for _, other in Players:GetPlayers() do
			services.NotificationService:Notify(
				other,
				MasterChopConfig.AnnouncementKind,
				`Master Chop by {player.DisplayName}!`
			)
		end
	elseif part then
		Effects.Hit(part, quality)
	end
	local revealDelay = if isMaster
		then MasterChopConfig.ImpactDelaySeconds
		else ChopConfig.SlowMoPreImpactSeconds
	hide(session, revealDelay)
	task.delay(revealDelay, function()
		Packets.GeodeHatched:FireAllClients(
			player,
			session.Spot,
			session.GeodeKey,
			grant.PetKey,
			table.find(RarityConfig.Order, pet.Rarity) or 1,
			grant.IsNew,
			grant.Trait or "",
			grant.Modifier or "",
			grant.Size or "",
			isPity
		)
	end)
	if rarity.Announce then
		task.delay(revealDelay + HatchTiming.RevealSeconds(pet.Rarity), function()
			for _, other in Players:GetPlayers() do
				services.NotificationService:Notify(
					other,
					GeodeConfig.AnnouncementKind,
					`{player.DisplayName} got {rarity.DisplayName} {pet.DisplayName}!`,
					ItemIcons.Get("Pet", grant.PetKey)
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
