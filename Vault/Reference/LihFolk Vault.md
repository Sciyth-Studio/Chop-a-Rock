---
description: 2026-10-28 third-party Roblox knowledge vault in Downloads (825 notes, Oct 2026); read-only reference, safe to open, don't run its installer; which notes matter for Chop a Rock.
type: reference
updated: 2026-10-28
---
# LihFolk Vault

`C:\Users\Admin\Downloads\LihFolk Vault V1 Lite\LihFolk Vault V1`: a downloaded Obsidian vault on Roblox dev (825 notes, written October 2026). Facts are tagged "Roblox docs", "Measured" (one combat RPG, not general) or "Rule of thumb"; code is mostly not run. `VAULT_INDEX.md` is a one-line-per-note index to grep.

## How to use it
- Read-only reference. Our own vault and the skills in `.claude/skills/` win where they disagree.
- Don't run `install-ai.ps1`: it copies 10 skills into `~/.claude/skills`, sets a `ROBLOX_VAULT` user env var and, with `-Global`, tells Claude to use the vault on every Roblox task.
- Reviewed 2026-10-28: the Obsidian plugin, CSS and scripts make no network calls or deletes (fonts from Google only). The `upload/*.zip` skill files are really tar archives.

## Notes that matter for this game
- `11 .../Paid Random Items and Odds Disclosure in Practice`: odds must be shown as the player's true odds while any paid modifier is active (own boost, server luck someone else bought, pity); restricted players gated on the server. Cash bought with Robux makes cash-priced random items count too.
- `11 .../Developer Products and ProcessReceipt`, `22 .../Economy Exploits - Dupes Races and Purchase Abuse`: our `PurchaseService` already follows the checklist (one owner, marker in the profile, save then acknowledge, grant on unexpected receipts).
- `48 .../Drop Tables Rarity and Pity Systems`: effective-rate maths for pity (`p / (1 - (1-p)^K)`); a higher hit resets lower counters (`HatchPity.After` does).
- `10 .../First-Time User Experience and Onboarding`, `11 .../Analytics and Funnels`, `48 .../Economy Telemetry and Balancing Live`, `47 .../Reward Moments and Celebrations`, `38 .../Limited-Time Offers - Design and Ethics`, `32 .../Case Study - Pet Simulator 99`.

## Modelling notes (checked 2026-10-28)
Strong and consistent with our pipeline (1 unit = 1 stud, FBX Apply Scalings "FBX Unit Scale", 20k tris per mesh). Most useful: `14 .../Exporting and Validating Models for Roblox` (pivot traps, a read-only import audit script), `54 .../Faceted Low-Poly - Flat Normals and Facet Size` (size facets by on-screen pixels, 5 to 12 across a silhouette, no triangles over about 8:1), `54 .../Flat Colour vs Gradient Atlas vs Vertex Colour` (`Color` must be white on vertex-coloured meshes), `45 .../Blender 5 Python Gotchas for Headless Builds`, `45 .../Low-Poly Creature From a Flat Reference Sheet`. Its stud and shading advice (three tones per material, outlines) is generic; our [[Flat Shading On Buildings]] and [[Studs On Models By Default]] win. Section 45 renders are Eevee, not Roblox captures.

Related: [[Monetization References]], [[Robux Shop Plan Approved]], [[Geode Shop]], [[Analytics]], [[Tutorial]].
