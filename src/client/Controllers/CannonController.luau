--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)
local MovementLock = require(ReplicatedStorage.Utils.MovementLock)
local Packets = require(ReplicatedStorage.Packets)
local Trove = require(ReplicatedStorage.Packages.Trove)

local CannonController = { Name = "CannonController" }

local trove = Trove.new()
local flightTrove = Trove.new()
local controllers: { [string]: any } = {}
local cannonTrove = Trove.new()

local function equippedColor(): Color3
	local key = controllers.DataController:Get({ "EquippedCannon" })
	for _, cannon in CannonConfig.Cannons do
		if cannon.Key == key then
			return cannon.Color
		end
	end
	return CannonConfig.EmptyColor
end

local function tint()
	local model = workspace:FindFirstChild(CannonConfig.CannonName)
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

local function arcPoint(start: Vector3, finish: Vector3, height: number, alpha: number): Vector3
	return start:Lerp(finish, alpha) + Vector3.new(0, 4 * height * alpha * (1 - alpha), 0)
end

local function fly(start: Vector3, finish: Vector3, height: number, duration: number)
	flightTrove:Clean()
	local character = Players.LocalPlayer.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not humanoid or not root or not root:IsA("BasePart") or duration <= 0 then
		return
	end
	local flat = Vector3.new(finish.X - start.X, 0, finish.Z - start.Z)
	local facing = if flat.Magnitude > 0 then flat.Unit else Vector3.zAxis
	flightTrove:Add(MovementLock.Acquire(humanoid))
	humanoid.PlatformStand = true
	flightTrove:Add(function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = CFrame.lookAt(finish, finish + facing)
	end)
	local began = os.clock()
	flightTrove:Connect(RunService.PreSimulation, function()
		if not humanoid.Parent or humanoid.Health <= 0 then
			flightTrove:Clean()
			return
		end
		local alpha = math.min((os.clock() - began) / duration, 1)
		local position = arcPoint(start, finish, height, alpha)
		local ahead = arcPoint(start, finish, height, math.min(alpha + 0.01, 1))
		local velocity = (ahead - position) / (0.01 * duration)
		root.CFrame = CFrame.lookAt(position, position + facing)
		root.AssemblyLinearVelocity = velocity
		root.AssemblyAngularVelocity = Vector3.zero
		if alpha >= 1 then
			flightTrove:Clean()
		end
	end)
end

function CannonController.Init(_self: any, registry: { [string]: any })
	controllers = registry
end

function CannonController.Start(_self: any)
	trove:Add(flightTrove)
	trove:Add(cannonTrove)
	trove:Add(controllers.DataController:Observe({ "EquippedCannon" }, tint))
	local existing = workspace:FindFirstChild(CannonConfig.CannonName)
	if existing then
		watchCannon(existing)
	end
	trove:Connect(workspace.ChildAdded, function(child: Instance)
		if child.Name == CannonConfig.CannonName then
			watchCannon(child)
		end
	end)
	trove:Add(Packets.CannonLaunch.OnClientEvent:Connect(fly))
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
