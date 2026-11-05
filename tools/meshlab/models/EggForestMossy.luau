--!nocheck
-- Chop a Rock zone egg: Forest, from the Mossy Boulder. Cream shell with a thick moss cap that
-- runs down the sides in uneven drips.

local Egg = require("./EggShell")

local drips = {
	{ 25, 0.42, 0.5 }, { 62, 0.5, 0.42 }, { 97, 0.36, 0.54 }, { 142, 0.48, 0.44 },
	{ 205, 0.38, 0.52 }, { 265, 0.46, 0.46 }, { 320, 0.34, 0.54 },
}

return function(em, lib, Shapes)
	local C3 = lib.Color3
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	local S = Shapes.new(em, lib)
	Egg.Shell(S, lib, C3.fromRGB(235, 225, 190))
	Egg.plain(em, lib, function()
		Egg.Cap(S, lib, 0.62, drips, C3.fromRGB(80, 200, 30))
	end)
	Shapes.PITCH = pitch
end
