--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetRegistry = require(ReplicatedStorage.AssetRegistry)
local TrainingConfig = require(ReplicatedStorage.Config.TrainingConfig)

local Stands = {}

function Stands.Current(plot: Model): Model?
	local stand = plot:FindFirstChild(TrainingConfig.StandModelName)
	return if stand and stand:IsA("Model") then stand else nil
end

function Stands.Apply(plot: Model, stand: TrainingConfig.Stand): boolean
	local current = Stands.Current(plot)
	if not current then
		return false
	end
	local key = current:GetAttribute(TrainingConfig.StandKeyAttribute)
	if key == stand.Key or (key == nil and stand.Key == TrainingConfig.Stands[1].Key) then
		return false
	end
	local asset = AssetRegistry.get(stand.TemplateKey)
	if not asset:IsA("Model") then
		asset:Destroy()
		return false
	end
	local replacement = asset :: Model
	replacement.Name = TrainingConfig.StandModelName
	replacement:SetAttribute(TrainingConfig.StandKeyAttribute, stand.Key)
	replacement:PivotTo(current:GetPivot())
	current:Destroy()
	replacement.Parent = plot
	return true
end

return Stands
