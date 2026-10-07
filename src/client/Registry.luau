--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local controllers: { Lifecycle.System } = {
	require(script.Parent.Controllers.DataController),
	require(script.Parent.Controllers.AppController),
	require(script.Parent.Controllers.UIController),
	require(script.Parent.Controllers.ComponentController),
	require(script.Parent.Controllers.ChopController),
	require(script.Parent.Controllers.RockController),
	require(script.Parent.Controllers.ChopAnimationController),
	require(script.Parent.Controllers.HatchController),
	require(script.Parent.Controllers.TrainingController),
	require(script.Parent.Controllers.GuideController),
	require(script.Parent.Controllers.NotificationController),
	require(script.Parent.Controllers.AdminController),
	require(script.Parent.Controllers.PromptController),
	require(script.Parent.Controllers.MusicController),
	require(script.Parent.Controllers.SettingsController),
	require(script.Parent.Controllers.PadSoundController),
	require(script.Parent.Controllers.LevelUpController),
}

return controllers
