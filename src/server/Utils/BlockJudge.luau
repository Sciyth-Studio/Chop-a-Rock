--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local BlockRoundConfig = require(ReplicatedStorage.Config.BlockRoundConfig)
local ChopConfig = require(ReplicatedStorage.Config.ChopConfig)
local ChopTiming = require(ServerScriptService.Utils.ChopTiming)
local ChopZones = require(ReplicatedStorage.ChopZones)

export type Difficulty = { Speed: number, ZoneScale: number }

local BlockJudge = {}

function BlockJudge.Judge(
	startTime: number,
	claimed: number,
	center: number,
	isTouch: boolean,
	difficulty: Difficulty
): number
	local elapsed = ChopTiming.Elapsed(startTime, claimed)
	if elapsed < BlockRoundConfig.LeadSeconds then
		return BlockRoundConfig.Outcomes.Missed
	end
	local position = ChopZones.BlockPosition(elapsed, isTouch, difficulty.Speed)
	return ChopZones.ClassifyBlock(position, center, isTouch, difficulty.ZoneScale)
end

function BlockJudge.TimeoutSeconds(isTouch: boolean, difficulty: Difficulty): number
	return BlockRoundConfig.LeadSeconds
		+ ChopZones.BlockPassSeconds(isTouch, difficulty.Speed)
		+ ChopConfig.MaxLatencySeconds
end

return BlockJudge
