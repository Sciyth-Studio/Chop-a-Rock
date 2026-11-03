--!strict

export type Scene = {
	Folder: Folder,
	Model: Model,
	Origin: CFrame,
	Scale: number,
	CenterHeight: number,
	Highlight: Highlight,
	Anchor: BasePart,
}

export type ShownPet = {
	Model: Model,
	Scale: number,
	Facing: CFrame,
	Lift: number,
}

export type Pose = {
	Height: number,
	Scale: number,
	Shake: number,
	Spin: number,
}

export type Hatch = {
	Owner: Player?,
	GeodeKey: string,
	PetKey: string,
	Rarity: string,
	IsNew: boolean,
	Trait: string?,
	Modifier: string?,
	Size: string?,
}

return {}
