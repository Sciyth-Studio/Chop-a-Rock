--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local TeleportConfig = require(ReplicatedStorage.Config.TeleportConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local TeleportService = { Name = "TeleportService" }

local trove = Trove.new()
local services: { [string]: any } = {}
local destinations: { [string]: TeleportConfig.Destination } = {}
local lastTeleport: { [Player]: number } = {}

local function findTarget(player: Player, destination: TeleportConfig.Destination): BasePart?
	if destination.IsBase then
		return services.BaseService:GetSpawn(player)
	end
	local folder = workspace:FindFirstChild(TeleportConfig.PointsFolderName)
	local marker = if folder then folder:FindFirstChild(destination.Marker) else nil
	return if marker and marker:IsA("BasePart") then marker else nil
end

local function endActivities(player: Player)
	services.RockService:EndSession(player)
	services.DiamondRockService:EndSession(player)
	services.GeodeFallService:EndSession(player)
	services.GeodeService:EndSession(player)
	services.TrainingService:Stop(player)
	Packets.ChopEnded:FireClient(player)
end

local function notify(player: Player, message: string)
	services.NotificationService:Notify(player, "Info", message)
end

local function onTeleport(player: Player, destinationId: string)
	local destination = destinations[destinationId]
	if not destination or not services.DataService:GetData(player) then
		return
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end
	if services.GeodeService:IsRevealing(player) then
		notify(player, TeleportConfig.RevealingMessage)
		return
	end
	if services.CannonService:IsLaunching(player) then
		return
	end
	local now = os.clock()
	local last = lastTeleport[player]
	if last and now - last < TeleportConfig.CooldownSeconds then
		return
	end
	local target = findTarget(player, destination)
	if not target then
		warn(`[TeleportService] No target for destination {destination.Id}`)
		return
	end
	lastTeleport[player] = now
	endActivities(player)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	local height = target.Size.Y / 2 + humanoid.HipHeight + root.Size.Y / 2
	local destinationCFrame = target.CFrame * CFrame.new(0, height, 0)
	task.spawn(function()
		local streamed, streamError = pcall(function()
			player:RequestStreamAroundAsync(destinationCFrame.Position, TeleportConfig.StreamTimeoutSeconds)
		end)
		if not streamed then
			warn(`[TeleportService] Stream request failed: {streamError}`)
		end
	end)
	services.GeodeFallService:AllowMove(player)
	character:PivotTo(destinationCFrame)
end

function TeleportService.EndActivities(_self: any, player: Player)
	endActivities(player)
end

function TeleportService.Init(_self: any, registry: { [string]: any })
	services = registry
	for _, destination in TeleportConfig.Destinations do
		destinations[destination.Id] = destination
	end
end

function TeleportService.Start(_self: any)
	trove:Add(Packets.Teleport.OnServerEvent:Connect(onTeleport))
	trove:Add(Players.PlayerRemoving:Connect(function(player: Player)
		lastTeleport[player] = nil
	end))
end

function TeleportService.Destroy(_self: any)
	trove:Clean()
	table.clear(lastTeleport)
	table.clear(destinations)
end

return TeleportService
