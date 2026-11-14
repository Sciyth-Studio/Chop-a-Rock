---
description: The user usually playtests changes in Studio themself; Claude runs the check script and leaves Studio playtests to them unless asked.
type: preference
---
# User playtests changes

The user said "I'll test it myself" (2026-10-18) and "I'll test it btw" (2026-10-19, stopping a planned playtest). Default: after a code change, run `./scripts/check.ps1`, then hand over what to look for in Studio instead of driving a playtest. Run a Studio playtest only when the user asks for one, as they did on 2026-10-18 ("double check the first bullet, and use the admin panel").

**Playtests constantly (2026-11-10):** the user said they test the game "like all the time", so a build marked "not playtested" in the vault has probably been played and they just didn't report it. Don't list unplaytested builds as open work or ask the user to playtest them; treat a build as fine unless the user reports a problem.

**Applies to briefs too (2026-11-11):** Claude briefed four parallel boss sessions to "check it in Play" and playtested the boss fight itself, and the user said "i could've done the testing". When starting or briefing another session, tell it **not** to playtest: run `check.ps1`, do any Edit-mode setup, and end with a list of what the user should try in Play.

Related: [[Ask The User To Look]].
