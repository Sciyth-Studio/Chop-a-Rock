--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Component = require(ReplicatedStorage.Packages.Component)
local EggDropConfig = require(ReplicatedStorage.Config.EggDropConfig)
local EggLuck = require(ReplicatedStorage.Utils.EggLuck)
local GeodeConfig = require(ReplicatedStorage.Config.GeodeConfig)
local PedestalConfig = require(ReplicatedStorage.Config.PedestalConfig)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)

type HatchPadInfo = {
	Instance: Instance,
	Trove: any,
}

local function label(root: Instance, name: string): TextLabel?
	local found = root:FindFirstChild(name, true)
	return if found and found:IsA("TextLabel") then found else nil
end

local function timeText(seconds: number): string
	local whole = math.ceil(seconds)
	return string.format("%d:%02d", math.floor(whole / 60), whole % 60)
end

return function(_controllers: { [string]: any })
	local HatchPadInfo = Component.new({ Tag = GeodeConfig.HatchPadTag }) :: any

	function HatchPadInfo.Start(self: HatchPadInfo)
		local pad = self.Instance
		self.Trove = Trove.new()
		if not pad:IsA("BasePart") then
			return
		end
		local template = AssetRegistry.get(EggDropConfig.LabelTemplateKey)
		if not template:IsA("BillboardGui") then
			template:Destroy()
			warn(`[HatchPadInfo] {EggDropConfig.LabelTemplateKey} is not a BillboardGui`)
			return
		end
		local gui = template :: BillboardGui
		Typography.Apply(gui)
		gui.Adornee = pad
		gui.MaxDistance = PedestalConfig.LabelMaxDistance
		gui.StudsOffsetWorldSpace = Vector3.new(0, GeodeConfig.HatchLabelHeightStuds, 0)
		gui.Enabled = false
		gui.Parent = pad
		self.Trove:Add(gui)
		local detail, luckLabel = label(gui, "Detail"), label(gui, "Luck")
		local clover = gui:FindFirstChild("Clover", true)
		if clover and clover:IsA("ImageLabel") then
			clover.Image = EggDropConfig.LuckIcon
		end
		local timerRowInstance = gui:FindFirstChild("TimerRow", true)
		local timerRow: GuiObject? = if timerRowInstance and timerRowInstance:IsA("GuiObject")
			then timerRowInstance
			else nil
		local clockInstance = gui:FindFirstChild("Clock", true)
		local clock: GuiObject? = if clockInstance and clockInstance:IsA("GuiObject")
			then clockInstance
			else nil
		local progressInstance = gui:FindFirstChild("Progress", true)
		local progress: GuiObject? = if progressInstance and progressInstance:IsA("GuiObject")
			then progressInstance
			else nil
		local fillInstance = if progress then progress:FindFirstChild("Fill") else nil
		local fill: GuiObject? = if fillInstance and fillInstance:IsA("GuiObject") then fillInstance else nil
		local wasReady: boolean? = nil
		local shown = ""
		local measured: Model? = nil
		local function place()
			local found = pad:FindFirstChild(GeodeConfig.PadGeodeName)
			local model = if found and found:IsA("Model") then found else nil
			if model == measured then
				return
			end
			measured = model
			if not model then
				gui.StudsOffsetWorldSpace = Vector3.new(0, GeodeConfig.HatchLabelHeightStuds, 0)
				return
			end
			local box, size = model:GetBoundingBox()
			local top = box.Position.Y + size.Y / 2 - pad.Position.Y
			gui.StudsOffsetWorldSpace =
				Vector3.new(0, top + GeodeConfig.HatchLabelGapStuds + gui.Size.Y.Scale / 2, 0)
		end
		local rocking: Model? = nil
		local rockBase: CFrame? = nil
		local glow: Highlight? = nil
		local function stopRocking()
			if rocking and rockBase and rocking.Parent then
				rocking:PivotTo(rockBase)
			end
			if glow then
				glow:Destroy()
			end
			rocking, rockBase, glow = nil, nil, nil
		end
		self.Trove:Add(stopRocking)
		local function rock(isReady: boolean)
			local found = pad:FindFirstChild(GeodeConfig.PadGeodeName)
			local model = if isReady and found and found:IsA("Model") then found else nil
			if model ~= rocking then
				stopRocking()
				if model then
					rocking = model
					rockBase = model:GetPivot()
					local highlight = Instance.new("Highlight")
					highlight.Name = "ReadyGlow"
					highlight.FillColor = GeodeConfig.ReadyGlowColor
					highlight.FillTransparency = GeodeConfig.ReadyGlowTransparency
					highlight.OutlineColor = Color3.new(1, 1, 1)
					highlight.OutlineTransparency = 0
					highlight.DepthMode = Enum.HighlightDepthMode.Occluded
					highlight.Parent = model
					glow = highlight
				end
			end
			local base = rockBase
			if rocking and base then
				local angle = math.rad(GeodeConfig.ReadyRockDegrees)
					* math.sin(os.clock() * 2 * math.pi / GeodeConfig.ReadyRockSeconds)
				rocking:PivotTo(base * CFrame.Angles(0, 0, angle))
			end
		end
		self.Trove:Connect(RunService.Heartbeat, function()
			local geodeKey = pad:GetAttribute("GeodeKey")
			local readyAt = pad:GetAttribute("ReadyAt")
			local geode = if type(geodeKey) == "string" then GeodeConfig.Geodes[geodeKey] else nil
			gui.Enabled = geode ~= nil and type(readyAt) == "number"
			if not geode or type(readyAt) ~= "number" then
				shown = ""
				rock(false)
				return
			end
			place()
			local paused = pad:GetAttribute("PausedSeconds")
			local left = if type(paused) == "number" then paused else readyAt - workspace:GetServerTimeNow()
			rock(left <= 0)
			local isReady = left <= 0
			local text = if isReady then GeodeConfig.HatchReadyText else timeText(left)
			if timerRow then
				timerRow.Visible = true
			end
			if clock then
				clock.Visible = not isReady
			end
			if progress then
				progress.Visible = not isReady
			end
			if fill then
				local total = math.max(geode.HatchSeconds, left, 1)
				fill.Size = UDim2.fromScale(math.clamp(1 - left / total, 0, 1), 1)
			end
			if detail and isReady ~= wasReady then
				wasReady = isReady
				Typography.ApplyTextStyle(detail, if isReady then "Green" else "Chrome")
			end
			local luck = pad:GetAttribute("EggLuck")
			local luckText =
				EggLuck.Text(if type(luck) == "number" then luck else EggDropConfig.LuckMinHundredths)
			if text .. luckText ~= shown then
				shown = text .. luckText
				if luckLabel then
					luckLabel.Text = luckText
				end
				if detail then
					detail.Text = text
					detail.Visible = true
				end
			end
		end)
	end

	function HatchPadInfo.Stop(self: HatchPadInfo)
		if self.Trove then
			self.Trove:Destroy()
		end
	end

	return HatchPadInfo
end
