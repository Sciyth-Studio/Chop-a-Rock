--!strict

export type PendingReset = {
	UserId: number,
	ExpiresAt: number,
}

export type Context = {
	Services: { [string]: any },
	PendingResets: { [Player]: PendingReset },
}

export type Handler = (context: Context, player: Player, argument: string) -> ()

return {}
