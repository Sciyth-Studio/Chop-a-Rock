--!nocheck
-- Chop a Rock zone decor: DecorDeadTree for the volcano zone, in charcoal bark.

local deadTree = require("./DecorDeadTree")

return function(em, lib, Shapes, part)
	deadTree(em, lib, Shapes, part, { charred = true })
end
