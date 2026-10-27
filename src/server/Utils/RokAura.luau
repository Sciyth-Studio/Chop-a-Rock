--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)

local RokAura = {}

function RokAura.Attach(model: Model, petKey: string, scale: number)
	local pet = PetConfig.Pets[petKey]
	local body = model.PrimaryPart
	if not pet or not pet.AuraKey or not body then
		return
	end
	local template = AssetRegistry.get(pet.AuraKey)
	for _, descendant in template:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant:Clone().Parent = body
		elseif descendant:IsA("PointLight") then
			local light = descendant:Clone()
			light.Range *= scale
			light.Parent = body
		end
	end
	template:Destroy()
end

return RokAura
