--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WalkSpeedConfig = require(ReplicatedStorage.Config.WalkSpeedConfig)

local WalkSpeedTarget = {}

function WalkSpeedTarget.Get(player: Player): number?
	local value = player:GetAttribute(WalkSpeedConfig.TargetAttribute)
	return if type(value) == "number" then value else nil
end

return WalkSpeedTarget
