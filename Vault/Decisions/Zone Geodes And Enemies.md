---
description: 2026-11-03, approved, not built - no Geode Shop or cracking; free geodes spawn in zones guarded by one personal enemy per zone (spam click, launched if you lose, flees once you outgrow it); geodes hatch on 8 base pads and wait to be opened; 8 best Pets pay your account directly; pity, Auto Open and Wild Geodes removed. Full plan in ZoneGeodesPlan.md.
type: decision
---
# Zone geodes and enemies (2026-11-03)

Approved by the user 2026-11-03. Full plan with every rule, draft number and build step: `ZoneGeodesPlan.md`. Not built. Numbers are starting points until the [[Balance Model]] pass.

**Why:** Pets earned far less than chopping and cracking took too long. The user also wants to use what already works on Roblox: "changing that adds unnecessary variables to solve in the game succeeding or failing. I think i got too innovation happy when I first started working on the game." This reverses the choice to keep the shop in [[Wild Geodes]].

## The user's calls
- Geodes spawn in zones and you just pick them up. The Geode Shop goes: "the entire game will progress in the zones".
- One enemy per zone, a scaled-up Common Pet near the zone's centre. It ignores you unless you go for a geode. The user prefers this to the speed gates other games use, because the Golem boss comes at the end.
- Combat is spam clicking. Anyone at the zone's weakest rock strength can win; strength only changes how fast. One fight per geode. Personal enemy for each player.
- You can't die. If you lose, you get launched away. Far enough above the zone's strength, the enemy runs away from you.
- 2 geode looks per zone, based on the zone's rocks, purely visual.
- Base remodel: hatch pads in front, a fenced pen on a platform at the back where Pets hop around. The central pit goes.
- 8 hatch pads, none to buy. 8 best Pets earn, paid straight into your account.
- Finished geodes wait until you open them. Skip wait is one dev product, 9 R$ per geode, no skip-all.
- Pets stay through rebirth. 4 geodes out per zone.
- Removed: chop-quality luck, pity, Auto Open (nobody owned the pass). Kept: [[Geode Fall]].

## Claude's drafts the user agreed to
40 clicks at the gate, 15 s limit, enemy flees at 25x the weakest rock, sell value 15 s, Legendary and Secret odds x1.2, rebirth multiplier on all cash, Wild Geodes removed, weakest-rock gate for zones 6-10 (replacing the second-rock gate in `World1Plan.md`). Geode `Price` stays as a hidden value so [[Cash Packs]] keep working.

## Numbers after the Balance Model pass (user, 2026-11-03)
A flat 2 min hatch and Pet x4 pushed Pets to 60-97% of income from the Desert on, because free geodes make a player's best 8 far better than the model's old fixed lineup. The user chose instead: hatch time 30 s, 2, 4, 5, 8, 11, 12, 15, 20, 27 min (Forest to Golem Ruins), Pet income x2, 1.5, 1.5, 1.25, 1, 1, 0.75, 0.75, 0.75, 0.75, offline rate 4%. Pets are 30-53% of income at the end of each zone ([[Balance Model]] v12, tab New Loop).

## Build status (2026-11-03)
On branch `claude/modest-mccarthy-6d6424`, passes check.ps1, never run in Play: `GeodeService` is hatch pads (`HatchPads`, `Opening`; `PlayerData.HatchPads[index] = { GeodeKey, ReadyAt }`), `PedestalService` pays Pet income to Cash every second and draws the 8 best Pets in the pen (`Display.RenderPen`, client `Components/PetHop` inside `IdlePet`). Pit, earnings pads, pity, chop luck, Auto Open server code and Wild Geodes are removed; old `PedestalEarnings` are paid into Cash in `Migrate`. `PedestalSlots` data and the name `PedestalService` stay for now. Geodes are placed by the pad's prompt and a Place All prompt on the path, not by holding a Tool as the plan first said.

Not done: the shop, tutorial rewrite and template swap wait for the side session branches (enemies, zone geodes, Robux) to be merged. This code needs `Model_BasePlot_New` to work: on the old template, geodes can't be opened and Pets don't show, though income still pays.

## Still open
- Which 2 of each zone's 3 rocks the geode looks are based on.
- A Secret takes about 2.5-5 hours of hatching per zone with no pity. Left as is; a playtest decides.

Related: [[Bases]], [[Pedestals]], [[Geode Shop]], [[Auto Open]], [[Wild Geode]], [[Tutorial]], [[Rock Spawning]], [[World 1 Plan]]
