--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)

local ChopTiming = {}

function ChopTiming.Elapsed(startTime: number, claimed: number): number
	local measured = os.clock() - startTime
	local earliest = math.max(0, measured - ChopConfig.MaxLatencySeconds)
	if claimed ~= claimed then
		return earliest
	end
	return math.clamp(claimed, earliest, math.max(earliest, measured))
end

return ChopTiming
