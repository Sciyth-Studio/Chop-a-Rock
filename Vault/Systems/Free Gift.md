---
description: Free Gift popup (2026-10-28) — lobby pad by the entrance opens a "Free Gift!" panel; Claim checks Sciyth Studio group membership server-side, once per player, for cash worth 3 of your zone's geode.
type: system
---
# Free Gift

The user asked (2026-10-28) for a "Free Gift! Limited time!" screen like the reference in [[Studded Panel Style Reference]] (`Panel Style Ref Free Gift.webp`): big reward picture, three step cards with screenshots (1. Like the game, 2. Favorite the game, 3. Join the community) and a green Claim button.

**Decisions (user, 2026-10-28)**
- Claim checks only the community (group) membership. Roblox can't check likes, and favorites can't be read back, so those two steps are still shown and asked for but don't gate the claim.
- Reward: cash worth 3 of the player's zone geode (`CashPack.GeodeValue(3, strength)`, the Small cash pack's size). Draft size.
- No automatic popup. A pad near the lobby entrance, off to the side, opens it like a shop pad.

**How it works**
- `FreeGiftService` handles `Packets.ClaimFreeGift` (returns `Claimed`, `NotInGroup`, `AlreadyClaimed` or `Failed`). It checks `GroupService:GetGroupsAsync` rather than `Player:IsInGroup`, because `IsInGroup` caches per server, so a player who joins the group mid-session would be refused until they rejoin. The claim is saved as the `Offers.FreeGift` flag (no schema change), rechecked after the yield, and guarded per player against overlapping calls.
- `Screens/FreeGift` paints the card green, shows the reward in the player's cash, and greys the button to "Claimed!" once the flag is set. Step 2's card opens `AvatarEditorService:PromptSetFavorite(PlaceId, Asset)`, step 3's opens `GroupService:PromptJoinAsync(groupId)`; step 1 has no API. A failed claim shakes the button and shows a red hint ("Join the community first!").
- Studio: `StarterGui.FreeGift` is a copy of the Welcome Back panel with a red header, gift header icon, `Body.Card` holding `Icon` (Cash5 chest), `Reward`, `Hint`, `Steps.Step1..3` (`Title`, `Shot`, `Button`) and `ClaimButton`. The pad is a `ShopPad` (`Screen = FreeGift`, `ShopName = Free Gift`) in `Workspace.FreeGift`.
- Step screenshots are drawn mock-ups of the Roblox game page (`assets/Icons/FreeGift/draw_steps.py`, ids in `assets.json` and `FreeGiftConfig.Steps`). The join card shows a placeholder "S" logo, not the real group icon. Uploading `StepFavorite.png` failed with `INTERNAL` and worked as "FavoriteStep" (same gotcha as [[Open Cloud Key]]).
- Group id 10962733 (Sciyth Studio) in `FreeGiftConfig.GroupId`.
- Placement: `Workspace.FreeGift` is a stud-part gift box (red, gold ribbon and bow, Red "Free Gift!" stand sign billboard) at x -50, z -216, just inside the lobby's open forest-side end, left of centre; the red 12x6 pad sits in front of it toward the opening.
- Playtested 2026-10-28 (injected into Studio): pad opens the panel, reward read "Free $1,500 Cash" (Forest geode x3), Claim paid +$1,500 and turned grey "Claimed!", a second click and a direct packet paid nothing, and with a non-member group id the hint showed "Join the community first!" and nothing was paid. The favorite and join prompts are Roblox CoreGui and were not seen in captures; the favorite click logged no errors.

Related: [[Shop Pads]], [[Cash Packs]], [[Menu Panel Style]]
