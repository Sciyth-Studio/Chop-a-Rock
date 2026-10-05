--!strict

export type Context = {
	Controllers: { [string]: any },
	Open: (name: string, argument: any?) -> (),
	Close: (name: string) -> (),
}

export type Screen = {
	Modal: boolean,
	StartsOpen: boolean,
	Open: (self: Screen, argument: any?) -> (),
	Close: (self: Screen) -> (),
	Destroy: (self: Screen) -> (),
}

export type ScreenModule = {
	new: (context: Context, gui: ScreenGui) -> Screen,
}

return {}
