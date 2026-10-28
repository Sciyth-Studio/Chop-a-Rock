--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TutorialConfig = require(ReplicatedStorage.Config.TutorialConfig)
local Targets = require(script.Parent.Targets)

export type State = {
	Adornee: Instance?,
	LastRoot: Vector3?,
	BindName: string,
	IsTurning: boolean,
}

local CameraTurn = {}

local count = 0

local function flat(vector: Vector3): Vector3?
	local result = Vector3.new(vector.X, 0, vector.Z)
	return if result.Magnitude > 0.01 then result.Unit else nil
end

local function yawBetween(from: Vector3, to: Vector3): number
	local angle = math.atan2(from.Z, from.X) - math.atan2(to.Z, to.X)
	return (angle + math.pi) % (2 * math.pi) - math.pi
end

function CameraTurn.new(): State
	count += 1
	return {
		Adornee = nil,
		LastRoot = nil,
		BindName = `TutorialCameraTurn{count}`,
		IsTurning = false,
	}
end

local function stop(state: State)
	if state.IsTurning then
		state.IsTurning = false
		RunService:UnbindFromRenderStep(state.BindName)
	end
end

local function start(state: State, target: Targets.Target)
	stop(state)
	state.IsTurning = true
	local elapsed = 0
	local turned = 0
	RunService:BindToRenderStep(state.BindName, Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		local camera = workspace.CurrentCamera
		if not camera or camera.CameraType ~= Enum.CameraType.Custom then
			stop(state)
			return
		end
		local focus = camera.Focus.Position
		local look = flat(camera.CFrame.LookVector)
		local wanted = flat(target.Position - focus)
		if not look or not wanted then
			stop(state)
			return
		end
		elapsed += dt
		local alpha = math.clamp(elapsed / TutorialConfig.CameraTurnSeconds, 0, 1)
		local eased = 1 - (1 - alpha) ^ 3
		local remaining = yawBetween(look, wanted)
		local total = turned + remaining
		local step = total * eased - turned
		turned += step
		local pivot = CFrame.new(focus)
		camera.CFrame = pivot * CFrame.Angles(0, step, 0) * pivot:Inverse() * camera.CFrame
		if alpha >= 1 then
			stop(state)
		end
	end)
end

function CameraTurn.Update(state: State, target: Targets.Target?, isWalking: boolean)
	local root = Targets.RootPosition()
	local isJump = root ~= nil
		and state.LastRoot ~= nil
		and (root - state.LastRoot :: Vector3).Magnitude > TutorialConfig.CameraTurnJumpStuds
	local adornee = if target then target.Adornee else nil
	if target and isWalking and (adornee ~= state.Adornee or isJump) then
		start(state, target)
	end
	if not isWalking or adornee ~= state.Adornee then
		state.Adornee = if isWalking then adornee else nil
	end
	state.LastRoot = root
end

function CameraTurn.Destroy(state: State)
	stop(state)
end

return CameraTurn
