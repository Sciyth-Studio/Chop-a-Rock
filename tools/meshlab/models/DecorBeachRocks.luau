--!nocheck
-- Chop a Rock Boss Arena: beach rock cluster for the Boulder Crab's island (assets/Arena/LineupB.webp
-- #1) in the JungleTree stud-block style. One big sandy boulder of four crossed courses, each turned
-- so it reads faceted, with two smaller boulders huddled in front, lighter tops. ~8 wide, ~4.6 tall.
-- lib.seed varies the turns. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local sand, sandLight, sandDark = C3.fromRGB(232, 168, 88), C3.fromRGB(246, 196, 122), C3.fromRGB(208, 144, 70)
	local function cross(cf, w, h, col)
		S:bevelBox(cf, V3.new(w, h, w * 0.72), col, 0)
		S:bevelBox(cf, V3.new(w * 0.78, h + 0.02, w * 0.9), col, 0)
	end
	local function boulder(x, z, scale, yaw)
		local courses = { { 1.0, 1.0, sandDark }, { 1.04, 1.1, sand }, { 0.88, 0.9, sand }, { 0.62, 0.6, sandLight } }
		local y = 0
		for i, c in courses do
			local turn = yaw + (if i % 2 == 0 then 18 else -12) + rand(-6, 6)
			cross(CF.new(x, y + c[2] * scale / 2, z) * CF.Angles(0, rad(turn), 0), 4.4 * c[1] * scale, c[2] * scale, c[3])
			y += c[2] * scale * 0.97
		end
	end

	boulder(0.3, 0.8, 1.25, 10)
	boulder(-2.6, -1.9, 0.72, -25)
	boulder(2.7, -1.7, 0.78, 35)

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
