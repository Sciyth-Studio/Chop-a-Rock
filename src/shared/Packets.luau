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
	SetSetting = Packet("SetSetting", Packet.String, Packet.Boolean8):RateLimit(5, 1),
	Notify = Packet("Notify", Packet.String, Packet.String),
	DevResetData = Packet("DevResetData"):RateLimit(1, 2),
	DevForceMaster = Packet("DevForceMaster"):RateLimit(1, 1),
}

return Packets
