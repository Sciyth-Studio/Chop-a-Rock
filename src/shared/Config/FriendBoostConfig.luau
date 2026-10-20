--!strict

export type FriendBoostSettings = {
	FirstFriendPercent: number,
	AdditionalFriendPercent: number,
	MaxPercent: number,
}

local FriendBoostConfig: FriendBoostSettings = {
	FirstFriendPercent = 15,
	AdditionalFriendPercent = 5,
	MaxPercent = 30,
}

return table.freeze(FriendBoostConfig)
