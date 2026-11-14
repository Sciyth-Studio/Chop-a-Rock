--!strict

local Types = require(script.Parent.Types)

export type Colors = {
	Core: Color3,
	Hot: Color3,
	Main: Color3,
	Dark: Color3,
	Edge: Color3,
	EdgeDark: Color3,
	Accent: Color3,
	Light: Color3,
}

local Palette = {}

local white = Color3.new(1, 1, 1)

local function shift(color: Color3, hue: number, saturation: number, value: number, lift: number): Color3
	local h, s, v = color:ToHSV()
	return Color3.fromHSV((h + hue) % 1, math.clamp(s + saturation, 0, 1), math.clamp(v * value + lift, 0, 1))
end

local function ramp(colors: { Color3 }, times: { number }): ColorSequence
	local keys = {}
	for i, color in colors do
		keys[i] = ColorSequenceKeypoint.new(times[i], color)
	end
	return ColorSequence.new(keys)
end

function Palette.Derive(main: Color3, accent: Color3?): Colors
	local edgeBase = accent or main
	return {
		Core = white:Lerp(main, 0.18),
		Hot = shift(main, 0.03, -0.15, 1, 0.15),
		Main = main,
		Dark = shift(main, -0.06, 0.1, 0.55, 0),
		Edge = shift(edgeBase, -0.02, 0.15, 0.8, 0),
		EdgeDark = shift(edgeBase, -0.06, 0.2, 0.4, 0),
		Accent = edgeBase,
		Light = white:Lerp(main, 0.8),
	}
end

function Palette.Apply(rig: Types.Rig, main: Color3, accent: Color3?)
	local colors = Palette.Derive(main, accent)
	local sequences: { [Types.Role]: ColorSequence } = {
		Glow = ramp({ colors.Core, colors.Hot }, { 0, 1 }),
		Wisp = ramp({ colors.Core, colors.Hot, colors.Main, colors.Dark }, { 0, 0.3, 0.6, 1 }),
		Edge = ramp({ colors.Edge, colors.EdgeDark }, { 0, 1 }),
		Spark = ramp({ colors.Core, colors.Accent, colors.EdgeDark }, { 0, 0.45, 1 }),
		Ring = ramp({ colors.Hot, colors.Main, colors.Dark }, { 0, 0.5, 1 }),
	}
	for _, entry in rig.Emitters do
		entry.Emitter.Color = sequences[entry.Role]
	end
	rig.Light.Color = colors.Light
end

return Palette
