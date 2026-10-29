--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PlayerListConfig = require(ReplicatedStorage.Config.PlayerListConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PlayerListService = { Name = "PlayerListService" }

local trove = Trove.new()
local services: { [string]: any } = {}
local folders: { [Player]: Folder } = {}
local elapsed = 0

local function amountOf(value: any): number
	return if type(value) == "number" then math.floor(math.max(value, 0)) else 0
end

local function refresh(player: Player)
	local folder = folders[player]
	local data = services.DataService:GetData(player)
	if not folder or not data then
		return
	end
	for _, stat in PlayerListConfig.Stats do
		local value = folder:FindFirstChild(stat.Name)
		if value and value:IsA("NumberValue") then
			local amount = amountOf((data :: any)[stat.Field])
			if value.Value ~= amount then
				value.Value = amount
			end
		end
	end
end

local function add(player: Player)
	if folders[player] or player.Parent ~= Players then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = PlayerListConfig.FolderName
	for _, stat in PlayerListConfig.Stats do
		local value = Instance.new("NumberValue")
		value.Name = stat.Name
		value.Parent = folder
	end
	folders[player] = folder
	refresh(player)
	folder.Parent = player
end

local function remove(player: Player)
	local folder = folders[player]
	folders[player] = nil
	if folder then
		folder:Destroy()
	end
end

function PlayerListService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function PlayerListService.Start(_self: any)
	local dataService = services.DataService
	trove:Connect(dataService.PlayerLoaded, function(player: Player)
		remove(player)
		add(player)
	end)
	trove:Connect(Players.PlayerRemoving, remove)
	for _, player in Players:GetPlayers() do
		if dataService:GetData(player) then
			add(player)
		end
	end
	trove:Connect(RunService.Heartbeat, function(dt: number)
		elapsed += dt
		if elapsed < PlayerListConfig.RefreshSeconds then
			return
		end
		elapsed = 0
		for player in folders do
			refresh(player)
		end
	end)
end

function PlayerListService.Destroy(_self: any)
	trove:Destroy()
	for player in folders do
		remove(player)
	end
end

return PlayerListService
