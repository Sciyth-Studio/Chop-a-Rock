# Rok inventory, pedestal income and base management: plan

Status: **approved 2026-10-06.** The user accepted every recommendation; logged in the Master Game Plan. Every number marked *draft* is a placeholder for playtesting and will live in config.

## Read first
`AGENTS.md`, `Vault/Index.md`, `Chop_a_Rock_Master_Game_Plan.txt` (§03 Pet rocks, §07 Pet rocks / Offline income / Rebirth), `GeodeSystemPlan.md`, and the vault notes `Base Plot Reference`, `Menu Panel Style`, `Hatch Reveal Reference`, `Index`. Skills: `studio-ui`, `studio-playtest`.

## What the user asked for (2026-10-06)
1. **Rok inventory is the Roblox Backpack.** Each Rok is a Tool, as in popular games of the genre.
2. **Pets give flat money per second**, not a money multiplier (too many multiplier sources already). Prices go up to absorb the extra money.
3. **Base management:** place Roks on base pedestals by hand, or **Equip Best** to fill them automatically. The reference panel shows "1/7 Active", "+1 Equip [$1M]", a row per placed pet ("Bird ($19/s)" + Unequip) and an Equip Best button.

## Decided items this overturns (Master Game Plan)
- 2026-10-03 "Every pet has one stat, a money multiplier" → every pet has one stat, **money per second**.
- §07 "Equipped: a limited number follow the player and boost gains; the rest sit on pedestals" → Roks earn **only on pedestals**. See D1.
- Weather modifiers "multiply that pet's money boost" and are caught by "equipped pets out in the weather" → they multiply the Rok's $/s and are caught by Roks **on pedestals** (the base is outdoors).
- The planned Bag screen is replaced by the Backpack plus the management panel.

## 1. Decisions to approve

| # | Question | Recommendation | Why |
| --- | --- | --- | --- |
| D1 | Do Roks still follow the player? | **No.** A Rok earns only on a pedestal. Holding its tool shows it in your hand, and that's the only way it travels with you. | Following pets only made sense as a multiplier. With flat $/s, pedestals are where the value is, and one system is easier for kids to understand. |
| D2 | One Tool per Rok, or stacks? | **One Tool per Rok** (cap stays 100). Tools can't stack, and each Rok can carry its own trait or modifier. The tool's name is the Rok's name; its tooltip shows "$1/s". | Matches the genre. 100 tools fit in the Backpack's grid, which has a search box. |
| D3 | Hotbar icons | Render a square icon per Rok, upload it, and set it as the tool's `TextureId`. The name shows as text until the icons exist. | The hotbar can only show uploaded images, not ViewportFrames. |
| D4 | Placing by hand | Hold a Rok and walk up to an empty unlocked pedestal on **your own** base. A "Place" prompt puts it on top and removes the tool. A placed Rok has a "Pick up" prompt that returns its tool. | The usual pattern; no new UI. |
| D5 | Starting slots and slot prices | **3 of 8** pedestals unlocked at the start. The rest are bought in order: 4th **$1,000**, 5th **$4,000**, 6th **$15,000**, 7th **$60,000**, 8th **$250,000** (*drafts*, ~4x each). A locked pedestal shows a lock and its price, and its prompt buys it. | Slots become the money sink that limits passive income. 8 is the plot's physical limit until rebirth floors. |
| D6 | How is the money paid? | **It builds up on each pedestal's green pad** (the pad shows the amount) and is **collected by stepping on the pad**. | That's what the pads in the approved base design are for. It gives players a reason to come home, and other visitors can see your earnings. Alternative: straight into the wallet every second. |
| D7 | Offline earnings | Pads keep filling while offline, at **50%** of the live rate (*draft*), capped at the existing **4 hours**. No popup: the pads show it when you come back. | At full rate, a typical forest setup (~$25/s) would pay $360,000 in 4 hours, more than every forest arm combined. Half rate keeps "playing beats idling" and is still a strong reason to return. |
| D8 | Do other multipliers apply to pet income? | **No.** Rebirth cash, the Index +10% and the friend boost apply to chop money only. Only weather modifiers (later) multiply a Rok's $/s. | "Bloky $1/s" should mean exactly $1/s. That fixes the "too many multipliers" problem. |
| D9 | Panel | The **Bag menu button becomes "Roks"** and opens the panel from anywhere: header "3/8 Placed" with a "+1 Slot [$1,000]" button, one row per placed Rok (icon, "Bloky ($1/s)", Unequip), and a big green **Equip Best** button. House panel style. Unequip sends the tool back to the Backpack. | Matches the reference. Opening it anywhere saves a trip home. Placing still needs the walk-up. |
| D10 | Equip Best | Fills every unlocked slot with your highest-$/s Roks. It swaps out a weaker placed Rok if a better one is in the Backpack. | What kids expect from the button. |
| D11 | Holding a Rok while chopping | Starting a chop, a training round or a geode crack **puts away** the held tool automatically. | Both use the right arm, and the chop animation would clash with the tool grip. |
| D12 | Hotbar vs EXP bar | Both sit at bottom centre. **Move the EXP bar up** above the hotbar. | The hotbar's position is fixed by Roblox. |
| D13 | Deleting Roks (needed now: a full bag blocks buying) — **replaced 2026-10-06 by the Sell Shop** (vault: Systems/Sell Shop) | While holding a Rok, a small red **Delete** button shows on screen. It asks "Delete Bloky?" before deleting. Placed Roks can't be deleted. | The Backpack has no delete. This keeps delete next to the item it acts on. |
| D14 | Traits (speed, luck, training) | Count only while the Rok is placed. If several placed Roks have the same trait, only the strongest one counts. Still no effect until their systems are hooked up. | Same rule as income. Stops 8 luck Roks stacking. |
| D15 | Rebirth | Placed Roks stay. Whether bought slots reset stays [OPEN]; config flag `ResetPedestalSlots`, default off. | Pets persist through rebirth (decided). |

## 2. Economy drafts

Rough forest chop income, from the current configs (~2.4 s per chop, payout split across hits): early Stone **~$4–10/s**, Boulder **~$20–50/s**, late Mossy Boulder **~$90–300/s**.

**Rok income (forest, *drafts*):**

| Rok | Rarity | Odds | $/s |
| --- | --- | --- | --- |
| Bloky | Common | 60% | **1** |
| Sprout | Uncommon | 25% | **2** |
| Shroomy | Rare | 10% | **5** |
| Nesty | Epic | 3.9% | **12** |
| Berry | Legendary | 1% | **30** |
| Treebo | Secret | 0.1% | **150** |

The average geode is worth ~$2.50/s. A typical full base late in the forest earns ~$20–30/s, about 10–25% of active chopping, so playing always pays more than idling. A Legendary is a big jump ($30/s from one Rok), and a Secret is huge.

**Price increases (*drafts*):**
- Forest geode **$250 → $500**. At $250, the average Rok pays for its geode in under 2 minutes, which would make spamming geodes beat buying arms.
- Arms **x1.5**: Wood $300, Stone $2,400, Iron $19,200, Crystal $153,600. The 8x ratio between tiers is unchanged.
- Rock payouts unchanged.

After approval, I'll re-run the zone 1 pacing estimate with these numbers before treating them as final.

## 3. Build outline

**Data** (`PlayerData`, with `Validate`, `Template` and a migration if needed): each pet record gains `Slot: number?`. New fields: `PedestalSlots` (default 3) and `PedestalEarnings` (uncollected money per slot). Earnings build up on a server timer, using server time. Offline earnings are added on join from `LastSeenAt`.

**Server**
- `PetService`: keeps one Tool per unplaced Rok in the Backpack, rebuilt from data on every spawn. Each Tool has a `PetId` attribute and a handle welded to a scaled clone of the Rok's model. It also handles delete.
- New `PedestalService` (folder: `Placement`, `Earnings`, `Slots`): place, pick up, Equip Best, buy slot, collect on pad touch, the per-second earnings tick, and the Rok model and pad displays on the owner's `BasePlot.Pedestals`. Prompts are handled on the server.
- `RockService`/`TrainingService`/`GeodeService` aren't touched. D11 is client-side: the chop and crack start calls `Humanoid:UnequipTools()`.
- Packets: `UnequipPet(slot)`, `EquipBest()`, `BuyPedestalSlot()`, `DeletePet(petId)`, all rate limited.

**Client**
- `Roks` screen (the panel, built in Studio) wired to the Bag/Roks menu button. The pad and pedestal billboards are a client component reading pedestal attributes, so visitors see them too.
- `HatchReveal` and `Index` show "$X/s" instead of the multiplier.
- The Delete button while holding a Rok, and the EXP bar moved up.
- Rok hotbar icons: an asset step (render + upload) for the user.

**Docs:** update the Master Game Plan (§03, §07, Decision Log) and add a vault `Systems/Pedestals` note.

## Built (2026-10-06)
Everything in section 3 is in, except hotbar icons. Those come from the item-icon pipeline in `IconSystemPlan.md`, so ids aren't kept in two places. Details are in the vault note `Systems/Pedestals`.

## Out of scope
Rebirth floors, weather modifiers (rates leave a hook), Golden fusion, desert pets and their rates, and trait effects.
