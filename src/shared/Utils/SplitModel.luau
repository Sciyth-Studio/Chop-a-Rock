--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)

export type Push = {
	OutwardStuds: number,
	UpStuds: number,
	TorqueRadPerSec: number,
}

local SplitModel = {}

SplitModel.Attribute = "SplitModel"

function SplitModel.Spawn(part: BasePart, push: Push): Model?
	local key = part:GetAttribute(SplitModel.Attribute)
	if type(key) ~= "string" then
		return nil
	end
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Model") then
		asset:Destroy()
		return nil
	end
	local model = asset :: Model
	local boxCFrame, boxSize = model:GetBoundingBox()
	model.WorldPivot = boxCFrame
	model:ScaleTo(model:GetScale() * part.Size.X / boxSize.X)
	model:PivotTo(part.CFrame)

	local pieces: { BasePart } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = true
			descendant.CanQuery = false
			descendant.Color = part.Color
			descendant.Material = part.Material
			descendant.MaterialVariant = part.MaterialVariant
			table.insert(pieces, descendant)
		end
	end
	model.Parent = workspace

	local up = part.CFrame.UpVector
	for _, piece in pieces do
		local offset = piece.Position - part.Position
		local outward = offset - up * offset:Dot(up)
		local direction = if outward.Magnitude > 1e-3 then outward.Unit else part.CFrame.RightVector
		piece.AssemblyLinearVelocity = direction * push.OutwardStuds + up * push.UpStuds
		piece.AssemblyAngularVelocity = up:Cross(direction) * push.TorqueRadPerSec
	end
	return model
end

return SplitModel
