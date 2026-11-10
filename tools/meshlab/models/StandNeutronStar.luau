--!nocheck
-- Chop a Rock training stand, Neutron Star (space finale one-off).
-- Frame: two silver posts on chamfered plinths joined by a low base beam, each topped by a fork cradle, and two flat
-- crossed rings round the star resting in the forks (Frame), with blue glow strips up the post fronts (Glow, Neon).
-- Breakable: a faceted glowing sphere (Star, tagged TrainingBoard, plain, Neon in Studio), lofted along X so it
-- cuts cleanly at x = 0. Front faces -Z, pivot bottom centre, 5.5 wide, star centre 3.7 up.
local Kit = require("./StandKit")

return function(em, lib, Shapes, part)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rgb = C3.fromRGB
	local palettes = { { frame = rgb(176, 184, 198), glow = rgb(90, 170, 255), star = rgb(206, 232, 255) } }
	local postX, R, cy = 1.95, 1.5, 3.7

	local function ring(S, tilt, yaw, radius, w, t, color)
		local cf = CF.new(0, cy, 0) * CF.Angles(0, yaw, 0) * CF.Angles(0, 0, tilt)
		local rings = {}
		for i = 0, 24 do
			local a = i / 24 * math.pi * 2
			local dir = V3.new(math.cos(a), 0, math.sin(a))
			local up = V3.new(0, 1, 0)
			local pts = {}
			for _, p in { { -t, -w }, { t, -w }, { t, w }, { -t, w } } do
				table.insert(pts, cf * (dir * (radius + p[1]) + up * p[2]))
			end
			table.insert(rings, pts)
		end
		S:loft(rings, { color = color, caps = false })
	end

	Kit.Run(lib, Shapes, part, palettes, {
		frame = function(new, o, pal)
			local S = new("Frame")
			local G = new("Glow")
			local c = pal.frame
			for _, sx in { -1, 1 } do
				local x = o.X + sx * postX
				Kit.Stack(S, lib, x, o.Z, {
					{ 0, 0.9, 1.0, 0.18 },
					{ 0.4, 0.9, 1.0, 0.18 },
					{ 0.85, 0.62, 0.72, 0.2 },
				}, c)
				Kit.Stack(S, lib, x, o.Z, {
					{ 0.8, 0.42, 0.42, 0.1 },
					{ 2.15, 0.42, 0.42, 0.1 },
					{ 2.4, 0.5, 0.5, 0.14 },
					{ 2.6, 0.5, 0.5, 0.14 },
				}, c)
				for _, f in { { 0.3, 3.5 }, { -0.3, 2.95 } } do
					Kit.Stack(S, lib, x + sx * f[1], o.Z, {
						{ 2.55, 0.14, 0.36, 0.04 },
						{ f[2], 0.13, 0.32, 0.04 },
						{ f[2] + 0.15, 0.07, 0.24, 0.04 },
					}, c)
				end
				Kit.Plain(G, lib, function()
					G:bevelBox(CF.new(x, 1.5, o.Z - 0.43), V3.new(0.12, 1.1, 0.06), pal.glow, 0)
				end)
			end
			S:bevelBox(CF.new(o.X, 0.22, o.Z), V3.new(3.0, 0.36, 1.1), c, 0.06)
			ring(S, math.rad(28), math.rad(18), 1.95, 0.16, 0.1, c)
			ring(S, math.rad(-28), math.rad(-18), 1.95, 0.16, 0.1, c)
		end,
		breakable = function(new, o, pal, x0, x1)
			local S = new("Star")
			local rings = {}
			local steps = 8
			for i = 0, steps do
				local x = -R + 2 * R * i / steps
				if x >= x0 - 1e-6 and x <= x1 + 1e-6 then
					local r = math.sqrt(math.max(R * R - x * x, 0.0004))
					local pts = {}
					for s = 0, 11 do
						local a = s / 12 * math.pi * 2
						table.insert(pts, V3.new(o.X + x, o.Y + cy + math.cos(a) * r, o.Z + math.sin(a) * r))
					end
					table.insert(rings, pts)
				end
			end
			Kit.Plain(S, lib, function()
				S:loft(rings, { color = pal.star })
			end)
		end,
	})
end
