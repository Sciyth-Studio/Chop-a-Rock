---
description: Any test or Studio script that changes workspace.CurrentCamera.CameraType must set it back to Custom before it ends.
type: preference
---
The user had to keep switching `workspace.CurrentCamera.CameraType` back to Custom themselves after Claude's tests (2026-10-05).

**Rule:** every `execute_luau` call (Edit, Client or Server) that sets `CameraType` to Scriptable, to frame a prompt or a screenshot for example, sets it back to `Enum.CameraType.Custom` before the call ends. That includes early returns and error paths: save the old type and restore it in the same call. Never leave the camera Scriptable between calls, and before stopping Play, make sure it's Custom. Studio's assistant sometimes resets it on its own, but don't rely on that.

**Gotcha (2026-10-06):** after `start_stop_play` stops a playtest, the Edit camera has read `Fixed` even when it was Custom before Play. So after **every** Play stop, read `workspace.CurrentCamera.CameraType` in Edit and set it back to Custom if needed.

**How to apply:** write test snippets as `local previous = cam.CameraType; ...; cam.CameraType = Enum.CameraType.Custom` (or `previous` when that was Custom). After a session of camera tests, check `workspace.CurrentCamera.CameraType` in Edit mode.

Procedure detail lives in the `studio-playtest` skill. Related: [[Code Output Rules]]
