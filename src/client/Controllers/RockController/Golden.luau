--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local GoldenRockConfig = require(ReplicatedStorage.Config.GoldenRockConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local VFXEmit = require(ReplicatedStorage.VFX.Emit) :: any

local Golden = {}

function Golden.Start(part: BasePart): () -> ()
	part.Color = GoldenRockConfig.Color
	part:SetAttribute(GoldenRockConfig.GoldenAttribute, true)

	local outline = Instance.new("Highlight")
	outline.Name = "GoldenOutline"
	outline.FillColor = GoldenRockConfig.Color
	outline.FillTransparency = 1
	outline.OutlineColor = GoldenRockConfig.OutlineColor
	outline.OutlineTransparency = 0
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Adornee = part
	outline.Parent = part

	local glow = AssetRegistry.get(GoldenRockConfig.GlowKey)
	local emitters: { ParticleEmitter } = {}
	for _, descendant in glow:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Parent = part
			table.insert(emitters, descendant)
		end
	end
	glow:Destroy()

	return function()
		outline:Destroy()
		for _, emitter in emitters do
			emitter:Destroy()
		end
	end
end

function Golden.Burst(part: BasePart)
	LocalSound.Play(GoldenRockConfig.BreakSoundKey)
	local asset = AssetRegistry.get(GoldenRockConfig.BurstKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	asset:PivotTo(CFrame.new(part.Position - Vector3.new(0, part.Size.Y / 2, 0)))
	asset.Parent = workspace
	VFXEmit.emit(asset, {
		onDone = function()
			asset:Destroy()
		end,
	})
end

return Golden
