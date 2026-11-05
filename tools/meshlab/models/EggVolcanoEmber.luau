--!nocheck
-- Chop a Rock zone egg: Volcano, from the Ember Boulder. Charcoal shell with a network of orange
-- cracks painted on it (assets/Eggs/VolcanoEmber/VolcanoEmber_body.png).

local Egg = require("./EggShell")

return function(em, lib, Shapes)
	Egg.BuildPainted(em, lib, Shapes)
end
