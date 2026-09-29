--!strict

local Packet = require(script.Parent.Packet)

local Packets = {
	Ping = Packet("Ping"):Response(Packet.NumberF64):RateLimit(5, 1),
	ChopMinigameStart = Packet("ChopMinigameStart", Packet.Instance, Packet.Boolean8):RateLimit(3, 1),
	ChopRelease = Packet("ChopRelease"):RateLimit(3, 1),
	ChopResult = Packet("ChopResult", Packet.NumberU8, Packet.NumberU32):RateLimit(5, 1),
	TrainingStarted = Packet("TrainingStarted"):RateLimit(5, 1),
	TrainingStopped = Packet("TrainingStopped"):RateLimit(5, 1),
	TrainingStopRequest = Packet("TrainingStopRequest"):RateLimit(5, 1),
	ShopOpen = Packet("ShopOpen"):RateLimit(5, 1),
	BuyArm = Packet("BuyArm", Packet.NumberU8):Response(Packet.Boolean8):RateLimit(5, 1),
}

return Packets
