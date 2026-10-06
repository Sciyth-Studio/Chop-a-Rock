--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

type OwnedPrompt = {
	Instance: Instance,
	Trove: any,
}

return function(_controllers: { [string]: any })
	local OwnedPrompt = Component.new({ Tag = "OwnedPrompt" }) :: any

	function OwnedPrompt.Start(self: OwnedPrompt)
		local prompt = self.Instance
		if not prompt:IsA("ProximityPrompt") then
			return
		end
		self.Trove = Trove.new()
		local function refresh()
			local shouldEnable = prompt:GetAttribute("OwnerUserId") == Players.LocalPlayer.UserId
				and prompt:GetAttribute("Active") == true
			if prompt.Enabled ~= shouldEnable then
				prompt.Enabled = shouldEnable
			end
		end
		self.Trove:Add(prompt:GetAttributeChangedSignal("OwnerUserId"):Connect(refresh))
		self.Trove:Add(prompt:GetAttributeChangedSignal("Active"):Connect(refresh))
		self.Trove:Add(prompt:GetPropertyChangedSignal("Enabled"):Connect(refresh))
		refresh()
	end

	function OwnedPrompt.Stop(self: OwnedPrompt)
		if self.Trove then
			self.Trove:Destroy()
		end
	end

	return OwnedPrompt
end
