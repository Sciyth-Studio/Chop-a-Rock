--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Component = require(ReplicatedStorage.Packages.Component)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RokModifier = require(ReplicatedStorage.RokModifier)
local RokSize = require(ReplicatedStorage.RokSize)
local RokSizeConfig = require(ReplicatedStorage.Config.RokSizeConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)

type Pedestal = {
	Instance: Instance,
	Trove: any,
}

local function findLabel(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name, true)
	return if found and found:IsA("TextLabel") then found else nil
end

local function billboard(key: string, adornee: BasePart, height: number): BillboardGui?
	local template = AssetRegistry.get(key)
	if not template:IsA("BillboardGui") then
		template:Destroy()
		return nil
	end
	Typography.Apply(template)
	template.Adornee = adornee
	template.MaxDistance = PedestalConfig.LabelMaxDistance
	template.StudsOffsetWorldSpace = Vector3.new(0, adornee.Size.Y / 2 + height, 0)
	template.Enabled = false
	template.Parent = adornee
	return template
end

local function surface(key: string, adornee: BasePart): SurfaceGui?
	local template = AssetRegistry.get(key)
	if not template:IsA("SurfaceGui") then
		template:Destroy()
		return nil
	end
	Typography.Apply(template)
	template.Adornee = adornee
	template.Face = Enum.NormalId.Top
	template.MaxDistance = PedestalConfig.LabelMaxDistance
	template.Enabled = false
	template.Parent = adornee
	return template
end

local function number(value: any): number
	return if type(value) == "number" then value else 0
end

return function(_controllers: { [string]: any })
	local Pedestal = Component.new({ Tag = PedestalConfig.PedestalTag }) :: any

	function Pedestal.Start(self: Pedestal)
		local pedestal = self.Instance
		self.Trove = Trove.new()
		local mountTrove = self.Trove:Extend()
		local padGui: SurfaceGui?
		local infoGui: BillboardGui?
		local amount: TextLabel?
		local title: TextLabel?
		local detail: TextLabel?
		local modifierLabel: TextLabel?

		local function refreshInfo()
			if not padGui or not infoGui then
				return
			end
			local isOwned = pedestal:GetAttribute("OwnerUserId") ~= nil
			local state = pedestal:GetAttribute("State")
			local price = pedestal:GetAttribute("Price")
			local petKey = pedestal:GetAttribute("PetKey")
			local pet = if type(petKey) == "string" then PetConfig.Pets[petKey] else nil
			padGui.Enabled = isOwned and state ~= "Locked"
			infoGui.Enabled = isOwned and (state == "Locked" or pet ~= nil)
			local modifierValue = pedestal:GetAttribute(WeatherConfig.ModifierAttribute)
			local modifier = if type(modifierValue) == "string" then modifierValue else nil
			local incomeValue = pedestal:GetAttribute("Income")
			local income = if type(incomeValue) == "number" then incomeValue else nil
			local modifierConfig = RokModifier.Get(modifier)
			local sizeValue = pedestal:GetAttribute(RokSizeConfig.Attribute)
			local size = if type(sizeValue) == "string" then sizeValue else nil
			if title then
				title.Text = if state == "Locked"
					then "Locked"
					elseif pet then RokSize.Name(petKey :: string, nil, size)
					else ""
			end
			local part = pedestal:FindFirstChild(PedestalConfig.PedestalPartName)
			if part and part:IsA("BasePart") then
				local lift = (RokSize.Scale(if pet then size else nil) - 1)
					* RokSizeConfig.InfoLiftStudsPerScale
				infoGui.StudsOffsetWorldSpace =
					Vector3.new(0, part.Size.Y / 2 + PedestalConfig.InfoHeightStuds + lift, 0)
			end
			if modifierLabel then
				local isShown = modifierConfig ~= nil and pet ~= nil and state ~= "Locked"
				modifierLabel.Visible = isShown
				if modifierConfig and isShown then
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
			if detail then
				detail.Text = if state == "Locked"
					then (if type(price) == "number" then `${NumberFormat.Compact(price)}` else "")
					elseif pet then `${NumberFormat.Rate(
						RokModifier.Rate(petKey :: string, modifier, income)
					)}/s`
					else ""
				detail.Visible = detail.Text ~= ""
			end
		end

		local shownTicks: number? = nil

		local function currentTicks(): number
			local elapsed =
				math.max(0, workspace:GetServerTimeNow() - number(pedestal:GetAttribute("BankedAt")))
			return math.floor(elapsed / PedestalConfig.IncomeTickSeconds)
		end

		local function refreshAmount()
			if not amount or not padGui or not padGui.Enabled then
				return
			end
			local ticks = currentTicks()
			shownTicks = ticks
			local value = number(pedestal:GetAttribute("Banked"))
				+ number(pedestal:GetAttribute("Rate")) * ticks * PedestalConfig.IncomeTickSeconds
			amount.Text = `${NumberFormat.Compact(math.floor(value))}`
		end

		local function mount()
			mountTrove:Clean()
			padGui, infoGui, amount, title, detail, modifierLabel = nil, nil, nil, nil, nil, nil
			local part = pedestal:FindFirstChild(PedestalConfig.PedestalPartName)
			local pad = pedestal:FindFirstChild(PedestalConfig.PadPartName)
			if not part or not part:IsA("BasePart") or not pad or not pad:IsA("BasePart") then
				return
			end
			local newPadGui = surface(PedestalConfig.PadTemplateKey, pad)
			local newInfoGui = billboard(PedestalConfig.InfoTemplateKey, part, PedestalConfig.InfoHeightStuds)
			if newPadGui then
				mountTrove:Add(newPadGui)
			end
			if newInfoGui then
				mountTrove:Add(newInfoGui)
			end
			if not newPadGui or not newInfoGui then
				warn(
					`[Pedestal] Missing {PedestalConfig.PadTemplateKey} SurfaceGui or {PedestalConfig.InfoTemplateKey} BillboardGui`
				)
				return
			end
			padGui, infoGui = newPadGui, newInfoGui
			amount = findLabel(newPadGui, "Amount")
			title = findLabel(newInfoGui, "Title")
			detail = findLabel(newInfoGui, "Detail")
			modifierLabel = findLabel(newInfoGui, "Modifier")
			refreshInfo()
			refreshAmount()
		end

		local function onChildChanged(child: Instance)
			if child.Name == PedestalConfig.PedestalPartName or child.Name == PedestalConfig.PadPartName then
				mount()
			end
		end

		for _, name in
			{
				"OwnerUserId",
				"State",
				"Price",
				"PetKey",
				"Income",
				WeatherConfig.ModifierAttribute,
				RokSizeConfig.Attribute,
			}
		do
			self.Trove:Connect(pedestal:GetAttributeChangedSignal(name), function()
				refreshInfo()
				refreshAmount()
			end)
		end
		for _, name in { "Banked", "BankedAt", "Rate" } do
			self.Trove:Connect(pedestal:GetAttributeChangedSignal(name), refreshAmount)
		end
		self.Trove:Connect(pedestal.ChildAdded, onChildChanged)
		self.Trove:Connect(pedestal.ChildRemoved, onChildChanged)
		self.Trove:Connect(RunService.Heartbeat, function()
			if amount and padGui and padGui.Enabled and currentTicks() ~= shownTicks then
				refreshAmount()
			end
		end)
		mount()
	end

	function Pedestal.Stop(self: Pedestal)
		if self.Trove then
			self.Trove:Destroy()
		end
	end

	return Pedestal
end
