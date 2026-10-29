--!nocheck
-- Chop a Rock zone decor: broken stone pillar in the JungleTree style (Lineup D #4). A square
-- plinth in two steps, a crossed-box column in banded courses, a broken top of uneven blocks, and
-- a green vine spiralling up with small leaves. ~9.5 tall, plinth 3.8 wide. lib.seed varies the
-- break and the vine. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local stone, stoneDark = C3.fromRGB(222, 192, 132), C3.fromRGB(196, 166, 110)
	local vine, leaf = C3.fromRGB(55, 135, 45), C3.fromRGB(75, 165, 55)
	local function cross(cf, w, h, col)
		S:bevelBox(cf, V3.new(w, h, w * 0.75), col, 0)
		S:bevelBox(cf, V3.new(w * 0.75, h + 0.02, w), col, 0)
	end

	S:bevelBox(CF.new(0, 0.5, 0), V3.new(3.8, 1.0, 3.8), stoneDark, 0)
	S:bevelBox(CF.new(0, 1.25, 0), V3.new(3.2, 0.5, 3.2), stone, 0)
	cross(CF.new(0, 1.75, 0), 2.8, 0.5, stoneDark)

	local colW = 2.3
	local y = 2.0
	local colTop = 7.6
	local i = 0
	while y < colTop - 0.01 do
		local h = math.min(1.4, colTop - y)
		cross(CF.new(0, y + h / 2, 0), colW, h + 0.02, i % 2 == 0 and stone or stoneDark)
		y += h
		i += 1
	end
	for _, b in { { -0.55, -0.3, 1.9, 1.0 }, { 0.5, 0.35, 1.1, 0.9 }, { 0.45, -0.45, 0.6, 0.8 } } do
		S:bevelBox(CF.new(b[1], colTop + b[3] / 2, b[2]), V3.new(b[4], b[3], b[4]), stone, 0)
	end

	local turns, r = 1.6, 1.3
	local a0 = rand(0, math.pi * 2)
	local steps = 14
	local prev = nil
	for s = 0, steps do
		local t = s / steps
		local a = a0 + t * turns * math.pi * 2
		local p = V3.new(math.cos(a) * r, 2.2 + t * (colTop - 2.4), math.sin(a) * r)
		if prev then
			local d = (p - prev).Unit
			P.limb(S, lib, prev - d * 0.1, d, (p - prev).Magnitude + 0.2, 0.3, vine)
			if s % 2 == 0 then
				local out = V3.new(math.cos(a), 0.3, math.sin(a)).Unit
				S:bevelBox(P.lookAt(lib, p + out * 0.4, out), V3.new(0.55, 0.12, 0.7), leaf, 0)
			end
		end
		prev = p
	end

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
