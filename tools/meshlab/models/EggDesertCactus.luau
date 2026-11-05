--!nocheck
-- Chop a Rock zone egg: Desert, from the Cactus Boulder. Terracotta shell with two small saguaros on its upper sides.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local green = rgb(60, 190, 60)
	Egg.Build(em, lib, Shapes, rgb(230, 90, 40), function(S)
		for _, a in { 35, 145 } do
			local rad = math.rad(a)
			local out = V3.new(math.cos(rad), 0, -math.sin(rad))
			local side = V3.new(if a < 90 then 1 else -1, 0, 0)
			local base = out * 1.45 + V3.new(0, 3.9, 0)
			Egg.Along(S, lib, { base, base + V3.new(0, 1.5, 0), base + V3.new(0, 2.5, 0), base + V3.new(0, 2.85, 0) },
				{ 0.46, 0.46, 0.46, 0.26 }, 8, green)
			local joint = base + V3.new(0, 1.25, 0)
			Egg.Along(S, lib, { joint, joint + side * 0.72, joint + side * 0.8 + V3.new(0, 0.75, 0), joint + side * 0.8 + V3.new(0, 0.95, 0) },
				{ 0.26, 0.26, 0.26, 0.15 }, 6, green)
		end
	end)
end
