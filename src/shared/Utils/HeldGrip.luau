--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HeldItemConfig = require(ReplicatedStorage.Config.HeldItemConfig)

local HeldGrip = {}

function HeldGrip.For(model: Model, handle: BasePart): CFrame
	local box, size = model:GetBoundingBox()
	local lift = handle.Position.Y - (box.Y - size.Y / 2) + HeldItemConfig.GapStuds
	return CFrame.new(0, -lift, 0) * HeldItemConfig.OverheadGrip
end

return HeldGrip
