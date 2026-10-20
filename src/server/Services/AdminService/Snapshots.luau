--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AdminConfig = require(ReplicatedStorage.Config.AdminConfig)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local PlayerData = require(script.Parent.Parent.Parent.Data.PlayerData)
local Types = require(script.Parent.Types)

local fields = {
	"Cash",
	"Strength",
	"AuraTier",
	"TrainingTier",
	"Rebirths",
	"Geodes",
	"Pets",
	"NextPetId",
	"PedestalSlots",
	"PedestalEarnings",
	"Index",
	"Tutorial",
}

type Snapshot = {
	SavedAt: number,
	Data: { [string]: any },
}

local Snapshots = {}

local function store(): DataStore
	local name = AdminConfig.Snapshots.StoreName
	return DataStoreService:GetDataStore(if RunService:IsStudio() then `{name}_Studio` else name)
end

local function validName(name: string): boolean
	return #name > 0
		and #name <= AdminConfig.Snapshots.MaxNameLength
		and string.match(name, "^[%w_%-]+$") ~= nil
end

local function read(player: Player): ({ [string]: Snapshot }?, string?)
	local ok, result = pcall(function()
		return store():GetAsync(tostring(player.UserId))
	end)
	if not ok then
		return nil, `snapshot store failed: {result}`
	end
	return if type(result) == "table" then result else {}, nil
end

function Snapshots.Save(context: Types.Context, player: Player, name: string): string
	if not validName(name) then
		return `name must be 1-{AdminConfig.Snapshots.MaxNameLength} letters, digits, - or _`
	end
	local data = context.Services.DataService:GetData(player)
	if not data then
		return "data not loaded"
	end
	local copy: { [string]: any } = {}
	for _, field in fields do
		local value = (data :: any)[field]
		copy[field] = if type(value) == "table" then TableUtil.Copy(value, true) else value
	end
	local problem: string? = nil
	local ok, result = pcall(function()
		store():UpdateAsync(tostring(player.UserId), function(old: any)
			local saved: { [string]: Snapshot } = if type(old) == "table" then old else {}
			local count = 0
			for _ in saved do
				count += 1
			end
			if not saved[name] and count >= AdminConfig.Snapshots.MaxPerPlayer then
				problem = `already {count} snapshots, delete one first`
				return nil
			end
			saved[name] = { SavedAt = os.time(), Data = copy }
			return saved
		end)
	end)
	if not ok then
		return `snapshot store failed: {result}`
	end
	return problem or `saved snapshot {name}`
end

function Snapshots.Load(context: Types.Context, player: Player, name: string): string
	local saved, problem = read(player)
	if not saved then
		return problem or "snapshot store failed"
	end
	local snapshot = saved[name]
	local data = context.Services.DataService:GetData(player)
	if type(snapshot) ~= "table" or type(snapshot.Data) ~= "table" then
		return `no snapshot called {name}`
	end
	if not data then
		return "data not loaded"
	end
	local candidate = table.clone(data :: any)
	for _, field in fields do
		candidate[field] = snapshot.Data[field]
	end
	if not PlayerData.Validate(candidate) then
		return `snapshot {name} is not valid data any more`
	end
	local overrides: { [string]: any } = {}
	for _, field in fields do
		overrides[field] = snapshot.Data[field]
	end
	if not context.Services.DataService:ResetData(player, overrides) then
		return "data not loaded"
	end
	return `loaded snapshot {name}`
end

function Snapshots.Delete(_context: Types.Context, player: Player, name: string): string
	local found = false
	local ok, result = pcall(function()
		store():UpdateAsync(tostring(player.UserId), function(old: any)
			if type(old) ~= "table" or old[name] == nil then
				return nil
			end
			found = true
			old[name] = nil
			return old
		end)
	end)
	if not ok then
		return `snapshot store failed: {result}`
	end
	return if found then `deleted snapshot {name}` else `no snapshot called {name}`
end

function Snapshots.List(_context: Types.Context, player: Player): string
	local saved, problem = read(player)
	if not saved then
		return problem or "snapshot store failed"
	end
	local names: { string } = {}
	for name in saved do
		table.insert(names, name)
	end
	table.sort(names)
	return if #names > 0 then `snapshots: {table.concat(names, ", ")}` else "no snapshots saved"
end

return Snapshots
