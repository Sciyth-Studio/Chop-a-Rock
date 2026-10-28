local root = workspace:FindFirstChild("BUILD_NAME", true)
assert(root, "Set BUILD_NAME to the build's root Model")

local eps = 0.00005
local minOverlap = 0.05

local boxes = {}
local skipped = 0
for _, p in root:GetDescendants() do
	if p:IsA("BasePart") and p.Transparency < 1 then
		local cf = p.CFrame
		local aligned = true
		for _, v in { cf.RightVector, cf.UpVector, cf.LookVector } do
			if math.max(math.abs(v.X), math.abs(v.Y), math.abs(v.Z)) < 0.9999 then
				aligned = false
			end
		end
		if aligned then
			local h = cf:VectorToWorldSpace(p.Size / 2)
			h = Vector3.new(math.abs(h.X), math.abs(h.Y), math.abs(h.Z))
			table.insert(boxes, { part = p, min = cf.Position - h, max = cf.Position + h })
		else
			skipped += 1
		end
	end
end

local axes = { "X", "Y", "Z" }
local hits = {}
for i = 1, #boxes do
	local a = boxes[i]
	for j = i + 1, #boxes do
		local b = boxes[j]
		local overlap = {}
		local apart = false
		for _, ax in axes do
			local o = math.min(a.max[ax], b.max[ax]) - math.max(a.min[ax], b.min[ax])
			overlap[ax] = o
			if o < -eps then
				apart = true
			end
		end
		if not apart then
			for k, ax in axes do
				local other1, other2 = axes[k % 3 + 1], axes[(k + 1) % 3 + 1]
				if overlap[other1] > minOverlap and overlap[other2] > minOverlap then
					local side = nil
					if math.abs(a.min[ax] - b.min[ax]) < eps then
						side = "min"
					elseif math.abs(a.max[ax] - b.max[ax]) < eps then
						side = "max"
					end
					if side then
						table.insert(hits, `{a.part:GetFullName()} <> {b.part:GetFullName()} share {side} {ax}`)
					end
				end
			end
		end
	end
end

print(`Coplanar sweep: {#hits} hits, {#boxes} parts checked, {skipped} rotated parts skipped`)
for _, line in hits do
	print(line)
end
