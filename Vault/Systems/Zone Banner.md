---
description: Silent top-screen banner shown each time a player walks into a zone (zone name + emoji, "Recommended: <first rock's strength> Strength"); replaced the in-world zone signs 2026-11-09.
type: system
---
# Zone banner

Built 2026-11-09 from [[Zone Banner Reference]] (user feedback item 2). Not playtested yet.

- **Server:** `ZonePresenceService` polls every `PollSeconds` (0.5) and looks up each player's zone from the `RockSpawnArea` boxes **by Z only** (zones sit in one line on +Z, so terraces and walls still count as the zone; the lobby and boss arena are no zone). When it changes to a zone in `ZoneBannerConfig.Zones` it fires `Packets.ZoneEntered(zone)`. Walking back to the lobby and in again shows it again. `GetZone(player)` is available to other services.
- **Client:** `NotificationController` fires `ZoneEntered` unless muted (`IsMuted`: Notifications setting off, tutorial running, tutorial complete screen open; shared with `Notify`). The `Notifications` screen clones `StarterGui.Notifications.ZoneTemplate` (a CanvasGroup: `Backdrop` with the notification strip's fade gradient, `Title`, `Recommended` row of `Label` / `Icon` / `Value`) into the notification `Container` on top (`LayoutOrder` -2000), fades `GroupTransparency` in 0.25 s, holds 3 s, fades out 0.6 s. No sound. A new zone replaces the current banner.
- **Text (drafts, user approved Strength 2026-11-09):** title `<Zone> Zone <emoji>` in the zone's old sign style (Forest/Jungle/Swamp/Bamboo Green, Desert/Savanna Gold, Ocean Sky, Snow/Ruins Chrome, Volcano Red); "Recommended:" white with black stroke; bicep `IconConfig.Strength`; value = the zone's first rock `StrengthRequired` (`RecommendedRock`), `NumberFormat.CompactRock`, `Strength` style. Emojis: 🌲 🌵 🌴 🌊 ❄️ 🐸 🦁 🎋 🌋 🏛️.
- The cannon landing no longer sends "Welcome to the <Zone>!" (`CannonHintService`); the banner covers it.

Related: [[Forest Zone Entrance]], [[Zone Line]], [[UI Text Style]]
