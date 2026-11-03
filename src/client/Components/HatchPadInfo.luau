--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local Component = require(ReplicatedStorage.Packages.Component)
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
		local template = AssetRegistry.get(PedestalConfig.InfoTemplateKey)
		if not template:IsA("BillboardGui") then
			template:Destroy()
			warn(`[HatchPadInfo] {PedestalConfig.InfoTemplateKey} is not a BillboardGui`)
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
		local title, detail = label(gui, "Title"), label(gui, "Detail")
		for _, name in { "Modifier", "Size" } do
			local extra = label(gui, name)
			if extra then
				extra.Visible = false
			end
		end
		local shown = ""
		self.Trove:Connect(RunService.Heartbeat, function()
			local geodeKey = pad:GetAttribute("GeodeKey")
			local readyAt = pad:GetAttribute("ReadyAt")
			local geode = if type(geodeKey) == "string" then GeodeConfig.Geodes[geodeKey] else nil
			gui.Enabled = geode ~= nil and type(readyAt) == "number"
			if not geode or type(readyAt) ~= "number" then
				shown = ""
				return
			end
			local left = readyAt - workspace:GetServerTimeNow()
			local text = if left <= 0 then GeodeConfig.HatchReadyText else timeText(left)
			if text ~= shown then
				shown = text
				if title then
					title.Text = geode.DisplayName
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
