--!nocheck
-- Chop a Rock zone egg: Snow, from the Snowy Rock. Deep blue shell with a thick white snow cap that drips down the sides.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local drips = {
		{ 40, 0.46, 0.62 }, { 92, 0.38, 0.66 }, { 150, 0.5, 0.56 }, { 215, 0.42, 0.62 }, { 275, 0.48, 0.56 }, { 330, 0.4, 0.62 },
	}
	Egg.Build(em, lib, Shapes, rgb(40, 110, 235), function(S)
		Egg.Cap(S, lib, 0.62, drips, rgb(245, 250, 255), 0.13)
	end)
end
