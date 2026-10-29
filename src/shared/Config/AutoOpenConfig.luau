--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChopQuality = require(ReplicatedStorage.ChopQuality)

export type AutoOpenSettings = {
	PassKey: string,
	QualityWeights: { [number]: number },
	StartDelaySeconds: number,
	RangeStuds: number,
	RangeCheckSeconds: number,
	PromptName: string,
	PromptTag: string,
	PromptOffset: Vector3,
	PromptKey: Enum.KeyCode,
	PromptGamepadKey: Enum.KeyCode,
	PromptText: string,
	PromptPriceFormat: string,
	RunningAttribute: string,
	CountAttribute: string,
	ScreenName: string,
	PillFormat: string,
	DoneText: string,
	StoppedText: string,
	BagFullText: string,
}

local AutoOpenConfig: AutoOpenSettings = {
	PassKey = "AutoOpen",
	QualityWeights = {
		[ChopQuality.Bad] = 5,
		[ChopQuality.Mid] = 15,
		[ChopQuality.Good] = 40,
		[ChopQuality.Great] = 25,
		[ChopQuality.Perfect] = 15,
	},
	StartDelaySeconds = 0.3,
	RangeStuds = 14,
	RangeCheckSeconds = 0.5,
	PromptName = "AutoPrompt",
	PromptTag = "AutoOpenPrompt",
	PromptOffset = Vector3.new(0, 6, 0),
	PromptKey = Enum.KeyCode.R,
	PromptGamepadKey = Enum.KeyCode.ButtonL1,
	PromptText = "Auto Open",
	PromptPriceFormat = "Auto Open (%s%d)",
	RunningAttribute = "AutoOpening",
	CountAttribute = "AutoOpenCount",
	ScreenName = "AutoOpenButton",
	PillFormat = "Auto Open · %d opened",
	DoneText = "All geodes opened!",
	StoppedText = "Auto Open stopped",
	BagFullText = "Bag full! Sell some Roks",
}

return table.freeze(AutoOpenConfig)
