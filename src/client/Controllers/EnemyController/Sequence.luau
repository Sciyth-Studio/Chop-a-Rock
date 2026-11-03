--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ChopAnimationConfig = require(ReplicatedStorage.Config.ChopAnimationConfig)
local ChopAnimation = require(ReplicatedStorage.Utils.ChopAnimation)
local EnemyConfig = require(ReplicatedStorage.Config.EnemyConfig)
local EnemyRules = require(ReplicatedStorage.Utils.EnemyRules)
local MovementLock = require(ReplicatedStorage.Utils.MovementLock)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Effects = require(script.Parent.Effects)
local Motion = require(script.Parent.Motion)
local Shots = require(script.Parent.Shots)

type TroveInstance = typeof(Trove.new())

export type Context = {
	Trove: TroveInstance,
	Character: Model,
	Root: BasePart,
	Humanoid: Humanoid,
	Enemy: Motion.Enemy?,
	Feet: Vector3,
	StartedAt: number,
	GetDanger: () -> number,
}

local Sequence = {}

local function shotFor(context: Context, enemy: Motion.Enemy, start: CFrame): () -> CFrame
	local sideShot: CFrame? = nil
	local hasSwirled = false
	return function(): CFrame
		local elapsed = os.clock() - context.StartedAt
		local phase, count = EnemyRules.IntroPhase(elapsed)
		if phase == "Banner" then
			return Shots.Watch(start, enemy, elapsed / EnemyConfig.ChargeSeconds)
		end
		local alpha = ((elapsed - EnemyConfig.IntroBannerSeconds) / EnemyConfig.CountSeconds) % 1
		if phase == "Count" and count == 3 then
			return Shots.Face(enemy, alpha)
		elseif phase == "Count" and count == 2 then
			if not hasSwirled then
				hasSwirled = true
				Effects.Swirl(context.Feet)
			end
			return Shots.Player(context.Root, enemy.Position, alpha)
		end
		local cached = sideShot
		if cached then
			return cached
		end
		local made = Shots.Side(enemy, context.Feet, context.Character)
		sideShot = made
		return made
	end
end

function Sequence.Camera(context: Context)
	local enemy = context.Enemy
	local camera = workspace.CurrentCamera
	if not enemy or not camera then
		return
	end
	local shot = shotFor(context, enemy, camera.CFrame)
	camera.CameraType = Enum.CameraType.Scriptable
	context.Trove:Add(function()
		camera.CameraType = Enum.CameraType.Custom
		if context.Humanoid.Parent then
			camera.CameraSubject = context.Humanoid
		end
	end)
	context.Trove:Connect(RunService.RenderStepped, function()
		camera.CFrame = shot()
	end)
end

function Sequence.Tint(context: Context)
	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = EnemyConfig.TintName
	tint.Parent = Lighting
	context.Trove:Add(tint)
	local shown = 0
	local white = Color3.new(1, 1, 1)
	context.Trove:Connect(RunService.Heartbeat, function(dt: number)
		shown += (context.GetDanger() - shown) * math.min(dt * EnemyConfig.TintFollowSpeed, 1)
		tint.TintColor = white:Lerp(EnemyConfig.TintDanger, shown)
	end)
end

function Sequence.Hold(context: Context)
	local humanoid = context.Humanoid
	local root = context.Root
	context.Trove:Add(MovementLock.Acquire(humanoid))
	root.AssemblyLinearVelocity = Vector3.zero
	local enemy = context.Enemy
	if enemy then
		local towards = Vector3.new(enemy.Position.X, root.Position.Y, enemy.Position.Z)
		if (towards - root.Position).Magnitude > 1e-3 then
			root.CFrame = CFrame.lookAt(root.Position, towards)
		end
	end
end

function Sequence.Strikes(context: Context): () -> ()
	local track: AnimationTrack? = nil
	local trove = context.Trove
	trove:Add(task.spawn(function()
		local tracks = ChopAnimation.Load(context.Character, 1)
		local strike = if tracks then tracks.Strike else nil
		if strike then
			track = strike
		end
	end))
	trove:Add(function()
		local loaded = track
		if loaded then
			loaded:Stop()
			loaded:Destroy()
		end
	end)
	local lastStrike = 0
	return function()
		local now = os.clock()
		local loaded = track
		if not loaded or now - lastStrike < EnemyConfig.StrikeEverySeconds then
			return
		end
		lastStrike = now
		loaded:Play(0.05, 1, ChopAnimationConfig.StrikeSpeed)
		loaded.TimePosition = ChopAnimationConfig.StrikeStartSeconds
	end
end

return Sequence
