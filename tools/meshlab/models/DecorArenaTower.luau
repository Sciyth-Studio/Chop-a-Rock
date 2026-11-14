--!nocheck
-- Chop a Rock Boss Arena: corner tower (assets/Arena/LineupA.webp #1) in the JungleTree stud-block
-- style. Wide dark plinth, a gently tapering shaft of round courses in two light greys, two dark
-- bands, a jutting dark top rim with eight merlons, and the coal fire bowl on top. Built at world
-- size: ~32 wide at the foot, ~66 tall to the coals. Studs 1 per stud. Base on Y = 0, front -Z.

local Arena = require("./ArenaParts")

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	local S = Shapes.new(em, lib)
	local c = Arena.Colors(C3)
	local k = Arena.Kit(S, lib)

	local y = 0
	local function course(w, h, col)
		k.round(CF.new(0, y + h / 2, 0), w, h, col)
		y += h
	end

	course(33, 2.5, c.stoneDeep)
	course(30.5, 2.5, c.stoneDark)
	local shaft = { 26.5, 26.2, 25.8, "band", 25.4, 25.0, 24.6, 24.2, "band", 23.8, 23.5, 23.2 }
	local light = true
	for _, entry in shaft do
		if entry == "band" then
			course(28, 3.4, c.stoneDark)
		else
			course(entry, 3.6, if light then c.stone else c.stoneLight)
			light = not light
		end
	end
	course(27, 1.4, c.stoneDeep)
	course(30, 3.2, c.stoneDark)
	local rimTop = y
	course(23, 1.0, c.stoneDeep)

	for i = 0, 7 do
		local a = math.rad(i * 45 + 22.5)
		local r = 12.3
		k.block(
			CF.new(math.cos(a) * r, rimTop + 2.6, math.sin(a) * r) * CF.Angles(0, -a + math.pi / 2, 0),
			V3.new(6.2, 5.2, 3.4),
			if i % 2 == 0 then c.stone else c.stoneLight
		)
		k.block(
			CF.new(math.cos(a) * r, rimTop + 5.35, math.sin(a) * r) * CF.Angles(0, -a + math.pi / 2, 0),
			V3.new(6.6, 0.5, 3.8),
			c.stoneDark
		)
	end

	course(12, 2.6, c.stoneDark)
	course(9, 1.6, c.stoneDeep)
	Arena.Bowl(S, lib, V3.new(0, y, 0), 2.1, c)

	Shapes.PITCH = pitch
end
