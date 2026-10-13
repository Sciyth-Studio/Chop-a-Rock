--!strict
-- Paste into execute_luau (Edit) after filling ROCKS and PROP_COLORS. Replaces Model_Rock_<Key> and
-- Model_RockPreview_<Key> in ReplicatedStorage.Assets.Models with the uploaded rock (props nested under it)
-- and creates Model_RockSplit_<Name> with each prop under the piece on its side.

local ROCKS = {
	-- { Name = "FernRock", Key = "JungleFirst", Rock = 0, Split = 0 },
}
local PROP_COLORS: { [string]: Color3 } = {
	-- Fern = Color3.fromRGB(30, 150, 45),
}

local InsertService = game:GetService("InsertService")
local Models = game.ReplicatedStorage.Assets.Models

local function baseName(name: string, rockName: string): string
	local trimmed = string.gsub(name, "^" .. rockName .. "_", "")
	return trimmed
end

local function colorFor(name: string): Color3?
	local stripped = string.gsub(name, "_[LR]$", "")
	return PROP_COLORS[stripped]
end

local function stud(part: BasePart)
	part.Material = Enum.Material.Plastic
	part.MaterialVariant = "2022 Inlet"
	if part:IsA("MeshPart") then
		part.TextureID = ""
	end
end

local out = {}
for _, info in ROCKS do
	local old = Models:FindFirstChild("Model_Rock_" .. info.Key, true) :: BasePart
	local oldPreview = Models:FindFirstChild("Model_RockPreview_" .. info.Key, true)
	local loaded = InsertService:LoadAsset(info.Rock)
	local rock: MeshPart
	for _, d in loaded:GetDescendants() do
		if d:IsA("MeshPart") and d.Name == info.Name then
			rock = d
		end
	end
	assert(rock, "no rock mesh " .. info.Name)
	local props = {}
	for _, d in loaded:GetDescendants() do
		if d:IsA("MeshPart") and d ~= rock then
			table.insert(props, d)
		end
	end
	local rel = {}
	for _, p in props do
		rel[p] = rock.CFrame:ToObjectSpace(p.CFrame)
	end
	rock.Name = "Model_Rock_" .. info.Key
	rock.Color = old.Color
	stud(rock)
	rock.Anchored = true
	rock.Archivable = true
	rock:SetAttribute("RockKey", info.Key)
	rock:SetAttribute("SplitModel", "Model_RockSplit_" .. info.Name)
	local base = old.CFrame
	rock.CFrame = CFrame.new(base.X, base.Y - old.Size.Y / 2 + rock.Size.Y / 2, base.Z)
	for _, c in old:GetChildren() do
		if not c:IsA("BasePart") then
			c:Clone().Parent = rock
		end
	end
	for _, p in props do
		p.Name = baseName(p.Name, info.Name)
		p.Color = colorFor(p.Name) or p.Color
		stud(p)
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = rock.CFrame:ToWorldSpace(rel[p])
		p.Parent = rock
	end
	rock.Parent = old.Parent
	old:Destroy()
	loaded:Destroy()

	if oldPreview then
		local oldRock = oldPreview:FindFirstChild("Rock") :: BasePart
		local bottom = oldRock.Position.Y - oldRock.Size.Y / 2
		local preview = Instance.new("Model")
		preview.Name = oldPreview.Name
		local copy = rock:Clone()
		copy.Name = "Rock"
		copy:SetAttribute("RockKey", nil)
		copy:SetAttribute("SplitModel", nil)
		for _, c in copy:GetChildren() do
			if c:IsA("Highlight") then
				c:Destroy()
			end
		end
		local target = CFrame.new(0, bottom + copy.Size.Y / 2, 0)
		for _, c in copy:GetChildren() do
			if c:IsA("BasePart") then
				c.CFrame = target:ToWorldSpace(copy.CFrame:ToObjectSpace(c.CFrame))
			end
		end
		copy.CFrame = target
		copy.Parent = preview
		preview.PrimaryPart = copy
		preview.Parent = oldPreview.Parent
		oldPreview:Destroy()
	end

	local splitAsset = InsertService:LoadAsset(info.Split)
	local pieces, splitProps = {}, {}
	for _, d in splitAsset:GetDescendants() do
		if d:IsA("MeshPart") then
			if string.find(d.Name, "_Piece") then
				table.insert(pieces, d)
			else
				table.insert(splitProps, d)
			end
		end
	end
	local splitModel = Instance.new("Model")
	splitModel.Name = "Model_RockSplit_" .. info.Name
	local centreX = 0
	for _, p in pieces do
		centreX += p.Position.X / #pieces
	end
	for _, p in pieces do
		p.Name = baseName(p.Name, info.Name)
		stud(p)
		p.Color = rock.Color
		p.Anchored = false
		p.Parent = splitModel
	end
	for _, p in splitProps do
		p.Name = baseName(p.Name, info.Name)
		p.Color = colorFor(p.Name) or p.Color
		stud(p)
		p.Anchored = false
		p.CanCollide = false
		local side = p.Position.X - centreX
		for _, piece in pieces do
			if (piece.Position.X - centreX) * side > 0 then
				p.Parent = piece
			end
		end
	end
	local existing = Models:FindFirstChild(splitModel.Name, true)
	local splitParent = if existing then existing.Parent else rock.Parent
	if existing then
		existing:Destroy()
	end
	splitModel.Parent = splitParent
	splitAsset:Destroy()

	local line = info.Key .. " size " .. tostring(rock.Size) .. " props " .. #props
	for _, piece in pieces do
		local names = {}
		for _, c in piece:GetChildren() do
			table.insert(names, c.Name)
		end
		line ..= " [" .. piece.Name .. ": " .. table.concat(names, ",") .. "]"
	end
	table.insert(out, line)
end
return table.concat(out, "\n")
