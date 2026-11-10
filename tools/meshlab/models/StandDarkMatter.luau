--!nocheck
-- Chop a Rock training stand, Dark Matter (space finale one-off).
-- Frame: two tall dark pillars on chamfered plinths joined by a low base beam; each pillar's top forks into a tall
-- outer finger and a short inner tooth that cup the cube (Frame), with purple glow strips up the pillar fronts and
-- plinths (Glow, Neon in Studio). Breakable: a plain cube floating between them (Cube, tagged TrainingBoard; the
-- swirl is a decal or texture in Studio). Front faces -Z, pivot bottom centre, 5.5 wide, cube centre 3.65 up.
local Kit = require("./StandKit")

return function(em, lib, Shapes, part)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rgb = C3.fromRGB
	local palettes = { { frame = rgb(54, 48, 64), glow = rgb(176, 84, 255), cube = rgb(92, 42, 176) } }
	local postX, cube = 1.9, 1.9

	Kit.Run(lib, Shapes, part, palettes, {
		frame = function(new, o, pal)
			local S = new("Frame")
			local G = new("Glow")
			local c = pal.frame
			for _, sx in { -1, 1 } do
				local x = o.X + sx * postX
				Kit.Stack(S, lib, x, o.Z, {
					{ 0, 0.85, 0.95, 0.16 },
					{ 0.4, 0.85, 0.95, 0.16 },
					{ 0.8, 0.6, 0.7, 0.18 },
				}, c)
				Kit.Stack(S, lib, x, o.Z, {
					{ 0.75, 0.5, 0.48, 0.1 },
					{ 3.45, 0.45, 0.44, 0.1 },
				}, c)
				Kit.Stack(S, lib, x + sx * 0.2, o.Z, {
					{ 3.4, 0.25, 0.44, 0.06 },
					{ 4.55, 0.25, 0.42, 0.06 },
					{ 4.85, 0.16, 0.34, 0.08 },
				}, c)
				Kit.Stack(S, lib, x - sx * 0.24, o.Z, {
					{ 3.4, 0.21, 0.44, 0.06 },
					{ 3.85, 0.21, 0.42, 0.06 },
					{ 4.0, 0.12, 0.34, 0.06 },
				}, c)
				Kit.Plain(G, lib, function()
					local zf = o.Z - 0.46
					G:bevelBox(CF.new(x, 2.05, zf), V3.new(0.12, 2.3, 0.06), pal.glow, 0)
					local a, b = V3.new(x, 3.2, zf - 0.005), V3.new(x + sx * 0.22, 4.4, zf - 0.005)
					G:bevelBox(Shapes.Props.lookAt(lib, (a + b) / 2, (b - a).Unit), V3.new(0.12, 0.06, (b - a).Magnitude), pal.glow, 0)
					local fz = o.Z - 0.82
					G:bevelBox(CF.new(x, 0.32, fz) * CF.Angles(-math.atan2(0.25, 0.4), 0, 0), V3.new(0.12, 0.45, 0.06), pal.glow, 0)
				end)
			end
			S:bevelBox(CF.new(o.X, 0.25, o.Z), V3.new(3.0, 0.4, 1.3), c, 0.06)
		end,
		breakable = function(new, o, pal, x0, x1)
			local S = new("Cube")
			local h = cube / 2
			local a, b = math.max(x0, -h), math.min(x1, h)
			Kit.Plain(S, lib, function()
				S:bevelBox(CF.new(o.X + (a + b) / 2, o.Y + 3.65, o.Z), V3.new(b - a, cube, cube), pal.cube, 0.06)
			end)
		end,
	})
end
