--!nocheck
-- Chop a Rock zone decor: kelp in the JungleTree style (Lineup B #3). A crossed holdfast pad with
-- three chunky flat sea-green strips rising from it, each a chain of thick segments leaning side
-- to side for a gentle wave, alternating shades, ~6, 8 and 10 tall. lib.seed varies the wave.
-- Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local kelp, kelpDark = C3.fromRGB(60, 210, 90), C3.fromRGB(35, 175, 70)
	S:bevelBox(CF.new(0, 0.3, 0), V3.new(3.2, 0.6, 2.2), kelpDark, 0)
	S:bevelBox(CF.new(0, 0.3, 0), V3.new(2.4, 0.62, 2.8), kelpDark, 0)

	-- Each strip sways in its own plane (around its local Z), so the flat face never twists.
	for k, strip in { { -1.0, 0.2, 6, 0.4 }, { 0, -0.2, 10, -0.2 }, { 1.0, 0.3, 8, 0.1 } } do
		local yaw = strip[4] + rand(-0.15, 0.15)
		local base = CF.new(strip[1], 0.5, strip[2]) * CF.Angles(0, yaw, 0)
		local q = V3.new(0, 0, 0)
		local segLen = 1.3
		local phase = rand(0, math.pi * 2)
		local n = math.floor(strip[3] / segLen)
		for i = 0, n - 1 do
			local sway = math.sin(phase + i * 1.1) * rad(18)
			local d = V3.new(-math.sin(sway), math.cos(sway), 0)
			local mid = q + d * (segLen / 2)
			local w = i == n - 1 and 0.8 or 1.25
			S:bevelBox(base * CF.new(mid.X, mid.Y, mid.Z) * CF.Angles(0, 0, sway), V3.new(w, segLen + 0.1, 0.4), (i + k) % 2 == 0 and kelp or kelpDark, 0)
			q += d * segLen
		end
	end

	Shapes.finishBake(lib, { distance = 1.8, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
