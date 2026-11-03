--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local Types = require(script.Parent.Types)

local Strips = {}

function Strips.Order(weights: { [string]: number }): { string }
	local configs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	local keys: { string } = {}
	for key in weights do
		if configs[key] then
			table.insert(keys, key)
		end
	end
	table.sort(keys, function(first: string, second: string)
		local firstStrength = configs[first].StrengthRequired
		local secondStrength = configs[second].StrengthRequired
		if firstStrength == secondStrength then
			return first < second
		end
		return firstStrength < secondStrength
	end)
	return keys
end

function Strips.Entrance(areas: { BasePart }, zone: string): Vector3?
	for _, area in areas do
		local parent = area.Parent
		if area:GetAttribute(RockSpawnConfig.ZoneAttribute) == zone and parent then
			local entrance = parent:FindFirstChild(RockSpawnConfig.EntranceName, true)
			if entrance and entrance:IsA("BasePart") then
				return entrance.Position
			elseif entrance and entrance:IsA("Model") then
				return entrance:GetPivot().Position
			end
		end
	end
	return nil
end

function Strips.Assign(spots: { Types.Spot }, entrance: Vector3, count: number)
	if #spots == 0 or count < 1 then
		return
	end
	local centre = Vector3.zero
	for _, spot in spots do
		centre += spot.Position
	end
	centre /= #spots
	local flat = Vector3.new(centre.X - entrance.X, 0, centre.Z - entrance.Z)
	if flat.Magnitude < 1e-3 then
		return
	end
	local direction = flat.Unit
	local depths: { number } = {}
	local nearest, farthest = math.huge, -math.huge
	for index, spot in spots do
		local depth = (spot.Position - entrance):Dot(direction)
		depths[index] = depth
		nearest = math.min(nearest, depth)
		farthest = math.max(farthest, depth)
	end
	local span = math.max(farthest - nearest, 1e-3)
	for index, spot in spots do
		spot.Strip = math.clamp(math.floor((depths[index] - nearest) / span * count) + 1, 1, count)
	end
end

function Strips.Filter(spots: { Types.Spot }, strip: number?): { Types.Spot }
	if not strip then
		return spots
	end
	local kept: { Types.Spot } = {}
	for _, spot in spots do
		if spot.Strip == strip then
			table.insert(kept, spot)
		end
	end
	return kept
end

return Strips
