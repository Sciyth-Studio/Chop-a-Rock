--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Component = require(ReplicatedStorage.Packages.Component)
local PetModifier = require(ReplicatedStorage.PetModifier)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFX.Emit) :: any
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)

local CATCH_WINDOW_SECONDS = 3

type ModifiedPet = {
	Instance: Instance,
	Trove: any,
	LookTrove: any,
}

local function mainPart(root: Instance): BasePart?
	if root:IsA("Model") and root.PrimaryPart then
		return root.PrimaryPart
	end
	local handle = root:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		return handle
	end
	return root:FindFirstChildWhichIsA("BasePart", true)
end

local function playCatch(root: Instance, modifier: WeatherConfig.Modifier)
	local part = mainPart(root)
	local asset = AssetRegistry.get(modifier.CatchVFXKey)
	if not part or not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	asset:PivotTo(CFrame.new(part.Position - Vector3.new(0, part.Size.Y / 2, 0)))
	asset.Parent = workspace
	VFXEmit.emit(asset, {
		onDone = function()
			asset:Destroy()
		end,
	})
end

local function scaleEmitter(emitter: ParticleEmitter, factor: number)
	local keypoints = {}
	for _, keypoint in emitter.Size.Keypoints do
		table.insert(
			keypoints,
			NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * factor, keypoint.Envelope * factor)
		)
	end
	emitter.Size = NumberSequence.new(keypoints)
	emitter.Speed = NumberRange.new(emitter.Speed.Min * factor, emitter.Speed.Max * factor)
	emitter.Acceleration *= factor
end

local function dress(root: Instance, trove: any, modifier: WeatherConfig.Modifier, key: string)
	local colors: { [BasePart]: Color3 } = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			colors[descendant] = descendant.Color
		end
	end
	PetModifier.Tint(root, key)
	trove:Add(function()
		for part, color in colors do
			part.Color = color
		end
	end)
	local part = mainPart(root)
	if not part then
		return
	end
	local factor = part.Size.X / WeatherConfig.PetVFXReferenceStuds
	local template = AssetRegistry.get(modifier.VFXKey)
	for _, child in template:GetChildren() do
		if child:IsA("ParticleEmitter") then
			local emitter = child:Clone()
			scaleEmitter(emitter, factor)
			emitter.Name = WeatherConfig.PetVFXName
			emitter.Parent = part
			trove:Add(emitter)
		elseif child:IsA("PointLight") then
			local light = child:Clone()
			light.Range *= factor
			light.Name = WeatherConfig.PetVFXName
			light.Parent = part
			trove:Add(light)
		end
	end
	template:Destroy()
end

return function(_controllers: { [string]: any })
	local ModifiedPet = Component.new({ Tag = WeatherConfig.PetTag }) :: any

	function ModifiedPet.Start(self: ModifiedPet)
		local root = self.Instance
		self.Trove = Trove.new()
		self.LookTrove = self.Trove:Extend()
		local function refresh()
			self.LookTrove:Clean()
			local value = root:GetAttribute(WeatherConfig.ModifierAttribute)
			local key = if type(value) == "string" then value else nil
			local modifier = PetModifier.Get(key)
			if modifier and key then
				dress(root, self.LookTrove, modifier, key)
			end
		end
		local function caught()
			local value = root:GetAttribute(WeatherConfig.CaughtAtAttribute)
			local modifierValue = root:GetAttribute(WeatherConfig.ModifierAttribute)
			local modifier = PetModifier.Get(if type(modifierValue) == "string" then modifierValue else nil)
			if
				type(value) == "number"
				and modifier
				and workspace:GetServerTimeNow() - value < CATCH_WINDOW_SECONDS
			then
				playCatch(root, modifier)
			end
		end
		self.Trove:Connect(root:GetAttributeChangedSignal(WeatherConfig.ModifierAttribute), refresh)
		self.Trove:Connect(root:GetAttributeChangedSignal(WeatherConfig.CaughtAtAttribute), caught)
		refresh()
		caught()
	end

	function ModifiedPet.Stop(self: ModifiedPet)
		if self.Trove then
			self.Trove:Destroy()
		end
	end

	return ModifiedPet
end
