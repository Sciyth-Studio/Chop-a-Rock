--!nocheck
-- Chop a Rock Boss Arena: fire bowl (assets/Arena/LineupA.webp #3) in the JungleTree stud-block
-- style, the same bowl the tower carries. A flared dark foot, a short pedestal, a wide shallow
-- stepped bowl and a heaped mound of orange and yellow coals; flames are particles in Studio.
-- ~13 wide, ~12 tall at scale 1.6. Studs 1 per stud. Base on Y = 0, front -Z.

local Arena = require("./ArenaParts")

return function(em, lib, Shapes)
	local V3, C3 = lib.Vector3, lib.Color3
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	local S = Shapes.new(em, lib)
	Arena.Bowl(S, lib, V3.new(0, 0, 0), 1.6, Arena.Colors(C3))
	Shapes.PITCH = pitch
end
