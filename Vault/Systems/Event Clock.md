---
description: Event Clock (2026-10-29) - every 5 min on the :00/:05 server-time grid one server event rolls (Geode Fall 40, Diamond Rock 35, Weather 25, never the same twice in a row); replaced each event's own timer.
type: system
---
# Event Clock

The user asked on 2026-10-29 for one shared timer for every server event: "every 5 mins any event will roll".

- **Clock:** `EventClockService` (server) ticks every second. Slots sit on multiples of `EventClockConfig.PeriodSeconds` (300) of `workspace:GetServerTimeNow()`, so they fire on :00, :05, :10 and so on. At each slot it starts the event it rolled at the previous slot, then rolls the next one, weighted by `EventClockConfig.Events` (Geode Fall 40, Diamond Rock 35, Weather 25, a first guess) and excluding the event that just ran. Each server rolls its own. Weather is no longer shared across servers.
- **Weather** is booked a whole slot ahead with `WeatherService:Schedule(startsAt)`, so its 1-minute warning and the HUD pill's "next weather" countdown still work. It now lasts 240 s, so it ends before the next slot. `WeatherClock` only keeps `Event` and `Pick`. The `:00/:30` slots and `ClockSeed` are gone.
- **Geode Fall** and **Diamond Rock** start through their admin `Spawn(nil)` entry points, so they still give their own 10 s and 60 s warnings. If an event can't start (nobody has reached a zone, no room), that slot is simply skipped.
- **Not on the clock:** Rush Rocks, which stay a per-player chopping reward ([[Golden Rocks]]). The admin commands that force an event ignore the clock.
- Removed: Geode Fall's 20-25 min timer and its weather and diamond gap checks, the Diamond Rock's 10-15 min timer, `WeatherService:SecondsUntilNext` and `DiamondRockService:SecondsSinceEnded`.

Not playtested yet. The weights, the 4-minute weather and the geode count are drafts to tune.

Related: [[Weather]], [[Geode Fall]], [[Diamond Rock]], [[Admin Panel]]
