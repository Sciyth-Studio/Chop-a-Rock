---
description: Creator Hub analytics beyond the onboarding funnel: cash economy events on every server cash change and a 3-step Robux shop funnel; names in AnalyticsConfig, logged server-side through Utils/Analytics. Built 2026-10-27.
type: system
updated: 2026-10-27
---
# Analytics

Built 2026-10-27 for [[Launch Checklist]] §2. The onboarding funnel lives in [[Tutorial]] (`TutorialService`, 13 steps). Everything here is analytics only; nothing player-facing changed. Passes check.ps1; **not yet seen in Creator Hub** (needs a live test session, Studio Play doesn't report).

## Where things are
- `src/shared/Config/AnalyticsConfig.luau`: currency name (`Cash`), every cash flow as `{ Type, Sku }` under `Sources` and `Sinks`, the shop funnel's name and steps. Shared because the client sends funnel step data. Add a new flow here, never a string at the call site.
- `src/server/Utils/Analytics.luau`: `LogCash(player, flow, amount, balance, detail?)` and `LogFunnelStep(player, funnel, sessionId, step)`, both in `pcall` with a warn, like `TutorialService.logFunnel`. Sign of `amount` picks Source or Sink. `detail` becomes `Sku:detail` (rock key, geode key, aura tier, cannon key, pack key, slot, stand tier, Index kind, rebirth number).
- `DataService:AdjustCash(player, amount, flow?, detail?)` logs when a flow is passed. Calls without a flow log nothing (admin `GrantCash`, and the pad collect, which logs its own split).

## Economy events
Transaction types are Roblox's enum names: Gameplay, Shop, IAP, TimedReward.
- Sources: Chop, StormRock, RushRock (`RockService` picks by the rock's Modifier/Weather), DiamondRock, Pad, Offline, SellRoks, IndexClaim, CashPack, GiftCashPack, StarterPack, OfflineClaim (the Robux 2x claim).
- Sinks: Aura, Geode, Cannon, PedestalSlot, TrainingUpgrade, Rebirth (the cash wiped on rebirth, so balances add up).
- Offline earnings are banked onto pads at join, so `PedestalService` keeps `session.Offline[slot]` and the first collects from that slot log as Offline, the rest as Pad. Offline left on a pad when the player leaves counts as Pad next session.
- Geode Fall pays no cash (it grants a Rok), so it has no event. Geode buys write `Cash` with `Set`, so `GeodeService/Purchasing` logs directly.
- Not logged on purpose: admin SetCash/GrantCash, presets, `ResetData`.

## Robux shop funnel
`LogFunnelStepEvent`, funnel `RobuxShop`: Opened 1 → Prompted 2 → Purchased 3, one funnel session (GUID) per shop open. Chosen over `LogCustomEvent` because Creator Hub draws a step-by-step drop-off chart for funnel events, which is the question being asked; custom events only give counts.
- No "item selected" step: every buy button prompts at once, and only some cards have Details.
- Client: `RobuxShop` screen fires `RobuxShopOpened` on Open and, while open, forwards `PurchaseController.Prompted(kind, id)` as `RobuxShopPrompted`. `PurchaseController` fires `Prompted` for every product and pass prompt; the cash cards prompt directly and fire it themselves.
- Server: `RobuxShopFunnelService` keeps a session per player with the last prompted kind and id. Purchased logs only when `PromptProductPurchaseFinished` / `PromptGamePassPurchaseFinished` matches that prompt, so buys from elsewhere (can't-afford packs, starter offer, exclusive stand) don't count. Gifts open `GiftPicker`, which closes the shop, so they're outside the funnel.

Related: [[Robux Shop Plan Approved]], [[Cash Packs]], [[Pedestals]]
