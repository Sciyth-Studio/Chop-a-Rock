--!nocheck
-- Chop a Rock zone egg: Snow, from the Drift Boulder. Sky blue shell, a wide white snow collar with icicles hanging from it.

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local snow, ice = rgb(245, 250, 255), rgb(190, 235, 255)
	Egg.Build(em, lib, Shapes, rgb(0, 170, 255), function(S)
		Egg.Band(S, lib, 0.44, 0.6, 0.36, snow)
		for k = 1, 12 do
			local a = k * 30 + 5
			local long = if k % 2 == 0 then 1.35 else 0.85
			local base = Egg.Point(lib, a, 0.46, 0.14)
			Egg.Along(S, lib, { base, base + V3.new(0, -long, 0) }, { 0.36, 0.04 }, 5, ice)
		end
	end)
end
