---
description: Free Gift popup (2026-10-28) — lobby pad by the entrance opens a "Free Gift!" panel; Claim checks the favorite on the client (since 2026-11-03) and Sciyth Studio group membership server-side, once per player, for cash worth 3 of your zone's geode. Likes can't be checked.
type: system
---
# Free Gift

**What Claim checks (user 2026-11-03: "make the free gift actually check for the things that are checkable"; replaces the 2026-10-28 decision below, which said favorites can't be read)**
| Step | Can Roblox tell us? | What happens on Claim |
|---|---|---|
| 1. Like | No. No API reads a player's like. | Asked for, never checked |
| 2. Favorite | Client only, after the player allows inventory access: `AvatarEditorService:PromptAllowInventoryReadAccess`, then `GetFavoriteAsync(PlaceId, Asset)`. The server has no call for it; the only other route is an undocumented web endpoint through a third-party proxy, not used. | Not favorited: red hint "Favorite the game first!", shake, nothing sent to the server. Favoriting through the step's prompt counts for the session (`PromptSetFavoriteCompleted` Success) even if the read is stale. If the player declines access, the read errors, or there is no answer in `FavoriteCheckSeconds` (30, draft), the step can't be checked and doesn't block the claim. |
| 3. Join | Yes, on the server (`GetGroupsAsync`) | Not a member: "Join the community first!", nothing paid. |

The favorite check is a client check: a modified client can skip it. Only membership and the once-per-player flag are enforced by the server. Reward is a one-time small cash amount, so that risk was accepted. Not yet seen in Play (2026-11-03): the access prompt, a real `GetFavoriteAsync` result for a place id (Edit only confirmed the permission error), the "Favorite the game first!" hint. Check these first if players can't claim. Whether rewarding likes and favorites is fine under Roblox's rules wasn't settled; forum posts disagree.

The user asked (2026-10-28) for a "Free Gift! Limited time!" screen like the reference in [[Studded Panel Style Reference]] (`Panel Style Ref Free Gift.webp`): big reward picture, three step cards with screenshots (1. Like the game, 2. Favorite the game, 3. Join the community) and a green Claim button.

**Decisions (user, 2026-10-28)**
- Claim checked only the community (group) membership; likes and favorites didn't gate it. Superseded for favorites on 2026-11-03, see the table above.
- Reward: cash worth 3 of the player's zone geode (`CashPack.GeodeValue(3, strength)`, the Small cash pack's size). Draft size.
- No automatic popup. A pad near the lobby entrance, off to the side, opens it like a shop pad.

**How it works**
- `FreeGiftService` handles `Packets.ClaimFreeGift` (returns `Claimed`, `NotInGroup`, `AlreadyClaimed` or `Failed`). It checks `GroupService:GetGroupsAsync` rather than `Player:IsInGroup`, because `IsInGroup` caches per server, so a player who joins the group mid-session would be refused until they rejoin. The claim is saved as the `Offers.FreeGift` flag (no schema change), rechecked after the yield, and guarded per player against overlapping calls.
- `Screens/FreeGift` paints the card green, shows the reward in the player's cash, and greys the button to "Claimed!" once the flag is set. Step 2's card opens `AvatarEditorService:PromptSetFavorite(PlaceId, Asset)`, step 3's opens `GroupService:PromptJoinAsync(groupId)`; step 1 has no API. A failed claim shakes the button and shows a red hint ("Join the community first!").
- Studio: `StarterGui.FreeGift` is a copy of the Welcome Back panel with a red header, gift header icon, `Body.Card` holding `Icon` (Cash5 chest), `Reward`, `Hint`, `Steps.Step1..3` (`Title`, `Shot`, `Button`) and `ClaimButton`. The pad is a `ShopPad` (`Screen = FreeGift`, `ShopName = Free Gift`) in `Workspace.FreeGift`.
- Step screenshots are drawn mock-ups of the Roblox game page (`assets/Icons/FreeGift/draw_steps.py`, ids in `assets.json` and `FreeGiftConfig.Steps`). The join card shows a placeholder "S" logo, not the real group icon. Uploading `StepFavorite.png` failed with `INTERNAL` and worked as "FavoriteStep" (same gotcha as [[Open Cloud Key]]).
- Since 2026-10-29 the step images are the user's own screenshots with red arrows (Like 93695998180737, Favorite 138695166719600, Join 126557040840800), uploaded under the group. Each `Shot` is a fixed 240x135 (16:9) with Fit scaling, so replacements should be 16:9, about 960x540. The `Reward` amount text is `Chrome` (black stroke) instead of `Green`.
- Group id 10962733 (Sciyth Studio) in `FreeGiftConfig.GroupId`.
- Placement: `Workspace.FreeGift` is a stud-part gift box (red, gold ribbon and bow, Red "Free Gift!" stand sign billboard) just inside the lobby's open forest-side end (the user moved it to about x -81, z -211). Since 2026-10-28 (user feedback) the pad is a yellow 18x18 square centred on the box, so the glow wall runs all around the gift, and it has `HasPrompt = false`: walking in opens the panel, there is no E prompt, and walking out and back in reopens it.
- **Cash chest (2026-10-30, user):** the stud-part gift box was replaced by `Workspace.FreeGift.Chest`, a meshlab MeshPart modelled after the Cash5 shop icon (open red chest, gold trim, cash heap, coins and bills; see [[Meshlab]]). It sits at the old box's base, front facing -Z, toward the back of the lobby (user), `2022 Stud`, collides. `SignAnchor` and `StandSign` moved onto it with the anchor kept at world y 13.
- Playtested 2026-10-28 (injected into Studio): pad opens the panel, reward read "Free $1,500 Cash" (Forest geode x3), Claim paid +$1,500 and turned grey "Claimed!", a second click and a direct packet paid nothing, and with a non-member group id the hint showed "Join the community first!" and nothing was paid. The favorite and join prompts are Roblox CoreGui and were not seen in captures; the favorite click logged no errors.

Related: [[Shop Pads]], [[Cash Packs]], [[Menu Panel Style]]
