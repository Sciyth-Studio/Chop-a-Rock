--!nocheck
-- Chop a Rock lobby prop: open treasure chest heaped with cash, after the Cash5 shop icon.
-- Red body with chunky gold corner posts, rims and lock, lid swung back past upright, a
-- mound of green cash bundles with gold bands, and gold coins and loose bills on the ground.
-- ~7.5 wide, ~8.6 tall. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local function plain(fn)
		local before = {}
		for _, f in em:GetFaces() do
			before[f] = true
		end
		fn()
		local flat = em:AddUV(lib.Vector2.new(0.03, 0.03))
		for _, f in em:GetFaces() do
			if not before[f] then
				em:SetFaceUVs(f, { flat, flat, flat })
			end
		end
	end

	local red, redDark, inside = C3.fromRGB(215, 25, 55), C3.fromRGB(185, 18, 45), C3.fromRGB(130, 12, 35)
	local gold, goldDark = C3.fromRGB(255, 195, 25), C3.fromRGB(240, 145, 10)
	local cash, cashDark = C3.fromRGB(70, 180, 60), C3.fromRGB(40, 140, 50)
	local band = C3.fromRGB(255, 175, 30)

	local w, d, h = 6.4, 4.4, 3.8
	local t = 0.45

	S:bevelBox(CF.new(0, 1.0, 0), V3.new(w, 2.0, d), redDark, 0)
	S:bevelBox(CF.new(0, 2.0 + (h - 2.5) / 2, 0), V3.new(w - 0.1, h - 2.5, d - 0.1), red, 0)

	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			S:bevelBox(CF.new(sx * (w / 2 - 0.3), h / 2, sz * (d / 2 - 0.3)), V3.new(0.8, h + 0.1, 0.8), gold, 0)
		end
	end
	S:bevelBox(CF.new(0, 0.3, 0), V3.new(w + 0.2, 0.6, d + 0.2), goldDark, 0)
	for _, s in { -1, 1 } do
		S:bevelBox(CF.new(0, h - 0.25, s * (d / 2 - t / 2 + 0.1)), V3.new(w + 0.2, 0.5, t + 0.2), gold, 0)
		S:bevelBox(CF.new(s * (w / 2 - t / 2 + 0.1), h - 0.25, 0), V3.new(t + 0.2, 0.5, d + 0.2), gold, 0)
	end
	S:bevelBox(CF.new(0, h - 0.95, -d / 2 - 0.1), V3.new(1.1, 1.3, 0.3), gold, 0)
	S:bevelBox(CF.new(0, h - 1.05, -d / 2 - 0.27), V3.new(0.5, 0.6, 0.1), goldDark, 0)

	local hinge = CF.new(0, h, d / 2) * CF.Angles(rad(108), 0, 0)
	local lw, ld = w + 0.2, d + 0.2
	S:bevelBox(hinge * CF.new(0, 0.4, -ld / 2), V3.new(lw, 0.8, ld), red, 0)
	S:bevelBox(hinge * CF.new(0, -0.03, -ld / 2), V3.new(lw - 1.0, 0.08, ld - 1.0), inside, 0)
	S:bevelBox(hinge * CF.new(0, 1.05, -ld / 2), V3.new(lw - 0.8, 0.5, ld - 1.0), redDark, 0)
	S:bevelBox(hinge * CF.new(0, 0.4, -0.25), V3.new(lw + 0.1, 0.9, 0.5), gold, 0)
	S:bevelBox(hinge * CF.new(0, 0.4, -ld + 0.25), V3.new(lw + 0.1, 0.9, 0.5), gold, 0)
	for _, sx in { -1, 1 } do
		S:bevelBox(hinge * CF.new(sx * (lw / 2 - 0.2), 0.75, -ld / 2), V3.new(0.5, 0.6, ld), gold, 0)
	end
	S:bevelBox(hinge * CF.new(0, 0.3, -ld - 0.15), V3.new(1.0, 0.9, 0.3), gold, 0)

	local seed = 7
	local function rnd()
		seed = (seed * 16807) % 2147483647
		return seed / 2147483647
	end
	local function bundle(cf)
		local col = rnd() < 0.5 and cash or cashDark
		S:bevelBox(cf, V3.new(1.7, 0.45, 0.85), col, 0)
		S:bevelBox(cf, V3.new(0.35, 0.5, 0.9), band, 0)
	end
	S:bevelBox(CF.new(0, h - 0.3, 0), V3.new(w - 2 * t, 0.5, d - 2 * t), cashDark, 0)
	local layers = {
		{ y = h - 0.05, n = 14, rx = 2.3, rz = 1.5 },
		{ y = h + 0.35, n = 12, rx = 2.0, rz = 1.3 },
		{ y = h + 0.8, n = 9, rx = 1.6, rz = 1.0 },
		{ y = h + 1.2, n = 6, rx = 1.1, rz = 0.7 },
		{ y = h + 1.6, n = 3, rx = 0.5, rz = 0.4 },
	}
	for _, layer in layers do
		for i = 1, layer.n do
			local x = (rnd() * 2 - 1) * layer.rx
			local z = (rnd() * 2 - 1) * layer.rz
			local cf = CF.new(x, layer.y + rnd() * 0.15, z)
				* CF.Angles(rad((rnd() - 0.5) * 24), rad(rnd() * 180), rad((rnd() - 0.5) * 24))
			bundle(cf)
		end
	end
	bundle(CF.new(-1.4, h - 0.1, -d / 2 + 0.2) * CF.Angles(rad(-35), rad(15), rad(8)))
	bundle(CF.new(1.9, h + 0.1, -d / 2 + 0.3) * CF.Angles(rad(-28), rad(-20), rad(-6)))

	local function bill(cf)
		S:bevelBox(cf, V3.new(1.6, 0.08, 0.8), cash, 0)
		S:bevelBox(cf * CF.new(0, 0.05, 0), V3.new(0.5, 0.04, 0.4), cashDark, 0)
	end
	bill(CF.new(-2.6, 0.05, -d / 2 - 1.2) * CF.Angles(0, rad(25), 0))
	bill(CF.new(2.4, 0.05, -d / 2 - 1.4) * CF.Angles(0, rad(-35), 0))
	bill(CF.new(-1.8, h - 0.5, -d / 2 - 0.35) * CF.Angles(rad(-70), rad(10), rad(-15)))

	plain(function()
		local function coin(cf, r)
			S:lathe(cf, { { 0, 0 }, { r, 0 }, { r, 0.3 }, { 0, 0.3 } }, 12, goldDark)
			S:lathe(cf * CF.new(0, 0.3, 0), { { r * 0.8, 0 }, { r * 0.65, 0.06 }, { 0, 0.06 } }, 12, gold)
		end
		coin(CF.new(-3.4, 0, -d / 2 - 0.2), 0.75)
		coin(CF.new(-3.1, 0.3, -d / 2 + 0.6) * CF.Angles(rad(12), 0, rad(-8)), 0.6)
		coin(CF.new(3.5, 0, -d / 2 - 0.5), 0.7)
		coin(CF.new(0.9, 0, -d / 2 - 1.5), 0.6)
		coin(CF.new(1.4, h + 0.9, -0.6) * CF.Angles(rad(-20), 0, rad(15)), 0.5)
		coin(CF.new(-1.8, h + 0.7, 0.3) * CF.Angles(rad(15), 0, rad(-20)), 0.5)
	end)

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
