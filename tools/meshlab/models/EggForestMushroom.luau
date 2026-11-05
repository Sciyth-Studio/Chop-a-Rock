--!nocheck
-- Chop a Rock zone egg: Forest, from the zone's Mushroom decor. Red shell with raised white spots
-- and two small spotted mushrooms at the front of the base.

local Egg = require("./EggShell")

local spots = {
	{ 70, 0.74, 0.62 }, { 125, 0.5, 0.72 }, { 45, 0.42, 0.56 }, { 165, 0.74, 0.5 },
	{ 205, 0.46, 0.68 }, { 262, 0.72, 0.6 }, { 300, 0.36, 0.7 }, { 350, 0.66, 0.56 },
}

return function(em, lib, Shapes)
	local V3, C3 = lib.Vector3, lib.Color3
	local red, white = C3.fromRGB(225, 40, 35), C3.fromRGB(250, 250, 250)
	local stem, gill = C3.fromRGB(235, 205, 150), C3.fromRGB(240, 225, 190)
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	local S = Shapes.new(em, lib)

	local function mushroom(x, z, scale)
		local base = V3.new(x, 0, z)
		Egg.Turned(S, lib, base, {
			{ 0.36 * scale, 0 },
			{ 0.28 * scale, 0.3 * scale },
			{ 0.28 * scale, 0.9 * scale },
		}, 8, stem)
		Egg.Turned(S, lib, base, {
			{ 0.85 * scale, 0.75 * scale },
			{ 0.85 * scale, 0.94 * scale },
			{ 0.62 * scale, 1.28 * scale },
			{ 0.26 * scale, 1.46 * scale },
		}, 8, function(i, k)
			return if k == 0 and i == 1 then gill else red
		end)
		for _, spot in { { 70, 0.45 }, { 210, 0.45 } } do
			local a = math.rad(spot[1])
			local out = V3.new(math.cos(a), 0, -math.sin(a))
			Egg.Disc(S, lib, base + out * (spot[2] * scale) + V3.new(0, 1.32 * scale, 0), (out + V3.new(0, 0.9, 0)).Unit,
				0.24 * scale, 0.05, white, 5)
		end
	end

	Egg.Shell(S, lib, red)
	Egg.plain(em, lib, function()
		for _, spot in spots do
			Egg.Disc(S, lib, Egg.Point(lib, spot[1], spot[2], -0.1), Egg.Normal(lib, spot[1], spot[2]), spot[3], 0.1, white, 8)
		end
		mushroom(1.0, -1.95, 1.2)
		mushroom(-0.65, -2.2, 0.85)
	end)
	Shapes.PITCH = pitch
end
