--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ChopPoseConfig = require(ReplicatedStorage.Config.ChopPoseConfig)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())
type Joint = Instance
type Rig = {
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

local ChopAnimationController = {
	Name = "ChopAnimationController",
	_trove = nil :: TroveInstance?,
}

local chopController: any = nil
local trainingController: any = nil
local rig: Rig? = nil
local stance = 0
local crouchBoost = 1
local armAngle = 0
local waistLean = 0
local leftArmBlend = 0
local isHipHeightApplied = false

local function setTransform(joint: Joint, value: CFrame)
	(joint :: any).Transform = value
end

local function buildRig(character: Model): Rig?
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return nil
	end
	local found: { [string]: any } = { Humanoid = humanoid, HipHeight = humanoid.HipHeight }
	for _, path in JOINT_PATHS do
		local part = character:WaitForChild(path.Part, 10)
		local joint = if part then part:WaitForChild(path.Joint, 10) else nil
		if not joint or not (joint:IsA("Motor6D") or joint:IsA("AnimationConstraint")) then
			return nil
		end
		found[path.Field] = joint
	end
	return found :: any
end

local function targets(): (number, number, number, number, number)
	local wait = math.rad(ChopPoseConfig.RightArmWaitDegrees)
	local peak = math.rad(ChopPoseConfig.RightArmPeakDegrees)
	local strike = math.rad(ChopPoseConfig.RightArmStrikeDegrees)
	local waistStance = math.rad(ChopPoseConfig.WaistLeanDegrees)
	local waistStrike = math.rad(ChopPoseConfig.WaistStrikeLeanDegrees)
	if chopController and chopController:IsMinigameActive() then
		local masterPhase = chopController:GetMasterPhase()
		if masterPhase == "WindUp" then
			return peak,
				math.rad(ChopPoseConfig.MasterWindUpWaistDegrees),
				1,
				ChopPoseConfig.MasterCrouchBoost,
				ChopPoseConfig.ArmFollowRate
		elseif masterPhase == "Strike" then
			return strike, waistStrike, 1, ChopPoseConfig.MasterCrouchBoost, ChopPoseConfig.StrikeRate
		end
		if chopController:IsReleased() then
			return math.rad(ChopPoseConfig.RightArmStrikeDegrees),
				math.rad(ChopPoseConfig.WaistStrikeLeanDegrees),
				1,
				ChopPoseConfig.StrikeCrouchBoost,
				ChopPoseConfig.StrikeRate
		end
		local level = math.clamp(chopController:GetCursorPosition(), 0, 1)
		return wait + (peak - wait) * level, waistStance, 1, 1, ChopPoseConfig.ArmFollowRate
	end
	if trainingController and trainingController:IsTraining() then
		local since = trainingController:GetSecondsSinceChop()
		local hold = ChopPoseConfig.TrainingStrikeHoldSeconds
		local hasChopped = trainingController:HasChopped()
		if hasChopped and since < hold then
			return strike, waistStrike, 1, ChopPoseConfig.StrikeCrouchBoost, ChopPoseConfig.StrikeRate
		end
		local windStart = if hasChopped then hold else 0
		local windSeconds = math.max(TrainingConfig.ChopIntervalSeconds - windStart, 1e-3)
		local level = math.clamp((since - windStart) / windSeconds, 0, 1)
		return wait + (peak - wait) * level, waistStance, 1, 1, ChopPoseConfig.ArmFollowRate
	end
	return 0, 0, 0, 1, ChopPoseConfig.RecoverRate
end

local function approach(current: number, target: number, rate: number, dt: number): number
	return current + (target - current) * (1 - math.exp(-rate * dt))
end

local function releaseHipHeight(current: Rig)
	if isHipHeightApplied then
		current.Humanoid.HipHeight = current.HipHeight
		isHipHeightApplied = false
	end
end

local function step(dt: number)
	local current = rig
	if not current then
		return
	end
	local targetArm, targetWaist, targetStance, targetBoost, rate = targets()
	armAngle = approach(armAngle, targetArm, rate, dt)
	waistLean = approach(waistLean, targetWaist, rate, dt)
	stance = approach(stance, targetStance, ChopPoseConfig.StanceRate, dt)
	crouchBoost = approach(crouchBoost, targetBoost, ChopPoseConfig.StrikeRate, dt)
	local isMaster = chopController ~= nil and chopController:GetMasterPhase() ~= nil
	leftArmBlend = approach(leftArmBlend, if isMaster then 1 else 0, ChopPoseConfig.MasterArmBlendRate, dt)

	local threshold = ChopPoseConfig.SettleThresholdRadians
	if targetStance == 0 and stance < threshold and math.abs(armAngle) < threshold then
		stance = 0
		armAngle = 0
		waistLean = 0
		leftArmBlend = 0
		releaseHipHeight(current)
		return
	end

	local pose = ChopPoseConfig
	local crouch = stance * crouchBoost
	local flex = math.rad(pose.HipFlexDegrees) * crouch
	local bend = math.rad(pose.KneeBendDegrees) * crouch
	local abduct = math.rad(pose.HipAbductDegrees) * stance
	local tremor = math.sin(os.clock() * math.pi * 2 * pose.TremorHz) * math.rad(pose.TremorDegrees) * stance
	local kneeAngle = -bend + tremor
	local ankleAngle = bend - flex

	setTransform(current.RightHip, CFrame.Angles(flex, 0, abduct))
	setTransform(current.LeftHip, CFrame.Angles(flex, 0, -abduct))
	setTransform(current.RightKnee, CFrame.Angles(kneeAngle, 0, 0))
	setTransform(current.LeftKnee, CFrame.Angles(kneeAngle, 0, 0))
	setTransform(current.RightAnkle, CFrame.Angles(ankleAngle, 0, 0))
	setTransform(current.LeftAnkle, CFrame.Angles(ankleAngle, 0, 0))

	local guard = CFrame.Angles(
		math.rad(pose.LeftShoulderGuardDegrees) * stance,
		math.rad(pose.LeftShoulderYawDegrees) * stance,
		math.rad(pose.LeftShoulderInwardDegrees) * stance
	)
	setTransform(current.LeftShoulder, guard:Lerp(CFrame.Angles(armAngle, 0, 0), leftArmBlend))
	setTransform(
		current.LeftElbow,
		CFrame.Angles(math.rad(pose.LeftElbowGuardDegrees) * stance * (1 - leftArmBlend), 0, 0)
	)

	local wait = math.rad(pose.RightArmWaitDegrees)
	local peak = math.rad(pose.RightArmPeakDegrees)
	local raised = math.clamp((armAngle - wait) / (peak - wait), 0, 1)
	local elbow = math.rad(pose.RightElbowWaitDegrees)
		+ (math.rad(pose.RightElbowPeakDegrees) - math.rad(pose.RightElbowWaitDegrees)) * raised
	setTransform(current.RightShoulder, CFrame.Angles(armAngle, 0, 0))
	setTransform(current.RightElbow, CFrame.Angles(elbow * stance, 0, 0))
	setTransform(current.Waist, CFrame.Angles(waistLean, 0, 0))

	current.Humanoid.HipHeight = current.HipHeight - pose.HipHeightDrop * stance
	isHipHeightApplied = true
end

local function onCharacter(character: Model)
	isHipHeightApplied = false
	stance = 0
	crouchBoost = 1
	armAngle = 0
	waistLean = 0
	rig = nil
	task.spawn(function()
		local built = buildRig(character)
		if character.Parent then
			rig = built
		end
	end)
end

function ChopAnimationController.Init(self: any, controllers: { [string]: any })
	self._trove = Trove.new()
	chopController = controllers.ChopController
	trainingController = controllers.TrainingController
end

function ChopAnimationController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local player = Players.LocalPlayer
	trove:Connect(player.CharacterAdded, onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
	trove:Connect(RunService.PreSimulation, step)
	trove:Add(function()
		local current = rig
		if current then
			releaseHipHeight(current)
		end
	end)
end

function ChopAnimationController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return ChopAnimationController
