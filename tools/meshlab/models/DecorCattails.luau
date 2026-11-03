--!nocheck
-- Chop a Rock zone decor: cattails in the JungleTree style (Lineup C #1). A crossed base pad with
-- six thin square reeds of different heights, four topped with a chunky crossed brown seed head
-- and a short spike, and long flat leaves bending outward in two segments. ~6.5 tall, ~4 wide.
-- Greens sit just above the swamp floor (50, 70, 40). lib.seed varies the clump.
-- Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local reed, reedDark = C3.fromRGB(64, 98, 46), C3.fromRGB(54, 84, 40)
	local head, headDark = C3.fromRGB(125, 72, 32), C3.fromRGB(105, 58, 26)
	local function cross(cf, w, h, col)
		S:bevelBox(cf, V3.new(w, h, w * 0.75), col, 0)
		S:bevelBox(cf, V3.new(w * 0.75, h + 0.02, w), col, 0)
	end

	cross(CF.new(0, 0.25, 0), 2.6, 0.5, reedDark)

	local a0 = rand(0, math.pi * 2)
	for k = 0, 5 do
		local a = a0 + k / 6 * math.pi * 2 + rand(-0.3, 0.3)
		local r = rand(0.3, 0.9)
		local base = V3.new(math.cos(a) * r, 0.3, math.sin(a) * r)
		local h = 4.2 + (k % 3) * 0.9 + rand(-0.3, 0.3)
		local d = P.dir(lib, a, rad(84))
		local top = P.limb(S, lib, base, d, h, 0.35, k % 2 == 0 and reed or reedDark)
		if k < 4 then
			local hc = top - d * 0.2 + V3.new(0, 0.8, 0)
			cross(CF.new(hc.X, hc.Y, hc.Z), 0.8, 1.6, k % 2 == 0 and head or headDark)
			P.limb(S, lib, hc + V3.new(0, 0.7, 0), V3.new(0, 1, 0), 0.8, 0.2, reed)
		end
	end

	for k = 0, 4 do
		local a = a0 + (k + 0.5) / 5 * math.pi * 2 + rand(-0.2, 0.2)
		local q = V3.new(math.cos(a) * 0.4, 0.4, math.sin(a) * 0.4)
		local yaw = math.atan2(math.cos(a), math.sin(a))
		for s, seg in { { 76, 2.2 }, { 40, 1.6 } } do
			local d = P.dir(lib, yaw, rad(seg[1] + rand(-6, 6)))
			local mid = q + d * (seg[2] / 2)
			S:bevelBox(P.lookAt(lib, mid, d), V3.new(0.45, 0.15, seg[2] + 0.1), (k + s) % 2 == 0 and reed or reedDark, 0)
			q += d * seg[2]
		end
	end

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
