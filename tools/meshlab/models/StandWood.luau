--!nocheck
-- Chop a Rock training stand, Wood (first stand), remodelled 2026-11-09 to match the meshlab stand ladder.
-- Frame: two square posts on chamfered feet with triangular braces front and back, a low crossbar between the feet
-- and a cap block on each post top (Frame, orange pine). Breakable: two stacked cream pine planks across the caps
-- (Board, tagged TrainingBoard). Front faces -Z, pivot bottom centre, 5.5 wide, board centre 3.6 up. Seeds: see StandKit.
local Kit = require("./StandKit")

return function(em, lib, Shapes, part)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rgb = C3.fromRGB
	local palettes = { { frame = rgb(190, 90, 30), board = rgb(248, 217, 109) } }
	local postX, post = 1.85, 0.85
	local boardY = 3.25

	local function brace(S, x, sx, color)
		local function tri(z)
			local pts = {}
			for _, p in { { 0, 0.62 }, { 0, 1.55 }, { 0.62, 0.62 } } do
				table.insert(pts, V3.new(x + sx * (post / 2 + p[1] - 0.02), p[2], z))
			end
			return pts
		end
		S:loft({ tri(-0.16), tri(0.16) }, { color = color })
	end

	Kit.Run(lib, Shapes, part, palettes, {
		frame = function(new, o, pal)
			local S = new("Frame")
			local c = pal.frame
			for _, sx in { -1, 1 } do
				local x = o.X + sx * postX
				Kit.Stack(S, lib, x, o.Z, {
					{ 0, 0.82, 0.95, 0.14 },
					{ 0.42, 0.82, 0.95, 0.14 },
					{ 0.62, 0.62, 0.75, 0.14 },
				}, c)
				S:bevelBox(CF.new(x, (0.62 + boardY - 0.22) / 2, o.Z), V3.new(post, boardY - 0.22 - 0.62, post), c, 0.05)
				S:bevelBox(CF.new(x, boardY - 0.11, o.Z), V3.new(1.1, 0.22, 1.2), c, 0.04)
				Kit.Plain(S, lib, function()
					brace(S, x, -1, c)
					brace(S, x, 1, c)
				end)
			end
			S:bevelBox(CF.new(o.X, 0.3, o.Z), V3.new(2 * postX - 1.2, 0.36, 0.5), c, 0.04)
		end,
		breakable = function(new, o, pal, x0, x1)
			local S = new("Board")
			for i, layer in { { 5.1, 0, 0 }, { 4.9, 0.06, 1 } } do
				local hw = layer[1] / 2
				local a, b = math.max(x0, -hw + layer[2]), math.min(x1, hw + layer[2])
				local y = o.Y + boardY + 0.18 + layer[3] * 0.36
				S:bevelBox(CF.new(o.X + (a + b) / 2, y, o.Z), V3.new(b - a, 0.36, 1.3), pal.board, 0.05)
			end
		end,
	})
end
