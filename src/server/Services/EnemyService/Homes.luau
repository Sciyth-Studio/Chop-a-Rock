--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)

local Homes = {}

local function taggedByZone(tag: string, attribute: string): { [string]: BasePart }
	local parts: { [string]: BasePart } = {}
	for _, tagged in CollectionService:GetTagged(tag) do
		if tagged:IsA("BasePart") and tagged:IsDescendantOf(workspace) then
			local zone = tagged:GetAttribute(attribute)
			if type(zone) == "string" then
				parts[zone] = tagged
			end
		end
	end
	return parts
end

local function groundBelow(part: BasePart, excluded: { Instance }): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	params.RespectCanCollide = true
	local top = part.Position + Vector3.new(0, part.Size.Y / 2, 0)
	local result = workspace:Raycast(top, Vector3.new(0, -EnemyConfig.GroundRayStuds, 0), params)
	return if result then result.Position else part.Position
end

function Homes.Find(): { [string]: Vector3 }
	local rings = taggedByZone(EnemyConfig.RingTag, EnemyConfig.ZoneAttribute)
	local areas = taggedByZone(RockSpawnConfig.AreaTag, RockSpawnConfig.ZoneAttribute)
	local excluded: { Instance } = {}
	for _, ring in rings do
		table.insert(excluded, ring)
	end
	for _, area in areas do
		table.insert(excluded, area)
	end
	local homes: { [string]: Vector3 } = {}
	for zone in RockSpawnConfig.Zones do
		local part = rings[zone] or areas[zone]
		if part then
			homes[zone] = groundBelow(part, excluded)
		else
			warn(`[EnemyService] {zone} has no {EnemyConfig.RingTag} or {RockSpawnConfig.AreaTag} part`)
		end
	end
	return homes
end

return Homes
