--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LeaderboardConfig = require(ReplicatedStorage.Config.LeaderboardConfig)

export type Candidate = {
	Name: string,
	Rank: number?,
}

type Pending = {
	Key: string,
	Passed: { Candidate },
	Rank: number?,
}

local Passes = {}

local pairAt: { [string]: number } = {}
local toastAt: { [Player]: number } = {}
local ahead: { [string]: { [string]: boolean } } = {}

local function label(key: string): string
	for _, board in LeaderboardConfig.Boards do
		if board.Key == key then
			return (string.gsub(board.Title, "^Top ", ""))
		end
	end
	return key
end

local function pairKey(key: string, winner: number, loser: number): string
	return `{key}:{winner}:{loser}`
end

local function claimPair(key: string, winner: number, loser: number): boolean
	local id = pairKey(key, winner, loser)
	local now = os.clock()
	local last = pairAt[id]
	if last and now - last < LeaderboardConfig.PairCooldownSeconds then
		return false
	end
	pairAt[id] = now
	return true
end

local function message(pending: Pending): string
	local where = label(pending.Key)
	local passed = pending.Passed
	if #passed == 0 then
		return `You're #{pending.Rank} in {where}!`
	end
	local who = passed[1].Name
	if #passed > 1 then
		who = `{who} and {#passed - 1} more`
	end
	if pending.Rank then
		return `You passed {who}! You're #{pending.Rank} in {where}`
	end
	return `You passed {who} in {where}!`
end

local function deliver(player: Player, pending: Pending, notify: (Player, string) -> ())
	local now = os.clock()
	local last = toastAt[player]
	if last and now - last < LeaderboardConfig.ToastCooldownSeconds then
		return
	end
	toastAt[player] = now
	notify(player, message(pending))
end

function Passes.CheckServer(key: string, values: { [Player]: number }, notify: (Player, string) -> ())
	local states = ahead[key]
	if not states then
		states = {}
		ahead[key] = states
	end
	local margin = 1 + LeaderboardConfig.PassMargin
	local found: { [Player]: { { Player: Player, Value: number } } } = {}
	for player, value in values do
		for other, otherValue in values do
			if player ~= other then
				local id = `{player.UserId}:{other.UserId}`
				local was = states[id]
				local now = was
				if value > otherValue * margin and value > 0 then
					now = true
				elseif otherValue > value * margin then
					now = false
				elseif was == nil then
					now = value >= otherValue
				end
				states[id] = now
				if was == false and now == true and otherValue > 0 then
					local list = found[player] or {}
					found[player] = list
					table.insert(list, { Player = other, Value = otherValue })
				end
			end
		end
	end
	for player, list in found do
		table.sort(list, function(a, b)
			return a.Value > b.Value
		end)
		local passed: { Candidate } = {}
		for _, entry in list do
			if claimPair(key, player.UserId, entry.Player.UserId) then
				table.insert(passed, { Name = entry.Player.Name })
			end
		end
		if #passed > 0 then
			deliver(player, { Key = key, Passed = passed, Rank = nil }, notify)
		end
	end
end

function Passes.CheckGlobal(
	key: string,
	before: { [number]: number },
	after: { [number]: number },
	players: { Player },
	names: ({ number }) -> { [number]: string },
	notify: (Player, string) -> ()
)
	for _, player in players do
		local userId = player.UserId
		local rank = after[userId]
		if rank then
			local old = before[userId]
			local passedIds: { number } = {}
			for otherId, otherOld in before do
				local otherNew = after[otherId]
				if otherId ~= userId and otherNew and otherNew > rank and (old == nil or otherOld < old) then
					table.insert(passedIds, otherId)
				end
			end
			table.sort(passedIds, function(a, b)
				return after[a] < after[b]
			end)
			local claimed: { number } = {}
			for _, otherId in passedIds do
				if claimPair(key, userId, otherId) then
					table.insert(claimed, otherId)
				end
			end
			if #claimed > 0 then
				local resolved = names({ claimed[1] })
				local passed: { Candidate } = {}
				for _, otherId in claimed do
					table.insert(
						passed,
						{ Name = resolved[otherId] or tostring(otherId), Rank = after[otherId] }
					)
				end
				deliver(player, { Key = key, Passed = passed, Rank = rank }, notify)
			elseif old == nil and #passedIds == 0 then
				deliver(player, { Key = key, Passed = {}, Rank = rank }, notify)
			end
		end
	end
end

function Passes.Forget(player: Player)
	toastAt[player] = nil
	local prefix = `{player.UserId}:`
	local suffix = `:{player.UserId}`
	for _, states in ahead do
		for id in states do
			if string.sub(id, 1, #prefix) == prefix or string.sub(id, -#suffix) == suffix then
				states[id] = nil
			end
		end
	end
end

return Passes
