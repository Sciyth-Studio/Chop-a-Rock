---
description: 2026-10-24 monetization inputs from the user - 20 screenshots of other games' Robux UI, the "09 Monetization" notes (Downloads), and the user's calls (timed boosts crucial, paid geodes OK, gifting and server boosts in); used by RobuxShopPlan.md.
type: reference
updated: 2026-10-24
---
# Monetization references

The user shared these on 2026-10-24 for the Robux shop and starter pack plan (`RobuxShopPlan.md`). Take **ideas and layout** from them. The look stays the house style ([[Menu Panel Style]], [[Tile Style Reference]]).

**User's views (2026-10-24):**
- **Timed boosts are crucial** to turn players into payers. The plan makes them a full product line: 2x Cash and 2x Strength, 15 min and 1 h, a free taste after the tutorial, and an offer when one runs out.
- **Paid geodes aren't a problem.** This reverses §00's "geodes are never sold for Robux"; logged in the Master Game Plan's Decision Log on 2026-10-24. The plan sells Lucky Geodes under the paid random item rules.
- **Gifting and server-wide boosts are "elite knowledge":** players keep a server boost chain going, and gifting encourages playing together. Both are approved even though they grant outside the buyer's profile.

## The notes
`C:\Users\Admin\Downloads\09 Monetization.md` (also a password-protected `.pdf`). Collected developer advice, with confidence levels. The points the plan uses:
- Daily revenue per player = share of players who buy × average spend per buyer. Fix the share who buy first, with a very cheap first purchase (a starter pack around 29 R$ gets about 3%). Then add 1,000+ R$ items for big spenders. A full shop should add up to at least about 3,000 R$.
- Price ladder: entry 1-49, core 99-300, big-ticket 499+. Boosts cost about 1-1.5 R$ per minute (about 20 per 15 min, 79 per hour). 2x and 5x offline earnings products (29-39 R$) are a simulator must-have.
- Make more developer products than game passes (about 5-8 passes). A starter pack works better as a developer product, so it stays off the game page's Store tab. Bundle passes 20-30% cheaper.
- Show products where players already look and when they need them: physical spots in the world, "+" buttons on capacity bars, and the covering cash pack on "not enough cash". Big buttons and looping motion help. Don't clutter the HUD, and don't interrupt with random popups.
- Show live prices with `GetProductInfo`. Strike through only a price that really existed. A "2x" must really be 2x (false advertising).
- Paid random items (crates, eggs, rolls) need odds shown and can never give nothing. They're banned for under-18s in the UK and Australia, and in Belgium and the Netherlands: hide them with a PolicyService check and answer "yes" in the maturity questionnaire. Chop a Rock's Lucky Geodes must follow this.
- Regional pricing: on for normal items, off under about 10 R$.
- Buying your own pass in Studio may charge real Robux (reported bug): test with fake ownership.

## Screenshots
1. A game page Store tile: "2X Money" pass with a money-chest icon, 199 R$.
![[Monetization Ref 01.png]]
2. "Welcome Back!" offline earnings popup: big money chest, "$1.4M", a purple "Claim x3" button for 29 R$ beside a green "Claim!". This is the plan's Claim x3.
![[Monetization Ref 02.webp]]
3. Shop grid of six currency packs (59 to 2,249 R$). The icon grows with the pack: one bolt, two, three, a pile, a sack, a chest. Each card has a green price bar and a small purple gift button.
![[Monetization Ref 03.webp]]
4. "Featured" limited-time chest with odds per pet and 1 / 3 / 10 / 50 chest prices (a struck-through 4,950). A paid random item: the model for the Lucky Geode card (odds per Rok, Buy 1 / 3 / 10, gift buttons).
![[Monetization Ref 04.png]]
5. "Exclusive" pet card with Income and Speed stat tiles and a "Sold Out" state: a limited-stock Robux pet. Later idea (plan R7).
![[Monetization Ref 05.png]]
6. "Double your Stamina": "x1 ▶ x2" in huge numbers and a 3 R$ button. The plan's boost cards copy this layout.
![[Monetization Ref 06.png]]
7. "Upgrade Dinomachine": current → next, "+68 Stamina / rep", with a Robux button (69) beside a cash button ($5M). In this game the Robux button is the covering cash pack (plan R9), never a direct skip.
![[Monetization Ref 07.png]]
8. Shop "Money" section: a wide "Double your Money, x2 Forever!" pass card (199) above cash pack cards (45 / 90 / 225) with gift buttons. The plan's pass cards copy it.
![[Monetization Ref 08.png]]
9. "Fuse Machine": a free fuse at 70%, or "100% Chance" for 39 R$. Only relevant if Rok upgrades are built (deferred).
![[Monetization Ref 09.png]]
10. "Starter Pack" popup: three item tiles (currency, wins, a 5-min 2x potion) and a big green 39 R$ button with 99 struck through. The plan copies the layout but shows a real "Worth" value instead of a strike-through.
![[Monetization Ref 10.webp]]
11. "Evolve": current → next with multipliers, requirement bars, and a rainbow "Skip Evolve, 49 R$" button. Chop a Rock never sells skipping a rebirth gate ([[Rebirth Gated By Strength]]).
![[Monetization Ref 11.webp]]

Second batch (2026-10-24):

12. "Welcome Back! You trained while you were offline": +3.14B skill on rays, a rainbow "+9.41B" button for 11 R$ and a green "Claim!". The same Claim x3 idea for offline training.
![[Monetization Ref 12.png]]
13. An in-world whale pet: King Bones on a glowing pedestal with an aura ring, a billboard "Best in game, always 1200% better", and a ProximityPrompt "Buy 1,559". The model for the exclusive Rok stand (the plan uses 3x, not 12x).
![[Monetization Ref 13.png]]
14. In-world Robux training areas: "All worlds" 119 / 299 / 719 R$ for 75x / 300x / 1000x skill, shown locked. The plan recommends against it (R13): it would make training gates take seconds.
![[Monetization Ref 14.png]]
15. A limited in-world relic: "Stock: 5835/10000", "Always 200% better", "Only 839", Buy prompt. The model for the exclusive stand's stock counter.
![[Monetization Ref 15.png]]
16. "Random Brainrot!" silhouette with an Odds tag and a 9 R$ price (29 struck through). The model for the 9 R$ first Lucky Geode.
![[Monetization Ref 16.png]]
17. "Starter Bundle" HUD offer: two pets and a speed icon, "Only 99", and a 23:59:26 countdown.
![[Monetization Ref 17.png]]
18. A full Store panel (yellow studded header, basket icon): "Infinity Lucky Block" paid crate with per-pet income, odds, "Infinity Mutation Guaranteed" and Buy 1 / 3 / 8 (299 / 799 / 1,999); a "Server Luck x2 + 15M" card at 169 with Details; a Starter Pack with a timer; a big Gift button bottom-right.
![[Monetization Ref 18.webp]]
19. The same store: Starter Pack (two pets + "+3 Speed", 279 struck through, 99, timer) and a V.I.P card (2x Luck, 1.5x Cash, VIP tag; 729; "Best Seller!").
![[Monetization Ref 19.webp]]
20. The same store's pass grid: coloured cards "X2 Kick Power" 349, "X2 Cash" 399, "x2 Brainrot Luck" 249, "x2 Mutation Luck" 265, each with an icon, a one-line blurb and a purple Details button.
![[Monetization Ref 20.webp]]

Related: [[Cash Packs]], [[Balance Model]], [[UI Feel]].
