--!strict

export type Data = {
	SchemaVersion: number,
	Cash: number,
	Strength: number,
	ArmTier: number,
	Rebirths: number,
	Settings: { [string]: boolean },
	LastSeenAt: number,
	Receipts: { [string]: number },
}

local PlayerData = {}

PlayerData.Template = {
	SchemaVersion = 1,
	Cash = 0,
	Strength = 0,
	ArmTier = 1,
	Rebirths = 0,
	Settings = {
		Music = true,
		SoundEffects = true,
	},
	LastSeenAt = 0,
	Receipts = {},
} :: Data

local function natural(value: any): boolean
	return type(value) == "number"
		and value == value
		and math.abs(value) < math.huge
		and value >= 0
		and value % 1 == 0
end

function PlayerData.Validate(data: any): boolean
	if type(data) ~= "table" or (data.SchemaVersion ~= nil and data.SchemaVersion ~= 1) then
		return false
	end
	for _, key in { "Cash", "Strength", "Rebirths", "LastSeenAt" } do
		if data[key] ~= nil and not natural(data[key]) then
			return false
		end
	end
	if data.ArmTier ~= nil and (not natural(data.ArmTier) or data.ArmTier < 1) then
		return false
	end
	if data.Settings ~= nil then
		if type(data.Settings) ~= "table" then
			return false
		end
		for name, value in data.Settings do
			if type(name) ~= "string" or type(value) ~= "boolean" then
				return false
			end
		end
	end
	if data.Receipts ~= nil then
		if type(data.Receipts) ~= "table" then
			return false
		end
		for purchaseId, grantedAt in data.Receipts do
			if type(purchaseId) ~= "string" or #purchaseId == 0 or not natural(grantedAt) then
				return false
			end
		end
	end
	return true
end

function PlayerData.Migrate(_data: any) end

return PlayerData
