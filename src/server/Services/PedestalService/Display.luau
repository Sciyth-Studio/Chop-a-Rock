--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RokAura = require(ServerScriptService.Utils.RokAura)
local RokModifier = require(ReplicatedStorage.RokModifier)
local RokMotionConfig = require(ReplicatedStorage.Config.RokMotionConfig)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)
local Types = require(script.Parent.Types)

local PROMPT_NAME = "PedestalPrompt"
local OWNED_PROMPT_TAG = "OwnedPrompt"

export type SlotView = {
	State: "Locked" | "Empty" | "Placed",
	PetKey: string?,
	Modifier: string?,
	Income: number?,
	Price: number?,
	Earnings: Types.SlotEarnings?,
	CanPlace: boolean,
}

local Display = {}

function Display.Pedestals(plot: Model): { [number]: Model }
	local pedestals: { [number]: Model } = {}
	local folder = plot:FindFirstChild(PedestalConfig.FolderName)
	if not folder then
		return pedestals
	end
	for _, child in folder:GetChildren() do
		local slot = child:GetAttribute("SlotIndex")
		if child:IsA("Model") and type(slot) == "number" then
			pedestals[slot] = child
		end
	end
	return pedestals
end

function Display.PedestalPart(pedestal: Model): BasePart?
	local part = pedestal:FindFirstChild(PedestalConfig.PedestalPartName)
	return if part and part:IsA("BasePart") then part else nil
end

function Display.Pad(pedestal: Model): BasePart?
	local pad = pedestal:FindFirstChild(PedestalConfig.PadPartName)
	return if pad and pad:IsA("BasePart") then pad else nil
end

function Display.EnsurePrompt(pedestal: Model): ProximityPrompt?
	local part = Display.PedestalPart(pedestal)
	if not part then
		warn(`[PedestalService] {pedestal:GetFullName()} has no "{PedestalConfig.PedestalPartName}" part`)
		return nil
	end
	local existing = part:FindFirstChild(PROMPT_NAME)
	if existing and existing:IsA("ProximityPrompt") then
		return existing
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.HoldDuration = PedestalConfig.PromptHoldSeconds
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.MaxActivationDistance = PedestalConfig.PromptRangeStuds
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Active", false)
	CollectionService:AddTag(prompt, OWNED_PROMPT_TAG)
	prompt.Parent = part
	pedestal.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	CollectionService:AddTag(pedestal, PedestalConfig.PedestalTag)
	return prompt
end

local function setModifier(model: Instance, modifier: string?, isCatch: boolean)
	if model:GetAttribute(WeatherConfig.ModifierAttribute) == modifier then
		return
	end
	model:SetAttribute(WeatherConfig.ModifierAttribute, modifier)
	if modifier then
		CollectionService:AddTag(model, WeatherConfig.RokTag)
	else
		CollectionService:RemoveTag(model, WeatherConfig.RokTag)
	end
	if isCatch and modifier then
		model:SetAttribute(WeatherConfig.CaughtAtAttribute, workspace:GetServerTimeNow())
	end
end

local function setRok(pedestal: Model, petKey: string?, modifier: string?, scale: number?)
	local current = pedestal:FindFirstChild(PedestalConfig.DisplayName)
	if current and current:GetAttribute("PetKey") == petKey then
		setModifier(current, modifier, true)
		return
	end
	if current then
		current:Destroy()
	end
	local pet = if petKey then PetConfig.Pets[petKey] else nil
	local part = Display.PedestalPart(pedestal)
	if not pet or not part then
		return
	end
	local asset = AssetRegistry.get(pet.ModelKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	local model = asset :: Model
	model.Name = PedestalConfig.DisplayName
	model:SetAttribute("PetKey", petKey)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	RokAura.Attach(model, petKey :: string, scale or PedestalConfig.RokScale)
	model:ScaleTo(scale or PedestalConfig.RokScale)
	local top = part.CFrame * CFrame.new(0, part.Size.Y / 2, 0)
	model:PivotTo(CFrame.new(top.Position) * pedestal:GetPivot().Rotation)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute(RokMotionConfig.PlacedAtAttribute, workspace:GetServerTimeNow())
	CollectionService:AddTag(model, RokMotionConfig.Tag)
	setModifier(model, modifier, false)
	model.Parent = pedestal
end

function Display.ShowRok(pedestal: Model, petKey: string?, scale: number?)
	setRok(pedestal, petKey, nil, scale)
end

function Display.Render(pedestal: Model, owner: Player, view: SlotView)
	local pet = if view.PetKey then PetConfig.Pets[view.PetKey] else nil
	pedestal:SetAttribute("OwnerUserId", owner.UserId)
	pedestal:SetAttribute("State", view.State)
	pedestal:SetAttribute("PetKey", if pet then view.PetKey else nil)
	pedestal:SetAttribute(WeatherConfig.ModifierAttribute, if pet then view.Modifier else nil)
	pedestal:SetAttribute("Income", if pet then view.Income else nil)
	pedestal:SetAttribute("Price", view.Price)
	local earnings = view.Earnings
	pedestal:SetAttribute("Rate", if earnings then earnings.Rate else 0)
	pedestal:SetAttribute("Banked", if earnings then earnings.Banked else 0)
	pedestal:SetAttribute("BankedAt", if earnings then earnings.BankedAt else 0)
	setRok(pedestal, if pet then view.PetKey else nil, if pet then view.Modifier else nil)

	local prompt = Display.EnsurePrompt(pedestal)
	if not prompt then
		return
	end
	prompt:SetAttribute("OwnerUserId", owner.UserId)
	if view.State == "Locked" then
		prompt.ActionText = "Unlock"
		prompt.ObjectText = if view.Price then `${NumberFormat.Compact(view.Price)}` else ""
		prompt:SetAttribute("Active", view.Price ~= nil)
	elseif view.State == "Placed" then
		prompt.ActionText = "Pick up"
		prompt.ObjectText = if view.PetKey then RokModifier.Name(view.PetKey, view.Modifier) else ""
		prompt:SetAttribute("Active", true)
	else
		prompt.ActionText = "Place"
		prompt.ObjectText = ""
		prompt:SetAttribute("Active", view.CanPlace)
	end
end

function Display.Clear(pedestal: Model)
	for _, name in
		{
			"OwnerUserId",
			"State",
			"PetKey",
			WeatherConfig.ModifierAttribute,
			"Price",
			"Rate",
			"Banked",
			"BankedAt",
		}
	do
		pedestal:SetAttribute(name, nil)
	end
	setRok(pedestal, nil, nil)
	local part = Display.PedestalPart(pedestal)
	local prompt = if part then part:FindFirstChild(PROMPT_NAME) else nil
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt:SetAttribute("OwnerUserId", nil)
		prompt:SetAttribute("Active", false)
	end
end

return Display
