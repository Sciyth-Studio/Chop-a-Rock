--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lifecycle = require(ReplicatedStorage.Lifecycle)

local services: { Lifecycle.System } = {
	require(script.Parent.Services.DataService),
	require(script.Parent.Services.PurchaseService),
	require(script.Parent.Services.PassService),
	require(script.Parent.Services.GameService),
	require(script.Parent.Services.ComponentService),
	require(script.Parent.Services.NotificationService),
	require(script.Parent.Services.AnnouncementService),
	require(script.Parent.Services.CollisionService),
	require(script.Parent.Services.StatsService),
	require(script.Parent.Services.WalkSpeedService),
	require(script.Parent.Services.HotStreakService),
	require(script.Parent.Services.FriendBoostService),
	require(script.Parent.Services.RebirthService),
	require(script.Parent.Services.AuraService),
	require(script.Parent.Services.IndexService),
	require(script.Parent.Services.PetService),
	require(script.Parent.Services.BaseService),
	require(script.Parent.Services.VipBaseService),
	require(script.Parent.Services.RockService),
	require(script.Parent.Services.DiamondRockService),
	require(script.Parent.Services.WeatherService),
	require(script.Parent.Services.TrainingService),
	require(script.Parent.Services.GeodeService),
	require(script.Parent.Services.PedestalService),
	require(script.Parent.Services.TutorialService),
	require(script.Parent.Services.BoostService),
	require(script.Parent.Services.OfferService),
	require(script.Parent.Services.ExclusiveService),
	require(script.Parent.Services.RobuxShopFunnelService),
	require(script.Parent.Services.TeleportService),
	require(script.Parent.Services.CannonService),
	require(script.Parent.Services.GeodeFallService),
	require(script.Parent.Services.CannonHintService),
	require(script.Parent.Services.AuraHintService),
	require(script.Parent.Services.RockHintService),
	require(script.Parent.Services.RebirthHintService),
	require(script.Parent.Services.LeaderboardService),
	require(script.Parent.Services.PlayerListService),
	require(script.Parent.Services.AdminService),
	require(script.Parent.Services.SettingsService),
}

return services
