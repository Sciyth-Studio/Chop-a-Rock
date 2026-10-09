--!strict

export type Context = {
	Services: { [string]: any },
}

export type Handler = (context: Context, player: Player, argument: string) -> ()

return {}
