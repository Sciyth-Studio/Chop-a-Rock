--!strict

export type Piece = {
	Parts: { BasePart },
	Finals: { CFrame },
	Collides: { boolean },
	Base: Vector3,
	Width: number,
	Depth: number,
	Distance: number,
	Angle: number,
	IsProp: boolean,
	Delay: number,
	Duration: number,
	Started: boolean,
	Finished: boolean,
}

export type Active = {
	Model: Model,
	Boss: Model,
	Pieces: { Piece },
	Emitters: { ParticleEmitter },
	Centre: Vector3,
	DustColor: Color3,
	Token: number,
	Sinking: boolean,
}

return nil
