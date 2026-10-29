# World 1 finish: zones 6-10 and the Golem boss: plan

Status: **approved 2026-10-29**. The user and Claude planned it together in chat; nothing is built yet. Nothing gets built until the plan is done, because each zone is mostly recoloured parts plus models (user, 2026-10-29). Numbers come from the existing rules, and every one is a *draft* to check against the [[Balance Model]] before building. Names follow [[Simple Names No Material Clash]] (no lava, magma, crystal, diamond, etc.), and Roks follow [[Roks Stay Rocks]]: a Bloky body and eyes, with the theme carried by props, hoods and markings.

## Read first
`AGENTS.md`, `Vault/Index.md`, and the vault notes `Zones After Desert`, `Zone Line`, `Rebirth Gated By Strength`, `Balance Pass Oct 18`, `Auras`, `Geode Shop`, `Diamond Rock`, `Geode Fall`. Skills: `new-zone`, `batch-model`, `rock-model`, `studify`, `vfx`, `studio-ui`.

## 1. Decisions

| # | Question | Decision |
| --- | --- | --- |
| W1 | Zones 6-10 | **Swamp → Savanna → Bamboo Forest → Volcano → Golem Ruins** (user, 2026-10-29). World 1 is somewhat realistic biomes. The Volcano sits last, right before the boss, and is allowed to be fantastical; Golem Ruins may use magic. Rejected: Autumn Woods, Cave, Mountains ("in a game filled with rocks"), Beach (it belongs before the Ocean), Canyon and Flower Meadow (too close to the Desert, or not picked). |
| W2 | Numbers | **Extend the existing rules** (user): rock strength x5 and pay x4 per tier, so the toughest rock grows x125 per zone. Geode strength is 5x the zone's First rock, and its price is 12.5x the First rock's payout. Rok income is the forest 1/2/5/12/30/150 times (First payout / 40). Odds shift upward each zone. Auras for zones 6-10 are already priced ([[Auras]]). **Balanced 2026-10-29 in the Balance Model v11 (tab Zones 6-10, every check passes):** Rok income x1.1 / 1.15 / 1.2 / 1.2 / 1.2 over the rule so pets stay 15-25% of income, and geode prices x6 / 8 / 10 / 12 / 13 so a Roks page takes 6.5-6.8 min and hatch-and-sell stays at 21-35% worst case. The tables below include both. |
| W3 | Training stands | **Meteor (R6) → Sun (R7) → Black Hole (R8) → Galaxy (R9)** (user), continuing on from Cosmic. **Balanced 2026-10-29** to training targets of 12 / 14 / 16 / 22 / 28 min (Swamp to Golem Ruins; the last two stretched so the Golem feels like a climax, user 2026-10-29; world 1 is about 4 h of active play): **Cosmic 1.4B per rep (was 5B, never tuned; it is the Swamp stand)**, Meteor 150B, Sun 15T, Black Hole 1.4Qa, Galaxy 130Qa. Training comes out at 12.1 / 13.7 / 16.6 / 21.5 / 28.1 min. Cash prices are about 4.5 min of income in the zone you buy them in: Meteor $190T, Sun $13.5Qa, Black Hole $970Qa, Galaxy $70Qi (at 4 min one max-stack chop could buy the next stand). |
| W4 | Map | No Baseplate limit. It only exists for the beta, so space is unlimited (user). Zones continue at 168 studs apart on +Z ([[Zone Line]]). |
| W5 | Savanna Roks | **Rock bodies with animal markings and props** (stripes, spots, mane, horns, ears), not animal-shaped bodies (user). |
| W6 | After the boss | **World 2** (user). |

## 2. The Golem boss (approved 2026-10-29)
- **Fight:** the Golem is a giant boulder golem. Glowing cracks open on it, and you walk up and chop them with the normal chop meter, where better quality does more damage. Every so often it slams the ground, and you step out of the shockwave ring. Other players can join, like the Diamond Rock.
- **Where and when:** in a round stone arena at the far end of Golem Ruins. **It's always awake, with no waiting** (user: "a player who needs to fight shouldn't have to wait at all"). Walking in starts a fight or joins the one already running, and its health scales with the number of players. A new fight can start as soon as one ends.
- **Gate:** strength at least the Statue Boulder's (zone 10's toughest rock, 745Qi), the same rule as a rebirth.
- **Length:** about 60-90 s solo at the gate strength (*draft*). Damage per chop is like the Diamond Rock's: chop quality times strength.
- **Getting hit:** knockback plus about 1 s stun. No dying and nothing lost.
- **First win:** opens the **world 2 portal**, and gives a badge, a big cash prize (*draft* ~10 min of Golem Ruins income, about $10Sx) and the exclusive **Golem Rok**.
- **Repeat wins:** you can fight any time, but loot (cash, *draft* ~2 min of Golem Ruins income, about $2Sx, plus about 2% Golem Rok) pays at most once every **~5 min per player**, with a "Loot ready in m:ss" readout. The first win each day pays double cash and has a bigger Golem Rok chance. Golem Rok pity: guaranteed after about 25 rewarded wins, with a progress bar.
- **Golem Rok:** a Bloky body with mossy golem armour plates and glowing eyes. Boss only, never from a geode. *Draft* $/s 8.1Qi, 2x Warpy.

## 3. Zones
Every zone gets what Jungle, Ocean and Snow got: a floor and terrace walls, an entrance sign, a spawn area, 3 chop rocks with splits and previews, 6 Roks, a geode, an Index page, decor, floor decor, an admin warp and a cannon. Colours are drafts. Each zone's six Roks share one body colour ([[Coloured Roks After Forest]]).

### 6. Swamp
Floor is murky dark green (~50, 70, 40). Decor is Stump, Mushroom and Bush reused, plus cattails, lily pads and dead bare trees. Roks are **moss green** (~120, 170, 30).

| Rock | Prop | Strength | Pays |
|---|---|---|---|
| Muddy Rock | mud drips and a few reeds | 122B | 53.7B |
| Reedy Boulder | a cattail clump and a lily pad | 610B | 215B |
| Rooty Boulder | gnarled dead-tree roots wrapped around it | 3.05T | 859B |

| Rarity | Rok | Look | $/s | Odds |
|---|---|---|---|---|
| Common | Mucky | plain, with mud drips | 1.48B | 40 |
| Uncommon | Lily | a lily pad hat with a pink flower | 2.95B | 25 |
| Rare | Froggy | a tiny frog sitting on its head | 7.38B | 18 |
| Epic | Snappy | a venus flytrap on top, jaws open | 17.7B | 12 |
| Legendary | Gator | a gator-head hood (like Chompy's shark hood) | 44.3B | 4.3 |
| Secret | Wispy | glowing swamp wisps floating around it | 221B | 0.7 |

Swamp Geode: needs 610B strength and costs 4.03T (x6, balanced 2026-10-29).

### 7. Savanna
Floor is straw-gold grass (~200, 175, 70), yellower than the Desert. Decor is flat-topped acacias, tall grass tufts and termite mounds. Roks are **terracotta** (~205, 95, 50).

| Rock | Prop | Strength | Pays |
|---|---|---|---|
| Grassy Rock | dry grass tufts | 15.3T | 3.44T |
| Acacia Boulder | a small acacia tree on top | 76.3T | 13.7T |
| Anthill Boulder | a termite-mound tower | 381T | 55T |

| Rarity | Rok | Look | $/s | Odds |
|---|---|---|---|---|
| Common | Stripy | zebra stripes | 98.8B | 38 |
| Uncommon | Spotty | giraffe spots and two horn nubs | 198B | 25 |
| Rare | Rhiny | a rhino horn on its nose | 494B | 19 |
| Epic | Tusky | elephant ears and tusks | 1.19T | 13 |
| Legendary | Cheety | cheetah spots and a glowing speed-streak trail | 2.96T | 4.2 |
| Secret | Leo | a big lion mane that glows gold | 14.8T | 0.8 |

Savanna Geode: needs 76.3T strength and costs 344T (x8).

### 8. Bamboo Forest
Floor is soft sage green (~120, 150, 90) with stepping-stone paths and low mist. Decor is tall lime bamboo clumps, shoots and mossy stones. Roks are **teal green** (~0, 170, 130).

| Rock | Prop | Strength | Pays |
|---|---|---|---|
| Shooty Rock | bamboo shoots poking out | 1.91Qa | 220T |
| Bamboo Boulder | a cluster of bamboo stalks | 9.54Qa | 880T |
| Pagoda Boulder | a tiny stone pagoda on top | 47.7Qa | 3.52Qa |

| Rarity | Rok | Look | $/s | Odds |
|---|---|---|---|---|
| Common | Shooty | one small bamboo shoot | 6.6T | 36 |
| Uncommon | Koi | two koi fish swimming round it in a water ring | 13.2T | 25 |
| Rare | Lotus | a pink lotus flower crown | 33T | 20 |
| Epic | Pandy | panda ears and eye patches | 79.2T | 14 |
| Legendary | Fluffy | red-panda ears and a striped tail | 198T | 4.1 |
| Secret | Sensei | a straw hat and long white beard, meditating afloat in a soft glow | 990T | 0.9 |

Bamboo Geode: needs 9.54Qa strength and costs 27.5Qa (x10).

### 9. Volcano (fantastical allowed)
Floor is near-black charcoal (~40, 35, 35) with glowing orange crack strips. Decor is smoking vents, charred trees and ash piles, plus an orange sky tint. Roks are **fire red** (~230, 40, 30). Rok names avoid the weather modifiers (Dusty, Windy, Toasty, Zappy, Eclipsed). Rare to Legendary is a dragon story (egg → wings → dragon), and Phoenix nods to rebirth.

| Rock | Prop | Strength | Pays |
|---|---|---|---|
| Smoky Rock | smoke curling from cracks | 238Qa | 14.1Qa |
| Ember Boulder | glowing orange cracks | 1.19Qi | 56.3Qa |
| Crater Boulder | a glowing crater on top, puffing smoke | 5.96Qi | 225Qa |

| Rarity | Rok | Look | $/s | Odds |
|---|---|---|---|---|
| Common | Smudge | soot smudges and a tiny smoke wisp | 422T | 34 |
| Uncommon | Impy | little devil horns and a pointy tail | 844T | 25 |
| Rare | Hatchy | sitting in a cracked spotted dragon egg | 2.11Qa | 21 |
| Epic | Wingy | small flapping dragon wings | 5.07Qa | 15 |
| Legendary | Dragy | a horned dragon-head hood that puffs fire | 12.7Qa | 4 |
| Secret | Phoenix | blazing gold-orange feather wings and tail, rising from ash | 63.3Qa | 1 |

Volcano Geode: needs 1.19Qi strength and costs 2.11Qi (x12).

### 10. Golem Ruins (magic allowed)
Floor is mossy grey-green stone tiles (~110, 115, 100). Decor is broken pillars, toppled statue heads, vines and glowing purple rune stones. The boss arena is a round courtyard at the far end. Roks are **rune purple** (~140, 60, 220).

| Rock | Prop | Strength | Pays |
|---|---|---|---|
| Rune Rock | glowing purple carved runes | 29.8Qi | 901Qa |
| Pillar Boulder | a broken column on top | 149Qi | 3.6Qi |
| Statue Boulder | a giant carved stone fist bursting out (sets the boss gate) | 745Qi | 14.4Qi |

| Rarity | Rok | Look | $/s | Odds |
|---|---|---|---|---|
| Common | Runey | one glowing rune on its front | 27Qa | 32 |
| Uncommon | Pillary | a tiny broken column as a hat | 54Qa | 25 |
| Rare | Wizzy | a tall pointy wizard hat with stars | 135Qa | 22 |
| Epic | Guardy | an ancient guard helmet with a plume, and a tiny shield | 324Qa | 16 |
| Legendary | Spelly | an open spellbook floating above it, pages flipping, with sparkles | 811Qa | 4 |
| Secret | Warpy | a swirling purple portal ring behind it, half stepping out, sparkles pulled in (hints at world 2) | 4.05Qi | 1 |

Ruins Geode: needs 149Qi strength and costs 146Qi (x13).

## 4. Still open (decide during the build, not blocking)
- Boss rewards (first-win cash, repeat loot, Golem Rok income) are drafts sized from Golem Ruins income, not modelled yet. Everything else is balanced in the Balance Model v11.
- The Golem's own look (a reference sheet via `model-workflow`) and its health, damage and shockwave timings.
- What rebirth 10 unlocks, if anything, alongside the world 2 portal.
- Each zone's reference sheets (the rocks and the six Roks) before modelling, one zone at a time as before.

## 5. Build order (when the user starts it)
Zone by zone, Swamp first: floor and walls → rocks → Roks → geode and Index page → decor → stand. The Golem boss comes after the Golem Ruins zone exists.
