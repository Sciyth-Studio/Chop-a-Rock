--!strict

export type FriendBoostSettings = {
	FirstFriendPercent: number,
	AdditionalFriendPercent: number,
}

local FriendBoostConfig: FriendBoostSettings = {
	FirstFriendPercent = 15,
	AdditionalFriendPercent = 5,
}

return table.freeze(FriendBoostConfig)
