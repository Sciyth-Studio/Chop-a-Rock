--!nocheck
-- Chop a Rock zone decor: lily pads in the JungleTree style (Lineup C #2). Three flat pads of
-- different sizes, each two crossed courses with a slot notch cut from the centre to one edge,
-- a pink flower of four petal blocks and a yellow centre on the biggest. ~6 across, ~0.5 tall
-- (flower ~1). Greens sit just above the swamp floor (50, 70, 40). Studs 1 per stud.
-- Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local pad, padDark = C3.fromRGB(80, 135, 50), C3.fromRGB(64, 112, 42)
	local petal, petalDark, middle = C3.fromRGB(255, 125, 190), C3.fromRGB(240, 95, 170), C3.fromRGB(255, 215, 40)

	-- One course of a notched pad in its own frame: the crossed shape with a slot along +Z.
	local function course(frame, w, y, h, col)
		local slot = w * 0.12
		local function piece(x0, x1, z0, z1)
			S:bevelBox(frame * CF.new((x0 + x1) / 2, y + h / 2, (z0 + z1) / 2), V3.new(x1 - x0, h, z1 - z0), col, 0)
		end
		local a, b = w * 0.5, w * 0.375
		piece(-a, a, -b, 0)
		piece(-b, b, -a, 0.01)
		piece(-a, -slot, -0.01, b)
		piece(slot, a, -0.01, b)
		piece(-b, -slot, 0, a)
		piece(slot, b, 0, a)
	end
	local function lily(x, z, w, yaw)
		local frame = CF.new(x, 0, z) * CF.Angles(0, rad(yaw), 0)
		course(frame, w, 0, 0.25, padDark)
		course(frame, w * 0.82, 0.25, 0.2, pad)
	end

	lily(-0.6, -0.4, 3.6, 150)
	lily(2.1, 1.3, 2.4, 30)
	lily(1.8, -2.0, 2.0, 255)

	local c = V3.new(-0.9, 0.45, -0.7)
	S:bevelBox(CF.new(c.X, c.Y + 0.15, c.Z), V3.new(0.9, 0.3, 0.9), petalDark, 0)
	for k = 0, 3 do
		local r = CF.new(c.X, c.Y, c.Z) * CF.Angles(0, rad(45 + k * 90), 0)
		S:bevelBox(r * CF.new(0, 0.3, -0.45) * CF.Angles(rad(-25), 0, 0), V3.new(0.5, 0.15, 0.7), petal, 0)
	end
	S:bevelBox(CF.new(c.X, c.Y + 0.38, c.Z), V3.new(0.35, 0.12, 0.35), middle, 0)

	Shapes.finishBake(lib, { distance = 1.0, strength = 0.5, sky = 0.22 })
	Shapes.PITCH = pitch
end
