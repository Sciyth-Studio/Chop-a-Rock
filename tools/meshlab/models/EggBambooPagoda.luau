--!nocheck
-- Chop a Rock zone egg: Bamboo, from the Pagoda Boulder. Pale stone shell, two red roof tiers as a cap, a dark arched window.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local red, dark = rgb(200, 50, 40), rgb(110, 70, 40)
	Egg.Build(em, lib, Shapes, rgb(235, 220, 185), function(S)
		Egg.Turned(S, lib, V3.new(), { { 2.95, 3.65 }, { 2.95, 3.8 }, { 2.1, 4.35 }, { 1.6, 4.85 } }, 8, red)
		Egg.Turned(S, lib, V3.new(), { { 1.85, 4.68 }, { 1.85, 4.8 }, { 1.05, 5.4 }, { 0.42, 6 }, { 0.1, 6.85 } }, 8, red)
		Egg.Stripe(S, lib, 90, 0.14, 90, 0.33, 0.42, 0.05, dark, 2)
		Egg.Disc(S, lib, Egg.Point(lib, 90, 0.33, 0), Egg.Normal(lib, 90, 0.33), 0.42, 0.05, dark, 8)
	end)
end
