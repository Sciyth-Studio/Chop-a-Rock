# Robux shop icon prompts (ChatGPT)

The game's icons come from the **Free Icon Pack v3.1 (Basic)** by gvesster (`Downloads/Free Icon Pack v3.1 (Basic)`). `assets/Icons/Cannon/IconStyleSheet.png` is eight of them, so ChatGPT copies the pack's style. Every icon here must match it.

- **No baked outline.** The pack's "1st" icons have none. The shop draws its own black outline around every icon with eight `IconOutline` copies, so a baked outline would come out twice as thick.
- **Attach** `assets/Icons/Cannon/IconStyleSheet.png` to every prompt. Some prompts also say to attach a pack icon so the new one matches it.
- **One chat per icon**, so earlier icons don't bleed into the next.
- **Save** each result into `assets/Icons/Shop/` under the filename given. Claude trims, resizes and uploads them under the group.

Shared style block (already pasted into each prompt below):

```
Style to copy from the attached sheet:
- Chunky, toy-like 3D shapes in a three-quarter view from slightly above, drawn as flat vector art.
- Every surface is one flat colour. Side faces are a darker shade of the same colour. One or two crisp, hard-edged white highlight slivers sit on the top edges. No gradients, no texture, no noise.
- No outline, no drop shadow, no glow halo, no text, no background shapes.
- Bright, saturated colours, the same strength as the sheet.
- It must still read clearly when shrunk to 64 x 64 pixels: big simple shapes, few small details.
Output: one icon centred on a transparent background, square 1024 x 1024, filling about 85% of the frame. Only the object, nothing else.
```

## Do these now

### 1. LuckyGeode.png: Lucky Geode

```
Make one new game icon in exactly the same style as the icons in the attached sheet: a lucky geode cracked open.

The geode:
- A chunky round rock split open, seen in three-quarter view from slightly above, the top half tilted back so we look into it.
- The shell is warm grey-brown stone with a few flat facets, with a jagged crack line around the middle.
- The hollow inside is packed with crystals in rainbow colours: red, orange, yellow, green, blue and purple, each crystal one flat colour with a white highlight sliver, pointing inwards and up.
- Two or three small white four-point sparkles float just above the opening. Keep them simple and inside the frame.
- It must look clearly different from the single blue crystal cluster in the sheet: the round stone shell and the rainbow colours are the point.

Style to copy from the attached sheet:
- Chunky, toy-like 3D shapes in a three-quarter view from slightly above, drawn as flat vector art.
- Every surface is one flat colour. Side faces are a darker shade of the same colour. One or two crisp, hard-edged white highlight slivers sit on the top edges. No gradients, no texture, no noise.
- No outline, no drop shadow, no glow halo, no text, no background shapes.
- Bright, saturated colours, the same strength as the sheet.
- It must still read clearly when shrunk to 64 x 64 pixels: big simple shapes, few small details.
Output: one icon centred on a transparent background, square 1024 x 1024, filling about 85% of the frame. Only the object, nothing else.
```

### 2. Cash ladder (cash packs)

Five steps that grow with the pack. Step 2 is the green cash stack already in the sheet (the game's Money icon, `Currency/Cash/256px/Green Cash 1st 256px.png` in the pack), so it needs no prompt. Steps 1, 3, 4 and 5 must look like the same set as that stack: same green bills, same orange paper band.

Attach the sheet **and** `Downloads/Free Icon Pack v3.1 (Basic)/Currency/Cash/256px/Green Cash 1st 256px.png` to each.

#### Cash1.png: one bill

```
Make one new game icon in exactly the same style as the icons in the attached sheet: a single banknote.

It is one bill taken from the green cash stack in the attached images: the same green, the same paper pattern, no band. It is slightly curled, lying at an angle in three-quarter view, so it reads as a 3D object and not a flat rectangle. It is clearly the smallest amount of money in a set.

Style to copy from the attached sheet:
- Chunky, toy-like 3D shapes in a three-quarter view from slightly above, drawn as flat vector art.
- Every surface is one flat colour. Side faces are a darker shade of the same colour. One or two crisp, hard-edged white highlight slivers sit on the top edges. No gradients, no texture, no noise.
- No outline, no drop shadow, no glow halo, no text, no background shapes.
- Bright, saturated colours, the same strength as the sheet.
- It must still read clearly when shrunk to 64 x 64 pixels: big simple shapes, few small details.
Output: one icon centred on a transparent background, square 1024 x 1024, filling about 85% of the frame. Only the object, nothing else.
```

#### Cash3.png: a pile

```
Make one new game icon in exactly the same style as the icons in the attached sheet: a pile of cash.

Four or five of the banded green cash stacks from the attached images heaped into a small pyramid, a couple of them tilted, with two or three loose bills on the sides. Same green, same orange band. It should look clearly bigger and richer than one stack.

Style to copy from the attached sheet:
- Chunky, toy-like 3D shapes in a three-quarter view from slightly above, drawn as flat vector art.
- Every surface is one flat colour. Side faces are a darker shade of the same colour. One or two crisp, hard-edged white highlight slivers sit on the top edges. No gradients, no texture, no noise.
- No outline, no drop shadow, no glow halo, no text, no background shapes.
- Bright, saturated colours, the same strength as the sheet.
- It must still read clearly when shrunk to 64 x 64 pixels: big simple shapes, few small details.
Output: one icon centred on a transparent background, square 1024 x 1024, filling about 85% of the frame. Only the object, nothing else.
```

#### Cash4.png: a money bag

```
Make one new game icon in exactly the same style as the icons in the attached sheet: a big money sack.

A fat, round cloth sack in warm tan, tied at the top with an orange rope, a big green dollar sign on its front as a flat shape (no letters or other text). A couple of the banded green cash stacks from the attached images poke out of the opening and one leans against the bottom. Bigger and richer than a pile of cash.

Style to copy from the attached sheet:
- Chunky, toy-like 3D shapes in a three-quarter view from slightly above, drawn as flat vector art.
- Every surface is one flat colour. Side faces are a darker shade of the same colour. One or two crisp, hard-edged white highlight slivers sit on the top edges. No gradients, no texture, no noise.
- No outline, no drop shadow, no glow halo, no text, no background shapes.
- Bright, saturated colours, the same strength as the sheet.
- It must still read clearly when shrunk to 64 x 64 pixels: big simple shapes, few small details.
Output: one icon centred on a transparent background, square 1024 x 1024, filling about 85% of the frame. Only the object, nothing else.
```

#### Cash5.png: a treasure chest of cash (also "Welcome back / Claim x3")

Also attach `Downloads/Free Icon Pack v3.1 (Basic)/Item/Chest/256px/Chest 1st 256px.png`, so the chest matches the pack's own chest.

```
Make one new game icon in exactly the same style as the icons in the attached sheet: a treasure chest overflowing with cash.

Use the attached red-and-gold chest as the chest, with its lid flipped open. It is stuffed so full of the banded green cash stacks from the attached images that they spill over the front edge, with a few loose green bills and two or three gold coins. This is the biggest, richest step of a set of cash icons.

Style to copy from the attached sheet:
- Chunky, toy-like 3D shapes in a three-quarter view from slightly above, drawn as flat vector art.
- Every surface is one flat colour. Side faces are a darker shade of the same colour. One or two crisp, hard-edged white highlight slivers sit on the top edges. No gradients, no texture, no noise.
- No outline, no drop shadow, no glow halo, no text, no background shapes.
- Bright, saturated colours, the same strength as the sheet.
- It must still read clearly when shrunk to 64 x 64 pixels: big simple shapes, few small details.
Output: one icon centred on a transparent background, square 1024 x 1024, filling about 85% of the frame. Only the object, nothing else.
```

### 3. AutoOpen.png: Auto Open

The pack has an "Auto Open" icon (`Main/Rebirth and Auto Open/256px/Auto Open 1st 256px.png`), but it is the game's Rebirth arrows in green. Next to Rebirth it would read as "rebirth" again, so this one shows a geode.

```
Make one new game icon in exactly the same style as the icons in the attached sheet: an auto-opening geode.

A chunky round grey-brown stone geode, with a glowing crack across its front showing purple and blue crystals inside. Two thick curved arrows circle around it like a "repeat" symbol: one green, one white-blue, in the same chunky, faceted style as the red-and-white arrows in the sheet. The arrows wrap the geode without hiding the crack.

Style to copy from the attached sheet:
- Chunky, toy-like 3D shapes in a three-quarter view from slightly above, drawn as flat vector art.
- Every surface is one flat colour. Side faces are a darker shade of the same colour. One or two crisp, hard-edged white highlight slivers sit on the top edges. No gradients, no texture, no noise.
- No outline, no drop shadow, no glow halo, no text, no background shapes.
- Bright, saturated colours, the same strength as the sheet.
- It must still read clearly when shrunk to 64 x 64 pixels: big simple shapes, few small details.
Output: one icon centred on a transparent background, square 1024 x 1024, filling about 85% of the frame. Only the object, nothing else.
```

## Probably not needed

### Server badge

The pack's `Nature/Planet/256px/Green Planet 1st 256px.png` (a small Earth with clouds) already is a globe badge in the exact style. Claude can prepare and upload it like the others. Only run this if it reads badly as a small corner badge.

#### ServerBadge.png

```
Make one new game icon in exactly the same style as the icons in the attached sheet: a small "whole server" badge.

A chunky round globe: blue oceans, bright green continents as a few big simple shapes, and two small white puffy clouds. A thick gold ring goes around it like a badge rim. It will sit small in the corner of other icons, so keep it extremely simple and bold.

Style to copy from the attached sheet:
- Chunky, toy-like 3D shapes in a three-quarter view from slightly above, drawn as flat vector art.
- Every surface is one flat colour. Side faces are a darker shade of the same colour. One or two crisp, hard-edged white highlight slivers sit on the top edges. No gradients, no texture, no noise.
- No outline, no drop shadow, no glow halo, no text, no background shapes.
- Bright, saturated colours, the same strength as the sheet.
- It must still read clearly when shrunk to 64 x 64 pixels: big simple shapes, few small details.
Output: one icon centred on a transparent background, square 1024 x 1024, filling about 85% of the frame. Only the object, nothing else.
```

### Crown, gift, clock, backpack, skip

No prompt needed. They come from the same pack as the sheet, so they already match it exactly. They are in this folder as `Crown.png`, `Gift.png` (Red Gift), `Clock.png` (Golden Clock), `Backpack.png` (Golden Backpack) and `Skip.png`, the no-outline "1st" versions, converted to RGBA. 256 px is the pack's largest size. Upscaling would only blur them, and the shop shows icons at 150 px or less.

## Licence

The pack allows commercial use and editing within our own project. It does not allow reselling the icons or putting them in an asset pack (`Downloads/Free Icon Pack v3.1 (Basic)/License.txt`). Crediting @gvesster is optional.
