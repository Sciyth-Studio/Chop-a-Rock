--!nocheck
-- Chop a Rock Boss Arena: crystal outcrop for the Diamond cavern (assets/Arena/LineupB.webp #3) in
-- the JungleTree stud-block style. Two stacked dark neutral slate rocks of crossed turned courses,
-- the top one smaller, five cyan crystal prisms growing out of the top and two small ones out of
-- the right side. ~8 wide, ~14 tall. lib.seed varies the turns. Studs 1 per stud. Base on Y = 0,
-- front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local slate, slateLight, slateDark = C3.fromRGB(84, 84, 84), C3.fromRGB(102, 102, 102), C3.fromRGB(66, 66, 66)
	local shades = { C3.fromRGB(0, 200, 255), C3.fromRGB(60, 226, 255), C3.fromRGB(0, 172, 240) }
	local function cross(cf, w, h, col)
		S:bevelBox(cf, V3.new(w, h, w * 0.74), col, 0)
		S:bevelBox(cf, V3.new(w * 0.8, h + 0.02, w * 0.92), col, 0)
	end

	local y = 0
	local lower = { { 7.6, 1.4, slateDark, 0 }, { 7.9, 1.6, slate, 20 }, { 7.0, 1.5, slateLight, -10 }, { 5.6, 1.0, slate, 25 } }
	for _, c in lower do
		cross(CF.new(0, y + c[2] / 2, 0) * CF.Angles(0, rad(c[4] + rand(-5, 5)), 0), c[1], c[2], c[3])
		y += c[2] * 0.97
	end
	local upper = { { 5.4, 1.2, slateDark, -20 }, { 5.6, 1.4, slate, 10 }, { 4.6, 1.2, slateLight, -15 }, { 3.2, 0.7, slate, 20 } }
	for _, c in upper do
		cross(CF.new(-0.3, y + c[2] / 2, 0.2) * CF.Angles(0, rad(c[4] + rand(-5, 5)), 0), c[1], c[2], c[3])
		y += c[2] * 0.97
	end
	local top = y

	local function prism(base, yaw, tilt, length, width, col)
		local dir = P.dir(lib, rad(yaw), rad(90 - tilt))
		local tip = P.limb(S, lib, base - dir * 0.4, dir, length * 0.78 + 0.4, width, col)
		tip = P.limb(S, lib, tip - dir * 0.05, dir, length * 0.12, width * 0.66, col)
		P.limb(S, lib, tip - dir * 0.05, dir, length * 0.1, width * 0.34, col)
	end

	local crown = { { -0.3, 0.2, 0, 0, 7.0, 2.1 }, { -1.5, 0.6, 250, 30, 5.0, 1.6 }, { 0.9, 0.8, 80, 28, 5.4, 1.7 }, { -0.4, -1.0, 170, 34, 4.2, 1.4 }, { 0.5, 1.3, 20, 38, 3.6, 1.3 } }
	for i, c in crown do
		prism(V3.new(c[1], top - 0.3, c[2]), c[3], c[4], c[5], c[6], shades[(i % 3) + 1])
	end
	prism(V3.new(2.8, 2.2, 0.4), 90, 58, 3.8, 1.3, shades[2])
	prism(V3.new(2.7, 3.6, -0.7), 100, 48, 3.0, 1.1, shades[1])

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
