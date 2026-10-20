--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local ReplicaServer = require(ServerScriptService.ReplicaServer)
local Signal = require(ReplicatedStorage.Packages.Signal)
local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local DataSessions = require(script.Parent.Parent.Data.DataSessions)
local Tutorial = require(ReplicatedStorage.Tutorial)

type Path = { string | number }

local DataService = {
	Name = "DataService",
	PlayerLoaded = Signal.new() :: Signal.Signal<(Player, PlayerData.Data)>,
	PlayerReleasing = Signal.new() :: Signal.Signal<(Player, PlayerData.Data)>,
}
local sessions: DataSessions.DataSessions? = nil
local profileStore: any = nil
local token: any = nil
local replicas: { [Player]: ReplicaServer.Replica } = {}
local connections: { { Disconnect: (self: any) -> () } } = {}
local stopped = false
local warnedMock = false

function DataService.Init(_self: any, _services: { [string]: any })
	local storeName = if RunService:IsStudio() then "PlayerData_Studio" else "PlayerData"
	local store = ProfileStore.New(storeName, PlayerData.Template)
	profileStore = store
	sessions = DataSessions.new(store :: any, function(player)
		return player.Parent == Players
	end)
	token = ReplicaServer.Token("PlayerData")
end

local function removeReplica(player: Player)
	local replica = replicas[player]
	replicas[player] = nil
	if replica then
		replica:Destroy()
	end
end

local function load(player: Player)
	while ProfileStore.DataStoreState == "NotReady" and not stopped and player.Parent == Players do
		task.wait()
	end
	if stopped or player.Parent ~= Players then
		return
	end
	if ProfileStore.DataStoreState ~= "Access" and not warnedMock then
		warnedMock = true
		warn(
			`[DataService] DataStores unavailable ({ProfileStore.DataStoreState}); using mock data that resets when Play stops. Enable Studio Access to API Services to test saving.`
		)
	end
	local activeSessions = sessions
	if not activeSessions then
		return
	end
	activeSessions:Load(player)
	local data = activeSessions:GetData(player)
	if not data then
		return
	end
	local replica = ReplicaServer.New({
		Token = token,
		Tags = { Player = player },
		Data = data :: any,
	})
	replicas[player] = replica
	if ReplicaServer.ReadyPlayers[player] then
		replica:Subscribe(player)
	end
	DataService.PlayerLoaded:Fire(player, data)
end

function DataService.GetData(_self: any, player: Player): PlayerData.Data?
	local activeSessions = sessions
	return if activeSessions then activeSessions:GetData(player) else nil
end

function DataService.GetReplica(_self: any, player: Player): ReplicaServer.Replica?
	return if DataService:GetData(player) then replicas[player] else nil
end

function DataService.Set(_self: any, player: Player, path: Path, value: any): boolean
	local replica = DataService:GetReplica(player)
	if not replica then
		return false
	end
	if type(value) ~= "table" then
		local parent: any = replica.Data
		for index = 1, #path - 1 do
			parent = if type(parent) == "table" then parent[path[index]] else nil
		end
		if type(parent) == "table" and parent[path[#path]] == value then
			return true
		end
	end
	replica:Set(path :: any, value)
	return true
end

function DataService.Start(_self: any)
	table.insert(connections, Players.PlayerAdded:Connect(load))
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			local activeSessions = sessions
			if not activeSessions then
				return
			end
			local data = activeSessions:GetData(player)
			if data then
				DataService.PlayerReleasing:Fire(player, data)
			end
			activeSessions:Release(player)
			removeReplica(player)
		end)
	)
	table.insert(
		connections,
		ReplicaServer.NewReadyPlayer:Connect(function(player: Player)
			local replica = replicas[player]
			if replica then
				replica:Subscribe(player)
			end
		end)
	)
	for _, player in Players:GetPlayers() do
		task.defer(load, player)
	end
end

function DataService.RequestSave(_self: any, player: Player): boolean
	local activeSessions = sessions
	return if activeSessions then activeSessions:RequestSave(player) else false
end

function DataService.WaitForSave(_self: any, player: Player, saved: (any) -> boolean): boolean
	local activeSessions = sessions
	return if activeSessions then activeSessions:WaitForSave(player, saved) else false
end

function DataService.AdjustCash(_self: any, player: Player, amount: number): boolean
	if amount ~= amount or math.abs(amount) == math.huge or amount % 1 ~= 0 then
		return false
	end
	local data = DataService:GetData(player)
	if not data then
		return false
	end
	local nextBalance = data.Cash + amount
	if nextBalance < 0 or nextBalance > 9007199254740991 then
		return false
	end
	if not DataService:Set(player, { "Cash" }, nextBalance) then
		return false
	end
	return DataService:RequestSave(player)
end

local function resetValues(overrides: { [string]: any }?): { [string]: any }
	local template = PlayerData.Template
	local values: { [string]: any } = {
		Cash = template.Cash,
		Strength = template.Strength,
		AuraTier = template.AuraTier,
		TrainingTier = template.TrainingTier,
		Rebirths = template.Rebirths,
		Geodes = {},
		Pets = {},
		NextPetId = template.NextPetId,
		PedestalSlots = template.PedestalSlots,
		PedestalEarnings = {},
		Index = { Pets = {}, Rocks = {}, Claimed = { Pets = {}, Rocks = {}, Zones = {} } },
		Tutorial = Tutorial.NewState(),
	}
	if overrides then
		for key, value in overrides do
			values[key] = value
		end
	end
	return values
end

function DataService.ResetData(_self: any, player: Player, overrides: { [string]: any }?): boolean
	local data = DataService:GetData(player)
	local replica = DataService:GetReplica(player)
	if not data or not replica then
		return false
	end
	replica:SetValues({}, resetValues(overrides))
	table.clear(data.Receipts)
	DataService.PlayerLoaded:Fire(player, data)
	DataService:RequestSave(player)
	return true
end

function DataService.ResetOfflineData(_self: any, userId: number): (boolean, string)
	if not profileStore or stopped then
		return false, "data store not ready"
	end
	if Players:GetPlayerByUserId(userId) then
		return false, "that player is in this server"
	end
	local key = `Player_{userId}`
	local found, existing = pcall(function()
		return profileStore:GetAsync(key)
	end)
	if not found then
		return false, `could not read the save: {existing}`
	end
	if existing == nil then
		return false, `no save for UserId {userId}`
	end
	local ok, result = pcall(function()
		return profileStore:StartSessionAsync(key, {
			Cancel = function()
				return stopped or Players:GetPlayerByUserId(userId) ~= nil
			end,
		})
	end)
	if not ok or result == nil then
		return false, if ok then "the save is busy, try again" else `could not open the save: {result}`
	end
	local profile = result
	if not PlayerData.Validate(profile.Data) then
		profile:EndSession()
		return false, "the save is invalid, left unchanged"
	end
	PlayerData.Migrate(profile.Data)
	profile:Reconcile()
	for field, value in resetValues(nil) do
		profile.Data[field] = value
	end
	table.clear(profile.Data.Receipts)
	profile:EndSession()
	return true, "reset"
end

function DataService.Destroy(_self: any)
	stopped = true
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	local activeSessions = sessions
	if activeSessions then
		for _, player in Players:GetPlayers() do
			local data = activeSessions:GetData(player)
			if data then
				DataService.PlayerReleasing:Fire(player, data)
			end
		end
		activeSessions:Destroy()
	end
	for player in replicas do
		removeReplica(player)
	end
end

return DataService
