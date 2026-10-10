--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopAnimation = require(ReplicatedStorage.Utils.ChopAnimation)
local Component = require(ReplicatedStorage.Packages.Component)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)

type ChopDummy = {
	Instance: Instance,
	Tracks: ChopAnimation.Tracks?,
	Offset: number,
}

return function(_controllers: { [string]: any })
	local Dummy = Component.new({ Tag = "ChopDummy" }) :: any

	function Dummy.Construct(self: ChopDummy)
		self.Offset = math.random() * TrainingConfig.ChopIntervalSeconds
	end

	function Dummy.Start(self: ChopDummy)
		local model = self.Instance
		if not model:IsA("Model") then
			return
		end
		self.Tracks = ChopAnimation.Load(model, 10)
	end

	function Dummy.Stop(self: ChopDummy)
		local tracks = self.Tracks
		if tracks then
			ChopAnimation.SetMode(tracks, "None")
		end
	end

	function Dummy.SteppedUpdate(self: ChopDummy, _dt: number)
		local tracks = self.Tracks
		if not tracks then
			return
		end
		ChopAnimation.SetMode(tracks, ChopAnimation.LoopMode(os.clock() + self.Offset))
		ChopAnimation.HoldStrikeEnd(tracks)
	end

	return Dummy
end
