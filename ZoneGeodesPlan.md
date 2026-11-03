# Zone geodes, enemies and the new base: plan

Status: **approved 2026-11-03**. The user and Claude planned this in chat. Nothing is built. The user accepted the numbers marked *draft* as starting points; they still get a Balance Model pass, and any change that pass suggests goes back to the user.

Written against `master` at 80c1bb6 plus the uncommitted 2026-11-03 work in the main checkout (rebirth at every rock, all 8 pedestals free, rebirth luck removed, Rush Rocks being removed). That work should be committed first, because this plan changes the same files.

## Read first
`AGENTS.md`, `Vault/Index.md`, and the vault notes `Bases`, `Pedestals`, `Geode Shop`, `Geode Fall`, `Wild Geode`, `Rock Spawning`, `Tutorial`, `Toolbar`, `Cash Packs`, `Balance Model`, `World 1 Plan`. Skills: `model-workflow`, `studio-ui`, `studify`, `new-zone`, `studio-playtest`.

## 1. Why
Playtesting on 2026-11-03 showed Pets earn far less than chopping and that cracking takes a long time. The user also wants the game closer to what already works on Roblox: "the entire game will progress in the zones". This reverses the 2026-10-29 choice in `Wild Geodes` to keep the shop.

## 2. The new loop
1. Train, then chop rocks in a zone for cash.
2. Go for a geode in the zone. If you're not far above the zone's strength, its enemy charges you.
3. Spam click to beat it. The geode is yours.
4. Take it home and place it on a hatch pad in the front of your base.
5. It hatches after a while and waits on the pad until you come back and open it.
6. Your 8 best Pets hop around the fenced pen at the back and pay straight into your account.

## 3. Decisions

| # | Topic | Decision | Source |
|---|---|---|---|
| D1 | Geode source | Geodes spawn in zones. The Geode Shop is removed. | User |
| D2 | Geode cost | Free: you just pick it up. | User |
| D3 | Geode looks | 2 geode looks per zone, based on that zone's rocks. Visual only: same odds, same Pets. | User |
| D4 | Enemy | One per zone, a scaled-up copy of the zone's Common Pet, based near the zone's centre. Ignores you unless you go for a geode. | User |
| D5 | Whose enemy | Personal: each player has their own. | User |
| D6 | Fights | One fight per geode. | User |
| D7 | Combat | Spam clicking. Damage comes from Strength, so strength only changes how fast you win. Anyone at the zone's weakest rock strength can win. | User |
| D8 | Losing | You can't die. Lose the fight and you get launched away. | User |
| D9 | Outgrowing a zone | Far enough above the zone's strength, the enemy runs away from you and you take the geode with no fight. | User |
| D10 | Hatching | Place a geode on a pad. It hatches on a timer, then waits until you open it. A dev product skips the wait. | User |
| D11 | Hatch pads | 8, all free. No buying more. | User |
| D12 | Earning Pets | 8 earn, with the best picked automatically. The rest stay in the bag. | User |
| D13 | Pet income | Paid straight into your account. No pads to step on. | User |
| D14 | Cracking | Gone, along with chop-quality luck and the central pit. | User |
| D15 | Pity | Removed. | User |
| D16 | Auto Open | Removed, not replaced. Nobody owns the pass yet. | User |
| D17 | Geode Fall | Kept. | User |
| D18 | Wild Geodes | Removed: built around cracking on the break, and overlaps with zone spawns. | Claude, user agreed |
| D19 | Later zones | Zones 6-10 use the same weakest-rock rule. `World1Plan.md` set their geode gate at the second rock, which this replaces. | Claude, user agreed |
| D20 | Rebirth | Pets stay through rebirth and keep paying. The rebirth multiplier applies to all cash, Pets included. | User (Pets stay); Claude, user agreed (multiplier) |
| D21 | Skip wait | One dev product at 9 R$ per geode. No skip-all option. | User |

## 4. Fight rules

| Rule | Value |
|---|---|
| Gate | Current Strength at least the zone's weakest rock. Below it the geode refuses you: "Get stronger!" |
| Enemy health | Weakest rock strength x 40, so 40 clicks at the gate *draft* |
| Time limit | 15 s, so about 3 clicks a second wins at the gate *draft*. Running out of time is how you lose. |
| Lose | Launched away, enemy goes home, geode stays. Try again straight away. |
| Walk or teleport away | Fight ends the same way, without the launch *draft*. |
| Clicks | Counted on the server, capped at about 15 a second *draft*, so an autoclicker is only as good as a very fast player. |
| Runs away | At 25x the zone's weakest rock, which is the zone's toughest rock *draft*. It flees when you come near and you take the geode. |
| Getting the geode | Only after the win, or once it has fled, so teleports and cannons can't dodge the fight. |

Rocks step up x5, so a fight takes 40 clicks at the first rock, 8 at the second and 2 just before the enemy starts to flee.

With rebirth at every rock, a player crosses this range over about 3 rebirths per zone. Rebirth resets Strength, so they retrain before fighting again.

The Golem keeps its approved plan (chop meter, weak spots, co-op), so the final boss feels like a step up from spam clicking.

## 5. Draft numbers

| Number | Draft | Why |
|---|---|---|
| Geodes out per zone | 4 per player (user), new one 30 s after a pickup | Enough to find one quickly. Hatch pads are the real limit. |
| Hatch time | 2 min, the same in every zone | 8 pads gives up to 240 Pets an hour. Fast manual cracking is about 450-700. |
| Tutorial's first hatch | 5 s | Must not stall the first minutes. |
| Timer while offline | Keeps running | A reason to come back. |
| Pet income | x4 on every Pet | Pets were about 15% of income in the 2026-10-18 model. x4 takes them near 40%. To check in the model. |
| Sell value | 15 s of income (was 60) | With x4 income, a Pet sells for the same money as today. Selling is now pure profit, so this must not rise with income. |
| Legendary and Secret odds | x1.2 | Replaces lost chop luck and pity. Simulated Forest with pity gave 1.32% Legendary+ against 1.1% base. |
| Luck pass and boosts | Stay, applied when you open | Saving ready geodes for a luck boost becomes a small trick for players. |
| Skip wait dev product | 9 R$ per geode, no skip-all (user) | The same price as a Lucky Geode. |
| Offline income | Unchanged: 12.5%, 2 h cap, paid on join | Shown on the Welcome Back card. |

Hatch odds roll when you open the geode, not when you place it.

## 6. Base remodel (Blender, `model-workflow`)
`Model_BasePlot` stays on its 64 x 64 footprint, with the entrance at local -Z.
- **Front:** 8 hatch pads, each with a spot for a geode and a label for its timer or "Ready!".
- **Back:** a fenced raised platform where the 8 earning Pets hop around.
- **Removed:** the pit, all pedestals and all earnings pads.
- **Kept:** training stand and upgrade sign, `BaseSpawn`, owner sign.

Pet motion stays client-side, building on `Components/IdlePet`: hops, turning, pausing, bumping each other. Pets stay inside the fence and are skipped when far from the camera. The plot must keep the `Atomic` and remount rules in the `Pedestals` gotchas.

## 7. Map (Studio, all 10 zones)
- Each zone gets a clear ring near its centre for the enemy and geodes, marked by a tagged part like `RockSpawnArea`.
- Rock spawning skips that ring. Rock strips by distance from `ZoneEntrance` stay as they are.
- Teleport points and cannon landings stay out of the ring.
- The user will probably change zone layouts for this, so the marker is a part they can move.

## 8. Models and art
- **Enemies:** existing Common Pets scaled up: Bloky, Pointy, Roly, Drip, Hexy, then the Common Pet of zones 6-10 as those are built. No new meshes, but code-driven charge, slam, stagger and flee motion.
- **Geodes:** 2 looks x 10 zones = 20 geode models. Reuses the geode mesh with shells taken from the zone's rock colours and props. Each zone has 3 rocks, so the user picks which 2, or Claude drafts them. Split models are dropped: `SplitModelKey` is only declared in `GeodeConfig` and no other code reads it.
- **Effects:** launch, enemy defeat, enemy flee, pad "Ready!" glow, through the `vfx` skill.

## 9. Code

**New**
- `EnemyService` (server): one enemy state per player per zone, health, click counting, time limit, win, lose, flee. Sends state to that player only, like rocks. `EnemyConfig` holds the numbers.
- `EnemyController` (client): draws the enemy and its motion, fight input on mouse, touch and gamepad, health bar screen. Other players within 150 studs get dust and sound, as with `RockChopShown`.
- Zone geode spawning, sharing `RockService`'s spot sampling and area reservation.
- Hatch pad logic, replacing most of `GeodeService`. `PlayerData.HatchPads[slot] = { GeodeKey, Look, ReadyAt }`.

**Changed**
- `PedestalService` becomes the pen: `Placement.EquipBest` runs automatically, slots are invisible, `Earnings` pays `AdjustCash` once a second. Cash analytics are grouped so they don't log every second.
- `Cracking.Finish` becomes open-at-pad, keeping weather modifiers, Index, announcements and the reveal at the pad.
- Geodes in the bag follow the Toolbar's Tool pattern. Holding one shows "Place" on empty pads, and a Place All button fills them. Bag rule stays: Pets + unplaced geodes + geodes on pads at most Backpack size.
- `GeodeConfig`: `Price` stays as a hidden value so `CashPack`, `OfferService`, `FreeGiftService` and gifts keep working. Adds `Looks` for each zone. Odds and pity changes go here too.
- Lucky Geodes move to the Robux shop, with odds shown before buying. Geodes bought with Robux hatch without the wait *draft*.
- `GeodeStand` keeps only its odds view, opened from a hatch pad, for the odds display.
- `HatchReveal`: loses the pity stamp.
- Tutorial: Train, Chop, Get Geode (first fight), Place, Open, then done. Forced first Pet stays. Chop now has no cash goal for a geode, so it needs a new one *draft: break 3 Stones*. Funnel steps renumber, and `Targets`, `Locks`, `Spotlight` and `Teleports` follow.
- Admin: new commands for fights and pads, and old ones removed (Next Hatch stays, Pity and Wild go).
- `MonetizationConfig` and `RobuxShopConfig`: Auto Open removed, and VIP's `Includes` updated.

**Removed**
- Auto Open: `GeodeService/AutoOpen`, `AutoOpenConfig`, `Screens/AutoOpenButton`, its packets.
- Pity: `HatchPity`, `GeodeConfig` thresholds, `PlayerData.Pity`, shop bars, admin commands.
- Wild Geodes: `GeodeService/Wild`, `WildGeodeConfig`, admin commands.
- Shop and pit: `GeodeService/Purchasing` buying, `GeodePicker`, `BuyGeode` and `SelectGeode` packets, `Luck` chop bonus, `Tutorial.GeodeCost`, Geode teleport option, shop pad and stall.
- Pads: `PadCollected`, `PadSoundController`, the `CashPopController` pad parts, `PedestalService.Collected`, `ClearEarnings`, the +1 Slot button.

**Save migration** (adds a `SchemaVersion` step, never resets progress)
- Uncollected `PedestalEarnings` are paid into Cash.
- Unopened geodes stay in the bag, placeable.
- `Pity`, `SelectedGeode` and `PedestalSlots` are dropped.
- Tutorial steps 3-5 map onto the new steps.

## 10. User steps
- Take the Auto Open game pass (2053686145) off sale.
- Confirm the skip-wait dev product before Claude creates it with the Open Cloud key.
- Model approval through `model-workflow` for the base and geodes.
- Zone layout changes in Studio.
- Playtest.

## 11. Build order
1. Commit the 2026-11-03 work and sync this branch with `master`.
2. Balance Model new version with sections 4 and 5. Numbers get approved here.
3. Base remodel and ring markers, so the rest has a place to test in.
4. Hatch pads, the pen and direct income, testing with admin-granted geodes. Remove pads, pit and pity.
5. Zone geodes with free pickup, then remove the shop and Wild Geodes.
6. Enemies and fights.
7. Tutorial, Lucky Geodes, dev products, Auto Open removal.
8. Migration test on an old save, then a full playtest from a fresh profile.

## 12. Vault updates when built
Rewrite `Bases`, `Pedestals`, `Geode Shop` (retire), `Tutorial`. Retire `Auto Open`, `Wild Geode`. Add `Zone Enemies`, `Hatch Pads`, and a dated decision note. Update `Balance Model`, `Cash Packs`, `To Do`, `World 1 Plan`, and the `Index`.
