--!nocheck
-- Chop a Rock zone decor: snow pile in the JungleTree style (Lineup B #6). Three or four lumps,
-- each a small pad of crossed courses: an ice blue base course, white courses stepping in above.
-- ~7 wide, ~2.6 tall. lib.seed varies the clump. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local snow, snowDark, ice = C3.fromRGB(250, 252, 255), C3.fromRGB(228, 240, 255), C3.fromRGB(150, 205, 255)
	local function cross(cf, w, h, col)
		S:bevelBox(cf, V3.new(w, h, w * 0.75), col, 0)
		S:bevelBox(cf, V3.new(w * 0.75, h + 0.02, w), col, 0)
	end
	local function lump(x, z, w, h)
		local r = CF.Angles(0, rand(-0.5, 0.5), 0)
		local h0 = h * 0.35
		cross(CF.new(x, h0 / 2, z) * r, w, h0, ice)
		cross(CF.new(x, h0 + (h - h0) * 0.3, z) * r, w * 0.82, (h - h0) * 0.6, snow)
		cross(CF.new(x, h0 + (h - h0) * 0.8, z) * r, w * 0.55, (h - h0) * 0.4, snowDark)
	end

	lump(0, 0, rand(3.8, 4.2), 2.6)
	local n = 2 + math.floor(rand(0, 2))
	local a0 = rand(0, math.pi * 2)
	for k = 0, n - 1 do
		local a = a0 + k / n * math.pi * 2 + rand(-0.4, 0.4)
		local rr = rand(1.9, 2.4)
		lump(math.cos(a) * rr, math.sin(a) * rr * 0.7, rand(2.5, 3.1), rand(1.5, 1.9))
	end

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.5, sky = 0.22 })
	Shapes.PITCH = pitch
end
