--!nocheck
-- Chop a Rock zone decor: dry savanna grass tuft in the JungleTree style (Lineup C #5). A small
-- crossed base pad with eleven flat golden blades fanning out all round in three segments, the
-- tips bending over, and two thin seed stalks. ~3.2 tall, ~4 wide. Golds sit just off the
-- savanna floor (200, 175, 70). lib.seed varies the fan. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local grass, grassDark, seed = C3.fromRGB(232, 190, 55), C3.fromRGB(205, 160, 40), C3.fromRGB(245, 210, 90)
	S:bevelBox(CF.new(0, 0.2, 0), V3.new(1.6, 0.4, 1.2), grassDark, 0)
	S:bevelBox(CF.new(0, 0.2, 0), V3.new(1.2, 0.42, 1.6), grassDark, 0)

	local n = 11
	local a0 = rand(0, math.pi * 2)
	for k = 0, n - 1 do
		local yaw = a0 + k / n * math.pi * 2 + rand(-0.2, 0.2)
		local q = V3.new(math.sin(yaw) * 0.3, 0.3, math.cos(yaw) * 0.3)
		local steep = rand(-6, 10)
		local scale = rand(0.8, 1.15)
		for s, seg in { { 80, 1.4, 0.45 }, { 66, 1.1, 0.38 }, { 30, 0.8, 0.28 } } do
			local d = P.dir(lib, yaw, rad(seg[1] + steep))
			local len = seg[2] * scale
			local mid = q + d * (len / 2)
			S:bevelBox(P.lookAt(lib, mid, d), V3.new(seg[3], 0.14, len + 0.1), (k + s) % 2 == 0 and grass or grassDark, 0)
			q += d * len
		end
	end
	for _, a in { a0 + 0.6, a0 + 3.4 } do
		local tip = P.limb(S, lib, V3.new(0, 0.3, 0), P.dir(lib, a, rad(76)), 3.4, 0.16, grassDark)
		P.limb(S, lib, tip - P.dir(lib, a, rad(76)) * 0.2, P.dir(lib, a, rad(60)), 0.6, 0.22, seed)
	end

	Shapes.finishBake(lib, { distance = 1.2, strength = 0.5, sky = 0.22 })
	Shapes.PITCH = pitch
end
