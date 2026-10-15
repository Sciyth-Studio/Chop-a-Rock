--!strict

local suffixes = { "K", "M", "B", "T", "Qa" }
local compactThreshold = 1e6
local rockCompactThreshold = 1e3

local NumberFormat = {}

function NumberFormat.Commas(value: number): string
	local digits = tostring(math.floor(value))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (grouped:gsub("^,", ""))
end

function NumberFormat.Compact(value: number, threshold: number?): string
	if value < (threshold or compactThreshold) then
		return NumberFormat.Commas(value)
	end
	local index = math.clamp(math.floor(math.log10(value) / 3), 1, #suffixes)
	local scaled = math.floor(value / 10 ^ (3 * index) * 100) / 100
	local text = string.format("%.2f", scaled):gsub("0+$", ""):gsub("%.$", "")
	return `{text}{suffixes[index]}`
end

function NumberFormat.Rate(value: number): string
	if value < 1000 and value % 1 ~= 0 then
		return (string.format("%.1f", value):gsub("%.0$", ""))
	end
	return NumberFormat.Compact(value)
end

function NumberFormat.CompactRock(value: number): string
	return NumberFormat.Compact(value, rockCompactThreshold)
end

function NumberFormat.Percent(chance: number): string
	local percent = chance * 100
	local decimals = if percent < 1 then 2 else 1
	local text = string.format(`%.{decimals}f`, percent)
	text = string.gsub(text, "%.?0+$", "")
	return `{text}%`
end

function NumberFormat.Multiplier(value: number): string
	local text = string.format("%.2f", value)
	text = string.gsub(text, "%.?0+$", "")
	return `x{text}`
end

return NumberFormat
