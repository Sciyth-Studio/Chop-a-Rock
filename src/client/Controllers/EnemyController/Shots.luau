--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local Motion = require(script.Parent.Motion)

local Shots = {}

local function enemyChest(enemy: Motion.Enemy): Vector3
	return enemy.Position + Vector3.new(0, enemy.Height * EnemyConfig.SideShotLookHeights, 0)
end

function Shots.Watch(start: CFrame, enemy: Motion.Enemy, alpha: number): CFrame
	local eased = 1 - (1 - math.clamp(alpha, 0, 1)) ^ 3
	return start:Lerp(CFrame.lookAt(start.Position, enemyChest(enemy)), eased)
end

function Shots.Face(enemy: Motion.Enemy, alpha: number): CFrame
	local look = enemy.Position + Vector3.new(0, enemy.Height * 0.6, 0)
	local distance = enemy.Height * EnemyConfig.FaceShotHeights - EnemyConfig.ShotPushInStuds * alpha
	return CFrame.lookAt(look + enemy.Facing * distance, look)
end

function Shots.Player(root: BasePart, towards: Vector3, alpha: number): CFrame
	local look = root.Position + Vector3.new(0, EnemyConfig.PlayerShotLookStuds, 0)
	local away = Vector3.new(towards.X - look.X, 0, towards.Z - look.Z)
	local direction = if away.Magnitude > 1e-3 then away.Unit else root.CFrame.LookVector
	local distance = EnemyConfig.PlayerShotStuds - EnemyConfig.ShotPushInStuds * alpha
	return CFrame.lookAt(look + direction * distance, look)
end

local function clearDistance(from: Vector3, direction: Vector3, wanted: number, character: Model): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(from, direction * wanted, params)
	return if hit then math.max(hit.Distance - EnemyConfig.SideShotWallMarginStuds, 0) else wanted
end

function Shots.Side(enemy: Motion.Enemy, feet: Vector3, character: Model): CFrame
	local between = Vector3.new(enemy.Position.X - feet.X, 0, enemy.Position.Z - feet.Z)
	local right = if between.Magnitude > 1e-3 then between.Unit else enemy.Facing
	local look = (feet + enemy.Position) / 2
		+ Vector3.new(0, enemy.Height * EnemyConfig.SideShotLookHeights, 0)
	local wanted =
		math.max((between.Magnitude + enemy.Height) * EnemyConfig.SideShotSpan, EnemyConfig.SideShotMinStuds)
	local back = -Vector3.yAxis:Cross(right)
	local distance = clearDistance(look, back, wanted, character)
	if distance < wanted then
		local otherDistance = clearDistance(look, -back, wanted, character)
		if otherDistance > distance then
			back = -back
			distance = otherDistance
		end
	end
	local position = look + back * distance + Vector3.new(0, EnemyConfig.SideShotLiftStuds, 0)
	return CFrame.lookAt(position, look)
end

return Shots
