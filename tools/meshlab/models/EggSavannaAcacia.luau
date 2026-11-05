--!nocheck
-- Chop a Rock zone egg: Savanna, from the Acacia Boulder. Red-orange shell with a small flat-topped acacia on top.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local bark, leaf = rgb(115, 70, 40), rgb(72, 120, 40)
	Egg.Build(em, lib, Shapes, rgb(225, 85, 35), function(S)
		local base = V3.new(0, 5.25, 0)
		local fork = base + V3.new(0, 0.35, 0)
		Egg.Along(S, lib, { base, fork }, { 0.24, 0.2 }, 6, bark)
		for _, s in { 1, -1 } do
			Egg.Along(S, lib, { fork, fork + V3.new(s * 0.55, 0.5, 0) }, { 0.16, 0.11 }, 5, bark)
		end
		Egg.Turned(S, lib, V3.new(0, 6, 0), { { 1.0, 0 }, { 1.7, 0.2 }, { 1.5, 0.58 }, { 0.8, 0.82 } }, 6, leaf)
	end)
end
