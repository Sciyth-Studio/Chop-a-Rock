--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local Packets = require(ReplicatedStorage.Packets)
local TeleportConfig = require(ReplicatedStorage.Config.TeleportConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

local CannonService = { Name = "CannonService" }

local trove = Trove.new()
local services: { [string]: any } = {}
local cannons: { [string]: CannonConfig.Cannon } = {}
local flights: { [Player]: thread } = {}
local lastLaunch: { [Player]: number } = {}
local prompt: ProximityPrompt? = nil

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

local function showEmpty(player: Player)
	services.NotificationService:Notify(player, "Info", CannonConfig.EmptyMessage)
	Packets.CannonEmpty:FireClient(player)
end

local function launch(player: Player)
	local data = services.DataService:GetData(player)
	if not data or flights[player] then
		return
	end
	local cannon = cannons[data.EquippedCannon]
	if not cannon or not data.Cannons[cannon.Key] then
		showEmpty(player)
		return
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end
	if services.GeodeService:IsRevealing(player) then
		return
	end
	local now = os.clock()
	local last = lastLaunch[player]
	if last and now - last < CannonConfig.CooldownSeconds then
		return
	end
	local model = findLobbyCannon()
	local marker = findMarker(cannon)
	if not model or not marker then
		warn(`[CannonService] Missing lobby cannon or marker {cannon.Marker}`)
		return
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
	Packets.CannonLaunch:FireClient(
		player,
		start,
		destination.Position,
		arcHeight,
		CannonConfig.FlightSeconds
	)
	flights[player] = task.delay(CannonConfig.FlightSeconds, function()
		flights[player] = nil
		if player.Character ~= character or humanoid.Health <= 0 or not character.Parent then
			return
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		character:PivotTo(destination)
	end)
end

local function setupPrompt(model: Model)
	if prompt and prompt.Parent then
		return
	end
	local anchor = model:FindFirstChild(CannonConfig.PromptAnchorName, true)
	local parent: Instance? = if anchor and (anchor:IsA("Attachment") or anchor:IsA("BasePart"))
		then anchor
		else model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not parent then
		warn(`[CannonService] {model:GetFullName()} has no part for the prompt`)
		return
	end
	local newPrompt = trove:Add(Instance.new("ProximityPrompt"))
	newPrompt.ActionText = CannonConfig.PromptActionText
	newPrompt.ObjectText = CannonConfig.PromptObjectText
	newPrompt.HoldDuration = CannonConfig.PromptHoldSeconds
	newPrompt.Style = Enum.ProximityPromptStyle.Custom
	newPrompt.MaxActivationDistance = CannonConfig.PromptRangeStuds
	newPrompt.RequiresLineOfSight = false
	newPrompt.Parent = parent
	trove:Connect(newPrompt.Triggered, launch)
	prompt = newPrompt
end

function CannonService.Find(_self: any, key: string): CannonConfig.Cannon?
	return cannons[key]
end

function CannonService.IsLaunching(_self: any, player: Player): boolean
	return flights[player] ~= nil
end

function CannonService.Buy(_self: any, player: Player, key: string): boolean
	local data = services.DataService:GetData(player)
	local cannon = cannons[key]
	if not data or not cannon or data.Cannons[key] then
		return false
	end
	if data.Strength < cannon.StrengthRequired or data.Cash < cannon.Price then
		return false
	end
	if not services.DataService:AdjustCash(player, -cannon.Price) then
		return false
	end
	services.DataService:Set(player, { "Cannons", key }, true)
	services.DataService:Set(player, { "EquippedCannon" }, key)
	services.NotificationService:Notify(player, "Purchase", `Bought {cannon.DisplayName}!`)
	services.DataService:RequestSave(player)
	return true
end

function CannonService.Equip(_self: any, player: Player, key: string): boolean
	local data = services.DataService:GetData(player)
	if not data or (key ~= "" and not data.Cannons[key]) then
		return false
	end
	return services.DataService:Set(player, { "EquippedCannon" }, key)
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
	local model = findLobbyCannon()
	if model then
		setupPrompt(model)
	else
		warn(`[CannonService] No Workspace.{CannonConfig.CannonName} yet`)
	end
	trove:Connect(workspace.ChildAdded, function(child: Instance)
		if child.Name == CannonConfig.CannonName and child:IsA("Model") then
			setupPrompt(child)
		end
	end)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		local flight = flights[player]
		if flight then
			task.cancel(flight)
		end
		flights[player] = nil
		lastLaunch[player] = nil
	end)
	Packets.BuyCannon.OnServerInvoke = function(player: Player, key: string): boolean
		return CannonService:Buy(player, key)
	end
	Packets.EquipCannon.OnServerInvoke = function(player: Player, key: string): boolean
		return CannonService:Equip(player, key)
	end
end

function CannonService.Destroy(_self: any)
	Packets.BuyCannon.OnServerInvoke = nil
	Packets.EquipCannon.OnServerInvoke = nil
	for _, flight in flights do
		task.cancel(flight)
	end
	table.clear(flights)
	table.clear(lastLaunch)
	trove:Clean()
	prompt = nil
end

return CannonService
