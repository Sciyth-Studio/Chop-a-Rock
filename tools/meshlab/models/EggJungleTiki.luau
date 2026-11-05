--!nocheck
-- Chop a Rock zone egg: Jungle, from the Tiki Boulder. Golden shell with a tiki face painted on the
-- front (assets/Eggs/JungleTiki/JungleTiki_body.png), palm leaves on top in the texture's leaf row.

local Egg = require("./EggShell")

return function(em, lib, Shapes)
	local V3 = lib.Vector3
	local white = lib.Color3.new(1, 1, 1)
	Egg.BuildPainted(em, lib, Shapes, function(_, solid)
		solid(function(S)
			for k = 1, 7 do
				local a = math.rad(k * 360 / 7)
				local out = V3.new(math.cos(a), 0, -math.sin(a))
				local base = V3.new(0, 5.25, 0)
				Egg.Blade(S, lib, { base, base + out * 0.7 + V3.new(0, 0.55, 0), base + out * 1.65 + V3.new(0, -0.1, 0) },
					V3.new(-out.Z, 0, out.X), { 0.2, 0.44, 0.03 }, 0.08, white)
			end
		end, 0.994)
	end)
end
