--!nocheck
-- Chop a Rock intro cutscene car: red toy convertible from the ChatGPT six-view sheet
-- (Vault: Intro Car Reference), kept at the old part-built car's footprint (7 wide, 12.5 long)
-- and lowered from the sheet so the doors are ~3 high: the Seat (driver left, root 2.95 up,
-- 0.5 behind centre) and the Boing Out clip were tuned for the old car.
-- One mesh (the Body MeshPart). Front -Z, wheels on Y = 0, studs 1 per stud.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.5 })
	local S = Shapes.new(em, lib)

	local red = C3.fromRGB(255, 30, 30)
	local white = C3.fromRGB(245, 245, 245)
	local lip = C3.fromRGB(70, 70, 78)
	local grille = C3.fromRGB(30, 30, 34)
	local lamp = C3.fromRGB(255, 210, 0)
	local tail = C3.fromRGB(200, 15, 25)
	local glass = C3.fromRGB(150, 220, 255)
	local seat = C3.fromRGB(55, 55, 62)
	local floor = C3.fromRGB(150, 150, 158)
	local tyre = C3.fromRGB(30, 30, 34)
	local rim = C3.fromRGB(90, 90, 100)
	local hub = C3.fromRGB(170, 170, 180)

	-- Round details get no studs: every UV of what fn builds points at one flat spot of the
	-- stud tile (the kit does the same for faces too thin to stud).
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

	local function box(x, y, z, sx, sy, sz, col, bevel, rot)
		local cf = CF.new(x, y, z)
		if rot then
			cf = cf * rot
		end
		S:bevelBox(cf, V3.new(sx, sy, sz), col, bevel or 0)
	end

	local W, L = 7, 12.5
	local hw, hl = W / 2, L / 2 - 0.25 -- body ends at ±6; bumpers reach ±6.35
	local belt = 3.0
	local tubTop = 2.4
	local cabinFront, cabinBack = -1.6, 2.6

	-- Wheels: tucked under the body, tyre + dark rim + grey hub.
	local wheelR, wheelW = 1.25, 1.1
	for _, wz in { -3.6, 3.6 } do
		for _, side in { -1, 1 } do
			local inner = side * (hw - 0.3 - wheelW)
			local axis = CF.Angles(0, 0, -side * rad(90))
			plain(function()
				P.cyl(S, CF.new(inner, wheelR, wz) * axis, wheelR, wheelW, tyre, 16, 0.12)
				P.cyl(S, CF.new(inner - side * 0.03, wheelR, wz) * axis, 0.8, wheelW + 0.08, rim, 12, 0.06)
				P.cyl(S, CF.new(inner - side * 0.06, wheelR, wz) * axis, 0.4, wheelW + 0.16, hub, 10, 0.05)
			end)
		end
	end

	-- Body: a band over the wheel arches, blocks down to the sills between and outside the
	-- arches, hood and trunk decks up to the belt, door walls along the open cabin.
	local archTop = 2.0
	box(0, (archTop + tubTop) / 2, 0, W, tubTop - archTop, hl * 2, red, 0.15)
	for _, span in { { -hl, -4.95 }, { -2.25, 2.25 }, { 4.95, hl } } do
		local z0, z1 = span[1], span[2]
		box(0, (0.55 + archTop) / 2 + 0.01, (z0 + z1) / 2, W, archTop - 0.55 + 0.02, z1 - z0, red, 0.12)
	end
	for _, wz in { -3.6, 3.6 } do
		box(0, archTop - 0.05, wz, W - 0.7, 0.1, 2.7, lip)
	end
	box(0, (tubTop + belt) / 2, (-hl + cabinFront) / 2, W, belt - tubTop, cabinFront + hl, red, 0.15)
	box(0, (tubTop + belt) / 2, (cabinBack + hl) / 2, W, belt - tubTop, hl - cabinBack, red, 0.15)
	for _, side in { -1, 1 } do
		box(side * (hw - 0.25), (tubTop + belt) / 2, (cabinFront + cabinBack) / 2, 0.5, belt - tubTop, cabinBack - cabinFront, red, 0.1)
	end

	-- Stripe over the hood and its front face, and over the trunk deck and its back face.
	local sw = 1.6
	box(0, belt + 0.02, (-hl + cabinFront) / 2, sw, 0.04, cabinFront + hl - 0.1, white)
	box(0, (2.35 + belt) / 2, -hl - 0.02, sw, belt - 2.35, 0.04, white)
	box(0, belt + 0.02, (cabinBack + hl) / 2, sw, 0.04, hl - cabinBack - 0.1, white)
	box(0, (1.5 + belt) / 2, hl + 0.02, sw, belt - 1.5, 0.04, white)

	-- Front: grille slot, plate, round headlights with indicators, bumper with a dark lip.
	box(0, 1.95, -hl - 0.03, 3.0, 0.45, 0.06, grille)
	box(0, 1.5, -hl - 0.03, 1.4, 0.32, 0.06, white)
	local toFront = CF.Angles(-rad(90), 0, 0)
	plain(function()
		for _, side in { -1, 1 } do
			P.cyl(S, CF.new(side * 2.4, 2.3, -hl) * toFront, 0.42, 0.12, lamp, 20, 0.03)
			P.cyl(S, CF.new(side * 2.4, 1.6, -hl) * toFront, 0.17, 0.08, lamp, 12, 0.02)
		end
	end)
	box(0, 1.0, -hl - 0.1, W + 0.2, 0.55, 0.5, red, 0.12)
	box(0, 0.62, -hl - 0.08, W - 0.2, 0.22, 0.42, lip, 0.05)

	-- Back: square tail lights, bumper with a dark lip, exhaust on the right.
	for _, side in { -1, 1 } do
		box(side * 2.4, 2.2, hl + 0.03, 0.8, 0.6, 0.06, tail, 0.05)
	end
	box(0, 1.0, hl + 0.1, W + 0.2, 0.55, 0.5, red, 0.12)
	box(0, 0.62, hl + 0.08, W - 0.2, 0.22, 0.42, lip, 0.05)
	plain(function()
		P.cyl(S, CF.new(1.6, 0.62, hl + 0.2) * CF.Angles(rad(90), 0, 0), 0.18, 0.35, lip, 10, 0.03)
	end)

	-- Windshield: short, leaning back 15°, red frame around light-blue glass.
	local lean = CF.Angles(rad(15), 0, 0)
	local ws = CF.new(0, belt, cabinFront + 0.15) * lean
	local wsH = 1.3
	for _, side in { -1, 1 } do
		S:bevelBox(ws * CF.new(side * 3.05, wsH / 2, 0), V3.new(0.25, wsH, 0.25), red, 0.05)
	end
	S:bevelBox(ws * CF.new(0, wsH - 0.12, 0), V3.new(6.35, 0.25, 0.25), red, 0.05)
	S:bevelBox(ws * CF.new(0, (wsH - 0.25) / 2, 0), V3.new(5.85, wsH - 0.25, 0.08), glass, 0)

	-- Mirrors on short stalks at the windshield base.
	for _, side in { -1, 1 } do
		box(side * (hw + 0.15), belt + 0.15, cabinFront + 0.3, 0.3, 0.12, 0.12, red)
		box(side * (hw + 0.35), belt + 0.35, cabinFront + 0.3, 0.45, 0.35, 0.18, red, 0.05)
	end

	-- Cabin: grey floor, dash, steering wheel on the left, two dark seats with headrests.
	box(0, tubTop + 0.03, (cabinFront + cabinBack) / 2, W - 1.0, 0.06, cabinBack - cabinFront, floor)
	box(0, belt - 0.25, cabinFront + 0.3, W - 1.0, 0.5, 0.6, seat, 0.08)
	plain(function()
		P.cyl(S, CF.new(-1.5, belt - 0.15, cabinFront + 0.6) * CF.Angles(rad(60), 0, 0), 0.2, 0.5, grille, 8, 0.03)
		P.cyl(S, CF.new(-1.5, belt + 0.1, cabinFront + 1.0) * CF.Angles(rad(60), 0, 0), 0.55, 0.12, grille, 14, 0.03)
	end)
	for _, side in { -1, 1 } do
		local x = side * 1.5
		box(x, tubTop + 0.3, 0.9, 2.1, 0.5, 1.8, seat, 0.12)
		box(x, tubTop + 1.15, 2.0, 2.1, 1.5, 0.45, seat, 0.12, CF.Angles(rad(-10), 0, 0))
		box(x, tubTop + 2.1, 2.2, 1.2, 0.6, 0.38, seat, 0.1)
	end

	Shapes.finishBake(lib, { distance = 1.8, strength = 0.5, sky = 0.16 })
	Shapes.PITCH = pitch
end
