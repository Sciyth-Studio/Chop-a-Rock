--!nocheck
-- Chop a Rock Boss Arena: DecorCrystalCluster recoloured ice blue for the Frost Yeti's set.

local cluster = require("./DecorCrystalCluster")

return function(em, lib, Shapes, part)
	cluster(em, lib, Shapes, part, { ice = true })
end
