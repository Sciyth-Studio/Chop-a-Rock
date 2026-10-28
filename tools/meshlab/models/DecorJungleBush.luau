--!nocheck
-- Chop a Rock zone decor: DecorBush for the jungle, greens close to the jungle floor.

local bush = require("./DecorBush")

return function(em, lib, Shapes, part)
	bush(em, lib, Shapes, part, { jungle = true })
end
