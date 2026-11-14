--!nocheck
-- Chop a Rock Boss Arena: hand emblem for the centre of the dais, replacing the claw crest (user,
-- 2026-11-11: "just make a hand symbol"). A flat round stone medallion in two rings with a raised
-- golden open hand on it: a palm block, four straight fingers with stepped tips, a thumb angled
-- out to the side and a short wrist. Lies flat, fingers toward -Z. ~40 across, ~3 tall.
-- Studs 1 per stud. Base on Y = 0.

local Arena = require("./ArenaParts")

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	local S = Shapes.new(em, lib)
	local c = Arena.Colors(C3)
	local k = Arena.Kit(S, lib)

	k.disc(CF.new(0, 0.5, 0), 40, 1.0, c.stoneDark, 12)
	k.disc(CF.new(0, 1.15, 0), 36, 0.3, c.stoneDeep, 12)
	k.disc(CF.new(0, 1.4, 0), 33, 0.8, c.stone, 12)
	local top = 1.8

	local function plate(x, z, w, l, h, col, yaw)
		k.block(CF.new(x, top + h / 2, z) * CF.Angles(0, rad(yaw or 0), 0), V3.new(w, h, l), col)
	end

	plate(0, 9.8, 7.0, 3.6, 1.4, c.goldDark)
	plate(0, 3.6, 12.4, 8.4, 1.6, c.gold)
	plate(0, 3.6, 11.0, 7.0, 1.85, c.goldDark)

	local fingers = { { -4.65, 9.6 }, { -1.55, 11.6 }, { 1.55, 11.0 }, { 4.65, 8.6 } }
	for i, f in fingers do
		local x, length = f[1], f[2]
		local col = if i % 2 == 0 then c.goldDark else c.gold
		local start = -0.4
		plate(x, start - (length - 1.6) / 2, 2.7, length - 1.6, 1.6, col)
		plate(x, start - length + 1.0, 2.2, 1.8, 1.6, col)
	end

	local thumbYaw = 38
	local thumbBase = V3.new(4.6, 0, 5.4)
	local dir = V3.new(math.sin(rad(thumbYaw)), 0, -math.cos(rad(thumbYaw)))
	local mid = thumbBase + dir * 3.6
	plate(mid.X, mid.Z, 3.0, 7.2, 1.6, c.goldDark, -thumbYaw)
	local tip = thumbBase + dir * 7.8
	plate(tip.X, tip.Z, 2.3, 1.8, 1.6, c.goldDark, -thumbYaw)

	Shapes.PITCH = pitch
end
