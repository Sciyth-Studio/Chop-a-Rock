--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local UserService = game:GetService("UserService")
local LeaderboardConfig = require(ReplicatedStorage.Config.LeaderboardConfig)
local ReplicaServer = require(ServerScriptService.ReplicaServer)
local Statues = require(script.Statues)
local Stores = require(script.Stores)

type Row = {
	UserId: number,
	Name: string,
	Value: number,
}

type Standing = {
	Rank: number,
	Value: number,
}

local LeaderboardService = { Name = "LeaderboardService" }

local services: { [string]: any } = {}
local replica: ReplicaServer.Replica? = nil
local loop: thread? = nil
local names: { [number]: string } = {}
local written: { [Player]: { [string]: number } } = {}
local countedAt: { [Player]: number } = {}

local function readValue(player: Player, key: string): number
	local data = services.DataService:GetData(player)
	if not data then
		return 0
	end
	if key == "Strength" then
		return data.Strength
	elseif key == "MoneyPerSecond" then
		return services.PedestalService:GetIncomeRate(player)
	elseif key == "PerfectChops" then
		return data.PerfectChops
	elseif key == "Playtime" then
		return data.Playtime
	end
	return 0
end

local function countPlaytime(player: Player)
	local data = services.DataService:GetData(player)
	local since = countedAt[player]
	if not data or not since then
		return
	end
	local seconds = math.floor(os.clock() - since)
	if seconds <= 0 then
		return
	end
	countedAt[player] = since + seconds
	services.DataService:Set(player, { "Playtime" }, data.Playtime + seconds)
end

local function writePlayer(player: Player)
	local cache = written[player]
	if not cache then
		return
	end
	for _, board in LeaderboardConfig.Boards do
		local encoded = Stores.Encode(readValue(player, board.Key))
		if cache[board.Key] ~= encoded and Stores.Write(board.Key, player.UserId, encoded) then
			cache[board.Key] = encoded
		end
	end
end

local function resolveNames(userIds: { number })
	local missing = {}
	for _, userId in userIds do
		if not names[userId] then
			local player = Players:GetPlayerByUserId(userId)
			if player then
				names[userId] = player.Name
			else
				table.insert(missing, userId)
			end
		end
	end
	if #missing == 0 then
		return
	end
	local ok, infos = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync(missing)
	end)
	if ok then
		for _, info in infos do
			names[info.Id] = info.Username
		end
	end
end

local function localEntries(key: string): { Stores.Entry }
	local entries: { Stores.Entry } = {}
	for player in written do
		table.insert(entries, { UserId = player.UserId, Value = readValue(player, key) })
	end
	table.sort(entries, function(a, b)
		return a.Value > b.Value
	end)
	return entries
end

local function refresh()
	for player in written do
		countPlaytime(player)
		writePlayer(player)
	end
	local boards: { [string]: { Row } } = {}
	local standings: { [string]: { [string]: Standing } } = {}
	for player in written do
		standings[tostring(player.UserId)] = {}
	end
	for _, board in LeaderboardConfig.Boards do
		local entries = Stores.ReadTop(board.Key, LeaderboardConfig.RankLimit) or localEntries(board.Key)
		local ranks: { [number]: number } = {}
		local topIds = {}
		for rank, entry in entries do
			ranks[entry.UserId] = rank
			if rank <= LeaderboardConfig.Rows then
				table.insert(topIds, entry.UserId)
			end
		end
		resolveNames(topIds)
		local rows: { Row } = {}
		for rank = 1, math.min(#entries, LeaderboardConfig.Rows) do
			local entry = entries[rank]
			table.insert(rows, {
				UserId = entry.UserId,
				Name = names[entry.UserId] or tostring(entry.UserId),
				Value = entry.Value,
			})
		end
		boards[board.Key] = rows
		for player in written do
			local standing = standings[tostring(player.UserId)]
			if standing then
				standing[board.Key] = {
					Rank = ranks[player.UserId] or 0,
					Value = readValue(player, board.Key),
				}
			end
		end
		for _, boardModel in Statues.Boards(board.Key) do
			task.spawn(Statues.Show, boardModel, if rows[1] then rows[1].UserId else nil)
		end
	end
	local current = replica
	if current then
		current:Set({ "Boards" }, boards)
		current:Set({ "Standings" }, standings)
	end
end

local function onLoaded(player: Player)
	written[player] = {}
	countedAt[player] = os.clock()
end

local function onReleasing(player: Player, data: any)
	local since = countedAt[player]
	if since then
		data.Playtime += math.floor(os.clock() - since)
	end
	countedAt[player] = nil
	local cache = written[player]
	written[player] = nil
	if not cache then
		return
	end
	local userId = player.UserId
	local finals: { [string]: number } = {}
	for _, board in LeaderboardConfig.Boards do
		if board.Key == "Playtime" then
			finals[board.Key] = Stores.Encode(data.Playtime)
		elseif board.Key ~= "MoneyPerSecond" then
			finals[board.Key] = Stores.Encode(data[board.Key])
		end
	end
	task.spawn(function()
		for key, encoded in finals do
			if cache[key] ~= encoded then
				Stores.Write(key, userId, encoded)
			end
		end
	end)
end

function LeaderboardService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function LeaderboardService.Start(_self: any)
	local newReplica = ReplicaServer.New({
		Token = ReplicaServer.Token("Leaderboards"),
		Data = { Boards = {}, Standings = {} },
	})
	newReplica:Replicate()
	replica = newReplica
	services.DataService.PlayerLoaded:Connect(onLoaded)
	services.DataService.PlayerReleasing:Connect(onReleasing)
	loop = task.spawn(function()
		task.wait(LeaderboardConfig.FirstRefreshDelaySeconds)
		while true do
			refresh()
			task.wait(LeaderboardConfig.RefreshSeconds)
		end
	end)
end

function LeaderboardService.Destroy(_self: any)
	if loop and coroutine.status(loop) ~= "dead" then
		task.cancel(loop)
	end
	loop = nil
end

return LeaderboardService
