--!nocheck
-- Chop a Rock zone egg: Ruins, from the Rune Rock. Dark violet stone shell with all 24 Elder Futhark
-- runes painted around it in three rows (assets/Eggs/RuinsRune/RuinsRune_body.png).

local Egg = require("./EggShell")

return function(em, lib, Shapes)
	Egg.BuildPainted(em, lib, Shapes)
end
