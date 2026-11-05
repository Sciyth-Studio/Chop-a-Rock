--!nocheck

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local stone, stoneDark = C3.fromRGB(222, 192, 132), C3.fromRGB(196, 166, 110)
	local moss, mossDark = C3.fromRGB(110, 175, 55), C3.fromRGB(90, 150, 45)

	local colWidth = 2.3
	local radius = colWidth / 2

	local function cross(cf, w, h, col)
		S:bevelBox(cf, V3.new(w, h, w * 0.75), col, 0)
		S:bevelBox(cf, V3.new(w * 0.75, h - 0.14, w), col, 0)
	end

	local baseX = -4.0
	S:bevelBox(CF.new(baseX, 0.5, 0), V3.new(3.8, 1.0, 3.8), stoneDark, 0)
	S:bevelBox(CF.new(baseX, 1.25, 0), V3.new(3.2, 0.5, 3.2), stone, 0)
	cross(CF.new(baseX, 1.75, 0), 2.8, 0.5, stoneDark)
	cross(CF.new(baseX, 2.7, 0), colWidth, 1.4, stone)
	cross(CF.new(baseX, 3.9, 0), colWidth, 1.0, stoneDark)
	for _, b in { { -0.55, -0.3, 1.3, 1.0 }, { 0.5, 0.35, 0.8, 0.9 }, { 0.6, -0.55, 0.4, 0.7 } } do
		S:bevelBox(CF.new(baseX + b[1], 4.4 + b[3] / 2, b[2]), V3.new(b[4], b[3], b[4]), stone, 0)
	end

	local function drum(x, z, yaw, tilt, length, y, col)
		local cf = CF.new(x, y, z) * CF.Angles(0, rad(yaw), rad(90 + tilt))
		cross(cf, colWidth, length, col)
		return cf
	end

	drum(-0.8, -0.15, 4, 0, 2.5, radius, stone)
	drum(1.75, 0.1, -3, 0, 2.3, radius, stoneDark)
	drum(4.0, -0.35, -13, 0, 1.9, radius, stone)
	S:bevelBox(CF.new(5.1, 1.5, -0.6) * CF.Angles(0, rad(-13), 0), V3.new(0.5, 1.2, 0.9), stoneDark, 0)
	S:bevelBox(CF.new(5.05, 0.7, 0.0) * CF.Angles(0, rad(-13), 0), V3.new(0.5, 0.9, 0.8), stoneDark, 0)

	S:bevelBox(CF.new(-1.0, colWidth + 0.05, -0.15) * CF.Angles(0, rad(4), 0), V3.new(1.5, 0.14, 1.2), moss, 0)
	S:bevelBox(CF.new(1.5, colWidth + 0.05, 0.1) * CF.Angles(0, rad(-3), 0), V3.new(1.1, 0.14, 0.9), mossDark, 0)
	S:bevelBox(CF.new(baseX + 0.4, 1.05, 1.74), V3.new(1.4, 0.14, 0.28), moss, 0)
	S:bevelBox(CF.new(baseX - 0.5, 4.45, 0.6), V3.new(1.0, 0.14, 0.8), mossDark, 0)

	S:bevelBox(CF.new(0.2, 0.35, -2.0) * CF.Angles(0, rad(30), 0), V3.new(1.2, 0.7, 1.0), stoneDark, 0)
	S:bevelBox(CF.new(2.8, 0.3, 1.9) * CF.Angles(0, rad(-25), 0), V3.new(1.0, 0.6, 0.9), stone, 0)
	S:bevelBox(CF.new(3.0, 0.1, -1.9), V3.new(1.8, 0.2, 1.1), moss, 0)

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
