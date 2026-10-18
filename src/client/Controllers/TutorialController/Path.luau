--!strict

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)

export type State = {
	Path: Path,
	Points: { Vector3 },
	Goal: Vector3?,
	ComputedAt: number,
	IsComputing: boolean,
	Generation: number,
}

local Path = {}

local goalMoveStuds = 3

function Path.new(): State
	return {
		Path = PathfindingService:CreatePath({
			AgentRadius = TutorialConfig.PathAgentRadius,
			AgentHeight = TutorialConfig.PathAgentHeight,
			AgentCanJump = true,
			WaypointSpacing = TutorialConfig.PathWaypointSpacing,
		}),
		Points = {},
		Goal = nil,
		ComputedAt = -math.huge,
		IsComputing = false,
		Generation = 0,
	}
end

function Path.Clear(state: State)
	state.Generation += 1
	state.Points = {}
	state.Goal = nil
	state.ComputedAt = -math.huge
	state.IsComputing = false
end

local function distanceToSegment(point: Vector3, a: Vector3, b: Vector3): (number, number)
	local flatPoint = Vector3.new(point.X, 0, point.Z)
	local flatA = Vector3.new(a.X, 0, a.Z)
	local flatB = Vector3.new(b.X, 0, b.Z)
	local segment = flatB - flatA
	local lengthSquared = segment:Dot(segment)
	local t = if lengthSquared > 0
		then math.clamp((flatPoint - flatA):Dot(segment) / lengthSquared, 0, 1)
		else 0
	return (flatA + segment * t - flatPoint).Magnitude, t
end

local function compute(state: State, from: Vector3, goal: Vector3)
	state.IsComputing = true
	state.ComputedAt = os.clock()
	local generation = state.Generation
	task.spawn(function()
		local ok = pcall(function()
			state.Path:ComputeAsync(from, goal)
		end)
		if state.Generation ~= generation then
			return
		end
		state.IsComputing = false
		if ok and state.Path.Status == Enum.PathStatus.Success then
			local points = {}
			for _, waypoint in state.Path:GetWaypoints() do
				table.insert(points, waypoint.Position)
			end
			state.Points = points
		else
			state.Points = { from, goal }
		end
	end)
end

function Path.Update(state: State, from: Vector3, goal: Vector3)
	local hasGoalMoved = state.Goal == nil or ((state.Goal :: Vector3) - goal).Magnitude > goalMoveStuds
	if hasGoalMoved then
		state.Goal = goal
		state.Points = { from, goal }
		state.ComputedAt = -math.huge
	end
	if state.IsComputing then
		return
	end
	local isStale = os.clock() - state.ComputedAt >= TutorialConfig.PathRecomputeSeconds
	if hasGoalMoved or isStale or Path.Stray(state, from) > TutorialConfig.PathStrayStuds then
		compute(state, from, goal)
	end
end

function Path.Stray(state: State, from: Vector3): number
	local points = state.Points
	if #points < 2 then
		return 0
	end
	local best = math.huge
	for index = 1, #points - 1 do
		local distance = distanceToSegment(from, points[index], points[index + 1])
		best = math.min(best, distance)
	end
	return best
end

function Path.From(state: State, from: Vector3): { Vector3 }
	local points = state.Points
	if #points < 2 then
		return { from, state.Goal or from }
	end
	local bestIndex = 1
	local bestT = 0
	local best = math.huge
	for index = 1, #points - 1 do
		local distance, t = distanceToSegment(from, points[index], points[index + 1])
		if distance < best then
			best = distance
			bestIndex = index
			bestT = t
		end
	end
	local result = { from }
	if bestT < 1 then
		table.insert(result, points[bestIndex + 1])
	end
	for index = bestIndex + 2, #points do
		table.insert(result, points[index])
	end
	return result
end

return Path
