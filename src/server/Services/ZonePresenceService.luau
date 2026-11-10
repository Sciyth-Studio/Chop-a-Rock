--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local RockSpawnConfig = require(ReplicatedStorage.Config.RockSpawnConfig)
local ZoneBannerConfig = require(ReplicatedStorage.Config.ZoneBannerConfig)

local ZonePresenceService = { Name = "ZonePresenceService" }

local zones: { [Player]: string } = {}
local loop: thread? = nil
local removing: RBXScriptConnection? = nil

local function zoneAt(position: Vector3): string
	for _, area in CollectionService:GetTagged(RockSpawnConfig.AreaTag) do
		if not area:IsA("BasePart") or not area:IsDescendantOf(workspace) then
			continue
		end
		local relative = area.CFrame:PointToObjectSpace(position)
		if math.abs(relative.Z) <= area.Size.Z / 2 then
			local zone = area:GetAttribute(RockSpawnConfig.ZoneAttribute)
			if type(zone) == "string" then
				return zone
			end
		end
	end
	return ""
end

local function check(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local zone = zoneAt(root.Position)
	if zones[player] == zone then
		return
	end
	zones[player] = zone
	if ZoneBannerConfig.Zones[zone] then
		Packets.ZoneEntered:FireClient(player, zone)
	end
end

function ZonePresenceService.GetZone(_self: any, player: Player): string?
	local zone = zones[player]
	return if zone and zone ~= "" then zone else nil
end

function ZonePresenceService.Init(_self: any, _registry: { [string]: any }) end

function ZonePresenceService.Start(_self: any)
	removing = Players.PlayerRemoving:Connect(function(player: Player)
		zones[player] = nil
	end)
	loop = task.spawn(function()
		while true do
			task.wait(ZoneBannerConfig.PollSeconds)
			for _, player in Players:GetPlayers() do
				check(player)
			end
		end
	end)
end

function ZonePresenceService.Destroy(_self: any)
	if loop then
		task.cancel(loop)
		loop = nil
	end
	if removing then
		removing:Disconnect()
		removing = nil
	end
	table.clear(zones)
end

return ZonePresenceService
