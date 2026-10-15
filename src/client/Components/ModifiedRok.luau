--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Component = require(ReplicatedStorage.Packages.Component)
local RokModifier = require(ReplicatedStorage.RokModifier)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VFXEmit = require(ReplicatedStorage.VFX.Emit) :: any
local WeatherConfig = require(ReplicatedStorage.Config.WeatherConfig)

local CATCH_WINDOW_SECONDS = 3

type ModifiedRok = {
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

local function dress(root: Instance, trove: any, modifier: WeatherConfig.Modifier, key: string)
	local colors: { [BasePart]: Color3 } = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			colors[descendant] = descendant.Color
		end
	end
	RokModifier.Tint(root, key)
	trove:Add(function()
		for part, color in colors do
			part.Color = color
		end
	end)
	local part = mainPart(root)
	if not part then
		return
	end
	local template = AssetRegistry.get(modifier.VFXKey)
	for _, child in template:GetChildren() do
		if child:IsA("ParticleEmitter") then
			local emitter = child:Clone()
			emitter.Name = WeatherConfig.RokVFXName
			emitter.Parent = part
			trove:Add(emitter)
		end
	end
	template:Destroy()
end

return function(_controllers: { [string]: any })
	local ModifiedRok = Component.new({ Tag = WeatherConfig.RokTag }) :: any

	function ModifiedRok.Start(self: ModifiedRok)
		local root = self.Instance
		self.Trove = Trove.new()
		self.LookTrove = self.Trove:Extend()
		local function refresh()
			self.LookTrove:Clean()
			local value = root:GetAttribute(WeatherConfig.ModifierAttribute)
			local key = if type(value) == "string" then value else nil
			local modifier = RokModifier.Get(key)
			if modifier and key then
				dress(root, self.LookTrove, modifier, key)
			end
		end
		local function caught()
			local value = root:GetAttribute(WeatherConfig.CaughtAtAttribute)
			local modifierValue = root:GetAttribute(WeatherConfig.ModifierAttribute)
			local modifier = RokModifier.Get(if type(modifierValue) == "string" then modifierValue else nil)
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

	function ModifiedRok.Stop(self: ModifiedRok)
		if self.Trove then
			self.Trove:Destroy()
		end
	end

	return ModifiedRok
end
