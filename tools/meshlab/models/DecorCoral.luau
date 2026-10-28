--!nocheck
-- Chop a Rock zone decor: branching coral in the JungleTree style (Lineup B #4). A crossed foot
-- pad and banded stem split into two chunky arms that fork upward like antlers, mostly in the
-- X-Y plane: square limbs in straight segments, each end stepping in twice so the tip reads rounded.
-- ~5.5 tall, ~7 wide. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local pink, pinkDark = C3.fromRGB(255, 60, 160), C3.fromRGB(225, 35, 135)
	local function cross(cf, w, h, col)
		S:bevelBox(cf, V3.new(w, h, w * 0.75), col, 0)
		S:bevelBox(cf, V3.new(w * 0.75, h + 0.02, w), col, 0)
	end
	cross(CF.new(0, 0.25, 0), 2.4, 0.5, pinkDark)
	cross(CF.new(0, 1.0, 0), 1.2, 1.1, pink)

	-- Chain of square limbs from p: each step { side angle from vertical (deg, + = +X), length }.
	-- Returns the end point. Each limb starts a little back inside the last so the joins read solid.
	local function chain(p, steps, t, col)
		for _, st in steps do
			local a = rad(st[1])
			local d = V3.new(math.sin(a), math.cos(a), 0)
			p = P.limb(S, lib, p - d * 0.15, d, st[2] + 0.15, t, col)
		end
		return p
	end
	-- A branch whose end steps in twice, in its own pink, so the tip reads rounded.
	local function branch(p, steps, t)
		local last = steps[#steps][1]
		local d = V3.new(math.sin(rad(last)), math.cos(rad(last)), 0)
		local q = P.limb(S, lib, chain(p, steps, t, pink) - d * 0.1, d, 0.4, t * 0.75, pink)
		P.limb(S, lib, q - d * 0.1, d, 0.3, t * 0.45, pink)
	end

	local fork = V3.new(0, 1.5, 0)
	for _, side in { -1, 1 } do
		local arm = chain(fork, { { side * 50, 1.4 } }, 0.95, pinkDark)
		branch(arm, { { side * 12, 1.4 }, { 0, 0.9 } }, 0.8)
		local elbow = chain(arm, { { side * 60, 1.3 } }, 0.8, pinkDark)
		branch(elbow, { { side * 12, 1.3 } }, 0.75)
		branch(elbow, { { side * 75, 0.6 }, { side * 20, 0.5 } }, 0.6)
	end
	branch(V3.new(0, 1.4, 0.3), { { 0, 1.9 } }, 0.75)

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
