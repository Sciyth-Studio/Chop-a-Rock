--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIFeelConfig = require(ReplicatedStorage.Config.UIFeelConfig)

export type PanelPop = {
	Find: (gui: LayerCollector) -> UIScale?,
	Open: (scale: UIScale) -> (),
	Close: (scale: UIScale, onDone: () -> ()) -> (),
	Destroy: () -> (),
}

local PanelPop = {}

local openInfo = TweenInfo.new(UIFeelConfig.PopOpenSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local closeInfo = TweenInfo.new(UIFeelConfig.PopCloseSeconds, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

function PanelPop.new(): PanelPop
	local tweens: { [UIScale]: Tween } = {}

	local function stop(scale: UIScale)
		local running = tweens[scale]
		if running then
			tweens[scale] = nil
			running:Cancel()
		end
	end

	local function play(scale: UIScale, info: TweenInfo, target: number): Tween
		stop(scale)
		local tween = TweenService:Create(scale, info, { Scale = target })
		tweens[scale] = tween
		tween.Completed:Connect(function()
			if tweens[scale] == tween then
				tweens[scale] = nil
			end
		end)
		tween:Play()
		return tween
	end

	local function find(gui: LayerCollector): UIScale?
		local root = gui:FindFirstChild(UIFeelConfig.PopRootName)
		if not root then
			return nil
		end
		local scale = root:FindFirstChild(UIFeelConfig.PopScaleName)
		return if scale and scale:IsA("UIScale") then scale else nil
	end

	local function open(scale: UIScale)
		stop(scale)
		scale.Scale = UIFeelConfig.PopOpenFromScale
		play(scale, openInfo, 1)
	end

	local function close(scale: UIScale, onDone: () -> ())
		local tween = play(scale, closeInfo, UIFeelConfig.PopCloseToScale)
		tween.Completed:Connect(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed then
				onDone()
			end
		end)
	end

	local function destroy()
		for scale in tweens do
			stop(scale)
		end
	end

	return {
		Find = find,
		Open = open,
		Close = close,
		Destroy = destroy,
	}
end

return PanelPop
