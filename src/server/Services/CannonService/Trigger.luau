--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CannonConfig = require(ReplicatedStorage.Config.CannonConfig)

export type Regions = {
	Entry: BasePart?,
	Area: BasePart?,
}

local Trigger = {}

local settings = CannonConfig.Trigger

local function findPart(folder: Instance, name: string): BasePart?
	local part = folder:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return part
	end
	warn(`[CannonService] Missing BasePart {folder:GetFullName()}.{name}`)
	return nil
end

function Trigger.Find(): Regions
	local folder = workspace:FindFirstChild(settings.FolderName)
	if not folder then
		warn(`[CannonService] Missing Workspace.{settings.FolderName}; the Fire Cannon button is off`)
		return {}
	end
	return {
		Entry = findPart(folder, settings.EntryName),
		Area = findPart(folder, settings.AreaName),
	}
end

function Trigger.Contains(part: BasePart?, position: Vector3): boolean
	if not part then
		return false
	end
	local offset = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(offset.X) <= half.X and math.abs(offset.Y) <= half.Y and math.abs(offset.Z) <= half.Z
end

function Trigger.RootPosition(player: Player): Vector3?
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if root and root:IsA("BasePart") then root.Position else nil
end

return Trigger
