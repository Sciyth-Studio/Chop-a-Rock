---
description: UI is authored in Studio (StarterGui) via the Studio MCP and driven by UIController screens, never built with Instance.new.
type: preference
updated: 2026-09-29
---
Build all UI as ScreenGuis authored in StarterGui through the Roblox Studio MCP, with one `UIController` screen module per ScreenGui (`src/client/Controllers/UIController/Screens/<Name>.luau`). Code only finds elements by name and drives them. Do not create UI with `Instance.new`.

**Why:** AGENTS.md's UI section requires this unless the user prefers code-built UI. The chop meter, HUD and training hint were once built in code without checking; asked, the user said "I don't prefer code built UI". They want to restyle visuals in Studio.

**How to apply:** check AGENTS.md and the `studio-ui` skill before any client/UI work. Use `mcp__Roblox_Studio__*` tools (execute_luau in Edit mode to build instances). Runtime effects such as the damage number are templates in `ReplicatedStorage/Assets/VFX` fetched through AssetRegistry. Controllers open and close screens via `UIController:Open/Close`; per-quality colors live in `ChopStyleConfig`; fonts are applied by `Typography.Apply`. StarterGui lives in the place file, not git, so remind the user to save the place after UI changes. See also [[High Saturation Colors]], [[UI Text Style]].

**Exception (2026-10-03):** the Settings gear in Roblox's top bar is a TopbarPlus icon made in code (`Screens/Settings.luau`), because the user wanted it to match Roblox's own top bar buttons. The Settings panel it opens is still authored in Studio.
