--!strict

export type Role = "Glow" | "Wisp" | "Edge" | "Spark" | "Ring"

export type Emitter = {
	Emitter: ParticleEmitter,
	Role: Role,
	Rate: number,
	Size: NumberSequence,
	Speed: NumberRange,
	Acceleration: Vector3,
	Burst: number,
	Lifts: boolean,
	Sways: boolean,
}

export type Rig = {
	Emitters: { Emitter },
	Light: PointLight,
	Shockwave: ParticleEmitter?,
	Instances: { Instance },
}

export type Aura = {
	Character: Model,
	Root: BasePart,
	SetEnabled: (self: Aura, isEnabled: boolean) -> (),
	Destroy: (self: Aura) -> (),
}

return {}
