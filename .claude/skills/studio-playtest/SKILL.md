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
- **Always restore the camera.** If a snippet sets `workspace.CurrentCamera.CameraType` (e.g. Scriptable to face a prompt), it must set it back to `Enum.CameraType.Custom` before the call returns, on every path. Never leave it for Studio's assistant to reset. Stopping Play can leave the Edit camera on `Fixed`, so after every `start_stop_play` stop, set the Edit camera back to Custom (vault: [[Always Restore Camera Type]]).

## Limits of the test tool

- The tool runs in a plugin context. Requiring a game module gives a separate copy, so calling the real controller's methods or signals does not reach the running one. Test screens by requiring the screen module and calling `.new(stubContext, clonedGui)` with a stub controller (a table with a `Signal` and getters), then firing the stub.
- Never `require(ReplicatedStorage.ReplicaClient)` in a Client test. The copy hears every replica update but owns no replicas, so it logs "Received update for missing replica" errors until Play is restarted. To check saved data, restart Play and look at what the server reports instead.
- Firing a client packet from a required copy of `Packets` does reach the server (used for `AdminRun`). For request packets the copy gets the reply, and the real `Packets` also logs "Response thread not found ... discarding response". That line is a test artefact, not a bug.
- `user_keyboard_input` sends real key presses (e.g. `keyPress` `E` to release a chop), so the client runs its real path. Prefer it over firing `ChopRelease`/`ChopLeave` from a copy of `Packets`, which updates the server but leaves the real client's minigame open.
- After an `execute_luau` call that set the camera to Scriptable, Studio's assistant resets it to Custom when the call ends. Don't trust camera checks made inside that same call.
- Workspace has StreamingEnabled. An instance created and sent in a packet in the same moment can arrive as nil on the client. Pre-create it (with `ModelStreamingMode` Persistent) or send something already replicated.
- `screen_capture` often times out while something heavy is animating. For timed sequences, start a sampler in a `task.spawn` that writes changes to `_G.<Name>` (it survives between `execute_luau` calls), trigger the action, then read `_G` back. Take screenshots only at known resting points.
- To click a real UI button (which fires `Activated`), use `user_mouse_input` with `instance_path` such as `LocalPlayer.PlayerGui.GeodeStand.Panel.LuckToggle`, then `mouseButtonClick`.
- Admin commands (vault note [[Admin Panel]]): the "Admin" top-bar icon or Ctrl+Shift + C (+1,000 cash), P (rolled Rok), G (+1 geode), H (next hatch Secret), M (next chop is Master), Backspace (reset own data). From a test script, fire `Packets.AdminRun:Fire("GrantCash")` from a required copy, or click `LocalPlayer.PlayerGui.AdminPanel.Panel.List.<Id>` with `user_mouse_input`.
- If new scripts don't show up in Studio, check that Rojo is running (`Get-Process rojo`; this project serves on port 34872). If it isn't, start `rojo serve default.project.json --address 127.0.0.1` in the background and ask the user to click Connect in the Rojo plugin.
- Firing server packets from a required copy of a service may not deliver. Prefer exercising the real path (attributes, prompts) or a stub.
- It cannot write `Motor6D.C0`, send real key input (`VirtualInputManager` is blocked), or construct an `InputObject`.
- Changing a player attribute on the client only changes the client's view, which is enough to test HUD, arrows, labels and highlights (for example `LocalPlayer:SetAttribute("Strength", 300)`).
- A `ProximityPrompt` only shows when the character is in range and the camera faces it. To test prompt UI, place the character near the rock, point a Scriptable camera at it, wait about 1.5 seconds, then call `prompt:InputHoldBegin()` and `prompt:InputHoldEnd()`.
- The character's joints are `AnimationConstraint`s, not Motor6Ds. Poses are set by writing `.Transform` on `RunService.PreSimulation`; writing on RenderStepped has no effect.
- `screen_capture` needs a capture id; prefer numeric checks (positions, sizes, colors, transparencies) and describe visuals honestly as unseen.
- `LogService:GetLogHistory()` in the Client datamodel shows warnings that `get_console_output` omits.

## Reporting

- State what was verified numerically and what was not seen on screen. Do not claim visual results that were only checked by values.
