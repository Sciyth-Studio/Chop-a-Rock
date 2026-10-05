---
description: Player-facing text is Title Case or sentence case ("Rebirth", "Buy 1"), never all caps; applies to Studio labels and strings set in code.
type: preference
updated: 2026-10-05
---
Never write player-facing text in all caps. Use "Rebirth", not "REBIRTH"; "Need 10 Strength", not "NEED 10 STRENGTH". Do not `string.upper` names for display.

**Why:** the user said so during the 2026-10-05 UI restyle ("that goes for all UI"), to match [[Studded Panel Style Reference]].

**How to apply:** on 2026-10-05 every all-caps label in StarterGui and every all-caps UI string in code was converted. This included menu buttons, panel titles, Buy and Need labels, Shop states, the On/Off toggles, touch button titles, the "Tap" key, Perfect!/Master!!, `LevelConfig.LevelWord` = "Lvl" and the server notifications. Acronyms such as "SFX" were left alone. Check new text against this rule.

Related: [[UI Text Style]], [[Menu Panel Style]].

**Exception (2026-10-05):** in the Rebirth panel's "Rebirth only consumes CASH", the word CASH is all caps on purpose, in the HUD money style (`Green` text style, italic, black shadow copy). The user asked for this one word only, not for every mention of cash.
