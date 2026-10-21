--!strict

export type Geode = {
	Id: number,
	Model: Model,
	Part: BasePart,
	Spot: Attachment,
	Zone: string,
	GeodeKey: string,
	Health: number,
	MaxHealth: number,
	StrengthRequired: number,
	ReserveOwner: string,
	LandsAt: number,
	ClaimedBy: Player?,
	ClaimExpiresAt: number?,
	IsDone: boolean,
}

export type Fall = {
	Zone: string,
	GeodeKey: string,
	Total: number,
	Left: number,
	LandsAt: number,
	EndsAt: number,
	Geodes: { [number]: Geode },
	IsEnding: boolean,
}

export type Session = {
	Geode: Geode,
	StrengthRatio: number,
	Center: number,
	StartTime: number?,
	Round: number,
}

export type Track = {
	Position: Vector3?,
	SampledAt: number,
	AllowedUntil: number,
	FlaggedUntil: number,
}

return {}
