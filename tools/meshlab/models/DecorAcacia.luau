--!nocheck
-- Chop a Rock zone decor: savanna acacia in the JungleTree style (Lineup C #4). A slim banded
-- trunk on small root fins forks into three angled limbs that hold one wide, flat, thin canopy of
-- crossed courses, plus two lower side pads so the top isn't one slab. ~12 tall, canopy ~16 wide.
-- lib.seed varies yaw and pads. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local bark, barkDark = C3.fromRGB(125, 75, 38), C3.fromRGB(102, 60, 30)
	local leaf, leafDark = C3.fromRGB(72, 102, 40), C3.fromRGB(60, 88, 34)
	local function block(cf, size, col)
		S:bevelBox(cf, size, col, 0)
	end

	local yaw = rad(15 * math.floor(rand(0, 6)))
	local trunkH = 5
	for i = 0, 1 do
		block(CF.new(0, trunkH / 2 * (i + 0.5), 0) * CF.Angles(0, yaw, 0), V3.new(1.3 - i * 0.15, trunkH / 2 + 0.05, 1.3 - i * 0.15), i == 0 and bark or barkDark)
	end
	for k = 0, 3 do
		local a = yaw + k * math.pi / 2 + rad(45)
		local d = V3.new(math.sin(a), 0, math.cos(a))
		block(CF.new(d.X * 0.9, 0.5, d.Z * 0.9) * CF.Angles(0, a, 0), V3.new(0.4, 1.0, 0.9), barkDark)
	end

	local canopyY = 10.4
	local function pad(c, w, depth)
		local r = CF.Angles(0, yaw + rand(-0.25, 0.25), 0)
		for i, f in { 1.0, 0.78, 0.5 } do
			local cf = CF.new(c.X, c.Y + (i - 0.5) * 0.8, c.Z) * r
			block(cf, V3.new(w * f, 0.8, depth * f), i % 2 == 1 and leaf or leafDark)
			block(cf, V3.new(w * f * 0.85, 0.82, depth * f * 1.15), i % 2 == 1 and leaf or leafDark)
		end
	end

	local fork = V3.new(0, trunkH - 0.2, 0)
	for k = 0, 2 do
		local a = yaw + k / 3 * math.pi * 2 + rand(-0.25, 0.25)
		local d = P.dir(lib, a, rad(58))
		local len = (canopyY - 0.4 - fork.Y) / d.Y
		P.limb(S, lib, fork, d, len, 0.75, k % 2 == 0 and bark or barkDark)
	end
	pad(V3.new(0, canopyY, 0), 16, 11)
	for _, side in { -1, 1 } do
		local a = yaw + (side > 0 and 0 or math.pi) + rad(90)
		pad(V3.new(math.sin(a) * 5.5, canopyY - 0.6, math.cos(a) * 3.5), rand(6, 7), rand(5, 6))
	end

	Shapes.finishBake(lib, { distance = 2.2, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
