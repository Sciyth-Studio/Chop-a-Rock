--!nocheck
-- Chop a Rock zone egg: Ocean, from the Barnacle Rock. Cyan shell covered in hollow-topped cream cones.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local cream, hollow = rgb(240, 225, 185), rgb(170, 150, 110)
	local spots = {
		{ 90, 0.72, 0.62 }, { 55, 0.46, 0.5 }, { 122, 0.44, 0.66 }, { 88, 0.2, 0.46 }, { 25, 0.74, 0.46 }, { 155, 0.76, 0.5 },
		{ 185, 0.38, 0.6 }, { 235, 0.68, 0.6 }, { 250, 0.26, 0.5 }, { 300, 0.48, 0.58 }, { 345, 0.72, 0.42 }, { 5, 0.3, 0.56 }, { 145, 0.16, 0.42 },
	}
	Egg.Build(em, lib, Shapes, rgb(0, 190, 255), function(S)
		for _, spot in spots do
			local normal = Egg.Normal(lib, spot[1], spot[2])
			local base = Egg.Point(lib, spot[1], spot[2], -0.14)
			local tip = base + normal * (spot[3] * 0.85)
			Egg.Along(S, lib, { base, tip }, { spot[3], spot[3] * 0.62 }, 6, cream)
			Egg.Disc(S, lib, tip, normal, spot[3] * 0.4, 0.02, hollow, 5)
		end
	end)
end
