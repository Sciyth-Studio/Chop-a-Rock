--!nocheck
-- Chop a Rock zone egg: Swamp, from the Muddy Rock. Lime shell with a mud cap dripping down, cattails beside the base.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local mud, stem, head, leaf = rgb(85, 60, 35), rgb(70, 130, 50), rgb(115, 65, 30), rgb(60, 150, 50)
	local drips = {
		{ 35, 0.5, 0.5 }, { 95, 0.42, 0.56 }, { 140, 0.54, 0.46 }, { 210, 0.46, 0.54 }, { 280, 0.5, 0.48 }, { 335, 0.44, 0.52 },
	}
	Egg.Build(em, lib, Shapes, rgb(170, 210, 60), function(S)
		Egg.Cap(S, lib, 0.64, drips, mud)
		for _, c in { { 1.45, -1.75, 2.4 }, { 0.75, -2.15, 1.75 } } do
			local base = V3.new(c[1], 0, c[2])
			local top = base + V3.new(0.1, c[3], -0.15)
			Egg.Along(S, lib, { base, top }, { 0.1, 0.07 }, 4, stem)
			Egg.Along(S, lib, { top - V3.new(0, 0.8, 0), top - V3.new(0, 0.7, 0), top + V3.new(0, 0.05, 0) }, { 0.12, 0.24, 0.16 }, 5, head)
		end
		local root = V3.new(1.1, 0, -2)
		for _, s in { -1, 1 } do
			local side = V3.new(0.8, 0, 0.6)
			Egg.Blade(S, lib, { root, root + side * (s * 0.3) + V3.new(0, 0.5, 0), root + side * (s * 0.8) + V3.new(0, 0.95, 0) },
				V3.new(0.6, 0, -0.8), { 0.2, 0.17, 0.02 }, 0.04, leaf)
		end
	end)
end
