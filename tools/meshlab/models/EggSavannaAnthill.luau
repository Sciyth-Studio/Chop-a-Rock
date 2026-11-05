--!nocheck
-- Chop a Rock zone egg: Savanna, from the Anthill Boulder. Brown shell with one tall termite spire and three short ones, off-centre.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local mound = rgb(165, 100, 55)
	Egg.Build(em, lib, Shapes, rgb(130, 85, 55), function(S)
		for _, c in { { 0.15, 0.1, 4.6, 6.85, 0.72 }, { 1.05, 0.2, 3.9, 6.05, 0.46 }, { -0.9, 0.25, 4.1, 6.15, 0.46 }, { -0.1, -0.95, 4, 5.9, 0.4 } } do
			local base = V3.new(c[1], c[3], c[2])
			local h = c[4] - c[3]
			Egg.Turned(S, lib, base, { { c[5], 0 }, { c[5] * 0.76, h * 0.5 }, { c[5] * 0.5, h * 0.82 }, { c[5] * 0.16, h } }, 7, mound)
		end
	end)
end
