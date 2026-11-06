--!strict

local GeodeConfig = require(script.Parent.Parent.Config.GeodeConfig)
local ItemIconConfig = require(script.Parent.Parent.Config.ItemIconConfig)

local ItemIcons = {}

export type Visual = ImageLabel | ViewportFrame

function ItemIcons.Get(kind: string, key: string): string?
	local icons = ItemIconConfig[kind]
	if not icons then
		return nil
	end
	local icon = icons[key]
	if icon or kind ~= "Geode" then
		return icon
	end
	local geode = GeodeConfig.Geodes[key]
	return if geode and geode.BaseKey and not geode.IsSecondLook then icons[geode.BaseKey] else nil
end

function ItemIcons.Tint(visual: Visual?, color: Color3)
	if not visual then
		return
	end
	if visual:IsA("ImageLabel") then
		visual.ImageColor3 = color
	elseif visual:IsA("ViewportFrame") then
		visual.ImageColor3 = color
	end
end

local function clearViewport(frame: ViewportFrame)
	for _, child in frame:GetChildren() do
		if child:IsA("Model") or child:IsA("Camera") then
			child:Destroy()
		end
	end
end

function ItemIcons.Apply(
	holder: Instance,
	kind: string,
	key: string,
	buildFallback: (ViewportFrame) -> ()
): Visual?
	local image = ItemIcons.Get(kind, key)
	local icon = holder:FindFirstChild("Icon")
	local preview = holder:FindFirstChild("Preview")
	local shown: Visual? = nil
	if icon and icon:IsA("ImageLabel") then
		icon.Image = image or ""
		icon.Visible = image ~= nil
		if image then
			shown = icon
		end
	end
	if preview and preview:IsA("ViewportFrame") then
		preview.Visible = shown == nil
		if shown == nil then
			buildFallback(preview)
			shown = preview
		else
			clearViewport(preview)
		end
	end
	return shown
end

return ItemIcons
