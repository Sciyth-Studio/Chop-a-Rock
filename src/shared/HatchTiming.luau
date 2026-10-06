--!strict

local HatchRevealConfig = require(script.Parent.Config.HatchRevealConfig)
local RarityConfig = require(script.Parent.Config.RarityConfig)

local HatchTiming = {}

function HatchTiming.Steps(rarityKey: string): number
	return table.find(RarityConfig.Order, rarityKey) or 1
end

function HatchTiming.RevealSeconds(rarityKey: string): number
	return HatchRevealConfig.HoverSeconds
		+ HatchRevealConfig.WhitenSeconds
		+ HatchRevealConfig.SpinUpSeconds
		+ HatchTiming.Steps(rarityKey) * (HatchRevealConfig.StepSeconds + HatchRevealConfig.StepPauseSeconds)
		+ HatchRevealConfig.PopHoldSeconds
end

return table.freeze(HatchTiming)
