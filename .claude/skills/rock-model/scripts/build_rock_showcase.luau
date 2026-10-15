--!strict
-- Paste into execute_luau (Edit). Rebuilds Workspace.RockShowcase (EditorOnly) west of the zones: one plate per
-- zone at that zone's Z, each rock template in front and its split model behind with the pieces pulled apart.
-- Copies carry a ShowcaseSource attribute (split models also ShowcaseRock) that the RockShowcase plugin uses to
-- mirror template colour and material changes live. Rerun after reshaping or replacing a rock template.

local CollectionService = game:GetService("CollectionService")
local Rocks = game.ReplicatedStorage.Assets.Models.Rocks
local RockConfig = require(game.ReplicatedStorage.Config.RockConfig).Rocks

local ZONES = {
	{ Name = "Forest", Z = -135, Floor = Color3.fromRGB(39, 70, 45), Keys = { "Basic", "Second", "Third" } },
	{ Name = "Desert", Z = -15, Floor = Color3.fromRGB(160, 132, 79), Keys = { "DesertFirst", "DesertSecond", "DesertThird" } },
	{ Name = "Jungle", Z = 105, Floor = Color3.fromRGB(50, 130, 40), Keys = { "JungleFirst", "JungleSecond", "JungleThird" } },
	{ Name = "Ocean", Z = 225, Floor = Color3.fromRGB(0, 55, 110), Keys = { "OceanFirst", "OceanSecond", "OceanThird" } },
	{ Name = "Snow", Z = 345, Floor = Color3.fromRGB(240, 245, 255), Keys = { "SnowFirst", "SnowSecond", "SnowThird" } },
	{ Name = "Diamond", Z = -255, Floor = Color3.fromRGB(60, 60, 60), Keys = { "Diamond" } },
}
local CENTER_X = -260
local SLOT_X = { 55, 0, -60 }
local ROCK_Z = -22
local SPLIT_Z = 28
local SPREAD = 4
local PLATE_SIZE = Vector3.new(170, 1, 110)

local old = workspace:FindFirstChild("RockShowcase")
if old then
	old:Destroy()
end
local root = Instance.new("Folder")
root.Name = "RockShowcase"
CollectionService:AddTag(root, "EditorOnly")

local function label(parent: Instance, name: string, text: string, color: Color3, cframe: CFrame, size: Vector3)
	local sign = Instance.new("Part")
	sign.Name = name
	sign.Anchored = true
	sign.CanCollide = false
	sign.Size = size
	sign.CFrame = cframe
	sign.Color = Color3.fromRGB(30, 30, 30)
	sign.Material = Enum.Material.SmoothPlastic
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = sign
	local text_ = Instance.new("TextLabel")
	text_.Size = UDim2.fromScale(1, 1)
	text_.BackgroundTransparency = 1
	text_.Font = Enum.Font.FredokaOne
	text_.TextScaled = true
	text_.Text = text
	text_.TextColor3 = color
	text_.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = color:Lerp(Color3.new(0, 0, 0), 0.75)
	stroke.Parent = text_
	sign.Parent = parent
end

local function ground(model: Model, position: Vector3)
	local cf, size = model:GetBoundingBox()
	local offset = position - cf.Position + Vector3.new(0, size.Y / 2, 0)
	model:PivotTo(model:GetPivot() + offset)
end

local function archivable(instance: Instance)
	instance.Archivable = true
	for _, d in instance:GetDescendants() do
		d.Archivable = true
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
end

local made = {}
for _, zone in ZONES do
	local row = Instance.new("Model")
	row.Name = zone.Name
	local plateTop = 1
	local plate = Instance.new("Part")
	plate.Name = "Plate"
	plate.Anchored = true
	plate.Size = PLATE_SIZE
	plate.CFrame = CFrame.new(CENTER_X, plateTop - PLATE_SIZE.Y / 2, zone.Z)
	plate.Color = zone.Floor
	plate.Material = Enum.Material.Plastic
	plate.MaterialVariant = "2022 Inlet"
	plate.Parent = row
	label(
		row,
		"Title",
		zone.Name,
		zone.Floor:Lerp(Color3.new(1, 1, 1), 0.35),
		CFrame.new(CENTER_X, plateTop + 6, zone.Z - PLATE_SIZE.Z / 2 + 1),
		Vector3.new(40, 10, 0.5)
	)
	for index, key in zone.Keys do
		local template = Rocks:FindFirstChild("Model_Rock_" .. key, true)
		if not template then
			table.insert(made, "missing Model_Rock_" .. key)
			continue
		end
		local x = CENTER_X + (if #zone.Keys == 1 then 0 else SLOT_X[index])
		local stand = Instance.new("Model")
		stand.Name = key
		local rock = template:Clone()
		rock:SetAttribute("ShowcaseSource", template.Name)
		local rockModel = Instance.new("Model")
		rockModel.Name = "Rock"
		rock.Parent = rockModel
		rockModel.Parent = stand
		ground(rockModel, Vector3.new(x, plateTop, zone.Z + ROCK_Z))
		local info = RockConfig[key]
		local title = if info and info.DisplayName then info.DisplayName else key
		label(
			stand,
			"Name",
			title,
			if template:IsA("BasePart") then template.Color else Color3.new(1, 1, 1),
			CFrame.new(x, plateTop + 2, zone.Z + ROCK_Z - 18),
			Vector3.new(22, 4, 0.5)
		)
		local splitKey = template:GetAttribute("SplitModel")
		local splitTemplate = if type(splitKey) == "string" then Rocks:FindFirstChild(splitKey, true) else nil
		if splitTemplate and splitTemplate:IsA("Model") then
			local split = splitTemplate:Clone()
			split.Name = "Split"
			split:SetAttribute("ShowcaseSource", splitTemplate.Name)
			split:SetAttribute("ShowcaseRock", template.Name)
			local low, high = math.huge, -math.huge
			for _, piece in split:GetChildren() do
				if piece:IsA("BasePart") then
					local half = piece.Size / 2
					for _, sx in { -1, 1 } do
						for _, sy in { -1, 1 } do
							for _, sz in { -1, 1 } do
								local point = piece.CFrame:PointToWorldSpace(half * Vector3.new(sx, sy, sz))
								low = math.min(low, point.X)
								high = math.max(high, point.X)
							end
						end
					end
				end
			end
			if template:IsA("BasePart") and high > low then
				split:ScaleTo(split:GetScale() * template.Size.X / (high - low))
			end
			local center = split:GetBoundingBox().Position
			for _, piece in split:GetChildren() do
				local pieceCf = if piece:IsA("Model")
					then piece:GetBoundingBox()
					elseif piece:IsA("BasePart") then piece.CFrame
					else nil
				if pieceCf then
					local away = (pieceCf.Position - center) * Vector3.new(1, 0, 1)
					if away.Magnitude > 0.01 then
						local shift = away.Unit * SPREAD
						if piece:IsA("Model") then
							piece:PivotTo(piece:GetPivot() + shift)
						elseif piece:IsA("BasePart") then
							piece.CFrame += shift
							for _, prop in piece:GetDescendants() do
								if prop:IsA("BasePart") then
									prop.CFrame += shift
								end
							end
						end
					end
				end
			end
			split.Parent = stand
			ground(split, Vector3.new(x, plateTop, zone.Z + SPLIT_Z))
		elseif zone.Name ~= "Diamond" then
			table.insert(made, "no split for " .. key)
		end
		archivable(stand)
		stand.Parent = row
		table.insert(made, key)
	end
	row.Parent = root
end
root.Parent = workspace
return table.concat(made, ", ")
