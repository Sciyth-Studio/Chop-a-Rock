--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local MovementLock = require(ReplicatedStorage.Utils.MovementLock)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

export type Path = {
	Inside: Vector3,
	Start: Vector3,
	Finish: Vector3,
	Axis: Vector3,
	Height: number,
	ChargeSeconds: number,
	FlightSeconds: number,
}

local Flight = {}

local function arcPoint(path: Path, alpha: number): Vector3
	return path.Start:Lerp(path.Finish, alpha) + Vector3.new(0, 4 * path.Height * alpha * (1 - alpha), 0)
end

local function upright(position: Vector3, facing: Vector3): CFrame
	return CFrame.lookAt(position, position + facing)
end

local function along(position: Vector3, direction: Vector3, facing: Vector3): CFrame
	if direction.Magnitude < 1e-3 then
		return upright(position, facing)
	end
	local up = direction.Unit
	local right = up:Cross(Vector3.yAxis)
	if right.Magnitude < 1e-3 then
		right = facing:Cross(Vector3.yAxis)
	end
	return CFrame.fromMatrix(position, right.Unit, up)
end

function Flight.Fly(trove: TroveInstance, character: Model, path: Path)
	trove:Clean()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") or path.FlightSeconds <= 0 then
		return
	end
	local flat = Vector3.new(path.Finish.X - path.Start.X, 0, path.Finish.Z - path.Start.Z)
	local facing = if flat.Magnitude > 0 then flat.Unit else Vector3.zAxis
	local pullFrom = if (root.Position - path.Inside).Magnitude <= CannonConfig.PullRangeStuds
		then root.Position
		else path.Inside
	local barrel = along(Vector3.zero, path.Axis, facing)
	local standing = upright(Vector3.zero, facing)
	trove:Add(MovementLock.Acquire(humanoid))
	humanoid.PlatformStand = true
	trove:Add(function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = upright(path.Finish, facing)
	end)
	local began = os.clock()
	trove:Connect(RunService.PreSimulation, function()
		if not humanoid.Parent or humanoid.Health <= 0 then
			trove:Clean()
			return
		end
		local elapsed = os.clock() - began
		if elapsed < path.ChargeSeconds then
			local pull = math.min(elapsed / math.max(CannonConfig.PullSeconds, 0.01), 1)
			local eased = 1 - (1 - pull) ^ 3
			local position = pullFrom:Lerp(path.Inside, eased)
			root.CFrame = CFrame.new(position) * standing:Lerp(barrel, eased)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			return
		end
		local flown = elapsed - path.ChargeSeconds
		local alpha = math.min(flown / path.FlightSeconds, 1)
		local position = arcPoint(path, alpha)
		local ahead = arcPoint(path, math.min(alpha + 0.01, 1))
		local pose = along(position, ahead - position, facing)
		local remaining = path.FlightSeconds - flown
		if remaining < CannonConfig.UprightSeconds then
			local settle = 1 - math.max(remaining, 0) / math.max(CannonConfig.UprightSeconds, 0.01)
			pose = pose:Lerp(upright(position, facing), settle)
		end
		root.CFrame = pose
		root.AssemblyLinearVelocity = (ahead - position) / (0.01 * path.FlightSeconds)
		root.AssemblyAngularVelocity = Vector3.zero
		if alpha >= 1 then
			trove:Clean()
		end
	end)
end

return Flight
