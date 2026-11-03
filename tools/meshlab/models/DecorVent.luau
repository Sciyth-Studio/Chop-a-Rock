--!nocheck
-- Chop a Rock zone decor: smoking volcano vent in the JungleTree style (Lineup D #3). A charcoal
-- cone of four shrinking crossed courses, the top course a ring around a hole that glows lava
-- orange with a hotter centre, and rock flanks on the slopes. The smoke is a particle emitter
-- added in Studio. ~4.2 tall, ~7 wide. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local rock, rockDark = C3.fromRGB(90, 85, 82), C3.fromRGB(72, 68, 66)
	local lava, lavaHot = C3.fromRGB(255, 110, 20), C3.fromRGB(255, 190, 50)
	local function cross(cf, w, h, col)
		S:bevelBox(cf, V3.new(w, h, w * 0.78), col, 0)
		S:bevelBox(cf, V3.new(w * 0.78, h + 0.02, w), col, 0)
	end

	cross(CF.new(0, 0.5, 0), 7.0, 1.0, rockDark)
	cross(CF.new(0, 1.5, 0) * CF.Angles(0, rad(15), 0), 5.6, 1.0, rock)
	cross(CF.new(0, 2.5, 0), 4.4, 1.0, rockDark)

	local hole, outer, h, y = 2.2, 3.8, 1.2, 3.0
	local band = (outer - hole) / 2
	for k = 0, 3 do
		local r = CF.new(0, y + h / 2, 0) * CF.Angles(0, rad(k * 90), 0)
		S:bevelBox(r * CF.new(0, 0, -(hole / 2 + band / 2)), V3.new(outer - band, h, band), k % 2 == 0 and rock or rockDark, 0)
	end
	S:bevelBox(CF.new(0, y + h * 0.75, 0), V3.new(hole + 0.1, 0.1, hole + 0.1), lava, 0)
	S:bevelBox(CF.new(0, y + h * 0.75 + 0.06, 0), V3.new(hole * 0.55, 0.05, hole * 0.55), lavaHot, 0)

	for k = 0, 4 do
		local a = rad(20 + k * 72)
		local d = V3.new(math.sin(a), 0, math.cos(a))
		S:bevelBox(CF.new(d.X * 2.9, 0.9, d.Z * 2.9) * CF.Angles(0, a, 0), V3.new(1.4, 1.8, 1.6), k % 2 == 0 and rock or rockDark, 0)
	end

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
