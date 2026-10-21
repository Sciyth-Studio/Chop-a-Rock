--!strict

local Packet = require(script.Parent.Packet)

local Packets = {
	Ping = Packet("Ping"):Response(Packet.NumberF64):RateLimit(5, 1),
	ChopMinigameStart = Packet(
		"ChopMinigameStart",
		Packet.Instance,
		Packet.Boolean8,
		Packet.NumberF64,
		Packet.NumberF64,
		Packet.NumberF64,
		Packet.NumberF64
	):RateLimit(3, 1),
	RockReady = Packet("RockReady"):RateLimit(2, 1),
	RockSpawned = Packet(
		"RockSpawned",
		Packet.NumberU32,
		Packet.String,
		Packet.Vector3F32,
		Packet.String,
		Packet.String
	),
	RockChop = Packet("RockChop", Packet.NumberU32):RateLimit(3, 1),
	RockMinigameStart = Packet(
		"RockMinigameStart",
		Packet.NumberU32,
		Packet.Boolean8,
		Packet.NumberF64,
		Packet.NumberF64,
		Packet.NumberF64,
		Packet.NumberF64
	),
	RockChopped = Packet("RockChopped", Packet.NumberU32, Packet.NumberU8, Packet.Boolean8),
	RockChopShown = Packet(
		"RockChopShown",
		Packet.Vector3F32,
		Packet.NumberF32,
		Packet.NumberU8,
		Packet.Boolean8
	),
	RockRushEnded = Packet("RockRushEnded", Packet.NumberU32),
	RockRemoved = Packet("RockRemoved", Packet.NumberU32),
	RockWeatherSet = Packet("RockWeatherSet", Packet.NumberU32, Packet.String),
	DiamondChop = Packet("DiamondChop"):RateLimit(3, 1),
	DiamondChopped = Packet("DiamondChopped", Packet.NumberU8, Packet.Boolean8),
	DiamondEnded = Packet("DiamondEnded"),
	GeodeFallChop = Packet("GeodeFallChop", Packet.NumberU16):RateLimit(3, 1),
	GeodeFallChopped = Packet("GeodeFallChopped", Packet.NumberU16, Packet.NumberU8, Packet.Boolean8),
	ChopEnded = Packet("ChopEnded"),
	RockSpawnSpots = Packet("RockSpawnSpots", { Packet.Vector3F32 }, { Packet.String }),
	ChopRoundStart = Packet("ChopRoundStart", Packet.NumberF64):RateLimit(5, 1),
	ChopRelease = Packet("ChopRelease", Packet.NumberF32):RateLimit(3, 1),
	ChopLeave = Packet("ChopLeave"):RateLimit(3, 1),
	ChopResult = Packet(
		"ChopResult",
		Packet.NumberU8,
		Packet.NumberU32,
		Packet.NumberF64,
		Packet.NumberF64,
		Packet.NumberF64
	):RateLimit(5, 1),
	TrainingStarted = Packet("TrainingStarted"):RateLimit(5, 1),
	TrainingStopped = Packet("TrainingStopped"):RateLimit(5, 1),
	TrainingChop = Packet("TrainingChop"):RateLimit(5, 1),
	TrainingStopRequest = Packet("TrainingStopRequest"):RateLimit(5, 1),
	UpgradeTraining = Packet("UpgradeTraining"):Response(Packet.String):RateLimit(3, 1),
	TrainingMinigameOpen = Packet("TrainingMinigameOpen"):Response(Packet.Boolean8):RateLimit(3, 1),
	TrainingMinigameClose = Packet("TrainingMinigameClose"):RateLimit(3, 1),
	TrainingMinigameWave = Packet(
		"TrainingMinigameWave",
		{ Packet.NumberU16 },
		{ Packet.NumberU8 },
		{ Packet.NumberF32 },
		{ Packet.NumberF32 },
		{ Packet.NumberF32 },
		{ Packet.NumberF32 }
	),
	TrainingMinigameSlice = Packet("TrainingMinigameSlice", Packet.NumberU16):RateLimit(30, 1),
	TrainingMinigameScore = Packet("TrainingMinigameScore", Packet.NumberU16, Packet.NumberF64),
	BuyAura = Packet("BuyAura", Packet.NumberU8):Response(Packet.Boolean8):RateLimit(5, 1),
	BuyCannon = Packet("BuyCannon", Packet.String):Response(Packet.Boolean8):RateLimit(5, 1),
	EquipCannon = Packet("EquipCannon", Packet.String):Response(Packet.Boolean8):RateLimit(5, 1),
	CannonLaunch = Packet(
		"CannonLaunch",
		Packet.Instance,
		Packet.String,
		Packet.Vector3F32,
		Packet.Vector3F32,
		Packet.NumberF32,
		Packet.NumberF32,
		Packet.NumberF32
	),
	CannonEmpty = Packet("CannonEmpty"),
	Rebirth = Packet("Rebirth"):Response(Packet.Boolean8):RateLimit(2, 1),
	BuyGeode = Packet("BuyGeode", Packet.String, Packet.NumberU8):Response(Packet.Boolean8):RateLimit(5, 1),
	GeodeHatched = Packet(
		"GeodeHatched",
		Packet.Instance,
		Packet.Instance,
		Packet.String,
		Packet.String,
		Packet.NumberU8,
		Packet.Boolean8,
		Packet.String,
		Packet.String
	),
	UnequipPet = Packet("UnequipPet", Packet.NumberU8):Response(Packet.Boolean8):RateLimit(10, 1),
	EquipBestPets = Packet("EquipBestPets"):Response(Packet.Boolean8):RateLimit(2, 1),
	BuyPedestalSlot = Packet("BuyPedestalSlot"):Response(Packet.Boolean8):RateLimit(3, 1),
	SellPets = Packet("SellPets", { Packet.String }):Response(Packet.NumberF64):RateLimit(3, 1),
	ClaimIndex = Packet("ClaimIndex", Packet.String, Packet.String)
		:Response(Packet.Boolean8)
		:RateLimit(10, 1),
	ClaimIndexZone = Packet("ClaimIndexZone", Packet.String, Packet.String)
		:Response(Packet.Boolean8)
		:RateLimit(5, 1),
	ClaimAllIndex = Packet("ClaimAllIndex"):Response(Packet.NumberU8):RateLimit(2, 1),
	SetSetting = Packet("SetSetting", Packet.String, Packet.Boolean8):RateLimit(5, 1),
	SetVolume = Packet("SetVolume", Packet.String, Packet.NumberU8):RateLimit(20, 1),
	PadCollected = Packet("PadCollected"),
	Notify = Packet("Notify", Packet.String, Packet.String),
	AdminRun = Packet("AdminRun", Packet.String, Packet.String):RateLimit(5, 1),
	Teleport = Packet("Teleport", Packet.String):RateLimit(6, 1),
	TutorialSkip = Packet("TutorialSkip"):RateLimit(2, 1),
}

return Packets
