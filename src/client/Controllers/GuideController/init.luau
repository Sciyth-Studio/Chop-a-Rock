--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local ArrowTrail = require(script.ArrowTrail)
local RockLabels = require(script.RockLabels)

type TroveInstance = typeof(Trove.new())

local GuideController = {
	Name = "GuideController",
	_trove = nil :: TroveInstance?,
}

function GuideController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function GuideController.Start(self: any)
	local trove = self._trove :: TroveInstance
	RockLabels.Start(trove)
	ArrowTrail.Start(trove)
end

function GuideController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return GuideController
