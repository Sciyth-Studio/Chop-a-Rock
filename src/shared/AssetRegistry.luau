--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

export type AssetCategory = "VFX" | "Sounds" | "Animations" | "Models" | "Images"

type AssetEntry = {
	Category: AssetCategory,
	InstanceName: string,
}

local map: { [string]: AssetEntry } = {
	SFX_Chop_Bad = { Category = "Sounds", InstanceName = "SFX_Chop_Bad" },
	SFX_Chop_Mid = { Category = "Sounds", InstanceName = "SFX_Chop_Mid" },
	SFX_Chop_Good = { Category = "Sounds", InstanceName = "SFX_Chop_Good" },
	SFX_Chop_Great = { Category = "Sounds", InstanceName = "SFX_Chop_Great" },
	SFX_Chop_Perfect = { Category = "Sounds", InstanceName = "SFX_Chop_Perfect" },
	SFX_Chop_Master = { Category = "Sounds", InstanceName = "SFX_Chop_Master" },
	VFX_Master_Burst = { Category = "VFX", InstanceName = "VFX_Master_Burst" },
	VFX_Board_Break = { Category = "VFX", InstanceName = "VFX_Board_Break" },
	VFX_Train_CoreBreak = { Category = "VFX", InstanceName = "VFX_Train_CoreBreak" },
	VFX_Train_CosmicBreak = { Category = "VFX", InstanceName = "VFX_Train_CosmicBreak" },
	VFX_LevelUp = { Category = "VFX", InstanceName = "VFX_LevelUp" },
	VFX_ShopPad = { Category = "VFX", InstanceName = "VFX_ShopPad" },
	VFX_Cannon_Fuse = { Category = "VFX", InstanceName = "VFX_Cannon_Fuse" },
	VFX_Cannon_Charge = { Category = "VFX", InstanceName = "VFX_Cannon_Charge" },
	VFX_Cannon_Blast = { Category = "VFX", InstanceName = "VFX_Cannon_Blast" },
	VFX_Cannon_Trail = { Category = "VFX", InstanceName = "VFX_Cannon_Trail" },
	VFX_Cannon_Land = { Category = "VFX", InstanceName = "VFX_Cannon_Land" },
	VFX_Cannon_Equip = { Category = "VFX", InstanceName = "VFX_Cannon_Equip" },
	VFX_GeodeFall_Meteor = { Category = "VFX", InstanceName = "VFX_GeodeFall_Meteor" },
	VFX_GeodeFall_Marker = { Category = "VFX", InstanceName = "VFX_GeodeFall_Marker" },
	VFX_GeodeFall_Impact = { Category = "VFX", InstanceName = "VFX_GeodeFall_Impact" },
	VFX_GeodeFall_Idle = { Category = "VFX", InstanceName = "VFX_GeodeFall_Idle" },
	SFX_Cannon_Fuse = { Category = "Sounds", InstanceName = "SFX_Cannon_Fuse" },
	SFX_Cannon_Boom = { Category = "Sounds", InstanceName = "SFX_Cannon_Boom" },
	SFX_Cannon_Whoosh = { Category = "Sounds", InstanceName = "SFX_Cannon_Whoosh" },
	SFX_Cannon_Land = { Category = "Sounds", InstanceName = "SFX_Cannon_Land" },
	SFX_Cannon_Equip = { Category = "Sounds", InstanceName = "SFX_Cannon_Equip" },
	SFX_Level_Up = { Category = "Sounds", InstanceName = "SFX_Level_Up" },
	SFX_Rock_Break = { Category = "Sounds", InstanceName = "SFX_Rock_Break" },
	SFX_Rock_Crack = { Category = "Sounds", InstanceName = "SFX_Rock_Crack" },
	SFX_Money_Gain = { Category = "Sounds", InstanceName = "SFX_Money_Gain" },
	SFX_Train_Chop = { Category = "Sounds", InstanceName = "SFX_Train_Chop" },
	SFX_Train_Brick = { Category = "Sounds", InstanceName = "SFX_Train_Brick" },
	SFX_Train_Steel = { Category = "Sounds", InstanceName = "SFX_Train_Steel" },
	SFX_Train_Vault = { Category = "Sounds", InstanceName = "SFX_Train_Vault" },
	SFX_Train_Core = { Category = "Sounds", InstanceName = "SFX_Train_Core" },
	SFX_Train_Cosmic = { Category = "Sounds", InstanceName = "SFX_Train_Cosmic" },
	SFX_Slice_Swipe1 = { Category = "Sounds", InstanceName = "SFX_Slice_Swipe1" },
	SFX_Slice_Swipe2 = { Category = "Sounds", InstanceName = "SFX_Slice_Swipe2" },
	SFX_Slice_Swipe3 = { Category = "Sounds", InstanceName = "SFX_Slice_Swipe3" },
	SFX_Slice_Swipe4 = { Category = "Sounds", InstanceName = "SFX_Slice_Swipe4" },
	SFX_Slice_Swipe5 = { Category = "Sounds", InstanceName = "SFX_Slice_Swipe5" },
	SFX_Slice_Swipe6 = { Category = "Sounds", InstanceName = "SFX_Slice_Swipe6" },
	SFX_Slice_Fuse = { Category = "Sounds", InstanceName = "SFX_Slice_Fuse" },
	SFX_Slice_ThrowBomb = { Category = "Sounds", InstanceName = "SFX_Slice_ThrowBomb" },
	SFX_Slice_ThrowBoard = { Category = "Sounds", InstanceName = "SFX_Slice_ThrowBoard" },
	SFX_Notification = { Category = "Sounds", InstanceName = "SFX_Notification" },
	SFX_UI_Hover = { Category = "Sounds", InstanceName = "SFX_UI_Hover" },
	SFX_UI_Click = { Category = "Sounds", InstanceName = "SFX_UI_Click" },
	SFX_UI_ShopBell = { Category = "Sounds", InstanceName = "SFX_UI_ShopBell" },
	SFX_UI_PanelOpen = { Category = "Sounds", InstanceName = "SFX_UI_PanelOpen" },
	SFX_UI_PanelClose = { Category = "Sounds", InstanceName = "SFX_UI_PanelClose" },
	SFX_UI_Error = { Category = "Sounds", InstanceName = "SFX_UI_Error" },
	SFX_UI_Toggle = { Category = "Sounds", InstanceName = "SFX_UI_Toggle" },
	SFX_UI_Tab = { Category = "Sounds", InstanceName = "SFX_UI_Tab" },
	UI_RockLabel = { Category = "VFX", InstanceName = "RockLabel" },
	UI_ChopPrompt = { Category = "VFX", InstanceName = "ChopPrompt" },
	UI_PedestalPad = { Category = "VFX", InstanceName = "PedestalPad" },
	UI_PedestalInfo = { Category = "VFX", InstanceName = "PedestalInfo" },
	Image_GuideArrow = { Category = "Images", InstanceName = "GuideArrow" },
	SFX_Rock_Rise = { Category = "Sounds", InstanceName = "SFX_Rock_Rise" },
	VFX_Rock_Dust = { Category = "VFX", InstanceName = "VFX_Rock_Dust" },
	Model_Rock_Basic = { Category = "Models", InstanceName = "Model_Rock_Basic" },
	Model_Rock_Second = { Category = "Models", InstanceName = "Model_Rock_Second" },
	Model_Rock_Third = { Category = "Models", InstanceName = "Model_Rock_Third" },
	Model_Rock_DesertFirst = { Category = "Models", InstanceName = "Model_Rock_DesertFirst" },
	Model_Rock_DesertSecond = { Category = "Models", InstanceName = "Model_Rock_DesertSecond" },
	Model_Rock_DesertThird = { Category = "Models", InstanceName = "Model_Rock_DesertThird" },
	Model_Rock_JungleFirst = { Category = "Models", InstanceName = "Model_Rock_JungleFirst" },
	Model_Rock_JungleSecond = { Category = "Models", InstanceName = "Model_Rock_JungleSecond" },
	Model_Rock_JungleThird = { Category = "Models", InstanceName = "Model_Rock_JungleThird" },
	Model_Rock_OceanFirst = { Category = "Models", InstanceName = "Model_Rock_OceanFirst" },
	Model_Rock_OceanSecond = { Category = "Models", InstanceName = "Model_Rock_OceanSecond" },
	Model_Rock_OceanThird = { Category = "Models", InstanceName = "Model_Rock_OceanThird" },
	Model_Rock_SnowFirst = { Category = "Models", InstanceName = "Model_Rock_SnowFirst" },
	Model_Rock_SnowSecond = { Category = "Models", InstanceName = "Model_Rock_SnowSecond" },
	Model_Rock_SnowThird = { Category = "Models", InstanceName = "Model_Rock_SnowThird" },
	Model_Rock_SwampFirst = { Category = "Models", InstanceName = "Model_Rock_SwampFirst" },
	Model_Rock_SwampSecond = { Category = "Models", InstanceName = "Model_Rock_SwampSecond" },
	Model_Rock_SwampThird = { Category = "Models", InstanceName = "Model_Rock_SwampThird" },
	Model_Rock_SavannaFirst = { Category = "Models", InstanceName = "Model_Rock_SavannaFirst" },
	Model_Rock_SavannaSecond = { Category = "Models", InstanceName = "Model_Rock_SavannaSecond" },
	Model_Rock_SavannaThird = { Category = "Models", InstanceName = "Model_Rock_SavannaThird" },
	Model_Rock_BambooFirst = { Category = "Models", InstanceName = "Model_Rock_BambooFirst" },
	Model_Rock_BambooSecond = { Category = "Models", InstanceName = "Model_Rock_BambooSecond" },
	Model_Rock_BambooThird = { Category = "Models", InstanceName = "Model_Rock_BambooThird" },
	Model_Rock_VolcanoFirst = { Category = "Models", InstanceName = "Model_Rock_VolcanoFirst" },
	Model_Rock_VolcanoSecond = { Category = "Models", InstanceName = "Model_Rock_VolcanoSecond" },
	Model_Rock_VolcanoThird = { Category = "Models", InstanceName = "Model_Rock_VolcanoThird" },
	Model_Rock_RuinsFirst = { Category = "Models", InstanceName = "Model_Rock_RuinsFirst" },
	Model_Rock_RuinsSecond = { Category = "Models", InstanceName = "Model_Rock_RuinsSecond" },
	Model_Rock_RuinsThird = { Category = "Models", InstanceName = "Model_Rock_RuinsThird" },
	Model_RockSplit_Block = { Category = "Models", InstanceName = "Model_RockSplit_Block" },
	Model_RockSplit_Boulder = { Category = "Models", InstanceName = "Model_RockSplit_Boulder" },
	Model_RockSplit_MossyBoulder = { Category = "Models", InstanceName = "Model_RockSplit_MossyBoulder" },
	Model_RockSplit_MossyStoneRock = { Category = "Models", InstanceName = "Model_RockSplit_MossyStoneRock" },
	Model_RockSplit_Sandstone = { Category = "Models", InstanceName = "Model_RockSplit_Sandstone" },
	Model_RockSplit_CanyonBoulder = { Category = "Models", InstanceName = "Model_RockSplit_CanyonBoulder" },
	Model_RockSplit_CactusBoulder = { Category = "Models", InstanceName = "Model_RockSplit_CactusBoulder" },
	Model_RockSplit_FernRock = { Category = "Models", InstanceName = "Model_RockSplit_FernRock" },
	Model_RockSplit_VineBoulder = { Category = "Models", InstanceName = "Model_RockSplit_VineBoulder" },
	Model_RockSplit_TikiBoulder = { Category = "Models", InstanceName = "Model_RockSplit_TikiBoulder" },
	Model_RockSplit_BarnacleRock = { Category = "Models", InstanceName = "Model_RockSplit_BarnacleRock" },
	Model_RockSplit_KelpBoulder = { Category = "Models", InstanceName = "Model_RockSplit_KelpBoulder" },
	Model_RockSplit_ReefBoulder = { Category = "Models", InstanceName = "Model_RockSplit_ReefBoulder" },
	Model_RockSplit_SnowyRock = { Category = "Models", InstanceName = "Model_RockSplit_SnowyRock" },
	Model_RockSplit_DriftBoulder = { Category = "Models", InstanceName = "Model_RockSplit_DriftBoulder" },
	Model_RockSplit_IglooBoulder = { Category = "Models", InstanceName = "Model_RockSplit_IglooBoulder" },
	Model_TrainingBoardSplit = { Category = "Models", InstanceName = "Model_TrainingBoardSplit" },
	Model_TrainingStand_Wood = { Category = "Models", InstanceName = "Model_TrainingStand_Wood" },
	Model_TrainingStand_Brick = { Category = "Models", InstanceName = "Model_TrainingStand_Brick" },
	Model_TrainingStand_Steel = { Category = "Models", InstanceName = "Model_TrainingStand_Steel" },
	Model_TrainingStand_Vault = { Category = "Models", InstanceName = "Model_TrainingStand_Vault" },
	Model_TrainingStand_Core = { Category = "Models", InstanceName = "Model_TrainingStand_Core" },
	Model_TrainingStand_Cosmic = { Category = "Models", InstanceName = "Model_TrainingStand_Cosmic" },
	Model_TrainingSplit_Brick = { Category = "Models", InstanceName = "Model_TrainingSplit_Brick" },
	Model_TrainingSplit_Steel = { Category = "Models", InstanceName = "Model_TrainingSplit_Steel" },
	Model_TrainingSplit_Vault = { Category = "Models", InstanceName = "Model_TrainingSplit_Vault" },
	Model_TrainingSplit_Core = { Category = "Models", InstanceName = "Model_TrainingSplit_Core" },
	Model_TrainingSplit_Cosmic = { Category = "Models", InstanceName = "Model_TrainingSplit_Cosmic" },
	Model_Geode_Basic = { Category = "Models", InstanceName = "Model_Geode_Basic" },
	Model_GeodeSplit_Basic = { Category = "Models", InstanceName = "Model_GeodeSplit_Basic" },
	Model_Geode_Desert = { Category = "Models", InstanceName = "Model_Geode_Desert" },
	Model_GeodeSplit_Desert = { Category = "Models", InstanceName = "Model_GeodeSplit_Desert" },
	Model_Geode_Jungle = { Category = "Models", InstanceName = "Model_Geode_Jungle" },
	Model_GeodeSplit_Jungle = { Category = "Models", InstanceName = "Model_GeodeSplit_Jungle" },
	Model_Geode_Ocean = { Category = "Models", InstanceName = "Model_Geode_Ocean" },
	Model_GeodeSplit_Ocean = { Category = "Models", InstanceName = "Model_GeodeSplit_Ocean" },
	Model_Geode_Snow = { Category = "Models", InstanceName = "Model_Geode_Snow" },
	Model_GeodeSplit_Snow = { Category = "Models", InstanceName = "Model_GeodeSplit_Snow" },
	Model_GeodeStand = { Category = "Models", InstanceName = "Model_GeodeStand" },
	Model_BasePlot = { Category = "Models", InstanceName = "Model_BasePlot" },
	Model_BasePedestal = { Category = "Models", InstanceName = "Model_BasePedestal" },
	Model_RockPreview_Basic = { Category = "Models", InstanceName = "Model_RockPreview_Basic" },
	Model_RockPreview_Second = { Category = "Models", InstanceName = "Model_RockPreview_Second" },
	Model_RockPreview_Third = { Category = "Models", InstanceName = "Model_RockPreview_Third" },
	Model_RockPreview_DesertFirst = { Category = "Models", InstanceName = "Model_RockPreview_DesertFirst" },
	Model_RockPreview_DesertSecond = { Category = "Models", InstanceName = "Model_RockPreview_DesertSecond" },
	Model_RockPreview_DesertThird = { Category = "Models", InstanceName = "Model_RockPreview_DesertThird" },
	Model_RockPreview_JungleFirst = { Category = "Models", InstanceName = "Model_RockPreview_JungleFirst" },
	Model_RockPreview_JungleSecond = { Category = "Models", InstanceName = "Model_RockPreview_JungleSecond" },
	Model_RockPreview_JungleThird = { Category = "Models", InstanceName = "Model_RockPreview_JungleThird" },
	Model_RockPreview_OceanFirst = { Category = "Models", InstanceName = "Model_RockPreview_OceanFirst" },
	Model_RockPreview_OceanSecond = { Category = "Models", InstanceName = "Model_RockPreview_OceanSecond" },
	Model_RockPreview_OceanThird = { Category = "Models", InstanceName = "Model_RockPreview_OceanThird" },
	Model_RockPreview_SnowFirst = { Category = "Models", InstanceName = "Model_RockPreview_SnowFirst" },
	Model_RockPreview_SnowSecond = { Category = "Models", InstanceName = "Model_RockPreview_SnowSecond" },
	Model_RockPreview_SnowThird = { Category = "Models", InstanceName = "Model_RockPreview_SnowThird" },
	Model_RockPreview_SwampFirst = { Category = "Models", InstanceName = "Model_RockPreview_SwampFirst" },
	Model_RockPreview_SwampSecond = { Category = "Models", InstanceName = "Model_RockPreview_SwampSecond" },
	Model_RockPreview_SwampThird = { Category = "Models", InstanceName = "Model_RockPreview_SwampThird" },
	Model_RockPreview_SavannaFirst = { Category = "Models", InstanceName = "Model_RockPreview_SavannaFirst" },
	Model_RockPreview_SavannaSecond = {
		Category = "Models",
		InstanceName = "Model_RockPreview_SavannaSecond",
	},
	Model_RockPreview_SavannaThird = { Category = "Models", InstanceName = "Model_RockPreview_SavannaThird" },
	Model_RockPreview_BambooFirst = { Category = "Models", InstanceName = "Model_RockPreview_BambooFirst" },
	Model_RockPreview_BambooSecond = { Category = "Models", InstanceName = "Model_RockPreview_BambooSecond" },
	Model_RockPreview_BambooThird = { Category = "Models", InstanceName = "Model_RockPreview_BambooThird" },
	Model_RockPreview_VolcanoFirst = { Category = "Models", InstanceName = "Model_RockPreview_VolcanoFirst" },
	Model_RockPreview_VolcanoSecond = {
		Category = "Models",
		InstanceName = "Model_RockPreview_VolcanoSecond",
	},
	Model_RockPreview_VolcanoThird = { Category = "Models", InstanceName = "Model_RockPreview_VolcanoThird" },
	Model_RockPreview_RuinsFirst = { Category = "Models", InstanceName = "Model_RockPreview_RuinsFirst" },
	Model_RockPreview_RuinsSecond = { Category = "Models", InstanceName = "Model_RockPreview_RuinsSecond" },
	Model_RockPreview_RuinsThird = { Category = "Models", InstanceName = "Model_RockPreview_RuinsThird" },
	Model_Pet_Bloky = { Category = "Models", InstanceName = "Model_Pet_Bloky" },
	Model_Pet_Sprout = { Category = "Models", InstanceName = "Model_Pet_Sprout" },
	Model_Pet_Shroomy = { Category = "Models", InstanceName = "Model_Pet_Shroomy" },
	Model_Pet_Nesty = { Category = "Models", InstanceName = "Model_Pet_Nesty" },
	Model_Pet_Berry = { Category = "Models", InstanceName = "Model_Pet_Berry" },
	Model_Pet_Treebo = { Category = "Models", InstanceName = "Model_Pet_Treebo" },
	Model_Pet_Pointy = { Category = "Models", InstanceName = "Model_Pet_Pointy" },
	Model_Pet_Spike = { Category = "Models", InstanceName = "Model_Pet_Spike" },
	Model_Pet_Howdy = { Category = "Models", InstanceName = "Model_Pet_Howdy" },
	Model_Pet_Flowy = { Category = "Models", InstanceName = "Model_Pet_Flowy" },
	Model_Pet_Ankhy = { Category = "Models", InstanceName = "Model_Pet_Ankhy" },
	Model_Pet_Sunny = { Category = "Models", InstanceName = "Model_Pet_Sunny" },
	Model_Pet_Roly = { Category = "Models", InstanceName = "Model_Pet_Roly" },
	Model_Pet_Leafy = { Category = "Models", InstanceName = "Model_Pet_Leafy" },
	Model_Pet_Viney = { Category = "Models", InstanceName = "Model_Pet_Viney" },
	Model_Pet_Coco = { Category = "Models", InstanceName = "Model_Pet_Coco" },
	Model_Pet_Tiki = { Category = "Models", InstanceName = "Model_Pet_Tiki" },
	Model_Pet_Bloomy = { Category = "Models", InstanceName = "Model_Pet_Bloomy" },
	Model_Pet_Drip = { Category = "Models", InstanceName = "Model_Pet_Drip" },
	Model_Pet_Bubbly = { Category = "Models", InstanceName = "Model_Pet_Bubbly" },
	Model_Pet_Shelly = { Category = "Models", InstanceName = "Model_Pet_Shelly" },
	Model_Pet_Reefy = { Category = "Models", InstanceName = "Model_Pet_Reefy" },
	Model_Pet_Glowy = { Category = "Models", InstanceName = "Model_Pet_Glowy" },
	Model_Pet_Chompy = { Category = "Models", InstanceName = "Model_Pet_Chompy" },
	Model_Pet_Hexy = { Category = "Models", InstanceName = "Model_Pet_Hexy" },
	Model_Pet_Beanie = { Category = "Models", InstanceName = "Model_Pet_Beanie" },
	Model_Pet_Cozy = { Category = "Models", InstanceName = "Model_Pet_Cozy" },
	Model_Pet_Stacky = { Category = "Models", InstanceName = "Model_Pet_Stacky" },
	Model_Pet_Climby = { Category = "Models", InstanceName = "Model_Pet_Climby" },
	Model_Pet_Starry = { Category = "Models", InstanceName = "Model_Pet_Starry" },
	Model_Pet_Champ = { Category = "Models", InstanceName = "Model_Pet_Champ" },
	Model_Pet_Kingy = { Category = "Models", InstanceName = "Model_Pet_Kingy" },
	SFX_Hatch_Step = { Category = "Sounds", InstanceName = "SFX_Hatch_Step" },
	SFX_Hatch_Common = { Category = "Sounds", InstanceName = "SFX_Hatch_Common" },
	SFX_Hatch_Uncommon = { Category = "Sounds", InstanceName = "SFX_Hatch_Uncommon" },
	SFX_Hatch_Rare = { Category = "Sounds", InstanceName = "SFX_Hatch_Rare" },
	SFX_Hatch_Epic = { Category = "Sounds", InstanceName = "SFX_Hatch_Epic" },
	SFX_Hatch_Legendary = { Category = "Sounds", InstanceName = "SFX_Hatch_Legendary" },
	SFX_Hatch_Secret = { Category = "Sounds", InstanceName = "SFX_Hatch_Secret" },
	VFX_Hatch_Burst = { Category = "VFX", InstanceName = "VFX_Hatch_Burst" },
	VFX_Chop_Hit = { Category = "VFX", InstanceName = "VFX_Chop_Hit" },
	VFX_Chop_Crack = { Category = "VFX", InstanceName = "VFX_Chop_Crack" },
	VFX_Chop_Break = { Category = "VFX", InstanceName = "VFX_Chop_Break" },
	VFX_Perfect_Burst = { Category = "VFX", InstanceName = "VFX_Perfect_Burst" },
	VFX_Master_WindUp = { Category = "VFX", InstanceName = "VFX_Master_WindUp" },
	VFX_Cash_Pop = { Category = "VFX", InstanceName = "VFX_Cash_Pop" },
	VFX_HotStreak = { Category = "VFX", InstanceName = "VFX_HotStreak" },
	UI_CashPopText = { Category = "VFX", InstanceName = "CashPopText" },
	UI_RushCountdown = { Category = "VFX", InstanceName = "RushCountdown" },
	VFX_Rush_Glow = { Category = "VFX", InstanceName = "VFX_Rush_Glow" },
	VFX_Rush_Pillar = { Category = "VFX", InstanceName = "VFX_Rush_Pillar" },
	VFX_Rush_Burst = { Category = "VFX", InstanceName = "VFX_Rush_Burst" },
	SFX_Rush_Chime = { Category = "Sounds", InstanceName = "SFX_Rush_Chime" },
	SFX_Rush_Tick = { Category = "Sounds", InstanceName = "SFX_Rush_Tick" },
	Model_Rock_Diamond = { Category = "Models", InstanceName = "Model_Rock_Diamond" },
	Model_LeaderboardCrown = { Category = "Models", InstanceName = "Model_LeaderboardCrown" },
	Model_RockSplit_DiamondRock = { Category = "Models", InstanceName = "Model_RockSplit_DiamondRock" },
	UI_DiamondLabel = { Category = "VFX", InstanceName = "DiamondLabel" },
	VFX_Diamond_Glow = { Category = "VFX", InstanceName = "VFX_Diamond_Glow" },
	VFX_Diamond_Ring = { Category = "VFX", InstanceName = "VFX_Diamond_Ring" },
	VFX_Diamond_Shards = { Category = "VFX", InstanceName = "VFX_Diamond_Shards" },
	VFX_Diamond_Burst = { Category = "VFX", InstanceName = "VFX_Diamond_Burst" },
	SFX_Diamond_Appear = { Category = "Sounds", InstanceName = "SFX_Diamond_Appear" },
	SFX_Diamond_Hit = { Category = "Sounds", InstanceName = "SFX_Diamond_Hit" },
	SFX_Diamond_Shimmer = { Category = "Sounds", InstanceName = "SFX_Diamond_Shimmer" },
	SFX_Diamond_Beacon = { Category = "Sounds", InstanceName = "SFX_Diamond_Beacon" },
	SFX_Diamond_Shatter = { Category = "Sounds", InstanceName = "SFX_Diamond_Shatter" },
	SFX_Diamond_Tick = { Category = "Sounds", InstanceName = "SFX_Diamond_Tick" },
	SFX_Diamond_Despawn = { Category = "Sounds", InstanceName = "SFX_Diamond_Despawn" },
	SFX_Diamond_Payout = { Category = "Sounds", InstanceName = "SFX_Diamond_Payout" },
	VFX_Weather_Sandstorm = { Category = "VFX", InstanceName = "VFX_Weather_Sandstorm" },
	SFX_Weather_Sandstorm = { Category = "Sounds", InstanceName = "SFX_Weather_Sandstorm" },
	VFX_Weather_Hurricane = { Category = "VFX", InstanceName = "VFX_Weather_Hurricane" },
	SFX_Weather_Hurricane = { Category = "Sounds", InstanceName = "SFX_Weather_Hurricane" },
	VFX_Weather_HeatWave = { Category = "VFX", InstanceName = "VFX_Weather_HeatWave" },
	SFX_Weather_HeatWave = { Category = "Sounds", InstanceName = "SFX_Weather_HeatWave" },
	VFX_Weather_Thunderstorm = { Category = "VFX", InstanceName = "VFX_Weather_Thunderstorm" },
	SFX_Weather_Thunderstorm = { Category = "Sounds", InstanceName = "SFX_Weather_Thunderstorm" },
	VFX_Weather_Eclipse = { Category = "VFX", InstanceName = "VFX_Weather_Eclipse" },
	Sky_Eclipse = { Category = "VFX", InstanceName = "Sky_Eclipse" },
	SFX_Weather_Eclipse = { Category = "Sounds", InstanceName = "SFX_Weather_Eclipse" },
	VFX_Modifier_Dusty = { Category = "VFX", InstanceName = "VFX_Modifier_Dusty" },
	VFX_Catch_Dusty = { Category = "VFX", InstanceName = "VFX_Catch_Dusty" },
	VFX_Modifier_Windy = { Category = "VFX", InstanceName = "VFX_Modifier_Windy" },
	VFX_Catch_Windy = { Category = "VFX", InstanceName = "VFX_Catch_Windy" },
	VFX_Modifier_Toasty = { Category = "VFX", InstanceName = "VFX_Modifier_Toasty" },
	VFX_Catch_Toasty = { Category = "VFX", InstanceName = "VFX_Catch_Toasty" },
	VFX_Modifier_Zappy = { Category = "VFX", InstanceName = "VFX_Modifier_Zappy" },
	VFX_Pet_GoldAura = { Category = "VFX", InstanceName = "VFX_Pet_GoldAura" },
	VFX_Catch_Zappy = { Category = "VFX", InstanceName = "VFX_Catch_Zappy" },
	VFX_Modifier_Eclipsed = { Category = "VFX", InstanceName = "VFX_Modifier_Eclipsed" },
	VFX_Catch_Eclipsed = { Category = "VFX", InstanceName = "VFX_Catch_Eclipsed" },
	VFX_Weather_Lightning = { Category = "VFX", InstanceName = "VFX_Weather_Lightning" },
	SFX_Weather_Thunder = { Category = "Sounds", InstanceName = "SFX_Weather_Thunder" },
	SFX_Weather_Start = { Category = "Sounds", InstanceName = "SFX_Weather_Start" },
	SFX_HotStreak_Loop = { Category = "Sounds", InstanceName = "SFX_HotStreak_Loop" },
	SFX_HotStreak_Up = { Category = "Sounds", InstanceName = "SFX_HotStreak_Up" },
	VFX_Aura = { Category = "VFX", InstanceName = "VFX_Aura" },
	Anim_Chop_WindUp = { Category = "Animations", InstanceName = "Anim_Chop_WindUp" },
	Anim_Chop_Strike = { Category = "Animations", InstanceName = "Anim_Chop_Strike" },
	Anim_Intro_Player_Drive = { Category = "Animations", InstanceName = "Anim_Intro_Player_Drive" },
	Anim_Intro_Player_LookUp = { Category = "Animations", InstanceName = "Anim_Intro_Player_LookUp" },
	Anim_Intro_Player_BoingOut = { Category = "Animations", InstanceName = "Anim_Intro_Player_BoingOut" },
	Anim_Intro_Player_Dazed = { Category = "Animations", InstanceName = "Anim_Intro_Player_Dazed" },
	Anim_Intro_Player_Awe = { Category = "Animations", InstanceName = "Anim_Intro_Player_Awe" },
	Anim_Intro_Master_Idle = { Category = "Animations", InstanceName = "Anim_Intro_Master_Idle" },
	Anim_Intro_Master_Leap = { Category = "Animations", InstanceName = "Anim_Intro_Master_Leap" },
	Anim_Intro_Master_Chop = { Category = "Animations", InstanceName = "Anim_Intro_Master_Chop" },
	Anim_Intro_Master_Point = { Category = "Animations", InstanceName = "Anim_Intro_Master_Point" },
	SFX_Intro_Teleport = { Category = "Sounds", InstanceName = "SFX_Intro_Teleport" },
	SFX_Intro_GoTrain = { Category = "Sounds", InstanceName = "SFX_Intro_GoTrain" },
	SFX_Intro_Dizzy = { Category = "Sounds", InstanceName = "SFX_Intro_Dizzy" },
	SFX_Intro_CarDrive = { Category = "Sounds", InstanceName = "SFX_Intro_CarDrive" },
	SFX_Intro_Honk = { Category = "Sounds", InstanceName = "SFX_Intro_Honk" },
	SFX_Intro_RockRoll = { Category = "Sounds", InstanceName = "SFX_Intro_RockRoll" },
	SFX_Intro_FallWhistle = { Category = "Sounds", InstanceName = "SFX_Intro_FallWhistle" },
	SFX_Intro_Boing = { Category = "Sounds", InstanceName = "SFX_Intro_Boing" },
	SFX_Intro_Gulp = { Category = "Sounds", InstanceName = "SFX_Intro_Gulp" },
	SFX_Intro_SlideUp = { Category = "Sounds", InstanceName = "SFX_Intro_SlideUp" },
	MUS_Intro_Drive = { Category = "Sounds", InstanceName = "MUS_Intro_Drive" },
	MUS_Intro_Suspense = { Category = "Sounds", InstanceName = "MUS_Intro_Suspense" },
	MUS_Intro_Dizzy = { Category = "Sounds", InstanceName = "MUS_Intro_Dizzy" },
	MUS_Intro_Master = { Category = "Sounds", InstanceName = "MUS_Intro_Master" },
	MUS_Intro_Kabuki = { Category = "Sounds", InstanceName = "MUS_Intro_Kabuki" },
	MUS_Intro_Victory = { Category = "Sounds", InstanceName = "MUS_Intro_Victory" },
	Model_IntroSet = { Category = "Models", InstanceName = "IntroSet" },
	Model_IntroMaster = { Category = "Models", InstanceName = "IntroMaster" },
	Model_IntroStar = { Category = "Models", InstanceName = "IntroStar" },
}

local soundGroupName = "SoundEffects"

local warned: { [string]: true } = {}

local function warnOnce(key: string, message: string)
	if warned[key] then
		return
	end
	warned[key] = true
	warn(message)
end

local function makePlaceholder(key: string, category: AssetCategory?): Instance
	if category == "Sounds" then
		local sound = Instance.new("Sound")
		sound.Name = key
		return sound
	elseif category == "Animations" then
		local animation = Instance.new("Animation")
		animation.Name = key
		return animation
	elseif category == "Images" then
		local decal = Instance.new("Decal")
		decal.Name = key
		return decal
	elseif category == "VFX" then
		local attachment = Instance.new("Attachment")
		attachment.Name = key
		return attachment
	end
	local part = Instance.new("Part")
	part.Name = key
	part.Size = Vector3.new(2, 2, 2)
	part.Anchored = true
	return part
end

local function joinSoundGroup(asset: Instance): Instance
	if asset:IsA("Sound") then
		local group = SoundService:FindFirstChild(soundGroupName)
		if group and group:IsA("SoundGroup") then
			asset.SoundGroup = group
		end
	end
	return asset
end

local AssetRegistry = {}

function AssetRegistry.get(key: string): Instance
	local entry = map[key]
	if not entry then
		warnOnce(key, `[AssetRegistry] Unregistered asset key "{key}" — returning placeholder Part.`)
		return makePlaceholder(key, nil)
	end

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if assets then
		local category = assets:FindFirstChild(entry.Category)
		if category then
			local asset = category:FindFirstChild(entry.InstanceName, true)
			if asset then
				return joinSoundGroup(asset:Clone())
			end
		end
	end

	warnOnce(
		key,
		`[AssetRegistry] Missing asset "Assets/{entry.Category}/{entry.InstanceName}" for key "{key}" — returning placeholder.`
	)
	return makePlaceholder(key, entry.Category)
end

return AssetRegistry
