--!strict

export type Geode = {
	Id: number,
	Model: Model,
	Part: BasePart,
	Zone: string,
	StrengthRequired: number,
	ReserveOwner: string,
	LandsAt: number,
	IsDone: boolean,
}

export type Fall = {
	Label: string,
	Zones: { string },
	Total: number,
	Left: number,
	LandsAt: number,
	EndsAt: number,
	Geodes: { [number]: Geode },
	IsEnding: boolean,
}

export type Track = {
	Position: Vector3?,
	SampledAt: number,
	AllowedUntil: number,
	FlaggedUntil: number,
}

return {}
