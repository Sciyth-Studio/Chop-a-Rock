--!nocheck
-- Chop a Rock zone decor: DecorPine for the snow zone, darker greens with snow on every course.

local pine = require("./DecorPine")

return function(em, lib, Shapes, part)
	pine(em, lib, Shapes, part, { snow = true })
end
