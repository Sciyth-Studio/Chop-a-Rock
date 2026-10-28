--!nocheck
-- Chop a Rock zone decor: bush in the JungleTree style (Lineup A #2). Four or five lumps, each a
-- small canopy pad: two crossed courses, the top one narrower and in the other shade, clumped
-- wider than tall: ~6 wide, ~3.5 tall. Greens sit close to the forest floor (39, 70, 45);
-- opts.jungle (DecorJungleBush) uses greens close to the jungle floor (50, 130, 40).
-- lib.seed varies the clump. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes, _, opts)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local jungle = opts and opts.jungle
	local leaf = jungle and C3.fromRGB(48, 128, 40) or C3.fromRGB(40, 78, 46)
	local patch = jungle and C3.fromRGB(62, 152, 50) or C3.fromRGB(52, 96, 56)
	local function cross(cf, w, h, col)
		S:bevelBox(cf, V3.new(w, h, w * 0.78), col, 0)
		S:bevelBox(cf, V3.new(w * 0.78, h + 0.02, w), col, 0)
	end
	local function lump(x, z, w, h, first)
		local r = CF.Angles(0, rand(-0.4, 0.4), 0)
		local h1 = h * 0.6
		cross(CF.new(x, h1 / 2, z) * r, w, h1, first)
		cross(CF.new(x, h1 + (h - h1) / 2, z) * r, w * 0.68, h - h1, first == leaf and patch or leaf)
	end

	lump(0, 0, rand(3.4, 3.8), rand(3.0, 3.4), leaf)
	local n = 3 + math.floor(rand(0, 2))
	local a0 = rand(0, math.pi * 2)
	for k = 0, n - 1 do
		local a = a0 + k / n * math.pi * 2 + rand(-0.3, 0.3)
		local rr = rand(1.6, 2.1)
		lump(math.cos(a) * rr, math.sin(a) * rr * 0.8, rand(2.2, 2.8), rand(1.8, 2.4), k % 2 == 0 and patch or leaf)
	end

	Shapes.finishBake(lib, { distance = 2.0, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
