--!nocheck
-- Chop a Rock Diamond Rock v2, the "Diamond Colossus" (sheet: assets/Rocks/Diamond/DiamondRockV2/Sheet.webp).
-- Built at final size: about 100 studs across, about 90 tall. Pivot bottom centre, front -Z.
-- Parts: Body = the stone crater (tilted grey slabs round a low mound, studs; the part the chop code uses),
-- Crystals = central spire, crown of six big spires, ring of low spikes (plain UVs), Core = the brilliant-cut
-- diamond heart the spire grows out of (Neon, pulses), Shards = ring of floating shards (spins on Y),
-- Veins = thin glowing zigzag strips on the slab faces (Neon). Core and Veins skip the AO bake.

return function(em, lib, Shapes, part)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed or 7)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0

	local stone, stoneDark, stoneLight = C3.fromRGB(128, 128, 134), C3.fromRGB(104, 104, 110), C3.fromRGB(146, 146, 152)
	local crystal = C3.fromRGB(40, 180, 245)
	local glow = C3.fromRGB(200, 250, 255)
	local vein = C3.fromRGB(90, 225, 255)

	local function plain(S, fn)
		local before = {}
		for _, f in S.em:GetFaces() do
			before[f] = true
		end
		fn()
		local flat = S.em:AddUV(lib.Vector2.new(0.03, 0.03))
		for _, f in S.em:GetFaces() do
			if not before[f] then
				S.em:SetFaceUVs(f, { flat, flat, flat })
			end
		end
	end

	local function prism(S, cf, h, r, shoulder, color, sides)
		sides = sides or 6
		local rings = {}
		for _, k in { { -2, 1 }, { h * shoulder, 1 }, { h, 0.04 } } do
			local ring = {}
			for i = 0, sides - 1 do
				local a = i * math.pi * 2 / sides + math.pi / sides
				table.insert(ring, cf * V3.new(math.cos(a) * r * k[2], k[1], math.sin(a) * r * k[2]))
			end
			table.insert(rings, ring)
		end
		S:loft(rings, { color = color })
	end

	local function bipyramid(S, cf, h, r, color)
		local rings = {}
		for _, k in { { -h / 2, 0.04 }, { -h * 0.12, 1 }, { h * 0.12, 1 }, { h / 2, 0.04 } } do
			local ring = {}
			for i = 0, 5 do
				local a = i * math.pi / 3
				table.insert(ring, cf * V3.new(math.cos(a) * r * k[2], k[1], math.sin(a) * r * k[2] * 0.7))
			end
			table.insert(rings, ring)
		end
		S:loft(rings, { color = color })
	end

	local function outward(angle)
		return V3.new(math.sin(angle), 0, -math.cos(angle))
	end

	Shapes.beginBake({ cell = 9 })
	local S = Shapes.new(em, lib)

	S:lathe(CF.new(0, 0, 0), { { 36, 0 }, { 35, 10 }, { 27, 15 }, { 12, 18 }, { 0, 18.5 } }, 12, stoneDark)

	local slabs = {}
	local count = 22
	for k = 0, count - 1 do
		local a = (k + rand(-0.2, 0.2)) / count * math.pi * 2
		local front = math.abs(math.cos(a))
		local radius = rand(37, 40)
		local w, h, d = rand(11, 15), rand(17, 27) + front * 3, rand(7, 10)
		local tilt = rand(8, 20)
		local dir = outward(a)
		local base = dir * radius + V3.new(0, h / 2 - 2.5, 0)
		local cf = P.lookAt(lib, base, dir) * CF.Angles(rad(-tilt), rad(rand(-10, 10)), rad(rand(-7, 7)))
		local col = k % 3 == 0 and stoneLight or (k % 3 == 1 and stone or stoneDark)
		S:bevelBox(cf, V3.new(w, h, d), col, 0)
		table.insert(slabs, { cf = cf, w = w, h = h, d = d })
	end
	for k = 0, 5 do
		local a = (k + 0.5) / 6 * math.pi * 2 + rand(-0.3, 0.3)
		local dir = outward(a)
		local w, h = rand(10, 14), rand(5, 8)
		local cf = P.lookAt(lib, dir * rand(45, 48) + V3.new(0, h / 2 - 2, 0), dir) * CF.Angles(rad(-rand(20, 35)), rad(rand(-15, 15)), rad(rand(-10, 10)))
		S:bevelBox(cf, V3.new(w, h, rand(6, 8)), k % 2 == 0 and stone or stoneDark, 0)
	end
	for k = 0, 7 do
		local a = (k + 0.3) / 8 * math.pi * 2
		local dir = outward(a)
		local sz = rand(9, 12)
		local cf = P.lookAt(lib, dir * rand(26, 30) + V3.new(0, 16, 0), dir) * CF.Angles(rad(-rand(20, 35)), rad(rand(-20, 20)), 0)
		S:bevelBox(cf, V3.new(sz * 1.3, sz * 0.7, sz), stone, 0)
	end

	local C = Shapes.new(part("Crystals"), lib)
	local heartY = 35
	local heartR = 19
	plain(C, function()
		prism(C, CF.new(0, heartY + 7, 0), 50, 9, 0.82, crystal)
		for k = 0, 7 do
			local a = (k + 0.5) / 8 * math.pi * 2
			local dir = outward(a)
			local base = dir * 7 + V3.new(0, heartY + 7, 0)
			local axis = dir:Cross(V3.new(0, 1, 0))
			local cf = CF.new(base) * CF.fromAxisAngle(axis, rad(-rand(14, 22))) * CF.Angles(0, a, 0)
			prism(C, cf, rand(30, 40), rand(6.0, 7.2), 0.78, crystal)
		end
		for k = 0, 13 do
			local a = k / 14 * math.pi * 2 + rand(-0.08, 0.08)
			local dir = outward(a)
			local base = dir * rand(29, 33) + V3.new(0, 20, 0)
			local axis = dir:Cross(V3.new(0, 1, 0))
			local cf = CF.new(base) * CF.fromAxisAngle(axis, rad(-rand(42, 56))) * CF.Angles(0, a, 0)
			prism(C, cf, rand(16, 23), rand(3.6, 4.8), 0.7, crystal)
		end
	end)

	local Sh = Shapes.new(part("Shards"), lib)
	plain(Sh, function()
		for k = 0, 9 do
			local a = k / 10 * math.pi * 2
			local dir = outward(a)
			local pos = dir * rand(44, 48) + V3.new(0, 34 + (k % 3) * 16 + rand(-3, 3), 0)
			local axis = dir:Cross(V3.new(0, 1, 0))
			local cf = CF.new(pos) * CF.fromAxisAngle(axis, rad(-rand(14, 26))) * CF.Angles(0, a + rad(90), 0)
			bipyramid(Sh, cf, rand(14, 18), rand(3.2, 3.8), crystal)
		end
	end)

	Shapes.finishBake(lib, { distance = 6, strength = 0.5, sky = 0.22 })

	local Co = Shapes.new(part("Core"), lib)
	plain(Co, function()
		local profile = { { 0, heartY - 14 }, { heartR, heartY + 1 }, { heartR, heartY + 3 }, { heartR * 0.62, heartY + 7.5 }, { 0, heartY + 7.5 } }
		Co:lathe(CF.new(0, 0, 0), profile, 8, glow)
	end)

	local Ve = Shapes.new(part("Veins"), lib)
	plain(Ve, function()
		for i, slab in slabs do
			if i % 3 ~= 0 then
				local x = rand(-slab.w * 0.25, slab.w * 0.25)
				local y = -slab.h / 2 + 1
				local z = -slab.d / 2 - 0.15
				local steps = 3
				for _ = 1, steps do
					local nx = math.clamp(x + rand(-4, 4), -slab.w / 2 + 1.5, slab.w / 2 - 1.5)
					local ny = y + slab.h / (steps + 0.5)
					local from, to = V3.new(x, y, z), V3.new(nx, ny, z)
					local mid = (from + to) / 2
					local len = (to - from).Magnitude
					local ang = math.atan2(to.X - from.X, to.Y - from.Y)
					Ve:box(slab.cf * CF.new(mid) * CF.Angles(0, 0, -ang), V3.new(1.5, len + 1, 0.5), vein)
					x, y = nx, ny
				end
			end
		end
		for k = 0, 5 do
			local a = (k + 0.5) / 6 * math.pi * 2
			local dir = outward(a)
			local len = 14
			local cf = P.lookAt(lib, dir * 20 + V3.new(0, 15.6, 0), dir) * CF.Angles(rad(-14), 0, 0)
			Ve:box(cf, V3.new(1.1, 0.5, len), vein)
		end
	end)

	Shapes.PITCH = pitch
end
