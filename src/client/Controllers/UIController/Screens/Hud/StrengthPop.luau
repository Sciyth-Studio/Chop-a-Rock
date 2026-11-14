--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HudConfig = require(ReplicatedStorage.Config.HudConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local NumberFormat = require(ReplicatedStorage.Utils.NumberFormat)
local Typography = require(ReplicatedStorage.Utils.Typography)

export type State = {
	Gui: ScreenGui,
	Label: TextLabel,
	Icon: ImageLabel?,
	IconSize: UDim2?,
	TextTemplate: TextLabel?,
	ScaleOf: () -> number,
	TextWidth: (TextLabel) -> number,
}

local StrengthPop = {}

local function findIcon(label: TextLabel): ImageLabel?
	local row = label.Parent
	if not row then
		return nil
	end
	local named = row:FindFirstChild(HudConfig.StrengthPop.IconName)
	if named and named:IsA("ImageLabel") then
		return named
	end
	for _, child in row:GetChildren() do
		if child:IsA("ImageLabel") and not string.find(child.Name, HudConfig.ShadowSuffix, 1, true) then
			return child
		end
	end
	return nil
end

function StrengthPop.new(
	gui: ScreenGui,
	label: TextLabel,
	textTemplate: TextLabel?,
	scaleOf: () -> number,
	textWidth: (TextLabel) -> number
): State
	local icon = findIcon(label)
	if not icon then
		warn(`[Hud] No strength icon next to {label:GetFullName()}; strength pops show text only`)
	end
	return {
		Gui = gui,
		Label = label,
		Icon = icon,
		IconSize = if icon then icon.Size else nil,
		TextTemplate = textTemplate,
		ScaleOf = scaleOf,
		TextWidth = textWidth,
	}
end

local function characterPoint(state: State): Vector2?
	local character = Players.LocalPlayer.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local camera = workspace.CurrentCamera
	if not root or not root:IsA("BasePart") or not camera then
		return nil
	end
	local world = root.Position + Vector3.yAxis * HudConfig.StrengthPop.OriginHeightStuds
	local point: Vector3, isOnScreen: boolean
	if state.Gui.IgnoreGuiInset then
		point, isOnScreen = camera:WorldToViewportPoint(world)
	else
		point, isOnScreen = camera:WorldToScreenPoint(world)
	end
	if not isOnScreen then
		return nil
	end
	return Vector2.new(point.X, point.Y)
end

local function bumpIcon(state: State)
	local icon = state.Icon
	local size = state.IconSize
	if not icon or not size or not icon.Parent then
		return
	end
	local settings = HudConfig.StrengthPop
	LocalSound.Play(settings.PopSound)
	local grown = UDim2.new(
		size.X.Scale * settings.BumpScale,
		size.X.Offset * settings.BumpScale,
		size.Y.Scale * settings.BumpScale,
		size.Y.Offset * settings.BumpScale
	)
	icon.Size = grown
	TweenService:Create(
		icon,
		TweenInfo.new(settings.BumpSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = size }
	):Play()
end

local function flyIcon(state: State, from: Vector2, delaySeconds: number)
	local icon = state.Icon
	if not icon then
		return
	end
	local settings = HudConfig.StrengthPop
	local scale = state.ScaleOf()
	local size = settings.IconSizePixels * scale
	local flyer = Instance.new("Frame")
	flyer.Name = "StrengthPopIcon"
	flyer.BackgroundTransparency = 1
	flyer.AnchorPoint = Vector2.new(0.5, 0.5)
	flyer.Size = UDim2.fromOffset(size * 0.4, size * 0.4)
	flyer.Position = UDim2.fromOffset(from.X, from.Y)
	local function addImage(name: string, offset: Vector2, color: Color3, zIndex: number)
		local image = Instance.new("ImageLabel")
		image.Name = name
		image.BackgroundTransparency = 1
		image.Image = icon.Image
		image.ImageRectOffset = icon.ImageRectOffset
		image.ImageRectSize = icon.ImageRectSize
		image.ImageColor3 = color
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Size = UDim2.fromScale(1, 1)
		image.Position = UDim2.fromScale(0.5 + offset.X, 0.5 + offset.Y)
		image.ZIndex = zIndex
		image.Parent = flyer
	end
	addImage("Icon", Vector2.zero, icon.ImageColor3, settings.ZIndex + 1)
	flyer.Parent = state.Gui

	local angle = math.random() * 2 * math.pi
	local burst = from
		+ Vector2.new(math.cos(angle), math.sin(angle))
			* settings.BurstPixels
			* scale
			* (0.6 + math.random() * 0.4)
	local burstTween = TweenService:Create(
		flyer,
		TweenInfo.new(settings.BurstSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(burst.X, burst.Y), Size = UDim2.fromOffset(size, size) }
	)
	burstTween.Completed:Once(function()
		task.delay(delaySeconds, function()
			if not flyer.Parent or not icon.Parent then
				flyer:Destroy()
				return
			end
			local target = icon.AbsolutePosition + icon.AbsoluteSize / 2
			local flyTween = TweenService:Create(
				flyer,
				TweenInfo.new(settings.FlySeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					Position = UDim2.fromOffset(target.X, target.Y),
					Size = UDim2.fromOffset(size * 0.6, size * 0.6),
				}
			)
			flyTween.Completed:Once(function()
				flyer:Destroy()
				bumpIcon(state)
			end)
			flyTween:Play()
		end)
	end)
	burstTween:Play()
end

local function showText(state: State, gain: number)
	local template = state.TextTemplate
	if not template then
		return
	end
	local settings = HudConfig.StrengthPop
	local floating = template:Clone()
	floating.Name = "StrengthDelta"
	floating.Text = `+{NumberFormat.Compact(gain)}`
	floating.TextColor3 = Color3.new(1, 1, 1)
	Typography.ApplyTextStyle(floating, settings.TextStyle)
	local startX = state.TextWidth(state.Label) + settings.TextGapPixels
	floating.Position = UDim2.new(0, startX, 0, 0)
	floating.Visible = true
	floating.Parent = state.Label
	local info = TweenInfo.new(settings.TextSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local slide = TweenService:Create(floating, info, {
		Position = UDim2.new(0, startX, 0, -settings.TextRisePixels),
		TextTransparency = 1,
	})
	local stroke = floating:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
	end
	slide.Completed:Once(function()
		floating:Destroy()
	end)
	slide:Play()
end

function StrengthPop.Play(state: State, gain: number)
	if gain <= 0 then
		return
	end
	showText(state, gain)
	local from = characterPoint(state)
	if not from then
		bumpIcon(state)
		return
	end
	local settings = HudConfig.StrengthPop
	for index = 1, settings.IconCount do
		flyIcon(state, from, (index - 1) * settings.StaggerSeconds)
	end
end

return StrengthPop
