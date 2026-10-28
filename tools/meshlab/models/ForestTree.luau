--!nocheck
-- Chop a Rock forest tree for the intro set, restyled from TreeBlob: brown trunk, forest greens,
-- sized near the set's primitive trees (canopy ~8-10 wide, ~13-16 tall). Studs 1 per stud so
-- 2022 Stud / 2022 Inlet line up in Studio. lib.seed varies it. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local greens = {
		{ C3.fromRGB(45, 165, 35), C3.fromRGB(80, 195, 40) },
		{ C3.fromRGB(35, 150, 35), C3.fromRGB(65, 180, 40) },
		{ C3.fromRGB(55, 175, 30), C3.fromRGB(95, 205, 45) },
	}
	local pal = greens[1 + math.floor(rand(0, #greens))]
	local leaf, patch = pal[1], pal[2]
	local bark, barkDark = C3.fromRGB(120, 70, 30), C3.fromRGB(100, 58, 24)
	local function block(cf, size, col)
		S:bevelBox(cf, size, col, 0)
	end

	local maxW = rand(8, 10)
	local courseH = 1.3
	local courses = 6
	local trunkH = rand(5.5, 7)
	local yaw = rad(15 * math.floor(rand(0, 6)))

	-- Trunk: 3 stacked segments, slight offsets, alternating shade.
	local segH = trunkH / 3
	local off = V3.new(0, 0, 0)
	for i = 0, 2 do
		block(CF.new(off.X, segH * (i + 0.5), off.Z) * CF.Angles(0, yaw, 0), V3.new(2.2, segH + 0.02, 2.2), i % 2 == 0 and bark or barkDark)
		off += V3.new(rand(-0.2, 0.2), 0, rand(-0.2, 0.2))
	end

	-- Roots: out of the trunk side ~1.4 up, down at ~40° to a toe block.
	local nRoots = 3 + math.floor(rand(0, 2))
	for k = 0, nRoots - 1 do
		local a = yaw + k / nRoots * math.pi * 2 + rand(-0.3, 0.3)
		local start = V3.new(math.sin(a) * 0.8, 1.4, math.cos(a) * 0.8)
		local d = P.dir(lib, a, rad(-40))
		local len = 1.4 / math.sin(rad(40))
		local tip = P.limb(S, lib, start, d, len, 0.7, k % 2 == 0 and barkDark or bark)
		block(CF.new(tip.X, 0.2, tip.Z) * CF.Angles(0, a, 0), V3.new(1.0, 0.4, 1.2), bark)
	end

	-- Branches: arced limbs out of the upper trunk into the canopy underside.
	for k = 0, 1 do
		local a = yaw + k * math.pi + rand(-0.4, 0.4)
		local p = V3.new(off.X, trunkH * 0.75, off.Z)
		local elev = rad(15)
		for seg = 1, 2 do
			local d = P.dir(lib, a, elev)
			local len, t = ({ 1.5, 1.3 })[seg], ({ 0.7, 0.55 })[seg]
			local tip = P.limb(S, lib, p, d, len, t, seg % 2 == 0 and bark or barkDark)
			p = tip - d * 0.25
			elev += rad(25)
		end
	end

	-- Canopy: stepped voxel sphere.
	local profile = { 0.5, 0.85, 1.0, 0.95, 0.75, 0.5 }
	local base = trunkH - 0.5
	local cx, cz = off.X, off.Z
	for i, f in profile do
		local w = maxW * f
		local y = base + (i - 0.5) * courseH
		local jx, jz = rand(-0.6, 0.6), rand(-0.6, 0.6)
		local core = CF.new(cx + jx, y, cz + jz) * CF.Angles(0, yaw, 0)
		block(core, V3.new(w, courseH, w * rand(0.85, 1.0)), leaf)
		block(core, V3.new(w * 0.72, courseH + 0.02, w * 1.08), leaf)
		for _ = 1, 1 + math.floor(rand(0, 2)) do
			local s = rand(1.4, 2.2)
			local a = rand(0, math.pi * 2)
			local r = w * 0.5 - s * 0.3
			local col = rand(0, 1) < 0.45 and patch or leaf
			block(core * CF.new(math.cos(a) * r, rand(-0.25, 0.25), math.sin(a) * r), V3.new(s, s * rand(0.7, 1.0), s), col)
		end
	end

	Shapes.finishBake(lib, { distance = 2.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
