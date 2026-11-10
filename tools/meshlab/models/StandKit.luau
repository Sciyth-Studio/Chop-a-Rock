--!nocheck
-- Shared helpers for the training stand families (StandPreciousMetal, StandCutGem, StandRawCrystal, Stand<Space>).
-- Kit.Run drives the seeds: 0 = white export meshes (whole breakable plus _L/_R halves cut at x = 0),
-- 1..n = palette n with the whole breakable, 11..10+n = palette n with the halves pulled apart.
-- Kit.Ring builds a chamfered-rectangle cross-section that always has points on x = 0, so a loft of these rings
-- can be cut into two halves whose cut faces match the whole.
local Kit = {}

local INF = math.huge

function Kit.Run(lib, Shapes, part, palettes, build)
	Shapes.PITCH = 1.0
	local V3 = lib.Vector3
	local seed = lib.seed or 0
	local function maker(suffix)
		return function(name)
			return Shapes.new(part(name .. suffix), lib)
		end
	end
	local zero = V3.new(0, 0, 0)
	if seed == 0 then
		local white = {}
		for k in palettes[1] do
			white[k] = lib.Color3.fromRGB(255, 255, 255)
		end
		build.frame(maker(""), zero, white)
		build.breakable(maker(""), zero, white, -INF, INF)
		build.breakable(maker("_L"), zero, white, -INF, 0)
		build.breakable(maker("_R"), zero, white, 0, INF)
	elseif seed <= 10 then
		local pal = palettes[seed]
		build.frame(maker(""), zero, pal)
		build.breakable(maker(""), zero, pal, -INF, INF)
	else
		local pal = palettes[seed - 10]
		build.frame(maker(""), zero, pal)
		build.breakable(maker("_L"), V3.new(-0.35, 0, 0), pal, -INF, 0)
		build.breakable(maker("_R"), V3.new(0.35, 0, 0), pal, 0, INF)
	end
end

-- Points of a chamfered rectangle (half-width hw along X, half-depth hd along Z, chamfer ch) at height y,
-- clipped to [x0, x1] where x0/x1 is -INF/INF or 0. Whole rings get 10 points, halves 6.
function Kit.Ring(lib, cx, y, cz, hw, hd, ch, x0, x1, warp)
	local V3 = lib.Vector3
	local full = {
		{ 0, -hd }, { hw - ch, -hd }, { hw, -hd + ch }, { hw, hd - ch }, { hw - ch, hd },
		{ 0, hd }, { -hw + ch, hd }, { -hw, hd - ch }, { -hw, -hd + ch }, { -hw + ch, -hd },
	}
	local pts = {}
	local function add(p)
		local v = V3.new(cx + p[1], y, cz + p[2])
		table.insert(pts, warp and warp(v) or v)
	end
	if x0 == -INF and x1 == INF then
		for _, p in full do
			add(p)
		end
	elseif x1 == 0 then
		for i = 6, 10 do
			add(full[i])
		end
		add(full[1])
	else
		for i = 1, 6 do
			add(full[i])
		end
	end
	return pts
end

-- Loft through chamfered rings given as { {y, hw, hd, ch}, ... } bottom to top, centred on (cx, cz).
function Kit.Stack(S, lib, cx, cz, rings, color, x0, x1, warp)
	local list = {}
	for _, r in rings do
		table.insert(list, Kit.Ring(lib, cx, r[1], cz, r[2], r[3], r[4], x0 or -INF, x1 or INF, warp))
	end
	S:loft(list, { color = color })
end

-- Same as Stack but the rings run along X (cross-sections in the YZ plane), for bars lying across the posts.
-- rings: { {x, hh, hd, ch}, ... } left to right; cy, cz centre. Only whole (no cut) since the cut is a ring.
function Kit.Bar(S, lib, cy, cz, rings, color, warp)
	local V3 = lib.Vector3
	local list = {}
	for _, r in rings do
		local x, hh, hd, ch = r[1], r[2], r[3], r[4]
		local ring = {}
		for _, p in { { -hh, -hd + ch }, { -hh + ch, -hd }, { hh - ch, -hd }, { hh, -hd + ch }, { hh, hd - ch }, { hh - ch, hd }, { -hh + ch, hd }, { -hh, hd - ch } } do
			local v = V3.new(x, cy + p[1], cz + p[2])
			table.insert(ring, warp and warp(v) or v)
		end
		table.insert(list, ring)
	end
	S:loft(list, { color = color })
end

-- Keeps only the rings of a Bar list inside [x0, x1], adding a ring exactly at the cut (interpolated).
function Kit.ClipBar(rings, x0, x1)
	local out = {}
	for i, r in rings do
		local inside = r[1] >= x0 and r[1] <= x1
		if inside then
			table.insert(out, r)
		end
		local nxt = rings[i + 1]
		if nxt then
			for _, cut in { x0, x1 } do
				if cut ~= -INF and cut ~= INF and (r[1] - cut) * (nxt[1] - cut) < 0 then
					local t = (cut - r[1]) / (nxt[1] - r[1])
					local m = { cut }
					for k = 2, 4 do
						m[k] = r[k] + (nxt[k] - r[k]) * t
					end
					table.insert(out, m)
				end
			end
		end
	end
	return out
end

-- Deterministic jitter from a position, for rough stone that matches across split halves.
function Kit.Rough(lib, amount, salt)
	local V3 = lib.Vector3
	local function h(x, y, z, k)
		local n = math.sin(x * 12.9898 + y * 78.233 + z * 37.719 + k * 4.581 + (salt or 0) * 1.37) * 43758.5453
		return (n - math.floor(n)) * 2 - 1
	end
	return function(v)
		local x, y, z = math.floor(v.X * 100 + 0.5) / 100, math.floor(v.Y * 100 + 0.5) / 100, math.floor(v.Z * 100 + 0.5) / 100
		return v + V3.new(h(x, y, z, 1), h(x, y, z, 2) * 0.6, h(x, y, z, 3)) * amount
	end
end

-- Runs fn and points the UVs of every face it added to S at a flat spot of the stud tile (no studs).
function Kit.Plain(S, lib, fn)
	local em = S.em
	local before = {}
	for _, f in em:GetFaces() do
		before[f] = true
	end
	fn()
	local flat = em:AddUV(lib.Vector2.new(0.03, 0.03))
	for _, f in em:GetFaces() do
		if not before[f] then
			em:SetFaceUVs(f, { flat, flat, flat })
		end
	end
end

return Kit
