--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local UserService = game:GetService("UserService")
local LeaderboardConfig = require(ReplicatedStorage.Config.LeaderboardConfig)
local ReplicaServer = require(ServerScriptService.ReplicaServer)
local Tutorial = require(ReplicatedStorage.Tutorial)
local Passes = require(script.Passes)
local Statues = require(script.Statues)
local Stores = require(script.Stores)

type Tab = string

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
local passLoop: thread? = nil
local names: { [number]: string } = {}
local written: { [Player]: { [string]: number } } = {}
local countedAt: { [Player]: number } = {}
local rowsByTab: { [Tab]: { [string]: { Row } } } = { AllTime = {}, Weekly = {} }
local ranksByTab: { [Tab]: { [string]: { [number]: number } } } = { AllTime = {}, Weekly = {} }
local refreshCount = 0
local isRefreshing = false

local function readValue(player: Player, key: string, tab: Tab): number
	local data = services.DataService:GetData(player)
	if not data then
		return 0
	end
	if tab == "Weekly" then
		local weekly = services.StatsService:GetWeekly(player)
		return if weekly then weekly[key] or 0 else 0
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

local function storeName(key: string, tab: Tab): string
	return Stores.Name(key, if tab == "Weekly" then services.StatsService:GetWeek() else nil)
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
	services.StatsService:AddWeekly(player, "Playtime", seconds)
end

local function writePlayer(player: Player)
	local cache = written[player]
	if not cache then
		return
	end
	services.StatsService:RaiseWeekly(
		player,
		"MoneyPerSecond",
		readValue(player, "MoneyPerSecond", "AllTime")
	)
	for _, tab in LeaderboardConfig.Tabs do
		for _, board in LeaderboardConfig.Boards do
			local name = storeName(board.Key, tab)
			local encoded = Stores.Encode(readValue(player, board.Key, tab))
			if cache[name] ~= encoded and Stores.Write(name, player.UserId, encoded) then
				cache[name] = encoded
			end
		end
	end
end

local function resolveNames(userIds: { number }): { [number]: string }
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
	if #missing > 0 then
		local ok, infos = pcall(function()
			return UserService:GetUserInfosByUserIdsAsync(missing)
		end)
		if ok then
			for _, info in infos do
				names[info.Id] = info.Username
			end
		end
	end
	return names
end

local function localEntries(key: string, tab: Tab): { Stores.Entry }
	local entries: { Stores.Entry } = {}
	for player in written do
		table.insert(entries, { UserId = player.UserId, Value = readValue(player, key, tab) })
	end
	table.sort(entries, function(a, b)
		return a.Value > b.Value
	end)
	return entries
end

local function notifyPass(player: Player, text: string)
	services.NotificationService:Notify(player, LeaderboardConfig.PassKind, text)
end

local function ranked(): { Player }
	local players = {}
	for player in written do
		table.insert(players, player)
	end
	return players
end

local function setTitles(globalKeys: { [string]: boolean })
	for player in written do
		local titles = {}
		for _, board in LeaderboardConfig.Boards do
			local rows = rowsByTab.AllTime[board.Key]
			if globalKeys[board.Key] and rows and rows[1] and rows[1].UserId == player.UserId then
				table.insert(titles, board.Key)
			end
		end
		player:SetAttribute(
			LeaderboardConfig.TitlesAttribute,
			if #titles > 0 then table.concat(titles, ",") else nil
		)
	end
end

local function readTab(tab: Tab)
	local globalKeys: { [string]: boolean } = {}
	for _, board in LeaderboardConfig.Boards do
		local fromStore = Stores.ReadTop(storeName(board.Key, tab), LeaderboardConfig.RankLimit)
		local entries = fromStore or localEntries(board.Key, tab)
		globalKeys[board.Key] = fromStore ~= nil
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
		local before = ranksByTab[tab][board.Key]
		rowsByTab[tab][board.Key] = rows
		ranksByTab[tab][board.Key] = ranks
		if tab == "AllTime" then
			if before and fromStore and table.find(LeaderboardConfig.PassBoards, board.Key) then
				Passes.CheckGlobal(board.Key, before, ranks, ranked(), resolveNames, notifyPass)
			end
			for _, boardModel in Statues.Boards(board.Key) do
				task.spawn(Statues.Show, boardModel, if rows[1] then rows[1].UserId else nil)
			end
		end
	end
	if tab == "AllTime" then
		setTitles(globalKeys)
	end
end

local function standingsFor(tab: Tab): { [string]: { [string]: Standing } }
	local standings: { [string]: { [string]: Standing } } = {}
	for player in written do
		local standing = {}
		for _, board in LeaderboardConfig.Boards do
			local ranks = ranksByTab[tab][board.Key]
			standing[board.Key] = {
				Rank = if ranks then ranks[player.UserId] or 0 else 0,
				Value = readValue(player, board.Key, tab),
			}
		end
		standings[tostring(player.UserId)] = standing
	end
	return standings
end

local function refresh(readsAll: boolean)
	if isRefreshing then
		return
	end
	isRefreshing = true
	for player in written do
		countPlaytime(player)
		writePlayer(player)
	end
	if readsAll then
		readTab("AllTime")
		readTab("Weekly")
		refreshCount = 0
	else
		readTab(if refreshCount % 2 == 0 then "AllTime" else "Weekly")
		refreshCount += 1
	end
	local current = replica
	if current then
		current:Set({ "Boards" }, rowsByTab.AllTime)
		current:Set({ "Standings" }, standingsFor("AllTime"))
		current:Set({ "WeeklyBoards" }, rowsByTab.Weekly)
		current:Set({ "WeeklyStandings" }, standingsFor("Weekly"))
		current:Set({ "WeekEndsAt" }, services.StatsService:GetWeekEndsAt())
	end
	isRefreshing = false
end

local function checkPasses()
	for _, key in LeaderboardConfig.PassBoards do
		local values: { [Player]: number } = {}
		for player in written do
			local data = services.DataService:GetData(player)
			if data and Tutorial.StepOf(data.Tutorial) >= Tutorial.Done then
				values[player] = readValue(player, key, "AllTime")
			end
		end
		Passes.CheckServer(key, values, notifyPass)
	end
end

local function onLoaded(player: Player)
	written[player] = {}
	countedAt[player] = os.clock()
	services.StatsService:GetWeekly(player)
end

local function onReleasing(player: Player, data: any)
	local since = countedAt[player]
	local seconds = if since then math.floor(os.clock() - since) else 0
	data.Playtime += seconds
	local week = services.StatsService:GetWeek()
	local weekly = data.Weekly
	if weekly.Week == week then
		weekly.Playtime += seconds
	end
	countedAt[player] = nil
	Passes.Forget(player)
	local cache = written[player]
	written[player] = nil
	if not cache then
		return
	end
	local userId = player.UserId
	local finals: { [string]: number } = {}
	for _, board in LeaderboardConfig.Boards do
		if board.Key ~= "MoneyPerSecond" then
			finals[Stores.Name(board.Key)] = Stores.Encode(data[board.Key])
		end
		if weekly.Week == week then
			finals[Stores.Name(board.Key, week)] = Stores.Encode(weekly[board.Key])
		end
	end
	task.spawn(function()
		for name, encoded in finals do
			if cache[name] ~= encoded then
				Stores.Write(name, userId, encoded)
			end
		end
	end)
end

function LeaderboardService.Refresh(_self: any): boolean
	if isRefreshing then
		return false
	end
	task.spawn(refresh, true)
	return true
end

function LeaderboardService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function LeaderboardService.Start(_self: any)
	local newReplica = ReplicaServer.New({
		Token = ReplicaServer.Token("Leaderboards"),
		Data = {
			Boards = {},
			Standings = {},
			WeeklyBoards = {},
			WeeklyStandings = {},
			WeekEndsAt = services.StatsService:GetWeekEndsAt(),
		},
	})
	newReplica:Replicate()
	replica = newReplica
	services.DataService.PlayerLoaded:Connect(onLoaded)
	services.DataService.PlayerReleasing:Connect(onReleasing)
	loop = task.spawn(function()
		task.wait(LeaderboardConfig.FirstRefreshDelaySeconds)
		refresh(true)
		while true do
			task.wait(LeaderboardConfig.RefreshSeconds)
			refresh(false)
		end
	end)
	passLoop = task.spawn(function()
		while true do
			task.wait(LeaderboardConfig.PassCheckSeconds)
			checkPasses()
		end
	end)
end

function LeaderboardService.Destroy(_self: any)
	for _, thread in { loop, passLoop } do
		if thread and coroutine.status(thread) ~= "dead" then
			task.cancel(thread)
		end
	end
	loop = nil
	passLoop = nil
end

return LeaderboardService
