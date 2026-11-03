--!strict

export type Result = "Won" | "Fled" | "Lost" | "Left"

export type Fight = {
	Zone: string,
	Anchor: Vector3,
	LeaveStuds: number,
	MaxHealth: number,
	Health: number,
	EndsAt: number,
	ShownAt: number,
	OnResult: (result: Result) -> (),
}

return {}
