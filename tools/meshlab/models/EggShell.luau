--!nocheck
-- Chop a Rock zone eggs: helpers shared by every Egg* model. One faceted shell, plus the pieces
-- the eggs dress it with. Not a model itself. Shell 4.8 wide, 5.6 tall, flat bottom on Y = 0,
-- front -Z (angle 90). Angles are degrees around Y, and +X is the viewer's left from the front.
-- Studs 1 per stud on the shell only; everything built through Egg.plain has no studs.

local Egg = {}

Egg.Height = 5.6
Egg.Radius = 2.4
Egg.Sides = 12

local profile = {
	{ 0, 0.5 },
	{ 0.07, 0.76 },
	{ 0.2, 0.94 },
	{ 0.36, 1 },
	{ 0.52, 0.96 },
	{ 0.68, 0.84 },
	{ 0.82, 0.64 },
	{ 0.93, 0.38 },
	{ 0.985, 0.12 },
}

function Egg.RadiusAt(t)
	if t <= profile[1][1] then
		return profile[1][2] * Egg.Radius
	end
	for i = 1, #profile - 1 do
		local a, b = profile[i], profile[i + 1]
		if t <= b[1] then
			return (a[2] + (b[2] - a[2]) * (t - a[1]) / (b[1] - a[1])) * Egg.Radius
		end
	end
	return profile[#profile][2] * Egg.Radius
end

local function around(lib, degrees)
	local a = math.rad(degrees)
	return lib.Vector3.new(math.cos(a), 0, -math.sin(a))
end

function Egg.Point(lib, degrees, t, outset)
	return around(lib, degrees) * (Egg.RadiusAt(t) + (outset or 0)) + lib.Vector3.new(0, t * Egg.Height, 0)
end

function Egg.Normal(lib, degrees, t)
	local slope = (Egg.RadiusAt(t + 0.03) - Egg.RadiusAt(t - 0.03)) / (0.06 * Egg.Height)
	return (around(lib, degrees) + lib.Vector3.new(0, -slope, 0)).Unit
end

-- top stops the shell short at that fraction of its height, closed with a flat lid.
function Egg.Shell(S, lib, color, top)
	local rings = {}
	for _, row in profile do
		if not top or row[1] <= top then
			local ring = {}
			for k = 1, Egg.Sides do
				ring[k] = around(lib, (k - 1) * 360 / Egg.Sides + 15) * (row[2] * Egg.Radius)
					+ lib.Vector3.new(0, row[1] * Egg.Height, 0)
			end
			table.insert(rings, ring)
		end
	end
	S:loft(rings, { color = color })
end

-- Builds a whole egg: the studded shell, then fn(S) for the plain dressing on it.
function Egg.Build(em, lib, Shapes, shellColor, fn, top)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	local S = Shapes.new(em, lib)
	Egg.Shell(S, lib, shellColor, top)
	Egg.plain(em, lib, function()
		fn(S)
	end)
	Shapes.PITCH = pitch
end

-- A shell for a painted body texture: white, with U running around it and V up it, so V is the
-- same fraction of the height as Egg.Point's t. fn(S, solid) adds the rest, and solid(fn2, v)
-- points whatever fn2 builds at one row of the texture, for parts in a single painted colour.
function Egg.BuildPainted(em, lib, Shapes, fn, top)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	local S = Shapes.new(em, lib)
	Egg.Shell(S, lib, lib.Color3.new(1, 1, 1), top)
	for _, f in em:GetFaces() do
		local ids = em:GetFaceVertices(f)
		local us, poles = {}, {}
		local sum, count = 0, 0
		for k, id in ids do
			local p = em:GetPosition(id)
			if math.abs(p.X) + math.abs(p.Z) < 0.001 then
				poles[k] = true
			else
				us[k] = (math.atan2(-p.Z, p.X) / (math.pi * 2)) % 1
			end
		end
		local lowest, highest = 1, 0
		for _, u in us do
			lowest, highest = math.min(lowest, u), math.max(highest, u)
		end
		for k, u in us do
			if highest - lowest > 0.5 and u < 0.5 then
				us[k] = u + 1
			end
			sum += us[k]
			count += 1
		end
		for k in poles do
			us[k] = sum / count
		end
		local uvs = {}
		for k, id in ids do
			local p = em:GetPosition(id)
			uvs[k] = em:AddUV(lib.Vector2.new(us[k], p.Y / Egg.Height))
		end
		em:SetFaceUVs(f, uvs)
	end
	local function solid(build, v)
		local before = {}
		for _, f in em:GetFaces() do
			before[f] = true
		end
		build(S)
		local flat = em:AddUV(lib.Vector2.new(0.5, v))
		for _, f in em:GetFaces() do
			if not before[f] then
				em:SetFaceUVs(f, { flat, flat, flat })
			end
		end
	end
	if fn then
		fn(S, solid)
	end
	Shapes.PITCH = pitch
end

-- A chamfered ring around the shell between two heights.
function Egg.Band(S, lib, t0, t1, outset, color)
	local function ring(t, offset)
		local points = {}
		for k = 1, Egg.Sides do
			points[k] = Egg.Point(lib, (k - 1) * 360 / Egg.Sides + 15, t, offset)
		end
		return points
	end
	local chamfer = (t1 - t0) * 0.15
	S:loft({
		ring(t0, -0.1),
		ring(t0 + chamfer, outset),
		ring(t1 - chamfer, outset),
		ring(t1, -0.1),
	}, { color = color })
end

-- A faceted tube through points, with radii[i] at points[i].
function Egg.Along(S, lib, points, radii, segs, color)
	local V3 = lib.Vector3
	local rings = {}
	local u = nil
	for i, p in points do
		local forward = (points[math.min(i + 1, #points)] - points[math.max(i - 1, 1)]).Unit
		if not u then
			local helper = math.abs(forward.Y) > 0.9 and V3.new(1, 0, 0) or V3.new(0, 1, 0)
			u = helper:Cross(forward).Unit
		else
			u = (u - forward * u:Dot(forward)).Unit
		end
		local v = forward:Cross(u).Unit
		local ring = {}
		for k = 1, segs do
			local a = (k - 1) / segs * math.pi * 2
			ring[k] = p + (u * math.cos(a) + v * math.sin(a)) * radii[i]
		end
		rings[i] = ring
	end
	S:loft(rings, { color = color })
end

-- A flat leaf or petal through points. side is the direction of its width.
function Egg.Blade(S, lib, points, side, widths, thick, color)
	local rings = {}
	for i, p in points do
		local forward = (points[math.min(i + 1, #points)] - points[math.max(i - 1, 1)]).Unit
		local up = side:Cross(forward).Unit
		rings[i] = {
			p + side * widths[i],
			p + up * thick,
			p - side * widths[i],
			p - up * thick,
		}
	end
	S:loft(rings, { color = color })
end

-- A raised strip laid on the shell from one surface point to another, for faces, cracks and runes.
function Egg.Stripe(S, lib, a0, t0, a1, t1, width, height, color, sub, caps)
	sub = sub or 1
	local rings = {}
	for i = 0, sub do
		local f = -0.05 + 1.1 * i / sub
		local a, t = a0 + (a1 - a0) * f, t0 + (t1 - t0) * f
		local centre = Egg.Point(lib, a, t, -0.03)
		local normal = Egg.Normal(lib, a, t)
		local forward = Egg.Point(lib, a1, t1, -0.03) - Egg.Point(lib, a0, t0, -0.03)
		local side = forward:Cross(normal).Unit
		rings[i + 1] = {
			centre + side * width + normal * height,
			centre - side * width + normal * height,
			centre - side * width - normal * height,
			centre + side * width - normal * height,
		}
	end
	S:loft(rings, { color = color, caps = caps ~= false })
end

-- A flat star lying on a surface at centre, facing along normal.
function Egg.Star(S, lib, centre, normal, outer, inner, thickness, color)
	local V3 = lib.Vector3
	local helper = math.abs(normal.Y) > 0.95 and V3.new(1, 0, 0) or V3.new(0, 1, 0)
	local u = helper:Cross(normal).Unit
	local v = normal:Cross(u).Unit
	local function ring(scale, lift)
		local points = {}
		for k = 1, 10 do
			local a = (k - 1) / 10 * math.pi * 2 + math.pi / 2
			local r = (if k % 2 == 1 then outer else inner) * scale
			points[k] = centre + normal * lift + (u * math.cos(a) + v * math.sin(a)) * r
		end
		return points
	end
	S:loft({ ring(1, -thickness), ring(0.85, thickness) }, { color = color })
end

function Egg.plain(em, lib, fn)
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

-- A faceted cap over the top with chunky drips down the sides. base is how far down the rim
-- reaches, as a fraction of the egg's height. Each drip is { angle, tip, width }.
function Egg.Cap(S, lib, base, drips, color, outset)
	outset = outset or 0.14
	local V3 = lib.Vector3
	local count = Egg.Sides
	local function columnAngle(k)
		return (k - 1) * 360 / count + 15
	end
	local function edge(k)
		return base + (if k % 2 == 0 then -0.012 else 0.012)
	end
	local lip, rim = {}, {}
	for k = 1, count do
		lip[k] = around(lib, columnAngle(k)) * (Egg.RadiusAt(edge(k)) * 0.95) + V3.new(0, edge(k) * Egg.Height, 0)
		rim[k] = Egg.Point(lib, columnAngle(k), edge(k), outset)
	end
	local rings = { lip, rim }
	for _, t in { (base + 0.82) / 2, 0.82, 0.93 } do
		local ring = {}
		for k = 1, count do
			ring[k] = Egg.Point(lib, columnAngle(k), t, outset)
		end
		table.insert(rings, ring)
	end
	local top = {}
	for k = 1, count do
		top[k] = Egg.Point(lib, columnAngle(k), 0.985, outset * 0.3) + V3.new(0, outset, 0)
	end
	table.insert(rings, top)
	S:loft(rings, { color = color })

	for _, drip in drips do
		local angle, tip, width = drip[1], drip[2], drip[3]
		local a = math.rad(angle)
		local side = V3.new(math.sin(a), 0, math.cos(a))
		local function ring(t, w, thick)
			local centre = Egg.Point(lib, angle, t, 0)
			local out = Egg.Normal(lib, angle, t)
			local points = {}
			for k = 1, 6 do
				local b = (k - 1) / 6 * math.pi * 2
				points[k] = centre + side * (math.cos(b) * w) + out * (math.sin(b) * thick)
			end
			return points
		end
		local length = base - tip
		S:loft({
			ring(tip - 0.012, width * 0.5, 0.07),
			ring(tip + length * 0.12, width * 0.85, 0.13),
			ring(tip + length * 0.6, width * 0.75, 0.13),
			ring(base + 0.04, width * 1.5, 0.08),
		}, { color = color })
	end
end

-- A flat chamfered disc lying on a surface at centre, facing along normal.
function Egg.Disc(S, lib, centre, normal, radius, thickness, color, segs)
	local V3 = lib.Vector3
	segs = segs or 10
	local helper = math.abs(normal.Y) > 0.95 and V3.new(1, 0, 0) or V3.new(0, 1, 0)
	local u = helper:Cross(normal).Unit
	local v = normal:Cross(u).Unit
	local function ring(r, lift)
		local points = {}
		for k = 1, segs do
			local a = (k - 1) / segs * math.pi * 2
			points[k] = centre + normal * lift + (u * math.cos(a) + v * math.sin(a)) * r
		end
		return points
	end
	S:loft({ ring(radius, -thickness), ring(radius * 0.92, thickness) }, { color = color })
end

-- A faceted shape turned around a vertical axis at base. shape = { {radius, y}, ... } bottom to top.
function Egg.Turned(S, lib, base, shape, segs, color)
	local rings = {}
	for i, row in shape do
		local ring = {}
		for k = 1, segs do
			local a = (k - 1) / segs * math.pi * 2
			ring[k] = base + lib.Vector3.new(math.cos(a) * row[1], row[2], -math.sin(a) * row[1])
		end
		rings[i] = ring
	end
	S:loft(rings, { color = color })
end

return Egg
