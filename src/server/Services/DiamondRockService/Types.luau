--!strict

export type Diamond = {
	Model: Model,
	Part: BasePart,
	Zone: string,
	Health: number,
	MaxHealth: number,
	Value: number,
	StrengthRequired: number,
	UpAt: number,
	EndsAt: number,
	Slots: { [number]: Player },
	Earned: { [Player]: number },
	IsEnding: boolean,
}

export type Session = {
	Diamond: Diamond,
	Slot: number,
	CanBreak: boolean,
	StrengthRatio: number,
	Center: number,
	StartTime: number?,
	Round: number,
}

export type ZoneStats = {
	FirstRequirement: number,
	TopStrength: number,
	TopPayout: number,
}

return {}
