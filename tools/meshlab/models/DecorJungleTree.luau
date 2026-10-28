--!nocheck
-- Chop a Rock zone decor: jungle tree in the ForestTree style (replaces the palm in the jungle;
-- palms are beach trees). Tall square trunk on four buttress-root fins, two short branches up to
-- wide flat stepped canopy pads at different heights, vines hanging from the pad edges.
-- ~16 tall, canopy ~13 wide. Leaves are close to the jungle floor green (50, 130, 40).
-- lib.seed varies yaw and pad offsets. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local bark, barkDark = C3.fromRGB(125, 80, 40), C3.fromRGB(100, 62, 30)
	local leaf, leafDark = C3.fromRGB(62, 152, 50), C3.fromRGB(48, 128, 40)
	local vine = C3.fromRGB(30, 95, 30)
	local function block(cf, size, col)
		S:bevelBox(cf, size, col, 0)
	end

	local yaw = rad(15 * math.floor(rand(0, 6)))
	local trunkH = 12.5
	local segH = trunkH / 3
	for i = 0, 2 do
		local w = 2.4 - i * 0.2
		block(CF.new(0, segH * (i + 0.5), 0) * CF.Angles(0, yaw, 0), V3.new(w, segH + 0.02, w), i % 2 == 0 and bark or barkDark)
	end

	-- Buttress roots: thin tall fins out of the trunk base, stepping down to the ground.
	for k = 0, 3 do
		local a = yaw + k * math.pi / 2 + rad(45)
		local d = V3.new(math.sin(a), 0, math.cos(a))
		local rot = CF.Angles(0, a, 0)
		block(CF.new(d.X * 1.6, 1.2, d.Z * 1.6) * rot, V3.new(0.5, 2.4, 1.6), barkDark)
		block(CF.new(d.X * 2.6, 0.5, d.Z * 2.6) * rot, V3.new(0.5, 1.0, 1.2), barkDark)
	end

	-- Canopy pad: three stacked crossed courses, widest at the bottom.
	local function pad(c, w)
		local r = CF.Angles(0, yaw + rand(-0.3, 0.3), 0)
		for i, f in { 1.0, 0.8, 0.5 } do
			local cf = CF.new(c.X, c.Y + (i - 0.5) * 1.1, c.Z) * r
			block(cf, V3.new(w * f, 1.1, w * f * 0.8), i % 2 == 1 and leaf or leafDark)
			block(cf, V3.new(w * f * 0.8, 1.12, w * f), i % 2 == 1 and leaf or leafDark)
		end
		-- vines: hanging strips under the pad's rim
		for k = 0, 3 do
			local a = rand(0, math.pi * 2)
			local rr = w * 0.38
			local len = rand(1.8, 3.4)
			block(CF.new(c.X + math.cos(a) * rr, c.Y - len / 2, c.Z + math.sin(a) * rr), V3.new(0.35, len, 0.35), vine)
		end
	end

	local top = V3.new(0, trunkH, 0)
	pad(top + V3.new(rand(-0.5, 0.5), 0.2, rand(-0.5, 0.5)), 10.5)
	for k = 0, 1 do
		local a = yaw + k * math.pi + rand(-0.4, 0.4)
		local tip = P.limb(S, lib, V3.new(0, trunkH - 7, 0), P.dir(lib, a, rad(32)), 5.2, 0.9, k == 0 and bark or barkDark)
		pad(tip + V3.new(0, -0.3, 0), rand(6.5, 7.5))
	end

	Shapes.finishBake(lib, { distance = 2.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
