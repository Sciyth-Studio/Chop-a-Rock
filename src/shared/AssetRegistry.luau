--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
	SFX_Rock_Break = { Category = "Sounds", InstanceName = "SFX_Rock_Break" },
	SFX_Rock_Crack = { Category = "Sounds", InstanceName = "SFX_Rock_Crack" },
	SFX_Money_Gain = { Category = "Sounds", InstanceName = "SFX_Money_Gain" },
	SFX_Train_Chop = { Category = "Sounds", InstanceName = "SFX_Train_Chop" },
	SFX_Notification = { Category = "Sounds", InstanceName = "SFX_Notification" },
	UI_RockLabel = { Category = "VFX", InstanceName = "RockLabel" },
	UI_ChopPrompt = { Category = "VFX", InstanceName = "ChopPrompt" },
	Image_GuideArrow = { Category = "Images", InstanceName = "GuideArrow" },
	Model_RockSplit_Block = { Category = "Models", InstanceName = "Model_RockSplit_Block" },
	Model_RockSplit_Boulder = { Category = "Models", InstanceName = "Model_RockSplit_Boulder" },
	Model_RockSplit_MossyBoulder = { Category = "Models", InstanceName = "Model_RockSplit_MossyBoulder" },
}

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
				return asset:Clone()
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
