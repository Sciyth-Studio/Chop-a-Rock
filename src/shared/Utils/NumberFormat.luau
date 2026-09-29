--!strict

local NumberFormat = {}

function NumberFormat.Commas(value: number): string
	local digits = tostring(math.floor(value))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (grouped:gsub("^,", ""))
end

return NumberFormat
