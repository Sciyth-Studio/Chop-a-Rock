--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local BossBarConfig = require(ReplicatedStorage.Config.BossBarConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)

export type BossHearts = {
	Set: (health: number?) -> (),
	Destroy: () -> (),
}

type Heart = {
	Clip: Frame,
	Full: ImageLabel,
	Broken: ImageLabel?,
	Pop: UIScale?,
	Amount: number,
}

local BossHearts = {}

local function child(root: Instance, name: string, class: string): Instance?
	local found = root:FindFirstChild(name, true)
	return if found and found:IsA(class) then found else nil
end

function BossHearts.new(frame: Frame): BossHearts
	local trove = Trove.new()
	local hearts: { Heart } = {}
	local ordered: { Frame } = {}
	for _, heartFrame in frame:GetChildren() do
		if heartFrame:IsA("Frame") then
			table.insert(ordered, heartFrame)
		end
	end
	table.sort(ordered, function(first: Frame, second: Frame)
		return first.LayoutOrder < second.LayoutOrder
	end)
	for _, heartFrame in ordered do
		local clip = child(heartFrame, "Clip", "Frame") :: Frame?
		local full = child(heartFrame, "Full", "ImageLabel") :: ImageLabel?
		if not clip or not full then
			warn(`[BossHearts] {heartFrame:GetFullName()} needs a Frame "Clip" holding an ImageLabel "Full"`)
			continue
		end
		local broken = child(heartFrame, "Broken", "ImageLabel") :: ImageLabel?
		if broken then
			broken.AnchorPoint = Vector2.new(0.5, 0.5)
			broken.Visible = false
		end
		table.insert(hearts, {
			Clip = clip,
			Full = full,
			Broken = broken,
			Pop = child(heartFrame, "PopScale", "UIScale") :: UIScale?,
			Amount = 1,
		})
	end

	local lastHeart: Heart? = nil

	local function bump(heart: Heart, scale: number, seconds: number)
		local pop = heart.Pop
		if not pop then
			return
		end
		pop.Scale = scale
		TweenService
			:Create(
				pop,
				TweenInfo.new(seconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			)
			:Play()
	end

	local function shatter(heart: Heart)
		local broken = heart.Broken
		if not broken then
			return
		end
		broken.Visible = true
		broken.ImageTransparency = 0
		broken.Size = UDim2.fromScale(1, 1)
		broken.Position = UDim2.fromScale(0.5, 0.5)
		local tween = TweenService:Create(
			broken,
			TweenInfo.new(BossBarConfig.HeartPopSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Size = UDim2.fromScale(BossBarConfig.HeartPopScale, BossBarConfig.HeartPopScale),
				Position = UDim2.new(0.5, 0, 0.5, -BossBarConfig.HeartRisePixels),
				ImageTransparency = 1,
			}
		)
		tween.Completed:Once(function()
			broken.Visible = false
		end)
		tween:Play()
	end

	local function set(health: number?)
		local value = health or 0
		local alive = 0
		for index, heart in hearts do
			local amount = math.clamp(
				(value - (index - 1) * BossBarConfig.HeartHealth) / BossBarConfig.HeartHealth,
				0,
				1
			)
			if health ~= nil and amount ~= heart.Amount then
				if amount <= 0 and heart.Amount > 0 then
					shatter(heart)
				else
					bump(heart, BossBarConfig.HeartHitScale, BossBarConfig.HeartHitSeconds)
				end
			end
			heart.Amount = amount
			heart.Clip.Size = UDim2.fromScale(amount, 1)
			heart.Full.ImageTransparency = 0
			if amount > 0 then
				alive += 1
			end
		end
		local previous = lastHeart
		lastHeart = if alive == 1 then hearts[1] else nil
		if previous and previous ~= lastHeart and previous.Pop then
			previous.Pop.Scale = 1
		end
	end

	trove:Connect(RunService.Heartbeat, function()
		local heart = lastHeart
		if not heart or not frame.Visible then
			return
		end
		local wave = (math.sin(os.clock() * BossBarConfig.LastHeartFlashSpeed) + 1) / 2
		heart.Full.ImageTransparency = wave * BossBarConfig.LastHeartFlashTransparency
		if heart.Pop then
			heart.Pop.Scale = 1 + wave * BossBarConfig.LastHeartPulseScale
		end
	end)

	set(nil)

	return {
		Set = set,
		Destroy = function()
			trove:Destroy()
		end,
	}
end

return BossHearts
