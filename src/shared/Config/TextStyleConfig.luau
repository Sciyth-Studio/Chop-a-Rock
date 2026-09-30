--!strict

export type TextStyle = {
	EdgeColor: Color3,
	CenterColor: Color3,
	StrokeColor: Color3,
	StrokeThickness: number?,
	GradientRotation: number,
}

export type TextStyleSettings = {
	AttributeName: string,
	Styles: { [string]: TextStyle },
}

local TextStyleConfig: TextStyleSettings = {
	AttributeName = "TextStyle",
	Styles = {
		Chrome = {
			EdgeColor = Color3.fromRGB(190, 190, 190),
			CenterColor = Color3.fromRGB(255, 255, 255),
			StrokeColor = Color3.fromRGB(110, 110, 110),
			StrokeThickness = nil,
			GradientRotation = 90,
		},
		Gold = {
			EdgeColor = Color3.fromRGB(255, 170, 0),
			CenterColor = Color3.fromRGB(255, 245, 130),
			StrokeColor = Color3.fromRGB(140, 70, 0),
			StrokeThickness = nil,
			GradientRotation = 90,
		},
		Sky = {
			EdgeColor = Color3.fromRGB(0, 110, 255),
			CenterColor = Color3.fromRGB(130, 205, 255),
			StrokeColor = Color3.fromRGB(0, 40, 130),
			StrokeThickness = nil,
			GradientRotation = 90,
		},
	},
}

return table.freeze(TextStyleConfig)
