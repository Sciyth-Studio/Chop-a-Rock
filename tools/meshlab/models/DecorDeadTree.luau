--!nocheck
-- Chop a Rock zone decor: bare dead tree in the JungleTree style (Lineup C #3). A thick banded
-- trunk that jogs a little at each band, four buttress-root fins, and four bare square limbs that
-- bend once and end in a short fork. ~13 tall, ~9 wide. opts.charred (DecorCharredTree, volcano)
-- swaps the bark for charcoal. lib.seed varies yaw and limbs. Studs 1 per stud.
-- Base on Y = 0, front -Z.

return function(em, lib, Shapes, _, opts)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local charred = opts and opts.charred
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local bark = charred and C3.fromRGB(80, 74, 72) or C3.fromRGB(100, 74, 50)
	local barkDark = charred and C3.fromRGB(62, 58, 56) or C3.fromRGB(82, 60, 40)
	local function block(cf, size, col)
		S:bevelBox(cf, size, col, 0)
	end

	local yaw = rad(15 * math.floor(rand(0, 6)))
	local r = CF.Angles(0, yaw, 0)
	local segH = 2.4
	local x = 0
	for i = 0, 2 do
		local w = 2.3 - i * 0.25
		block(CF.new(x, segH * (i + 0.5), 0) * r, V3.new(w, segH + 0.05, w), i % 2 == 0 and bark or barkDark)
		x += (i % 2 == 0 and 0.35 or -0.3)
	end
	local top = V3.new(x, segH * 3, 0)

	for k = 0, 3 do
		local a = yaw + k * math.pi / 2 + rad(45)
		local d = V3.new(math.sin(a), 0, math.cos(a))
		local rot = CF.Angles(0, a, 0)
		block(CF.new(d.X * 1.5, 1.0, d.Z * 1.5) * rot, V3.new(0.55, 2.0, 1.5), barkDark)
		block(CF.new(d.X * 2.4, 0.4, d.Z * 2.4) * rot, V3.new(0.55, 0.8, 1.1), barkDark)
	end

	for k = 0, 3 do
		local a = yaw + k * math.pi / 2 + rand(-0.35, 0.35)
		local start = top - V3.new(0, 0.6 + k * 0.5, 0)
		local col = k % 2 == 0 and bark or barkDark
		local elbow = P.limb(S, lib, start, P.dir(lib, a, rad(rand(22, 34))), rand(3.2, 3.8), 1.0, col)
		local tip = P.limb(S, lib, elbow - V3.new(0, 0.1, 0), P.dir(lib, a + rand(-0.4, 0.4), rad(rand(55, 70))), rand(2.6, 3.2), 0.75, col == bark and barkDark or bark)
		P.limb(S, lib, tip, P.dir(lib, a - 0.6, rad(40)), 1.8, 0.45, col)
		P.limb(S, lib, tip, P.dir(lib, a + 0.5, rad(72)), 1.5, 0.45, col)
	end
	P.limb(S, lib, top - V3.new(0, 0.2, 0), V3.new(0, 1, 0), 1.6, 1.2, bark)

	Shapes.finishBake(lib, { distance = 2.2, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
