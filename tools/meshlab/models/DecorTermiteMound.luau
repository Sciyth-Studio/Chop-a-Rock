--!nocheck
-- Chop a Rock zone decor: termite mound in the JungleTree style (Lineup C #6). A wide lumpy base
-- of crossed courses, rising into two chimney towers of different heights, each a stack of
-- shrinking crossed courses that jog a little, with a dark hole on top. ~8.5 tall, ~6.5 wide.
-- lib.seed varies the lumps. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local clay, clayDark, hole = C3.fromRGB(215, 110, 50), C3.fromRGB(190, 92, 40), C3.fromRGB(95, 45, 20)
	local function cross(cf, w, h, col)
		S:bevelBox(cf, V3.new(w, h, w * 0.78), col, 0)
		S:bevelBox(cf, V3.new(w * 0.78, h + 0.02, w), col, 0)
	end

	local y = 0
	for i, w in { 6.6, 5.6, 4.6 } do
		local h = 1.2
		cross(CF.new(rand(-0.2, 0.2), y + h / 2, rand(-0.2, 0.2)) * CF.Angles(0, rad(15 * i), 0), w, h, i % 2 == 1 and clayDark or clay)
		y += h
	end
	for k = 0, 2 do
		local a = rand(0, math.pi * 2)
		cross(CF.new(math.cos(a) * 2.6, 0.5, math.sin(a) * 2.0) * CF.Angles(0, a, 0), 2.0, 1.0, clay)
	end

	local function tower(x, z, height, w0)
		local ty = y
		local n = math.floor((height - y) / 1.1)
		local cx, cz = x, z
		for i = 0, n - 1 do
			local w = w0 - (w0 - w0 * 0.55) * i / math.max(1, n - 1)
			cx += rand(-0.12, 0.12)
			cz += rand(-0.12, 0.12)
			cross(CF.new(cx, ty + 0.55, cz) * CF.Angles(0, rad(15 * (i % 3)), 0), w, 1.1, i % 2 == 0 and clay or clayDark)
			ty += 1.1
		end
		S:bevelBox(CF.new(cx, ty + 0.02, cz), V3.new(w0 * 0.3, 0.06, w0 * 0.3), hole, 0)
	end
	tower(-0.8, 0.1, 8.6, 3.0)
	tower(1.4, -0.2, 6.4, 2.4)

	Shapes.finishBake(lib, { distance = 1.8, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
