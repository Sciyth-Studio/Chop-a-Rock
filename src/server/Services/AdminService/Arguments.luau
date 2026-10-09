--!strict

local maxLength = 32

local suffixes: { [string]: number } = {
	k = 1e3,
	m = 1e6,
	b = 1e9,
	t = 1e12,
}

local Arguments = {}

function Arguments.Number(text: string, min: number, max: number): number?
	if #text == 0 or #text > maxLength then
		return nil
	end
	local cleaned = string.lower((string.gsub(text, "[%s,_]", "")))
	local multiplier = suffixes[string.sub(cleaned, -1)]
	if multiplier then
		cleaned = string.sub(cleaned, 1, -2)
	end
	local value = tonumber(cleaned)
	if not value or value ~= value or math.abs(value) == math.huge then
		return nil
	end
	value = math.floor(value * (multiplier or 1) + 0.5)
	if value < min or value > max then
		return nil
	end
	return value
end

return Arguments
