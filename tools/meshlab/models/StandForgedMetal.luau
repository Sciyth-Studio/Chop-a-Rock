--!nocheck
-- Chop a Rock training stand, forged metal family (Bronze, Iron, Steel, Titanium, Tungsten): one shape, five colours.
-- Two square beam posts on stepped bevelled feet with bracket seats on top, and a thin plate laid across them on edge
-- (the breakable, tagged TrainingBoard) with a slim raised band and corner rivets as prop children, plus bracket caps.
-- Front faces -Z, pivot bottom centre, 5.5 wide, breakable centre 3.73 up. Units are studs.
-- Seed: none/0 = white meshes for export (part Color sets the metal), 1-5 = one metal, 6 = lineup of all five,
-- 11-15 = one metal with the split pulled apart, 16 = lineup with splits.
return function(em, lib, Shapes, part)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rgb = C3.fromRGB
	Shapes.PITCH = 1.0
	local seed = lib.seed or 0

	local metals = {
		{ frame = rgb(186, 106, 52), band = rgb(204, 124, 64), rivet = rgb(132, 72, 34) },
		{ frame = rgb(122, 108, 96), band = rgb(222, 106, 34), rivet = rgb(222, 106, 34) },
		{ frame = rgb(190, 194, 200), band = rgb(206, 210, 216), rivet = rgb(228, 230, 234) },
		{ frame = rgb(112, 128, 160), band = rgb(130, 112, 196), rivet = rgb(108, 110, 168) },
		{ frame = rgb(30, 32, 38), band = rgb(255, 150, 40), rivet = rgb(58, 60, 68) },
	}
	local white = { frame = rgb(255, 255, 255), band = rgb(255, 255, 255), rivet = rgb(255, 255, 255) }

	local postX, post = 1.9, 1.0
	local plateW, plateH, plateD = 5.3, 0.85, 1.0
	local plateY = 3.3
	local midY = plateY + plateH / 2

	local function frame(S, o, c)
		for _, sx in { -1, 1 } do
			local x = o.X + sx * postX
			S:bevelBox(CF.new(x, 0.15, o.Z), V3.new(1.7, 0.3, 1.7), c, 0.06)
			local lo, hi = {}, {}
			for _, p in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
				table.insert(lo, V3.new(x + p[1] * 0.8, 0.3, o.Z + p[2] * 0.8))
				table.insert(hi, V3.new(x + p[1] * 0.6, 0.56, o.Z + p[2] * 0.6))
			end
			S:loft({ lo, hi }, { color = c })
			S:bevelBox(CF.new(x, 0.63, o.Z), V3.new(1.2, 0.14, 1.2), c, 0.04)
			S:bevelBox(CF.new(x, (0.7 + 3.12) / 2, o.Z), V3.new(post, 3.12 - 0.7, post), c, 0.06)
			S:bevelBox(CF.new(x, 3.21, o.Z), V3.new(1.16, 0.18, 1.16), c, 0.04)
			for _, rx in { -0.5, 0.5 } do
				S:bevelBox(CF.new(x + rx, 0.33, o.Z - 0.66), V3.new(0.16, 0.08, 0.16), c, 0)
			end
		end
	end

	local function plate(S, o, c, x0, x1)
		local w = x1 - x0
		S:bevelBox(CF.new(o.X + (x0 + x1) / 2, midY, o.Z), V3.new(w, plateH, plateD), c, 0.05)
		for _, sx in { -1, 1 } do
			local cx = sx * 2.2
			if cx > x0 and cx < x1 then
				S:bevelBox(CF.new(o.X + cx, plateY + plateH + 0.09, o.Z), V3.new(0.62, 0.18, plateD + 0.16), c, 0.04)
			end
		end
	end

	local bandW = 4.9
	local function band(S, o, c, x0, x1)
		local a, b = math.max(x0, -bandW / 2), math.min(x1, bandW / 2)
		if b > a then
			S:bevelBox(CF.new(o.X + (a + b) / 2, midY, o.Z - plateD / 2 - 0.035), V3.new(b - a, 0.2, 0.09), c, 0.025)
		end
	end

	local function rivets(S, o, c, x0, x1)
		for _, rx in { -2.38, 2.38 } do
			if rx > x0 and rx < x1 then
				for _, ry in { -0.24, 0.24 } do
					for _, sz in { -1, 1 } do
						S:bevelBox(
							CF.new(o.X + rx, midY + ry, o.Z + sz * (plateD / 2 + 0.03)),
							V3.new(0.15, 0.15, 0.07),
							c,
							0
						)
					end
				end
			end
		end
	end

	local function stand(o, m, split)
		local Sf = Shapes.new(part("Frame"), lib)
		frame(Sf, o, m.frame)
		local half = plateW / 2
		if not split then
			plate(Shapes.new(part("Plate"), lib), o, m.frame, -half, half)
			band(Shapes.new(part("Band"), lib), o, m.band, -half, half)
			rivets(Shapes.new(part("Rivets"), lib), o, m.rivet, -half, half)
		end
		if split ~= false then
			local gap = split == "apart" and 0.35 or 0
			for _, side in { { "L", -1 }, { "R", 1 } } do
				local x0, x1 = side[2] < 0 and -half or 0, side[2] < 0 and 0 or half
				local so = o + V3.new(side[2] * gap, split == "apart" and 0.5 or 0, 0)
				plate(Shapes.new(part("Plate_" .. side[1]), lib), so, m.frame, x0, x1)
				band(Shapes.new(part("Band_" .. side[1]), lib), so, m.band, x0, x1)
				rivets(Shapes.new(part("Rivets_" .. side[1]), lib), so, m.rivet, x0, x1)
			end
		end
	end

	local zero = V3.new(0, 0, 0)
	if seed == 0 then
		stand(zero, white, nil)
	elseif seed <= 5 then
		stand(zero, metals[seed], false)
	elseif seed == 6 then
		for i, m in metals do
			stand(V3.new((3 - i) * 7, 0, 0), m, false)
		end
	elseif seed <= 15 then
		stand(zero, metals[seed - 10], "apart")
	else
		for i, m in metals do
			stand(V3.new((3 - i) * 7, 0, 0), m, "apart")
		end
	end
end
