--!strict

export type WalkSpeedSettings = {
	BaseWalkSpeed: number,
	TargetAttribute: string,
}

local WalkSpeedConfig: WalkSpeedSettings = {
	BaseWalkSpeed = 25,
	TargetAttribute = "WalkSpeedTarget",
}

return table.freeze(WalkSpeedConfig)
