--!strict

export type BaseOwnerSettings = {
	SpotName: string,
	TagName: string,
	NameLabelName: string,
	ImageName: string,
	NamePrefix: string,
	ImageFormat: string,
}

local BaseOwnerConfig: BaseOwnerSettings = {
	SpotName = "OwnerSpot",
	TagName = "OwnerTag",
	NameLabelName = "OwnerName",
	ImageName = "Avatar",
	NamePrefix = "@",
	ImageFormat = "rbxthumb://type=AvatarBust&id=%d&w=420&h=420",
}

return table.freeze(BaseOwnerConfig)
