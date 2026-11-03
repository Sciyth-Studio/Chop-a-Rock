--!nocheck
-- Chop a Rock zone decor: bamboo clump in the JungleTree style (Lineup D #1). A crossed base pad
-- with six tall square lime stalks close together, each in segments split by wider darker joint
-- rings, small flat pointed leaves on short twigs near the tops. ~15 tall, ~4 wide.
-- opts.shoot (DecorBambooShoot) makes three short stalks with stepped tips and a leaf each.
-- Leaves sit near the bamboo floor green (120, 150, 90). lib.seed varies the clump.
-- Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes, _, opts)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local shoot = opts and opts.shoot
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local stalk, stalkDark, joint = C3.fromRGB(165, 215, 60), C3.fromRGB(145, 195, 50), C3.fromRGB(110, 160, 40)
	local leaf, leafDark = C3.fromRGB(120, 175, 75), C3.fromRGB(100, 152, 62)
	local base = C3.fromRGB(100, 125, 72)
	S:bevelBox(CF.new(0, 0.2, shoot and 0 or 0.3), V3.new(shoot and 2.4 or 4.8, 0.4, shoot and 1.8 or 3.6), base, 0)
	S:bevelBox(CF.new(0, 0.2, shoot and 0 or 0.3), V3.new(shoot and 1.8 or 3.6, 0.42, shoot and 2.4 or 4.8), base, 0)

	local function leafAt(p, yaw)
		local twig = P.limb(S, lib, p, P.dir(lib, yaw, rad(35)), 0.7, 0.2, joint)
		local d = P.dir(lib, yaw, rad(-20))
		S:bevelBox(P.lookAt(lib, twig + d * 1.0, d), V3.new(0.6, 0.12, 2.0), leaf, 0)
		S:bevelBox(P.lookAt(lib, twig + d * 2.15, d), V3.new(0.3, 0.12, 0.5), leafDark, 0)
	end

	local stalks = shoot and { { -0.5, 0.2, 3.2 }, { 0.6, -0.3, 2.2 }, { 0.1, 0.7, 1.6 } }
		or { { -1.3, 0.3, 15 }, { 0.4, -1.0, 13 }, { 1.5, 0.5, 11 }, { -0.3, 1.5, 9.5 }, { 1.0, 2.0, 12.5 }, { -1.7, -1.3, 10.5 } }
	for k, st in stalks do
		local w = shoot and 0.8 or 0.85
		local h = st[3] * (shoot and 1 or rand(0.95, 1.05))
		local segLen = shoot and 0.9 or 2.0
		local y = 0.4
		local i = 0
		while y < h - 0.01 do
			local len = math.min(segLen, h - y)
			S:bevelBox(CF.new(st[1], y + len / 2, st[2]), V3.new(w, len + 0.02, w), (i + k) % 2 == 0 and stalk or stalkDark, 0)
			y += len
			if y < h - 0.3 then
				S:bevelBox(CF.new(st[1], y, st[2]), V3.new(w + 0.2, 0.25, w + 0.2), joint, 0)
			end
			i += 1
		end
		if shoot then
			S:bevelBox(CF.new(st[1], h + 0.25, st[2]), V3.new(w * 0.6, 0.5, w * 0.6), stalkDark, 0)
			S:bevelBox(CF.new(st[1], h + 0.65, st[2]), V3.new(w * 0.3, 0.3, w * 0.3), stalkDark, 0)
			leafAt(V3.new(st[1], h * 0.6, st[2]), rand(0, math.pi * 2))
		else
			for j = 0, 1 do
				local ly = h - 1.0 - j * 2.0
				local yaw = rand(0, math.pi * 2)
				leafAt(V3.new(st[1], ly, st[2]) + P.dir(lib, yaw, 0) * (w / 2), yaw)
			end
		end
	end

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
