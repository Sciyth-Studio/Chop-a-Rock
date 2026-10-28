--!nocheck
-- Chop a Rock zone decor: tree stump in the JungleTree style (Lineup A #3). A crossed-box trunk
-- cut low, in two bark bands, on four buttress-root fins, with a light tan cut top and a ring.
-- ~5 wide, ~2.4 tall. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local bark, barkDark = C3.fromRGB(120, 70, 30), C3.fromRGB(100, 58, 24)
	local cut, ring = C3.fromRGB(235, 190, 120), C3.fromRGB(205, 150, 85)
	local function cross(y, h, w, col)
		S:bevelBox(CF.new(0, y + h / 2, 0), V3.new(w, h, w * 0.75), col, 0)
		S:bevelBox(CF.new(0, y + h / 2, 0), V3.new(w * 0.75, h, w), col, 0)
	end

	cross(0, 1.1, 3.2, barkDark)
	cross(1.1, 1.1, 3.0, bark)
	cross(2.2, 0.1, 2.8, cut)
	cross(2.3, 0.05, 1.8, ring)
	cross(2.35, 0.05, 1.3, cut)

	for k = 0, 3 do
		local a = rad(45 + k * 90)
		local d = V3.new(math.sin(a), 0, math.cos(a))
		local rot = CF.Angles(0, a, 0)
		S:bevelBox(CF.new(d.X * 1.8, 0.75, d.Z * 1.8) * rot, V3.new(0.55, 1.5, 1.3), barkDark, 0)
		S:bevelBox(CF.new(d.X * 2.6, 0.3, d.Z * 2.6) * rot, V3.new(0.55, 0.6, 1.0), barkDark, 0)
	end

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
