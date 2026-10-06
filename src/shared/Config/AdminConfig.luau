--!strict

export type Command = {
	Id: string,
	Label: string,
	Shortcut: Enum.KeyCode?,
}

export type AdminSettings = {
	UserIds: { number },
	AttributeName: string,
	Commands: { Command },
	ShortcutModifiers: { Enum.KeyCode },
	CashAmount: number,
	TopbarLabel: string,
}

local AdminConfig: AdminSettings = {
	UserIds = {},
	AttributeName = "IsAdmin",
	Commands = {
		{ Id = "GrantCash", Label = "+1,000 Cash", Shortcut = Enum.KeyCode.C },
		{ Id = "GrantPet", Label = "Grant Rok", Shortcut = Enum.KeyCode.P },
		{ Id = "GrantGeode", Label = "+1 Geode", Shortcut = Enum.KeyCode.G },
		{ Id = "ForceMaster", Label = "Next Chop: Master", Shortcut = Enum.KeyCode.M },
		{ Id = "ForceSecret", Label = "Next Hatch: Secret", Shortcut = Enum.KeyCode.H },
		{ Id = "ResetData", Label = "Reset My Data", Shortcut = Enum.KeyCode.Backspace },
	},
	ShortcutModifiers = { Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift },
	CashAmount = 1000,
	TopbarLabel = "Admin",
}

return table.freeze(AdminConfig)
