--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local Motion = require(script.Parent.Motion)

local Wander = {}

local function queryParams(folder: Instance): RaycastParams
	local excluded: { Instance } = { folder }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(excluded, player.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	params.RespectCanCollide = true
	return params
end

local function candidate(enemy: Motion.Enemy, zoneScale: number): Vector3
	local angle = math.random() * 2 * math.pi
	local distance = math.sqrt(math.random()) * EnemyConfig.WanderRadiusStuds * zoneScale
	local point = enemy.Home + Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance
	local margin = enemy.Radius + EnemyConfig.WanderWallMarginStuds * zoneScale
	local low, high = enemy.AreaMin, enemy.AreaMax
	local function clampAxis(value: number, lowEdge: number, highEdge: number, middle: number): number
		if highEdge - lowEdge <= margin * 2 then
			return middle
		end
		return math.clamp(value, lowEdge + margin, highEdge - margin)
	end
	return Vector3.new(
		clampAxis(point.X, low.X, high.X, enemy.Home.X),
		enemy.Home.Y,
		clampAxis(point.Z, low.Z, high.Z, enemy.Home.Z)
	)
end

local function isOnFloor(
	enemy: Motion.Enemy,
	point: Vector3,
	params: RaycastParams,
	zoneScale: number
): boolean
	local origin = point + Vector3.new(0, enemy.Height + 2, 0)
	local result = workspace:Raycast(origin, Vector3.new(0, -enemy.Height * 2 - 4, 0), params)
	return result ~= nil
		and math.abs(result.Position.Y - enemy.Home.Y)
			<= EnemyConfig.WanderFloorToleranceStuds * zoneScale
end

local function isPathClear(enemy: Motion.Enemy, point: Vector3, params: RaycastParams): boolean
	local radius = math.min(enemy.Radius, enemy.Height / 2, 256) * 0.9
	local lift = Vector3.new(0, enemy.Height / 2, 0)
	local offset = point - enemy.Position
	local direction = offset + offset.Unit * enemy.Radius
	return workspace:Spherecast(enemy.Position + lift, radius, direction, params) == nil
end

function Wander.Pick(enemy: Motion.Enemy, folder: Instance, zoneScale: number): Vector3?
	local params = queryParams(folder)
	for _ = 1, EnemyConfig.WanderTries do
		local point = candidate(enemy, zoneScale)
		if (point - enemy.Position).Magnitude < enemy.Radius then
			continue
		end
		if isOnFloor(enemy, point, params, zoneScale) and isPathClear(enemy, point, params) then
			return point
		end
	end
	return nil
end

return Wander
