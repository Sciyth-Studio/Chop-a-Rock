--!nocheck
-- Chop a Rock zone egg: Volcano, from the Crater Boulder. Orange shell cut off at the top with a
-- red rim holding a glowing pool (part Glow, for Neon). The jagged red edge running down from the
-- rim is painted on (assets/Eggs/VolcanoCrater/VolcanoCrater_body.png).

local Egg = require("./EggShell")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local white = C3.new(1, 1, 1)
	local glowMesh = part("Glow")
	local G = Shapes.new(glowMesh, lib)
	Egg.BuildPainted(em, lib, Shapes, function(_, solid)
		solid(function(S)
			local rings = {}
			for i, row in { { 1.54, 4.59 }, { 1.42, 5.02 }, { 1.24, 5.12 }, { 1.12, 5.12 } } do
				local ring = {}
				for k = 1, Egg.Sides do
					local a = math.rad((k - 1) * 360 / Egg.Sides + 15)
					ring[k] = V3.new(math.cos(a) * row[1], row[2], -math.sin(a) * row[1])
				end
				rings[i] = ring
			end
			S:loft(rings, { color = white })
		end, 0.95)
	end, 0.82)
	Egg.Turned(G, lib, V3.new(0, 5.1, 0), { { 1.14, 0 }, { 1.1, 0.06 } }, 12, C3.fromRGB(255, 90, 0))
	local flat = glowMesh:AddUV(lib.Vector2.new(0.5, 0.995))
	for _, f in glowMesh:GetFaces() do
		glowMesh:SetFaceUVs(f, { flat, flat, flat })
	end
end
