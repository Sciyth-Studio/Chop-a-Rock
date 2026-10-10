--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RockConfig = require(ReplicatedStorage.Config.RockConfig)

export type Shape = {
	Key: string,
	Size: Vector3,
	Rotation: CFrame,
	IsRelative: boolean,
	Radius: number,
}

export type Spot = {
	Position: Vector3,
	Fits: { [string]: boolean },
	Largest: string?,
}

export type Rock = {
	Id: number,
	Key: string,
	Config: RockConfig.Rock,
	Zone: string,
	CFrame: CFrame,
	Size: Vector3,
	Modifier: string?,
	UpAt: number,
}

export type Reserved = {
	Zone: string,
	Position: Vector3,
	Radius: number,
}

export type RushState = {
	ChopSeconds: number,
	LastChopAt: number?,
	ActiveId: number?,
	IsScheduled: boolean,
}

export type Session = {
	Rock: Rock,
	CanBreak: boolean,
	StrengthRatio: number,
	Health: number,
	MaxHealth: number,
	Center: number,
	StartTime: number?,
	Round: number,
}

return {}
