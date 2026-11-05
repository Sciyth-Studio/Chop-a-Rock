--!nocheck
-- Chop a Rock zone egg: Swamp, from the Reedy Boulder. Teal shell, a lily pad resting on top like a flat hat, a pink flower on the pad.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local pad, pink, light, gold = rgb(70, 170, 50), rgb(255, 90, 170), rgb(255, 150, 200), rgb(255, 210, 40)
	Egg.Build(em, lib, Shapes, rgb(40, 190, 150), function(S)
		Egg.Turned(S, lib, V3.new(0, 4.95, 0), { { 0.8, -0.25 }, { 2.05, 0 }, { 2.05, 0.1 }, { 1.2, 0.28 }, { 0.7, 0.62 }, { 0.2, 0.74 } }, 12, pad)
		local base = V3.new(0, 5.6, 0)
		for ringIndex, r in { { 6, 0.85, 0.28, pink }, { 5, 0.5, 0.55, light } } do
			for k = 1, r[1] do
				local a = math.rad(k * 360 / r[1] + ringIndex * 25)
				local out = V3.new(math.cos(a), 0, -math.sin(a))
				Egg.Blade(S, lib, { base + V3.new(0, 0.1, 0), base + out * (r[2] * 0.6) + V3.new(0, r[3] * 0.5, 0), base + out * r[2] + V3.new(0, r[3] + 0.3, 0) },
					V3.new(-out.Z, 0, out.X), { 0.14, 0.36, 0.03 }, 0.09, r[4])
			end
		end
		Egg.Turned(S, lib, base, { { 0.2, 0.15 }, { 0.16, 0.55 } }, 6, gold)
	end)
end
