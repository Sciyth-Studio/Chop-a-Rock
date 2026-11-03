--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Component = require(ReplicatedStorage.Packages.Component)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local PetModifier = require(ReplicatedStorage.PetModifier)
local PetSize = require(ReplicatedStorage.PetSize)
local PetSizeConfig = require(ReplicatedStorage.Config.PetSizeConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)

type PenPetInfo = {
	Instance: Instance,
	Trove: any,
}

local function findLabel(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name, true)
	return if found and found:IsA("TextLabel") then found else nil
end

return function(_controllers: { [string]: any })
	local PenPetInfo = Component.new({ Tag = PedestalConfig.PenPetTag }) :: any

	function PenPetInfo.Start(self: PenPetInfo)
		local model = self.Instance
		self.Trove = Trove.new()
		if not model:IsA("Model") then
			return
		end
		local adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
		if not adornee then
			return
		end
		local template = AssetRegistry.get(PedestalConfig.InfoTemplateKey)
		if not template:IsA("BillboardGui") then
			template:Destroy()
			warn(`[PenPetInfo] {PedestalConfig.InfoTemplateKey} is not a BillboardGui`)
			return
		end
		local gui = template :: BillboardGui
		Typography.Apply(gui)
		gui.Adornee = adornee
		gui.MaxDistance = PedestalConfig.LabelMaxDistance
		gui.Parent = adornee
		self.Trove:Add(gui)
		local title = findLabel(gui, "Title")
		local detail = findLabel(gui, "Detail")
		local modifierLabel = findLabel(gui, "Modifier")
		local sizeLabel = findLabel(gui, "Size")
		local sizeTopPosition = if sizeLabel then sizeLabel.Position else nil

		local function refresh()
			local petKey = model:GetAttribute("PetKey")
			local pet = if type(petKey) == "string" then PetConfig.Pets[petKey] else nil
			gui.Enabled = pet ~= nil
			if not pet then
				return
			end
			local modifierValue = model:GetAttribute(WeatherConfig.ModifierAttribute)
			local modifier = if type(modifierValue) == "string" then modifierValue else nil
			local incomeValue = model:GetAttribute("Income")
			local income = if type(incomeValue) == "number" then incomeValue else nil
			local sizeValue = model:GetAttribute(PetSizeConfig.Attribute)
			local size = if type(sizeValue) == "string" then sizeValue else nil
			local modifierConfig = PetModifier.Get(modifier)
			local lift = (PetSize.Scale(size) - 1) * PetSizeConfig.InfoLiftStudsPerScale
			gui.StudsOffsetWorldSpace = Vector3.new(0, PedestalConfig.InfoHeightStuds + lift, 0)
			if title then
				title.Text = pet.DisplayName
			end
			if detail then
				detail.Text = `${NumberFormat.Rate(PetModifier.Rate(petKey :: string, modifier, income))}/s`
				detail.Visible = true
			end
			if sizeLabel then
				local isShown = PetSize.IsShown(size)
				sizeLabel.Visible = isShown
				if isShown then
					local sizeConfig = PetSize.Get(size)
					sizeLabel.Text = sizeConfig.DisplayName
					Typography.ApplyTextStyle(sizeLabel, sizeConfig.TextStyle)
					sizeLabel.Position = if modifierConfig and modifierLabel
						then sizeTopPosition or sizeLabel.Position
						else (if modifierLabel then modifierLabel.Position else sizeLabel.Position)
				end
			end
			if modifierLabel then
				modifierLabel.Visible = modifierConfig ~= nil
				if modifierConfig then
					modifierLabel.Text = modifierConfig.DisplayName
					local gradient = modifierLabel:FindFirstChildWhichIsA("UIGradient")
					if gradient then
						gradient.Color =
							ColorSequence.new(modifierConfig.LabelTop, modifierConfig.LabelBottom)
					end
					local stroke = modifierLabel:FindFirstChildWhichIsA("UIStroke")
					if stroke then
						stroke.Color =
							modifierConfig.LabelBottom:Lerp(Color3.new(0, 0, 0), WeatherConfig.LabelDarkAlpha)
					end
				end
			end
		end

		for _, name in { "PetKey", "Income", WeatherConfig.ModifierAttribute, PetSizeConfig.Attribute } do
			self.Trove:Connect(model:GetAttributeChangedSignal(name), refresh)
		end
		refresh()
	end

	function PenPetInfo.Stop(self: PenPetInfo)
		if self.Trove then
			self.Trove:Destroy()
		end
	end

	return PenPetInfo
end
