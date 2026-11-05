--!nocheck
-- Chop a Rock zone egg: Ocean, from the Reef Boulder. Coral pink shell, a short branching coral on top, a starfish on the side.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local coral, star = rgb(255, 40, 140), rgb(255, 140, 20)
	Egg.Build(em, lib, Shapes, rgb(255, 90, 120), function(S)
		local base = V3.new(0, 5.2, 0)
		local fork = base + V3.new(0, 0.55, 0)
		Egg.Along(S, lib, { base, fork }, { 0.36, 0.3 }, 6, coral)
		for _, b in { { 0.95, 0.65, 0.1 }, { -0.95, 0.75, -0.1 }, { 0.15, 1.1, 0.7 }, { -0.15, 1, -0.7 } } do
			local tip = fork + V3.new(b[1], b[2], b[3])
			local mid = fork + V3.new(b[1] * 0.6, b[2] * 0.35, b[3] * 0.6)
			Egg.Along(S, lib, { fork, mid, tip }, { 0.26, 0.24, 0.17 }, 6, coral)
		end
		local a, t = 118, 0.36
		Egg.Star(S, lib, Egg.Point(lib, a, t, 0.02), Egg.Normal(lib, a, t), 1.05, 0.42, 0.16, star)
	end)
end
