--!nocheck
-- Shared pieces for the Boss Arena props (assets/Arena/LineupA.webp): neutral grey stone in the
-- JungleTree stud-block style, a crossed-box helper, a stepped round course and the coal fire bowl.

local Arena = {}

function Arena.Colors(C3)
	return {
		stone = C3.fromRGB(160, 160, 160),
		stoneLight = C3.fromRGB(192, 192, 192),
		stoneDark = C3.fromRGB(112, 112, 112),
		stoneDeep = C3.fromRGB(92, 92, 92),
		coal = C3.fromRGB(255, 120, 0),
		coalHot = C3.fromRGB(255, 200, 0),
		coalDeep = C3.fromRGB(235, 80, 0),
		ivory = C3.fromRGB(245, 236, 205),
		ivoryDark = C3.fromRGB(226, 212, 172),
		gold = C3.fromRGB(255, 200, 0),
		goldDark = C3.fromRGB(235, 165, 0),
	}
end

function Arena.Kit(S, lib)
	local V3 = lib.Vector3
	local kit = {}
	function kit.block(cf, size, col)
		S:bevelBox(cf, size, col, 0)
	end
	function kit.cross(cf, w, h, col, ratio)
		local r = ratio or 0.78
		kit.block(cf, V3.new(w, h, w * r), col)
		kit.block(cf, V3.new(w * r, h + 0.02, w), col)
	end
	function kit.round(cf, w, h, col)
		local CF = lib.CFrame
		kit.block(cf, V3.new(w, h, w * 0.42), col)
		kit.block(cf, V3.new(w * 0.42, h + 0.02, w), col)
		kit.block(cf * CF.Angles(0, math.rad(45), 0), V3.new(w * 0.92, h + 0.01, w * 0.6), col)
		kit.block(cf * CF.Angles(0, math.rad(-45), 0), V3.new(w * 0.6, h + 0.03, w * 0.92), col)
	end
	function kit.disc(cf, w, h, col, sides)
		local CF = lib.CFrame
		local n = sides or 8
		for i = 0, n - 1 do
			kit.block(cf * CF.Angles(0, math.rad(i * 180 / n), 0), V3.new(w, h + i * 0.004, w * math.tan(math.pi / (2 * n)) * 2.0), col)
		end
	end
	return kit
end

function Arena.Bowl(S, lib, base, scale, colors)
	local CF, V3 = lib.CFrame, lib.Vector3
	local k = Arena.Kit(S, lib)
	local s = scale
	local y = base.Y
	local function at(h)
		return CF.new(base.X, y + h / 2, base.Z)
	end
	k.round(at(0.5 * s), 6.4 * s, 0.5 * s, colors.stoneDark)
	y += 0.5 * s
	k.round(at(0.6 * s), 4.6 * s, 0.6 * s, colors.stoneDeep)
	y += 0.6 * s
	k.round(at(0.7 * s), 2.6 * s, 0.7 * s, colors.stoneDark)
	y += 0.7 * s
	local courses = { { 3.6, 0.5, colors.stoneDeep }, { 5.6, 0.6, colors.stoneDark }, { 7.2, 0.7, colors.stoneDeep }, { 8.2, 0.6, colors.stoneDark } }
	for _, c in courses do
		k.round(at(c[2] * s), c[1] * s, c[2] * s, c[3])
		y += c[2] * s
	end
	local rim = y
	local heap = {
		{ 0, 0, 2.4, 1.2, colors.coal, 0 },
		{ 1.6, 1.1, 1.8, 1.0, colors.coalHot, 20 },
		{ -1.7, 0.8, 1.9, 1.0, colors.coalDeep, -15 },
		{ 0.9, -1.8, 1.7, 0.9, colors.coalHot, 35 },
		{ -1.0, -1.5, 1.8, 1.0, colors.coal, 10 },
		{ 2.4, -0.5, 1.4, 0.8, colors.coalDeep, -30 },
		{ -2.5, -0.4, 1.4, 0.8, colors.coalHot, 25 },
		{ 0.2, 2.4, 1.5, 0.8, colors.coalDeep, -5 },
		{ 0.3, 0.2, 1.6, 0.9, colors.coalHot, 40 },
	}
	for i, c in heap do
		local lift = if i == #heap then 1.0 else 0.1
		k.cross(CF.new(base.X + c[1] * s, rim + (lift + c[4] / 2) * s - 0.35 * s, base.Z + c[2] * s) * CF.Angles(0, math.rad(c[6]), 0), c[3] * s, c[4] * s, c[5])
	end
	local mound = {
		{ 0, 0, 5.2, 1.3, colors.coal, 10 },
		{ 0.3, -0.2, 3.6, 1.1, colors.coalHot, -20 },
		{ -0.2, 0.3, 2.0, 0.9, colors.coalDeep, 30 },
	}
	local top = rim + 0.4 * s
	for _, c in mound do
		k.cross(CF.new(base.X + c[1] * s, top + c[4] * s / 2, base.Z + c[2] * s) * CF.Angles(0, math.rad(c[6]), 0), c[3] * s, c[4] * s, c[5])
		top += c[4] * s * 0.85
	end
	return top
end

return Arena
