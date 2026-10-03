--!strict

local ChopConfig = require(script.Parent.Config.ChopConfig)
local ChopQuality = require(script.Parent.ChopQuality)

export type Band = {
	Quality: number,
	Low: number,
	High: number,
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

function ChopZones.Bands(center: number, strengthRatio: number): { Band }
	local bands: { Band } = {}
	local progress = ChopZones.StrengthProgress(strengthRatio)
	local baseCumulative = 0
	for _, entry in bandOrder do
		baseCumulative = math.min(1, baseCumulative + entry.Width * ChopConfig.ZoneWidthMultiplier)
		local cumulative = baseCumulative + (1 - baseCumulative) * progress
		local low = math.clamp(center - cumulative / 2, 0, 1 - cumulative)
		table.insert(bands, { Quality = entry.Quality, Low = low, High = low + cumulative })
	end
	return bands
end

function ChopZones.Classify(position: number, center: number, strengthRatio: number): number
	for _, band in ChopZones.Bands(center, strengthRatio) do
		if position >= band.Low and position <= band.High then
			return band.Quality
		end
	end
	return ChopQuality.Bad
end

function ChopZones.RandomCenter(random: Random): number
	return random:NextNumber(ChopConfig.ZoneCenterMin, ChopConfig.ZoneCenterMax)
end

function ChopZones.Position(elapsed: number): number
	local phase = (elapsed / ChopConfig.CycleSeconds) % 1
	return 1 - math.abs(2 * phase - 1)
end

return table.freeze(ChopZones)
