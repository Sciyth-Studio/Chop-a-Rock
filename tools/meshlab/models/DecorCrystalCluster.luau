--!nocheck
-- Chop a Rock Boss Arena: crystal cluster (assets/Arena/LineupB.webp #2) in the JungleTree stud-block
-- style. Nine square crystal prisms fan out of one low crossed base, the middle one tallest, each
-- tip stepping in twice in its own colour. Cyan for the Diamond cavern; opts.ice
-- (DecorIceCluster) recolours it ice blue for the Frost Yeti. ~7 wide, ~10 tall.
-- lib.seed varies the fan. Studs 1 per stud. Base on Y = 0, front -Z.

return function(em, lib, Shapes, _, opts)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local P = Shapes.Props
	local rand = P.rng(lib.seed)
	local ice = opts and opts.ice
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local shades = if ice
		then { C3.fromRGB(150, 214, 255), C3.fromRGB(186, 230, 255), C3.fromRGB(122, 194, 248) }
		else { C3.fromRGB(0, 200, 255), C3.fromRGB(60, 226, 255), C3.fromRGB(0, 172, 240) }
	local baseColor = if ice then C3.fromRGB(100, 168, 230) else C3.fromRGB(0, 140, 215)

	S:bevelBox(CF.new(0, 0.3, 0), V3.new(5.8, 0.6, 4.4), baseColor, 0)
	S:bevelBox(CF.new(0, 0.32, 0), V3.new(4.4, 0.64, 5.6), baseColor, 0)

	local function prism(base, yaw, tilt, length, width, col)
		local dir = P.dir(lib, rad(yaw), rad(90 - tilt))
		local shaft = length * 0.78
		local tip = P.limb(S, lib, base - dir * 0.4, dir, shaft + 0.4, width, col)
		tip = P.limb(S, lib, tip - dir * 0.05, dir, length * 0.12, width * 0.66, col)
		P.limb(S, lib, tip - dir * 0.05, dir, length * 0.1, width * 0.34, col)
	end

	prism(V3.new(0, 0.4, 0), 0, 0, 10, 1.9, shades[1])
	local ring = {
		{ 0, 30, 7.4, 1.5 },
		{ 45, 44, 5.8, 1.3 },
		{ 95, 34, 7.0, 1.4 },
		{ 140, 48, 5.0, 1.2 },
		{ 185, 30, 7.8, 1.5 },
		{ 230, 46, 5.4, 1.2 },
		{ 275, 36, 6.6, 1.4 },
		{ 320, 50, 4.8, 1.1 },
	}
	for i, r in ring do
		local yaw = r[1] + rand(-8, 8)
		local out = V3.new(math.sin(rad(yaw)), 0, math.cos(rad(yaw)))
		prism(V3.new(0, 0.4, 0) + out * 1.5, yaw, r[2] + rand(-4, 4), r[3] + rand(-0.4, 0.4), r[4], shades[(i % 3) + 1])
	end

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.5, sky = 0.22 })
	Shapes.PITCH = pitch
end
