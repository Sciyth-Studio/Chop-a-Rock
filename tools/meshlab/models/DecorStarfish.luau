--!nocheck
-- Chop a Rock zone decor: starfish in the JungleTree style (Lineup B #5). A chunky yellow
-- five-point star lying on the ground: a crossed centre pad in two courses, thick arms in two
-- tapering steps, white dots along the top (yellow, not orange: orange is the ocean Roks'
-- colour). ~4.6 across, ~1 tall. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local body, bodyDark, dot = C3.fromRGB(255, 205, 30), C3.fromRGB(245, 180, 20), C3.fromRGB(250, 250, 250)
	S:bevelBox(CF.new(0, 0.35, 0), V3.new(1.8, 0.7, 1.4), body, 0)
	S:bevelBox(CF.new(0, 0.35, 0), V3.new(1.4, 0.72, 1.8), body, 0)
	S:bevelBox(CF.new(0, 0.85, 0), V3.new(1.0, 0.3, 0.8), bodyDark, 0)
	S:bevelBox(CF.new(0, 0.85, 0), V3.new(0.8, 0.32, 1.0), bodyDark, 0)
	S:bevelBox(CF.new(0, 1.03, 0), V3.new(0.4, 0.06, 0.4), dot, 0)

	for k = 0, 4 do
		local arm = CF.Angles(0, rad(180 + k * 72), 0)
		S:bevelBox(arm * CF.new(0, 0.3, -1.3), V3.new(1.2, 0.6, 1.3), body, 0)
		S:bevelBox(arm * CF.new(0, 0.2, -2.3), V3.new(0.75, 0.4, 1.0), bodyDark, 0)
		S:bevelBox(arm * CF.new(0, 0.63, -1.35), V3.new(0.35, 0.06, 0.35), dot, 0)
		S:bevelBox(arm * CF.new(0, 0.43, -2.25), V3.new(0.25, 0.06, 0.25), dot, 0)
	end

	Shapes.finishBake(lib, { distance = 1.0, strength = 0.5, sky = 0.22 })
	Shapes.PITCH = pitch
end
