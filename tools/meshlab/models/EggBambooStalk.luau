--!nocheck
-- Chop a Rock zone egg: Bamboo, from the Shooty Rock. Jade shell with raised rings like bamboo segments and cone shoots on top.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local ring, shoot = rgb(110, 225, 70), rgb(120, 225, 50)
	Egg.Build(em, lib, Shapes, rgb(40, 200, 70), function(S)
		for _, t in { 0.2, 0.46, 0.72 } do
			Egg.Band(S, lib, t - 0.03, t + 0.03, 0.12, ring)
		end
		for _, c in { { 0, 0, 5.1, 6.85, 0.36 }, { 0.8, 0.1, 4.7, 6.15, 0.32 }, { -0.75, 0.2, 4.7, 6.25, 0.32 }, { 0, -0.8, 4.7, 6.2, 0.32 } } do
			local base = V3.new(c[1], c[3], c[2])
			local tip = V3.new(c[1] * 1.4, c[4], c[2] * 1.4)
			Egg.Along(S, lib, { base, tip }, { c[5], 0.02 }, 6, shoot)
		end
	end)
end
