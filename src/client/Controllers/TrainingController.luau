--!strict

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local STOP_ACTION = "TrainingStop"
local HINT_SCREEN = "TrainingHint"

local uiController: any = nil

local function beginTraining()
	uiController:Open(HINT_SCREEN)
	ContextActionService:BindAction(STOP_ACTION, function(_actionName, inputState)
		if inputState == Enum.UserInputState.Begin then
			Packets.TrainingStopRequest:Fire()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
end

local function endTraining()
	ContextActionService:UnbindAction(STOP_ACTION)
	uiController:Close(HINT_SCREEN)
end

local TrainingController = {
	Name = "TrainingController",
	_trove = nil :: TroveInstance?,
}

function TrainingController.Init(self: any, controllers: { [string]: any })
	self._trove = Trove.new()
	uiController = controllers.UIController
end

function TrainingController.Start(self: any)
	local trove = self._trove :: TroveInstance
	trove:Add(Packets.TrainingStarted.OnClientEvent:Connect(beginTraining))
	trove:Add(Packets.TrainingStopped.OnClientEvent:Connect(endTraining))
end

function TrainingController.Destroy(self: any)
	endTraining()
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return TrainingController
