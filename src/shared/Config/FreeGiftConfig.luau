--!strict

local IconConfig = require(script.Parent.IconConfig)

export type Step = {
	Title: string,
	Image: string,
	Action: string,
}

export type FreeGiftSettings = {
	GroupId: number,
	Geodes: number,
	OfferKey: string,
	Results: {
		Claimed: string,
		NotInGroup: string,
		AlreadyClaimed: string,
		Failed: string,
	},
	Texts: {
		Title: string,
		Reward: string,
		Claim: string,
		Claimed: string,
		JoinFirst: string,
		TryAgain: string,
	},
	RewardImage: string,
	Steps: { Step },
	HintSeconds: number,
}

local FreeGiftConfig: FreeGiftSettings = {
	GroupId = 10962733,
	Geodes = 3,
	OfferKey = "FreeGift",
	Results = table.freeze({
		Claimed = "Claimed",
		NotInGroup = "NotInGroup",
		AlreadyClaimed = "AlreadyClaimed",
		Failed = "Failed",
	}),
	Texts = table.freeze({
		Title = "Free Gift!",
		Reward = "Free %s Cash",
		Claim = "Claim",
		Claimed = "Claimed!",
		JoinFirst = "Join the community first!",
		TryAgain = "Something went wrong, try again",
	}),
	RewardImage = IconConfig.Cash5,
	Steps = {
		table.freeze({ Title = "1. Like the game", Image = "rbxassetid://125216111619355", Action = "Like" }),
		table.freeze({
			Title = "2. Favorite the game",
			Image = "rbxassetid://76440492325219",
			Action = "Favorite",
		}),
		table.freeze({
			Title = "3. Join the community",
			Image = "rbxassetid://91515294617775",
			Action = "Join",
		}),
	},
	HintSeconds = 3,
}

table.freeze(FreeGiftConfig.Steps)
return table.freeze(FreeGiftConfig)
