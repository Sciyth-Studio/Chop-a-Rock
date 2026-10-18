--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local RockLabels = require(script.RockLabels)

type TroveInstance = typeof(Trove.new())

local GuideController = {
	Name = "GuideController",
	_trove = nil :: TroveInstance?,
	_controllers = {} :: { [string]: any },
}

function GuideController.Init(self: any, controllers: { [string]: any })
	self._trove = Trove.new()
	self._controllers = controllers
end

function GuideController.Start(self: any)
	local trove = self._trove :: TroveInstance
	RockLabels.Start(trove)
end

function GuideController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return GuideController
