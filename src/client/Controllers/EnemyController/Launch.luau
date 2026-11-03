--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local MovementLock = require(ReplicatedStorage.Utils.MovementLock)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local Launch = {}

local function hasGround(position: Vector3, excluded: Instance): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { excluded }
	local ray = Vector3.new(0, -EnemyConfig.LaunchGroundRayStuds, 0)
	return workspace:Raycast(position, ray, params) ~= nil
end

function Launch.Play(trove: TroveInstance, character: Model, from: Vector3, zoneScale: number)
	trove:Clean()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return
	end
	local offset = Vector3.new(root.Position.X - from.X, 0, root.Position.Z - from.Z)
	local direction = if offset.Magnitude > 1e-3 then offset.Unit else -root.CFrame.LookVector
	local speed = EnemyConfig.LaunchSpeedStuds * zoneScale
	local up = EnemyConfig.LaunchUpStuds
	local airSeconds = 2 * up / workspace.Gravity
	if not hasGround(root.Position + direction * speed * airSeconds, character) then
		direction = -direction
	end

	trove:Add(MovementLock.Acquire(humanoid))
	humanoid.PlatformStand = true
	trove:Add(function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
	root.AssemblyLinearVelocity = direction * speed + Vector3.new(0, up, 0)
	root.AssemblyAngularVelocity = direction:Cross(Vector3.yAxis) * EnemyConfig.LaunchSpinRadians
	local endsAt = os.clock() + airSeconds + EnemyConfig.LaunchSeconds
	trove:Connect(RunService.Heartbeat, function()
		if os.clock() >= endsAt or not humanoid.Parent or humanoid.Health <= 0 then
			trove:Clean()
		end
	end)
end

return Launch
