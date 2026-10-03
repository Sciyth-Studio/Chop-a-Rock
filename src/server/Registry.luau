--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local services: { Lifecycle.System } = {
	require(script.Parent.Services.DataService),
	require(script.Parent.Services.PurchaseService),
	require(script.Parent.Services.GameService),
	require(script.Parent.Services.ComponentService),
	require(script.Parent.Services.NotificationService),
	require(script.Parent.Services.StatsService),
	require(script.Parent.Services.FriendBoostService),
	require(script.Parent.Services.ArmService),
	require(script.Parent.Services.ArmVisualService),
	require(script.Parent.Services.RebirthService),
	require(script.Parent.Services.RockService),
	require(script.Parent.Services.TrainingService),
	require(script.Parent.Services.ShopService),
}

return services
