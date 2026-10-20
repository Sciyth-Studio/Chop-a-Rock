--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local Effects = require(script.Effects)
local Flight = require(script.Flight)
local Packets = require(ReplicatedStorage.Packets)
local Shake = require(script.Shake)
local Trove = require(ReplicatedStorage.Packages.Trove)

local CannonController = { Name = "CannonController" }

local trove = Trove.new()
local flightTrove = Trove.new()
local cannonTrove = Trove.new()
local launches = Trove.new()
local controllers: { [string]: any } = {}
local cache: Effects.Cache = {}
local lastEquipped: string? = nil

local function cannonColor(key: string): Color3
	for _, cannon in CannonConfig.Cannons do
		if cannon.Key == key then
			return cannon.Color
		end
	end
	return CannonConfig.EmptyColor
end

local function equippedColor(): Color3
	return cannonColor(controllers.DataController:Get({ "EquippedCannon" }) or "")
end

local function findCannon(): Model?
	local model = workspace:FindFirstChild(CannonConfig.CannonName)
	return if model and model:IsA("Model") then model else nil
end

local function findAttachment(model: Model, name: string): Attachment?
	local found = model:FindFirstChild(name, true)
	return if found and found:IsA("Attachment") then found else nil
end

local function tint()
	local model = findCannon()
	if not model then
		return
	end
	local color = equippedColor()
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute(CannonConfig.TintAttribute) == true then
			part.Color = color
		end
	end
end

local function onEquipped(key: any)
	local equipped = if type(key) == "string" then key else ""
	tint()
	local previous = lastEquipped
	lastEquipped = equipped
	if previous == nil or previous == equipped or equipped == "" then
		return
	end
	local model = findCannon()
	if not model then
		return
	end
	local center = model:GetBoundingBox()
	Effects.Play(cache, CannonConfig.Effects.Equip, center, cannonColor(equipped))
	Effects.SoundAt(CannonConfig.Sounds.Equip, center.Position)
end

local function watchCannon(model: Instance)
	cannonTrove:Clean()
	cannonTrove:Connect(model.DescendantAdded, function(descendant: Instance)
		if descendant:IsA("BasePart") and descendant:GetAttribute(CannonConfig.TintAttribute) == true then
			descendant.Color = equippedColor()
		end
	end)
	cannonTrove:Connect(model.AncestryChanged, function()
		if not model:IsDescendantOf(workspace) then
			cannonTrove:Clean()
		end
	end)
	tint()
end

local function groundBelow(position: Vector3): Vector3
	local params = RaycastParams.new()
	local characters = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(characters, player.Character)
		end
	end
	params.FilterDescendantsInstances = characters
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -20, 0), params)
	return if hit then hit.Position else position - Vector3.new(0, 3, 0)
end

local function onLaunch(
	player: Instance,
	key: string,
	start: Vector3,
	finish: Vector3,
	height: number,
	chargeSeconds: number,
	flightSeconds: number
)
	if not player:IsA("Player") then
		return
	end
	local isLocal = player == Players.LocalPlayer
	local color = cannonColor(key)
	local model = findCannon()
	local muzzle = if model then findAttachment(model, CannonConfig.MuzzleName) else nil
	local bore = if model then findAttachment(model, CannonConfig.BoreName) else nil
	local fuse = if model then findAttachment(model, CannonConfig.FuseName) else nil
	local axis = if muzzle and bore
		then (muzzle.WorldPosition - bore.WorldPosition).Unit
		else (finish - start).Unit
	local mouth = CFrame.lookAt(start, start + axis)

	if isLocal and player.Character then
		Flight.Fly(flightTrove, player.Character, {
			Inside = if bore then bore.WorldPosition else start,
			Start = start,
			Finish = finish,
			Height = height,
			ChargeSeconds = chargeSeconds,
			FlightSeconds = flightSeconds,
		})
	end

	local launch = launches:Extend()
	if fuse then
		Effects.Play(cache, CannonConfig.Effects.Fuse, fuse.WorldCFrame, color)
		Effects.SoundAt(CannonConfig.Sounds.Fuse, fuse.WorldPosition)
	end
	Effects.Play(cache, CannonConfig.Effects.Charge, mouth, color)
	if model then
		Effects.Pulse(launch, model, chargeSeconds, tint)
	end

	launch:Add(task.delay(chargeSeconds, function()
		Effects.Play(cache, CannonConfig.Effects.Blast, mouth, color)
		Effects.SoundAt(CannonConfig.Sounds.Boom, start)
		if isLocal then
			Shake.Play(CannonConfig.BlastShake)
		end
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local stopTrail = function() end
		if root and root:IsA("BasePart") then
			stopTrail = Effects.Trail(cache, color, root)
			Effects.Sound(CannonConfig.Sounds.Whoosh, root)
		end
		launch:Add(stopTrail)
		launch:Add(task.delay(math.max(flightSeconds - CannonConfig.LandLeadSeconds, 0), function()
			stopTrail()
			local ground = groundBelow(finish)
			Effects.Play(cache, CannonConfig.Effects.Land, CFrame.new(ground), color)
			Effects.SoundAt(CannonConfig.Sounds.Land, ground)
			if isLocal then
				Shake.Play(CannonConfig.LandShake)
			end
			task.defer(function()
				launches:Remove(launch)
			end)
		end))
	end))
end

function CannonController.Init(_self: any, registry: { [string]: any })
	controllers = registry
end

function CannonController.Start(_self: any)
	cache = Effects.Load()
	trove:Add(flightTrove)
	trove:Add(cannonTrove)
	trove:Add(launches)
	trove:Add(function()
		for _, template in cache do
			template:Destroy()
		end
		table.clear(cache)
	end)
	trove:Add(controllers.DataController:Observe({ "EquippedCannon" }, onEquipped))
	local existing = findCannon()
	if existing then
		watchCannon(existing)
	end
	trove:Connect(workspace.ChildAdded, function(child: Instance)
		if child.Name == CannonConfig.CannonName then
			watchCannon(child)
		end
	end)
	trove:Add(Packets.CannonLaunch.OnClientEvent:Connect(onLaunch))
	trove:Add(Packets.CannonEmpty.OnClientEvent:Connect(function()
		controllers.UIController:Open(CannonConfig.ScreenName)
	end))
	trove:Connect(Players.LocalPlayer.CharacterRemoving, function()
		flightTrove:Clean()
	end)
end

function CannonController.Destroy(_self: any)
	trove:Destroy()
end

return CannonController
