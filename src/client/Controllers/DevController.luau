--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local RESET_KEY = Enum.KeyCode.Backspace

local DevController = {
	Name = "DevController",
	_trove = nil :: TroveInstance?,
}

function DevController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function DevController.Start(self: any)
	if not RunService:IsStudio() then
		return
	end
	local trove = self._trove :: TroveInstance
	trove:Connect(UserInputService.InputBegan, function(input: InputObject, _processed: boolean)
		if
			input.KeyCode == RESET_KEY
			and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		then
			Packets.DevResetData:Fire()
		end
	end)
end

function DevController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return DevController
