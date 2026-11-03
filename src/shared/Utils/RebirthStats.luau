--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RebirthConfig = require(ReplicatedStorage.Config.RebirthConfig)

local RebirthStats = {}

function RebirthStats.Get(rebirth: number): RebirthConfig.Rebirth
	local count = math.max(rebirth, 0)
	return {
		StrengthRequired = RebirthConfig.BaseStrengthRequired
			* RebirthConfig.StrengthGrowth ^ (math.max(count, 1) - 1),
		CashMultiplier = RebirthConfig.BaseMultiplier + RebirthConfig.MultiplierPerRebirth * count,
	}
end

return RebirthStats
