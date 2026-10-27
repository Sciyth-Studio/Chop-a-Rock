--!strict

export type GiftPickerSettings = {
	ScreenName: string,
	PickGiftText: string,
	PickPlayerText: string,
	SendText: string,
	FreeText: string,
	OwnedText: string,
	CantReceiveText: string,
	SentText: string,
	FailedText: string,
	PaletteByKind: { [string]: string },
}

local GiftPickerConfig: GiftPickerSettings = {
	ScreenName = "GiftPicker",
	PickGiftText = "Pick a gift",
	PickPlayerText = "Who gets %s?",
	SendText = "Send",
	FreeText = "Send free (%d)",
	OwnedText = "Has it",
	CantReceiveText = "Can't get it",
	SentText = "Gift sent!",
	FailedText = "That gift couldn't be sent",
	PaletteByKind = {
		Pass = "Gold",
		Boost = "Orange",
		Lucky = "Lucky",
		CashPack = "Green",
		Exclusive = "Purple",
	},
}

return table.freeze(GiftPickerConfig)
