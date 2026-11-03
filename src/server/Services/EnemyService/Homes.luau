--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)

export type Home = {
	Position: Vector3,
	AreaMin: Vector3,
	AreaMax: Vector3,
}

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

local function worldBounds(part: BasePart): (Vector3, Vector3)
	local half = part.Size / 2
	local axes = part.CFrame
	local extent = Vector3.new(
		math.abs(axes.RightVector.X) * half.X
			+ math.abs(axes.UpVector.X) * half.Y
			+ math.abs(axes.LookVector.X) * half.Z,
		math.abs(axes.RightVector.Y) * half.X
			+ math.abs(axes.UpVector.Y) * half.Y
			+ math.abs(axes.LookVector.Y) * half.Z,
		math.abs(axes.RightVector.Z) * half.X
			+ math.abs(axes.UpVector.Z) * half.Y
			+ math.abs(axes.LookVector.Z) * half.Z
	)
	return part.Position - extent, part.Position + extent
end

function Homes.Find(): { [string]: Home }
	local rings = taggedByZone(EnemyConfig.RingTag, EnemyConfig.ZoneAttribute)
	local areas = taggedByZone(RockSpawnConfig.AreaTag, RockSpawnConfig.ZoneAttribute)
	local excluded: { Instance } = {}
	for _, ring in rings do
		table.insert(excluded, ring)
	end
	for _, area in areas do
		table.insert(excluded, area)
	end
	local homes: { [string]: Home } = {}
	for zone in RockSpawnConfig.Zones do
		local part = rings[zone] or areas[zone]
		if part then
			local areaMin, areaMax = worldBounds(areas[zone] or part)
			homes[zone] = { Position = groundBelow(part, excluded), AreaMin = areaMin, AreaMax = areaMax }
		else
			warn(`[EnemyService] {zone} has no {EnemyConfig.RingTag} or {RockSpawnConfig.AreaTag} part`)
		end
	end
	return homes
end

return Homes
