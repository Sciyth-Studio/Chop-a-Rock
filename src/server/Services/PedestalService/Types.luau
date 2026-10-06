--!strict

export type SlotEarnings = {
	Rate: number,
	Banked: number,
	BankedAt: number,
}

export type Session = {
	Slots: { [number]: SlotEarnings },
	LastCollect: { [number]: number },
}

export type Context = {
	Services: { [string]: any },
}

return nil
