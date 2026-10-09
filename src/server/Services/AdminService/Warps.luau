--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local AdminWarps = require(ReplicatedStorage.Utils.AdminWarps)
local Types = require(script.Parent.Types)

local Warps = {}

local function target(context: Types.Context, player: Player, label: string): BasePart?
	if label == AdminConfig.BaseWarpLabel then
		local plot = context.Services.BaseService:GetPlot(player)
		local spawn = if plot then plot:FindFirstChild(AdminConfig.BaseSpawnName, true) else nil
		return if spawn and spawn:IsA("BasePart") then spawn else nil
	end
	return AdminWarps.Find(label)
end

function Warps.Teleport(context: Types.Context, player: Player, label: string): boolean
	local part = target(context, player, label)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not part or not character or not root or not root:IsA("BasePart") then
		return false
	end
	root.AssemblyLinearVelocity = Vector3.zero
	character:PivotTo(part.CFrame + Vector3.new(0, part.Size.Y / 2 + AdminConfig.WarpLiftStuds, 0))
	return true
end

return Warps
