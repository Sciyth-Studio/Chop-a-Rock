--!strict

export type Diamond = {
	Model: Model,
	Part: BasePart,
	Health: number,
	MaxHealth: number,
	UpAt: number,
	EndsAt: number,
	Slots: { [number]: Player },
	Earned: { [Player]: number },
	IsEnding: boolean,
}

export type Session = {
	Diamond: Diamond,
	Slot: number,
	StrengthRatio: number,
	Value: number,
	ShareHealth: number,
	Center: number,
	StartTime: number?,
	Round: number,
}

return {}
