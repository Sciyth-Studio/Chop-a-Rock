--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local Types = require(script.Parent.Types)

local Spawner = {}

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function isFree(spot: Types.Spot, shape: Types.Shape, rocks: { Types.Rock }, avoid: Vector3?): boolean
	if avoid and flatDistance(spot.Position, avoid) < shape.Radius + RockSpawnConfig.PlayerClearanceStuds then
		return false
	end
	for _, rock in rocks do
		local radius = math.max(rock.Size.X, rock.Size.Z) / 2
		if
			flatDistance(spot.Position, rock.CFrame.Position)
			< shape.Radius + radius + RockSpawnConfig.RockGapStuds
		then
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
	rocks: { Types.Rock },
	avoid: Vector3?
): Types.Spot?
	local valid: { Types.Spot } = {}
	for _, spot in spots do
		if spot.Fits[shape.Key] and isFree(spot, shape, rocks, avoid) then
			table.insert(valid, spot)
		end
	end
	if #valid == 0 then
		return nil
	end
	return valid[random:NextInteger(1, #valid)]
end

return Spawner
