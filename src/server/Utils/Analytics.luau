--!strict

local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsConfig = require(ReplicatedStorage.Config.AnalyticsConfig)

local Analytics = {}

function Analytics.LogCash(
	player: Player,
	flow: AnalyticsConfig.CashFlow,
	amount: number,
	balance: number,
	detail: string?
)
	if amount == 0 then
		return
	end
	local flowType = if amount > 0
		then Enum.AnalyticsEconomyFlowType.Source
		else Enum.AnalyticsEconomyFlowType.Sink
	local sku = if detail then `{flow.Sku}{AnalyticsConfig.SkuSeparator}{detail}` else flow.Sku
	local ok, err = pcall(function()
		AnalyticsService:LogEconomyEvent(
			player,
			flowType,
			AnalyticsConfig.Currency,
			math.abs(amount),
			balance,
			flow.Type,
			sku
		)
	end)
	if not ok then
		warn(`[Analytics] Economy event {sku} failed: {err}`)
	end
end

function Analytics.LogFunnelStep(
	player: Player,
	funnel: AnalyticsConfig.Funnel,
	sessionId: string,
	step: number
)
	local name = funnel.StepNames[step]
	if not name then
		return
	end
	local ok, err = pcall(function()
		AnalyticsService:LogFunnelStepEvent(player, funnel.Name, sessionId, step, name)
	end)
	if not ok then
		warn(`[Analytics] {funnel.Name} funnel step {step} failed: {err}`)
	end
end

return Analytics
