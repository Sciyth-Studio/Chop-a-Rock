--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local Packets = require(ReplicatedStorage.Packets)
local Signal = require(ReplicatedStorage.Packages.Signal)
local TeleportConfig = require(ReplicatedStorage.Config.TeleportConfig)
local Trigger = require(script.Trigger)
local Trove = require(ReplicatedStorage.Packages.Trove)

type Window = {
	Key: string,
	ExpiresAt: number,
}

local CannonService = {
	Name = "CannonService",
	Landed = Signal.new() :: Signal.Signal<Player, string>,
}

local trove = Trove.new()
local services: { [string]: any } = {}
local cannons: { [string]: CannonConfig.Cannon } = {}
local flights: { [Player]: thread } = {}
local lastLaunch: { [Player]: number } = {}
local windows: { [Player]: Window } = {}
local wasInForest: { [Player]: boolean } = {}
local regions: Trigger.Regions = {}

local function findMarker(cannon: CannonConfig.Cannon): BasePart?
	local folder = workspace:FindFirstChild(TeleportConfig.PointsFolderName)
	local marker = if folder then folder:FindFirstChild(cannon.Marker) else nil
	return if marker and marker:IsA("BasePart") then marker else nil
end

local function findLobbyCannon(): Model?
	local model = workspace:FindFirstChild(CannonConfig.CannonName)
	return if model and model:IsA("Model") then model else nil
end

local function muzzlePosition(model: Model): Vector3
	local muzzle = model:FindFirstChild(CannonConfig.MuzzleName, true)
	if muzzle and muzzle:IsA("Attachment") then
		return muzzle.WorldPosition
	elseif muzzle and muzzle:IsA("BasePart") then
		return muzzle.Position
	end
	return model:GetPivot().Position + Vector3.new(0, CannonConfig.MuzzleFallbackHeightStuds, 0)
end

local function equippedKey(data: any): string?
	local key = data.EquippedCannon
	if type(key) == "string" and cannons[key] and data.Cannons[key] then
		return key
	end
	return nil
end

local function isInForest(position: Vector3): boolean
	return Trigger.Contains(regions.Entry, position) or Trigger.Contains(regions.Area, position)
end

local function closeWindow(player: Player)
	if not windows[player] then
		return
	end
	windows[player] = nil
	Packets.CannonWindow:FireClient(player, "", 0)
end

local function openWindow(player: Player)
	local data = services.DataService:GetData(player)
	local key = if data then equippedKey(data) else nil
	if not key then
		return
	end
	windows[player] = { Key = key, ExpiresAt = os.clock() + CannonConfig.Trigger.WindowSeconds }
	Packets.CannonWindow:FireClient(player, key, CannonConfig.Trigger.WindowSeconds)
end

local function sample(player: Player)
	if flights[player] then
		return
	end
	local position = Trigger.RootPosition(player)
	if not position then
		return
	end
	local window = windows[player]
	if window and os.clock() > window.ExpiresAt + CannonConfig.Trigger.GraceSeconds then
		windows[player] = nil
	end
	local inForest = isInForest(position)
	local previous = wasInForest[player]
	wasInForest[player] = inForest
	if not inForest then
		closeWindow(player)
	elseif previous == false and Trigger.Contains(regions.Entry, position) then
		openWindow(player)
	end
end

local function launch(player: Player, key: string): boolean
	local data = services.DataService:GetData(player)
	local cannon = cannons[key]
	if not data or flights[player] or not cannon or not data.Cannons[key] then
		return false
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false
	end
	if services.GeodeService:IsRevealing(player) then
		return false
	end
	local now = os.clock()
	local last = lastLaunch[player]
	if last and now - last < CannonConfig.CooldownSeconds then
		return false
	end
	local model = findLobbyCannon()
	local marker = findMarker(cannon)
	if not model or not marker then
		warn(`[CannonService] Missing lobby cannon or marker {cannon.Marker}`)
		return false
	end
	lastLaunch[player] = now
	services.TeleportService:EndActivities(player)
	local height = marker.Size.Y / 2 + humanoid.HipHeight + root.Size.Y / 2
	local destination = marker.CFrame * CFrame.new(0, height, 0)
	local start = muzzlePosition(model)
	local arcHeight = math.max(
		CannonConfig.MinArcHeightStuds,
		(destination.Position - start).Magnitude * CannonConfig.ArcHeightRatio
	)
	task.spawn(function()
		local streamed, streamError = pcall(function()
			player:RequestStreamAroundAsync(destination.Position, CannonConfig.StreamTimeoutSeconds)
		end)
		if not streamed then
			warn(`[CannonService] Stream request failed: {streamError}`)
		end
	end)
	Packets.CannonLaunch:FireAllClients(
		player,
		cannon.Key,
		start,
		destination.Position,
		arcHeight,
		CannonConfig.ChargeSeconds,
		CannonConfig.FlightSeconds
	)
	flights[player] = task.delay(CannonConfig.ChargeSeconds + CannonConfig.FlightSeconds, function()
		flights[player] = nil
		if player.Character ~= character or humanoid.Health <= 0 or not character.Parent then
			return
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		character:PivotTo(destination)
		wasInForest[player] = isInForest(destination.Position)
		CannonService.Landed:Fire(player, cannon.Key)
	end)
	return true
end

function CannonService.Find(_self: any, key: string): CannonConfig.Cannon?
	return cannons[key]
end

function CannonService.IsLaunching(_self: any, player: Player): boolean
	return flights[player] ~= nil
end

function CannonService.UnlockReached(_self: any, player: Player)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	local newest: string? = nil
	for _, cannon in CannonConfig.Cannons do
		if not data.Cannons[cannon.Key] and data.PeakStrength >= cannon.StrengthRequired then
			services.DataService:Set(player, { "Cannons", cannon.Key }, true)
			services.NotificationService:Notify(player, "Unlock", `{cannon.DisplayName} unlocked!`)
			newest = cannon.Key
		end
	end
	if newest then
		CannonService:Equip(player, newest)
		services.DataService:RequestSave(player)
	end
end

function CannonService.Equip(_self: any, player: Player, key: string): boolean
	local data = services.DataService:GetData(player)
	if not data or (key ~= "" and (not cannons[key] or not data.Cannons[key])) then
		return false
	end
	local window = windows[player]
	if window and window.Key ~= key then
		closeWindow(player)
	end
	services.DataService:Set(player, { "EquippedCannon" }, key)
	return true
end

function CannonService.Fire(_self: any, player: Player): boolean
	local window = windows[player]
	local data = services.DataService:GetData(player)
	local position = Trigger.RootPosition(player)
	if not window or not data or not position then
		return false
	end
	if os.clock() > window.ExpiresAt + CannonConfig.Trigger.GraceSeconds then
		windows[player] = nil
		return false
	end
	if equippedKey(data) ~= window.Key or not isInForest(position) then
		return false
	end
	if not launch(player, window.Key) then
		return false
	end
	windows[player] = nil
	return true
end

function CannonService.SetOwned(_self: any, player: Player, owned: boolean): boolean
	if not services.DataService:GetData(player) then
		return false
	end
	local flags = {}
	if owned then
		for key in cannons do
			flags[key] = true
		end
	end
	closeWindow(player)
	services.DataService:Set(player, { "Cannons" }, flags)
	services.DataService:Set(player, { "EquippedCannon" }, "")
	services.DataService:RequestSave(player)
	return true
end

function CannonService.Init(_self: any, registry: { [string]: any })
	services = registry
	for _, cannon in CannonConfig.Cannons do
		cannons[cannon.Key] = cannon
	end
end

function CannonService.Start(_self: any)
	regions = Trigger.Find()
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		local flight = flights[player]
		if flight then
			task.cancel(flight)
		end
		flights[player] = nil
		lastLaunch[player] = nil
		windows[player] = nil
		wasInForest[player] = nil
	end)
	Packets.EquipCannon.OnServerInvoke = function(player: Player, key: string): boolean
		return CannonService:Equip(player, key)
	end
	Packets.FireCannon.OnServerInvoke = function(player: Player): boolean
		return CannonService:Fire(player)
	end
	local hasRegions = regions.Entry ~= nil and regions.Area ~= nil
	trove:Add(task.spawn(function()
		while true do
			task.wait(CannonConfig.Trigger.CheckSeconds)
			for _, player in Players:GetPlayers() do
				if services.DataService:GetData(player) then
					CannonService:UnlockReached(player)
					if hasRegions then
						sample(player)
					end
				end
			end
		end
	end))
end

function CannonService.Destroy(_self: any)
	Packets.EquipCannon.OnServerInvoke = nil
	Packets.FireCannon.OnServerInvoke = nil
	for _, flight in flights do
		task.cancel(flight)
	end
	table.clear(flights)
	table.clear(lastLaunch)
	table.clear(windows)
	table.clear(wasInForest)
	trove:Clean()
end

return CannonService
