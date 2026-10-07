# Rock spawning: plan

Status: **approved 2026-10-06 and built.** The user accepted every recommendation; logged in the Master Game Plan. Every number marked *draft* is a placeholder for playtesting and will live in config.

## Read first
`AGENTS.md`, `Vault/Index.md`, `Chop_a_Rock_Master_Game_Plan.txt` (§02 Loop details, §06 Main location, §08 Resource / spawning and Carried-over questions, Decision Log 2026-10-06 "Rocks spawn instead of being placed"), and the vault notes `Forest Rock Tiers`, `Rocks Look Like Boulders`, `Admin Panel`, `Index`. Skills: `studio-playtest`.

## Already decided (Master Game Plan, 2026-10-06)
- Each zone keeps a set number of rocks alive **per player** (draft 8-12). They rise out of the ground at a random clear spot inside the zone's spawn area.
- The spawn area is one or more rough, invisible boxes drawn in Studio. At server start the system samples points in them, finds the ground, drops steep slopes and spots where a tree, prop or building would overlap the rock, and keeps the rest as candidate spots.
- Spawns keep a minimum gap from the player's other rocks and never rise under the player.
- Each spawn rolls its type from the zone's weighted table. A broken rock is replaced at a new random spot after a short delay (draft 2s).
- Rocks are per-player and **invisible to other players**. Other players' chops still show their animation and effects (exact look proposed here, D7).
- The guide arrow points to the **nearest** rock of the kind the player should grind.
- An Admin panel toggle shows the candidate spots as dots.
- Rush Rocks, weather modifiers and the Diamond Rock come later. This build leaves room for them (D9) but doesn't build them.

## How it works today, and what changes
Today the three rocks are shared MeshParts placed by hand in `Workspace.Rocks`. The server owns their prompts, hides one while someone chops it, and plays the shake, chunks and split on the server so everyone sees them.

After this change:
- **Server** (`RockService`) keeps each player's rocks as data only: an id, kind, position and size. It picks spots, rolls kinds, validates every chop and pays out. It tells only that player's client when a rock spawns or goes away.
- **Client** builds each rock from a template, tags it `ChopRock` locally (so the existing rock labels keep working), runs the rise, the prompt, and the hit, crack and break effects.
- Because the client only creates the rock locally, other players can't see or bump into it.
- The three rocks in `Workspace.Rocks` become templates in `ReplicatedStorage.Assets.Models` (`Model_Rock_Basic`, `Model_Rock_Second`, `Model_Rock_Third`). Their split models are unchanged.

## 1. Decisions to approve

| # | Question | Recommendation | Why |
| --- | --- | --- | --- |
| D1 | How is the spawn area drawn? | Parts tagged `RockSpawnArea` with a `Zone` attribute (`"Forest"`), anywhere under the zone's model. Half-transparent blue in Studio; the game hides them at start. I draw a first box over the forest floor; you move or resize it and add more. | Same idea as the `BaseSpot` plates you already move by hand. |
| D2 | How many rocks, and of which kind? | **10 per player** in the forest (*draft*). Weights: **Stone 50, Boulder 30, Mossy Boulder 20** (*draft*), so about 5 / 3 / 2 at any time. | The plan's "rare Mossy" (e.g. 10%) would leave a player who's grinding Mossy with one rock on the map and a lot of walking. 20% keeps two around. |
| D3 | What counts as blocking a spot? | Only **collidable** parts block: tree trunks, stands, buildings, fences, other rocks. Grass, fallen leaves and other non-collidable decor don't. Spots on slopes steeper than **25°** (*draft*) are dropped. Each spot is checked per rock kind, so a small Stone can fit where a Mossy Boulder can't. | Grass covers most of the forest floor. If it blocked spots, almost nothing would be left. |
| D4 | Spacing | At least **8 studs** (*draft*) between the edges of a player's rocks. Never within **6 studs** (*draft*) of the player's own character. Other players don't matter, because they can't touch your rocks. | Keeps rocks from clumping and from rising into you. |
| D5 | The rise | The rock rises out of the ground over **0.6s** (*draft*) with a small dust puff and a low rumble sound. The Chop prompt and label appear once it's up. | The "rises from the ground" look the plan describes. Needs a dust and a rumble sound; placeholders until you have them. |
| D6 | Respawn | A broken rock's pieces clear as they do now. **2s** (*draft*) later a new rock rises at a new random spot. A crack (too weak) doesn't replace the rock. | As decided. |
| D7 | What other players see when you chop | Your **animation** (it already replicates), plus a small **dust burst and the hit sound** where your hand lands. On a break they see a **small chunk spray**, not the full split. No rock is shown. | Nobody looks like they're hitting thin air, without showing a rock they can't chop. The Master Chop announcement and camera stay as they are. |
| D8 | Guide arrow | Points to the **nearest** rock of the kind you should grind (or the shop, as now). If none of that kind is up, it points to the nearest rock you can break. | As decided, plus a fallback so the arrow never disappears. |
| D9 | Room for later rocks | Each spawned rock carries an empty `Modifier` field. Rush and weather fill it later; this build ignores it. | Rolling at spawn is why the plan chose spawning. |
| D10 | Admin toggle | **"Spawn Spots"** in the Admin panel shows every candidate spot for your zone as a small dot, coloured by the biggest rock that fits there (grey Stone, blue Boulder, green Mossy). Only you see them. | As decided. The colours show where the big rocks can go. |

## 2. Server checks (internal)
- A chop start sends the rock's id. The server checks that it's one of that player's rocks, that it's up, and that the player is within prompt range plus slack (*draft* 6 studs). The existing rate limits stay.
- Health stays per player, per session, and resets when the player leaves the rock, as now.
- Payout, the Index record, the Master Chop and the multiplier chain don't change.
- If the spawn area has fewer spots than needed, the server spawns as many as fit and warns in the output.

## 3. Build order
1. **Config:** `RockSpawnConfig` (count, weights per zone, gap, slope, rise time, respawn delay). Rock templates added to `AssetRegistry`.
2. **Studio:** move the three rocks into templates; draw the first forest `RockSpawnArea`; remove `Workspace.Rocks`.
3. **Server:** `RockService/SpawnPoints` (sampling) and `RockService/Spawner` (per-player rocks), new packets `RockSpawned` / `RockRemoved`. `ChopStart` takes the rock id instead of a prompt trigger.
4. **Client:** `RockController` builds rocks, the rise and the prompt. The hit, crack and break effects move from the server's `Effects` into it. `ChopController` takes a rock id. `ArrowTrail` picks the nearest rock.
5. **Others' effects (D7):** the server tells nearby players where a hit landed; they play the dust, sound and chunk spray.
6. **Admin:** "Spawn Spots" toggle.
7. **Playtest:** check with two players that each sees only their own rocks, chopping, cracking, breaking, the Master Chop, the guide arrow and labels.

## Not in this build
Rush Rocks, Hot Streak, weather modifiers, the Diamond Rock and other shared special rocks, more zones.
