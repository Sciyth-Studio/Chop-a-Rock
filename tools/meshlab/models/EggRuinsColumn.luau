--!nocheck
-- Chop a Rock zone egg: Ruins, from the Pillar Boulder. Sandstone shell with fluted grooves, a raised ring near the top, a moss patch.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local stone, groove, moss = rgb(222, 192, 132), rgb(170, 135, 85), rgb(120, 160, 60)
	Egg.Build(em, lib, Shapes, function(i, k)
		return if i >= 2 and i <= 5 and k % 2 == 0 then groove else stone
	end, function(S)
		Egg.Band(S, lib, 0.74, 0.83, 0.16, rgb(235, 205, 145))
		for _, m in { { 120, 0.74, 0.5 }, { 134, 0.66, 0.42 }, { 108, 0.65, 0.34 } } do
			Egg.Disc(S, lib, Egg.Point(lib, m[1], m[2], 0.12), Egg.Normal(lib, m[1], m[2]), m[3], 0.12, moss, 6)
		end
	end)
end
