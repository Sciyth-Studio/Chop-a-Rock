--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopPoseConfig = require(ReplicatedStorage.Config.ChopPoseConfig)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)

type Joint = Instance

export type Rig = {
	Humanoid: Humanoid,
	HipHeight: number,
	RightShoulder: Joint,
	RightElbow: Joint,
	LeftShoulder: Joint,
	LeftElbow: Joint,
	Waist: Joint,
	RightHip: Joint,
	LeftHip: Joint,
	RightKnee: Joint,
	LeftKnee: Joint,
	RightAnkle: Joint,
	LeftAnkle: Joint,
}

export type State = {
	Stance: number,
	CrouchBoost: number,
	ArmAngle: number,
	WaistLean: number,
	LeftArmBlend: number,
}

export type Targets = {
	Arm: number,
	Waist: number,
	Stance: number,
	Boost: number,
	Rate: number,
	LeftArmBlend: number,
}

local JOINT_PATHS: { { Field: string, Part: string, Joint: string } } = {
	{ Field = "RightShoulder", Part = "RightUpperArm", Joint = "RightShoulder" },
	{ Field = "RightElbow", Part = "RightLowerArm", Joint = "RightElbow" },
	{ Field = "LeftShoulder", Part = "LeftUpperArm", Joint = "LeftShoulder" },
	{ Field = "LeftElbow", Part = "LeftLowerArm", Joint = "LeftElbow" },
	{ Field = "Waist", Part = "UpperTorso", Joint = "Waist" },
	{ Field = "RightHip", Part = "RightUpperLeg", Joint = "RightHip" },
	{ Field = "LeftHip", Part = "LeftUpperLeg", Joint = "LeftHip" },
	{ Field = "RightKnee", Part = "RightLowerLeg", Joint = "RightKnee" },
	{ Field = "LeftKnee", Part = "LeftLowerLeg", Joint = "LeftKnee" },
	{ Field = "RightAnkle", Part = "RightFoot", Joint = "RightAnkle" },
	{ Field = "LeftAnkle", Part = "LeftFoot", Joint = "LeftAnkle" },
}

local ChopPose = {}

local function setTransform(joint: Joint, value: CFrame)
	(joint :: any).Transform = value
end

local function approach(current: number, target: number, rate: number, dt: number): number
	return current + (target - current) * (1 - math.exp(-rate * dt))
end

function ChopPose.NewState(): State
	return { Stance = 0, CrouchBoost = 1, ArmAngle = 0, WaistLean = 0, LeftArmBlend = 0 }
end

function ChopPose.LoopTargets(clock: number): Targets
	local interval = TrainingConfig.ChopIntervalSeconds
	local hold = ChopPoseConfig.TrainingStrikeHoldSeconds
	local since = clock % interval
	if since < hold then
		return {
			Arm = math.rad(ChopPoseConfig.RightArmStrikeDegrees),
			Waist = math.rad(ChopPoseConfig.WaistStrikeLeanDegrees),
			Stance = 1,
			Boost = ChopPoseConfig.StrikeCrouchBoost,
			Rate = ChopPoseConfig.StrikeRate,
			LeftArmBlend = 0,
		}
	end
	local wait = math.rad(ChopPoseConfig.RightArmWaitDegrees)
	local peak = math.rad(ChopPoseConfig.RightArmPeakDegrees)
	local level = math.clamp((since - hold) / math.max(interval - hold, 1e-3), 0, 1)
	return {
		Arm = wait + (peak - wait) * level,
		Waist = math.rad(ChopPoseConfig.WaistLeanDegrees),
		Stance = 1,
		Boost = 1,
		Rate = ChopPoseConfig.ArmFollowRate,
		LeftArmBlend = 0,
	}
end

function ChopPose.Build(character: Model, timeout: number): Rig?
	local humanoid = character:WaitForChild("Humanoid", timeout)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return nil
	end
	local found: { [string]: any } = { Humanoid = humanoid, HipHeight = humanoid.HipHeight }
	for _, path in JOINT_PATHS do
		local part = character:WaitForChild(path.Part, timeout)
		local joint = if part then part:WaitForChild(path.Joint, timeout) else nil
		if not joint or not (joint:IsA("Motor6D") or joint:IsA("AnimationConstraint")) then
			return nil
		end
		found[path.Field] = joint
	end
	return found :: any
end

function ChopPose.Step(state: State, targets: Targets, dt: number): boolean
	state.ArmAngle = approach(state.ArmAngle, targets.Arm, targets.Rate, dt)
	state.WaistLean = approach(state.WaistLean, targets.Waist, targets.Rate, dt)
	state.Stance = approach(state.Stance, targets.Stance, ChopPoseConfig.StanceRate, dt)
	state.CrouchBoost = approach(state.CrouchBoost, targets.Boost, ChopPoseConfig.StrikeRate, dt)
	state.LeftArmBlend =
		approach(state.LeftArmBlend, targets.LeftArmBlend, ChopPoseConfig.MasterArmBlendRate, dt)

	local threshold = ChopPoseConfig.SettleThresholdRadians
	if targets.Stance == 0 and state.Stance < threshold and math.abs(state.ArmAngle) < threshold then
		state.Stance = 0
		state.ArmAngle = 0
		state.WaistLean = 0
		state.LeftArmBlend = 0
		return false
	end
	return true
end

function ChopPose.Apply(rig: Rig, state: State): number
	local pose = ChopPoseConfig
	local stance = state.Stance
	local crouch = stance * state.CrouchBoost
	local flex = math.rad(pose.HipFlexDegrees) * crouch
	local bend = math.rad(pose.KneeBendDegrees) * crouch
	local abduct = math.rad(pose.HipAbductDegrees) * stance
	local tremor = math.sin(os.clock() * math.pi * 2 * pose.TremorHz) * math.rad(pose.TremorDegrees) * stance
	local kneeAngle = -bend + tremor
	local ankleAngle = bend - flex

	setTransform(rig.RightHip, CFrame.Angles(flex, 0, abduct))
	setTransform(rig.LeftHip, CFrame.Angles(flex, 0, -abduct))
	setTransform(rig.RightKnee, CFrame.Angles(kneeAngle, 0, 0))
	setTransform(rig.LeftKnee, CFrame.Angles(kneeAngle, 0, 0))
	setTransform(rig.RightAnkle, CFrame.Angles(ankleAngle, 0, 0))
	setTransform(rig.LeftAnkle, CFrame.Angles(ankleAngle, 0, 0))

	local armAngle = state.ArmAngle
	local leftArmBlend = state.LeftArmBlend
	local guard = CFrame.Angles(
		math.rad(pose.LeftShoulderGuardDegrees) * stance,
		math.rad(pose.LeftShoulderYawDegrees) * stance,
		math.rad(pose.LeftShoulderInwardDegrees) * stance
	)
	setTransform(rig.LeftShoulder, guard:Lerp(CFrame.Angles(armAngle, 0, 0), leftArmBlend))
	setTransform(
		rig.LeftElbow,
		CFrame.Angles(math.rad(pose.LeftElbowGuardDegrees) * stance * (1 - leftArmBlend), 0, 0)
	)

	local wait = math.rad(pose.RightArmWaitDegrees)
	local peak = math.rad(pose.RightArmPeakDegrees)
	local raised = math.clamp((armAngle - wait) / (peak - wait), 0, 1)
	local elbow = math.rad(pose.RightElbowWaitDegrees)
		+ (math.rad(pose.RightElbowPeakDegrees) - math.rad(pose.RightElbowWaitDegrees)) * raised
	setTransform(rig.RightShoulder, CFrame.Angles(armAngle, 0, 0))
	setTransform(rig.RightElbow, CFrame.Angles(elbow * stance, 0, 0))
	setTransform(rig.Waist, CFrame.Angles(state.WaistLean, 0, 0))

	return pose.HipHeightDrop * stance
end

return ChopPose
