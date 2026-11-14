--!nocheck
-- Chop a Rock base plot, rebuilt in meshlab 2026-11-09 from the 2026-11-03 Blender plot (assets/Base/BasePlot/plot_builder.py).
-- 64 wide, 66-94 long by level: three stacked slabs (Edge = lower two, Floor = top, both per level), a centre path that drapes down the front steps (Path)
-- with a white stringer trim on both edges (Trim), 12 hatch pads 3x2 per side (PadFrames + Pad1-12 centres; 8 wide since 2026-11-13) and a raised
-- green pen with a fence. The pen grows in length with the base level: front edge fixed at z 2, 56 wide, 28 deep at
-- level 1 up to 56 deep at level 8; the slabs end 2 studs behind it (Floor/Edge/PenFloor/PenSide/FencePosts/FenceRails per level). Every piece is its own part
-- so each can be recoloured. Front (entrance) faces -Z, pivot bottom centre, 1 unit = 1 stud, flat (no bake).
-- Seeds: 0 = white export with every level's pen parts (suffix _L1.._L8); 1..8 = coloured preview at that level.
return function(em, lib, Shapes, part)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rgb = C3.fromRGB
	Shapes.PITCH = 1.0

	local seed = lib.seed or 0
	local white = rgb(255, 255, 255)
	local function col(r, g, b)
		return if seed == 0 then white else rgb(r, g, b)
	end
	local floorCol = col(59, 59, 59)
	local stoneCol = col(125, 125, 125)
	local padCol = col(82, 82, 82)
	local penCol = col(22, 103, 0)

	local SLABS = { { 64, 0, 0.6 }, { 62, 0.6, 1.4 }, { 60, 1.4, 2.4 } }
	local BACK_EXTRA = 30
	local F = 2.4
	local SLAB_BEVEL = 0.12
	local WALK_HALF, WALK_H, TRIM_W, TRIM_H = 4, 0.4, 0.6, 0.1
	local PAD, PAD_RIM_W, PAD_RIM_H, PAD_BASE_H = 8, 1, 0.5, 0.1
	local PEN_X, PEN_Z0, PEN_H, PEN_TOP_H = 28, 2, 2, 0.4
	local STAIR_Z, STAIR_STEPS = -4, 3
	local FENCE_H, POST, POST_GAP, RAIL, FENCE_INSET = 3, 1.2, 7, 0.6, 0.7
	local RAIL_YS = { 1.1, 2.3 }
	local PEN_DEPTHS = { 28, 32, 36, 40, 44, 48, 52, 56 }
	local PADS = {
		{ 8.5, -21 }, { 8.5, -10 }, { 17.15, -21 }, { 17.15, -10 }, { 25.8, -21 }, { 25.8, -10 },
		{ -8.5, -21 }, { -8.5, -10 }, { -17.15, -21 }, { -17.15, -10 }, { -25.8, -21 }, { -25.8, -10 },
	}

	local function new(name)
		return Shapes.new(part(name), lib)
	end

	local function boxIn(S, x0, x1, y0, y1, z0, z1, color, bevel)
		S:bevelBox(
			CF.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2),
			V3.new(x1 - x0, y1 - y0, z1 - z0),
			color,
			bevel or 0
		)
	end

	local function round(x)
		return math.floor(x + 0.5)
	end

	local function spaced(a, b, gap)
		local count = math.max(1, round((b - a) / gap))
		local out = {}
		for i = 0, count do
			table.insert(out, a + (b - a) * i / count)
		end
		return out
	end

	local function slab(S, s, lift, color, backExtra)
		local w = s[1]
		boxIn(S, -w / 2, w / 2, s[2] - lift, s[3], -w / 2, w / 2 + backExtra, color, SLAB_BEVEL)
	end

	local function stairRects()
		local depth = (PEN_Z0 - STAIR_Z) / STAIR_STEPS
		local rise = (PEN_H - WALK_H) / STAIR_STEPS
		local out = {}
		for i = 0, STAIR_STEPS - 1 do
			table.insert(out, { STAIR_Z + i * depth, PEN_Z0 + FENCE_INSET, F + WALK_H + (i + 1) * rise })
		end
		return out
	end

	local function buildFixed()
		local wh = WALK_HALF - TRIM_W
		local path = new("BasePlot_Path")
		boxIn(path, -wh, wh, F - 0.01, F + WALK_H, -SLABS[3][1] / 2, STAIR_Z + 0.01, stoneCol)
		for _, pair in { { SLABS[3], SLABS[2] }, { SLABS[2], SLABS[1] } } do
			local upper, lower = pair[1], pair[2]
			local face, edgeZ = -upper[1] / 2, -lower[1] / 2
			boxIn(path, -wh, wh, lower[3] - 0.01, upper[3] + WALK_H, face - WALK_H, face + 0.01, stoneCol)
			local front = edgeZ + (if lower == SLABS[1] then 0.02 else 0)
			boxIn(path, -wh, wh, lower[3] - 0.01, lower[3] + WALK_H, front, face - WALK_H + 0.01, stoneCol)
		end
		local penTop = F + PEN_H - 0.02
		for _, r in stairRects() do
			boxIn(path, -wh, wh, F - 0.01, math.min(r[3], penTop), r[1], math.min(r[2], PEN_Z0 + 0.2), stoneCol)
		end

		local trim = new("BasePlot_Trim")
		local over = 0.05
		local rects = {}
		local back = STAIR_Z + 0.01
		for _, pair in { { SLABS[3], SLABS[2] }, { SLABS[2], SLABS[1] } } do
			local upper, lower = pair[1], pair[2]
			local face = -upper[1] / 2
			table.insert(rects, { face, back, upper[3] - 0.01, upper[3] + WALK_H + TRIM_H })
			table.insert(rects, { face - WALK_H - over, face, lower[3] - 0.01, upper[3] + WALK_H + TRIM_H })
			back = face - WALK_H - over
		end
		table.insert(rects, { -SLABS[1][1] / 2 + 0.02, back, SLABS[1][3] - 0.01, SLABS[1][3] + WALK_H + TRIM_H })
		for _, r in stairRects() do
			table.insert(rects, { r[1], r[2], F - 0.01, r[3] + TRIM_H })
		end
		for _, s in { -1, 1 } do
			local xa, xb = s * (WALK_HALF - TRIM_W), s * (WALK_HALF + over)
			if xa > xb then
				xa, xb = xb, xa
			end
			for _, r in rects do
				boxIn(trim, xa, xb, r[3], r[4], r[1], r[2], stoneCol)
			end
		end

		local frames = new("BasePlot_PadFrames")
		local half, top = PAD / 2, F + PAD_RIM_H
		local inner = PAD / 2 - PAD_RIM_W + 0.02
		for i, c in PADS do
			local cx, cz = c[1], c[2]
			boxIn(frames, cx - half, cx + half, F - 0.01, top, cz + half - PAD_RIM_W, cz + half, stoneCol, 0.1)
			boxIn(frames, cx - half, cx + half, F - 0.01, top, cz - half, cz - half + PAD_RIM_W, stoneCol, 0.1)
			boxIn(frames, cx - half, cx - half + PAD_RIM_W, F - 0.01, top, cz - half + PAD_RIM_W, cz + half - PAD_RIM_W, stoneCol, 0.1)
			boxIn(frames, cx + half - PAD_RIM_W, cx + half, F - 0.01, top, cz - half + PAD_RIM_W, cz + half - PAD_RIM_W, stoneCol, 0.1)
			boxIn(new(`BasePlot_Pad{i}`), cx - inner, cx + inner, F - 0.01, F + PAD_BASE_H, cz - inner, cz + inner, padCol)
		end
	end

	local function buildPen(level, suffix)
		local depth = PEN_DEPTHS[level]
		local backExtra = BACK_EXTRA - (PEN_DEPTHS[#PEN_DEPTHS] - depth)
		slab(new(`Floor{suffix}`), SLABS[3], 0.01, floorCol, backExtra)
		local edge = new(`Edge{suffix}`)
		slab(edge, SLABS[1], 0, floorCol, backExtra)
		slab(edge, SLABS[2], 0.01, floorCol, backExtra)

		local z0, z1 = PEN_Z0, PEN_Z0 + depth
		local top = F + PEN_H
		boxIn(new(`PenFloor{suffix}`), -PEN_X, PEN_X, top - PEN_TOP_H, top, z0, z1, penCol, 0.15)

		local inset, bottom = 0.02, F - 0.01
		boxIn(
			new(`PenSide{suffix}`),
			-PEN_X + inset,
			PEN_X - inset,
			bottom,
			bottom + PEN_H - PEN_TOP_H + 0.02,
			z0 + inset,
			z1 - inset,
			stoneCol
		)

		local base = top - 0.01
		local halfPost, rail = POST / 2, RAIL / 2
		local x1 = PEN_X - FENCE_INSET
		local fz0, fz1 = z0 + FENCE_INSET, z1 - FENCE_INSET
		local gap = WALK_HALF + halfPost
		local seen, posts = {}, {}
		local function addPost(x, z)
			local key = string.format("%.3f,%.3f", x, z)
			if not seen[key] then
				seen[key] = true
				table.insert(posts, { x, z })
			end
		end
		for _, x in spaced(-x1, x1, POST_GAP) do
			addPost(x, fz1)
		end
		for _, z in spaced(fz0, fz1, POST_GAP) do
			addPost(-x1, z)
			addPost(x1, z)
		end
		for _, s in { -1, 1 } do
			for _, x in spaced(gap, x1, POST_GAP) do
				addPost(s * x, fz0)
			end
		end
		local postsMesh = new(`FencePosts{suffix}`)
		for _, p in posts do
			boxIn(postsMesh, p[1] - halfPost, p[1] + halfPost, base, base + FENCE_H, p[2] - halfPost, p[2] + halfPost, stoneCol, 0.08)
		end

		local rails = new(`FenceRails{suffix}`)
		for _, y in RAIL_YS do
			local yb, yt = base + y - rail, base + y + rail
			boxIn(rails, -x1, x1, yb, yt, fz1 - rail, fz1 + rail, stoneCol)
			for _, s in { -1, 1 } do
				local xa, xb = s * x1 - rail, s * x1 + rail
				if xa > xb then
					xa, xb = xb, xa
				end
				boxIn(rails, xa, xb, yb, yt, fz0, fz1, stoneCol)
				local ga, gb = s * gap, s * x1
				if ga > gb then
					ga, gb = gb, ga
				end
				boxIn(rails, ga, gb, yb, yt, fz0 - rail, fz0 + rail, stoneCol)
			end
		end
	end

	buildFixed()
	if seed == 0 then
		for level = 1, #PEN_DEPTHS do
			buildPen(level, `_L{level}`)
		end
	else
		buildPen(math.clamp(seed, 1, #PEN_DEPTHS), "")
	end
end
