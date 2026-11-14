# World bosses: plan

Status: **approved by the user 2026-11-11** ("Approve it"); numbers in 4.11 stay drafts for playtests, the Boss Chest reward pool is still open (section 7). Drafted 2026-11-10. User answers 2026-11-10: four bosses plus the Diamond Rock is the right scope (three until release, since the Mega boss is deferred); the user picks and mixes the boss themes; the weekend Mega boss is **deferred until the game is released** (user, 2026-11-10; see 3.5); Boss Chest contents wait on the user's reference game; the Diamond Rock stays on the boss clock. Section 4 was rewritten the same day because the chop minigame locks you in place, and the user approved it ("Yes, that fits"). Then the user added: bosses damage players and take HP, they get mad at half HP, the boss bar follows their reference (4.8, 4.9), and a fight is a long server event: 4:00 to half health, then 5:00 (4.2). Written from the vault notes `World Boss Research` and `Target 90th Percentile` to help D7 retention. Players are about **10 years old**, so every choice is checked against that (section 2). All numbers are drafts for the Balance Model.

## Read first
`AGENTS.md`, `Vault/Index.md`, and the vault notes `World Boss Research`, `Event Clock`, `Boss Arena`, `Diamond Rock`, `Chop Minigame`, `Zone Enemies`, `Fight Tension Research`, `Kid Friendly Pass`, `World 1 Plan` (the Golem), `Balance Model`. Skills: `model-workflow`, `vfx`, `studio-ui`.

## 1. The idea in one line
A few big, goofy bosses take turns in the Boss Arena behind the lobby. Every boss can show up any day, but each one has **its own day** when it shows up much more often and drops its Pet more often. Beating different bosses during the week fills a **Boss Chest**.

## 2. Built for a 10-year-old
| Rule | Why | What it means here |
|---|---|---|
| **No reading a schedule** | Kids don't plan by weekday or time zone | No weekday names. A strip of 7 boss faces with today's lit up, and one countdown: "New boss in 3h". |
| **Never punish missing a day** | Kids can't pick when they play (school, parents, devices) | No streaks that reset. The Boss Chest counts *different bosses beaten this week*, any days. Pet pity carries over forever. |
| **Everyone can help** | A "too weak" crack in front of friends feels bad | No strength gate, like the arena Diamond Rock: health and pay scale with each player's best zone. |
| **One button** | Kids already know the chop button | Chopping and blocking both use the chop button. No new keys, no walking while the bar is up. |
| **Drop in, drop out** | A boss is a proper server event that takes a while (user: up to 4:00 to half health, then 5:00 more), longer than a kid's attention | Join any time with the **Go** button, leave any time, and keep the cash from every hit. Rewards need only some damage, not the whole fight (4.7). Something new happens about every minute (4.2). |
| **Hurt, but nothing lost** | The user wants real stakes (bosses take HP); losing loot makes kids quit | Bosses take your HP (4.8). At 0 HP you're knocked out for 5 s and come back at the arena gate with full HP. No cash lost, and your damage share stays. A boss that runs out of time just leaves; everyone still gets paid for their hits. |
| **Funny, not scary** | Under-13 audience | Huge, silly creatures with big eyes, in the Bloky style. No gore, no horror. |
| **Rewards they can show** | Kids value things friends can see | Each boss drops its own **boss Pet** that follows you, a badge, and big cash numbers. |
| **No Robux to take part** | Fairness and Roblox rules for kids | Fighting, drops and the chest are free. No paid boss summons and no paid random boss drops. |
| **Few words** | Reading level | Notices follow the Kid Friendly Pass: "Big Croc is here!", "Block!", "+1 Croc Pet!", "Boss Chest 2/3". |

## 3. How it works

### 3.1 When and where
- **Boss clock** (`EventClockConfig`, every 15 min at :02:30) already runs the Diamond Rock in the arena. It becomes a weighted roll of the bosses **plus** the Diamond Rock (user: the Diamond Rock stays).
- **Today's boss** gets most of the weight. Draft: today's boss 55%, Diamond Rock 20%, the other bosses share 25%. Never the same event twice in a row (already a clock rule).
- **The day** is the UTC day, the same for every server. Players never see "Tuesday", only today's face lit up on the strip and a countdown to the next one.
- The boss timer tile (bottom right) shows the next boss's face, as it does for the Diamond Rock. While a boss fight is running, the tile shows the boss's face, its health and the time left, with a **Go** button.
- **Fits the 15-min clock:** a boss takes at most 30 s asleep + 4:00 + 5:00 = 9:30, so it always ends before the next slot. The Diamond Rock keeps its own 90 s.

### 3.2 The fight
See section 4. In short: chop the boss's glowing weak spots with the normal chop bar, and when the boss attacks, the bar turns into a **Block!** prompt you answer with the same button.

### 3.3 Rewards
- **Cash** per hit, like the Diamond Rock, at **1.25x the cash per minute of chopping rocks in your best zone** (user, 2026-11-10; section 5), plus a **win bonus** of about 2 min of that income.
- **First win each day:** double cash and "Daily boss win!" (any boss, per player, UTC day).
- **Boss Pet:** each boss has one. Chance per win 5%, **10% on its own day**. Guaranteed on your 10th win of that boss, with a progress bar on the boss's label ("Croc Pet 7/10"). Its income scales with your best zone (about that zone's Epic), so it never breaks the Pets-share target the way King Rex does. Boss Pets have their own Index page.
- **Boss Chest (weekly):** beat 3 different bosses this week (the Diamond Rock doesn't count). **Opening (user, 2026-11-11):** it opens like an egg hatch: the chest shows as a black silhouette with an outline that grows, then pops open and gives the player **one reward**. What that reward can be is still open (section 7). Resets Monday 00:00 UTC; a chest earned but not opened stays.
- **Badge** for each boss's first win, and one for collecting every boss Pet.

### 3.4 The bosses (user picks and mixes the themes)
Four bosses plus the Diamond Rock (user: good scope for now). Three at launch: the Mega boss waits until after release. The themes below are placeholders; the user will mix them up. Each boss's signature move is a change to the chop bar (4.5), so a new boss is a model, a palette and one bar effect.

| Day | Boss (placeholder) | Signature move (4.5) | Pet |
|---|---|---|---|
| Mon, Thu | Big Croc | Chomp: the Good zone jumps each round | Croc Pet |
| Tue, Fri | Boulder Crab | Shell Hide: only Great and better do damage | Crab Pet |
| Wed, Sat | Frost Yeti | Frost: patches of ice cover parts of the bar | Yeti Pet |
| Sun | Mix day: no boss of the day, the three share the weight | | |
| (after release) | Mega boss, deferred (3.5) | Two attacks in a row, bigger health, 2x cash | Mega Pet |

The Golem stays separate: it lives in Golem Ruins, it is always awake, and it opens World 2. It is never on the boss clock. The user may re-add a small Golem arena in the Ruins (2026-11-11, not decided).

### 3.5 The weekend and "admin abuse" (deferred until release)
**Deferred (user, 2026-11-10): no Mega boss until the game is released.** Until then the weekend uses the three bosses (Yeti on Saturday, a mix day on Sunday). The notes below stay for when it comes back.
"Admin abuse" is the Roblox name for a live event where the developers join servers and switch on boosts and spawns that never happen in normal play. Saturday is the usual slot: Adopt Me (Saturdays 9 am PT), Carve Wood (Saturdays 1 pm ET), +1 Venom Evolution (Saturdays 9 am ET); Steal a Brainrot runs Tuesdays and Saturdays. On 2025-08-23 the Grow a Garden vs Steal a Brainrot "Admin Abuse War" helped take Roblox to about 47M concurrent players. Critics say they lift player counts short-term but can train players to show up only for the event.
- **So the weekend Mega boss could be our admin abuse slot:** a fixed Saturday time (draft: Saturday 17:00 UTC, which is 12 pm ET and 9 am PT) where the Mega boss is forced on every server, Pet chances are doubled, and the admin panel lets the user spawn extra bosses live while on stream or in servers.
- Outside that slot the Mega boss keeps its normal weekend weight, so a kid who can't play at that hour still meets it.
- Decision for the user (section 7).

## 4. Fight mechanics
**The constraint:** the chop minigame locks you in place. It freezes movement (`MovementLock`), takes the camera (wind-up and impact shots), hides the HUD and billboards, and snaps you to a chop slot. Walking-based dodges would mean throwing players out of the chop every few seconds, then a camera reset and a fresh prompt each time. So **the boss's attacks happen inside the chop bar**, and you only walk at three set moments per fight (4.6).

### 4.1 What other games do with a player who can't move
| Game | How the enemy fights back | What we take |
|---|---|---|
| Undertale / Deltarune | Your turn is a timing bar (like our chop bar); then the enemy's turn is a separate dodge box. Grazing bullets builds your meter. | Alternate turns: some rounds are chop rounds, some are the boss's round. |
| Pokémon GO raids | You stand still and tap to attack; the boss's charged move is flagged, and a swipe in the window dodges. Niantic widened the window so any swipe between the warning and the hit counts. | A clear flag, then one input in a wide window. |
| Punch-Out, Expedition 33, Sekiro | Read the wind-up, then block or parry on cue; a perfect parry hits back. | Block on cue; a perfect block rewards you. |
| Hi-Fi Rush | Bosses are parried on the beat; the music carries the timing. | A rising sound leads into the block. |
| Fisch (Roblox) Megalodon | The boss fish is caught with the normal reel minigame, made harder: faster, erratic, less progress per second. No dodging at all. | Boss moves change how the bar behaves. |
| Dredge | Monsters can strike while you're in the fishing minigame; they're warned by vibration and screen distortion. | Warn on several channels at once. |

### 4.2 Shape of a fight: two timed halves (user's reference)
A proper server event, like the reference: **4:00 to get the boss to half health, then the timer resets to 5:00** for the second half. Up to 9 minutes of fighting. Health is tuned so a typical server gets each half done with time to spare (draft target: half 1 in about 3:00, half 2 in about 4:00).

| Phase | Time | What happens |
|---|---|---|
| **Arrive** | 30 s before | The boss drops into the arena centre and sleeps, snoring, with "Wakes up in 0:30". The boss tile and a notice ("Big Croc is here!") show a **Go** button that teleports you to the arena gateway. |
| **Wake** | 3 s | Roar, camera shake within 150 studs, fight music starts, banner "Chop the glowing spots!". The bar's timer starts at **4:00**. |
| **Half 1** | up to 4:00 | Chop the weak spots (4.3). Every 4th round is a **Block** round (4.4). The gold spot moves every 20 s. At 75% health, a **Slam** (4.6, small version) keeps the first half from feeling flat. |
| **Big Attack** | at half health (the line in the middle of the boss bar, 4.9) | The boss **gets mad** (user). Every chop ends, the floor goes red except 3 green circles, 4 s to stand in one (4.6). The timer jumps to **5:00** with a flash and a whoosh, "Round 2!". Then "Back to chopping!". |
| **Half 2 (mad)** | up to 5:00 | Red eyes, steam puffs, the bar pulses, music +2 semitones (as in the Guardian fight), every 3rd round is a Block round, its hits take more HP (4.8). Its signature move (4.5) comes every 45 s. At 25% health, a second Big Attack. |
| **Finish it!** | at 10% | The boss falls over, dizzy, for 6 s. No Block rounds and no knock-outs; every spot turns gold and takes x2 damage. |
| **Win** | on 0 health | The last hit plays in slow motion with hitstop, the boss tumbles and poofs into confetti and coins, a result banner with your cash, then any Pet drop gets its own reveal. |
| **Time up, half 1** | 4:00 runs out above half | "Big Croc got bored!" It stomps off. Everyone keeps the cash from their hits. No win, no Pet roll. |
| **Time up, half 2** | 5:00 runs out | "Big Croc ran away!" Same as above, plus everyone who dealt damage gets a small "Almost!" bonus (draft: 25% of a win's cash), because the server got it past half. |

### 4.3 Weak spots (chop rounds)
- The boss has **4 weak spots** low on its body, each with **4 chop slots** around it (the Diamond Rock's slot code), so up to 16 players chop at once and nobody queues.
- Walk up, press the prompt, and you're in the normal chop: same bar, same camera, same quality (Good 1, Great 2, Perfect 3 damage units).
- **One spot is gold** and does x2. It moves to another spot every 20 s, announced by a sparkle and "Gold spot moved!". Changing spot is your choice, and it's the natural moment to leave a chop, so nobody is forced out.
- Hitstop on Great and better (70 / 110 ms) and the hit sounds come from the Guardian fight.

### 4.4 Block rounds (the boss's turn)
**Redesigned 2026-11-11 (user): the red block zone.** The first version (a separate target, a shrinking ring, a 1.5 s window) felt too far removed from the chop bar. Built and playtested on rocks, see the vault note `Block Rounds`.
Every 4th round of your chop (every 3rd when mad) is a Block round instead of a chop round:
1. **Warning:** the boss winds up at your spot (its `Attack` clip, `Tele` marker), a rising sound, "Block!", and the bar's coloured zones turn grey with **one red zone**.
2. **Block:** the cursor sweeps exactly as in a chop. Stop it in the red zone: **"Blocked!"**. In its yellow centre: **"Perfect block!"** (counter-hit worth one Great, x1.5 on your next chop, +10 HP). Outside, or no press within two sweeps: **"Ouch!"**, the boss's hit lands (`Hit` marker) and you lose HP (4.8).
3. A Block round deals no damage to the boss. **Made harder (user, 2026-11-11):** the zone shows for 0.6 s (the boss's wind-up), then the cursor makes **one pass** at chop speed and stops. Red zone 20% of the bar on PC (32% touch), centre 6% (10%). When mad: zone 15% smaller, 1.2x faster. (A first, faster version was "overkill difficulty", user 2026-11-11.) Strength doesn't change it. Numbers are drafts (see the vault note for the ms windows).
4. Each player's Block rounds come from their own round count. Everyone at one spot sees the boss swing at that spot.
5. **Server judging** is the chop's: the client's elapsed time, clamped server-side, turned into a cursor position.
6. Same inputs as the chop (the touch button reads "Block").

### 4.5 Signature moves (mad phase only, change the bar)
Like Fisch's harder boss reel: the boss makes your bar behave differently for a few rounds. Each is announced by an icon on the bar and a one-word banner, and lasts 3 rounds.

**Built 2026-11-11 (not yet played):** every 45 s once the boss is mad (first one 45 s after the first Big Attack), each player chopping gets 3 signature rounds. Chomp: the zone jumps every time the cursor turns around (4 places per round). Shell Hide: Good and below do no damage and pay nothing (the bar paints them grey, the result reads "Shell!"). Frost: two ice patches, one over part of the zone. Icon and word sit at the bar's top right (an emoji until there is a real icon); the banner is a notification. Vault note `World Bosses`.

| Boss | Move | What the bar does |
|---|---|---|
| Big Croc | **Chomp** | The Good-and-better zone jumps to a new place on the bar each round. |
| Boulder Crab | **Shell Hide** | The shell is up: Good does no damage; Great and Perfect do full damage. |
| Frost Yeti | **Frost** | Two ice patches cover parts of the bar; the cursor slides through them and stays visible, but the zone colours under the ice are hidden. |
| Mega boss (after release) | **Double trouble** | Two Block rounds in a row, then any one of the other three moves. |

### 4.6 The Big Attack (the only times you move)
Taken from Undertale's turn swap. With a 9-minute fight it happens three times, each a break from chopping: a small **Slam** at 75% (only a red ring round the boss is dangerous: get out of it within 2.8 s, or lose 20 HP; renamed from Stomp Wave and made harder, user 2026-11-12), the full **Big Attack** at half health when the boss gets mad, and a second full one at 25%.

**Built 2026-11-11 (not yet played):** the Slam (then called Stomp Wave) and both Big Attacks, judged on the server at landing, with the arena camera, floor arrow, knock-back and "Safe!" / "Ouch!" over the boss. The Big Attack at half health follows the 3 s Mad roar. The stomp ring reaches 16 studs past the farthest weak spot. Vault note `World Bosses`.

**Changed 2026-11-11 (user): each boss has its own Big Attack** in place of the shared green circles. Same rhythm: a red warning on the floor for 4 s, the wide camera, then a hit on whoever is still in the red.
- **Big Croc, Tail Sweep:** (changed 2026-11-12, user) the whole arena goes red except one 30-degree sliver from the croc out to the edge, at a random angle. On landing the croc spins its tail once around the arena in 1.6 s, the lit streak running well past its tail tip, and anyone the line passes is hit at that moment. The only way to be safe is to stand in the sliver, or behind the line once it has gone by (you get hit if you cross it). The croc is turned on each player's screen by rotating its pivot; it no longer jumps (no `BigAttack` clip for the croc, user 2026-11-12). A croc `TailSpin` clip (crouch, whip round, settle) would look much better.
- **Frost Yeti, Ice Spikes:** (changed 2026-11-12, user) the whole arena goes red except 3 green safe pockets, like the original green-circle Big Attack. When the yeti lands, ice spikes burst up across the floor outward from it, reaching the far edge 0.5 s later. Get into a pocket.
- **Boulder Crab, Boulder Rain:** 14 red spots, 10 studs across, half of them under where players stand when it starts, the rest scattered. A shadow grows in each spot and a boulder (the Forest's second rock, recoloured darker than the sand) drops into it on landing. Step out of your shadow. (Picked over a shockwave ring because the Stomp Wave is already a ring round the boss; dots read differently from the croc's fan and the yeti's lines, and falling rocks suit a rock crab.)
**Changed 2026-11-12 (user):** the Stomp Wave is now the **Slam** everywhere players see it, and it's harder: 2.8 s warning (was 4 s, and chops still take 0.7 s to end), the ring reaches 28 studs past the farthest weak spot (was 16) and is judged at full size (it was 5% smaller). Every floor warning is now drawn on a SurfaceGui over an invisible anchor, with no coloured Parts (user's hard rule). Boss chop zones are capped so the perfect zone is at most 17% of the bar (4.11).
- Every chop ends first (the chop's normal end, so the camera and HUD come back the usual way).
- The boss roars; its own danger shape (the fan, lines or spots above) goes red, with a 4 s countdown over the boss. A green arrow on the floor points each player to the nearest safe ground.
- Out of the red: **"Safe!"**, x1.5 on your next chop, and +10 HP. In the red: knocked back about 20 studs, dizzy 1 s, "Ouch!", and the biggest HP hit of the fight (4.8).
- Then "Back to chopping!" and the weak spots glow again.
- The server checks each player's position when it lands, with the circles counted 10% bigger than drawn.

### 4.7 Playing together
- **Health follows who's there.** At wake-up it is the sum of each player's share (Diamond Rock rule), so solo works. Over a 9-minute event players come and go, so when someone deals their first hit, their share is added to both health and max health; the bar's percentage stays put and nobody loses progress. Leaving takes nothing away.
- **Who gets the win:** anyone who dealt at least 3% of their own share (draft) gets the win cash, the Pet roll and Boss Chest credit, so a kid who drops in for the last two minutes still counts.
- **Team hit:** when 3+ players at the same spot land Great or better within 1 s, "Team hit!" and each of those hits gets x1.25.
- Late joiners can start chopping any time; pay per hit is by your own share of damage (Diamond Rock rule).
- The result banner names the 3 players who dealt the most damage (no full ranking, so nobody sees themselves last).

### 4.8 Player HP and knock-outs (user: bosses can damage players and take HP)
- **Fight HP, not Roblox health.** Each player gets 100 boss-fight HP when they first chop the boss. It is a server number, not `Humanoid.Health`: a real Roblox death would reset the character, end the chop and respawn you at the lobby spawn. Nothing in the game damages `Humanoid.Health` today.
- **What hurts** (drafts): a missed block 20 HP (30 when mad); being in the red at the Big Attack 40 HP. Five missed blocks before the boss is mad still leave you standing.
- **What heals:** Perfect block +10, "Safe!" at the Big Attack +10, and back to full when the fight ends. No regeneration mid-fight, so a block matters.
- **Your HP on screen:** a row of 5 hearts (20 HP each) just above the chop bar, so a kid reads it without numbers. A heart cracks and pops when it empties; the last heart flashes red. Outside the chop, the same hearts sit under the boss bar.
- **Knocked out at 0 HP:** your chop ends, your character flops over with swirly stars ("Knocked out!"), the camera holds for 2 s, then 3 s of "Back in 3, 2, 1" and you appear at the arena gate with full hearts. Your damage share and the cash it earned stay; you just lose the 5 s and the walk back. Being knocked out never costs you the reward: everyone who dealt damage is paid.
- **No knock-outs during Finish it!** The boss is dizzy and doesn't attack, so the end of the fight is always a celebration.

### 4.9 The boss health bar (user's reference)
![[Boss Health Bar Reference.png]] (vault attachment)
- **Top centre:** the boss's name in big two-tone title text above the bar ("BIG CROC", warm top colour fading to a lighter one, thick dark outline, like the reference's "WORLD TREE").
- **The bar:** red fill in the chop bar's stud style with a thick black outline, and a black **divider at the halfway point**. That line is where the boss gets mad, so kids can see it coming. When the fill crosses it, the bar shakes and the boss's eyes turn red.
- **The timer** sits under the bar in white with a black outline (m:ss), turning red in the last 10 s as the Guardian fight's does. It counts down 4:00 to half health, then resets to 5:00 for the second half (user's reference).
- It replaces the Diamond Rock's top-of-screen `HealthBar` for bosses (`Screens/ChopBar`) and is shown to everyone in the arena, chopping or not.

### 4.10 Built from what exists
- Shared health, chop slots, pay by share, the timer: `DiamondRockService` (Spawning, Chopping).
- Chop bar, camera, quality, hitstop, music speed-up and muffle, the bar-speed hook `ChopController:BeginExternal`: the rocks and the Guardian fight.
- The top-of-screen health bar: the Diamond Rock's `HealthBar` in `Screens/ChopBar`, restyled to the reference.
- New: a Block round mode in `ChopController` and `Screens/ChopBar` (shield, ring), a per-round bar modifier hook for the signature moves, the server's block judge, fight HP and knock-outs on the server, the hearts UI, the boss model with 4 weak-spot parts and attack animations, the three Big Attack floors (fan, lines, spots), and the warning, block and knock-out VFX via the `vfx` skill.

### 4.11 Numbers to tune (drafts)
4 weak spots x 4 slots; gold x2, moves every 20 s; Block round every 4th round (3rd when mad); red zone 0.2 and perfect centre 0.06 of the bar before the PC/touch multipliers; boss chop zones barely grow with strength, perfect at most 17% of the bar (PC 9% weakest, 13% at 10x strength, 17% at max; touch 15-17%; `BossConfig.MaxPerfectShare`, `ChopZones.CappedRatio`, user 2026-11-12), timeout 2 sweeps; counter = one Great, x1.5 next chop, +10 HP; player HP 100 (5 hearts); missed block 20 HP (30 mad); Big Attack miss 40 HP, Safe +10 HP; knock-out 5 s; signature move 3 rounds; mad at half health; Big Attack 4 s (croc whole-arena sweep with a 30-degree sliver, 1.6 s, yeti 7 lines 8 wide, crab 14 spots 10 across); Safe bonus x1.5; Finish it 6 s at x2; team hit x1.25 for 3+ within 1 s; sleep 30 s; half 1 limit 4:00 (target about 3:00), half 2 limit 5:00 (target about 4:00); Slam at 75% (20 HP, 2.8 s, ring +28 studs), second Big Attack at 25%; signature move every 45 s when mad; win credit at 3% of your share; "Almost!" bonus 25% of win cash.

## 5. Balance (to model before building)
Add to the Balance Model's New Loop:
- Boss cash per minute of fighting against chopping rocks in your best zone. A fight now runs up to 9 min, so it replaces rock chopping for that time: **1.25x rocks (user, 2026-11-10).** At 1.0x a fight really pays less than rocks: Block rounds, knock-outs, walking and Big Attacks take time, and the arena has none of the rock bonuses (Rush, Golden, weather, Master jackpots). The Pets, badges and chest are capped or one-time, so once collected, cash is the repeat reason to join. More than about 1.5x would make the arena the best cash farm and shorten the zones. Pay per boss chop round is therefore set above a rock round to make up for the rounds that aren't chops (Balance Model v18: 2.10x a rock round; the session income boost is 5-11%, every zone passes).
- Boss Pet income at about the best zone's Epic, then re-run the Pets-share checks.
- Expected days to each boss Pet for a 30-min-a-day player (target: within 2-3 weeks).

## 6. Analytics
Custom events: `BossFought` (boss key), `BossWon`, `BossPetDrop` (pity or luck), `BossChestClaimed`, `BossBlock` (Blocked, Perfect or Missed, to check the window suits kids), `BossKnockout` (to check kids aren't knocked out too often). Compare D7 of players who fought a boss in their first session with players who didn't.

## 7. Open questions for the user
1. ~~Four bosses plus the Diamond Rock?~~ **Good scope for now (user).**
2. ~~Boss themes?~~ **The user will mix them up.**
3. ~~Weekend Mega boss?~~ **Deferred until the game is released (user, 2026-11-10).** Then pick: a Saturday admin-abuse slot (3.5), weekend weighting only, or none.
4. Boss Chest: **opens like an egg hatch (black silhouette, outline, grows) and pops open with one reward (user, 2026-11-11).** Still open: what the reward pool is, and the "3 different bosses" target.
5. ~~Keep the Diamond Rock on the boss clock?~~ **Yes (user).**
6. ~~Block rounds (4.4) and the one Big Attack (4.6)?~~ **Approved (user, 2026-11-10: "Yes, that fits").** Numbers in 4.11 are still drafts.
7. ~~Fight timer?~~ **Like the reference (user, 2026-11-10): 4:00 to half health, then the timer resets to 5:00. A proper server event that takes a while.**

## 8. Build order (after approval)
1. Balance Model pass (section 5).
2. Generalise `DiamondRockService` into a shared arena-boss service; the Diamond Rock becomes one entry. **Done differently (2026-11-11):** a separate `BossService` with the shared maths moved to `ServerScriptService.Utils.ArenaShare`; the Diamond Rock keeps its own service (vault note `World Bosses`).
3. Block round mode in the chop bar, testable on a rock with the admin panel before any boss model exists.
4. Boss clock weights by UTC day, and the 7-face strip plus countdown UI.
5. One boss end to end: weak spots, gold spot, Block rounds, fight HP and hearts, knock-outs, the boss bar, Big Attack, its signature move, Finish it, VFX, Pet, pity, label. Playtest with kids if possible, and log `BossBlock` to check the window.
6. The other bosses, the Boss Chest, badges, the boss Index page. (The Mega boss and the Saturday slot wait until after release.)
7. Analytics events.
