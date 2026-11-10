--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OutlinedIconConfig = require(ReplicatedStorage.Config.OutlinedIconConfig)

local OutlinedIcon = {}

function OutlinedIcon.Get(image: string, pixels: number?): string
	if pixels and pixels <= OutlinedIconConfig.SmallMaxPixels then
		local small = OutlinedIconConfig.Small[image]
		if small then
			return small
		end
	end
	return OutlinedIconConfig.Normal[image] or image
end

function OutlinedIcon.For(label: ImageLabel, image: string): string
	local size = label.Size
	local pixels = if size.X.Scale == 0 then size.X.Offset else nil
	return OutlinedIcon.Get(image, pixels)
end

return OutlinedIcon
