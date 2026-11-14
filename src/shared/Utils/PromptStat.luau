--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local PetSizeConfig = require(ReplicatedStorage.Config.PetSizeConfig)
local PromptStatConfig = require(ReplicatedStorage.Config.PromptStatConfig)

export type Kind = "Money" | "Time" | "Luck"

local PromptStat = {}

function PromptStat.Text(stat: string, kind: Kind, name: string): string
	local color = PromptStatConfig.Colors[kind] or Color3.new(1, 1, 1)
	return `[<font color="#{color:ToHex()}">{stat}</font>] {name}`
end

function PromptStat.Duration(seconds: number): string
	local total = math.max(0, math.ceil(seconds))
	local minutes, rest = total // 60, total % 60
	if minutes == 0 then
		return `{rest}s`
	elseif rest == 0 then
		return `{minutes}m`
	end
	return `{minutes}m {rest}s`
end

function PromptStat.Egg(name: string, hatchSeconds: number): string
	return PromptStat.Text(PromptStat.Duration(hatchSeconds), "Time", name)
end

function PromptStat.Pet(name: string, income: number, size: string?): string
	local sizeInfo = if size and not PromptStatConfig.HiddenSizes[size]
		then PetSizeConfig.Sizes[size]
		else nil
	local fullName = if sizeInfo then `{sizeInfo.DisplayName} {name}` else name
	local stat = string.format(PromptStatConfig.MoneyFormat, NumberFormat.Rate(income))
	return PromptStat.Text(stat, "Money", fullName)
end

return PromptStat
