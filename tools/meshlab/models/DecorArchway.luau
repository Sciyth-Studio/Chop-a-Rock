--!nocheck

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local stone, stoneDark = C3.fromRGB(222, 192, 132), C3.fromRGB(196, 166, 110)
	local moss, mossDark = C3.fromRGB(110, 175, 55), C3.fromRGB(90, 150, 45)
	local vine, leaf = C3.fromRGB(55, 135, 45), C3.fromRGB(75, 165, 55)

	local depth = 2.4
	local legWidth = 1.7
	local legX = 3.1
	local legTop = 5.6

	local function leg(x, top)
		S:bevelBox(CF.new(x, 0.45, 0), V3.new(legWidth + 0.8, 0.9, depth + 0.8), stoneDark, 0)
		local y = 0.9
		local i = 0
		while y < top - 0.01 do
			local h = math.min(1.2, top - y)
			local inset = if i % 2 == 0 then 0 else 0.14
			S:bevelBox(
				CF.new(x, y + h / 2, 0),
				V3.new(legWidth - inset, h + 0.02, depth - inset),
				i % 2 == 0 and stone or stoneDark,
				0
			)
			y += h
			i += 1
		end
	end

	leg(-legX, legTop)
	leg(legX, 3.3)
	S:bevelBox(CF.new(legX - 0.35, 3.65, -0.3), V3.new(0.9, 0.7, 1.3), stone, 0)
	S:bevelBox(CF.new(legX + 0.4, 3.5, 0.55), V3.new(0.7, 0.4, 1.0), stoneDark, 0)

	local radius = legX
	local angles = { 172, 150, 128, 106, 84 }
	for i, a in angles do
		local t = rad(a)
		local cf = CF.new(math.cos(t) * radius, legTop + math.sin(t) * radius, 0) * CF.Angles(0, 0, t)
		local tangent = if i == #angles then 1.0 else 1.5
		local inset = if i % 2 == 0 then 0.14 else 0
		S:bevelBox(cf, V3.new(legWidth - inset, tangent, depth - inset), i % 2 == 0 and stoneDark or stone, 0)
	end
	local tipAngle = rad(70)
	S:bevelBox(
		CF.new(math.cos(tipAngle) * radius, legTop + math.sin(tipAngle) * radius, -0.35) * CF.Angles(0, 0, tipAngle),
		V3.new(1.0, 0.8, 1.2),
		stone,
		0
	)

	for _, a in { 150, 128, 106 } do
		local t = rad(a)
		local top = radius + legWidth / 2 + 0.06
		S:bevelBox(
			CF.new(math.cos(t) * top, legTop + math.sin(t) * top, 0.1) * CF.Angles(0, 0, t),
			V3.new(0.14, 1.5, depth - 0.5),
			a == 128 and mossDark or moss,
			0
		)
	end

	local vineSteps = {
		V3.new(-legX - 0.95, 1.0, -0.5),
		V3.new(-legX - 0.95, 2.4, 0.5),
		V3.new(-legX - 0.95, 3.8, -0.3),
		V3.new(-legX - 0.95, 5.2, 0.4),
		V3.new(-legX - 0.75, 6.4, -0.1),
	}
	for i = 1, #vineSteps - 1 do
		local from, to = vineSteps[i], vineSteps[i + 1]
		local dir = (to - from).Unit
		P.limb(S, lib, from - dir * 0.1, dir, (to - from).Magnitude + 0.2, if i % 2 == 0 then 0.22 else 0.3, vine)
		S:bevelBox(P.lookAt(lib, to + V3.new(-0.35, 0.1, 0), V3.new(-1, 0.3, 0).Unit), V3.new(0.55, 0.12, 0.7), leaf, 0)
	end

	S:bevelBox(CF.new(0.9, 0.4, -0.5) * CF.Angles(0, rad(25), 0), V3.new(1.6, 0.8, 1.3), stoneDark, 0)
	S:bevelBox(CF.new(1.1, 1.15, -0.4) * CF.Angles(0, rad(-15), rad(12)), V3.new(0.9, 0.6, 0.9), stone, 0)
	S:bevelBox(CF.new(-0.6, 0.3, 0.7) * CF.Angles(0, rad(50), 0), V3.new(1.0, 0.6, 0.9), stone, 0)
	S:bevelBox(CF.new(0.2, 0.1, -0.9), V3.new(1.6, 0.2, 1.1), moss, 0)

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
