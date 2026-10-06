--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Component = require(ReplicatedStorage.Packages.Component)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)

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

local function number(value: any): number
	return if type(value) == "number" then value else 0
end

return function(_controllers: { [string]: any })
	local Pedestal = Component.new({ Tag = PedestalConfig.PedestalTag }) :: any

	function Pedestal.Start(self: Pedestal)
		local pedestal = self.Instance
		local part = pedestal:FindFirstChild(PedestalConfig.PedestalPartName)
		local pad = pedestal:FindFirstChild(PedestalConfig.PadPartName)
		if not part or not part:IsA("BasePart") or not pad or not pad:IsA("BasePart") then
			return
		end
		self.Trove = Trove.new()
		local padGui = billboard(PedestalConfig.PadTemplateKey, pad, PedestalConfig.PadLabelHeightStuds)
		local infoGui = billboard(PedestalConfig.InfoTemplateKey, part, PedestalConfig.InfoHeightStuds)
		if not padGui or not infoGui then
			warn(
				`[Pedestal] Missing {PedestalConfig.PadTemplateKey} or {PedestalConfig.InfoTemplateKey} BillboardGui`
			)
			return
		end
		self.Trove:Add(padGui)
		self.Trove:Add(infoGui)
		local amount = findLabel(padGui, "Amount")
		local title = findLabel(infoGui, "Title")
		local detail = findLabel(infoGui, "Detail")

		local function refreshInfo()
			local isOwned = pedestal:GetAttribute("OwnerUserId") ~= nil
			local state = pedestal:GetAttribute("State")
			local price = pedestal:GetAttribute("Price")
			local petKey = pedestal:GetAttribute("PetKey")
			local pet = if type(petKey) == "string" then PetConfig.Pets[petKey] else nil
			padGui.Enabled = isOwned and state ~= "Locked"
			infoGui.Enabled = isOwned and (state == "Locked" or pet ~= nil)
			if title then
				title.Text = if state == "Locked" then "Locked" elseif pet then pet.DisplayName else ""
			end
			if detail then
				detail.Text = if state == "Locked"
					then (if type(price) == "number" then `${NumberFormat.Compact(price)}` else "")
					elseif pet then `${NumberFormat.Commas(pet.MoneyPerSecond)}/s`
					else ""
				detail.Visible = detail.Text ~= ""
			end
		end

		local function refreshAmount()
			if not amount or not padGui.Enabled then
				return
			end
			local elapsed =
				math.max(0, workspace:GetServerTimeNow() - number(pedestal:GetAttribute("BankedAt")))
			local value = number(pedestal:GetAttribute("Banked"))
				+ number(pedestal:GetAttribute("Rate")) * elapsed
			amount.Text = `${NumberFormat.Compact(math.floor(value))}`
		end

		for _, name in { "OwnerUserId", "State", "Price", "PetKey" } do
			self.Trove:Connect(pedestal:GetAttributeChangedSignal(name), refreshInfo)
		end
		local elapsed = 0
		self.Trove:Connect(RunService.Heartbeat, function(dt: number)
			elapsed += dt
			if elapsed >= PedestalConfig.DisplayRefreshSeconds then
				elapsed = 0
				refreshAmount()
			end
		end)
		refreshInfo()
		refreshAmount()
	end

	function Pedestal.Stop(self: Pedestal)
		if self.Trove then
			self.Trove:Destroy()
		end
	end

	return Pedestal
end
