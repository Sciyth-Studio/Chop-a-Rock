--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopPose = require(ReplicatedStorage.Utils.ChopPose)
local Component = require(ReplicatedStorage.Packages.Component)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)

type ChopDummy = {
	Instance: Instance,
	Rig: ChopPose.Rig?,
	Root: Motor6D?,
	State: ChopPose.State,
	Offset: number,
}

return function(_controllers: { [string]: any })
	local Dummy = Component.new({ Tag = "ChopDummy" }) :: any

	function Dummy.Construct(self: ChopDummy)
		self.State = ChopPose.NewState()
		self.Offset = math.random() * TrainingConfig.ChopIntervalSeconds
	end

	function Dummy.Start(self: ChopDummy)
		local model = self.Instance
		if not model:IsA("Model") then
			return
		end
		self.Rig = ChopPose.Build(model, 10)
		local lowerTorso = model:FindFirstChild("LowerTorso")
		local root = if lowerTorso then lowerTorso:FindFirstChild("Root") else nil
		self.Root = if root and root:IsA("Motor6D") then root else nil
	end

	function Dummy.SteppedUpdate(self: ChopDummy, dt: number)
		local rig = self.Rig
		if not rig then
			return
		end
		ChopPose.Step(self.State, ChopPose.LoopTargets(os.clock() + self.Offset), dt)
		local drop = ChopPose.Apply(rig, self.State)
		if self.Root then
			self.Root.Transform = CFrame.new(0, -drop, 0)
		end
	end

	return Dummy
end
