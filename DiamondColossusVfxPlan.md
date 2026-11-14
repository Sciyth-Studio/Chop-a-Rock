# Diamond Colossus VFX: proposal (2026-11-10)

Nothing here is built yet. Pick what you want and I'll build it.

## Where it stands now

The Colossus already has some motion, done in code without particles:
- the 10 floating shards turn slowly around it;
- the Neon heart pulses between bright and dim;
- the Neon veins glow all the time.

Everything else is left over from the old 50-stud Diamond, so it's the wrong size or a placeholder:
- **Beacon:** a Neon cylinder. VFX lesson 15 calls that a placeholder; it should be a textured Beam pillar.
- **`VFX_Diamond_Glow`:** sized for a rock half this big.
- **Hit effects:** each hit plays the shared rock hit and `VFX_Diamond_Shards`. Both are rock-sized, so they'll look like specks on a 100-stud boss.
- **Break:** `VFX_Diamond_Burst` and a whole-rock break (no split). Also rock-sized.

## Palette

- Cyan 40,180,245 for the crystals.
- White-cyan 200,250,255 for the heart and flashes.
- Deep blue 20,70,160 for the dark twins, so the effects don't turn into a white blob (lessons 3 and 6).
- No gold.

Bloom on this place starts at 2. So the cyan layers can run at Brightness 5-8, and anything white stays at 2 or below.

## The beats

Each beat gets its own template under `Assets.VFX.Diamond`.

### A. Arrival (once per event, everyone in the arena sees it)
The Colossus rises out of the floor today with no effect at all.
- **A1 Ground crack ring:** a cyan crack decal spreads out to about 60 studs across the floor in 1.5 s, then fades out over the countdown.
- **A2 Dust wall:** a ring of grey-cyan dust rolls outward from the base while it rises.
- **A3 Landing flash:** when the rise finishes, the heart flashes white and one big shockwave ring runs across the arena, with a short camera shake for anyone within 120 studs.

### B. Idle (the whole fight, about 90 s)
- **B1 Heart halo** (I'd make this the **hero**): a big soft cyan glow sprite behind the heart. It pulses in step with the core's colour, with slow light rays turning around it, and adds a cyan PointLight (range 60) so the crater and nearby players get lit.
- **B2 Crack light spill:** a faint cyan haze rises off the veins, a few slow particles per vein strip. The veins stay geometry; this only makes them look like they leak light.
- **B3 Shard trails:** a short Trail behind each floating shard, so the orbit reads from far away.
- **B4 Sparkle fizz:** tiny white glints on the crystal spires, a low rate (about 6 a second for the whole model).
- **B5 Beacon:** the Neon cylinder becomes a textured Beam pillar coming out of the centre spire's tip, so you can find the event from the lobby.

### C. Hits (every chop, from 52 studs behind the player)
Hits come from up to 12 players at once, so each one stays small and short (under 0.5 s). The scale comes from the boss reacting, not from big particles.
- **C1 Impact on the surface:** a cyan crystal burst sized for this rock (about 3x the current one), placed where the player is actually hitting, not at the centre.
- **C2 Boss reaction:** the heart flashes brighter for 0.15 s, and the shard orbit kicks to about 3x speed, then eases back over 1 s. One flash at a time, so 12 players don't strobe it.
- **C3 Perfect/Master:** a chunk of crystal flies off the surface and a vertical cyan slash flashes across the face. Master also shakes the camera a little.

### D. Low health (below 25%)
- **D1:** the heart pulses faster and redder-white (a shift toward 255,240,250), the veins flicker, and small crystal bits drop off the spires now and then. Players can tell it's about to break without reading the bar.

### E. Break (once, the payoff)
- **E1 Charge-up 0.4 s:** the shards pull in toward the heart, and the heart swells and goes white.
- **E2 Explosion:** a big white-cyan flash, two shockwave rings (one on the ground, one tilted), 30-40 crystal chunks flying out, a light pillar shooting up 150 studs, and a strong camera shake within 120 studs.
- **E3 Fallout:** glinting crystal dust drifts down over the arena for about 4 s, while the payout pops happen.

## Cost and rules

- About 9-11 new templates. Textures come from your VFX kit first; I'll draw only the crack decal and the light rays.
- Everything runs on the client. Damage and payouts never wait for an effect.
- Particle budget: idle under about 150 live particles; the break peaks briefly near 400, then drops.
- The uploads (one batch, maybe 6-8 images) only happen after you've seen the effects in Edit with uploaded preview textures.

## Questions for you
1. **Hero beat:** B1 (the glowing heart, all fight long) or E2 (the break explosion)? I'd pick B1, because players stare at it for 90 s. The break lasts 2 s.
2. **All of A-E, or a first pass?** A smaller first pass would be B1, B5, C1, C2 and E1-E2. That's the minimum that makes it feel like a boss.
3. **D1 colour shift:** keep it cyan and just go faster, or let it go toward pink/white when it's nearly broken?
4. **Camera shake on arrival and break:** fine, or none (some players hate shake)?
