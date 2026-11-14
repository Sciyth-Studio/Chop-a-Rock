--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossConfig = require(ReplicatedStorage.Config.BossConfig)
local BossHazards = require(ReplicatedStorage.BossHazards)
local Types = require(script.Parent.Types)

local Styles = BossConfig.BigStyles
local spec = BossConfig.BigAttack

local Attacks = {}

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function farthestSpot(spots: { Types.Spot }, center: Vector3): number
	local farthest = 0
	for _, spot in spots do
		farthest = math.max(farthest, flatDistance(spot.Part.Position, center))
	end
	return farthest
end

function Attacks.SlamRadius(spots: { Types.Spot }, center: Vector3): number
	return farthestSpot(spots, center) + BossConfig.Slam.RingMarginStuds
end

local function tailSweep(origin: Vector3, random: Random): BossHazards.Hazard
	local style = spec.TailSweep
	local gapAngle = random:NextNumber(0, math.pi * 2)
	return {
		Style = Styles.TailSweep,
		Origin = origin,
		Angle = gapAngle + math.pi,
		Span = math.pi * 2 - math.rad(style.SliverDegrees),
		Reach = style.ReachStuds,
		Size = 0,
		Points = {},
	}
end

function Attacks.SweepRange(hazard: BossHazards.Hazard): (number, number)
	local leniency = math.rad(spec.TailSweep.GapLeniencyDegrees)
	return leniency, hazard.Span - leniency
end

function Attacks.SweepAngle(hazard: BossHazards.Hazard, position: Vector3): number?
	local offset = Vector3.new(position.X - hazard.Origin.X, 0, position.Z - hazard.Origin.Z)
	if offset.Magnitude < 1e-3 then
		return nil
	end
	return (BossHazards.AngleOf(offset) - (hazard.Angle - hazard.Span / 2)) % (math.pi * 2)
end

local function iceSpikes(
	center: Vector3,
	origin: Vector3,
	targets: { Vector3 },
	random: Random
): BossHazards.Hazard
	local style = spec.IceSpikes
	local half = BossConfig.ArenaJudgeHalfStuds - style.PocketEdgeStuds
	local points: { Vector3 } = {}
	local function fits(candidate: Vector3): boolean
		if math.abs(candidate.X - center.X) > half or math.abs(candidate.Z - center.Z) > half then
			return false
		end
		if flatDistance(candidate, origin) < style.PocketMinCenterStuds then
			return false
		end
		for _, point in points do
			if flatDistance(point, candidate) < style.PocketGapStuds then
				return false
			end
		end
		return true
	end
	local function covered(target: Vector3): boolean
		for _, point in points do
			if flatDistance(point, target) <= style.AimMaxStuds then
				return true
			end
		end
		return false
	end
	for _, target in targets do
		if #points >= style.Pockets then
			break
		end
		if covered(target) then
			continue
		end
		for _ = 1, style.Tries do
			local distance = random:NextNumber(style.AimMinStuds, style.AimMaxStuds)
			local candidate = Vector3.new(target.X, center.Y, target.Z)
				+ BossHazards.Direction(random:NextNumber(0, math.pi * 2)) * distance
			if fits(candidate) then
				table.insert(points, candidate)
				break
			end
		end
	end
	local tries = 0
	while #points < style.Pockets and tries < style.Pockets * style.Tries do
		tries += 1
		local candidate = center
			+ Vector3.new(random:NextNumber(-half, half), 0, random:NextNumber(-half, half))
		if fits(candidate) then
			table.insert(points, candidate)
		end
	end
	return {
		Style = Styles.IceSpikes,
		Origin = origin,
		Angle = 0,
		Span = 0,
		Reach = BossConfig.ArenaJudgeHalfStuds,
		Size = style.PocketRadiusStuds,
		Points = points,
	}
end

local function boulderRain(
	spots: { Types.Spot },
	origin: Vector3,
	targets: { Vector3 },
	random: Random
): BossHazards.Hazard
	local style = spec.BoulderRain
	local body = farthestSpot(spots, origin)
	local area = math.min(body + style.AreaMarginStuds, style.MaxAreaStuds)
	local clear = body + style.RadiusStuds + style.BossClearStuds
	local points: { Vector3 } = {}
	local function fits(candidate: Vector3): boolean
		if flatDistance(candidate, origin) < clear then
			return false
		end
		for _, point in points do
			if flatDistance(point, candidate) < style.RadiusStuds * 2 + style.MinGapStuds then
				return false
			end
		end
		return true
	end
	local aimed = math.floor(style.Count * style.AimedShare)
	for _, target in targets do
		if #points >= aimed then
			break
		end
		local jitter = BossHazards.Direction(random:NextNumber(0, math.pi * 2))
			* random:NextNumber(0, style.AimJitterStuds)
		local candidate = Vector3.new(target.X, origin.Y, target.Z) + jitter
		if fits(candidate) then
			table.insert(points, candidate)
		end
	end
	local tries = 0
	while #points < style.Count and tries < style.Count * style.Tries do
		tries += 1
		local distance = math.sqrt(random:NextNumber(0, 1)) * math.max(area - clear, 0) + clear
		local candidate = origin + BossHazards.Direction(random:NextNumber(0, math.pi * 2)) * distance
		if fits(candidate) then
			table.insert(points, candidate)
		end
	end
	return {
		Style = Styles.BoulderRain,
		Origin = origin,
		Angle = 0,
		Span = 0,
		Reach = area,
		Size = style.RadiusStuds,
		Points = points,
	}
end

function Attacks.BigHazard(
	style: number,
	spots: { Types.Spot },
	center: Vector3,
	origin: Vector3,
	_facing: Vector3,
	targets: { Vector3 },
	random: Random
): BossHazards.Hazard
	if style == Styles.IceSpikes then
		return iceSpikes(center, origin, targets, random)
	elseif style == Styles.BoulderRain then
		return boulderRain(spots, origin, targets, random)
	end
	return tailSweep(origin, random)
end

function Attacks.JudgeScale(style: number): number
	if style == Styles.IceSpikes then
		return spec.IceSpikes.JudgeScale
	elseif style == Styles.BoulderRain then
		return spec.BoulderRain.JudgeScale
	end
	return 1
end

function Attacks.JudgeDelay(style: number): number
	if style == Styles.IceSpikes then
		return spec.IceSpikes.SpreadSeconds
	end
	return 0
end

function Attacks.WarnText(style: number): string
	if style == Styles.IceSpikes then
		return spec.IceSpikes.WarnText
	elseif style == Styles.BoulderRain then
		return spec.BoulderRain.WarnText
	end
	return spec.TailSweep.WarnText
end

function Attacks.InArena(position: Vector3, center: Vector3): boolean
	local half = BossConfig.ArenaJudgeHalfStuds
	return math.abs(position.X - center.X) <= half and math.abs(position.Z - center.Z) <= half
end

function Attacks.IsSafe(
	kind: number,
	position: Vector3,
	center: Vector3,
	slamRadius: number,
	hazard: BossHazards.Hazard?
): boolean
	if kind == BossConfig.Attacks.Slam then
		return flatDistance(position, center) >= slamRadius * BossConfig.Slam.JudgeScale
	end
	if not hazard then
		return true
	end
	return not BossHazards.IsHit(hazard, position, Attacks.JudgeScale(hazard.Style))
end

function Attacks.Knock(
	kind: number,
	position: Vector3,
	center: Vector3,
	hazard: BossHazards.Hazard?,
	studs: number
): Vector3
	if kind == BossConfig.Attacks.Big and hazard then
		return BossHazards.Knock(hazard, position, studs)
	end
	local flat = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
	return (if flat.Magnitude > 1e-3 then flat.Unit else Vector3.zAxis) * studs
end

return Attacks
