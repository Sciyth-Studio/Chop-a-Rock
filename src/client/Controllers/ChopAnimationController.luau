--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ChopPose = require(ReplicatedStorage.Utils.ChopPose)
local ChopPoseConfig = require(ReplicatedStorage.Config.ChopPoseConfig)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local ChopAnimationController = {
	Name = "ChopAnimationController",
	_trove = nil :: TroveInstance?,
}

local chopController: any = nil
local trainingController: any = nil
local rig: ChopPose.Rig? = nil
local state = ChopPose.NewState()
local isHipHeightApplied = false

local function targets(): ChopPose.Targets
	local wait = math.rad(ChopPoseConfig.RightArmWaitDegrees)
	local peak = math.rad(ChopPoseConfig.RightArmPeakDegrees)
	local strike = math.rad(ChopPoseConfig.RightArmStrikeDegrees)
	local waistStance = math.rad(ChopPoseConfig.WaistLeanDegrees)
	local waistStrike = math.rad(ChopPoseConfig.WaistStrikeLeanDegrees)
	local isMaster = chopController ~= nil and chopController:GetMasterPhase() ~= nil
	local leftArmBlend = if isMaster then 1 else 0
	if chopController and chopController:IsMinigameActive() then
		local masterPhase = chopController:GetMasterPhase()
		if masterPhase == "WindUp" then
			return {
				Arm = peak,
				Waist = math.rad(ChopPoseConfig.MasterWindUpWaistDegrees),
				Stance = 1,
				Boost = ChopPoseConfig.MasterCrouchBoost,
				Rate = ChopPoseConfig.ArmFollowRate,
				LeftArmBlend = leftArmBlend,
			}
		elseif masterPhase == "Strike" then
			return {
				Arm = strike,
				Waist = waistStrike,
				Stance = 1,
				Boost = ChopPoseConfig.MasterCrouchBoost,
				Rate = ChopPoseConfig.StrikeRate,
				LeftArmBlend = leftArmBlend,
			}
		end
		if chopController:IsReleased() then
			return {
				Arm = strike,
				Waist = waistStrike,
				Stance = 1,
				Boost = ChopPoseConfig.StrikeCrouchBoost,
				Rate = ChopPoseConfig.StrikeRate,
				LeftArmBlend = leftArmBlend,
			}
		end
		local level = math.clamp(chopController:GetCursorPosition(), 0, 1)
		return {
			Arm = wait + (peak - wait) * level,
			Waist = waistStance,
			Stance = 1,
			Boost = 1,
			Rate = ChopPoseConfig.ArmFollowRate,
			LeftArmBlend = leftArmBlend,
		}
	end
	if trainingController and trainingController:IsTraining() then
		local since = trainingController:GetSecondsSinceChop()
		local hold = ChopPoseConfig.TrainingStrikeHoldSeconds
		local hasChopped = trainingController:HasChopped()
		if hasChopped and since < hold then
			return {
				Arm = strike,
				Waist = waistStrike,
				Stance = 1,
				Boost = ChopPoseConfig.StrikeCrouchBoost,
				Rate = ChopPoseConfig.StrikeRate,
				LeftArmBlend = leftArmBlend,
			}
		end
		local windStart = if hasChopped then hold else 0
		local windSeconds = math.max(TrainingConfig.ChopIntervalSeconds - windStart, 1e-3)
		local level = math.clamp((since - windStart) / windSeconds, 0, 1)
		return {
			Arm = wait + (peak - wait) * level,
			Waist = waistStance,
			Stance = 1,
			Boost = 1,
			Rate = ChopPoseConfig.ArmFollowRate,
			LeftArmBlend = leftArmBlend,
		}
	end
	return {
		Arm = 0,
		Waist = 0,
		Stance = 0,
		Boost = 1,
		Rate = ChopPoseConfig.RecoverRate,
		LeftArmBlend = leftArmBlend,
	}
end

local function releaseHipHeight(current: ChopPose.Rig)
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
	if not ChopPose.Step(state, targets(), dt) then
		releaseHipHeight(current)
		return
	end
	current.Humanoid.HipHeight = current.HipHeight - ChopPose.Apply(current, state)
	isHipHeightApplied = true
end

local function onCharacter(character: Model)
	isHipHeightApplied = false
	state = ChopPose.NewState()
	rig = nil
	task.spawn(function()
		local built = ChopPose.Build(character, 10)
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
