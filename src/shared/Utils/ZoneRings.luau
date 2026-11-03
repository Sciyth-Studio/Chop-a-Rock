--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local ZoneGeodeConfig = require(ReplicatedStorage.Config.ZoneGeodeConfig)

export type Ring = {
	Zone: string,
	Center: Vector3,
	Radius: number,
}

local ZoneRings = {}

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

function ZoneRings.Read(): { Ring }
	local rings: { Ring } = {}
	for _, tagged in CollectionService:GetTagged(ZoneGeodeConfig.RingTag) do
		if not tagged:IsA("BasePart") or not tagged:IsDescendantOf(workspace) then
			continue
		end
		local zone = tagged:GetAttribute(RockSpawnConfig.ZoneAttribute)
		if type(zone) ~= "string" then
			warn(`[ZoneRings] {tagged:GetFullName()} has no {RockSpawnConfig.ZoneAttribute} attribute`)
			continue
		end
		local size = tagged.Size
		table.insert(rings, {
			Zone = zone,
			Center = tagged.Position,
			Radius = math.max(size.X, size.Y, size.Z) / 2,
		})
	end
	return rings
end

function ZoneRings.Hide()
	for _, tagged in CollectionService:GetTagged(ZoneGeodeConfig.RingTag) do
		if tagged:IsA("BasePart") then
			tagged.Transparency = 1
		end
	end
end

function ZoneRings.Overlaps(rings: { Ring }, position: Vector3, margin: number): boolean
	for _, ring in rings do
		if flatDistance(position, ring.Center) < ring.Radius + margin then
			return true
		end
	end
	return false
end

function ZoneRings.Containing(rings: { Ring }, zone: string, position: Vector3): Ring?
	for _, ring in rings do
		if ring.Zone == zone and flatDistance(position, ring.Center) <= ring.Radius then
			return ring
		end
	end
	return nil
end

return ZoneRings
