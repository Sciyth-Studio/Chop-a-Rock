---
description: Utils/NumberTicker counts displayed numbers up to a new value over 0.3-0.6 s (one shared Heartbeat, text set only when the formatted string changes); used by the HUD Money and Strength and the training minigame Strength label.
type: reference
---
# Number Ticker

`src/shared/Utils/NumberTicker.luau` (built 2026-10-23) makes a label count up to its new value instead of jumping.

- `NumberTicker.new(format, apply, initial?)` returns a ticker. `format(number) -> string` is the label's usual `NumberFormat` call; `apply(text)` writes the text (the HUD passes its `setText`, so shadows stay in sync).
- `:Set(value)` eases from the currently shown value to `value` (ease-out, power `EasePower`). The time is `MinSeconds` plus `SecondsPerDecade` per tenfold jump, capped at `MaxSeconds` (0.3 / 0.1 / 0.6 s, drafts in `NumberTickerConfig`). A new target mid-tween restarts from what is shown. Decreases, and changes that format to the same text, snap.
- `:Snap(value)` jumps with no tween (the HUD Strength label snaps on the first data load). `:Destroy()` stops it; add it to the screen's Trove with `trove:Add(ticker, "Destroy")`.
- All tickers share one Heartbeat connection, made when one starts and dropped when none are moving. `apply` is only called when the formatted string changes, so with compact formats (`1.2M`) most frames write nothing, and nothing is written while idle.
- Used by: `Hud.luau` Money (the floating `+$X` delta slides in, then the number counts up when it lands) and Strength, and `TrainingMinigame` Strength.
- Playtest 2026-10-23: $5,000 → $12.3M took 0.55 s over 35 text writes; Strength 5,678 → 2M took 0.56 s; drop to $100 was a single write.
- No scale pop on the label: a `UIScale` would change `TextBounds`, which the HUD backdrop and invite button track, so they would wobble.
