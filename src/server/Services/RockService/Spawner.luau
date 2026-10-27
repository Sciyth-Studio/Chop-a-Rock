--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local Types = require(script.Parent.Types)

local Spawner = {}

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function extent(rotation: CFrame, size: Vector3, direction: Vector3): number
	return math.abs(rotation.RightVector:Dot(direction)) * size.X / 2
		+ math.abs(rotation.LookVector:Dot(direction)) * size.Z / 2
end

local function isFree(
	spot: Types.Spot,
	shape: Types.Shape,
	rotation: CFrame,
	rocks: { Types.Rock },
	avoid: Vector3?,
	reserved: { Types.Reserved }
): boolean
	for _, area in reserved do
		if flatDistance(spot.Position, area.Position) < shape.Radius + area.Radius then
			return false
		end
	end
	if avoid and flatDistance(spot.Position, avoid) < shape.Radius + RockSpawnConfig.PlayerClearanceStuds then
		return false
	end
	for _, rock in rocks do
		local offset = rock.CFrame.Position - spot.Position
		local flat = Vector3.new(offset.X, 0, offset.Z)
		local distance = flat.Magnitude
		if distance < 1e-3 then
			return false
		end
		local direction = flat / distance
		local reach = extent(rotation, shape.Size, direction) + extent(rock.CFrame, rock.Size, direction)
		if distance < reach + RockSpawnConfig.RockGapStuds then
			return false
		end
	end
	return true
end

function Spawner.PickKey(
	random: Random,
	weights: { [string]: number },
	rockCount: number,
	rocks: { Types.Rock }
): string?
	local total = 0
	for _, weight in weights do
		total += math.max(weight, 0)
	end
	if total <= 0 then
		return nil
	end
	local counts: { [string]: number } = {}
	for _, rock in rocks do
		counts[rock.Key] = (counts[rock.Key] or 0) + 1
	end
	local best: { string } = {}
	local bestDeficit = -math.huge
	for key, weight in weights do
		if weight <= 0 then
			continue
		end
		local deficit = weight / total * rockCount - (counts[key] or 0)
		if deficit > bestDeficit + 1e-6 then
			best = { key }
			bestDeficit = deficit
		elseif math.abs(deficit - bestDeficit) <= 1e-6 then
			table.insert(best, key)
		end
	end
	return if #best > 0 then best[random:NextInteger(1, #best)] else nil
end

function Spawner.PickSpot(
	random: Random,
	spots: { Types.Spot },
	shape: Types.Shape,
	rotation: CFrame,
	rocks: { Types.Rock },
	avoid: Vector3?,
	reserved: { Types.Reserved }
): Types.Spot?
	local valid: { Types.Spot } = {}
	for _, spot in spots do
		if spot.Fits[shape.Key] and isFree(spot, shape, rotation, rocks, avoid, reserved) then
			table.insert(valid, spot)
		end
	end
	if #valid == 0 then
		return nil
	end
	return valid[random:NextInteger(1, #valid)]
end

function Spawner.PickSpotNear(
	random: Random,
	spots: { Types.Spot },
	shape: Types.Shape,
	rotation: CFrame,
	rocks: { Types.Rock },
	center: Vector3?,
	radius: number,
	reserved: { Types.Reserved }
): Types.Spot?
	if not center then
		return Spawner.PickSpot(random, spots, shape, rotation, rocks, nil, reserved)
	end
	local near: { Types.Spot } = {}
	local nearest: Types.Spot? = nil
	local nearestDistance = math.huge
	for _, spot in spots do
		if not spot.Fits[shape.Key] or not isFree(spot, shape, rotation, rocks, center, reserved) then
			continue
		end
		local distance = flatDistance(spot.Position, center)
		if distance <= radius then
			table.insert(near, spot)
		end
		if distance < nearestDistance then
			nearest = spot
			nearestDistance = distance
		end
	end
	if #near > 0 then
		return near[random:NextInteger(1, #near)]
	end
	return nearest
end

return Spawner
