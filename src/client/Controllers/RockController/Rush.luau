--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local RushRockConfig = require(ReplicatedStorage.Config.RushRockConfig)
local LocalSound = require(ReplicatedStorage.Utils.LocalSound)
local Typography = require(ReplicatedStorage.Utils.Typography)
local VFXEmit = require(ReplicatedStorage.VFX.Emit) :: any

export type Look = {
	End: (isFading: boolean) -> (),
}

local Rush = {}

local function playModel(key: string, cframe: CFrame)
	local asset = AssetRegistry.get(key)
	if not asset:IsA("Model") then
		asset:Destroy()
		return
	end
	asset:PivotTo(cframe)
	asset.Parent = workspace
	VFXEmit.emit(asset, {
		onDone = function()
			asset:Destroy()
		end,
	})
end

local function baseCFrame(part: BasePart): CFrame
	return CFrame.new(part.Position - Vector3.new(0, part.Size.Y / 2, 0))
end

local function paint(label: TextLabel, main: Color3, light: Color3, dark: Color3)
	local gradient = label:FindFirstChildWhichIsA("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, main),
			ColorSequenceKeypoint.new(0.5, light),
			ColorSequenceKeypoint.new(1, main),
		})
	end
	local stroke = label:FindFirstChildWhichIsA("UIStroke")
	if stroke then
		stroke.Color = dark
	end
end

local function makeCountdown(part: BasePart, endsAt: number): (() -> ())?
	local asset = AssetRegistry.get(RushRockConfig.CountdownKey)
	if not asset:IsA("BillboardGui") then
		asset:Destroy()
		return nil
	end
	local label = asset:FindFirstChild("Label", true)
	if not label or not label:IsA("TextLabel") then
		warn(`[RockController] {RushRockConfig.CountdownKey} needs a TextLabel named "Label"`)
		asset:Destroy()
		return nil
	end
	local shadow = asset:FindFirstChild("LabelShadow", true)
	local shadowLabel = if shadow and shadow:IsA("TextLabel") then shadow else nil
	local scale = label:FindFirstChildWhichIsA("UIScale")
	if not scale then
		local created = Instance.new("UIScale")
		created.Parent = label
		scale = created
	end
	Typography.Apply(asset)
	asset.Adornee = part
	asset.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + RushRockConfig.CountdownHeightAboveRock, 0)
	paint(label, RushRockConfig.TextMain, RushRockConfig.TextLight, RushRockConfig.TextDark)
	asset.Parent = part

	local shown = -1
	local isWarning = false
	local function refresh()
		local remaining = math.max(0, math.ceil(endsAt - os.clock()))
		if remaining == shown then
			return
		end
		shown = remaining
		local text = string.format(RushRockConfig.CountdownText, remaining)
		label.Text = text
		if shadowLabel then
			shadowLabel.Text = text
		end
		if remaining > RushRockConfig.WarningSeconds or remaining <= 0 then
			return
		end
		if not isWarning then
			isWarning = true
			paint(label, RushRockConfig.WarningMain, RushRockConfig.WarningLight, RushRockConfig.WarningDark)
		end
		LocalSound.Play(RushRockConfig.TickSoundKey)
		if scale then
			scale.Scale = RushRockConfig.PulseScale
			TweenService:Create(
				scale,
				TweenInfo.new(RushRockConfig.PulseSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
		end
	end
	refresh()
	local connection = RunService.Heartbeat:Connect(refresh)
	return function()
		connection:Disconnect()
		asset:Destroy()
	end
end

function Rush.Start(part: BasePart, target: CFrame, endsAt: number): Look
	local originalColor = part.Color
	part.Color = RushRockConfig.Color
	part:SetAttribute(RushRockConfig.EndsAtAttribute, endsAt)

	local outline = Instance.new("Highlight")
	outline.Name = "RushOutline"
	outline.FillColor = RushRockConfig.Color
	outline.FillTransparency = 1
	outline.OutlineColor = RushRockConfig.OutlineColor
	outline.OutlineTransparency = 0
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Adornee = part
	outline.Parent = part

	local glow = AssetRegistry.get(RushRockConfig.GlowKey)
	local emitters: { ParticleEmitter } = {}
	for _, descendant in glow:GetDescendants() do
		if descendant:IsA("ParticleEmitter") then
			descendant.Parent = part
			table.insert(emitters, descendant)
		end
	end
	glow:Destroy()

	playModel(RushRockConfig.PillarKey, CFrame.new(target.Position - Vector3.new(0, part.Size.Y / 2, 0)))
	LocalSound.Play(RushRockConfig.ChimeSoundKey)

	local stopCountdown = makeCountdown(part, endsAt)
	local hasEnded = false

	local function finish(isFading: boolean)
		if hasEnded then
			return
		end
		hasEnded = true
		part:SetAttribute(RushRockConfig.EndsAtAttribute, nil)
		if stopCountdown then
			stopCountdown()
		end
		for _, emitter in emitters do
			emitter:Destroy()
		end
		if not isFading or not part.Parent then
			outline:Destroy()
			return
		end
		local info =
			TweenInfo.new(RushRockConfig.FadeSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(part, info, { Color = originalColor }):Play()
		local tween = TweenService:Create(outline, info, { OutlineTransparency = 1 })
		tween.Completed:Once(function()
			outline:Destroy()
		end)
		tween:Play()
		local dust = AssetRegistry.get(RushRockConfig.EndDustKey)
		if dust:IsA("Attachment") then
			local anchor = Instance.new("Attachment")
			anchor.WorldPosition = baseCFrame(part).Position
			anchor.Parent = workspace.Terrain
			dust.Parent = anchor
			for _, descendant in dust:GetDescendants() do
				if descendant:IsA("ParticleEmitter") then
					local count = descendant:GetAttribute("EmitCount")
					descendant:Emit(if type(count) == "number" then count else 12)
				end
			end
			task.delay(3, function()
				anchor:Destroy()
			end)
		else
			dust:Destroy()
		end
	end

	return { End = finish }
end

function Rush.Burst(part: BasePart)
	playModel(RushRockConfig.BurstKey, baseCFrame(part))
end

return Rush
