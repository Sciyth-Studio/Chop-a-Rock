--!nocheck
-- Chop a Rock zone decor: toppled stone statue head in the JungleTree style (Lineup D #5). A tall
-- blocky head with a heavy brow, closed-eye slits, a long flat nose, ears and a chin, lying on its
-- side tipped 70 degrees with its face to the front, on a rubble block, moss on the top side and
-- on the ground. An old statue, not a monster. ~5.6 tall, ~6 long. Studs 1 per stud.
-- Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local stone, stoneDark, carve = C3.fromRGB(212, 205, 188), C3.fromRGB(186, 178, 160), C3.fromRGB(140, 134, 120)
	local moss, mossDark = C3.fromRGB(110, 175, 55), C3.fromRGB(90, 150, 45)

	local hw, hh, hd = 3.4, 4.6, 3.0
	local lean = rad(-38)
	local reach = math.abs(math.sin(lean)) * hh / 2 + math.abs(math.cos(lean)) * hw / 2
	local root = CF.new(0.4, reach - 0.35, 0) * CF.Angles(0, rad(-10), lean) * CF.Angles(rad(12), 0, 0)
	local function head(offset, size, col)
		S:bevelBox(root * offset, size, col, 0)
	end
	local front = -hd / 2

	head(CF.new(0, -0.2, 0), V3.new(hw, hh - 0.4, hd), stone)
	head(CF.new(0, hh / 2 - 0.3, 0.1), V3.new(hw - 0.4, 0.6, hd - 0.4), stoneDark)
	head(CF.new(0, -hh / 2 + 0.1, front + 0.9), V3.new(hw - 1.0, 0.6, 1.4), stoneDark)
	head(CF.new(0, 1.05, front - 0.3), V3.new(hw + 0.1, 0.7, 0.7), stoneDark)
	for _, side in { -1, 1 } do
		head(CF.new(side * 0.85, 0.4, front - 0.04), V3.new(1.0, 0.3, 0.1), carve)
		head(CF.new(side * (hw / 2 + 0.2), 0.1, 0.2), V3.new(0.5, 2.0, 1.0), stoneDark)
	end
	head(CF.new(0, -0.2, front - 0.5), V3.new(1.0, 2.2, 1.0), stoneDark)
	head(CF.new(0, -1.15, front - 0.75), V3.new(1.2, 0.4, 0.5), stoneDark)
	head(CF.new(0, -1.65, front - 0.04), V3.new(1.6, 0.25, 0.1), carve)

	head(CF.new(hw / 2 + 0.06, 0.4, 0.2), V3.new(0.12, 2.6, hd - 0.4), moss)
	head(CF.new(hw / 2 + 0.06, -1.0, -0.6), V3.new(0.14, 1.0, 1.2), mossDark)
	head(CF.new(0.3, hh / 2 + 0.06, 0.2), V3.new(2.6, 0.2, 2.4), moss)
	head(CF.new(0.9, hh / 2 + 0.2, 0.4), V3.new(1.4, 0.2, 1.4), mossDark)

	S:bevelBox(CF.new(-1.8, 0.45, 0.3) * CF.Angles(0, rad(15), 0), V3.new(1.8, 0.9, 2.2), stoneDark, 0)
	S:bevelBox(CF.new(2.9, 0.15, -0.6), V3.new(1.6, 0.3, 1.4), moss, 0)
	S:bevelBox(CF.new(-2.4, 0.12, -1.2) * CF.Angles(0, rad(30), 0), V3.new(1.2, 0.24, 0.9), mossDark, 0)

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
