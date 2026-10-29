--!nocheck
-- Chop a Rock zone decor: mossy stone in the JungleTree style (Lineup D #2). A low grey boulder of
-- three crossed courses, each turned 15 degrees so it reads faceted, under a thick moss cap of two
-- courses with moss drips hanging down the sides. ~3.4 tall, ~6.5 wide. Moss sits near the bamboo
-- floor green (120, 150, 90). lib.seed varies the drips. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local stone, stoneDark = C3.fromRGB(150, 150, 150), C3.fromRGB(125, 125, 125)
	local moss, mossDark = C3.fromRGB(126, 162, 80), C3.fromRGB(106, 140, 66)
	local function cross(cf, w, h, col)
		S:bevelBox(cf, V3.new(w, h, w * 0.7), col, 0)
		S:bevelBox(cf, V3.new(w * 0.8, h + 0.02, w * 0.85), col, 0)
	end

	cross(CF.new(0, 0.5, 0), 6.0, 1.0, stoneDark)
	cross(CF.new(0.1, 1.45, 0) * CF.Angles(0, rad(15), 0), 5.8, 0.9, stone)
	cross(CF.new(0, 2.25, 0.1) * CF.Angles(0, rad(-15), 0), 5.2, 0.7, stoneDark)
	cross(CF.new(0, 2.85, 0) * CF.Angles(0, rad(5), 0), 4.9, 0.55, moss)
	cross(CF.new(0.2, 3.25, -0.1) * CF.Angles(0, rad(20), 0), 3.4, 0.35, mossDark)

	for k = 0, 6 do
		local a = k / 7 * math.pi * 2 + rand(-0.2, 0.2)
		local rx, rz = 2.45, 1.85
		local len = rand(1.0, 1.9)
		S:bevelBox(CF.new(math.cos(a) * rx, 3.0 - len / 2, math.sin(a) * rz) * CF.Angles(0, -a, 0), V3.new(0.45, len, rand(0.6, 1.0)), k % 2 == 0 and moss or mossDark, 0)
	end

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
