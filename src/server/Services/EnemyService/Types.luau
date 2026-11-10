--!strict

export type Result = "Won" | "Fled" | "Lost" | "Left"

export type Fight = {
	Zone: string,
	Anchor: Vector3,
	LeaveStuds: number,
	MaxHealth: number,
	Health: number,
	StartsAt: number,
	Deadline: number,
	StrengthRatio: number,
	Center: number,
	RoundStart: number?,
	Round: number,
	IsGentle: boolean,
	IsOver: boolean,
	ShownAt: number,
	OnResult: (result: Result) -> (),
}

return {}
