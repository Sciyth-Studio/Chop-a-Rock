---
description: Three simulator Index screenshots (2026-10-06) for the Index screen layout: zone page of cards, detail pane with rewards, claim bar, variant tabs down the side.
type: reference
---
# Index UI reference

![[Index UI Ref Zone Page.webp]]
![[Index UI Ref Animal Index.png]]
![[Index UI Ref Variant Tabs.png]]

Take from them (layout and content only; style is [[Menu Panel Style]]):
- **Card grid per zone** with a zone label ("Meadow"). Cards are tinted by rarity; found entries show the pet and its name, unfound ones a black silhouette and "???".
- **Detail pane on the right** for the selected entry: big preview, name, rarity, odds as "1 in N", income, and a **Rewards** row of icon tiles with a Claim / "Claimed!" button.
- **Progress bar** under the grid ("3/8", "1 / 4") with a reward icon at the end for completing the zone.
- **Claim All (N)** button along the bottom.
- **Header bar** above the grid: "Normal Index · No mutation · 2 / 53".
- **Variant tabs** down the side (Normal, Golden, Diamond...), each with its own "found / total" count; the active one is highlighted with stripes.

Ignore: the forest painting on the left of the first shot, rounded corners, the blue header of the second shot.

Used by `IndexSystemPlan.md`. Related: [[UI Style References]] (older Index screenshot), [[Geode Stand UI Reference]], [[ViewportFrame Gotchas]]
