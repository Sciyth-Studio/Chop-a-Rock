--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AutoOpenConfig = require(ReplicatedStorage.Config.AutoOpenConfig)
local ChopQuality = require(ReplicatedStorage.ChopQuality)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Cracking = require(script.Parent.Cracking)
local Types = require(script.Parent.Types)

local AutoOpen = {}

function AutoOpen.IsAllowed(context: Types.Context, player: Player, data: any): boolean
	return context.Services.PassService:Owns(player, AutoOpenConfig.PassKey)
		and not Tutorial.IsActive(Tutorial.StepOf(data.Tutorial))
end

function AutoOpen.InRange(player: Player, spot: Attachment): boolean
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return root ~= nil
		and root:IsA("BasePart")
		and (root.Position - spot.WorldPosition).Magnitude <= AutoOpenConfig.RangeStuds
end

function AutoOpen.Next(context: Types.Context, player: Player, spot: Attachment): (string?, string?)
	local services = context.Services
	local data = services.DataService:GetData(player)
	if not data or services.BaseService:GetCrackSpot(player) ~= spot then
		return nil, AutoOpenConfig.StoppedText
	end
	if not AutoOpen.IsAllowed(context, player, data) or services.RockService:HasSession(player) then
		return nil, AutoOpenConfig.StoppedText
	end
	if not AutoOpen.InRange(player, spot) then
		return nil, AutoOpenConfig.StoppedText
	end
	local geodeKey = Cracking.PickGeode(data)
	local geode = if geodeKey then GeodeConfig.Geodes[geodeKey] else nil
	if not geodeKey or not geode then
		return nil, AutoOpenConfig.DoneText
	end
	if not services.PetService:CanAdd(player, 1) then
		return nil, AutoOpenConfig.BagFullText
	end
	return geodeKey, nil
end

function AutoOpen.RollQuality(random: Random): number
	local total = 0
	for _, weight in AutoOpenConfig.QualityWeights do
		total += weight
	end
	local roll = random:NextNumber() * total
	for quality = ChopQuality.Bad, ChopQuality.Perfect do
		local weight = AutoOpenConfig.QualityWeights[quality] or 0
		if roll < weight then
			return quality
		end
		roll -= weight
	end
	return ChopQuality.Perfect
end

return AutoOpen
