--!nocheck
-- Chop a Rock zone decor: DecorSnowPile for the volcano zone, grey ash on a charcoal base.

local pile = require("./DecorSnowPile")

return function(em, lib, Shapes, part)
	pile(em, lib, Shapes, part, { ash = true })
end
