--!nocheck
-- Chop a Rock training stand, Meteorite (space finale one-off).
-- Frame: two tapered dark posts on chamfered feet joined by a low crossbar, each topped by a heavy chamfered clamp
-- that grips the rock's ends. Breakable: a lumpy meteorite made of chipped rock chunks (Rock, tagged TrainingBoard)
-- around a glowing core that shows through the gaps as lava cracks (Lava, its prop child, plain, Neon in Studio).
-- Each chunk belongs to the half its centre sits in. Front faces -Z, pivot bottom centre, 5.5 wide, rock centre 3.7 up.
local Kit = require("./StandKit")

return function(em, lib, Shapes, part)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rgb = C3.fromRGB
	local palettes = { { frame = rgb(72, 68, 72), rock = rgb(60, 54, 54), lava = rgb(255, 122, 30) } }
	local postX = 1.95

	local function hash(i, k)
		local n = math.sin(i * 91.7 + k * 17.3) * 43758.5453
		return n - math.floor(n)
	end
	local chunks = {}
	for i, c in {
		{ -1.3, 3.25, -0.38, 0.62 }, { -1.3, 3.25, 0.38, 0.6 }, { -0.45, 3.2, -0.42, 0.7 }, { -0.45, 3.2, 0.42, 0.68 },
		{ 0.45, 3.2, -0.42, 0.7 }, { 0.45, 3.2, 0.42, 0.68 }, { 1.3, 3.25, -0.38, 0.62 }, { 1.3, 3.25, 0.38, 0.6 },
		{ -1.25, 3.95, -0.3, 0.55 }, { -1.25, 3.95, 0.32, 0.52 }, { -0.4, 4.15, -0.32, 0.66 }, { -0.4, 4.15, 0.34, 0.62 },
		{ 0.42, 4.2, -0.3, 0.68 }, { 0.42, 4.2, 0.34, 0.6 }, { 1.25, 3.95, -0.3, 0.55 }, { 1.25, 3.95, 0.32, 0.52 },
	} do
		chunks[i] = c
	end

	local function chunk(S, i, centre, r, color)
		local rot = CF.new(centre) * CF.Angles(hash(i, 1) * 0.6, hash(i, 2) * 6.28, hash(i, 3) * 0.6)
		local rings = {}
		for k, layer in { { -0.75, 0.62 }, { -0.1, 1 }, { 0.6, 0.66 } } do
			local ring = {}
			for s = 0, 5 do
				local a = s / 6 * math.pi * 2
				local rr = r * layer[2] * (0.82 + 0.36 * hash(i * 7 + k, s))
				table.insert(ring, rot * V3.new(math.cos(a) * rr, layer[1] * r, math.sin(a) * rr * 0.9))
			end
			table.insert(rings, ring)
		end
		S:loft(rings, { color = color })
	end

	Kit.Run(lib, Shapes, part, palettes, {
		frame = function(new, o, pal)
			local S = new("Frame")
			local c = pal.frame
			for _, sx in { -1, 1 } do
				local x = o.X + sx * postX
				Kit.Stack(S, lib, x, o.Z, {
					{ 0, 0.95, 1.05, 0.2 },
					{ 0.55, 0.95, 1.05, 0.2 },
					{ 1.05, 0.66, 0.74, 0.22 },
				}, c)
				Kit.Stack(S, lib, x, o.Z, {
					{ 1.0, 0.52, 0.55, 0.1 },
					{ 2.85, 0.44, 0.48, 0.1 },
				}, c)
				Kit.Stack(S, lib, x + sx * 0.05, o.Z, {
					{ 2.75, 0.5, 0.72, 0.18 },
					{ 2.95, 0.62, 0.86, 0.22 },
					{ 4.4, 0.62, 0.86, 0.22 },
					{ 4.62, 0.48, 0.7, 0.2 },
				}, c)
			end
			S:bevelBox(CF.new(o.X, 0.3, o.Z), V3.new(2.6, 0.5, 0.9), c, 0.06)
		end,
		breakable = function(new, o, pal, x0, x1)
			local S = new("Rock")
			for i, c in chunks do
				if c[1] >= x0 and c[1] < x1 then
					chunk(S, i, V3.new(o.X + c[1], o.Y + c[2], o.Z + c[3]), c[4], pal.rock)
				end
			end
			local L = new("Lava")
			Kit.Plain(L, lib, function()
				Kit.Stack(L, lib, o.X, o.Z, {
					{ o.Y + 2.8, 1.45, 0.55, 0.3 },
					{ o.Y + 3.35, 1.62, 0.7, 0.35 },
					{ o.Y + 4.05, 1.55, 0.66, 0.35 },
					{ o.Y + 4.5, 1.05, 0.42, 0.3 },
				}, pal.lava, x0, x1)
			end)
		end,
	})
end
