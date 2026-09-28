--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FontConfig = require(ReplicatedStorage.Config.FontConfig)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local STOP_ACTION = "TrainingStop"

local activeTrove: TroveInstance? = nil

local function hideUI()
	if activeTrove then
		activeTrove:Destroy()
		activeTrove = nil
	end
end

local function showUI()
	hideUI()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local trove = Trove.new()
	activeTrove = trove

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TrainingHint"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	trove:Add(screenGui)

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.85, 0)
	label.Size = UDim2.new(0, 520, 0, 70)
	label.BackgroundTransparency = 1
	label.FontFace = FontConfig.Default
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "Press SPACE to stop training"
	label.Parent = screenGui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.new(0, 0, 0)
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label

	ContextActionService:BindAction(STOP_ACTION, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			Packets.TrainingStopRequest:Fire()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)

	trove:Add(function()
		ContextActionService:UnbindAction(STOP_ACTION)
	end)
end

local TrainingController = {
	Name = "TrainingController",
	_trove = nil :: TroveInstance?,
}

function TrainingController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function TrainingController.Start(self: any)
	local trove = self._trove :: TroveInstance
	trove:Add(Packets.TrainingStarted.OnClientEvent:Connect(showUI))
	trove:Add(Packets.TrainingStopped.OnClientEvent:Connect(hideUI))
end

function TrainingController.Destroy(self: any)
	hideUI()
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return TrainingController
