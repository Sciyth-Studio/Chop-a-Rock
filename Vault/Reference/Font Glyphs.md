---
description: Which special characters render in the game font (BuilderSans ExtraBold) — arrows, Robux icon — and which show as empty boxes.
type: reference
updated: 2026-10-02
---
Checked on the Rebirth screen (2026-10-02):

| Character | Renders? | Use |
| --- | --- | --- |
| `▶` (U+25B6) | yes, chunky | before → after arrows (Rebirth screen) |
| `→` (U+2192) | yes, but thin | avoid for big arrows |
| `➜` (U+279C) | **no** — empty box | don't use |
| `utf8.char(0xE002)` | yes — the Robux icon | Robux prices (Skip Rebirth) |

When trying a new symbol, take a screenshot. Missing glyphs don't error; they just show a box. See [[UI Style References]].
