--!strict

local BuilderSans = "rbxasset://fonts/families/BuilderSans.json"

local FontConfig = {
	Default = Font.new(BuilderSans, Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal),
}

return table.freeze(FontConfig)
