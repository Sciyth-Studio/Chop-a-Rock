--!nocheck
-- Chop a Rock zone decor: prickly pear in the JungleTree style (Lineup A #6). Thick green pads
-- (a box crossed with a taller narrower one, plus a lighter inner face) stacked at angles, two
-- chunky pink flowers with yellow centres on the top edges. ~5.5 tall, ~5 wide.
-- Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local green, greenDark = C3.fromRGB(70, 195, 50), C3.fromRGB(45, 165, 45)
	local pink, pinkDark, yellow = C3.fromRGB(255, 60, 150), C3.fromRGB(230, 40, 130), C3.fromRGB(255, 210, 0)

	-- A pad standing on its bottom point (x, y, z), leaning `tilt` sideways (+ leans to -X),
	-- turned `yaw`. Returns the CFrame of its top edge.
	local function pad(x, y, z, yaw, tilt, w, h, col, face)
		local base = CF.new(x, y, z) * CF.Angles(0, rad(yaw), 0) * CF.Angles(0, 0, rad(tilt))
		local mid = base * CF.new(0, h / 2, 0)
		S:bevelBox(mid, V3.new(w, h * 0.72, 0.8), col, 0)
		S:bevelBox(mid, V3.new(w * 0.68, h, 0.8), col, 0)
		S:bevelBox(mid, V3.new(w * 0.62, h * 0.62, 1.0), face, 0)
		return base * CF.new(0, h, 0)
	end

	pad(0, 0, 0, 0, 0, 2.6, 3.0, green, greenDark)
	local l = pad(-0.5, 2.6, 0, 20, 35, 2.2, 2.4, greenDark, green)
	local r = pad(0.5, 2.6, 0, -25, -30, 2.2, 2.3, greenDark, green)
	pad(0.3, 0, 0.7, 70, -15, 1.8, 2.0, greenDark, green)

	for _, tip in { l, r } do
		local cf = tip * CF.new(0, 0.1, 0)
		S:bevelBox(cf * CF.new(0, 0.3, 0), V3.new(1.1, 0.6, 0.8), pink, 0)
		S:bevelBox(cf * CF.new(0, 0.3, 0), V3.new(0.8, 0.62, 1.1), pink, 0)
		S:bevelBox(cf * CF.new(0, 0.7, 0), V3.new(0.7, 0.25, 0.7), pinkDark, 0)
		S:bevelBox(cf * CF.new(0, 0.88, 0), V3.new(0.35, 0.15, 0.35), yellow, 0)
	end

	Shapes.finishBake(lib, { distance = 1.8, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
