--!strict

local Players = game:GetService("Players")

local ChopApproach = {}

function ChopApproach.Rotation(rock: BasePart): CFrame
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root or not root:IsA("BasePart") then
		return CFrame.identity
	end
	local offset = root.Position - rock.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude < 1e-3 then
		return CFrame.identity
	end
	return CFrame.lookAt(Vector3.zero, flat.Unit)
end

return ChopApproach
