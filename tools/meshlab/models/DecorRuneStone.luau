--!nocheck
-- Chop a Rock zone decor: rune stone in the JungleTree style (Lineup D #6). A thick upright grey
-- slab in two bands on a low foot, its top rounded by two stepped courses, with a glowing purple
-- rune (a stem and two strokes, like the sheet's) sitting just proud of the front face.
-- ~7 tall, ~3.8 wide. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local stone, stoneDark = C3.fromRGB(135, 135, 135), C3.fromRGB(112, 112, 112)
	local rune = C3.fromRGB(190, 90, 255)

	local w, d = 3.6, 1.4
	S:bevelBox(CF.new(0, 0.3, 0), V3.new(w + 0.6, 0.6, d + 0.6), stoneDark, 0)
	S:bevelBox(CF.new(0, 0.6 + 1.4, 0), V3.new(w, 2.8, d), stoneDark, 0)
	S:bevelBox(CF.new(0, 3.4 + 1.3, 0), V3.new(w, 2.6, d), stone, 0)
	S:bevelBox(CF.new(0, 6.0 + 0.3, 0), V3.new(w - 0.8, 0.6, d), stone, 0)
	S:bevelBox(CF.new(0, 6.6 + 0.2, 0), V3.new(w - 1.8, 0.4, d), stone, 0)

	local face = -d / 2 - 0.04
	local t = 0.4
	S:bevelBox(CF.new(-0.5, 3.6, face), V3.new(t, 3.6, 0.08), rune, 0)
	for _, stroke in { { 4.9, 1.4 }, { 3.9, 1.1 } } do
		local len = stroke[2]
		S:bevelBox(CF.new(-0.5 + math.cos(rad(30)) * len / 2, stroke[1] + math.sin(rad(30)) * len / 2, face) * CF.Angles(0, 0, rad(30)), V3.new(len + t, t, 0.08), rune, 0)
	end

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
