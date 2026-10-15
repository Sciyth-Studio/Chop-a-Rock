---
description: Only touch the shared Trello board when the user asks for it in their message; never mirror To Do changes automatically.
type: preference
updated: 2026-10-15
---
# Trello sync on request

2026-10-15, the user: "it should be a prompt only thing, not automatic." This replaces the 2026-10-14 rule to mirror every [[To Do]] change on the board in the same turn.

**Why:** each automatic sync cost about 3k to 5k tokens, mostly from `search_cards` returning every matching card's full description. That isn't worth it on every turn.

**How to apply:**
- Keep [[To Do]] current as usual, but don't read or write the [[Trello Board]] unless the user's message asks for it ("update Trello", "sync the board", "make a card for X").
- When asked, bring the board up to date with everything that changed since the last sync, in one go.
- Keep searches small: exact card name and `limit` 1 to 3, so the big pinned cards don't come back.
- Card conventions when syncing: new approved task → Up Next with a label colour; started → In Progress; built but needs the user to try it → Needs Playtest / Sign-off with a checklist; done → Done; dropped → archive; an asset the code waits on → Assets Needed; a user design decision → a dated card in Decisions; committed → remove "Not committed yet".
- Write cards for the brother: plain language, what to check, where the code lives. Leave out AI-workflow details unless they affect him.
- In the closing message, say which cards changed.
