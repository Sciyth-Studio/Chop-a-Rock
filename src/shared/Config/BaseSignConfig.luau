--!strict

export type BaseSignSettings = {
	PlotTag: string,
	OwnerAttribute: string,
	SignName: string,
	NameLabelName: string,
	HeadshotName: string,
	HeadshotFormat: string,
}

local BaseSignConfig: BaseSignSettings = {
	PlotTag = "BasePlot",
	OwnerAttribute = "OwnerUserId",
	SignName = "OwnerSign",
	NameLabelName = "OwnerName",
	HeadshotName = "Headshot",
	HeadshotFormat = "rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150",
}

return table.freeze(BaseSignConfig)
