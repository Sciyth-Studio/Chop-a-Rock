--!strict

export type Context = {
	Services: { [string]: any },
	ForcedRarities: { [Player]: string },
}

export type Pit = {
	ModelKey: string,
	Model: Model,
	Part: BasePart,
}

export type Session = {
	GeodeKey: string,
	Spot: Attachment,
	Model: Model,
	Part: BasePart,
	CanBreak: boolean,
	StrengthRatio: number,
	Center: number,
	StartTime: number,
}

return {}
