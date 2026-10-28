--!nocheck
-- Chop a Rock zone decor: mushroom in the JungleTree style (Lineup A #4). Chunky crossed-box stem
-- in two cream bands on a flared foot, a wide cap of three crossed courses in alternating reds
-- with a cream underside, white spots on the cap steps and sides. ~5.6 wide, ~5.3 tall.
-- Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local stem, stemDark, gill = C3.fromRGB(250, 235, 195), C3.fromRGB(235, 215, 170), C3.fromRGB(230, 210, 165)
	local red, redDark, white = C3.fromRGB(235, 25, 30), C3.fromRGB(205, 20, 25), C3.fromRGB(250, 250, 250)
	local function cross(y, h, w, col)
		S:bevelBox(CF.new(0, y + h / 2, 0), V3.new(w, h, w * 0.75), col, 0)
		S:bevelBox(CF.new(0, y + h / 2, 0), V3.new(w * 0.75, h, w), col, 0)
	end

	cross(0, 0.5, 2.6, stemDark)
	cross(0.5, 1.4, 2.0, stem)
	cross(1.9, 1.3, 1.8, stemDark)
	cross(3.2, 0.2, 4.8, gill)
	cross(3.3, 0.9, 5.6, red)
	cross(4.2, 0.7, 4.2, redDark)
	cross(4.9, 0.4, 2.6, red)

	local spot = 0.9
	for _, p in { { 1.6, 4.2, 0.6 }, { -1.3, 4.2, -1.3 }, { 0, 5.3, 0 }, { -0.6, 4.9, 1.4 } } do
		S:bevelBox(CF.new(p[1], p[2] + 0.04, p[3]), V3.new(spot, 0.08, spot), white, 0)
	end
	local half = 5.6 / 2
	for _, d in { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } } do
		local x, z = d[1] * (half + 0.04), d[2] * (half + 0.04)
		local sx, sz = d[1] ~= 0 and 0.08 or spot, d[2] ~= 0 and 0.08 or spot
		S:bevelBox(CF.new(x + d[2] * 0.6, 3.75, z - d[1] * 0.6), V3.new(sx, 0.6, sz), white, 0)
	end

	Shapes.finishBake(lib, { distance = 1.8, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
