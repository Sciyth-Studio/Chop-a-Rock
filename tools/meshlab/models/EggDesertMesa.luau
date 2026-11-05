--!nocheck
-- Chop a Rock zone egg: Desert, from the Sandstone rock. Orange and red stepped bands, a grass tuft on top.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local orange, red, green = rgb(255, 130, 40), rgb(200, 70, 30), rgb(70, 170, 50)
	Egg.Build(em, lib, Shapes, function(i)
		return if i % 2 == 0 then red else orange
	end, function(S)
		for _, band in { { 0.07, 0.2 }, { 0.36, 0.52 }, { 0.68, 0.82 } } do
			Egg.Band(S, lib, band[1], band[2], 0.08, red)
		end
		for k = 1, 7 do
			local a = math.rad(k * 360 / 7)
			local out = V3.new(math.cos(a), 0, -math.sin(a))
			local base = V3.new(0, 5.3, 0)
			Egg.Blade(S, lib, { base, base + out * 0.35 + V3.new(0, 0.55, 0), base + out * 0.75 + V3.new(0, 1.05, 0) },
				V3.new(-out.Z, 0, out.X), { 0.28, 0.26, 0.03 }, 0.07, green)
		end
	end)
end
