--!strict

export type Stat = {
	Name: string,
	Field: string,
}

local PlayerListConfig = {
	FolderName = "leaderstats",
	RefreshSeconds = 0.5,
	Stats = table.freeze({
		table.freeze({ Name = "Strength", Field = "Strength" }),
		table.freeze({ Name = "Money", Field = "Cash" }),
		table.freeze({ Name = "Rebirths", Field = "Rebirths" }),
	}) :: { Stat },
}

return table.freeze(PlayerListConfig)
