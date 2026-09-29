--!strict

local BuilderSans = "rbxasset://fonts/families/BuilderSans.json"

local FontConfig = {
	Default = Font.new(BuilderSans, Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal),
	Italic = Font.new(BuilderSans, Enum.FontWeight.ExtraBold, Enum.FontStyle.Italic),
	ItalicAttribute = "Italic",
}

return table.freeze(FontConfig)
