--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local services: { Lifecycle.System } = {
	require(script.Parent.Services.DataService),
	require(script.Parent.Services.PurchaseService),
	require(script.Parent.Services.GameService),
	require(script.Parent.Services.ComponentService),
	require(script.Parent.Services.StatsService),
	require(script.Parent.Services.RockService),
	require(script.Parent.Services.TrainingService),
}

return services
