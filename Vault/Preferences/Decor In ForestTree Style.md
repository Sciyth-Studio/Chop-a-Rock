---
description: Zone decor is built in the stud-block style of the intro ForestTree, refined to the JungleTree (crossed-box courses, alternating shades, chunky trunks, root fins); greens on green floors sit close to the floor colour; settled 2026-10-28.
type: preference
---
# Decor in the ForestTree style

The user (2026-10-28) settled this after three tries: "i should've just asked for the props to be in the style of the tree we made, it was really only the coral that looked bad earlier." Later the same day they liked `DecorJungleTree` "a lot" and had every prop restyled to match it.

How it went:
- First pass: stepped stud blocks like `ForestTree`. Only the coral looked bad (one bunched pink clump).
- Cartoon lineup sheets came back smooth. A prompt asking for stepped blocks gave sheets that looked "like legos", and the smooth cartoon ones then weren't "blocky enough".
- Two side sessions built smooth, then low-poly faceted versions. The user dropped both for the first pass.
- The JungleTree became the reference, and all props were restyled to it (Zone Decor v3).

How to apply:
- Build decor like `tools/meshlab/models/DecorJungleTree.luau`:
  - crisp `bevelBox(…, 0)` blocks, with round masses as **crossed boxes** (two boxes, w × 0.75w and 0.75w × w) stacked in shrinking courses of alternating shades;
  - chunky banded trunks and stems, and buttress root fins on trees and stumps;
  - `Props.limb` square limbs for branches, spread apart so they don't clump;
  - 1-stud studs (`PITCH = 1.0`).
- **Greens on green floors match the floor** (user, 2026-10-28: "green flora should be a similar green to the zone's floor"): pick shades just around the floor colour, not contrasting brights. Zone colours are in [[Zone Line]].
- Branch tips taper by stepping in, in the same colour. No wider caps and no lighter tip colour.
- Match the tree to the place: no palms in a jungle, and no beach props when no zone is a beach.
- The lineup sheets ([[Decor Lineups]]) give the parts, proportions and colours, not the finish. Ask for this style up front instead of describing a look in a prompt.
- Still few, simple props ([[Keep Decor Simple]]).

Related: [[Meshlab]], [[Studs On Models By Default]]
