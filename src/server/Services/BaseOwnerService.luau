--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BaseOwnerConfig = require(ReplicatedStorage.Config.BaseOwnerConfig)
local FontConfig = require(ReplicatedStorage.Config.FontConfig)

local BaseOwnerService = { Name = "BaseOwnerService" }

local services: { [string]: any } = {}
local connections: { any } = {}

local function setTag(plot: Model, owner: Player?)
	local spot = plot:FindFirstChild(BaseOwnerConfig.SpotName, true)
	local tag = spot and spot:FindFirstChild(BaseOwnerConfig.TagName)
	if not tag or not tag:IsA("BillboardGui") then
		warn(
			`[BaseOwnerService] {plot:GetFullName()} has no {BaseOwnerConfig.SpotName}.{BaseOwnerConfig.TagName}`
		)
		return
	end
	local label = tag:FindFirstChild(BaseOwnerConfig.NameLabelName, true)
	if label and label:IsA("TextLabel") then
		label.Text = if owner then `{BaseOwnerConfig.NamePrefix}{owner.Name}` else ""
		label.FontFace = FontConfig.Default
	end
	local image = tag:FindFirstChild(BaseOwnerConfig.ImageName, true)
	if image and image:IsA("ImageLabel") then
		image.Image = if owner then string.format(BaseOwnerConfig.ImageFormat, owner.UserId) else ""
	end
	tag.Enabled = owner ~= nil
end

function BaseOwnerService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function BaseOwnerService.Start(_self: any)
	local baseService = services.BaseService
	table.insert(
		connections,
		baseService.PlotClaimed:Connect(function(player: Player, plot: Model)
			setTag(plot, player)
		end)
	)
	table.insert(
		connections,
		baseService.PlotReleased:Connect(function(_player: Player, plot: Model)
			setTag(plot, nil)
		end)
	)
end

function BaseOwnerService.Destroy(_self: any)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

return BaseOwnerService
