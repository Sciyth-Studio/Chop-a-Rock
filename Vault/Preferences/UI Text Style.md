---
description: Default UI text style is a colored stroke plus vertical gradient fill; black/white only when the user explicitly asks.
type: preference
updated: 2026-09-29
---
Use a **colored** stroke and **gradient** text fill on player-facing UI text whenever possible. Plain black stroke / plain white text only when explicitly asked (e.g. notifications and rock labels were explicitly requested as white text with black stroke).

**Why:** the user likes the chunky Roblox-simulator UI style (dark edges, light middle, colored outline); stated as a standing rule on 2026-09-29.

**How to apply:** for new or restyled text, add a UIGradient (rotation 90: darker top and bottom, lighter middle) on a white-based TextLabel and a darker-shade UIStroke of the same hue. Italic text is applied through the "Italic" attribute read by Typography. The `studio-ui` skill has the full TextStyle system. Pairs with [[High Saturation Colors]] and [[UI Built In Studio]].
