--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local PetAura = require(ServerScriptService.Utils.PetAura)
local PetSize = require(ReplicatedStorage.PetSize)
local PetSizeConfig = require(ReplicatedStorage.Config.PetSizeConfig)
local PetMotionConfig = require(ReplicatedStorage.Config.PetMotionConfig)
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)

export type PenPetView = {
	PetKey: string,
	Modifier: string?,
	Size: string?,
	Income: number?,
}

local Display = {}

local random = Random.new()

local function setModifier(model: Instance, modifier: string?, isCatch: boolean)
	if model:GetAttribute(WeatherConfig.ModifierAttribute) == modifier then
		return
	end
	model:SetAttribute(WeatherConfig.ModifierAttribute, modifier)
	if modifier then
		CollectionService:AddTag(model, WeatherConfig.PetTag)
	else
		CollectionService:RemoveTag(model, WeatherConfig.PetTag)
	end
	if isCatch and modifier then
		model:SetAttribute(WeatherConfig.CaughtAtAttribute, workspace:GetServerTimeNow())
	end
end

local function buildPet(petKey: string, size: string?, scale: number): Model?
	local pet = PetConfig.Pets[petKey]
	if not pet then
		return nil
	end
	local asset = AssetRegistry.get(pet.ModelKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		return nil
	end
	local model = asset :: Model
	model:SetAttribute("PetKey", petKey)
	model:SetAttribute(PetSizeConfig.Attribute, size)
	local petScale = scale * PetSize.Scale(size)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	PetAura.Attach(model, petKey, petScale)
	model:ScaleTo(petScale)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute(PetMotionConfig.PlacedAtAttribute, workspace:GetServerTimeNow())
	CollectionService:AddTag(model, PetMotionConfig.Tag)
	return model
end

function Display.ShowPet(pedestal: Model, petKey: string?, scale: number?)
	local current = pedestal:FindFirstChild(PedestalConfig.DisplayName)
	if current and current:GetAttribute("PetKey") == petKey then
		return
	end
	if current then
		current:Destroy()
	end
	local part = pedestal:FindFirstChild(PedestalConfig.PedestalPartName)
	local model = if petKey then buildPet(petKey, nil, scale or PedestalConfig.PetScale) else nil
	if not model or not part or not part:IsA("BasePart") then
		if model then
			model:Destroy()
		end
		return
	end
	model.Name = PedestalConfig.DisplayName
	local top = part.CFrame * CFrame.new(0, part.Size.Y / 2, 0)
	model:PivotTo(CFrame.new(top.Position) * pedestal:GetPivot().Rotation)
	model.Parent = pedestal
end

function Display.Pen(plot: Model): BasePart?
	local pen = plot:FindFirstChild(PedestalConfig.PenPartName, true)
	return if pen and pen:IsA("BasePart") then pen else nil
end

local function penFolder(plot: Model): Folder
	local folder = plot:FindFirstChild(PedestalConfig.PenFolderName)
	if folder and folder:IsA("Folder") then
		return folder
	end
	local created = Instance.new("Folder")
	created.Name = PedestalConfig.PenFolderName
	created.Parent = plot
	return created
end

function Display.RenderPen(plot: Model, owner: Player, views: { [number]: PenPetView })
	local pen = Display.Pen(plot)
	if not pen then
		return
	end
	local folder = penFolder(plot)
	local halfX = pen.Size.X / 2 - PedestalConfig.PenMarginStuds
	local halfZ = pen.Size.Z / 2 - PedestalConfig.PenMarginStuds
	local top = pen.CFrame * CFrame.new(0, pen.Size.Y / 2, 0)
	for _, slot in PedestalConfig.UnlockOrder do
		local name = `PenPet{slot}`
		local view = views[slot]
		local current = folder:FindFirstChild(name)
		if
			current
			and (
				not view
				or current:GetAttribute("PetKey") ~= view.PetKey
				or current:GetAttribute(PetSizeConfig.Attribute) ~= view.Size
			)
		then
			current:Destroy()
			current = nil
		end
		if view and not current then
			local model = buildPet(view.PetKey, view.Size, PedestalConfig.PetScale)
			if model then
				model.Name = name
				local x, z = random:NextNumber(-halfX, halfX), random:NextNumber(-halfZ, halfZ)
				model:PivotTo(
					top * CFrame.new(x, 0, z) * CFrame.Angles(0, random:NextNumber(0, 2 * math.pi), 0)
				)
				model:SetAttribute(PedestalConfig.HopCenterAttribute, top.Position)
				model:SetAttribute(PedestalConfig.HopHalfSizeAttribute, Vector3.new(halfX, 0, halfZ))
				CollectionService:AddTag(model, PedestalConfig.PenPetTag)
				setModifier(model, view.Modifier, false)
				model.Parent = folder
				current = model
			end
		end
		if view and current then
			current:SetAttribute("OwnerUserId", owner.UserId)
			current:SetAttribute("Income", view.Income)
			setModifier(current, view.Modifier, true)
		end
	end
end

function Display.ClearPen(plot: Model)
	local folder = plot:FindFirstChild(PedestalConfig.PenFolderName)
	if folder then
		folder:ClearAllChildren()
	end
end

return Display
