--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseSignConfig = require(ReplicatedStorage.Config.BaseSignConfig)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Typography = require(ReplicatedStorage.Utils.Typography)

type BaseOwnerSign = {
	Instance: Instance,
	Trove: any,
}

return function(_controllers: { [string]: any })
	local BaseOwnerSign = Component.new({ Tag = BaseSignConfig.PlotTag }) :: any

	function BaseOwnerSign.Start(self: BaseOwnerSign)
		local plot = self.Instance
		if not plot:IsA("Model") or not plot:IsDescendantOf(workspace) then
			return
		end
		self.Trove = Trove.new()

		local function refresh()
			local sign = plot:FindFirstChild(BaseSignConfig.SignName)
			local gui = sign and sign:FindFirstChildWhichIsA("SurfaceGui", true)
			if not gui then
				return
			end
			Typography.Apply(gui)
			local userId = plot:GetAttribute(BaseSignConfig.OwnerAttribute)
			local owner = if type(userId) == "number" then Players:GetPlayerByUserId(userId) else nil
			gui.Enabled = owner ~= nil
			local label = gui:FindFirstChild(BaseSignConfig.NameLabelName, true)
			if label and label:IsA("TextLabel") then
				label.Text = if owner then owner.Name else ""
			end
			local headshot = gui:FindFirstChild(BaseSignConfig.HeadshotName, true)
			if headshot and headshot:IsA("ImageLabel") then
				headshot.Image = if owner
					then string.format(BaseSignConfig.HeadshotFormat, owner.UserId)
					else ""
			end
		end

		self.Trove:Add(plot:GetAttributeChangedSignal(BaseSignConfig.OwnerAttribute):Connect(refresh))
		self.Trove:Add(plot.DescendantAdded:Connect(function(descendant: Instance)
			if descendant:IsA("SurfaceGui") and descendant:IsDescendantOf(plot) then
				refresh()
			end
		end))
		refresh()
	end

	function BaseOwnerSign.Stop(self: BaseOwnerSign)
		if self.Trove then
			self.Trove:Destroy()
		end
	end

	return BaseOwnerSign
end
