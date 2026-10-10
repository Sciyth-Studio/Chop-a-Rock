--!strict

export type CashPopProfile = {
	CoinCount: number,
	CoinScale: number,
	CoinUpSpeed: NumberRange,
	CoinOutSpeed: NumberRange,
	ShowBurst: boolean,
}

export type CashPopSettings = {
	EffectKey: string,
	TextKey: string,
	Chop: CashPopProfile,
	Pad: CashPopProfile,
	CoinColor: Color3,
	CoinMaterial: Enum.Material,
	CoinSize: Vector3,
	CoinSpinRadPerSec: number,
	CoinLifetimeSeconds: number,
	CoinFadeSeconds: number,
	CollisionGroup: string,
}

local CashPopConfig: CashPopSettings = {
	EffectKey = "VFX_Cash_Pop",
	TextKey = "UI_CashPopText",
	Chop = {
		CoinCount = 3,
		CoinScale = 0.75,
		CoinUpSpeed = NumberRange.new(36, 42),
		CoinOutSpeed = NumberRange.new(4, 8),
		ShowBurst = false,
	},
	Pad = {
		CoinCount = 6,
		CoinScale = 1,
		CoinUpSpeed = NumberRange.new(48, 60),
		CoinOutSpeed = NumberRange.new(8, 14),
		ShowBurst = true,
	},
	CoinColor = Color3.fromRGB(255, 200, 0),
	CoinMaterial = Enum.Material.Neon,
	CoinSize = Vector3.new(0.25, 1.3, 1.3),
	CoinSpinRadPerSec = 18,
	CoinLifetimeSeconds = 1.1,
	CoinFadeSeconds = 0.3,
	CollisionGroup = "Debris",
}

return table.freeze(CashPopConfig)
