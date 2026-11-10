--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseUpgradeConfig = require(ReplicatedStorage.Config.BaseUpgradeConfig)

local BaseLevels = {}

function BaseLevels.Max(): number
	return #BaseUpgradeConfig.Levels
end

function BaseLevels.Clamp(level: any): number
	local value = if type(level) == "number" then math.floor(level) else 1
	return math.clamp(value, 1, BaseLevels.Max())
end

function BaseLevels.Get(level: any): BaseUpgradeConfig.Level
	return BaseUpgradeConfig.Levels[BaseLevels.Clamp(level)]
end

function BaseLevels.Next(level: any): BaseUpgradeConfig.Level?
	return BaseUpgradeConfig.Levels[BaseLevels.Clamp(level) + 1]
end

function BaseLevels.HatchMultiplier(level: any): number
	return BaseLevels.Get(level).HatchMultiplier
end

return BaseLevels
