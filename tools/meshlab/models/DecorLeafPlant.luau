--!nocheck
-- Chop a Rock zone decor: leaf plant in the JungleTree style (Lineup B #2). A crossed base pad
-- with six chunky flat leaves fanning up and out in three tapering segments, alternating
-- shades. ~3.8 tall, ~6 wide. lib.seed varies the fan. Studs 1 per stud. Base Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local leaf, leafDark = C3.fromRGB(62, 152, 50), C3.fromRGB(48, 128, 40)
	S:bevelBox(CF.new(0, 0.3, 0), V3.new(1.8, 0.6, 1.3), leafDark, 0)
	S:bevelBox(CF.new(0, 0.3, 0), V3.new(1.3, 0.62, 1.8), leafDark, 0)

	local n = 6
	local a0 = rand(0, math.pi * 2)
	for k = 0, n - 1 do
		local yaw = a0 + k / n * math.pi * 2 + rand(-0.2, 0.2)
		local q = V3.new(math.sin(yaw) * 0.4, 0.5, math.cos(yaw) * 0.4)
		local steep = rand(-8, 8)
		for s, seg in { { 72, 1.7, 1.4 }, { 45, 1.6, 1.1 }, { 15, 1.1, 0.6 } } do
			local d = P.dir(lib, yaw, rad(seg[1] + steep))
			local mid = q + d * (seg[2] / 2)
			S:bevelBox(P.lookAt(lib, mid, d), V3.new(seg[3], 0.4, seg[2] + 0.15), (k + s) % 2 == 0 and leaf or leafDark, 0)
			q += d * seg[2]
		end
	end

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
