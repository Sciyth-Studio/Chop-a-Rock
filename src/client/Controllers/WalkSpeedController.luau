--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MovementLock = require(ReplicatedStorage.Utils.MovementLock)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WalkSpeedConfig = require(ReplicatedStorage.Config.WalkSpeedConfig)
local WalkSpeedTarget = require(ReplicatedStorage.Utils.WalkSpeedTarget)

type TroveInstance = typeof(Trove.new())

local WalkSpeedController = {
	Name = "WalkSpeedController",
	_trove = nil :: TroveInstance?,
}

local function apply()
	local player = Players.LocalPlayer
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local target = WalkSpeedTarget.Get(player)
	if not humanoid or not target or MovementLock.IsLocked(humanoid) then
		return
	end
	humanoid.WalkSpeed = target
end

function WalkSpeedController.Init(self: any, _controllers: { [string]: any })
	self._trove = Trove.new()
end

function WalkSpeedController.Start(self: any)
	local trove = self._trove :: TroveInstance
	local player = Players.LocalPlayer
	trove:Connect(player:GetAttributeChangedSignal(WalkSpeedConfig.TargetAttribute), apply)
	trove:Connect(player.CharacterAdded, function(character: Model)
		character:WaitForChild("Humanoid", 10)
		apply()
	end)
	apply()
end

function WalkSpeedController.Destroy(self: any)
	if self._trove then
		self._trove:Destroy()
		self._trove = nil
	end
end

return WalkSpeedController
