--!strict

local Week = {}

local mondayEpoch = 345600
local weekSeconds = 604800

function Week.Current(now: number?, offset: number?): number
	return math.floor(((now or os.time()) - mondayEpoch) / weekSeconds) + (offset or 0)
end

function Week.EndsAt(week: number, offset: number?): number
	return mondayEpoch + (week - (offset or 0) + 1) * weekSeconds
end

return Week
