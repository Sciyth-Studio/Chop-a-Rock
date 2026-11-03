--!nocheck
-- Chop a Rock zone decor: DecorBush for the swamp zone, greens close to the swamp floor (50, 70, 40).

local bush = require("./DecorBush")

return function(em, lib, Shapes, part)
	bush(em, lib, Shapes, part, { leaf = lib.Color3.fromRGB(56, 82, 42), patch = lib.Color3.fromRGB(70, 100, 50) })
end
