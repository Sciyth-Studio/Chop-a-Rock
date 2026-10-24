---
description: Put Promises in a Trove with trove:AddPromise, never trove:Add; Add throws on a settled Promise and kills the screen
type: reference
---
# Trove Promises

Use `trove:AddPromise(promise)` for Promises (WaitFor, Promise chains). `trove:Add(promise)` in Trove 1.8 throws "failed to get cleanup function for object table: Promise(Resolved)" when the Promise has already settled. That happens whenever WaitFor finds its child straight away.

On 2026-10-23 this broke the HUD. The touch-dock code in `Screens/Hud` used `trove:Add`, so `Hud.new` threw before `bindData("Strength")`. UIController logged "Hud screen disabled", and the strength counter stopped updating while cash still updated.

When a screen misbehaves, check the client log for `[UIController] <Screen> screen disabled` first. `LogService:GetLogHistory()` in the Client datamodel shows it.
