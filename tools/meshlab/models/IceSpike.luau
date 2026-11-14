--!nocheck
-- Chop a Rock ice spike (sheet: assets/Models/IceSpike, prompt Prompt.md). Frost Yeti Ice Spikes attack
-- spike (Model_Boss_IceSpike1-3) and the Frost Yeti arena's ice clusters, scaled up in Studio.
-- Built like the Diamond Rock spires: six-sided prisms lofted to a sharp tip, plain colours, no studs.
-- A tall main crystal (one colour to the tip), two or three shorter crystals leaning out of its base, and a
-- low ring of faceted ice chunks. About 10 tall and 6 across. lib.seed 1-3 picks the variant.
-- Pivot bottom centre, ground Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local variant = ((lib.seed or 1) - 1) % 3 + 1
	local rand = P.rng(variant * 31)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0

	local body = C3.fromRGB(166, 206, 242)
	local side = C3.fromRGB(138, 188, 238)
	local chunkShades = { C3.fromRGB(118, 168, 226), C3.fromRGB(134, 182, 234), C3.fromRGB(104, 154, 214) }

	local S = Shapes.new(em, lib)

	local function plain(fn)
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

	local function crystal(cf, height, radius, shoulder, color)
		local rings = {}
		for _, k in { { -1.5, 1 }, { height * shoulder, 1 }, { height, 0.03 } } do
			local ring = {}
			for i = 0, 5 do
				local a = i * math.pi / 3 + math.pi / 6
				table.insert(ring, cf * V3.new(math.cos(a) * radius * k[2], k[1], math.sin(a) * radius * k[2]))
			end
			table.insert(rings, ring)
		end
		S:loft(rings, { color = color })
	end

	local function leaning(angle, distance, lean, height, radius, shoulder, color)
		local a = rad(angle)
		local x, z = math.cos(a) * distance, math.sin(a) * distance
		local cf = CF.new(x, 0, z) * CF.Angles(0, -a, 0) * CF.Angles(0, 0, rad(-lean))
		crystal(cf, height, radius, shoulder, color)
	end

	local function chunk(x, z, radius, height, color)
		local cf = CF.new(x, -0.2, z) * CF.Angles(rad(rand(-10, 10)), rad(rand(0, 360)), rad(rand(-10, 10)))
		local profile = { { radius, 0 }, { radius * 0.96, height * 0.55 }, { radius * 0.5, height }, { 0, height * 1.02 } }
		local bumps = {}
		for i = 1, 5 do
			bumps[i] = rand(0.7, 1.15)
		end
		S:lathe(cf, profile, 5, color, function(a)
			return bumps[math.floor(a / (math.pi * 2) * 5 + 0.5) % 5 + 1]
		end)
	end

	local layouts = {
		{
			main = { 90, 0.2, 4, 10, 1.55, 0.72 },
			sides = {
				{ 180, 1.5, 26, 5.8, 1.0, 0.7 },
				{ 0, 1.5, 24, 5.2, 0.95, 0.7 },
				{ 250, 1.2, 34, 3.8, 0.8, 0.66 },
			},
		},
		{
			main = { 0, 0.3, 8, 9.6, 1.6, 0.72 },
			sides = {
				{ 165, 1.5, 22, 6.4, 1.1, 0.7 },
				{ 40, 1.6, 34, 4.4, 0.9, 0.66 },
			},
		},
		{
			main = { 200, 0.5, 5, 8.8, 1.45, 0.72 },
			sides = {
				{ 20, 1.2, 12, 7.6, 1.25, 0.72 },
				{ 140, 1.5, 32, 4.4, 0.85, 0.66 },
				{ 300, 1.4, 36, 3.6, 0.75, 0.64 },
			},
		},
	}
	local layout = layouts[variant]

	Shapes.beginBake({ cell = 2.0 })
	plain(function()
		local m = layout.main
		leaning(m[1], m[2], m[3], m[4], m[5], m[6], body)
		for _, c in layout.sides do
			leaning(c[1] + rand(-8, 8), c[2], c[3], c[4], c[5], c[6], side)
		end
		local count = 8
		for k = 0, count - 1 do
			local a = (k + rand(-0.25, 0.25)) / count * math.pi * 2
			local d = rand(2.3, 3.0)
			chunk(math.cos(a) * d, math.sin(a) * d, rand(1.1, 1.6), rand(0.8, 1.4), chunkShades[k % 3 + 1])
		end
	end)
	Shapes.finishBake(lib, { distance = 1.4, strength = 0.45, sky = 0.22 })
	Shapes.PITCH = pitch
end
