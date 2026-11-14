--!strict

local BlockRoundConfig = require(script.Parent.Config.BlockRoundConfig)
local ChopConfig = require(script.Parent.Config.ChopConfig)
local ChopQuality = require(script.Parent.ChopQuality)
local PotionConfig = require(script.Parent.Config.PotionConfig)

export type Band = {
	Quality: number,
	Low: number,
	High: number,
}

export type BlockBand = {
	Low: number,
	High: number,
	PerfectLow: number,
	PerfectHigh: number,
}

local ChopZones = {}

local bandOrder: { { Quality: number, Width: number } } = {
	{ Quality = ChopQuality.Perfect, Width = ChopConfig.PerfectZoneWidth },
	{ Quality = ChopQuality.Great, Width = ChopConfig.GreatZoneWidth },
	{ Quality = ChopQuality.Good, Width = ChopConfig.GoodZoneWidth },
	{ Quality = ChopQuality.Mid, Width = ChopConfig.MidZoneWidth },
}

function ChopZones.StrengthProgress(strengthRatio: number): number
	return math.clamp(
		math.log(math.max(strengthRatio, 1)) / math.log(ChopConfig.PerfectOnlyStrengthRatio),
		0,
		1
	)
end

function ChopZones.CappedRatio(strengthRatio: number, isTouch: boolean?, maxPerfect: number): number
	local multiplier = if isTouch then ChopConfig.TouchZoneWidthMultiplier else ChopConfig.ZoneWidthMultiplier
	local base = math.min(1, ChopConfig.PerfectZoneWidth * multiplier)
	local cap = if base >= 1 then 0 else math.clamp((maxPerfect - base) / (1 - base), 0, 1)
	return ChopConfig.PerfectOnlyStrengthRatio ^ (ChopZones.StrengthProgress(strengthRatio) * cap)
end

function ChopZones.IsTouch(player: Player): boolean
	return player:GetAttribute(ChopConfig.TouchAttribute) == true
end

function ChopZones.Bands(
	center: number,
	strengthRatio: number,
	isTouch: boolean?,
	perfectScale: number?
): { Band }
	local bands: { Band } = {}
	local progress = ChopZones.StrengthProgress(strengthRatio)
	local widthMultiplier = if isTouch
		then ChopConfig.TouchZoneWidthMultiplier
		else ChopConfig.ZoneWidthMultiplier
	local baseCumulative = 0
	for _, entry in bandOrder do
		baseCumulative = math.min(1, baseCumulative + entry.Width * widthMultiplier)
		local cumulative = baseCumulative + (1 - baseCumulative) * progress
		if entry.Quality == ChopQuality.Perfect and perfectScale then
			local scaled = cumulative * perfectScale
			cumulative = if perfectScale > 1
				then math.min(scaled, math.max(cumulative, PotionConfig.FocusMaxPerfectShare))
				else scaled
		end
		local low = math.clamp(center - cumulative / 2, 0, 1 - cumulative)
		table.insert(bands, { Quality = entry.Quality, Low = low, High = low + cumulative })
	end
	return bands
end

function ChopZones.Classify(
	position: number,
	center: number,
	strengthRatio: number,
	isTouch: boolean?,
	perfectScale: number?
): number
	for _, band in ChopZones.Bands(center, strengthRatio, isTouch, perfectScale) do
		if position >= band.Low and position <= band.High then
			return band.Quality
		end
	end
	return ChopQuality.Bad
end

function ChopZones.BlockBand(center: number, isTouch: boolean?, zoneScale: number?): BlockBand
	local multiplier = (
		if isTouch then ChopConfig.TouchZoneWidthMultiplier else ChopConfig.ZoneWidthMultiplier
	) * (zoneScale or 1)
	local width = math.min(1, BlockRoundConfig.ZoneWidth * multiplier)
	local perfect = math.min(width, BlockRoundConfig.PerfectWidth * multiplier)
	local low = math.clamp(center - width / 2, 0, 1 - width)
	local perfectLow = math.clamp(center - perfect / 2, low, low + width - perfect)
	return { Low = low, High = low + width, PerfectLow = perfectLow, PerfectHigh = perfectLow + perfect }
end

function ChopZones.ClassifyBlock(
	position: number,
	center: number,
	isTouch: boolean?,
	zoneScale: number?
): number
	local band = ChopZones.BlockBand(center, isTouch, zoneScale)
	if position >= band.PerfectLow and position <= band.PerfectHigh then
		return BlockRoundConfig.Outcomes.Perfect
	end
	if position >= band.Low and position <= band.High then
		return BlockRoundConfig.Outcomes.Blocked
	end
	return BlockRoundConfig.Outcomes.Missed
end

function ChopZones.BlockPassSeconds(isTouch: boolean?, speed: number): number
	local cycleSeconds = if isTouch then ChopConfig.TouchCycleSeconds else ChopConfig.CycleSeconds
	return cycleSeconds / 2 / speed
end

function ChopZones.BlockPosition(elapsed: number, isTouch: boolean?, speed: number): number
	local moving = elapsed - BlockRoundConfig.LeadSeconds
	return math.clamp(moving / ChopZones.BlockPassSeconds(isTouch, speed), 0, 1)
end

function ChopZones.ChompCenter(elapsed: number, isTouch: boolean?, centers: { number }): number
	local cycleSeconds = if isTouch then ChopConfig.TouchCycleSeconds else ChopConfig.CycleSeconds
	local index = math.clamp(math.floor(math.max(elapsed, 0) / (cycleSeconds / 2)) + 1, 1, #centers)
	return centers[index] or 0.5
end

function ChopZones.RandomCenter(random: Random): number
	return random:NextNumber(ChopConfig.ZoneCenterMin, ChopConfig.ZoneCenterMax)
end

function ChopZones.Position(elapsed: number, isTouch: boolean?, speed: number?): number
	local cycleSeconds = if isTouch then ChopConfig.TouchCycleSeconds else ChopConfig.CycleSeconds
	local phase = (elapsed * (speed or 1) / cycleSeconds) % 1
	return 1 - math.abs(2 * phase - 1)
end

return table.freeze(ChopZones)
