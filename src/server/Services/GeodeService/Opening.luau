--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemIcons = require(ReplicatedStorage.Utils.ItemIcons)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local HatchOdds = require(ReplicatedStorage.HatchOdds)
local HatchTiming = require(ReplicatedStorage.HatchTiming)
local Packets = require(ReplicatedStorage.Packets)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local Effects = require(script.Parent.Effects)
local Luck = require(script.Parent.Luck)
local Types = require(script.Parent.Types)

local Opening = {}

local function rollModifier(context: Types.Context, player: Player, geodeKey: string): string?
	local weather = context.Services.WeatherService
	local modifier = weather:RollHatchModifier(player)
	if modifier or not GeodeConfig.Geodes[geodeKey].GuaranteedModifier then
		return modifier
	end
	return weather:RollAnyModifier()
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
	if Tutorial.StepOf(data.Tutorial) ~= Tutorial.Open or next(data.Pets) ~= nil then
		return false
	end
	for _, entry in GeodeConfig.Geodes[geodeKey].Pets do
		if entry.PetKey == TutorialConfig.FirstPetKey then
			return true
		end
	end
	return false
end

function Opening.Open(
	context: Types.Context,
	player: Player,
	geodeKey: string,
	pad: Types.Pad,
	random: Random
): number?
	local services = context.Services
	local data = services.DataService:GetData(player)
	if not data or not GeodeConfig.Geodes[geodeKey] then
		return nil
	end
	local luck = Luck.Total(context, player)
	local isFirst = isFirstPet(data, geodeKey)
	local forced = forcedPet(context, player, geodeKey) or if isFirst then TutorialConfig.FirstPetKey else nil
	local petKey = forced or HatchOdds.Roll(random, geodeKey, luck)
	if not petKey then
		return nil
	end
	local revealDelay = ChopConfig.SlowMoPreImpactSeconds
	local hatchedPet = PetConfig.Pets[petKey]
	local equipDelay = revealDelay
		+ HatchTiming.RevealSeconds(if hatchedPet then hatchedPet.Rarity else RarityConfig.Order[1])
	local grant = services.PetService:Grant(
		player,
		petKey,
		rollModifier(context, player, geodeKey),
		equipDelay,
		luck,
		if isFirst then TutorialConfig.FirstPetSize else nil
	)
	if not grant then
		return nil
	end
	local pet = PetConfig.Pets[grant.PetKey]
	local rarity = RarityConfig.Rarities[pet.Rarity]
	print(
		`[GeodeService] {player.Name} opened {geodeKey}: luck={string.format("%.2f", luck)}, pet={grant.PetKey}, new={grant.IsNew}`
	)
	Effects.Open(pad.Part)
	Effects.ShowOnPad(pad, nil)
	task.delay(revealDelay, function()
		Packets.GeodeHatched:FireAllClients(
			player,
			pad.Spot,
			geodeKey,
			grant.PetKey,
			table.find(RarityConfig.Order, pet.Rarity) or 1,
			grant.IsNew,
			grant.Trait or "",
			grant.Modifier or "",
			grant.Size or ""
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
	return revealDelay + HatchTiming.RevealSeconds(pet.Rarity) + GeodeConfig.RecrackDelaySeconds
end

return Opening
