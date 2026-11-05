--!nocheck

return function(em, lib, Shapes)
	local V3, CF, C3 = lib.Vector3, lib.CFrame, lib.Color3
	local rad = math.rad
	local pitch = Shapes.PITCH
	Shapes.PITCH = 1.0
	Shapes.beginBake({ cell = 2.0 })
	local S = Shapes.new(em, lib)

	local stone, stoneDark = C3.fromRGB(222, 192, 132), C3.fromRGB(196, 166, 110)
	local moss, mossDark = C3.fromRGB(110, 175, 55), C3.fromRGB(90, 150, 45)

	local width = 8
	local depth = 1.9
	local courseHeight = 1.1
	local blockLength = 1.6
	local profile = { 6.6, 6.6, 6.0, 4.8, 3.6, 2.6, 1.6, 1.0 }
	local baseHeight = 0.6

	S:bevelBox(CF.new(0, baseHeight / 2, 0), V3.new(width + 0.5, baseHeight, depth + 0.7), stoneDark, 0)

	local function heightAt(x)
		local column = math.clamp(math.floor((x + width / 2) / width * #profile) + 1, 1, #profile)
		return profile[column]
	end

	local placedBlocks = {}
	local function topAt(x)
		local top = baseHeight
		for _, block in placedBlocks do
			if x >= block.Left and x <= block.Right then
				top = math.max(top, block.Top)
			end
		end
		return top
	end

	local course = 0
	while true do
		local bottom = baseHeight + course * courseHeight
		local placed = false
		local x = -width / 2 + (if course % 2 == 0 then 0 else -blockLength / 2)
		local index = course
		while x < width / 2 - 0.01 do
			local left = math.max(x, -width / 2)
			local right = math.min(x + blockLength, width / 2)
			local middle = (left + right) / 2
			if bottom + courseHeight <= heightAt(middle) + 0.01 and right - left > 0.2 then
				local courseDepth = if course % 2 == 0 then depth else depth - 0.16
				S:bevelBox(
					CF.new(middle, bottom + courseHeight / 2, 0),
					V3.new(right - left, courseHeight + 0.02, courseDepth),
					index % 2 == 0 and stone or stoneDark,
					0
				)
				table.insert(placedBlocks, { Left = left, Right = right, Top = bottom + courseHeight })
				placed = true
			end
			x += blockLength
			index += 1
		end
		if not placed then
			break
		end
		course += 1
	end

	local function mossCap(x, width, col)
		S:bevelBox(CF.new(x, topAt(x) + 0.05, 0), V3.new(width, 0.14, depth - 0.3), col, 0)
	end
	local function mossDrape(x, width, height, col, out)
		S:bevelBox(
			CF.new(x, topAt(x) - height / 2 + 0.1 - out, -depth / 2 - 0.1 - out),
			V3.new(width, height, 0.14),
			col,
			0
		)
	end
	mossCap(-3.2, 1.2, moss)
	mossCap(-1.5, 0.8, mossDark)
	mossCap(0.5, 1.0, moss)
	mossDrape(-3.2, 1.2, 1.5, moss, 0)
	mossDrape(-2.7, 0.6, 2.2, mossDark, 0.08)

	S:bevelBox(CF.new(2.1, 0.45, -1.7) * CF.Angles(0, rad(20), 0), V3.new(1.6, 0.9, 1.2), stone, 0)
	S:bevelBox(CF.new(3.3, 0.4, -1.4) * CF.Angles(0, rad(-30), 0), V3.new(1.2, 0.8, 1.0), stoneDark, 0)
	S:bevelBox(CF.new(2.6, 1.15, -1.6) * CF.Angles(0, rad(40), rad(10)), V3.new(1.0, 0.6, 0.9), stoneDark, 0)
	S:bevelBox(CF.new(0.5, 0.25, -1.5) * CF.Angles(0, rad(55), 0), V3.new(0.9, 0.5, 0.8), stoneDark, 0)
	S:bevelBox(CF.new(3.0, 0.5, 1.5) * CF.Angles(0, rad(15), 0), V3.new(1.3, 1.0, 1.1), stone, 0)
	S:bevelBox(CF.new(1.4, 0.1, -1.6), V3.new(1.4, 0.2, 1.0), moss, 0)

	Shapes.finishBake(lib, { distance = 1.6, strength = 0.6, sky = 0.22 })
	Shapes.PITCH = pitch
end
