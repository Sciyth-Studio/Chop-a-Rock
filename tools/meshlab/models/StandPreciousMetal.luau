--!nocheck
-- Chop a Rock training stand, precious metal family (Silver, Gold, Platinum): one shape, three colours.
-- Two square posts on tapered bevelled feet with a raised diamond emblem on each foot's front (Frame), and an ingot
-- bar across the post tops with bevelled sloping top edges (Bar, the breakable, tagged TrainingBoard).
-- Front faces -Z, pivot bottom centre, 5.5 wide, bar centre 3.6 up. Seeds: see StandKit.
local Kit = require("./StandKit")

return function(em, lib, Shapes, part)
	local V3, C3 = lib.Vector3, lib.Color3
	local rgb = C3.fromRGB
	local palettes = {
		{ metal = rgb(200, 204, 212) },
		{ metal = rgb(236, 172, 38) },
		{ metal = rgb(188, 202, 226) },
	}
	local postX, post = 1.75, 0.85
	local barW, barH, barD, barY = 5.4, 1.0, 1.1, 3.1

	local function diamond(S, c, x, color)
		local up = V3.new(0, 0.66, 0.255).Unit
		local n = V3.new(0, 0.255, -0.66).Unit
		local right = V3.new(1, 0, 0)
		local centre = V3.new(x, 0.47, -0.8475) + n * 0.01
		local base, top = {}, {}
		for _, p in { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } } do
			table.insert(base, centre + right * p[1] * 0.22 + up * p[2] * 0.28)
			table.insert(top, centre + n * 0.15 + right * p[1] * 0.05 + up * p[2] * 0.06)
		end
		S:loft({ base, top }, { color = color })
	end

	Kit.Run(lib, Shapes, part, palettes, {
		frame = function(new, o, pal)
			local S = new("Frame")
			for _, sx in { -1, 1 } do
				local x = o.X + sx * postX
				Kit.Stack(S, lib, x, o.Z, {
					{ 0, 0.975, 0.975, 0.06 },
					{ 0.14, 0.975, 0.975, 0.06 },
					{ 0.8, 0.72, 0.72, 0.06 },
				}, pal.metal)
				Kit.Stack(S, lib, x, o.Z, {
					{ 0.8, 0.55, 0.55, 0.05 },
					{ 0.94, 0.55, 0.55, 0.05 },
				}, pal.metal)
				S:bevelBox(lib.CFrame.new(x, (0.94 + barY) / 2, o.Z), V3.new(post, barY - 0.94, post), pal.metal, 0.05)
				diamond(S, o, x, pal.metal)
			end
		end,
		breakable = function(new, o, pal, x0, x1)
			local S = new("Bar")
			local hw, hd = barW / 2, barD / 2
			Kit.Stack(S, lib, o.X, o.Z, {
				{ o.Y + barY, hw - 0.05, hd - 0.05, 0.05 },
				{ o.Y + barY + 0.07, hw, hd, 0.07 },
				{ o.Y + barY + barH * 0.62, hw, hd, 0.07 },
				{ o.Y + barY + barH, hw - 0.32, hd - 0.26, 0.05 },
			}, pal.metal, x0, x1)
		end,
	})
end
