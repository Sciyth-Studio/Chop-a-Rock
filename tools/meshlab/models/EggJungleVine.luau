--!nocheck
-- Chop a Rock zone egg: Jungle, from the Vine Boulder. Tan shell, a thick vine spiralling up it, leaves and yellow flowers.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local vine, leaf, yellow, orange = rgb(50, 160, 50), rgb(60, 185, 60), rgb(255, 220, 20), rgb(240, 130, 20)
	Egg.Build(em, lib, Shapes, rgb(210, 160, 90), function(S)
		local path, radii = {}, {}
		for i = 0, 20 do
			local f = i / 20
			path[i + 1] = Egg.Point(lib, 20 + f * 860, 0.12 + f * 0.8, 0.06)
			radii[i + 1] = 0.27
		end
		Egg.Along(S, lib, path, radii, 4, vine)
		for _, spot in { { 0.1, 1 }, { 0.3, -1 }, { 0.48, 1 }, { 0.66, -1 }, { 0.84, 1 } } do
			local f = spot[1]
			local a, t = 20 + f * 860, 0.12 + f * 0.8
			local normal = Egg.Normal(lib, a, t)
			Egg.Star(S, lib, Egg.Point(lib, a, t, 0.28), normal, 0.62, 0.42, 0.07, yellow)
			Egg.Disc(S, lib, Egg.Point(lib, a, t, 0.36), normal, 0.17, 0.05, orange, 5)
			local leafAt = Egg.Point(lib, a + 16, t + spot[2] * 0.03, 0.1)
			local tip = Egg.Point(lib, a + 38, t + spot[2] * 0.13, 0.14)
			local side = (tip - leafAt):Cross(normal).Unit
			Egg.Blade(S, lib, { leafAt, (leafAt + tip) / 2, tip }, side, { 0.1, 0.3, 0.02 }, 0.04, leaf)
		end
	end)
end
