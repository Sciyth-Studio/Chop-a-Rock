--!nocheck
-- Chop a Rock zone decor: DecorBamboo as a small shoot: three short stalks with stepped tips.

local bamboo = require("./DecorBamboo")

return function(em, lib, Shapes, part)
	bamboo(em, lib, Shapes, part, { shoot = true })
end
