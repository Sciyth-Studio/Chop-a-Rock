---
description: 2026-11-10 research on how other games schedule world bosses (cooldowns, fixed tables, weekly rotations, boosted windows, weekend events, caps), what players dislike, and what fits a day-of-week boss idea for Chop a Rock. Not approved, not built.
type: reference
---
# World boss research (2026-11-10)

The user asked whether world bosses could drive D7 ([[Target 90th Percentile]]), for example certain bosses being much more likely on certain days of the week. Sources are mostly wikis, guides and forums, not studio data. No source measured retention effects.

## How other games schedule bosses
| Pattern | Example | How it works |
|---|---|---|
| **Per-player cooldown after a kill** | Bee Swarm Simulator (Roblox) | King Beetle about 24 h, Tunnel Bear 48 h, Stump Snail 96 h, Commando Chick 30 min. The timer starts when *you* kill it, so "come back tomorrow" works in every time zone. A dev post credits it with next-day returns. |
| **Fixed public table** | Guild Wars 2 megaservers | Every boss at the same times every day on every server, one starting each hour and half hour, with a 24 h table in game. Chosen so players know when and where. Critique: a timetable makes villains feel scheduled. |
| **Random or opaque timer** | Diablo 4 world bosses | Roughly every 3.5-6 h. Players found it hard to plan around, built trackers, and asked for a fixed schedule. The pattern to avoid. |
| **Weekly rotation** | Destiny 2 featured raid and dungeon | Rotates at the Tuesday reset; one big reward per week from the featured one, normal loot always farmable; any one returns within 4 weeks. |
| **Boosted window** | Pokémon GO Raid Hour | Raid bosses rotate weekly; every Wednesday 6-7 pm local, 5-star raids are far more common. Concentrates play into one known slot. |
| **Weekend event** | Clash of Clans Raid Weekend; Roblox: Steal a Brainrot Taco Tuesday and Admin Abuse, Dragon Adventures Friday boss | Fixed weekly days, and the only source of its currency (Raid Medals). Why weekends was not stated by any source. |
| **Daily vs weekly value, capped** | MapleStory | Daily bosses pay small and often; weekly bosses pay much more; a weekly cap on boss income. |

## What players dislike
- Fixed short timers feel like "an on-call job": a few minutes late means missing it (WoW community events every 90 min).
- FOMO rewards make logging in an obligation. Accepted when the event is light and comes back later.
- Unpredictable spawns (Diablo 4). Asked-for fix: a visible countdown per boss.
- Hud's Guide: D7 comes mainly from the core loop and content, not from rewards; rewards don't help if players don't like the game.

## What fits Chop a Rock
- **Every boss is always fightable; the day only boosts it.** A "boss of the day" gets much better spawn odds and a better drop, like Raid Hour. This respects the [[World 1 Plan]] rule that no progression milestone waits on a timer.
- **A per-player daily first-kill bonus, not a global spawn time.** Like Bee Swarm, it works in every time zone and suits kids who can't play at a set hour. The Golem already plans a ~5 min per-player repeat-loot cooldown.
- **Use the player's local day, or show one clear countdown.** A UTC day flips mid-afternoon or evening for many players. Show "today's boss" and "changes in 4 h" on the [[Event Clock]] HUD (the [[Launch Checklist]] already wants "next event in" timers).
- **A weekly capstone with slack.** A chest for beating, for example, 5 of the 7 daily bosses that week (Destiny's once-a-week reward; the guide's strong day-7 reward), so missing one day doesn't kill the streak.
- **One co-op weekend boss.** A bigger shared fight Friday to Sunday, when kids play most (the reason is an assumption). Co-op was the guide's example of 98th-percentile D7.
- **Drops that matter but don't gate:** boss-only Pets, an Index page per boss, cosmetics. Not stand or zone requirements.
- Avoid: random hidden spawns, short windows, and rewards that only exist on one day with no rerun.

## Sources
[Bee Swarm boss timers](https://bee-swarm-simulator.fandom.com/wiki/Mobs), [Bringing players back (Roblox dev blog)](https://medium.com/roblox-developer/from-the-devs-a-glance-aat-tools-you-can-employ-to-bring-players-back-to-your-game-by-e04a80f56c5), [GW2 megaserver world bosses](https://www.guildwars2.com/en/news/the-megaserver-system-world-bosses-and-events/), [Diablo 4 world boss timing complaints](https://sportskeeda.com/mmo/250-world-boss-kills-diablo-4-players-react-unpredictable-world-boss-spawn-timings), [Destiny 2 rotator](https://gamespot.com/articles/old-destiny-2-raids-and-dungeons-will-be-worth-revisiting-next-season-in-a-new-weekly-rotation/1100-6502493/), [Pokémon GO weekly plan](https://doctorpokegogo.com/pokemon-go-weekly-plan-september-7-13-2026/), [Clash of Clans Raid Weekends](https://mobilematters.gg/clash-of-clans/raid-weekends-explained), [Steal a Brainrot Admin Abuse](https://www.sportskeeda.com/roblox-news/when-next-steal-brainrot-admin-abuse), [MapleStory boss crystals](https://www.digitaltq.com/maplestory-boss-crystal-calculator), [Time-limited events debate](https://massivelyop.com/2016/12/01/massively-overthinking-time-limited-events-in-mmorpgs/), [WoW timed events critique](https://finalboss.io/wows-time-gated-story-raids-are-broken-and).

Related: [[Fight Tension Research]], [[Zone Enemies]], [[Diamond Rock]]

**2026-11-10:** draft plan written: `WorldBossPlan.md` (four bosses plus the Diamond Rock on the boss clock, today's boss weighted, boss Pets with pity, a weekly Boss Chest for 3 different bosses). Not approved.

**2026-11-10 (user):** the Diamond Rock stays on the boss clock alongside the bosses. Fight mechanics drafted in `WorldBossPlan.md` section 4: chop 3 glowing weak spots (one gold x2) that crack and move, dodge Stomp circles, a Shockwave ring (jump) and one Big Attack (green safe circles) at 50%, a 6 s "Finish it!" at 10%; 2 s warnings, no loss when hit, a dodge gives x1.5 on the next chop. Not approved.

## Round 2 (2026-11-10): admin abuse, and fighting while locked in place
User answers: four bosses plus the Diamond Rock is good scope; the user mixes the boss themes; weekend Mega boss "maybe"; Boss Chest contents wait on the user's reference game. The user pointed out the first fight draft ignored that the chop minigame locks you in place ([[Chop Minigame]], [[Movement Lock]]).

**Admin abuse:** the Roblox name for a live event where developers join servers and switch on boosts and spawns normal play never has. Saturday is the usual slot (Adopt Me 9 am PT, Carve Wood 1 pm ET, +1 Venom Evolution 9 am ET; Steal a Brainrot Tuesdays and Saturdays). The 2025-08-23 Grow a Garden vs Steal a Brainrot "Admin Abuse War" helped Roblox reach about 47M concurrent players. Critics: short-term spikes, players learn to come only for the event. No source said why Saturday (likely no school).

**Locked-in fights elsewhere:** Undertale/Deltarune alternate an attack timing bar with a separate dodge turn (grazes build meter). Pokémon GO raids: stand still, tap to attack, swipe to dodge a flagged move; Niantic widened the window so any swipe between the warning and the hit counts. Punch-Out, Expedition 33, Sekiro, Hi-Fi Rush: block or parry on a readable cue, music carries timing. Fisch's Megalodon is just the normal reel minigame made harder (faster, erratic), no dodging. Dredge: monsters strike during the fishing minigame, warned by vibration and screen distortion.

**Result:** `WorldBossPlan.md` section 4 rewritten: every 4th chop round is a Block round (shield and shrinking ring on the bar, press chop; 1.0 s window, perfect ±0.12 s counter-hits, a miss skips one round); signature moves change the bar (Chomp moves the zone, Shell Hide needs Great+, Frost hides parts of the bar); the only walking is one Big Attack at 50% (green safe circles). Weekend Mega boss proposed as a Saturday admin-abuse slot. Not approved.

Sources: [Admin abuse and long-term effects](https://beebom.com/admin-abuse-might-save-dying-roblox-games-but-hurts-them-in-the-long-run/amp/), [Admin Abuse War record](https://www.tubefilter.com/2025/08/25/roblox-grow-garden-steal-brainrot-admin-war-record/amp/), [Adopt Me Saturday admin abuse](https://allthings.how/roblox-adopt-me-admin-abuse-on-november-29-2025-rewards-timing-and-past-drops), [Steal a Brainrot schedule](https://www.sportskeeda.com/roblox-news/when-next-steal-brainrot-admin-abuse), [Undertale battle design](https://gamedeveloper.com/design/game-design-deep-dive-i-undertale-i-s-action-based-rpg-battles), [Deltarune review](https://www.rpgfan.com/review/deltarune-chapters-12/), [Pokémon GO dodge fix](https://pokemongohub.net/post/news/dodging-in-raids-finally-fixed-heres-how-to-dodge-with-the-new-mechanic/), [Parries in Sekiro and Expedition 33](https://www.pcgamer.com/games/action/mag-407-why-i-love-the-parries-and-timed-blocks-of-sekiro-nine-sols-and-clair-obscur-expedition-33), [Fisch Megalodon](https://progameguides.com/roblox/fisch-megalodon-event-guide/), [Dredge monsters during fishing](https://steamcommunity.com/app/1562430/discussions/0/3826413850809174851).

**2026-11-10 (user):** the Block-round fight in `WorldBossPlan.md` section 4 is approved ("Yes, that fits"). The rest of the plan is still a draft; the weekend Mega boss and the Boss Chest contents are open.

**2026-11-10 (user):** the weekend Mega boss is deferred until the game is released. Until then three bosses: Croc Mon/Thu, Crab Tue/Fri, Yeti Wed/Sat, Sunday a mix day (drafts). Listed under Deferred in [[To Do]].

**2026-11-10 (user):** bosses can damage players and take HP, and get mad at half HP. Plan 4.8: 100 fight HP as 5 hearts (not `Humanoid.Health`), knocked out at 0 for 5 s, back at the arena gate, nothing lost. Plan 4.9: boss bar from [[Boss Health Bar Reference]].

**2026-11-10 (user):** a boss is a proper server event like the reference: 4:00 to get it to half health, then the timer resets to 5:00. Plan 4.2 now has two timed halves (up to 9:30 with the 30 s sleep, fits the 15-min boss clock), a Stomp Wave at 75%, Big Attacks at 50% and 25%, health that grows as players join, win credit at 3% of your share, and boss cash per minute about equal to chopping rocks.

**2026-11-10 (user):** boss cash is 1.25x chopping rocks per minute. Balance Model v18: pay per boss chop round 2.10x a rock round; session income boost 5-11%, every zone passes.
