--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local controllers: { Lifecycle.System } = {
	require(script.Parent.Controllers.AppController),
	require(script.Parent.Controllers.UIController),
	require(script.Parent.Controllers.ComponentController),
	require(script.Parent.Controllers.ChopController),
	require(script.Parent.Controllers.TrainingController),
	require(script.Parent.Controllers.GuideController),
	require(script.Parent.Controllers.NotificationController),
	require(script.Parent.Controllers.DevController),
}

return controllers
