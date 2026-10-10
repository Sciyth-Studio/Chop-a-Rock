--!strict

export type WalkSpeedSettings = {
	BaseWalkSpeed: number,
	TargetAttribute: string,
}

local WalkSpeedConfig: WalkSpeedSettings = {
	BaseWalkSpeed = 16,
	TargetAttribute = "WalkSpeedTarget",
}

return table.freeze(WalkSpeedConfig)
