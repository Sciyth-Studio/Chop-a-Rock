--!strict

local BossConfig = require(script.Parent.Config.BossConfig)

export type Hazard = {
	Style: number,
	Origin: Vector3,
	Angle: number,
	Span: number,
	Reach: number,
	Size: number,
	Points: { Vector3 },
}

local Styles = BossConfig.BigStyles

local BossHazards = {}

local function flat(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function angleOf(offset: Vector3): number
	return math.atan2(offset.Z, offset.X)
end

local function angleGap(a: number, b: number): number
	local difference = (a - b) % (math.pi * 2)
	if difference > math.pi then
		difference -= math.pi * 2
	end
	return difference
end

function BossHazards.Direction(angle: number): Vector3
	return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

function BossHazards.AngleOf(offset: Vector3): number
	return angleOf(offset)
end

function BossHazards.AngleGap(a: number, b: number): number
	return angleGap(a, b)
end

function BossHazards.IsHit(hazard: Hazard, position: Vector3, scale: number): boolean
	if hazard.Style == Styles.TailSweep then
		local offset = flat(position - hazard.Origin)
		if offset.Magnitude > hazard.Reach * scale then
			return false
		end
		if offset.Magnitude < 1e-3 then
			return true
		end
		return math.abs(angleGap(angleOf(offset), hazard.Angle)) <= hazard.Span / 2 * scale
	elseif hazard.Style == Styles.IceSpikes then
		local pocket = hazard.Size / math.max(scale, 1e-3)
		for _, point in hazard.Points do
			if flat(position - point).Magnitude <= pocket then
				return false
			end
		end
		return true
	elseif hazard.Style == Styles.BoulderRain then
		local reach = hazard.Size * scale
		for _, point in hazard.Points do
			if flat(position - point).Magnitude <= reach then
				return true
			end
		end
		return false
	end
	return false
end

function BossHazards.Knock(hazard: Hazard, position: Vector3, studs: number): Vector3
	local away = Vector3.zero
	if hazard.Style == Styles.TailSweep then
		local offset = flat(position - hazard.Origin)
		local outward = if offset.Magnitude > 1e-3 then offset.Unit else Vector3.zAxis
		local tangent = Vector3.new(-outward.Z, 0, outward.X)
		away = tangent + outward * BossConfig.BigAttack.TailSweep.KnockOutward
	elseif hazard.Style == Styles.IceSpikes then
		away = flat(position - hazard.Origin)
	else
		local best: Vector3? = nil
		local bestDistance = math.huge
		for _, point in hazard.Points do
			local distance = flat(position - point).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				best = point
			end
		end
		if best then
			away = flat(position - best)
		end
	end
	if away.Magnitude < 1e-3 then
		away = flat(position - hazard.Origin)
	end
	if away.Magnitude < 1e-3 then
		away = Vector3.zAxis
	end
	return away.Unit * studs
end

function BossHazards.NearestSafe(hazard: Hazard, position: Vector3, maxStuds: number): Vector3?
	if not BossHazards.IsHit(hazard, position, 1) then
		return nil
	end
	local directions = 32
	local step = 2
	for distance = step, maxStuds, step do
		local best: Vector3? = nil
		local bestScore = math.huge
		for index = 1, directions do
			local angle = index / directions * math.pi * 2
			local candidate = position + BossHazards.Direction(angle) * distance
			if not BossHazards.IsHit(hazard, candidate, 1) then
				local score = flat(candidate - hazard.Origin).Magnitude
				if score < bestScore then
					bestScore = score
					best = candidate
				end
			end
		end
		if best then
			return best
		end
	end
	return nil
end

function BossHazards.Write(model: Model, hazard: Hazard)
	model:SetAttribute(BossConfig.HazardOriginAttribute, hazard.Origin)
	model:SetAttribute(BossConfig.HazardAngleAttribute, hazard.Angle)
	model:SetAttribute(BossConfig.HazardSpanAttribute, hazard.Span)
	model:SetAttribute(BossConfig.HazardReachAttribute, hazard.Reach)
	model:SetAttribute(BossConfig.HazardSizeAttribute, hazard.Size)
	for index = 1, BossConfig.BigAttack.MaxPoints do
		model:SetAttribute(BossConfig.HazardPointAttribute .. index, hazard.Points[index])
	end
	model:SetAttribute(BossConfig.HazardStyleAttribute, hazard.Style)
end

function BossHazards.Clear(model: Model)
	model:SetAttribute(BossConfig.HazardStyleAttribute, nil)
	model:SetAttribute(BossConfig.HazardOriginAttribute, nil)
	model:SetAttribute(BossConfig.HazardAngleAttribute, nil)
	model:SetAttribute(BossConfig.HazardSpanAttribute, nil)
	model:SetAttribute(BossConfig.HazardReachAttribute, nil)
	model:SetAttribute(BossConfig.HazardSizeAttribute, nil)
	for index = 1, BossConfig.BigAttack.MaxPoints do
		model:SetAttribute(BossConfig.HazardPointAttribute .. index, nil)
	end
end

local function numberAttribute(model: Model, name: string): number
	local value = model:GetAttribute(name)
	return if type(value) == "number" then value else 0
end

function BossHazards.Read(model: Model): Hazard?
	local style = model:GetAttribute(BossConfig.HazardStyleAttribute)
	local origin = model:GetAttribute(BossConfig.HazardOriginAttribute)
	if type(style) ~= "number" or style == Styles.None or typeof(origin) ~= "Vector3" then
		return nil
	end
	local points: { Vector3 } = {}
	for index = 1, BossConfig.BigAttack.MaxPoints do
		local point = model:GetAttribute(BossConfig.HazardPointAttribute .. index)
		if typeof(point) == "Vector3" then
			table.insert(points, point)
		end
	end
	return {
		Style = style,
		Origin = origin,
		Angle = numberAttribute(model, BossConfig.HazardAngleAttribute),
		Span = numberAttribute(model, BossConfig.HazardSpanAttribute),
		Reach = numberAttribute(model, BossConfig.HazardReachAttribute),
		Size = numberAttribute(model, BossConfig.HazardSizeAttribute),
		Points = points,
	}
end

return BossHazards
