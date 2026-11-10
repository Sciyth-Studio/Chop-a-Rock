--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EggDropConfig = require(ReplicatedStorage.Config.EggDropConfig)

export type Saved = {
	Parts: { [BasePart]: { Color: Color3, Material: Enum.Material } },
	Meshes: { [MeshPart]: string },
	Hidden: { [Instance]: Instance },
	Faded: { [Decal]: number },
}

local Silhouette = {}

function Silhouette.Apply(model: Model): Saved
	local saved: Saved = { Parts = {}, Meshes = {}, Hidden = {}, Faded = {} }
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			saved.Parts[descendant] = { Color = descendant.Color, Material = descendant.Material }
			descendant.Color = EggDropConfig.SilhouetteColor
			descendant.Material = Enum.Material.SmoothPlastic
			if descendant:IsA("MeshPart") and descendant.TextureID ~= "" then
				saved.Meshes[descendant] = descendant.TextureID
				descendant.TextureID = ""
			end
		elseif descendant:IsA("SurfaceAppearance") then
			local parent = descendant.Parent
			if parent then
				saved.Hidden[descendant] = parent
			end
		elseif descendant:IsA("Decal") then
			saved.Faded[descendant] = descendant.Transparency
			descendant.Transparency = 1
		end
	end
	for instance in saved.Hidden do
		instance.Parent = nil
	end
	return saved
end

function Silhouette.Restore(saved: Saved)
	for part, state in saved.Parts do
		part.Color = state.Color
		part.Material = state.Material
	end
	for mesh, texture in saved.Meshes do
		mesh.TextureID = texture
	end
	for instance, parent in saved.Hidden do
		if parent.Parent then
			instance.Parent = parent
		end
	end
	for decal, transparency in saved.Faded do
		decal.Transparency = transparency
	end
end

return Silhouette
