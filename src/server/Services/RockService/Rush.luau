--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockConfig = require(ReplicatedStorage.Config.RockConfig)
local RushRockConfig = require(ReplicatedStorage.Config.RushRockConfig)
local Types = require(script.Parent.Types)

local Rush = {}

function Rush.New(): Types.RushState
	return { ChopSeconds = 0, LastChopAt = nil, ActiveId = nil, IsScheduled = false }
end

function Rush.RecordChop(state: Types.RushState, now: number)
	local last = state.LastChopAt
	state.LastChopAt = now
	if not last or state.ActiveId or state.IsScheduled then
		return
	end
	local gap = now - last
	if gap <= RushRockConfig.ActiveWindowSeconds then
		state.ChopSeconds += gap
	end
end

function Rush.IsDue(state: Types.RushState): boolean
	return state.ChopSeconds >= RushRockConfig.IntervalSeconds
		and not state.ActiveId
		and not state.IsScheduled
end

function Rush.Started(state: Types.RushState, id: number)
	state.ActiveId = id
	state.ChopSeconds = 0
	state.IsScheduled = false
end

function Rush.PickKey(
	weights: { [string]: number },
	shapes: { [string]: Types.Shape },
	strength: number,
	mixKey: string?
): string?
	local configs: { [string]: RockConfig.Rock } = RockConfig.Rocks
	local mixConfig = if mixKey then configs[mixKey] else nil
	if mixKey and mixConfig and mixConfig.StrengthRequired <= strength then
		return mixKey
	end
	local bestKey: string? = nil
	local bestRequired = -math.huge
	for key, weight in weights do
		local config = configs[key]
		if
			weight > 0
			and config
			and shapes[key]
			and config.StrengthRequired <= strength
			and config.StrengthRequired > bestRequired
		then
			bestKey = key
			bestRequired = config.StrengthRequired
		end
	end
	return bestKey
end

function Rush.ApplyPayout(rock: Types.Rock, payout: number): number
	if rock.Modifier ~= RushRockConfig.Modifier then
		return payout
	end
	return math.floor(payout * RushRockConfig.PayoutMultiplier + 0.5)
end

return Rush
