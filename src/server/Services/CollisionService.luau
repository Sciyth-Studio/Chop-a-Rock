--!strict

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)

local debrisGroup = "Debris"
local charactersGroup = "Characters"

local CollisionService = {
	Name = "CollisionService",
}

local trove = Trove.new()

local function setGroup(instance: Instance, group: string)
	if instance:IsA("BasePart") then
		instance.CollisionGroup = group
	end
end

local function watchCharacter(character: Model)
	for _, descendant in character:GetDescendants() do
		setGroup(descendant, charactersGroup)
	end
	local connection = character.DescendantAdded:Connect(function(descendant: Instance)
		setGroup(descendant, charactersGroup)
	end)
	trove:Add(connection)
	character.Destroying:Once(function()
		trove:Remove(connection)
	end)
end

local function watchPlayer(player: Player)
	if player.Character then
		watchCharacter(player.Character)
	end
	trove:Add(player.CharacterAdded:Connect(watchCharacter))
end

function CollisionService.MarkDebris(_self: any, root: Instance)
	setGroup(root, debrisGroup)
	for _, descendant in root:GetDescendants() do
		setGroup(descendant, debrisGroup)
	end
end

function CollisionService.Init(_self: any, _registry: { [string]: any }) end

function CollisionService.Start(_self: any)
	PhysicsService:RegisterCollisionGroup(debrisGroup)
	PhysicsService:RegisterCollisionGroup(charactersGroup)
	PhysicsService:CollisionGroupSetCollidable(debrisGroup, charactersGroup, false)

	for _, player in Players:GetPlayers() do
		watchPlayer(player)
	end
	trove:Add(Players.PlayerAdded:Connect(watchPlayer))
end

function CollisionService.Destroy(_self: any)
	trove:Clean()
end

return CollisionService
