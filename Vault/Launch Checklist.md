---
description: Pre-launch action list for Chop a Rock drawn from Hud's Guide (Downloads), grouped by phase; items marked "Your call" are player-facing and need the user's decision before building.
type: project
updated: 2026-10-27
---
# Launch Checklist

Built 2026-10-27 from Hud's Guide To Roblox Success, an Obsidian vault in `Downloads/Obsidian Vault - Huds Guide` (Discord advice from May–October 2026, with confidence ratings). Each item says what to do and when it's done. **Your call** = player-facing, so propose and wait ([[Code Output Rules]]). Day-to-day tasks stay in [[To Do]]. Tick items here as they land.

## 1. First 5 minutes (biggest lever, do first)
- [ ] **Your call: shorten the tutorial.** It's 9 steps now ([[Tutorial]]). The guide's target is 5 steps or fewer, under ~1 minute, or a short-step reveal across 3–5 min. Merge the second train and chop steps (TrainAgain 4, ChopAgain 5) into the first pair. Done when the tutorial has 5–6 steps and a fresh player finishes it in about a minute.
- [ ] **Your call: remove the Skip button.** The guide's consensus is no skip on a short tutorial, because players skip by accident and get lost. Done when Skip is gone or hidden until the tutorial has run about 60 s.
- [ ] **Show the long-term goal early.** Within the first minute, show later zones and the Roks they hold (the zone wall, the Index) so players know what they're working toward. Leaving at 60–180 s means there's no goal. Done when the tutorial points at it once.
- [ ] **Intro cutscene, ~15 s** (already in [[To Do]]). Play it on load, then go straight into the tutorial. Show the fantasy: a Master chop splitting a giant rock, a Secret Rok hatch. Keep it under 20 s; a 2-minute cutscene sank one game.
- [ ] **Load fast on mobile.** Players who leave at step 1 usually hit lag or a slow load. Time a cold join on a phone. Stream or defer zones the player can't reach yet. Preload HUD and menu images behind a cover until `IsLoaded`. Done when the HUD is usable in under ~10 s on mobile with no images popping in.

## 2. Analytics (before any players arrive)
- [ ] **Extend the onboarding funnel past the tutorial** (part of "Tracking funnels" in [[To Do]]). `TutorialService` already logs steps 1–11. Add steps for the first Rok placed, first pad collect, first sell, first Index claim, desert unlocked, first rebirth and ~30 min / ~60 min played. Aim for 12+ steps covering the first 15–30 min.
- [ ] **Add economy events** (`AnalyticsService:LogEconomyEvent`) for cash sources (chop, pads, Rush, Diamond Rock, sell) and sinks (auras, geodes, cannons, slots, training sign). Done when both show in Creator Hub after a test session.
- [ ] **Add custom events** for shop opens → purchases, so the Robux shop has its own small funnel.
- [ ] **Write down the targets.** Tutorial completion about 85%, per-step loss 0–5% (over 10% means fix it), first-60-s bounce under 15%, average playtime 20+ min (simulator), D1 above the 7.3% median.

## 3. Session length
- [ ] **Your call: timed playtime rewards** at 5, 10, 15, 30 and 50 min, shown in the UI with a countdown (owner-recommended). Rewards could be cash scaled to the zone or a short luck boost. None exist in code yet.
- [ ] **Stop the 20-minute idle kick.** Idle income makes AFK players likely. Reset the timer on input and teleport idle players a minute before the kick. Done when a player left idle for 25 min is still in the server.
- [ ] **Add "next event in" timers** for Weather, Geode Fall and the Diamond Rock where none are shown yet. Players stay for a countdown.
- [ ] **Check the sound mix.** One sound that was too loud cut playtime 20% in an A/B test. Listen for harsh or high-pitched SFX (Master chop, cannon blast, hatch) at default volume.
- [ ] **Your call: make Secret hatches spectacular.** The guide says very rare rolls need an over-the-top reveal. Done when a Secret hatch looks clearly bigger than a Legendary.

## 4. Performance
- [ ] **Set MaxDistance ~100** on every BillboardGui and SurfaceGui (stand signs, shop names, leaderboards, upgrade signs, pills in the world). Infinite distance means they all render at once.
- [ ] **Cap on-screen VFX.** More than ~40 at once kills FPS. Test a Hot Streak + storm + Diamond Rock pile-up on a phone.
- [ ] **Measure on a phone.** Targets: 30–40+ FPS, client memory under ~1,000 MB, network received under ~100 KB/s. Use the MicroProfiler to find the cause of any spikes.
- [ ] **Watch memory over a 30-min session.** If it climbs steadily there's a leak (check the EditableMesh slicing and the effects).

## 5. Account and page setup (a week or two before launch)
- [ ] ID-verify the group owner's account and turn on 2FA.
- [ ] Fill in the maturity questionnaire honestly and set the genre (Simulation). New games start locked to 16+.
- [ ] **Your call: 25 thumbnails.** These are 1920x1080, bright, one big subject, no raw Studio screenshots. Formats that fit: "Day 1 vs Day 100" (weak chop vs Master chop splitting a giant rock), noob-to-strong, a huge Secret Rok reveal. 5 go on the game page and up to 25 rotate in ads.
- [ ] Game icon and title: make sure the icon reads at small size on mobile.
- [ ] Short description that names the fantasy and mentions offline income.

## 6. Launch budget and run
- [ ] **Your call: budget.** Buy ad credits in USD (1 USD = 1 credit), never with Robux. About 16 credits/day for 7–14 days ($112–$224), Plays objective, broad targeting, don't pause. Add 1,000 Robux to clear the age gate at 250 HEP (100 HEP is announced for November).
- [ ] Ignore the first 24–48 h of data. Judge a thumbnail after ~10k impressions and cut anything under ~2–3% CTR.
- [ ] Ship small updates every day or two during the ad run, mostly fixes to whichever funnel step loses the most players.
- [ ] Stop or taper the ads once home-recommendation impressions pass ad impressions. If there are no home recs after ~2 weeks, change the game, not the budget.

## Already covered
- Monetization: the guide's `09 Monetization` notes fed `RobuxShopPlan.md` ([[Monetization References]]).
- In-session events every 5–15 min: Weather, Rush Rocks, Geode Fall, the Diamond Rock.
