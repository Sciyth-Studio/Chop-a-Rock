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
	ChopRoundStart = Packet("ChopRoundStart", Packet.NumberF64):RateLimit(5, 1),
	ChopRelease = Packet("ChopRelease"):RateLimit(3, 1),
	ChopLeave = Packet("ChopLeave"):RateLimit(3, 1),
	ChopResult = Packet("ChopResult", Packet.NumberU8, Packet.NumberU32, Packet.NumberF64, Packet.NumberF64):RateLimit(
		5,
		1
	),
	TrainingStarted = Packet("TrainingStarted"):RateLimit(5, 1),
	TrainingStopped = Packet("TrainingStopped"):RateLimit(5, 1),
	TrainingChop = Packet("TrainingChop"):RateLimit(5, 1),
	TrainingStopRequest = Packet("TrainingStopRequest"):RateLimit(5, 1),
	BuyArm = Packet("BuyArm", Packet.NumberU8):Response(Packet.Boolean8):RateLimit(5, 1),
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
	AdminRun = Packet("AdminRun", Packet.String):RateLimit(5, 1),
}

return Packets
