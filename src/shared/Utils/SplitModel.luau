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

local function piecesBox(pieces: { BasePart }): (CFrame, Vector3)
	local low = Vector3.one * math.huge
	local high = -Vector3.one * math.huge
	for _, piece in pieces do
		local half = piece.Size / 2
		for _, corner in
			{
				Vector3.new(-1, -1, -1),
				Vector3.new(-1, -1, 1),
				Vector3.new(-1, 1, -1),
				Vector3.new(-1, 1, 1),
				Vector3.new(1, -1, -1),
				Vector3.new(1, -1, 1),
				Vector3.new(1, 1, -1),
				Vector3.new(1, 1, 1),
			}
		do
			local point = piece.CFrame:PointToWorldSpace(half * corner)
			low = low:Min(point)
			high = high:Max(point)
		end
	end
	return CFrame.new((low + high) / 2), high - low
end

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

	local pieces: { BasePart } = {}
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(pieces, child)
		end
	end
	if #pieces == 0 then
		model:Destroy()
		return nil
	end

	local boxCFrame, boxSize = piecesBox(pieces)
	model.WorldPivot = boxCFrame
	model:ScaleTo(model:GetScale() * part.Size.X / boxSize.X)
	model:PivotTo(part.CFrame)

	for _, piece in pieces do
		piece.Anchored = false
		piece.CanCollide = true
		piece.CanQuery = false
		piece.Color = part.Color
		piece.Material = part.Material
		piece.MaterialVariant = part.MaterialVariant
		for _, descendant in piece:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = false
				descendant.CanCollide = false
				descendant.CanQuery = false
				descendant.Massless = true
				local weld = Instance.new("Weld")
				weld.Part0 = piece
				weld.Part1 = descendant
				weld.C0 = piece.CFrame:ToObjectSpace(descendant.CFrame)
				weld.Parent = descendant
			end
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
