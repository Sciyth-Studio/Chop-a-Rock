--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)

export type Warp = {
	Label: string,
	Order: number,
	Part: BasePart,
}

local AdminWarps = {}

function AdminWarps.Container(): Instance?
	return workspace:FindFirstChild(AdminConfig.WarpModelName)
end

function AdminWarps.List(): { Warp }
	local warps: { Warp } = {}
	local container = AdminWarps.Container()
	if not container then
		return warps
	end
	for _, child in container:GetChildren() do
		if not child:IsA("BasePart") then
			continue
		end
		local label = child:GetAttribute(AdminConfig.WarpLabelAttribute)
		local order = child:GetAttribute(AdminConfig.WarpOrderAttribute)
		table.insert(warps, {
			Label = if type(label) == "string" and #label > 0 then label else child.Name,
			Order = if type(order) == "number" then order else math.huge,
			Part = child,
		})
	end
	table.sort(warps, function(a: Warp, b: Warp)
		if a.Order ~= b.Order then
			return a.Order < b.Order
		end
		return a.Label < b.Label
	end)
	return warps
end

function AdminWarps.Find(label: string): BasePart?
	for _, warp in AdminWarps.List() do
		if warp.Label == label then
			return warp.Part
		end
	end
	return nil
end

return AdminWarps
