--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EggDropConfig = require(ReplicatedStorage.Config.EggDropConfig)

local EggLuck = {}

local function share(hundredths: number?): number
	local value = hundredths or EggDropConfig.LuckMinHundredths
	local span = EggDropConfig.LuckMaxHundredths - EggDropConfig.LuckMinHundredths
	return math.clamp((value - EggDropConfig.LuckMinHundredths) / span, 0, 1)
end

function EggLuck.Effect(hundredths: number?): number
	return 1 + share(hundredths) * (EggDropConfig.EffectMaxMultiplier - 1)
end

function EggLuck.Scale(hundredths: number?): number
	return 1 + share(hundredths) * (EggDropConfig.MaxSizeScale - 1)
end

function EggLuck.Text(hundredths: number): string
	return string.format("x%.2f", hundredths / 100)
end

return EggLuck
