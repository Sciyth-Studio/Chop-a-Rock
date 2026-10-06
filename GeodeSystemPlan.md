# Geode purchase + crack: plan

Status: **approved 2026-10-04.** The user accepted every recommendation in section 1, and they're logged in the Master Game Plan. Stand UI settled the same day: prompt + centred modal, no subtitle line. Every number marked *draft* is a placeholder for playtesting, kept in config.

## Read first
`AGENTS.md`, `Vault/Index.md`, `Chop_a_Rock_Master_Game_Plan.txt` (§00, §03 Pet rocks, §07 Luck / Rarities / Rewards / Rebirth), and the vault notes `Geode Reference`, `Geode Stand Reference`, `Geode Stand UI Reference`, `Base Plot Reference`, `Bloky Reference`, `Menu Panel Style`, `ViewportFrame Gotchas`. Skills: `studio-ui`, `studio-playtest`.

## What is already decided (do not change)
- Geodes are bought with money only, never Robux. One stand per zone; same stand model everywhere.
- Each geode tier has a strength requirement and a money price. Further-out geodes have better odds.
- Geodes are **inventory items**. They are cracked in the **crack pit at the player's base**, not at the stand, using the **chop meter**.
- Timing quality gives a **modest luck bonus** to the hatch roll. Being far stronger than the geode makes the meter all-Perfect, but the geode's own odds table caps its rarity.
- The geode splits into two halves, crystals inside take a rarity colour, the pet is shown on screen, then goes to the inventory.
- Rarities: Common, Uncommon, Rare, Epic, Legendary, Secret. Each has its own high-saturation colour. Secret triggers a server-wide announcement.
- Forest geode holds six Roks: Bloky / Sprout / Shroomy / Nesty / Berry / Treebo. Draft odds 60 / 25 / 10 / 4 / 1 + tiny Secret. Stands show the odds as a pet preview.
- Luck sources: crack timing, a permanent bonus per rebirth, the pet luck trait, and one permanent 2x Luck gamepass. The gamepass cannot lift a geode past its own cap, and the stand shows odds with and without it.
- Every pet has one stat, a money multiplier. Epic and up can also roll one trait (walk speed, luck or training speed).
- Pets and the index persist through rebirth. Duplicates are kept or deleted; there is no selling.
- Assets in Studio: `Model_Geode_Basic`, `Model_GeodeSplit_Basic` (shells + `Geode_CrystalsA/B`), `Model_GeodeStand`, `Model_BasePlot` (with the sunken crack pit), and all six forest `Model_Rok_*`.

## 1. Decisions (all approved as recommended, 2026-10-04)

| # | Question | Recommendation | Why |
| --- | --- | --- | --- |
| D1 | **Base plots don't exist in code yet**, and the pit is in the base. Build a minimal plot system first? | Yes: a small `BaseService` that gives each player a free `BasePlot` on join and frees it on leave. No pedestals, Home button or floors yet. | Cracking can't happen anywhere else without overturning the "crack at base" decision. |
| D2 | How many chops to crack a geode? | **One chop.** The single release's quality sets the timing bonus, then it opens. | Hatches in this genre take ~3 seconds; several rounds would make hatching a chore. One chop is still a skill moment. |
| D3 | Where is the strength requirement enforced? | **At the stand** (Buy is locked: "Need 10 strength"), **and again at the pit**. If too weak at the pit, the geode "clinks", is kept and shows "Get stronger!". | Rebirth resets strength, so a player can hold a geode they are now too weak for. |
| D4 | How does luck change the odds? | Luck **multiplies the chance of Rare and above** (Rare, Epic, Legendary, Secret). Common and Uncommon shrink to fit and keep their ratio. Rarities with 0% stay 0%, which is the cap. If lucky rarities would pass 90% in total, they're scaled down to 90%. | Kids can read it: "2x Luck: Legendary 1% → 2%". Each lucky chance really doubles. |
| D5 | How do luck sources combine? | `Luck = (1 + timing + rebirths × bonus + pet luck trait) × (2 if gamepass)`. Drafts: timing Perfect +0.25 / Great +0.15 / Good +0.05 / Mid and Bad 0; +0.1 per rebirth. | Bonuses add up and the gamepass doubles everything, so "2x" stays true. |
| D6 | Can a geode crack become a **Master Chop**? | Yes. It plays the full Master cinematic and gives a big luck bonus (draft +1.0). | It's the "skill feeds both axes" hook and it reuses the existing cinematic. |
| D7 | Crystal colour inside the split geode | **The hatched pet's rarity colour.** It shows as the halves open, before the pet card. | Gives the reveal a payoff beat. A per-zone colour would never change, since the forest has only one geode. |
| D8 | Buy amounts | **Buy 1** and **Buy 3** (Buy 3 shows only when affordable). No multi-crack at the pit yet. | Saves trips to the stand. Opening several at once is a common monetisation hook, so it waits for §10. |
| D9 | Do unopened geodes survive rebirth? | **Kept.** | Losing bought items feels bad at 6–12. Banking cash in geodes before rebirth is a harmless trick. |
| D10 | Pet storage cap | **Draft 100 pets.** When full, Buy and crack are blocked with "Bag full! Delete some Roks". | A cap stops the data from growing without limit. The Bag screen (with delete) has to follow soon after. |
| D11 | Epic+ trait roll at hatch | 25% chance (*draft*) for Epic and up to roll one trait, picked evenly from the three. Trait values are *drafts* and have no effect until their systems exist. | The roll happens at hatch, so this system has to store it even though equip comes later. |
| D12 | What the stand shows for Secret | A dark silhouette, "???" and its odds. The silhouette reveals once the player has hatched it. | Standard genre mystery. The odds stay visible because the odds are always shown. |
| D13 | Announcements | Secret goes to the **whole server**. Legendary gets a big local reveal only. | Matches the decided Secret rule without spamming chat. |
| D14 | After buying, how do players find the pit? | The existing guide arrow trail points to their pit while they hold unopened geodes. A "Crack it at your base!" notification shows on the first purchase. | The base is out of sight of the stand, and the guide system already exists. |

| D15 | Reveal animation (the user's idea) | The geode's possible Roks flash by in the hollow as silhouettes (`Highlight`: black fill, white outline), slowing down until they settle on the hatched one. | Slot-machine suspense; it also shows what you *could* have got. |

Approved drafts (all *[PLAYTEST]*, in config):
- Forest geode: price **250** (near the 200 Wood arm price), strength **10**.
- Rarity colours: Common 170,170,170 · Uncommon 0,220,60 · Rare 0,140,255 · Epic 170,0,255 · Legendary 255,180,0 · Secret 255,0,150 with a rainbow gradient on labels.
- Forest odds by pet: Bloky 60 · Sprout 25 · Shroomy 10 · Nesty 3.9 · Berry 1 · Treebo 0.1.
- Pet money multipliers (shown on the reveal card, used later by equip and pedestals): 1.1 / 1.25 / 1.5 / 2 / 3 / 5.

Out of scope here (later systems): equip and follow, pedestals and offline income, the Bag screen, the Index screen, weather modifiers (a hook is left in), random size variation (a leaning only), tutorial free geode ([PROPOSED]), multi-crack / auto-crack, and the gamepass itself (hook only; check Roblox's paid-random-item policy first).

## 2. Player flow

1. **Stand** (forest zone): a `Geode` ProximityPrompt (like the Arm Shop's) opens the **GeodeStand** screen, a **centred modal** with a close X (decided 2026-10-04). Layout comes from [[Geode Stand UI Reference]]; style is the house panel style, Sky blue.
   - **Header:** the geode's name ("Forest Geode") in Chrome style, plus the close X.
   - **No subtitle line** (the user rejected "You have 2 · crack them at your base"). The first-buy toast and the guide arrow tell players where to crack, and the pit prompt shows how many geodes are left.
   - **3 x 2 grid of Rok cards.** Each card has the odds % top-left, the Rok in a ViewportFrame in the middle and its name along the bottom. The card's colour glow is the rarity colour. An undiscovered Secret shows a black silhouette, "???" and its %.
   - **2x Luck odds:** a small gold "2x Luck" toggle above the grid swaps every % to the gamepass odds (shown gold) and back. That covers "odds with and without" without putting two numbers on every card for a 6-year-old.
   - **Two big buttons:** **Buy 1** and **Buy 3**, each showing the price with the money icon. Green when affordable, grey when too poor. Both turn into one grey "Need 10 Strength" bar when the player is too weak, and "Bag full!" when storage is full. No key hints: E is the prompt key and would clash, and the Arm Shop has none.
2. **Buy** → server checks money, strength and bag space, then takes the money and adds the geodes in one write. Money delta animation, "+1 Geode" toast, guide arrow switches to the base pit.
3. **Pit** (own base only): prompt "Crack" → closed geode appears in the pit, visible to everyone → player snaps to the pit edge, camera frames the geode, chop meter opens. The meter always uses the base zone sizes (`GeodeConfig.ZoneStrengthRatio = 1`, changed 2026-10-06): strength never widens Perfect or raises the Master chance on geodes, so the timing luck bonus stays a skill check.
4. **Release** → server classifies the timing, rolls Master, works out luck, rolls the pet, takes 1 geode and adds the pet in one write.
5. **Reveal** (*draft* timings, in config):
   1. **Hit:** the existing hit feel (slow-mo, shake, flash). The closed geode swaps to the split model and the halves slide apart. Crystals stay dim white.
   2. **Shuffle (~2 s, longer for rarer results):** the geode's six Roks take turns standing in the hollow as silhouettes (`Highlight`: FillColor black, FillTransparency 0, OutlineColor white). Each swap has a tick sound and a little scale pop. Swaps start every ~0.07 s and ease out to ~0.45 s, then the last swap is the hatched Rok. The order is random with no immediate repeats, and the Secret can appear in the shuffle.
   3. **Settle:** after a short hold (~0.4 s), the silhouette fades off (Fill and Outline tween to transparent). The crystals light up in the rarity colour with a burst and the rarity sound.
   4. **Show:** the Rok rises out of the hollow and turns to the camera. A **HatchReveal** card shows name, rarity, money multiplier, a "NEW!" badge if it's a first in the index, and the trait if one rolled.
   5. **Done:** tap or wait 2.5 s → the card closes, the Rok flies toward the Bag button, the halves fade and the pit clears.
6. If they hold more geodes, the prompt shows "Crack (2 left)". Secret: server-wide "{name} hatched a SECRET Treebo!"
7. **Visitors** in the base see the same world animation (split, shuffle, settle, rise) but get no camera move or card.


## 3. Architecture

### Config (`src/shared/Config`, frozen)
- `RarityConfig`: ordered list `Common … Secret`. Each entry has `DisplayName`, `Color`, `TextStyle`, `IsLucky` (Rare+), `Announce` (Secret), `ShuffleSeconds` (rarer = longer suspense), `SoundKey`. Shuffle timings (start and end swap interval, settle hold) also live here.
- `PetConfig`: `Pets[PetKey]` = `DisplayName`, `Rarity`, `ModelKey` (`Model_Rok_Bloky` …), `MoneyMultiplier`. Plus `MaxPets`, `TraitChance`, and `Traits` (key, display name, draft value range).
- `GeodeConfig`: `Geodes[GeodeKey]` = `DisplayName`, `Price`, `StrengthRequired`, `ModelKey`, `SplitModelKey`, `Pets = { {PetKey, Weight} }`, `BuyAmounts = {1, 3}`.
- `LuckConfig`: `TimingBonusByQuality`, `MasterBonus`, `PerRebirthBonus`, `LuckyShareCap` (0.9), `GamepassId` (nil until made), `GamepassMultiplier` (2).

### Shared pure module
- `src/shared/HatchOdds.luau`, a sibling of `ChopZones` (same precedent: game-specific pure logic both sides need).
  - `HatchOdds.Chances(geodeKey, luck) → { {PetKey, Chance} }` applies D4. The stand UI uses it for the "normal" and "2x Luck" columns.
  - `HatchOdds.Roll(random, geodeKey, luck) → PetKey`. Only the server calls it.

### Player data (`src/server/Data/PlayerData.luau`: update `Data`, `Template` and `Validate` together; `Reconcile` fills old profiles, so no schema bump)
- `Geodes: { [string]: number }`: unopened count per geode key.
- `Pets: { [string]: Pet }`, keyed by string id (a dictionary, so deletes never leave array gaps for Replica).
  `Pet = { Key: string, HatchedAt: number, Trait: string?, TraitValue: number?, Modifier: string? }`.
  Equip and pedestal fields are added by their own systems later.
- `NextPetId: number`.
- `Index: { Pets: { [string]: number } }`: hatch count per pet key (first hatch = "NEW!"). Rocks are added to the index later.

### Server systems
- **`BaseService`** (new, D1): tag `BasePlot` on plot models; claim a free plot on `PlayerLoaded`, set attribute `OwnerUserId`, release on `PlayerReleasing`. `GetPlot(player)`, `GetCrackSpot(player)` (the authored `GeodeSpot` attachment in the pit).
- **`PetService`** (new, small for now): owns `Pets`, `NextPetId` and `Index.Pets`. `CanAdd(player, count)`, `Grant(player, petKey, roll)` → id. Equip and pedestals grow here later.
- **`GeodeService`** (new, folder):
  - `init.luau`: stand prompts (tag `GeodeStand`, attribute `GeodeKey`), pit prompts, packet binding, crack sessions, cleanup.
  - `Purchasing.luau`: validate key, amount, strength, cash and bag space; `SetValues` for cash and geode count together.
  - `Cracking.luau`: session start/release, timing via `ChopZones`, Master roll, luck total, roll, consume + grant in one frame (no yield between them).
  - `Luck.luau`: sums the sources. Reads `RebirthService`, the cached gamepass flag, and later the pet trait through `PetService`.
  - `Effects.luau`: puts the closed geode in the pit when a crack starts (replicated, so visitors see it) and removes it at hatch. The rest of the reveal runs on clients (see `HatchController`), because a server-driven shuffle of fast swaps and tweens would replicate jerkily.
  - `Types.luau`.
  - Register after `RockService` and `PetService`. Add `RockService:HasSession(player)` so a crack can't start mid-chop, and refuse while training.

### Networking (`Packets.luau`, all rate-limited)
- `GeodeStandOpen(GeodeKey)` server → client, fired by the stand prompt, like `ShopOpen`.
- `BuyGeode(GeodeKey, Amount: U8) → Boolean8`, `RateLimit(5, 1)`.
- Crack reuses the chop packets: the server sends `ChopMinigameStart` with the geode part, and `GeodeService` also listens to `ChopRelease` / `ChopLeave`. `RockService` already ignores players without a rock session, so the two never clash.
- `GeodeHatched(Owner: Player, Spot: Attachment, PetKey, Rarity: U8, IsNew: Boolean8, Trait: String)` server → **all clients**. Every client plays the world reveal at `Spot`; only the owner also gets the camera and card.
- Data shown in UI (geode counts, pets, index) comes from Replica, not packets.

### Client
- `ChopController`: no rewrite. Check that its snap and camera maths work for a 6-stud geode in a sunken pit. If not, add optional `ChopCameraOffset` / `ChopSnapOffset` attributes on the target part (one small, contained change).
- **`HatchController`** (new, non-UI, folder): handles `GeodeHatched`. Per-frame camera and world animation belong in a controller, not a screen.
  - `Shuffle.luau`: clones the geode's Rok models from `AssetRegistry`, scaled to fit the hollow. It shows one at a time under a single reused `Highlight` (move its `Adornee`; there's a client limit of 31 Highlights). Swap intervals ease from the start interval to the end interval over `ShuffleSeconds`, and the last swap is the result.
  - `Reveal.luau`: split halves sliding apart, crystal tint, silhouette fade-out, burst, Rok rise and turn, fly-to-Bag, cleanup.
  - `init.luau`: owner-only camera framing (reuses the chop camera position) and opens `HatchReveal` at the show step.
- `PromptController`: hide pit prompts whose plot `OwnerUserId` isn't the local player.
- `GuideController`: add the "own pit" target while `Geodes` has any count.
- Screens (built in Studio first, house panel style, **Sky blue** panel to match the stand sign):
  - `GeodeStand`: centred modal; header with close X, 3 x 2 Rok card grid (ViewportFrames built at runtime from `GeodeConfig`, so new geodes need no UI work), 2x Luck toggle, Buy 1 / Buy 3. Odds come from `HatchOdds.Chances` at luck 1 and at the gamepass multiplier. Copy the header, close button and button fills from `StarterGui.Rebirth` / `Shop` and recolour to Sky blue.
  - `HatchReveal`: non-modal card, rarity-coloured burst behind the name, "NEW!" badge.

### Assets (AssetRegistry keys; placeholders until the user supplies them)
- `SFX_Geode_Crack`, `SFX_Hatch_Tick` (shuffle swap), `SFX_Hatch_Common` … `SFX_Hatch_Secret` (or one sound pitched by rarity), `VFX_Hatch_Burst` (tinted by code).
- Studio authoring: a `GeodeSpot` attachment at the pit centre of `Model_BasePlot`, a `GeodeStand` tag + `GeodeKey` attribute on the forest stand, and a `BasePlot` tag on the plot.

## 4. Build order (each step ends playtestable)

1. **Decisions:** ✅ approved and logged 2026-10-04. Stand UI: prompt + centred modal, no subtitle line.
2. **Config + odds:** `RarityConfig`, `PetConfig`, `GeodeConfig`, `LuckConfig`, `HatchOdds`. Check: in Studio, roll 100,000 times per luck value (1, 1.25, 2, 4, 10) and compare to `Chances`; confirm the 90% cap and that a 0% rarity stays 0%. ✅ 2026-10-04: every pet's observed rate within 1.6 standard deviations of its chance at luck 0.5 / 1 / 1.25 / 2 / 4 / 10. Luck 10 caps Rare+ at 90%; luck below 1 is treated as 1; an unknown geode gives no chances and no roll. Note for tuning: from luck ~3.4 up (e.g. gamepass + Master crack), Shroomy (Rare) becomes more likely than Bloky.
3. **Data + PetService:** new fields, `Validate`, `Grant`, index count. Check: grant through the dev panel and watch the replica update on the client. ✅ 2026-10-04: Ctrl+Shift+P (Studio only, `DevGrantPet`) grants a Rok rolled from the forest geode at luck 1. Granted ids 1–4 (Bloky new, Sprout new, Bloky not new); after a Play restart the next grant was id 5 and Sprout was not new, so the existing profile loaded, validated and kept the new fields. No client errors from the real `ReplicaClient`. Not yet tested: the 100-pet cap, and a trait roll (needs an Epic+ hatch). Ctrl+Shift+Backspace now also clears geodes, pets and index.
4. **BaseService:** claim and release, `OwnerUserId`, `GeodeSpot` lookup. Check with a 2-player local server: each gets a different plot, or a clean refusal when there are more players than plots. ✅ 2026-10-04 (solo Play; the MCP can't start a 2-player server): claims `Workspace.BasePlot` on join (`OwnerUserId` set). A cloned second plot is added unowned. Removing the owned plot's tag moves the owner to the free plot and clears the old attribute. Re-tagging and deleting the clone moves them back. Not tested: two real players, and the "No free BasePlot" warning. `GeodeSpot` placed on the pit surface (flush with the floor, so the sunken-pit risk in section 5 doesn't apply).
5. **Purchasing:** stand prompt + `BuyGeode`, then the `GeodeStand` screen in Studio and `Screens/GeodeStand.luau`. Check every button state (affordable, poor, weak, bag full), Buy 3, and money and geode count updating together. ✅ 2026-10-04:
   - Prompt opens the modal with 6 cards (correct models, odds and a Treebo silhouette).
   - Weak (0 strength): grey "NEED 10 STRENGTH" bar. Poor: grey Buy 1, centred. With 1,000 cash: both green.
   - Buy 3 → 250 left, Buy 3 hidden. Buy 1 → 0, grey.
   - Server refuses: too poor, amount 2, unknown geode.
   - 2x Luck toggle, clicked with real mouse input: odds go gold with the gamepass values (Bloky 49.4% … Treebo 0.2%).
   - Not tested: the "BAG FULL!" state (needs 100 pets) and the first-buy "Crack it at your base!" toast (notifications weren't checked).
   - Dev key Ctrl+Shift+C (+1,000 cash) added for testing. The stand is tagged `GeodeStand` with `GeodeKey = Forest` on `Workspace["Geode Stand"].GeodeStand`.
6. **Cracking:** pit prompt, session, chop meter on the geode, too-weak clink, Master path, consume + grant. Check: leaving mid-crack keeps the geode, the visitor can't crack, a forced Master works (admin "Next Chop: Master"), and there are no double grants when spamming release. ✅ 2026-10-04:
   - **Pit:** a hidden `PitGeode` (Persistent streaming) is prepared in each claimed pit and only shown during a crack. Creating it at crack time raced streaming: the client got a nil part and errored.
   - **Prompt:** `CrackPrompt` on `GeodeSpot`, tagged `OwnedPrompt`. The client component enables it only for the plot owner while `Active`. Text: "Crack (N left)".
   - **Camera:** the chop meter's player and camera offsets now follow the target's facing when the part has the `ChopRelative` attribute (only the pit geode). The player stands on the walkway side.
   - **Tested:**
     - Good crack: luck 1.05, one geode used, a Rok granted.
     - Three quick releases: only one crack.
     - Leave mid-crack: geode kept.
     - Forced Master: quality 6, luck 2.0. The pit stays locked through the cinematic (reopens about 4.5 s after the release).
     - Too weak (after a data reset): "Get stronger! Need 10 Strength", geode kept.
     - Prompt hides when `OwnerUserId` isn't the local player.
   - **Not tested:** a real second player at your pit (the server also checks ownership), and the server-wide Secret announcement.
   - **Placeholder until step 7:** a "You got X (Rarity)!" notification. `GeodeHatched` is already sent to all clients.
   - Admin command "+1 Geode" (Ctrl+Shift+G) added.
7. **Reveal:** ✅ first version 2026-10-04 (split halves + silhouette shuffle in the hollow + card). **Redone 2026-10-06** from the user's reference ([[Hatch Reveal Reference]]). The user chose: drop the shuffle, pop in a flash, grow in rarity steps.
   - **World (every client, from `GeodeHatched`):**
     - The closed geode lifts 4 studs over 0.5 s, spinning slowly, then turns white (a `Highlight` fades in).
     - It swells one step per rarity (+15% each), glowing each rarity's colour in turn with a wobble, and stops at the Rok's rarity: a Common takes 1 step, a Secret all 6.
     - After a short shake it pops: the model vanishes and a burst plays in the rarity colour.
     - Timings are in `HatchRevealConfig`. `HatchTiming.RevealSeconds` gives the server and client the same length. It drives the pit lock and the Secret announcement, which lands at the pop.
   - **Owner extras:**
     - Character hidden and movement locked; camera 14 studs out and 7 up, looking at the hover height.
     - Screen flash and the rarity sound at the pop.
     - Full-screen `HatchReveal` over a blur and shade: big name (Chrome), rarity label (rarity colour, rainbow on Secret), base odds % (Gold), tilted "New!" (Green), the Rok in a ViewportFrame on spinning rays tinted by rarity, the money icon with "xN" (Green), the trait if rolled, and "Click/Tap to continue".
     - The HUD, level bar and menu buttons are hidden while it's open. It closes on a click, after 10 s, or when a new chop starts.
   - **Seen on screen:** the hover glow mid-growth (Epic step), the Secret Treebo screen, the Common Bloky screen with the HUD hidden.
   - **Checked by values:** hover height 2.1 → 6.1; six colour steps to scale 1.9; pop then screen. After a click or the timeout: camera Custom, walk speed 16, character visible, blur gone, HUD back.
   - **Not tested:** a second player watching; the phone layout.
   - **Placeholders:**
     - Sounds `SFX_Hatch_Step` and `SFX_Hatch_<Rarity>` are missing (silent, one warning each).
     - `VFX_Hatch_Burst` is a simple sparkle.
     - 2026-10-06: the rays are now the user's sunburst image (`HatchRevealConfig.RaysImage`). The geode spin speeds up from 180 to 900 degrees per second over the reveal, with a 1 s spin-up after whitening (Secret about 6.8 turns, Common about 3).
     - `GeodeConfig.SplitModelKey` and the split model's crystals are no longer used by the reveal.
   - Admin command "Next Hatch: Secret" (Ctrl+Shift+H).
8. **Luck sources:** rebirth bonus, gamepass hook (off), timing and Master bonuses. Check: the luck value printed per crack matches the formula.
9. **Polish:** guide arrow to the pit, first-buy toast, sounds, phone layout. Write a vault `Systems/Geodes` note.

## 5. Risks and gotchas
- **Atomic grant:** take the geode and add the pet with no yield in between, so one save holds both. Never roll before the release arrives (re-rolling by leaving must be impossible).
- **Re-roll exploit:** the roll happens only on the server at release; the client never sees the odds result before committing.
- **Pit geometry:** the pit is sunken, and `ChopController` snaps the player to `rock bottom + root height`. The player may end up standing *in* the pit, so verify in step 6.
- **Import axis:** in `BasePlot` the pit ended up on Roblox −Z. Place `GeodeSpot` by looking at the parts, not by assuming.
- **Split model scale:** `SplitModel.Spawn` scales by `part.Size.X`. The geode split needs its crystals coloured separately, and must not inherit the shell colour/material the way rock pieces do. `Effects` handles the geode split itself instead of calling `SplitModel.Spawn` unchanged.
- **Rok fit:** each Rok must fit the 3.8 x 3.7 x 3.5 hollow; scale at reveal if a model is bigger. The shuffle swaps models of different heights, so pivot each at the hollow floor (Roks already pivot at bottom centre).
- **Highlight look:** use `DepthMode = Occluded` so the silhouette doesn't show through the shell halves. Check the white outline still reads against the white crystals; if it doesn't, tint the crystals darker during the shuffle.
- **No spoilers:** clients learn the result when `GeodeHatched` arrives, after the server has already granted the pet, so knowing it early changes nothing.
- **Rate limits:** debounce Buy and the pit prompt on the client so normal use never hits the limit.
- **Policy:** paid luck on random items for under-13s. Check Roblox's current policy before turning on the gamepass hook.
