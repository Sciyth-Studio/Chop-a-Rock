--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ChopAnimation = require(ReplicatedStorage.Utils.ChopAnimation)
local MasterChopConfig = require(ReplicatedStorage.Config.MasterChopConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local ChopAnimationController = {
	Name = "ChopAnimationController",
	_trove = nil :: TroveInstance?,
}

local chopController: any = nil
local trainingController: any = nil
local tracks: ChopAnimation.Tracks? = nil

local function currentMode(): ChopAnimation.Mode
	if chopController and chopController:IsMinigameActive() then
		local masterSeconds = chopController:GetMasterSeconds()
		if masterSeconds then
			local strikeAt = MasterChopConfig.ImpactDelaySeconds - ChopAnimation.StrikeLeadSeconds()
			return if masterSeconds >= strikeAt then "Strike" else "WindUp"
		end
		return if chopController:IsReleased() then "Strike" else "WindUp"
	end
	if trainingController and trainingController:IsTraining() then
		return ChopAnimation.TrainingMode(
			trainingController:GetSecondsSinceChop(),
			trainingController:HasChopped()
		)
	end
	return "None"
end

local function step()
	local current = tracks
	if not current then
		return
	end
	ChopAnimation.SetMode(current, currentMode())
	ChopAnimation.HoldStrikeEnd(current)
end

local function onCharacter(character: Model)
	tracks = nil
	task.spawn(function()
		local loaded = ChopAnimation.Load(character, 10)
		if character.Parent then
			tracks = loaded
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
		local current = tracks
		if current then
			ChopAnimation.SetMode(current, "None")
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
