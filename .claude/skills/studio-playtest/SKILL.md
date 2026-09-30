---
name: studio-playtest
description: Use when verifying a change in Roblox Studio for this project (running a playtest, testing client or server behavior, checking UI or animation values). Covers the play/stop workflow, Rojo sync timing, and the limits of the execute_luau test tool.
---

# Playtesting in Studio

## Workflow

1. Run `./scripts/check.ps1` after every code change; it must pass before testing.
2. Stop Play if it is running (`start_stop_play` with `is_start: false`). Edit-mode work needs Play stopped.
3. Apply Studio-side edits, then wait about 4 seconds in Edit mode for Rojo to sync. Confirm by reading the script `Source` or the value in Edit mode.
4. Start Play (`is_start: true`), wait about 5 to 9 seconds for controllers to finish starting, then test.
5. Stop Play when finished. The user often has Studio in Play mode too, so Edit calls can fail with "not available in Play mode"; stop it and retry.

## Running test code

- `execute_luau` takes `datamodel_type`: `Client` or `Server` in Play, `Edit` when stopped.
- Do not run a Client and a Server call in parallel when one depends on the other's timing.
- `Client`: `game.Players.LocalPlayer`, `PlayerGui`, `PlayerScripts`. `Server`: services and workspace.

## Limits of the test tool

- The tool runs in a plugin context. Requiring a game module gives a separate copy, so calling the real controller's methods or signals does not reach the running one. Test screens by requiring the screen module and calling `.new(stubContext, clonedGui)` with a stub controller (a table with a `Signal` and getters), then firing the stub.
- Firing server packets from a required copy of a service may not deliver. Prefer exercising the real path (attributes, prompts) or a stub.
- It cannot write `Motor6D.C0`, send real key input (`VirtualInputManager` is blocked), or construct an `InputObject`.
- Changing a player attribute on the client only changes the client's view, which is enough to test HUD, arrows, labels and highlights (for example `LocalPlayer:SetAttribute("Strength", 300)`).
- A `ProximityPrompt` only shows when the character is in range and the camera faces it. To test prompt UI, place the character near the rock, point a Scriptable camera at it, wait about 1.5 seconds, then call `prompt:InputHoldBegin()` and `prompt:InputHoldEnd()`.
- The character's joints are `AnimationConstraint`s, not Motor6Ds. Poses are set by writing `.Transform` on `RunService.PreSimulation`; writing on RenderStepped has no effect.
- `screen_capture` needs a capture id; prefer numeric checks (positions, sizes, colors, transparencies) and describe visuals honestly as unseen.
- `LogService:GetLogHistory()` in the Client datamodel shows warnings that `get_console_output` omits.

## Reporting

- State what was verified numerically and what was not seen on screen. Do not claim visual results that were only checked by values.
