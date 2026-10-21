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
	Height: number,
	ChargeSeconds: number,
	FlightSeconds: number,
}

local Flight = {}

local function arcPoint(path: Path, alpha: number): Vector3
	return path.Start:Lerp(path.Finish, alpha) + Vector3.new(0, 4 * path.Height * alpha * (1 - alpha), 0)
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
	trove:Add(MovementLock.Acquire(humanoid))
	humanoid.PlatformStand = true
	trove:Add(function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = CFrame.lookAt(path.Finish, path.Finish + facing)
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
			local position = pullFrom:Lerp(path.Inside, 1 - (1 - pull) ^ 3)
			root.CFrame = CFrame.lookAt(position, position + facing)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			return
		end
		local alpha = math.min((elapsed - path.ChargeSeconds) / path.FlightSeconds, 1)
		local position = arcPoint(path, alpha)
		local ahead = arcPoint(path, math.min(alpha + 0.01, 1))
		root.CFrame = CFrame.lookAt(position, position + facing)
		root.AssemblyLinearVelocity = (ahead - position) / (0.01 * path.FlightSeconds)
		root.AssemblyAngularVelocity = Vector3.zero
		if alpha >= 1 then
			trove:Clean()
		end
	end)
end

return Flight
