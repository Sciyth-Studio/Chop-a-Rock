--!nocheck
-- Chop a Rock zone decor: palm tree (Lineup B #1). Gently curved trunk of five stacked blocky
-- segments, seven long flat green leaf blades drooping from the crown, three coconuts.
-- ~14 tall, crown ~12 wide. lib.seed varies the lean and the leaves. Studs 1 per stud.
-- Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local bark, barkDark = C3.fromRGB(150, 95, 45), C3.fromRGB(120, 72, 32)
	local leaf, leafDark = C3.fromRGB(150, 225, 30), C3.fromRGB(110, 200, 25)
	local nut = C3.fromRGB(110, 65, 25)

	-- Trunk: each segment a little narrower and further along the lean, tilted to follow it.
	local lean = rand(0, math.pi * 2)
	local lx, lz = math.sin(lean), math.cos(lean)
	local p = V3.new(0, 0, 0)
	local segH = 2.5
	for i = 0, 4 do
		local tilt = rad(4 + i * 4)
		local d = V3.new(lx * math.sin(tilt), math.cos(tilt), lz * math.sin(tilt))
		local w = 1.9 - i * 0.12
		local mid = p + d * (segH / 2)
		S:bevelBox(P.lookAt(lib, mid, d), V3.new(w, w, segH + 0.1), i % 2 == 0 and bark or barkDark, 0)
		p += d * segH
	end
	S:bevelBox(CF.new(p.X, p.Y + 0.3, p.Z), V3.new(1.6, 0.8, 1.6), barkDark, 0)
	local crown = p + V3.new(0, 0.6, 0)

	-- Leaves: flat blades out and down in three tapering segments.
	local n = 7
	for k = 0, n - 1 do
		local yaw = k / n * math.pi * 2 + rand(-0.15, 0.15)
		local q = crown
		for s, seg in { { 20, 3.0, 2.3 }, { -15, 2.6, 1.8 }, { -45, 2.0, 1.0 } } do
			local d = P.dir(lib, yaw, rad(seg[1] + rand(-6, 6)))
			local mid = q + d * (seg[2] / 2)
			S:bevelBox(P.lookAt(lib, mid, d), V3.new(seg[3], 0.3, seg[2] + 0.15), (k + s) % 2 == 0 and leaf or leafDark, 0)
			q += d * seg[2]
		end
	end

	for k = 0, 2 do
		local a = rad(k * 120 + 40)
		S:bevelBox(CF.new(crown.X + math.sin(a) * 0.8, crown.Y - 1.0, crown.Z + math.cos(a) * 0.8), V3.new(0.9, 0.9, 0.9), nut, 0)
	end

	Shapes.finishBake(lib, { distance = 2.4, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
