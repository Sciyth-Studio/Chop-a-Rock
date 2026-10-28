--!strict

export type Actor = {
	Model: Model,
	Root: BasePart,
	Head: BasePart?,
	Animator: Animator,
	Tracks: { [string]: AnimationTrack },
}

export type Piece = {
	Part: BasePart,
	Start: CFrame,
	Velocity: Vector3,
	Spin: Vector3,
}

export type Stage = {
	Set: Model,
	Markers: { [string]: CFrame },
	Car: Model,
	CarParts: { { Part: BasePart, Size: Vector3, Offset: CFrame } },
	Seat: Attachment,
	Boulder: BasePart,
	BoulderRest: CFrame,
	Pieces: { Piece },
	Shadow: BasePart,
	Player: Actor,
	Master: Actor,
	Stars: { BasePart },
}

return {}
