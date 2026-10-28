--!nocheck
-- Chop a Rock zone decor: saguaro in the JungleTree style (Lineup A #5). A crossed-box column in
-- alternating green bands with a stepped crossed top, two chunky arms that go out and up (the
-- one on the viewer's left lower and longer), banded like the column. ~9.5 tall, ~8 wide.
-- Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local green, light = C3.fromRGB(30, 185, 60), C3.fromRGB(80, 210, 70)
	local function cross(x, y, z, w, h, col)
		S:bevelBox(CF.new(x, y, z), V3.new(w, h, w * 0.75), col, 0)
		S:bevelBox(CF.new(x, y, z), V3.new(w * 0.75, h + 0.02, w), col, 0)
	end

	local w, segH = 2.4, 2.1
	for i = 0, 3 do
		cross(0, segH * (i + 0.5), 0, w, segH + 0.02, i % 2 == 0 and green or light)
	end
	local top = segH * 4
	cross(0, top + 0.35, 0, w * 0.75, 0.7, green)
	cross(0, top + 0.85, 0, w * 0.45, 0.3, light)

	-- Arms: a horizontal crossed run out of the column side, then banded segments going up.
	local aw = 1.6
	for _, arm in { { 1, 3.2, 2.8, 3.0 }, { -1, 5.0, 2.3, 2.2 } } do
		local side, y0, out, up = arm[1], arm[2], arm[3], arm[4]
		local x1 = side * (w / 2 + out - aw / 2)
		S:bevelBox(CF.new(side * (w / 2 + out / 2), y0, 0), V3.new(out + 0.1, aw, aw * 0.75), green, 0)
		S:bevelBox(CF.new(side * (w / 2 + out / 2), y0, 0), V3.new(out + 0.1, aw * 0.75, aw), green, 0)
		local y = y0 + aw / 2
		local n = math.max(1, math.floor(up / 1.1 + 0.5))
		for k = 1, n do
			cross(x1, y + (up / n) * (k - 0.5), 0, aw, up / n + 0.02, k % 2 == 1 and light or green)
		end
		cross(x1, y + up + 0.25, 0, aw * 0.7, 0.5, green)
	end

	Shapes.finishBake(lib, { distance = 2.0, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
