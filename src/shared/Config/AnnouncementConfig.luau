--!strict

export type AnnouncementSettings = {
	Topic: string,
	Kind: string,
	MaxLength: number,
	CooldownSeconds: number,
}

local AnnouncementConfig: AnnouncementSettings = {
	Topic = "AdminAnnouncement",
	Kind = "Announcement",
	MaxLength = 200,
	CooldownSeconds = 5,
}

return table.freeze(AnnouncementConfig)
