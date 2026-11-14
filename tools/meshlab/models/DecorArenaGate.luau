--!nocheck
-- Chop a Rock Boss Arena: gate arch (assets/Arena/LineupA.webp #2) in the JungleTree stud-block
-- style. Two square pillars on dark plinths with dark capitals, a heavy 10-stud lintel with dark end
-- blocks and a sunken dark sign panel on the front, and five ivory tusks along the top, the middle
-- one tallest, each a stack of shrinking courses curving a little forward. Built at the gateway's
-- world size: 84 wide, opening 58 wide x 44 tall, ~85 tall to the tallest tusk tip.
-- Studs 1 per stud. Base on Y = 0, front -Z, centred on X = 0.

local Arena = require("./ArenaParts")

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	local S = Shapes.new(em, lib)
	local c = Arena.Colors(C3)
	local k = Arena.Kit(S, lib)

	local pillarX = 35.5
	local depth = 14

	local function pillar(x)
		k.block(CF.new(x, 2.5, 0), V3.new(17.5, 5, depth + 3.5), c.stoneDeep)
		k.block(CF.new(x, 6, 0), V3.new(15.5, 2, depth + 1.5), c.stoneDark)
		local y = 7
		local i = 0
		while y < 37.9 do
			local h = math.min(4, 38 - y)
			local inset = if i % 2 == 0 then 0 else 0.5
			k.block(CF.new(x, y + h / 2, 0), V3.new(13 - inset, h + 0.02, depth - inset), if i % 2 == 0 then c.stone else c.stoneLight)
			y += h
			i += 1
		end
		k.block(CF.new(x, 39.5, 0), V3.new(15.5, 3, depth + 1.5), c.stoneDark)
		k.block(CF.new(x, 42.5, 0), V3.new(14, 3, depth + 0.8), c.stoneDeep)
	end
	pillar(-pillarX)
	pillar(pillarX)

	k.block(CF.new(0, 49, 0), V3.new(86, 10, depth + 0.6), c.stone)
	for _, x in { -pillarX, pillarX } do
		k.block(CF.new(x, 49, 0), V3.new(17, 11, depth + 2.2), c.stoneDark)
	end
	k.block(CF.new(0, 54.6, 0), V3.new(88, 1.2, depth + 2.6), c.stoneDeep)
	k.block(CF.new(0, 49, -(depth + 0.6) / 2 + 0.25), V3.new(44, 7, 1.0), c.stoneDeep)
	k.block(CF.new(0, 49, -(depth + 0.6) / 2 - 0.15), V3.new(40, 5.4, 0.5), c.stoneDark)

	local P = Shapes.Props
	local tusks = { { -29, 18 }, { -14.5, 23 }, { 0, 30 }, { 14.5, 23 }, { 29, 18 } }
	for _, t in tusks do
		local x, height = t[1], t[2]
		local segments = 6
		local points = {}
		for i = 0, segments do
			local f = i / segments
			local angle = f * f * math.rad(38)
			table.insert(points, V3.new(x, 55.2 + math.sin(math.pi / 2 - angle * 0.5) * f * height, -math.sin(angle) * f * height * 0.55))
		end
		k.cross(CF.new(x, 55.9, 0), 9.4, 1.4, c.ivoryDark, 0.86)
		for i = 1, segments do
			local from, to = points[i], points[i + 1]
			local dir = (to - from).Unit
			local f = (i - 1) / segments
			local thick = 7.6 * (1 - f * 0.82)
			P.limb(S, lib, from - dir * 0.3, dir, (to - from).Magnitude + 0.6, thick, if i % 2 == 0 then c.ivoryDark else c.ivory)
		end
	end

	Shapes.PITCH = pitch
end
