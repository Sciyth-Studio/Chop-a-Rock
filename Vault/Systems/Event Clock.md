---
description: Event Clock - since 2026-11-09 two clocks - a weather clock every 5 min (:00/:05, Weather 60 / Geode Fall 40, no repeats) and a boss clock every 15 min at :02:30 (Diamond Rock in the arena; the Golem joins later); shown as icon timers bottom right.
type: system
---
# Event Clock

The user asked on 2026-10-29 for one shared timer for every server event. On 2026-11-09 they asked for boss events to run on their own timer in an arena behind the lobby ([[Boss Arena]]), separate from the weather.

- **Clocks (`EventClockConfig.Clocks`):** each has a `PeriodSeconds`, an `OffsetSeconds` and weighted `Events`. Slots sit at `k * Period + Offset` of `workspace:GetServerTimeNow()`. At each slot `EventClockService` starts the event it rolled at the previous slot, then rolls the next one, never the same twice in a row (unless a clock has only one event). Each server rolls its own.
  - **Weather clock:** every 300 s from :00 (:00, :05, ...). Weather 60, Geode Fall 40. Both happen out in the zones.
  - **Boss clock:** every 900 s at offset 150 (:02:30, :17:30, :32:30, :47:30), so it never lands on a weather slot. Diamond Rock only, for now; the Golem fight goes on here once it's built.
- **Published for the UI:** per clock, workspace attributes `<Name>ClockEvent` (key) and `<Name>ClockAt` (server time). `WeatherService` also publishes `NextWeather` (the booked weather key) next to `NextWeatherAt`.
- **Weather** is booked a whole slot ahead with `WeatherService:Schedule(startsAt)` and lasts 240 s, so it ends before the next slot. Since 2026-11-09 there is no "in 1 minute" warning notice; the timer icon is the warning. Start and end notices stay.
- **Geode Fall** and **Diamond Rock** start through their admin `Spawn(nil)` entry points. Geode Fall keeps its own 10 s lead. If an event can't start, that slot is skipped.
- **Not on a clock:** Rush Rocks ([[Golden Rocks]]). The admin commands that force an event ignore the clocks.

## Event timers UI (2026-11-09)
Replaces the `WeatherPill` (backup `ServerStorage.UIBackup["WeatherPill.BeforeEventTimers"]`). Look: [[Event Timer Icons Reference]].
- `StarterGui.EventTimers.Container`: bottom right (1,-16, 1,-16), `ScreenScale` with `ScalePosition`, a right-aligned horizontal `UIListLayout`. Hidden `TimerTemplate` (112x124): one 92 px `Icon` whose black outline is baked into the PNG (since 2026-11-09; the 8 `IconOutline` copies are gone), `Time` (white, Heavy italic, 38 px, 3.5 px black stroke) and a black `TimeShadow` (2,3).
- `Screens/EventTimers` clones one tile per clock, in config order (weather tile left, boss tile right). Weather tile: during weather, that weather's icon and the time left; otherwise the next event's icon (the booked weather's own icon, or the Geode Fall icon) and the time to the slot. Boss tile: the next boss event's icon and the time to its slot. A tile hides when its time is up. Icons for non-weather events come from `EventTimerConfig.Icons`.
- Icons (2026-11-09, ChatGPT from `assets/Icons/EventTimers/Prompts.md` + `IconReferenceSheet.png`, cleaned to 512 px and uploaded under the group): Geode Fall (flaming purple egg) 127553191276630, Diamond Rock (cyan crystals on grey stone) 93905220550976, boss fist (`Golem` key, spoiler-free) 123629196731881. The ChatGPT webps came with real transparency this time; only the haze cut and trim were needed. Raw files in `raw/`. The reference sheet was uploaded by accident too (88653576833472, unused).

Not playtested yet. Periods, offsets and weights are drafts.

Related: [[Weather]], [[Geode Fall]], [[Diamond Rock]], [[Boss Arena]], [[Admin Panel]]

**Outlined icons (2026-11-09, user: "there has GOT to be a better way to make outlines"):** every timer icon now has its outline baked in by `tools/icons/bake_outline.py` (see the `studio-ui` skill). Uploaded: Geode Fall 107449519840351, Diamond Rock 88370777803925, boss fist 103613630342041, idle cloud 132638548613590, and the weathers Sandstorm 110651249211406, Hurricane 122388756309754, Heat Wave 82203127494851, Thunderstorm 133227097714860, Eclipse 77596124514618. `WeatherConfig` event `Icon`s point at the outlined versions (the timer is their only user). Sandstorm, Heat Wave and Eclipse had no PNG on disk and were pulled from Studio pixel-exact into `assets/Icons/Weather/`; the outlined set is in `assets/Icons/EventTimers/Outlined/`.
