--!nocheck
-- Chop a Rock zone decor: pine in the JungleTree style (Lineup A #1). Chunky banded trunk on four
-- root fins, three tiers of crossed-box pads, each tier three shrinking courses in alternating
-- shades, the tiers getting smaller up the tree, a crossed tip. ~15 tall, ~9 wide.
-- opts.snow (DecorSnowPine) lays a crossed white slab on every course. lib.seed varies yaw and
-- widths. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes, _, opts)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local snow = opts and opts.snow
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local bark, barkDark = C3.fromRGB(120, 70, 30), C3.fromRGB(100, 58, 24)
	local leaf = snow and C3.fromRGB(20, 125, 60) or C3.fromRGB(52, 96, 56)
	local leafDark = snow and C3.fromRGB(15, 105, 50) or C3.fromRGB(40, 78, 46)
	local white = C3.fromRGB(245, 250, 255)
	local function block(cf, size, col)
		S:bevelBox(cf, size, col, 0)
	end
	local function cross(cf, w, h, col)
		block(cf, V3.new(w, h, w * 0.78), col)
		block(cf, V3.new(w * 0.78, h + 0.02, w), col)
	end

	local yaw = rad(15 * math.floor(rand(0, 6)))
	local r = CF.Angles(0, yaw, 0)
	local trunkH = 5
	for i = 0, 1 do
		block(CF.new(0, trunkH / 2 * (i + 0.5), 0) * r, V3.new(2.2 - i * 0.2, trunkH / 2 + 0.02, 2.2 - i * 0.2), i == 0 and bark or barkDark)
	end
	for k = 0, 3 do
		local a = yaw + k * math.pi / 2 + rad(45)
		local d = V3.new(math.sin(a), 0, math.cos(a))
		block(CF.new(d.X * 1.4, 0.9, d.Z * 1.4) * CF.Angles(0, a, 0), V3.new(0.5, 1.8, 1.3), barkDark)
		block(CF.new(d.X * 2.2, 0.35, d.Z * 2.2) * CF.Angles(0, a, 0), V3.new(0.5, 0.7, 1.0), barkDark)
	end

	local courseH = 1.1
	local y = trunkH - 0.5
	for i, w in { 9, 7, 5 } do
		w *= rand(0.94, 1.06)
		local tr = CF.Angles(0, yaw + (i % 2 == 0 and rad(45) or 0), 0)
		for c, f in { 1.0, 0.75, 0.5 } do
			local cf = CF.new(0, y + courseH / 2, 0) * tr
			cross(cf, w * f, courseH, c % 2 == 1 and leaf or leafDark)
			if snow then
				cross(cf * CF.new(0, courseH / 2 + 0.15, 0), w * f * 0.85, 0.3, white)
			end
			y += courseH
		end
		y -= courseH * 0.4
	end
	cross(CF.new(0, y + 0.6, 0) * r, 1.6, 1.2, snow and white or leaf)

	Shapes.finishBake(lib, { distance = 2.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
