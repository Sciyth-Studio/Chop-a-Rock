--!nocheck
-- Chop a Rock training stand, raw crystal family (Amethyst, Emerald, Sapphire, Ruby, Painite): one shape.
-- Frame: rough low-poly stone posts on chunky stone feet. Breakable: a rough stone slab across the post tops (Slab,
-- tagged TrainingBoard) with a cluster of leaning hexagonal crystal points on it as its prop child (Crystals, plain,
-- Neon or glowing in Studio). Each crystal belongs to the half its base sits in, so the split keeps them whole.
-- Front faces -Z, pivot bottom centre, 5.5 wide, slab centre 3.68 up. Seeds: see StandKit.
local Kit = require("./StandKit")

return function(em, lib, Shapes, part)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rgb = C3.fromRGB
	local rad = math.rad
	local palettes = {
		{ stone = rgb(118, 118, 124), crystal = rgb(150, 70, 230) },
		{ stone = rgb(92, 94, 98), crystal = rgb(40, 200, 110) },
		{ stone = rgb(92, 106, 126), crystal = rgb(40, 110, 240) },
		{ stone = rgb(82, 80, 82), crystal = rgb(235, 50, 60) },
		{ stone = rgb(40, 38, 40), crystal = rgb(235, 95, 40) },
	}
	local postX = 1.86
	local slabY, slabH = 3.14, 1.08
	local rough = Kit.Rough(lib, 0.07, 3)

	local crystals = {
		{ 0.2, 0.0, 1.9, 0.44, 0, 0 },
		{ -0.75, 0.08, 1.3, 0.32, -14, 4 },
		{ -1.35, -0.1, 1.0, 0.27, -26, -4 },
		{ -1.95, 0.1, 0.72, 0.22, -38, 4 },
		{ 0.98, 0.1, 1.25, 0.31, 15, 4 },
		{ 1.55, -0.1, 0.95, 0.26, 27, -4 },
		{ 2.08, 0.06, 0.68, 0.21, 38, 0 },
		{ -0.35, -0.38, 0.85, 0.23, -6, -16 },
		{ 0.62, 0.36, 0.85, 0.23, 8, 16 },
	}

	local function crystal(S, base, h, r, lean, tilt, color)
		local cf = CF.new(base) * CF.Angles(rad(tilt), 0, rad(-lean))
		local rings = {}
		for _, k in { { -0.3, 1 }, { h * 0.72, 1 }, { h, 0.08 } } do
			local ring = {}
			for i = 0, 5 do
				local a = i * math.pi / 3 + math.pi / 6
				table.insert(ring, cf * V3.new(math.cos(a) * r * k[2], k[1], math.sin(a) * r * k[2]))
			end
			table.insert(rings, ring)
		end
		S:loft(rings, { color = color })
	end

	Kit.Run(lib, Shapes, part, palettes, {
		frame = function(new, o, pal)
			local S = new("Frame")
			for _, sx in { -1, 1 } do
				local x = o.X + sx * postX
				Kit.Stack(S, lib, x, o.Z, {
					{ 0, 1.0, 0.95, 0.22 },
					{ 0.85, 0.98, 0.92, 0.24 },
					{ 1.22, 0.74, 0.7, 0.26 },
				}, pal.stone, nil, nil, rough)
				Kit.Stack(S, lib, x, o.Z, {
					{ 1.15, 0.5, 0.5, 0.12 },
					{ 2.2, 0.47, 0.48, 0.12 },
					{ slabY + 0.02, 0.5, 0.5, 0.12 },
				}, pal.stone, nil, nil, rough)
			end
		end,
		breakable = function(new, o, pal, x0, x1)
			local S = new("Slab")
			Kit.Stack(S, lib, o.X, o.Z, {
				{ o.Y + slabY, 2.48, 0.6, 0.15 },
				{ o.Y + slabY + 0.16, 2.56, 0.66, 0.22 },
				{ o.Y + slabY + slabH - 0.14, 2.56, 0.66, 0.22 },
				{ o.Y + slabY + slabH, 2.38, 0.54, 0.24 },
			}, pal.stone, x0, x1, function(v)
				return rough(v - V3.new(o.X, o.Y, o.Z)) + V3.new(o.X, o.Y, o.Z)
			end)
			local C = new("Crystals")
			Kit.Plain(C, lib, function()
				for _, c in crystals do
					if c[1] >= x0 and c[1] < x1 then
						crystal(C, V3.new(o.X + c[1], o.Y + slabY + slabH, o.Z + c[2]), c[3], c[4], c[5], c[6], pal.crystal)
					end
				end
			end)
		end,
	})
end
