--!strict

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local EditorOnly = {}

EditorOnly.Tag = "EditorOnly"
EditorOnly.StudioTag = "StudioOnly"

function EditorOnly.Strip()
	local tagged = CollectionService:GetTagged(EditorOnly.Tag)
	if not RunService:IsStudio() then
		for _, instance in CollectionService:GetTagged(EditorOnly.StudioTag) do
			table.insert(tagged, instance)
		end
	end
	if #tagged == 0 then
		return
	end
	local storage = ServerStorage:FindFirstChild(EditorOnly.Tag)
	if not storage then
		storage = Instance.new("Folder")
		storage.Name = EditorOnly.Tag
		storage.Parent = ServerStorage
	end
	for _, instance in tagged do
		if not instance:IsDescendantOf(ServerStorage) then
			instance.Parent = storage
		end
	end
end

return EditorOnly
