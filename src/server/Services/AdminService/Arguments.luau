--!strict

local maxLength = 32

local suffixes: { { Text: string, Multiplier: number } } = {
	{ Text = "sx", Multiplier = 1e21 },
	{ Text = "qi", Multiplier = 1e18 },
	{ Text = "qa", Multiplier = 1e15 },
	{ Text = "k", Multiplier = 1e3 },
	{ Text = "m", Multiplier = 1e6 },
	{ Text = "b", Multiplier = 1e9 },
	{ Text = "t", Multiplier = 1e12 },
}

local Arguments = {}

function Arguments.Number(text: string, min: number, max: number): number?
	if #text == 0 or #text > maxLength then
		return nil
	end
	local cleaned = string.lower((string.gsub(text, "[%s,_]", "")))
	local multiplier: number? = nil
	for _, suffix in suffixes do
		if string.sub(cleaned, -#suffix.Text) == suffix.Text then
			multiplier = suffix.Multiplier
			cleaned = string.sub(cleaned, 1, -#suffix.Text - 1)
			break
		end
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

function Arguments.Decimal(text: string, min: number, max: number): number?
	local value = tonumber((string.gsub(text, "[%s,_]", "")))
	if not value or value ~= value or value < min or value > max then
		return nil
	end
	return value
end

function Arguments.Words(text: string): { string }
	local words: { string } = {}
	for word in string.gmatch(text, "%S+") do
		table.insert(words, word)
	end
	return words
end

function Arguments.Match(text: string?, keys: { string }): string?
	if not text or #text == 0 then
		return nil
	end
	local query = string.lower(text)
	for _, key in keys do
		if string.lower(key) == query then
			return key
		end
	end
	local found: string? = nil
	for _, key in keys do
		if string.sub(string.lower(key), 1, #query) == query then
			if found then
				return nil
			end
			found = key
		end
	end
	return found
end

return Arguments
