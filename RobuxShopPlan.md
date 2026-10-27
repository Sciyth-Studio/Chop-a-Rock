# Robux shop, more monetization and a starter pack: plan

Status: **approved 2026-10-24. The user accepted every recommendation in R1-R13.**

Build progress (2026-10-24), steps 1-2, not yet playtested:
- `MonetizationConfig` exists, with the six passes (ids not made yet).
- `PlayerData.Passes` is added. The other new fields are added in the steps that use them.
- `PassService` is registered, with the admin "Fake Pass (Studio)" command (alias `pass`).
- 2x Luck now reads `PassService`. `LuckConfig.GamepassId` and `GeodeService`'s ownership cache are removed.

Step 3 (2026-10-24), not yet playtested:
- **2x Cash:** chop pay (`RockService`) and Diamond pay go through `PassService:ApplyCashMultiplier` after the Index multiplier.
- **2x Strength:** applied in `TrainingService.addTrainingStrength`, which covers idle reps and Board Slice.
- **Big Backpack:** `PassService:GetBackpackSize` (100 + 100). It's used by `PetService:CanAdd`, the sell limit, the geode buy check, admin Fill Backpack and the Geode Shop's free-space count.
- The bonuses live in `MonetizationConfig.PassMultiplierBonus` and `BackpackBonus`. Boosts will add to the same multiplier in step 4.

Step 4 (2026-10-24), not yet playtested:
- **`BoostService`:**
  - Personal 2x Cash and 2x Strength, counting down only while you're online and saved every 30 s and on leave. A `BoostEnds<Key>` player attribute holds the server-time end, and `BoostEnded` fires to the owner when a boost runs out.
  - Server boosts (Cash, Strength, Luck) live in server memory, with `ServerBoostEnds<Key>` / `ServerBoostBy<Key>` workspace attributes and a `PurchaseAnnounced` packet to everyone.
  - A free 5-min 2x Strength when the tutorial finishes, through the new `TutorialService.Finished` signal and the `Offers.BoostTaste` flag.
- **Multipliers:** `PassService:GetMultiplier` is now 1 + pass + personal boost + server boost. Luck is the pass multiplier (x2) plus the server luck bonus.
- **Products:** boost grants are registered in `PurchaseService/Products` once their product ids exist (all still `nil`).
- **Admin:** "Give Boost (+15 min)" (`boost`), "Server Boost (+15 min)" (`serverboost`) and "Clear All Boosts" (`noboosts`).
- **Data:** `Boosts` (seconds left) and `Offers` (flags) are added to `PlayerData`.

Step 5 (2026-10-24), checked by value in Studio Edit, not yet playtested:
- **Config:** `GeodeConfig` generates `Lucky<Zone>` entries from each zone geode (`RobuxOnly`, `BaseKey`, `MinRarity = "Rare"`, `GuaranteedModifier`). `GeodeOrder.Sorted` leaves them out (shop tabs, cash pack values and admin lists are unchanged), `SortedLucky` / `LuckyKey` list them, and cash buying refuses them.
- **Odds:** `HatchOdds.Chances` drops rarities below `MinRarity` and rescales the rest. LuckyForest is Shroomy 66.7%, Nesty 26.0%, Berry 6.7%, Treebo 0.7%; 10,000 simulated rolls matched.
  - **Finding:** luck only moves Common/Uncommon versus Rare+, so it has no effect inside a Lucky Geode. 2x Luck, the meter's timing bonus and the server luck boost don't change Lucky odds. **Kept as is (user, 2026-10-24: "luck shouldn't boost lucky geodes").** The odds view shows one set of numbers for Lucky Geodes.
- **Cracking:** the pit cracks owned Lucky Geodes first (highest zone first), uses and moves the base zone's pity counters, and always gives a modifier (the current weather's, or a weighted roll over the five, via `WeatherService:RollAnyModifier`).
- **Buying:**
  - `SetLuckyGeodeZone` picks the zone (validated against strength; otherwise the zone your strength reaches).
  - `GeodeService:GrantLucky` adds them to the geode inventory.
  - Four products (9 first-only, 49, 129, 399) are registered once ids exist; the first-only one sets `Offers.FirstLuckyGeode`.
- **Policy:** `PassService` caches `PolicyService` `ArePaidRandomItemsRestricted` (treated as restricted if the call fails) as the `RandomItemsRestricted` attribute, for the UI to hide Lucky Geodes.
- **Admin:** "+1 Lucky Geode" (`lucky`) on the Roks tab.

Step 6, first part (2026-10-24), not yet playtested:
- **`OfferService`** (new) owns the starter pack and Claim x3.
  - **Starter grant:** cash worth 20 geodes of your zone (23 for players where paid random items are restricted), 30 min 2x Strength, 1 Lucky Geode (skipped when restricted), and Champ once (`StarterPack.Bought`). With a full Backpack, Champ waits (`RokPending`, checked every 5 s). A duplicate receipt gives everything again except Champ.
  - **Offer window:** opens for 24 h when the tutorial finishes (`StarterPack.OfferEndsAt`). One second 24 h window after a rebirth if the first one ran out unbought (`SecondChanceUsed`). `IsStarterOfferOpen` is there for the UI.
  - **Claim x3:** `PedestalService` now fires `OfflineEarned(player, amount, seconds)`. If you were away at least 10 min, you're out of the tutorial, and the amount is worth at least one geode of your zone, it's stored in `Offline.LastAmount` and the `WelcomeBackDue` attribute is set. The grant pays 2x that amount and zeroes it.
- **Champ:** in `PetConfig` as `Exclusive` (100 $/s, Legendary colour, Bloky model as a placeholder). The sell skips exclusive Roks instead of failing the whole sale.
- **Mega cash pack:** in `CashPackConfig` (999 R$, 350 geodes). Packs without a product id are skipped for prompts and grants, so Mega stays off until its product exists.
- **New signals:** `RebirthService.Reborn`, `TutorialService.Finished`, `PedestalService.OfflineEarned`.
- **Admin:** "Grant Starter Pack" (`starter`), "Reset Starter Pack" (`nostarter`, also reopens the 24 h window) and "Grant Claim x3" (`claimx3`; use "Simulate Offline" first).
- **Exclusive Rok stand** (2026-10-24, the rest of step 6, built; seen in Studio Edit, not playtested):
  - **Kingy:** the first exclusive in `PetConfig`, with `IncomeRule = "BestTimes"`, `IncomeMultiplier = 3`, the Secret colour, and Starry's model as a placeholder. `PetService` stores `Income` on the Rok's record as 3x the base $/s of your best non-exclusive Rok, at least its own 100. It updates on load, on every grant, sale and removal, and refreshes pedestal rates when it changes. `RokModifier.Rate` takes that income, so pedestal billboards (`Income` attribute), the Roks panel and the Backpack tooltip show it.
  - **Pending Roks:** `PetService:GrantOrQueue` grants a Rok, or queues it in `PendingRoks` when the Backpack is full, then grants it within 5 s of there being room. Champ and Kingy both use it; `StarterPack.RokPending` was removed.
  - **`ExclusiveService`:** sets up every `ExclusiveStand`-tagged model (price, stock and sold attributes, the Rok shown on top at 3x scale through `PedestalService:ShowRok`, a "Buy" ProximityPrompt). Grants mark `Exclusives[key]`. Sales are counted in the `ExclusiveStock` DataStore (`_Studio` in Studio) with `IncrementAsync`, synced every 60 s. Sales since the last sync are lost if the server shuts down first; the count is approximate by design.
  - **`Components/ExclusiveStand`** (client): billboard text (pitch, stock left or "Sold out", price or "Owned!"). The prompt is hidden when owned or sold out. It opens the Robux prompt once a product id exists; until then it says "Coming soon!".
  - **Studio:** `Workspace.ExclusiveStand` is the base pedestal mesh scaled 1.5x and recoloured gold (255, 176, 0) with a warm PointLight, at the centre of the lobby aisle (42, -300) between the leaderboards. Tag `ExclusiveStand`, attribute `Exclusive = Kingy`, and a `Billboard` with Pitch (Gold), Title (Chrome), Stock and Price (Green).
  - **Admin:** "Grant Exclusive Rok" (`exclusive`) and "Reset Exclusive Owned" (`noexclusive`).

Step 7, gifting (2026-10-24), server side built, not playtested:
- **Catalogue:** `MonetizationConfig.Gifts` lists 19 gift twins (6 passes incl. VIP, 4 boosts, Lucky 1/3/10, 5 cash packs, Kingy). Each has a `ProductId` (all `nil` until made). `PurchaseService/Gifts` holds the per-kind rules:
  - `CanReceive`: not already owning the pass or exclusive; Lucky Geodes not for restricted players.
  - `Apply`: a pass sets `Passes[key]` (`PassService` counts profile flags as owned and now has `Refresh`); boosts, Lucky Geodes, cash at the recipient's zone and exclusives go through the existing services.
  - Also display names, credits, and `GiftsReceived` pruning (last 100).
- **Flow:**
  - `SetGiftTarget(userId, giftKey)` stores the buyer's chosen friend for the session. When a gift product's receipt arrives, `PurchaseService` handles it separately from normal products.
  - **Recipient in the server:** grant, write `GiftsReceived[purchaseId]`, wait for the recipient's save, then record the buyer's receipt and wait for the buyer's save.
  - **Recipient gone:** `DataService:SendMessage` (ProfileStore `MessageAsync`), delivered on their next join through `DataService.MessageReceived`, with the same purchase id check.
  - **No target, gifting yourself, or the recipient can't receive it:** the buyer gets `GiftCredits[giftKey] += 1`.
  - A retried receipt finds `GiftsReceived[purchaseId]` and doesn't grant twice.
  - **Known gaps:** a server crash between sending a message and saving the buyer's receipt loses the remembered target, so the retry gives the buyer a credit as well (the recipient still gets the gift once). A message gift for a pass the recipient bought meanwhile is marked received with nothing granted.
- **Credits:** `SendGiftCredit(userId, giftKey)` spends one credit on a player in the server, free.
- **Announcements:** `PurchaseAnnounced("Gift", buyer, recipient, item)` to everyone, `GiftReceived(from, item)` to the recipient, and notifications to both. `ThankGift(userId)` notifies the giver.
- **Admin:** "Gift To Another Player" (`gift`) applies a gift to the first other player in the server without a purchase, or gives you a credit when there's nobody else or they can't receive it.
- **Data:** `GiftsReceived` and `GiftCredits`.

Step 8 (2026-10-24), built, not playtested:
- **`PurchaseController`** (new, client):
  - `PromptPass`, `PromptBoost`, `PromptServerBoost`, `PromptLucky(index, zone)`, `PromptStarterPack`, `PromptOfflineClaim`, `PromptExclusive`, `Gift(giftKey, userId)`, `PromptCash(shortfall)` (calls `CashPackController`, which stays as the cash part), `CoveringPack(shortfall)` and `OwnsPass(key)`. A missing product id shows "Coming soon!".
  - It handles `PromptGamePassPurchaseFinished` ("<Pass> unlocked!" with the money sound).
- **Robux price tags (R11):**
  - A small yellow block button (`RobuxButton`, cut from the Cannon card's Robux button; colours `MonetizationConfig.RobuxButtonColors`, glyph U+E002) sits on the top-right corner of the Aura Shop next-tier buy button, the Geode Shop Buy 1, the Roks panel +1 Slot and the training Upgrade sign's cash button. The Cannon card's own `RobuxButton` is now used too.
  - Each one shows only when that cash price can't be afforded (and isn't locked), shows the covering cash pack's Robux price, and opens that pack's prompt. `Utils/RobuxButton.Show` paints it.
- **Rebirth Skip removed (R6):** the button is in `ServerStorage.UIBackup.Rebirth.SkipButton_Removed`, the Rebirth button is centred, and `RebirthConfig.SkipRobuxPrice` and its code are deleted.
- **Exclusive stand fix:** the stand's pedestal is turned 180° so Kingy faces the aisle (user: "kingy rock is facing the wrong way").

Step 9, shop UI, first layout (2026-10-24, Studio only, waiting for the user's look):
- `StarterGui.RobuxShop` backed up to `ServerStorage.UIBackup.RobuxShop_BeforeShopUI`. Panel 1120×740 with the existing gold header.
- **Left `Tabs`** (copied from the Geode Shop, count hidden), a purple **Gift!** button under them, and **`Pages`** on the right.
- **`Templates`:**
  - `PageTemplate`: a vertical scroll with a list layout.
  - `SectionTitle`: Gold.
  - `StarterBanner`: magenta card, icon on rays, Title (Gold), red Timer, an `Items` row of `ItemTemplate` tiles, a struck "Worth" price, a big green buy button, a "Best Value!" ribbon.
  - `WideCard`: coloured card, icon on rays, Title, a big Gold "x1 ▶ x2", Blurb, Timer, a `BuyButton` and `AltButton` (15m / 1h), a purple `GiftButton`, Ribbon.
  - `GridCard`: 270×300, icon on rays, Title, green buy button and a small Gift button, Ribbon.
  - `GridTemplate`: 3-column grid.
- **Cards:** coloured background with a white-to-grey gradient and black studs, 4px black outline. ZIndex is raised by 3 because the gui uses Global ZIndex.
- **Preview:** a temporary `Pages.Preview` filled with sample cards for screenshots. It gets deleted when the screen code is wired.
- **Changes after the user's look (2026-10-24):**
  - **No navigation buttons:** the side tabs are deleted and the shop is one scroll (user: "it should be scroll only"), so `Pages` spans the full panel width.
  - **Gift button outside the main frame:** it hangs below the panel's bottom-right corner, 230×72, still a child of `Panel` so it scales and pops with it.
  - **Panel size:** 1120×700, nudged up 50 px so the Gift button fits on screen.
  - This replaces the plan's tabbed layout: sections run top to bottom in one scroll.
- **Rebuilt to match the "Kick a lucky block" store screenshots (2026-10-24, user: "i need to nail the details"):**
  - **Cards:** every card is a `Tray` (dark slate 30,34,46, 3px black outline, 8px padding) holding a bright `Card`: a light-to-base vertical gradient, studs tinted a darker shade of the card colour (not black), and diagonal shine `Stripes` (`124988166234585`, 0.72) clipped to the card. No rays; big icons sit over the card edge.
  - **Buttons:** lime block buttons. Two-line ones carry the price on top and a `Sub` line ("Buy 1 / Buy 3 / Buy 10", "1 hour"). Small purple `Details` / `Odds` pills. A red struck-through `Worth` price above the buy button. Red tilted ribbons ("New!", "Popular") stick out past the top-left corner, and a red "Best Seller!" `Headline` sits top-right. The big lime "Gift!" button hangs outside the panel's bottom-right.
  - **Templates, in scroll order:**
    - `LuckyCard`: Lucky Geode with Rok tiles showing income above, odds bottom-right and a rarity-coloured background for Legendary and Secret, an Odds pill, and Buy 1 / 3 / 10.
    - `WideCard`: the server boosts (huge Gold "x2 + 15M"), personal boosts (`AltButton` for the 1 h price, `Timer`), and VIP (a `Perks` list with icons, "Best Seller!", struck 1,045).
    - `StarterCard`: item tiles joined by big gold "+" signs, income above and name below, red timer, struck price.
    - `PassGrid` of `PassCard` (2 columns, 500×250: title, icon, blurb, Details, price, Owned).
    - `SectionTitle` "Cash", then `CashGrid` of `CashCard` (3 columns, 330×300).
  - **3D frames (user, 2026-10-24: "the dark frame should've gone around what we had before, with the darker part to make it look more 3d like the rest of the games buttons"):** the slate tray is replaced by the block-button recipe.
    - The `Tray` background is the card colour 55% toward black, with a 6px inset and a 3px black outline.
    - The card gets a `Bevel`: a 4px stroke in the light colour pushed toward white.
    - It also gets a bottom `Lip`: 14px, base 30% toward black, with a 3px `Highlight` line.
    - The screen code must repaint all of these per card: tray background, card gradient, stud tint, bevel stroke, lip and highlight.
  - **Inner glow (user, 2026-10-24):** each card has a `Glow` frame with four 70px strips (Left, Right, Top, Bottom). Each strip is white, tinted with the card's light colour 35% toward white, with a `UIGradient` fading 0.05 → 0.6 → 1 inward. The screen code tints the strips per card.
  - **Less white (user, 2026-10-24: "the white layers on the cards are washing out the gradients"):** the glow strips are tinted with the card's light colour (no white mix) and fade 0.35 → 0.8 → 1. The shine stripes are at 0.86 (was 0.72). The bevel stroke is the light colour at 0.45 (was white-mixed at 0.15).
  - **Gradient glow (user, 2026-10-24: "can the inner glow be a gradient"):** each glow strip has a colour gradient from a vivid edge colour (the card's base hue at full brightness, saturation x1.1) to the card's light colour halfway in. Transparency goes 0.2 → 0.75 → 1. Strip backgrounds are white so the `UIGradient` colours show as set.
  - **Icon strokes (user, 2026-10-24: "the icons in the shop need stroke"):** every `Icon` has eight black `IconOutline1..8` copies and an `IconShadow`, like the header icon.
    - Outline offset: 4px for icons 120px and up, 3px from 60px, 2px below.
    - Shadow: black at 0.6, offset px / px+2.
    - **Not on Rok icons:** the rendered Rok icons (`ItemIconConfig`) already have their outline baked in. The Lucky tile icons have no outline copies (user: "way to heavy"), and the screen code must skip outlines for any Rok icon (e.g. Champ or Kingy in the starter pack and exclusive cards).
    - Rebuilt after the resize, which had left the old copies at the wrong sizes and offsets. The screen code must rebuild or resize the copies whenever it resizes an icon. The screen code must set `Image` on the icon, its outlines and its shadow together.
  - **Narrower (user, 2026-10-24: "the shop is too wide"):** the panel is 920×700, and every card is refitted to it:
    - Wide-card text is 330-340 wide from x 220; buy buttons are 210 wide.
    - Lucky buttons are 180 wide, and its tiles 112.
    - Starter items are 104 wide with 80px icons and 30px "+" joiners.
    - Pass grid cells are 400×250 (icons 150, buttons 180); cash grid cells are 260×290.
  - **Still missing art:** a crown icon for VIP and a gift-box icon for the Gift button (the user imports PNGs through Studio).
Step 9, shop screen code (2026-10-25), built and checked in Play by screenshot; motion not seen yet:
- **Code:** `Screens/RobuxShop/` is now a folder.
  - `init`: builds the page from `MonetizationConfig` / `CashPackConfig`.
  - `Cards`: clone, paint the 3D frame and glow, text and shadow, icon plus outline copies, buttons.
  - `Prices`: live `GetProductInfo` prices, cached, with the config price as a fallback.
  - `Motion`: icons bob, the big "x2" text pulses, shine stripes scroll, `SparkleCross` sparkles twinkle on the Lucky, Starter, VIP and Exclusive cards. Off with Low Graphics. One `RenderStepped` connection while the shop is open.
  - Settings live in `RobuxShopConfig` (palettes, button colours, icons per item, texts, `ServerBoostOrder`, motion).
- **Order:**
  - Lucky Geode: the zone your strength reaches, Rare+ tiles with Rok icons, income and odds; the first one is 9 R$ as "First one!"; hidden when `RandomItemsRestricted`.
  - Server Luck / Cash / Strength, with timers.
  - Starter Pack: only while the 24 h offer is open and not bought; items joined by "+", the struck real total, the timer.
  - Personal 2x Cash / 2x Strength: "15 min" and "1 hour" buttons stacked, timer.
  - VIP: crown, perks, struck 1,045, "Owned!" when owned.
  - Kingy exclusive.
  - 2-column passes (Owned state).
  - "Cash" heading, then 5 cash packs (value at your zone, Mega "Best Value!").
- **Clicks** go through `PurchaseController`. With no product ids yet, every buy says "Coming soon!". Details buttons notify the item's blurb, and the Gift! button says "Coming soon!" until the gift picker is built (step 10).
- **Icons:** from the shop-icons session (`IconConfig` Crown, Gift, Clock, Backpack, LuckyGeode, AutoOpen, ServerBadge, Cash1-5). Champ and Kingy still have no rendered icon (the crown stands in) and need the `item-icons` skill.
- **Studio:** the preview page is deleted; `Pages` starts empty and the code fills it.
- **Changes after the user's look (2026-10-25):**
  - The icon bob and the "x2" pulse are removed (user: "the animations are rather laggy"). Only the shine drift and the sparkles remain.
  - Cash cards: the icon is 128px at y 76 and the amount sits at y 146, above the buy button (it was hidden under it).
Step 10, popups and HUD (2026-10-25), built and seen in Play except where noted:
- **Shared helpers:** `UIController/ShopCards` (was `RobuxShop/Cards`: paint, text, icon, buttons, plus `Clock`, `PetIcon`, `FillStarter`, `GiftInfo`) and `UIController/ShopPrices` (was `RobuxShop/Prices`). `UIController:IsModalOpen()` is added. Popups wait while a modal is open, the tutorial is active (by tutorial data, since `TutorialHud` always counts as open), or the hatch reveal, chop meter or training minigame is open.
- **GiftPicker** (modal, `GiftPickerConfig`): the shop's Gift! button opens it. Step 1 is a grid of all giftable items (pass colours, `GiftInfo` name, icon and price; "Free xN!" ribbon when you have gift credits; Lucky Geodes hidden when restricted). Step 2 lists the players in the server with headshots and a Send button: "Has it" for a pass they own, "Can't get it" for Lucky Geodes in a restricted country, "Send free (N)" when you have credits (`SendGiftCredit`), otherwise the gift product prompt (`PurchaseController:Gift`, which sets the target first). It shows "Nobody else is here to gift yet!" when you're alone. Seen in Play, solo only.
- **StarterOffer** (modal): when the 24 h window opens, the server sets `StarterOfferDue`. The client shows the popup at the next free moment and fires `StarterOfferShown`, which clears it, so it shows at most once per window (tutorial end, and the one second chance after a rebirth). It has the starter card with a live timer, the price and "Maybe later", and closes when bought or expired. Seen in Play via admin `nostarter`.
- **WelcomeBack** (modal): shows once per session when `WelcomeBackDue` holds an amount. Money chest, "+$X", Claim! (closes) and Claim x3 (two-line purple button with the price; closes with the money sound when the grant clears the attribute). Seen in Play via admin `offline 2`.
- **OfferRail** (non-modal, top right under the teleport bar, hidden during the tutorial and while a modal is open):
  - One offer slot rotating every 5 s between Starter Pack (with timer, only while the offer is open), Lucky Geode (opens the shop) and "Boost the server!" (Server 2x Luck).
  - Prompt cards, at most 2:
    - "2x X ran out! Keep it going?" with 15 min / 1 hour, once per boost per session, 8 s.
    - The server boost chain card, "Server 2x X / Ends soon! Keep it going?" +15 min, in a boost's last 60 s; it goes away when extended or ended.
    - "A gifted you X!" with Thank! (`ThankGift`); `GiftReceived` now carries the giver's user id.
  - Seen in Play: the slot and the chain card. Not seen: run-out and gift-received cards.
- **PurchaseBanner** (non-modal, top centre, Gold): queues `PurchaseAnnounced` as "A gifted B X!" / "A boosted the server: Server 2x Luck!" for 4 s each, with the money sound. Seen in Play via admin `serverboost Luck`.
- **Studio:** the popups are gutted copies of the RobuxShop panel (header, close, pop). Their cards are clones of the shop templates. `OfferRail.Container` holds `OfferTemplate` / `PromptTemplate`, and `PurchaseBanner` is a `GeodeFallPill` copy.
- **Known nit:** the prompt card title is a little cramped next to the icon ("Server 2x Cash" just fits).
- **Rail restyle (2026-10-25, after the user's reference screenshot):** the offer slot is a floating `OfferTemplate` with no card: a Chrome title, a 170px outlined icon with a gold sparkle, a red timer, a green price ("R$ 25") and an invisible full-size `Button`. Below it, `Boosts` holds two big icon buttons with "Only R$ 19" above each: `StrengthButton` (rainbow fill, `RobuxShopConfig.RailRainbowBoost`) and `CashButton` (gold, `RailBoostColors`), each with an outlined icon overflowing the left edge. Each prompts its 15-min boost. Prompt cards push in above and hide the offer slot while shown. Seen in Play.

Step 12, products (2026-10-25): **34 developer products created through Open Cloud** (universe 10768221393, all for sale) and their ids written into `MonetizationConfig` / `CashPackConfig`:
- Boosts: 15 min / 1 h for Cash and Strength.
- Server boosts: Cash, Strength, Luck.
- Lucky Geodes: first, 1, 3, 10.
- Starter Pack, Claim x3 Offline, Mega Cash Pack, Kingy.
- 19 "Gift: …" twins.

Prices match the plan. They have the default product icon.

**6 game passes created through Open Cloud (2026-10-25)**, once the user added the game pass scope to the key:

| Pass | Id | Price (R$) |
|---|---|---|
| 2x Luck | 2052498180 | 299 |
| 2x Strength | 2053392229 | 249 |
| 2x Cash | 2052162295 | 199 |
| Auto Open | 2053686145 | 199 |
| Big Backpack | 2055384154 | 99 |
| VIP | 2053344170 | 799 |

All are for sale, ids are in `MonetizationConfig.Passes`, and each has a 512px icon: the icon pack's clover, arm and green cash, plus the shop's Auto Open, Backpack and Crown PNGs.

**Rail tweaks (user, 2026-10-25):** the offer slot shows only the Starter Pack (no rotation; hidden once bought or expired). The "Only R$ 19" labels use the `Chrome` style, and the gold sparkle is removed.

**VIP perks (2026-10-25), seen by value in Play:**
- `ChatTagController` (new) now owns `TextChatService.OnIncomingMessage`. It combines the #1 leaderboard tag (`CrownController:ChatTag(player)`, which used to set the callback itself) with a gold `[VIP]` tag and a gold name for players with the `PassVIP` attribute.
- Colours and text are in `MonetizationConfig.Vip`.
- Checked with fake VIP: the message prefix came out as `[#1 Strength] [VIP] Archrono:` with the VIP tag `#FFD500` and the name `#FFC400`.
- The gold name is in chat only; the overhead Roblox name can't be recoloured without a custom nametag.
- **Gold base with red carpet (user, 2026-10-25, replaces "gold name" as the VIP perk):**
  - `VipBaseService` (new) recolours the VIP owner's plot from `MonetizationConfig.Vip.Base.PartColors`: floor dark gold, stone gold, pit darker gold, walkway trim red. The original colours are kept in an `OriginalColor` attribute and restored when the plot is released or VIP is lost.
  - It adds red Fabric `VipCarpet` strips: one outside, under the spawn, and one up the walkway's stone centre to the pit.
  - The shop's VIP perk reads "Gold base + red carpet", and the VIP game pass description was updated on Roblox to match.
  - Seen in Play with fake VIP before the walkway strip was added. The walkway strip is untested; the user is checking it.

**Fixes after the first live test (user, 2026-10-25):**
- **Rail:** the "Only R$ 19" labels sit higher, with a bigger gap, and draw above the buttons, so the hover grow doesn't cover them.
- **Offline claim:** Claim! didn't do anything. It now fires `ClaimOffline`, and the server banks every pedestal pad (`PedestalService:CollectAll`). Claim x3 also banks the pads, plus the 2x extra.
- **VIP base:** ivory and gold instead of all gold.
  - Floor dark ivory (214,198,160), stone light ivory, pedestals lightest ivory.
  - Trim, pit and pad edges gold.
  - Red carpet unchanged.
  - The recolour now matches parts by name anywhere in the plot, so the pedestals are included.
- **VIP base, second pass (user):** stone and trim both gold (255,190,0); pedestals darker ivory (196,178,136); floor stays dark ivory; no red carpet (`Carpets = {}`). The perk text and pass description now say "gold VIP base". Skip Rebirth stays removed (user confirmed).
- **"Keep it going?" popup:** now floating like the offer slot, with no card frame: Chrome title, 110px outlined icon, "Keep it going?", two stacked lime buttons, and a small X.
- **Starter pack offer icon:** a stack of its contents with outlines (cash, strength arm, Lucky Geode, and Champ's icon once it exists) instead of the gift box.
- **Boost pill format (user, 2026-10-27):** "2x Strength (14:52)", or "(1:05:00)" past an hour. While paused, the server stores the frozen seconds left in `BoostPaused<Key>` (a number) instead of re-sending the end time every second. That end-time resend had made the text jump and re-wrap each second.
- **2x Strength boost counts down only while training** (`OnlyWhileTraining`, `TrainingService:IsTraining`). While it's paused, the player gets a `BoostPaused<Key>` attribute and the pill reads "2x Strength (28m15s) paused". The shop card says "Counts down only while you train".
- Geode Shop: turning the 2x Luck odds view on prompts the 2x Luck pass once per opening for non-owners (odds still toggle for everyone, per §00). A full Backpack shows "Bag Full! Tap for +100 slots" and tapping it prompts Big Backpack (just "Bag Full!" for owners).

Boost pills (2026-10-24, pulled forward from step 10 at the user's request; seen in Studio Edit):
- `StarterGui.BoostPills` has a `Stack` of pills above the weather pill, styled like the weather pill (a clone of its Container: right-aligned label in a text style, icon with outlines and shadow, gradient backdrop). One pill per active boost, e.g. "2x Strength (9m54s)", or "(1h05m)" past an hour.
- Covered: personal 2x Cash / 2x Strength and Server 2x Cash / Strength / Luck. The list lives in `MonetizationConfig.BoostPill.Pills`.
- `Screens/BoostPills.luau` reads the `BoostEnds<Key>` player attributes and `ServerBoostEnds<Key>` workspace attributes, and moves the stack up with the screen scale so it stays just above the weather pill.
- **Free taste fix:** the free 5-min boost is once per player (`Offers.BoostTaste`). Admin "Reset Tutorial" now clears that flag, so skipping the tutorial again gives the boost again. Prices and numbers stay *draft* until playtested and checked in the balance model; the balance checks in section 11 must pass before each item goes on sale.

How it got here:
- First pass: from the code, the Master Game Plan and the vault.
- Second pass: the user shared 20 screenshots of other games' Robux UI and the `09 Monetization` notes (see [[Monetization References]]).
- User decisions on 2026-10-24:
  - **Timed boosts are crucial** to turn players into payers.
  - **Paid geodes are fine.** This reverses §00 "geodes are never sold for Robux".
  - **Gifting and server-wide boosts are in.** Players keep a server boost going together, and gifting encourages playing with friends.

Every price and number marked *draft* goes in config and is checked in a playtest and the [[Balance Model]]. Studio UI is built with the `studio-ui` skill and shown to the user before it's final. This plan covers two To Do items together: the Robux shop and expanded monetization with a starter pack.

## Decisions (approved 2026-10-24, the user accepted every recommendation)

| # | Question | Decision | Why |
| --- | --- | --- | --- |
| R1 | **Starter pack: what's in it, and for how much?** | **29 R$, a developer product, once per player:** cash worth 20 geodes of your zone, **Champ** (an exclusive Rok, 100 $/s, can't be sold), 30 min of 2x Strength, and 1 Lucky Geode. The price button has the real separate total struck through above it ("~~199~~"). | A 29 R$ starter pack gets about 3% of players to buy (notes). A developer product stays off the game page's Store tab. The struck price is the real sum of the items' shop prices, so it isn't a fake anchor. |
| R2 | **When is it offered, and does it expire?** | **A real 24 h timer** (screenshots 17-19) starting when the tutorial ends or is skipped. A popup at the start, a timer on the HUD offer and the shop banner. **When it reaches 0 the offer really ends.** One "Back for 24 h!" second chance after the first rebirth, if not bought. | The user keeps pointing at timed starter packs. A timer that really ends is honest urgency; one that resets or keeps selling breaks the false-advertising rule. The second chance catches players who weren't ready yet. |
| R3 | **Personal timed boosts** | **2x Cash and 2x Strength, 15 min for 19 R$ or 1 h for 59 R$.** They stack time up to 6 h and count down only while you play. A free 5-min 2x Strength when the tutorial ends, and a "Keep it going?" card when a boost runs out. | The user's call: boosts are how players start paying. About 1-1.5 R$ per minute matches the notes. |
| R4 | **Permanent passes** | **2x Luck 299, 2x Strength 249, 2x Cash 199, Auto Open 199, Big Backpack 99**, and **VIP 799**: all five plus a VIP chat tag and a gold name (screenshot 19), 24% off. Each card has a **Details** button (screenshots 18, 20). | The notes suggest 5-8 passes, a bundle 20-30% off, and putting new perks into the existing VIP. Other games price 2x passes at 249-399; we're a new game, so the low end. |
| R5 | **What does 2x Cash double?** | **Chop cash and Diamond Rock pay.** Not pedestals, offline income or sell value. | Keeps the offline target ([[Balance Pass Oct 18]]) and hatch-and-sell under 100%. |
| R6 | **Welcome back with Claim x3** | **Yes, 29 R$:** a popup on join showing what your pedestals earned offline, with **Claim** (free) and **Claim x3** (adds 2x the amount as cash). | The notes call offline multipliers a simulator must-have. Screenshots 2 and 12 show the popup (12 sells it for 11 R$). |
| R7 | **Paid geodes: what form?** | **A Lucky Geode per zone:** that zone's Roks, **Rare or better only**, with a **guaranteed weather modifier**. 1 for 49, 3 for 129, 10 for 399 R$, and your **first one ever for 9 R$**. Bought geodes go into your geode inventory and are cracked at the pit like any other geode, so they count toward pity. Odds are shown before buying, and they're hidden for players in countries where paid random items are restricted (section 4). | Screenshot 18's Robux lucky block (Buy 1/3/8) and screenshot 16's 9 R$ random pet are the model. Rare+ with a modifier makes it clearly better than a cash geode, so it isn't just a cash pack in disguise. Cracking at the pit keeps the meter, pity and the reveal. |
| R8 | **Server-wide boosts** | **Server 2x Cash and Server 2x Strength, 15 min, 99 R$ each.** Buying one while it's running adds 15 min (up to 2 h). Everyone in the server gets it, the buyer's name is announced, and everyone sees "Keep the server boost going?" in its last minute. **Server 2x Luck for 15 min at 169 R$** (screenshot 18) too. | The user's call. Free players benefit too, so it's good for the server. The last-minute offer is how one purchase becomes a chain. Server Luck is the one exception to §00's "Robux luck is only the 2x Luck pass": it is server-wide, never personal. |
| R9 | **Gifting** | **Gift any pass, VIP, boost, Lucky Geode or cash pack to a player in your server.** A big Gift button sits next to Buy (screenshot 18), you pick from a list of players, and the server announces "A gifted B 2x Luck!". Starter Pack and Claim x3 aren't giftable. | The user's call: gifting encourages playing together. Roblox can't gift game passes, so each giftable item gets a developer product "gift twin" that grants it to the friend (section 7). |
| R10 | **Big-ticket items** | **Mega cash pack** (999 R$, 350 geodes) now. **An exclusive Rok stand in the lobby** (screenshots 13, 15): one big Rok per update on a glowing pedestal with a Buy prompt, 1,499 R$, income **always 3x your best Rok**, with a server-wide stock (draft 10,000) shown on it and "Sold out" when gone. | The notes say a full shop should reach at least 3,000 R$ and that items seen without opening a menu sell most. Screenshot 13 promises 12x; 3x keeps pedestals from taking over income. |
| R11 | **Rebirth Skip and the Robux buttons by cash prices** | **Remove Skip** (Robux never skips the rebirth gate). **Show a Robux button beside every cash price you can't afford** (screenshot 7), opening the covering cash pack. | The Skip button contradicts [[Rebirth Gated By Strength]]. A visible Robux price sells better than the shortfall prompt alone. |
| R12 | **In-world purchase spots** | **Yes:** a 2x Strength sign on each training stand, 2x Luck and Auto Open signs plus a Lucky Geode pedestal at the Geode Shop, the exclusive Rok stand, and a "Bag full" Big Backpack button. No Robux-spent leaderboard. | Sales from spots in the world can be up to 10x those from a menu (notes). A board ranking kids by spending puts pressure on them. |
| R13 | **Robux training mats** (screenshot 14: 119 / 299 / 719 for 75x / 300x / 1000x)? | **No.** 2x Strength (pass, boost, server boost) covers it. | Training time is the core pacing ([[Balance Pass Oct 18]]), and 30x mats would make every gate take seconds. If wanted later, one "Gold Mat" at x3 for 299 that replaces the 2x Strength pass is the most it could be. |

Also, outside the code:
- Regional pricing: on for everything 19 R$ and up, off under 10 R$.
- Update the maturity questionnaire: **paid random items: yes** (Lucky Geodes).
- Private servers: decide (§10 leaves it blank).
- Never buy our own passes in Studio: a reported bug charges real Robux. Use the admin fake pass.

## Read first
`AGENTS.md` (Purchases, Player data, UI), `Vault/Index.md`, [[Monetization References]], `AutoOpenGeodePlan.md`, `GeodePitySystemPlan.md`, `Chop_a_Rock_Master_Game_Plan.txt` §00 and §10 (Decision Log 2026-10-24), `ROADMAP.md`, and the vault notes `Cash Packs`, `Cannon Shop`, `Rebirth Gated By Strength`, `Balance Pass Oct 18`, `Balance Model`, `Geode Shop`, `Geode Fall`, `Weather`, `Pedestals`, `Leaderboards`, `Menu Panel Style`, `Tile Style Reference`, `UI Feel`, `Tutorial`, `Sell Shop`, `Index`.

Code:
- `PurchaseService` (`init`, `Products`), `DataService`, `PlayerData`.
- `CashPackConfig`, `Utils/CashPack`, `CashPackController`.
- `GeodeService` (`init`, `Cracking`, `Purchasing`, `Luck`), `GeodeConfig`, `HatchOdds`.
- `PedestalService/Earnings`, `LeaderboardService/Passes`, `CrownController`.
- `Screens/RobuxShop`, `Screens/Rebirth`, `Screens/CannonShop`.

Skills: `studio-ui`, `studio-playtest`, `model-workflow`, `item-icons`.

## Why
The user wants one shop for everything sold for Robux, more enticing than the other panels, and more to sell, with a one-time starter pack for new players. Today the only working Robux items are four cash packs that show up when you can't afford something. Both the tier-list session and the monetization notes rank cash packs as the weakest seller.

The things that sell aren't in the game yet:
- a cheap first purchase
- timed boosts
- permanent 2x passes and a VIP bundle
- offline multipliers
- paid geodes
- server boosts and gifts
- big-ticket items

## What is already decided (do not change)
- **Paid geodes are allowed** (user, 2026-10-24; Decision Log updated). They follow Roblox's paid random item rules (section 4).
- **Robux never skips a gate:** no rebirth skips and no stand skips. Robux buys cash, boosts and Roks ([[Rebirth Gated By Strength]]).
- **Personal Robux luck stays the permanent 2x Luck pass.** No personal luck potions (§00). The one exception is the server-wide Server 2x Luck (R8, approved 2026-10-24).
- **No middleman** ([[Cash Packs]]): a buy button you can't afford opens the Robux prompt straight away. The shop is the catalogue.
- **Auto Open is a 199 R$ game pass** (`AutoOpenGeodePlan.md` A6). It may crack owned Lucky Geodes but **never buys** them.
- `PurchaseService` owns `ProcessReceipt`; grants are confirmed only after a save holds the reward and the receipt id.

## 1. What is sold today

| Item | Kind | Id | Price | Where | State |
| --- | --- | --- | --- | --- | --- |
| Cash pack Small / Medium / Large / Huge (3 / 12 / 40 / 150 geodes of your zone) | Developer product | 3720804848 / 51 / 55 / 60 | 25 / 79 / 199 / 499 | Prompted when you can't afford an Aura, Cannon or Geode Shop buy, a +1 Slot, or the Upgrade sign | **Live** |
| 2x Luck | Game pass | none (`LuckConfig.GamepassId = nil`) | not set | Geode Shop `LuckToggle` shows odds with it | **Not made**; ownership cached in `GeodeService`, no prompt |
| Auto Open | Game pass | none | 199 draft | Geode Shop (planned) | **Planned** |
| Skip Rebirth | none | none | 25 shown | Rebirth panel | **Shown, does nothing** (R11) |
| Cannon Robux button | none | none | "99" placeholder | Cannon Shop card, hidden | **Hidden** (R11) |
| Training stand products | Developer product | 3719074519 / 40 / 43 / 45 / 47 | 25-149 | nowhere | **Off sale** |
| Robux Shop | Screen | n/a | n/a | Top menu button `Shop` | **Empty panel** |

## 2. Product list (all prices *draft*)

Price ladder (notes): entry 9-29 R$ for the first purchase, core 99-299, big-ticket 399-1,499. A player who bought one of everything would spend about 5,500 R$.

| Item | Kind | Price | What it does |
| --- | --- | --- | --- |
| **Starter Pack** | Dev product, once, 24 h offer | **29** | Cash worth 20 geodes, Champ, 30 min 2x Strength, 1 Lucky Geode |
| **First Lucky Geode** | Dev product, once | **9** | 1 Lucky Geode of your zone |
| **Lucky Geode** ×1 / ×3 / ×10 | Dev product | **49 / 129 / 399** | Rare+ Rok of the chosen zone with a guaranteed modifier |
| **2x Cash / 2x Strength, 15 min** | Dev product | **19** each | +1x while it runs, play time only |
| **2x Cash / 2x Strength, 1 h** | Dev product | **59** each | Same |
| **Server 2x Cash / Server 2x Strength, 15 min** | Dev product | **99** each | +1x for everyone in the server; adds 15 min if one is running |
| **Server 2x Luck, 15 min** | Dev product | **169** | Luck +1x for everyone in the server (R8) |
| **Claim x3 offline** | Dev product | **29** | Adds 2x your last offline earnings as cash |
| **2x Luck** | Game pass | **299** | Luck x2 on every crack, within each geode's rarity cap |
| **2x Strength** | Game pass | **249** | Training strength x2 |
| **2x Cash** | Game pass | **199** | Chop and Diamond cash x2 |
| **Auto Open** | Game pass | **199** | `AutoOpenGeodePlan.md` |
| **Big Backpack** | Game pass | **99** | Backpack 100 → 200 Roks |
| **VIP** | Game pass | **799** | All five passes + VIP chat tag + gold name (1,045 separately) |
| Cash packs Small / Medium / Large / Huge / **Mega** | Dev product | 25 / 79 / 199 / 499 / **999** | Mega = 350 geodes of your zone |
| **Exclusive Rok** (one per update) | Dev product, once per player, limited stock | **1,499** | Earns 3x your best Rok's income; can't be sold |
| **Gift twins** | Dev product | same as the item | The same item granted to another player |

Why these kinds:
- **Developer products** for anything bought more than once, anything gifted, and the starter pack (so it stays off the Store tab).
- **Game passes** for permanent perks. Simulator players expect them, and Roblox checks ownership.
- **VIP:** while a player owns 3 or more passes, it's hidden, since Roblox can't charge less for passes they already have. Passes received as gifts count as owned.

Not sold:
- skipping a rebirth or a stand
- personal luck potions
- auto-chop
- Robux training mats (R13)
- a Robux-spent leaderboard

Later, with Rok upgrades: a 100%-chance fuse (screenshot 9).

## 3. Timed boosts

### Personal (R3)
- **Products:** 2x Cash and 2x Strength, 15 min (19) or 1 h (59). Buying more adds time, up to 6 h stored.
- **Countdown:** only while you're in the game. Every minute you paid for is one you play, and the timer on screen is a reason to stay. The alternative is real time, which pushes players to come back sooner but wastes time they paid for.
- **Free taste:** 5 min of 2x Strength when the tutorial ends or is skipped, so it runs out partway through the first real training.
- **"Keep it going?":** when a boost runs out, a card slides in on the right with +15 min for 19 and +1 h for 59. At most once per boost kind per session. Never during a chop, reveal, cannon flight or the tutorial. It closes itself after 8 s.

### Server-wide (R8)
- **Products:** Server 2x Cash and Server 2x Strength, 15 min, 99 R$ each. Server 2x Luck, 169 R$.
- **Who gets it:** everyone in the server, free players included.
- **Buying while it's running** adds 15 min, up to 2 h stored.
- **When bought:**
  - A top banner and a chat line: "**Name** boosted the server: 2x Cash for 15 min!"
  - Confetti on every screen.
  - A server pill shows the time left and the last three buyers: "Server 2x Cash 12:30, thanks Name, Name, Name".
- **The chain:** in the boost's last 60 s, every player sees a small "Keep the server boost going? R$ 99" card (with a Gift-free, one-tap prompt). When someone extends it, the banner says "**Name** kept it going! +15 min".
- **Storage:** server memory only. It ends if the server shuts down; the 2 h cap limits what could be lost. It isn't saved in anyone's profile.

### Stacking and labels
- Every source adds +1x: pass, personal boost and server boost. All three make x4.
- The HUD shows the real total ("x3 Cash 14:52"). A "2x" that isn't 2x breaks the false-advertising rule.
- Luck: Server 2x Luck adds the same way (pass x2 + server +1 = x3). The luck cap (`LuckConfig.LuckyShareCap` 0.9) still applies.

### Where boosts are sold
- The shop's Boosts tab.
- HUD pills: tap one to add time.
- The training stand sign.
- The run-out card and the server chain card.

## 4. Lucky Geodes (paid geodes, R7)

### What they are
- **One Lucky Geode per zone**, unlocked at the same strength as that zone's geode. It's a `GeodeConfig` entry `Lucky<Zone>` with `RobuxOnly = true`, `MinRarity = "Rare"` and `GuaranteedModifier = true`.
- **Odds:** the zone's Rare, Epic, Legendary and Secret by their usual weights, rolled with `HatchOdds.RollAtLeast(geode, "Rare")` (what Geode Fall uses), with the player's luck applied as usual. Every crack also rolls a weather modifier (`WeatherService` weights), so it's never a plain Rok.
- **Buying:**
  - The shop's Lucky Geode card (or the Lucky Geode pedestal at the Geode Shop) has zone tabs.
  - The client sends `SetLuckyGeodeZone(zoneKey)` and then prompts the product.
  - The grant adds n geodes of that zone to `data.Geodes`. If there's no valid choice, it uses the highest zone your strength reaches.
  - They're cracked at the pit like any geode, so the timing meter's luck bonus, the reveal and Index all work unchanged. They add to and reset **that zone's pity counters**.
- **Prices:** first one ever 9 R$ (its own product, once, shown as "Your first one: 9!"), then 1 / 3 / 10 for 49 / 129 / 399.

### Paid random item rules (must ship with it)
- **Odds shown before purchase:** an "Odds" button on the card and the pedestal opens the exact percentages, with and without 2x Luck. They're computed from config, like the Geode Shop.
- **Never nothing:** every geode gives a Rok. A full Backpack never blocks or wastes a purchase; the geodes wait in inventory.
- **Restricted countries:** on load, `PolicyService:GetPolicyInfoForPlayerAsync(player).ArePaidRandomItemsRestricted` is cached (pcall; treated as restricted if the call fails).
  - Restricted players never see Lucky Geode buttons, gifts of them, or their offers.
  - The starter pack's Lucky Geode is swapped for 3 more cash geodes for them.
  - A gift of a Lucky Geode to a restricted player can't be chosen.
  - If a receipt still arrives (an exploit), it's granted. They paid, and refusing would loop.
- **No trading:** Roks can't be traded for Robux or items outside the game (there's no trading).
- **Maturity questionnaire:** answer "yes" to paid random items.
- **Auto Open** may crack owned Lucky Geodes but never buys them.

## 5. Gifting (R9)

### The player's view
- **Where:** a big **Gift** button in the shop's bottom-right corner (as big as Buy, screenshot 18), plus a small gift button on every giftable card (screenshots 3 and 4).
- **Picking a friend:** a list of players in the server with headshots. A player is greyed out with a reason when they already own that pass, are restricted for Lucky Geodes, or haven't loaded.
- **Confirm** opens the Robux prompt for that item's gift twin.
- **After the purchase:** the server banner says "**A** gifted **B** VIP!". B gets a popup with the item and a "Thank A" button that sends a chat line. Both get confetti.

### What can be gifted
- Passes and VIP, both personal boosts (15 min and 1 h), Lucky Geodes (1 / 3 / 10) and cash packs.
- **Not giftable:** Starter Pack and Claim x3 (both per-player).

### Crash-safe flow (gift receipts can't use the plain grant)
A gift changes two profiles, so `PurchaseService` handles gift twins in a child module, `Gifts`, instead of `Products`.
1. Before prompting, the client sends `SetGiftTarget(recipientUserId, itemKey)`. The server checks it and stores it for the buyer's session.
2. When the receipt arrives:
   - **The recipient is loaded in this server:** grant the item into the recipient's profile, write `GiftsReceived[purchaseId]` in the same step, and wait until a save of the recipient's profile holds it.
   - **The recipient has left:** send the gift to their profile with ProfileStore's message queue (`MessageAsync`; check the vendored ProfileStore version supports it). It's granted on their next join by the same idempotent code.
3. Then the usual buyer side: `Receipts[purchaseId]` in the buyer's profile, wait for its save, `PurchaseGranted`.

Why it's safe:
- A retried receipt finds `GiftsReceived[purchaseId]` already set and skips to step 3, so a crash can't grant twice.
- The receipt isn't confirmed until both sides are saved, so a paid gift can't be lost.
- **No target, or the recipient already owns the pass by the time it arrives:** the buyer gets a **gift credit** for that item (`GiftCredits[itemKey]`), shown in the Gift menu. They can send it to anyone later for free, so nothing paid is wasted.

### Pass gifts
- The recipient gets `Passes[key] = true` in their profile. `PassService` treats a profile flag as owned, alongside Roblox ownership.
- A gifted VIP sets all five passes plus the VIP perks.

## 6. Starter pack, Welcome back, exclusive Rok

### Starter pack (R1, R2)
- **Contents:**
  - Cash worth 20 geodes of your zone, worked out when it's granted.
  - **Champ:** exclusive, 100 $/s, can't be sold, not counted for Index completion. The model is Bloky's body and eyes with a karate headband and a gold body.
  - 30 min of 2x Strength.
  - 1 Lucky Geode of your zone (3 more cash geodes for restricted players).
- **Struck price:** the real separate total: 20 geodes ≈ 132 (Medium rate) + 38 (2 × 15 min) + 49 (Lucky Geode) = 219, shown as "~~219~~". It's computed from config, so it stays true when prices change.
- **Timer:** `StarterPack.OfferEndsAt` = tutorial end + 24 h (real time, *draft*).
  - It shows on the popup (screenshot 10 layout), the HUD offer slot (screenshot 17) and the shop banner (screenshot 19).
  - At 0 all of them disappear and the product can't be prompted.
  - After the first rebirth, if not bought, one more 24 h window ("Back for 24 h!", `SecondChanceUsed`).
- **Only once:** `StarterPack.Bought` is set in the grant. The client hides it, and buttons disable while a prompt is open. A duplicate receipt (two servers or an exploit) grants the cash, boost and geode again but no second Champ, and returns true.
- **Full Backpack:** Champ waits (`RokPending`) and is granted once there's room.

### Welcome back (R6)
- **What it shows:** `PedestalService` records the offline amount it credits (`Offline.LastAmount`, `LastAt`). On join, if you were away at least 10 min and the amount is at least 1 geode of your zone, `WelcomeBack` shows (screenshots 2 and 12): a clock-and-money icon, "Your Roks earned while you were away", the amount on rays, **Claim** (green) and **Claim x3** (rainbow, 29 R$).
- **The Claim x3 grant:** adds `2 × LastAmount` as cash and zeroes it in the same step, so a retry can't pay twice. A duplicate returns true with nothing extra.
- **Not shown** on the first join or during the tutorial.

### Exclusive Rok stand (R10)
- **Where:** a glowing pedestal in the lobby with a big Rok on it, idle motion and an aura ring (screenshot 13).
- **Billboard:** "Best Rok in the game! Always 3x your best", the price, and "Stock: 5,835 / 10,000".
- **Buying:** a ProximityPrompt "Buy, R$ 1,499". Once owned, the prompt shows "Owned". It's also on the shop's Featured tab.
- **Income:** `IncomeRule = "BestTimes"`. Its $/s is 3x the base $/s of your best non-exclusive Rok, recalculated when your Roks change. It can't be sold, and it can be gifted.
- **Stock:**
  - A global count in a DataStore key, increased with `UpdateAsync` in a task *after* the receipt is confirmed, never inside the grant.
  - Servers read it every 60 s.
  - At the limit, the stand shows "Sold out" and hides the prompt.
  - A handful of extra sales across servers are possible and allowed, since a paid receipt is never refused. The shown number is labelled as stock, not a promise.
- **One per update:** each new exclusive gets its own `PetConfig` entry and stock key. The last one stays visible as "Sold out" in the Index's Exclusive row.

## 7. The shop

### Layout (`StarterGui.RobuxShop`, rebuilt inside the existing `PopRoot.Panel`)
- **Size:** 1120×740, the biggest panel in the game. `ScreenScale` fits it to phones.
- **Header:** a Gold block header with "Shop" in `Chrome`, the basket icon overlapping the corner (screenshots 18-20 use the same yellow header).
- **Left tabs:** **Featured**, **Boosts**, **Geodes**, **Passes**, **Cash**.
- **Featured:**
  - The Starter Pack banner with its timer while the offer runs. After that, VIP.
  - The exclusive Rok card (stats tiles: Income "3x your best", stock).
  - The server boost card ("Server 2x Cash x2 + 15M", screenshot 18) with live state.
  - A Lucky Geode strip.
- **Boosts:**
  - Personal boost cards in the "Double your Strength: x1 ▶ x2" layout (screenshot 6), with timers.
  - The server boost cards below them.
- **Geodes:** the Lucky Geode card like screenshot 18. Zone tabs, the six Roks with icons and odds % (Common and Uncommon shown greyed as "not in this geode"), "Modifier guaranteed!", buttons Buy 1 / Buy 3 / Buy 10, an Odds button, and a gift button beside each.
- **Passes:**
  - VIP on top (screenshot 19: crown, perk list, "Best Seller!").
  - Then a 2-column grid of coloured cards like screenshot 20: name, icon, one-line blurb, price, a purple **Details** button.
  - Colours: Luck green, Strength orange, Cash gold, Auto Open sky, Backpack purple.
  - Owned cards show a green tick, move to the end and keep their gift button.
- **Cash:** a 3-column grid like screenshot 3. Each card shows the cash it gives you now; the icon grows with the pack size.
- **Every card:** Buy and Gift buttons, plus the big Gift button in the corner.
- **Prices:** live from `MarketplaceService:GetProductInfo` (regional pricing), with the config price as a fallback. If the live price can't be read, show only the Robux icon.

### Making it more enticing than the other panels
The house style stays: sharp corners, black outlines, studs, block buttons, `Chrome` titles, no all caps. On top of it, all *draft* in `RobuxShopConfig.Motion`:
- **Opening:** the world blurs behind a dark shade, the panel pops, then cards pop in one after another (0.05 s apart, Back easing) with a rising chime.
- **Rays** turn behind every icon (20°/s in the card's colour). The starter pack's and the exclusive Rok's turn at 40°/s and shift colour.
- **Icons** bob ±4 px on a 2 s loop, out of step with each other.
- **Big numbers:** "x2" pulses (1 ↔ 1.06). 2x passes use a sliding rainbow gradient (the notes: make 2x stand out with a rainbow).
- **Timers:** the starter pack's ticks in red `Chrome` (screenshots 17-19). The server boost's ticks with a pulsing ring in its last minute.
- **Starter and exclusive cards:** a pulsing outline and twinkling stars.
- **Ribbons** ("New!", "Best Seller!", "Best Value!") wiggle every 3 s.
- **Header:** a shine band sweeps across every 3 s.
- **Buttons:** `Shimmer` on every unowned price button, and `Tilt` on hover.
- **On purchase:**
  - Confetti burst in the card's colour, a card bounce and the money sound.
  - Then the Owned flip, the timer start or the geode count.
  - Gifts and server boosts also fire the server banner.
- **Tab switch:** a slide and fade (0.15 s).
- **Performance and settings:** one `RenderStepped` connection only while the shop is open. **Low Graphics** turns off rays, stars and confetti.

### Where products show besides the shop
- **The Shop menu button:** it pulses, with a "New!" ribbon while the starter offer runs.
- **HUD offer slot, right side:** cycles every 5 s through the Starter Pack with its timer, the server boost (live, or "Boost the server!"), a personal boost and the Lucky Geode. Tapping it prompts directly.
- **HUD pills:** personal boosts and server boosts.
- **In the world (R12):**
  - A 2x Strength sign on each training stand.
  - 2x Luck and Auto Open signs, and a Lucky Geode pedestal (spinning geode, "Odds" and "Buy" prompts), at the Geode Shop.
  - The exclusive Rok stand.
- **At the moment of need:**
  - Not enough cash: the covering pack, plus a Robux button beside each cash price (R11).
  - "Bag full!": Big Backpack.
  - A boost runs out: "Keep it going?".
  - The server boost's last minute: the chain card.
  - Join: Welcome back.
  - `LuckToggle`: 2x Luck.
- **Not a lobby shop stall:** the shop opens from anywhere. The exclusive Rok and Lucky Geode pedestals are the lobby's in-world sales spots.

## 8. How scattered purchase points route
One client controller, `PurchaseController`, replaces `CashPackController` (which becomes its cash-pack part). It is the only code that prompts purchases and listens for the purchase-finished events. Everything calls it by catalogue key: `Prompt(key)`, `PromptCash(shortfall)`, `Gift(key)`.

| Point | Today | After |
| --- | --- | --- |
| Aura, Cannon, Geode buy, +1 Slot, Upgrade sign when short | `CashPackController:Prompt` | `PromptCash`, plus a visible Robux button (R11) |
| Geode Shop `LuckToggle`, Auto Open, Bag full | Odds only / planned / message | Prompt 2x Luck / Auto Open / Big Backpack |
| Geode Shop | Cash geodes | Plus a "Lucky" tab that opens the shop's Geodes tab |
| Rebirth Skip | Shows 25 | Removed |
| Cannon `RobuxButton` | Hidden | Covering pack price |
| Training stand, Geode Shop signs, Lucky pedestal, exclusive Rok stand | none | `Components/PurchaseSign` (tag `PurchaseSign`, attribute `Item`) |
| Shop, HUD offer, pills, run-out and chain cards, Starter popup, Welcome back | none | `Prompt(key)` / `Gift(key)` |

## 9. Architecture

### Config
- **`MonetizationConfig.luau`** (new), the catalogue. Every item has `Key`, `Kind` (`Pass`, `Product`, `Boost`, `ServerBoost`, `LuckyGeode`, `Cash`, `Exclusive`), ids, `RobuxPrice`, `GiftProductId?`, `DisplayName`, `Blurb`, `Details`, `Colour`, `Icon` and `Ribbon?`.
  - `Passes` (Luck, Strength, Cash, AutoOpen, Backpack, VIP with `Includes` and `ChatTag`).
  - `Boosts` (with `CapSeconds` 21600, `TasteSeconds` 300) and `ServerBoosts` (`Seconds` 900, `CapSeconds` 7200, `ChainOfferSeconds` 60).
  - `LuckyGeodes` (first, 1, 3, 10).
  - `StarterPack` (`OfferSeconds` 86400, contents, `SecondChance`).
  - `OfflineClaim`, `Exclusives` (each `{ RokKey, ProductId, RobuxPrice, Stock, StockKey }`), `PassMultipliers`, `BackpackBonus`.
  - `LuckConfig.GamepassId` and the planned `AutoOpenConfig.GamepassId` move here.
- **`RobuxShopConfig.luau`** (new): tabs, colours, ribbons, offer rotation and `Motion`.
- **`CashPackConfig`:** adds Mega.
- **`GeodeConfig`:** adds the five `Lucky<Zone>` entries.
- **`PetConfig`:** adds Champ and the first exclusive (`Exclusive = true`, `IncomeRule?`).

### Player data
In `PlayerData.luau`, update `Data`, `Template` and `Validate` together. These are new fields only, so no migration is needed.
- `Passes: { [string]: boolean }`: owned through Roblox (cached) or a gift.
- `Boosts: { [string]: number }`: seconds left per boost.
- `StarterPack: { Bought, RokPending, OfferEndsAt, SecondChanceUsed }`.
- `Offline: { LastAmount, LastAt }`.
- `Offers: { TasteGiven, FirstLuckyBought }`.
- `GiftsReceived: { [string]: number }` (last 100) and `GiftCredits: { [string]: number }`.
- `Exclusives: { [string]: boolean }`: bought, so each exclusive is bought once.

### Server
- **`PassService`** (new):
  - Ownership from `UserOwnsGamePassAsync` (pcall, one retry), `data.Passes` (gifts and the cache), and VIP's `Includes`.
  - Server-side `PromptGamePassPurchaseFinished`, re-checked before it counts.
  - `Owns`, `PassChanged`, `Pass<Key>` attributes, and the VIP chat tag (through `TextChatService`, next to the #1 crown tag in `CrownController`).
  - Admin "Fake Pass <key>" (Studio only).
  - Replaces the pass cache `AutoOpenGeodePlan.md` puts in `GeodeService`.
- **`BoostService`** (new):
  - Personal boosts: a 1 s loop counting down in memory, written every 30 s and in `PlayerReleasing`, `BoostEnds<Key>` attributes, the free taste, and `BoostEnded` for the run-out card.
  - Server boosts: in memory, with `workspace` attributes `ServerBoostEnds<Key>` and `ServerBoostBy<Key>` (last three names), the chain card trigger in the last 60 s, and the `PurchaseAnnounced` banner.
  - `BoostService:Multiplier(player, key)` = personal (0/1) + server (0/1).
- **`PolicyService` cache** (inside `PassService`): `ArePaidRandomItemsRestricted` per player, as a `RandomItemsRestricted` attribute.
- **`PurchaseService`:**
  - `Products` gains the boosts, server boosts, Lucky Geodes, Starter Pack, Claim x3, Mega and exclusives. Each is non-yielding and changes only the buyer's profile, except server boosts, which change server memory (approved by the user 2026-10-24).
  - New child `Gifts` for gift twins (the two-profile flow in section 5).
  - `processReceipt` routes gift product ids to `Gifts.Process`; everything else is unchanged.
- **`DataService`:** add `SendProfileMessage(userId, message)` and a message handler on load, for gifts to players who left. Only `DataService` touches ProfileStore.
- **Multipliers:**
  - **Cash:** chop and Diamond pay go through `PassService:ApplyCashMultiplier`: × (1 + pass + personal + server).
  - **Strength:** training does the same.
  - **Backpack:** `PetService:CanAdd` uses the Big Backpack bonus.
  - **Luck:** `GeodeService/Luck` adds the Server 2x Luck boost.
- **`GeodeService`:** Lucky geode config (`RollAtLeast` Rare, a forced modifier roll), `SetLuckyGeodeZone`, pity on the base zone's counters. Auto Open never buys `RobuxOnly` geodes.
- **`PedestalService`:** records the offline amount, sets `WelcomeBackDue`, and handles `IncomeRule = "BestTimes"` Roks.
- **`ExclusiveService`** (new, small): the global stock count, read every 60 s and incremented after confirmed sales, and the stand's state attributes.
- **Champ and exclusives:** `SellShop` refuses them, and `IndexService` lists them in an Exclusive row that isn't counted for completion or claims.

### Networking (`Packets.luau`)
- `SetGiftTarget = Packet("SetGiftTarget", Packet.NumberF64, Packet.String):RateLimit(4, 1)`.
- `SetLuckyGeodeZone = Packet("SetLuckyGeodeZone", Packet.String):RateLimit(4, 1)`.
- `StarterOfferShown = Packet("StarterOfferShown"):RateLimit(1, 5)`.
- `BoostEnded = Packet("BoostEnded", Packet.String)`: server to owner.
- `PurchaseAnnounced = Packet("PurchaseAnnounced", Packet.String, Packet.String, Packet.String, Packet.String)`: kind, buyer, recipient, item. Server to all.
- `GiftReceived = Packet("GiftReceived", Packet.String, Packet.String)`: from, item. Server to the recipient.
- `ThankGift = Packet("ThankGift", Packet.NumberF64):RateLimit(2, 5)`.

### Client
- `PurchaseController`: prompts, gift flow, purchase-finished handling and notifications.
- `Screens/RobuxShop.luau`: tabs, cards, live prices, timers, the Gift button, motion.
- New screens:
  - `GiftPicker` (modal)
  - `StarterOffer` (modal)
  - `WelcomeBack` (modal)
  - `OfferRail` (right side: the rotating offer, run-out and chain cards)
  - `BoostPills`
  - `PurchaseBanner` (gift and server boost announcements)
  - `GiftReceivedPopup`
- `Components/PurchaseSign` for every in-world purchase spot. `Components/ExclusiveStand`.
- Edits: `Rebirth` (remove Skip), `CannonShop`, `Shop`, `GeodeStand`, `Roks` and `TrainingUpgradeSign` (the Robux button by cash prices), `GeodeStand` (Luck, Auto Open, Bag full, Lucky tab).

### Studio (with the `studio-ui` skill; save the place)
- **Back up first:** copy `StarterGui.RobuxShop` to `ServerStorage.UIBackup.RobuxShop`.
- **The shop:** tabs, the five pages, templates (`StarterBanner`, `BoostCard`, `ServerBoostCard`, `LuckyGeodeCard`, `PassCard`, `VipCard`, `CashCard`, `ExclusiveCard`, `Ribbon`, `Confetti`, `Star`), and the corner `GiftButton`.
- **New ScreenGuis:** `GiftPicker`, `StarterOffer`, `WelcomeBack`, `OfferRail`, `BoostPills`, `PurchaseBanner`, `GiftReceivedPopup`.
- **World:**
  - A `PurchaseSign` on `Model_BasePlot`'s training stand.
  - Two signs and the Lucky Geode pedestal at the Geode Shop.
  - The exclusive Rok stand in the lobby. The user places it; keep the aisles clear.
- **Icons:**
  - Reused: Strength arm, money.
  - New: clover, Auto Open, Backpack, clock, VIP crown, gift box, the Lucky Geode (a geode with a rainbow crystal), Champ, and the exclusive Rok (`item-icons`).
  - The user imports new PNGs through Studio so they land in the group.

### Making the products
- **Developer products:** about 40 (items plus gift twins), made through Open Cloud by a script that writes the ids into `MonetizationConfig` ([[Open Cloud Key]] has the dev product scope).
- **Game passes:** 6, made by the user in the Creator Dashboard, or through Open Cloud with a game pass scope.
- **Names and descriptions** state exactly what each item does. The Lucky Geode descriptions say "random Rare or better Rok, odds shown in game".

## 10. Safe purchase handling (summary)
- **Normal developer products:** `ProcessReceipt` is unchanged. The receipt id and reward go in one profile and are confirmed after one save holds both. Grants don't yield.
- **Gift twins:** recipient-first, idempotent by `GiftsReceived[purchaseId]`, through the profile message queue when the recipient has left. Gift credits mean nothing paid is lost (section 5).
- **Server boosts:** server memory changes once per receipt id (the buyer's `Receipts` stops repeats). Lost only if the server shuts down, within the 2 h cap.
- **Once-only products** (Starter Pack, first Lucky Geode, Claim x3, exclusives): guarded by profile flags set in the grant. Duplicates return true with what is safe to give.
- **Game passes:** ownership comes from the server's `UserOwnsGamePassAsync` or the profile's gift flag. Client attributes only pick buttons.
- **Stock and timers** never block a paid grant. They only hide the prompt.
- **Exploits:** no packet grants anything. `SetGiftTarget` and `SetLuckyGeodeZone` only choose where a paid grant goes, and the server validates them.
- **Policy:** odds shown before buying, never an empty result, the PolicyService check for paid random items, honest multipliers, real struck prices and real timers.

## 11. Balance check ([[Balance Model]] v9; re-run as v10)
- **Strength (pass, personal, server):**
  - Each source halves, thirds or quarters training time. At x4: Forest 0.3, Desert 0.8, Jungle 1.3, Ocean 1.6, Snow 2.7 min to each gate.
  - Brakes: the next stand still costs cash, and rebirth still needs the full strength. Server boosts help everyone in the server, so free players get some too.
  - Model: "x2 / x3 / x4" columns on Zone Model.
- **Cash (chop and Diamond):**
  - Halves to quarters the minutes of income needed for auras, cannons, stands and slots.
  - The biggest possible chop reaches about 3.2-3.6x the next stand at x4. That check protected the cash packs from free jackpots, and these players paid or were boosted, so accept it.
- **Lucky Geodes:**
  - **Pedestal income for payers:** Rare+ Roks of your zone with a modifier go straight onto pedestals. A buyer's pedestal income can jump from about 15% of income toward the Legendary/Secret level of that zone. Model: a "Lucky buyer" row on Collection (10 Lucky Geodes per zone).
  - **Sell value per Robux:** a Lucky Rok sells for 60 s of income, or 100 s if modified (all of them are). Check that Robux spent on Lucky Geodes and sold doesn't beat the same Robux in cash packs by much. If it does, lower modified sell value for `RobuxOnly` Roks, not the cash packs.
  - **Pity:** paid cracks move the zone's counters, so a 10-pack gets a buyer closer to the Legendary guarantee. Intended.
- **2x Luck and Server 2x Luck:** the Jungle hatch-and-sell worst case is already 96%. **Run the model with luck x2 and x3 before either goes on sale.** If the Jungle passes 100%, lower Jungle Legendary/Secret sell values or raise the Jungle geode price.
- **2x Cash + Auto Open:** with the first auto-open design (buys and cracks anywhere), the Snow Roks page dropped to about 3.9 min for players with both; accepted for payers. Auto Open has since moved to the pit with owned geodes only ([[Auto Open At The Pit]]), so the player buys geodes by hand and this floor no longer applies. Re-check it when the model is re-run.
- **Exclusive Rok (3x your best):** one pedestal earning 3x your best Rok adds about +40% to pedestal income at 8 slots, about +6% of total income. Model: an Exclusive row.
- **Claim x3:** about 7 min of total income, under one stand.
- **Starter pack:** right after the tutorial, about 10-15 min of early progress plus a Rare+ Forest Rok. Champ fades from the Jungle on.
- **Mega pack:** 350 geodes of your zone is about 12-25 min of income, below most next stands.
- **Model v10:** multiplier inputs (off by default), "with passes", "boosted x4" and "Lucky buyer" check rows, the Exclusive and Champ rows, and luck x3 for the hatch-and-sell worst case.

## 12. Build order (each step ends checkable)
1. **Config and data:** `MonetizationConfig`, `RobuxShopConfig`, the PlayerData fields. `check.ps1` passes; old profiles load.
2. **`PassService`:** fake passes, VIP includes, gift flag, the policy cache. 2x Luck moves to it.
3. **Multipliers and Big Backpack** with fake passes.
4. **`BoostService`:** personal boosts, taste, run-out; server boosts, chain, attributes. Test by calling the grants in Studio.
5. **Lucky Geodes:** config, zone choice, grant into inventory, cracking with the forced modifier, pity, policy hiding, odds view. Run 10,000 simulated cracks and compare with the shown odds.
6. **Starter Pack, Claim x3, Mega, exclusives:** grants and once-only guards; offline amount recording; `BestTimes` income; stock counter.
7. **Gifts:** `SetGiftTarget`, `PurchaseService/Gifts`, the profile message path, gift credits. Test in a two-player Studio server: online recipient, a recipient who leaves mid-gift, and a recipient who already owns the pass.
8. **`PurchaseController`:** move the cash prompt in, add the Robux buttons by cash prices (R11), remove Skip, wire the Geode Shop prompts.
9. **Shop UI in Studio:** show the user still frames and a motion capture, then wire `Screens/RobuxShop`.
10. **Popups, rail, pills, banner, gift picker:** show each one, then wire it.
11. **In-world signs, the Lucky pedestal and the exclusive stand.** The user places them.
12. **Make the products and passes** (script plus Dashboard), put the ids in config, and test real prompts and a real gift in a published test place.
13. **Models and icons:** Champ, the first exclusive Rok, the Lucky Geode (`model-workflow`, `item-icons`).
14. **Docs:**
    - Balance model v10.
    - Master Game Plan §10 filled in.
    - Vault notes `Systems/Robux Shop`, `Game Passes`, `Boosts`, `Gifting`, `Lucky Geodes`, plus updates to [[Cash Packs]], [[Geode Shop]] and [[Rebirth Gated By Strength]].
    - Remove the two To Do lines once built and checked.
15. `./scripts/check.ps1` passes. The user playtests.

## 13. Risks and gotchas
- **Too many offers:** popups are limited to:
  - the starter pack (its 24 h windows)
  - Welcome back (on join, when worth it)
  - the run-out card (once per boost per session)
  - the server chain card (only in a boost's last minute)
  - gift received

  Everything else waits in the rail, the shop and the world.
- **Paid random rules** must ship with the Lucky Geodes, not after: odds, PolicyService, the questionnaire. Skipping the regional check risks a per-country ban with no appeal (notes).
- **Two-profile gifts** are the most complex code here. Build and test them alone (step 7). Check that the vendored ProfileStore supports `MessageAsync`; if not, gifts go only to recipients in the server, and anything else becomes a gift credit.
- **Server boost loss on shutdown:** accepted. If Roblox restarts servers for an update, a boost bought in the last minutes ends early. Keep the cap at 2 h.
- **Exclusive stock across servers:** approximate by design; a few extra sales are possible.
- **Jungle hatch-and-sell with more luck:** must be checked first (section 11).
- **Auto Open plan overlap:** build `PassService` first. The auto-open session was told through the shared notes folder.
- **Real Robux in Studio:** use fake passes and call grants directly.
- **Studio UI isn't in git:** back up, and remind the user to save the place.

## Out of scope
Skipping rebirths or stands, personal luck potions, Robux training mats (R13), auto-chop, trading, a Robux-spent leaderboard, Rok upgrade skips, base floors and extra pedestal slots, and analytics funnels (separate To Do; this plan's shop, prompt, purchase, gift and server boost events are its hook points).
