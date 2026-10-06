--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local HatchOdds = require(ReplicatedStorage.HatchOdds)
local HatchRevealConfig = require(ReplicatedStorage.Config.HatchRevealConfig)
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local PetConfig = require(ReplicatedStorage.Config.PetConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local ViewportScale = require(ReplicatedStorage.Utils.ViewportScale)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local HatchReveal = {}

local function find(root: Instance, name: string, className: string): any
	local found = root:FindFirstChild(name, true)
	if found and found:IsA(className) then
		return found
	end
	warn(`[HatchReveal] Missing {className} "{name}" in {root:GetFullName()}`)
	return nil
end

local function setText(label: TextLabel?, text: string)
	if not label then
		return
	end
	label.Text = text
	local shadow = if label.Parent
		then label.Parent:FindFirstChild(label.Name .. HudConfig.ShadowSuffix)
		else nil
	if shadow and shadow:IsA("TextLabel") then
		shadow.Text = text
	end
end

local function buildPreview(frame: ViewportFrame, modelKey: string)
	for _, child in frame:GetChildren() do
		if child:IsA("Model") or child:IsA("Camera") then
			child:Destroy()
		end
	end
	local asset = AssetRegistry.get(modelKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	local model = asset :: Model
	local camera = Instance.new("Camera")
	camera.FieldOfView = HatchRevealConfig.PreviewFieldOfView
	camera.Parent = frame
	model.Parent = frame
	local center, size = model:GetBoundingBox()
	local distance = size.Magnitude
		/ 2
		/ math.tan(math.rad(camera.FieldOfView / 2))
		* HatchRevealConfig.PreviewPadding
	camera.CFrame =
		CFrame.lookAt(center.Position + HatchRevealConfig.PreviewDirection.Unit * distance, center.Position)
	frame.CurrentCamera = camera
end

function HatchReveal.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	ViewportScale.Bind(gui, trove)
	local screenName = HatchRevealConfig.ScreenName

	local petName: TextLabel? = find(gui, "PetName", "TextLabel")
	local rarityLabel: TextLabel? = find(gui, "RarityLabel", "TextLabel")
	local odds: TextLabel? = find(gui, "Odds", "TextLabel")
	local newBadge: GuiObject? = find(gui, "NewBadge", "GuiObject")
	local rays: GuiObject? = find(gui, "Rays", "GuiObject")
	local preview: ViewportFrame? = find(gui, "Preview", "ViewportFrame")
	local statValue: TextLabel? = find(gui, "StatValue", "TextLabel")
	local trait: TextLabel? = find(gui, "Trait", "TextLabel")
	local continueLabel: TextLabel? = find(gui, "Continue", "TextLabel")
	local dismiss: TextButton? = find(gui, "Dismiss", "TextButton")
	local popScale: UIScale? = find(gui, "PopScale", "UIScale")
	local rarityGradient = if rarityLabel then rarityLabel:FindFirstChildWhichIsA("UIGradient") else nil

	local openTrove = trove:Extend()

	local function show(hatch: any)
		local pet = PetConfig.Pets[hatch.PetKey]
		local rarity = RarityConfig.Rarities[hatch.Rarity]
		if not pet or not rarity then
			return
		end
		setText(petName, pet.DisplayName)
		setText(rarityLabel, rarity.DisplayName)
		if rarityLabel then
			rarityLabel.TextColor3 = if rarity.RainbowLabel then Color3.new(1, 1, 1) else rarity.Color
		end
		if rarityGradient then
			rarityGradient.Enabled = rarity.RainbowLabel
			rarityGradient.Color = RarityConfig.Rainbow
		end
		local chance = 0
		for _, entry in HatchOdds.Chances(hatch.GeodeKey, 1) do
			if entry.PetKey == hatch.PetKey then
				chance = entry.Chance
			end
		end
		setText(odds, NumberFormat.Percent(chance))
		if newBadge then
			newBadge.Visible = hatch.IsNew == true
		end
		setText(statValue, NumberFormat.Multiplier(pet.MoneyMultiplier))
		local traitConfig = if hatch.Trait then PetConfig.Traits[hatch.Trait] else nil
		if trait then
			trait.Visible = traitConfig ~= nil
			setText(trait, if traitConfig then `+ {traitConfig.DisplayName}` else "")
		end
		if rays and rays:IsA("ImageLabel") then
			rays.Image = HatchRevealConfig.RaysImage
			rays.ImageColor3 = Color3.new(1, 1, 1):Lerp(rarity.Color, HatchRevealConfig.RaysTint)
		end
		if preview then
			buildPreview(preview, pet.ModelKey)
		end
		setText(
			continueLabel,
			if UserInputService.TouchEnabled and not UserInputService.MouseEnabled
				then HatchRevealConfig.TapText
				else HatchRevealConfig.ClickText
		)
		context.Open(screenName)
	end

	trove:Add(context.Controllers.HatchController.Revealed:Connect(show))
	if dismiss then
		trove:Add(dismiss.Activated:Connect(function()
			context.Close(screenName)
		end))
	end

	return {
		Modal = false,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			openTrove:Clean()
			local blur = Instance.new("BlurEffect")
			blur.Name = "HatchRevealBlur"
			blur.Size = HatchRevealConfig.BlurSize
			blur.Parent = Lighting
			openTrove:Add(blur)
			if popScale then
				popScale.Scale = HatchRevealConfig.PopInStartScale
				local tween = TweenService:Create(
					popScale,
					TweenInfo.new(
						HatchRevealConfig.PopInSeconds,
						Enum.EasingStyle.Back,
						Enum.EasingDirection.Out
					),
					{ Scale = 1 }
				)
				tween:Play()
				openTrove:Add(tween)
			end
			if rays then
				openTrove:Add(RunService.RenderStepped:Connect(function(dt: number)
					rays.Rotation = (rays.Rotation + HatchRevealConfig.RaysSpinDegreesPerSecond * dt) % 360
				end))
			end
			local uiController = context.Controllers.UIController
			for _, name in HatchRevealConfig.HiddenScreens do
				if uiController:IsOpen(name) then
					context.Close(name)
					openTrove:Add(function()
						context.Open(name)
					end)
				end
			end
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			openTrove:Clean()
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return HatchReveal
