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
	VFX_LevelUp = { Category = "VFX", InstanceName = "VFX_LevelUp" },
	SFX_Level_Up = { Category = "Sounds", InstanceName = "SFX_Level_Up" },
	SFX_Rock_Break = { Category = "Sounds", InstanceName = "SFX_Rock_Break" },
	SFX_Rock_Crack = { Category = "Sounds", InstanceName = "SFX_Rock_Crack" },
	SFX_Money_Gain = { Category = "Sounds", InstanceName = "SFX_Money_Gain" },
	SFX_Train_Chop = { Category = "Sounds", InstanceName = "SFX_Train_Chop" },
	SFX_Notification = { Category = "Sounds", InstanceName = "SFX_Notification" },
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
	Model_RockSplit_Block = { Category = "Models", InstanceName = "Model_RockSplit_Block" },
	Model_RockSplit_Boulder = { Category = "Models", InstanceName = "Model_RockSplit_Boulder" },
	Model_RockSplit_MossyBoulder = { Category = "Models", InstanceName = "Model_RockSplit_MossyBoulder" },
	Model_TrainingBoardSplit = { Category = "Models", InstanceName = "Model_TrainingBoardSplit" },
	Model_ArmPreview = { Category = "Models", InstanceName = "Model_ArmPreview" },
	Model_Geode_Basic = { Category = "Models", InstanceName = "Model_Geode_Basic" },
	Model_GeodeSplit_Basic = { Category = "Models", InstanceName = "Model_GeodeSplit_Basic" },
	Model_GeodeStand = { Category = "Models", InstanceName = "Model_GeodeStand" },
	Model_BasePlot = { Category = "Models", InstanceName = "Model_BasePlot" },
	Model_BasePedestal = { Category = "Models", InstanceName = "Model_BasePedestal" },
	Model_RockPreview_Basic = { Category = "Models", InstanceName = "Model_RockPreview_Basic" },
	Model_RockPreview_Second = { Category = "Models", InstanceName = "Model_RockPreview_Second" },
	Model_RockPreview_Third = { Category = "Models", InstanceName = "Model_RockPreview_Third" },
	Model_RockPreview_DesertFirst = { Category = "Models", InstanceName = "Model_RockPreview_DesertFirst" },
	Model_RockPreview_DesertSecond = { Category = "Models", InstanceName = "Model_RockPreview_DesertSecond" },
	Model_RockPreview_DesertThird = { Category = "Models", InstanceName = "Model_RockPreview_DesertThird" },
	Model_Rok_Bloky = { Category = "Models", InstanceName = "Model_Rok_Bloky" },
	Model_Rok_Sprout = { Category = "Models", InstanceName = "Model_Rok_Sprout" },
	Model_Rok_Shroomy = { Category = "Models", InstanceName = "Model_Rok_Shroomy" },
	Model_Rok_Nesty = { Category = "Models", InstanceName = "Model_Rok_Nesty" },
	Model_Rok_Berry = { Category = "Models", InstanceName = "Model_Rok_Berry" },
	Model_Rok_Treebo = { Category = "Models", InstanceName = "Model_Rok_Treebo" },
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
	SFX_HotStreak_Loop = { Category = "Sounds", InstanceName = "SFX_HotStreak_Loop" },
	SFX_HotStreak_Up = { Category = "Sounds", InstanceName = "SFX_HotStreak_Up" },
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
			local asset = category:FindFirstChild(entry.InstanceName)
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
