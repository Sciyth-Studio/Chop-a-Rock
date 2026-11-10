--!nocheck
-- Chop a Rock training stand, cut gem family (Obsidian, Diamond, Black Diamond): one shape, three colourways.
-- Frame: two square posts on tapered bevelled feet, a crossbar beam on top, and four prongs rising from the
-- crossbar's corners that lean in to grip the gem. Gem: a faceted cushion cut lying along X on the crossbar
-- (the breakable, tagged TrainingBoard; Glass / transparency and sparkles are set in Studio).
-- Front faces -Z, pivot bottom centre, 5.5 wide, gem centre 3.75 up. Seeds: see StandKit.
local Kit = require("./StandKit")

return function(em, lib, Shapes, part)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rgb = C3.fromRGB
	local palettes = {
		{ frame = rgb(84, 86, 94), gem = rgb(70, 30, 130) },
		{ frame = rgb(172, 176, 186), gem = rgb(200, 232, 255) },
		{ frame = rgb(232, 172, 44), gem = rgb(24, 24, 30) },
	}
	local INF = math.huge
	local postX, post = 1.75, 0.85
	local barTop = 2.95

	Kit.Run(lib, Shapes, part, palettes, {
		frame = function(new, o, pal)
			local S = new("Frame")
			local c = pal.frame
			for _, sx in { -1, 1 } do
				local x = o.X + sx * postX
				Kit.Stack(S, lib, x, o.Z, {
					{ 0, 1.0, 1.1, 0.16 },
					{ 0.45, 1.0, 1.1, 0.16 },
					{ 0.85, 0.66, 0.76, 0.12 },
				}, c)
				S:bevelBox(CF.new(x, (0.85 + 2.35) / 2, o.Z), V3.new(post, 1.5, post), c, 0.05)
			end
			S:bevelBox(CF.new(o.X, 2.65, o.Z), V3.new(5.3, 0.6, 2.0), c, 0.08)
			for _, sx in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local px, pz = o.X + sx * 2.49, o.Z + sz * 0.94
					local ix, iz = -sx * 0.12, -sz * 0.08
					S:loft({
						Kit.Ring(lib, px, barTop, pz, 0.19, 0.19, 0.05, -INF, INF),
						Kit.Ring(lib, px, 3.75, pz, 0.17, 0.17, 0.05, -INF, INF),
						Kit.Ring(lib, px + ix, 4.12, pz + iz, 0.2, 0.2, 0.07, -INF, INF),
						Kit.Ring(lib, px + ix * 1.6, 4.34, pz + iz * 1.6, 0.1, 0.1, 0.04, -INF, INF),
					}, { color = c })
				end
			end
		end,
		breakable = function(new, o, pal, x0, x1)
			local S = new("Gem")
			local y = o.Y
			Kit.Plain(S, lib, function()
				Kit.Stack(S, lib, o.X, o.Z, {
					{ y + barTop + 0.02, 1.9, 0.55, 0.25 },
					{ y + 3.3, 2.35, 0.85, 0.35 },
					{ y + 3.62, 2.55, 1.0, 0.4 },
					{ y + 3.88, 2.55, 1.0, 0.4 },
					{ y + 4.25, 2.35, 0.85, 0.35 },
					{ y + 4.55, 2.0, 0.6, 0.25 },
				}, pal.gem, x0, x1)
			end)
		end,
	})
end
