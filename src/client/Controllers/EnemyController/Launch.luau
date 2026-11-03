--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local MovementLock = require(ReplicatedStorage.Utils.MovementLock)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local Launch = {}

local function excludeOnly(excluded: Instance): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { excluded }
	return params
end

local function addTrail(trove: TroveInstance, root: BasePart)
	local top = Instance.new("Attachment")
	top.Position = Vector3.new(0, root.Size.Y / 2, 0)
	top.Parent = root
	trove:Add(top)
	local bottom = Instance.new("Attachment")
	bottom.Position = Vector3.new(0, -root.Size.Y / 2, 0)
	bottom.Parent = root
	trove:Add(bottom)
	local trail = Instance.new("Trail")
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Color = ColorSequence.new(EnemyConfig.TrailColor)
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = EnemyConfig.TrailSeconds
	trail.WidthScale = NumberSequence.new(EnemyConfig.TrailWidthStuds / math.max(root.Size.Y, 1))
	trail.LightEmission = 0.5
	trail.Parent = root
	trove:Add(trail)
end

function Launch.Play(
	trove: TroveInstance,
	character: Model,
	from: Vector3,
	zoneScale: number,
	onLanded: (hit: RaycastResult) -> ()
)
	trove:Clean()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") or humanoid.Health <= 0 then
		return
	end
	local params = excludeOnly(character)
	local offset = Vector3.new(root.Position.X - from.X, 0, root.Position.Z - from.Z)
	local direction = if offset.Magnitude > 1e-3 then offset.Unit else -root.CFrame.LookVector
	local speed = EnemyConfig.LaunchSpeedStuds * zoneScale
	local up = EnemyConfig.LaunchUpStuds
	local airSeconds = 2 * up / workspace.Gravity
	local landing = root.Position + direction * speed * airSeconds
	if not workspace:Raycast(landing, Vector3.new(0, -EnemyConfig.LaunchGroundRayStuds, 0), params) then
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
	addTrail(trove, root)
	root.AssemblyLinearVelocity = direction * speed + Vector3.new(0, up, 0)
	root.AssemblyAngularVelocity = direction:Cross(Vector3.yAxis) * EnemyConfig.LaunchSpinRadians
	local startedAt = os.clock()
	local endsAt = startedAt + airSeconds + EnemyConfig.LaunchSeconds
	local hasLanded = false
	trove:Connect(RunService.Heartbeat, function()
		local now = os.clock()
		if now >= endsAt or not humanoid.Parent or humanoid.Health <= 0 then
			trove:Clean()
			return
		end
		if hasLanded or now - startedAt < airSeconds / 2 then
			return
		end
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -EnemyConfig.LandRayStuds, 0), params)
		if hit then
			hasLanded = true
			onLanded(hit)
		end
	end)
end

return Launch
