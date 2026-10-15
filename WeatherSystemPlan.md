# Weather events and Rok modifiers: plan

Status: **approved 2026-10-14** (W1–W12 as recommended). Rules come from the Master Game Plan §05 (decided 2026-10-03 and 2026-10-14). Everything marked *draft* goes in config and gets tuned in playtesting.

## Read first
`AGENTS.md`, `Vault/Index.md`, `Chop_a_Rock_Master_Game_Plan.txt` §05 Random events, `PetBaseSystemPlan.md`, and the vault notes `Diamond Rock`, `Rush Rocks`, `Pedestals`, `Why The Game Looks Blue`, `High Saturation Colors`, `Simple Names No Material Clash`. Skills: `vfx`, `studio-ui`, `studio-playtest`.

## Already decided (not up for review)
- An event starts on every :00 and :30 (UTC), on every server, and lasts 15 minutes.
- Which event plays is a weighted roll: Sandstorm 35%, Hurricane 25%, Heat Wave 20%, Thunderstorm 15%, Eclipse 5%.
- Modifiers: Dusty x1.5, Windy x2, Toasty x2.5, Zappy x3, Eclipsed x5. Each multiplies the Rok's $/s.
- Each Rok on a pedestal has a 2% chance per minute to catch the event's modifier. A geode opened during an event has a 25% chance to hatch with the modifier.
- Each Rok has one modifier and keeps whichever is bigger. Modifiers and Roks persist through rebirth.
- During an event every rock takes on the weather's look and pays more chop money (*draft*: the event's multiplier).
- Weather spawns no special rocks and adds no event geodes.
- Each event gets sky, lighting, particles and sound, an announcement when it starts, and a HUD countdown to the next one.
- A modified Rok sells for 100 s of its multiplied income.

## 1. Decisions to approve

| # | Question | Recommendation | Why |
| --- | --- | --- | --- |
| W1 | What does the rock pay boost stack with? | Applies to **per-player rocks, including Rush rocks**, and stacks like Rush (before Hot Streak, friend, rebirth and Index). **Not the Diamond Rock.** | Same pattern as Rush. The Diamond Rock is already 15x and was cut once for paying too much. |
| W2 | Is x5 on rocks during an Eclipse too much? | Keep the rock boost **equal to the Rok multiplier** for now (Eclipse x5 chop money for 15 min, about once every 10 h). The rock boost is its own config value per event, so it can be cut without touching Roks. | A rare x5 window is the kind of moment that brings players online. Easy to tune. |
| W3 | How does a rock look in the weather? | Each rock gets that weather's **modifier particles** (the same ones a modified Rok wears: dust puffs, wind swirl, heat shimmer, sparks, purple stars), plus a light tint toward the weather colour. No outline. | One look per weather for both rocks and Roks teaches kids "Zappy = sparks". Highlights are capped at 31 per screen, so they can't be used on every rock. |
| W4 | How does a modified Rok look? | The modifier's particles on the Rok, plus a body tint for Toasty (rosy) and Eclipsed (purple). This applies to the pedestal Rok, the held tool, the hatch reveal and the Roks/Sell panels (ViewportFrames can't show particles, so those show the tint only). | Matches §05. |
| W5 | How is the modifier named? | The modifier word goes **before the Rok's name** in the modifier colour: "Zappy Bloky". Used on the tool name, the tooltip ("Zappy Bloky · $3/s"), the pedestal sign, the Roks and Sell panel rows and the hatch reveal (an extra line under the rarity). | The usual genre pattern; reads well for kids. |
| W6 | Catching a modifier | When a Rok catches one: a short effect on the pedestal for that weather (lightning bolt for Zappy, gust for Windy, and so on), and a notice for the owner: "Bloky caught Zappy! $1/s → $3/s". No notice when the roll loses to an existing bigger modifier. | Catching should feel like a win, even if you're away from your base. |
| W7 | Event start | Server-wide notice "A Thunderstorm is here! Roks can catch Zappy (x3)", with a sting sound. A 1-minute warning notice before it starts: "Thunderstorm in 1 minute". | Gives players a reason to stay online for the start. |
| W8 | HUD | A **weather pill at top centre**, below the teleport bar. During an event: icon, name and time left ("Thunderstorm 12:34") in the weather colour. Between events: "Next weather 14:02" in grey. It never says which event is next. When the Diamond Rock pill is up, both show, stacked. | §05 asks for a countdown. Keeping the next event hidden keeps the surprise. |
| W9 | World look per weather | Tween `Lighting` (`Atmosphere`, `ColorCorrection`, sky colours, `ClockTime`) over 4 s and back. All looks stay bright and saturated (§03). See section 2. | Reuses the lighting that's already tuned; restoring the saved values leaves no drift. |
| W10 | Offline | Modifiers are caught **only while you're in a server**. Offline pedestal income uses the multiplied rate. | §05: "being online during events is what pays". |
| W11 | Index tabs per modifier | **Not in this build.** The Index stays as it is. | Already deferred in the plan. |
| W12 | Admin | Commands: "Weather: Start" (pick an event), "Weather: End", "Weather: Next in 10 s", "Rok: Give Modifier" (held or chosen Rok). Studio-only presets can force an event. | Testing a 30-minute clock by hand is not workable. |

## 2. World looks (*drafts*, to tune in Studio)

| Event | Sky and light | Particles (around the camera) | Sound |
| --- | --- | --- | --- |
| Sandstorm | Warm orange haze (Atmosphere density up, orange tint) | Blowing sand streaks and dust puffs | Wind loop |
| Hurricane | Cool grey-blue, brighter than a real storm | Fast slanted rain, leaves and wind swirls | Strong wind and rain loop |
| Heat Wave | Bright, warm, saturated yellow-orange | Heat shimmer near the ground, floating embers | Low hum and cicadas |
| Thunderstorm | Deep blue, with rain | Rain; a lightning flash and bolt every 8–20 s, thunder after | Rain loop and thunder |
| Eclipse | Vivid purple sky, sun covered by a dark disc with a glowing ring, stars visible | Floating purple sparkles | Low choir drone |

Low Graphics drops the camera particles and keeps the lighting. Sounds are placeholders until you pick real ones; they follow the SFX volume setting.

## 3. Build outline

**Shared**
- `Config/WeatherConfig`: the clock (period 1800 s, length 900 s, warning 60 s), the event list (key, display name, weight, modifier, Rok multiplier, rock multiplier, colour, lighting values, sound keys), the catch chance and the hatch chance.
- `WeatherClock` (pure module): given a server time, returns the current event key, its start and end, and the next start. The event for each slot comes from `Random.new(slotIndex)`, so every server gets the same one without talking to the others. An admin override layer sits on top.

**Server**
- New `WeatherService`: runs the clock, sets `Workspace` attributes `Weather`, `WeatherEndsAt` and `NextWeatherAt` (the client reads these), sends the warning and start notices, and rolls catches once a minute for every placed Rok of every player in the server. Exposes `GetActive()`, `RockMultiplier()` and `RollHatchModifier()`.
- `RockService`: one line in the payout chain (`WeatherService:ApplyRockMultiplier`) next to Rush.
- `PetService`: `GetRate` multiplies by the modifier. `Grant` takes an optional modifier. `SetModifier` keeps the bigger multiplier, updates the tool, and fires a signal so `PedestalService` re-banks the slot at the new rate.
- `GeodeService/Cracking`: rolls the hatch modifier and passes it to `Grant`. `GeodeHatched` sends the modifier.
- `RokValue.Sell` and `Placement` (Equip Best) use the multiplied rate.
- `PedestalService/Display`: sets a `Modifier` attribute on the placed Rok; the tool gets one too.
- Admin commands from W12.

**Client**
- New `WeatherController`: lighting tweens, camera particles, sounds, lightning, and rock looks (adds modifier particles to every rock while an event is on).
- `Components/RokModifier` (reads the `Modifier` attribute): particles and tint on placed Roks and held tools; the catch effect.
- Name and colour changes on the `Pedestal` component, the `Roks`, `SellShop` and `HatchReveal` screens.
- New `WeatherPill` screen (built in Studio, house text style).

**Studio assets** (made with the `vfx` skill): `VFX_Modifier_<Name>` for each of the five, `VFX_Weather_<Event>` camera emitters, catch effects, the eclipse sun, lightning, and placeholder sounds. All registered in `AssetRegistry`.

**Docs**: vault `Systems/Weather` note, Index line, To Do, admin note.

## Order of work
1. Clock, config, service, notices, HUD pill, admin commands (testable without art).
2. Rok modifiers: catching, hatching, rate, sell, names.
3. Rock pay boost.
4. Art: world looks, then the modifier and catch effects. Each one gets a look from you before the next.

## Out of scope
Index tabs per modifier, non-weather random events, event geodes, special weather rocks, and Golden variants.

## Built (2026-10-14)
Steps 1–3 and a first art pass are done. Details are in the vault note `Systems/Weather`. Differences from the plan:
- Rocks get the modifier particles only, with no tint, because Rush paints rocks gold and fades back to their saved colour.
- The timer is a money-style row in the bottom-right corner (changed 2026-10-14 at the user's request), not a pill at the top.
- Every weather sound is an empty placeholder until the user picks one.
