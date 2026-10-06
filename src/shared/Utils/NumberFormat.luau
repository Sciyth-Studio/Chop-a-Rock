--!strict

local suffixes = { "M", "B", "T", "Qa" }
local compactThreshold = 1e6

local NumberFormat = {}

function NumberFormat.Commas(value: number): string
	local digits = tostring(math.floor(value))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (grouped:gsub("^,", ""))
end

function NumberFormat.Compact(value: number): string
	if value < compactThreshold then
		return NumberFormat.Commas(value)
	end
	local index = math.min(#suffixes, math.floor(math.log10(value) / 3) - 1)
	local scaled = math.floor(value / 10 ^ (3 * (index + 1)) * 100) / 100
	local text = string.format("%.2f", scaled):gsub("0+$", ""):gsub("%.$", "")
	return `{text}{suffixes[index]}`
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
