--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

type TroveInstance = typeof(Trove.new())

local PadSoundController = {
	Name = "PadSoundController",
	_trove = nil :: TroveInstance?,
}

function PadSoundController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function PadSoundController.Start(self: any)
	local trove = self._trove :: TroveInstance
	trove:Add(Packets.PadCollected.OnClientEvent:Connect(function()
		LocalSound.Play("SFX_Money_Gain")
	end))
end

function PadSoundController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return PadSoundController
