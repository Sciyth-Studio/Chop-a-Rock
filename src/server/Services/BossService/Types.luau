--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BossHazards = require(ReplicatedStorage.BossHazards)

export type Spot = {
	Index: number,
	Part: BasePart,
	Slots: { [number]: Player },
}

export type Fight = {
	Key: string,
	Model: Model,
	Animator: Animator?,
	Loop: AnimationTrack?,
	Spots: { Spot },
	Phase: number,
	IsMad: boolean,
	Health: number,
	MaxHealth: number,
	EndsAt: number,
	FinishUntil: number,
	GoldSpot: number,
	NextGoldMove: number,
	LastAttack: number,
	Counted: { [Player]: number },
	Dealt: { [Player]: number },
	Pending: { [Player]: number },
	PlayerHealth: { [Player]: number },
	KnockedOut: { [Player]: true },
	NextBonus: { [Player]: number },
	Token: number,
	Busy: boolean,
	Attack: number,
	AttackToken: number,
	SlamDone: boolean,
	BigCount: number,
	SlamRadius: number,
	Hazard: BossHazards.Hazard?,
	NextSignature: number,
}

export type Session = {
	Fight: Fight,
	Spot: Spot,
	Slot: number,
	StrengthRatio: number,
	ZoneRatio: number,
	PerfectScale: number,
	Center: number,
	StartTime: number?,
	BlockStart: number?,
	BlockDifficulty: { Speed: number, ZoneScale: number }?,
	Round: number,
	Bonus: number,
	SignatureLeft: number,
	Modifier: number,
	Centers: { number }?,
}

return {}
