---
name: new-zone
description: Use when adding a new zone to Chop a Rock (jungle, ocean, snow or any later zone), or any part of one - planning its rocks, Roks and decoration, laying the floor and terrace walls, the entrance sign, the rock spawn area, rock templates and config, the geode and Index pages. Says which step a zone is on and what each step touches. Use it even when the user only says "start the jungle" or "make the ocean base".
---

# Making a new zone

A zone is one 220 x 168 stud strip in the straight line of zones, with its own rock material, three chop rocks, a geode of six Roks, and decoration. Work through the steps in order. Say which step you are on, and what is still missing, before starting work.

Read first: vault [[Zone Line]] (where each zone sits and its colours), [[Rock Spawning]], [[Forest Zone Entrance]], [[Roks Stay Rocks]], [[Simple Names No Material Clash]], and the master plan §03 (rocks, zone list, Rok lineup) and §06 (gates, teleport pads, walk speed).

## 1. Plan (propose and wait)

Player-facing, so propose and wait for the user's answer. Never build from an unapproved proposal.

- **Rocks:** three rocks of the zone's material that get bigger: First (small, plain), Second (boulder), Third (biggest, with a zone feature). The feature is painted into the vertex colours like the forest moss. It can't be a second mesh or a Neon part, because those don't follow the split halves. Names are simple, name the material, and never use "Diamond".
- **Strength:** the desert set ×5 per rock (500 / 2,500 / 12,500). Continuing that is only a draft; check it against arm prices and mark it [PLAYTEST].
- **Roks:** already in the master plan §03 for desert, jungle, ocean and snow. Later zones need six new ones (Common to Legendary plus Secret) following [[Roks Stay Rocks]].
- **Decoration:** ground and walls, two or three landmarks, scatter props, sky and particles, sign colour. Each zone's environment matches its material.

When the user approves, log it in the master plan (section plus a dated Decision Log entry).

## 2. Base: floor and terrace walls

Built by Claude when the user asks. Everything else in the world is built by the user.

- Clone the previous zone's `ZoneTemplate` (Floor plus `Walls`), drop `ZoneEntrance`, and move the clone +168 on Z per zone. Parent it to `Workspace.Zones.Zone<Name>` (folder) as `ZoneTemplate`.
- The floor is 168 x 1 x 220 rotated -90°, so the zone runs along X (x -68 to 152), and it is 168 deep on Z. The walls are two terraces at x -98 and x 182, each three stacked layers: `ThirdLayerWall` (bottom, 16 tall), `SecondLayerWall` (15) and `FirstLayerWall` (the 4-stud cap). All of them are Glacier with the `2022 Stud` MaterialVariant and six faint black stud `Texture`s, which come along with the clone.
- Colours: the cap is the same colour as the floor. The two lower layers are the zone's cliff colour, middle lighter than bottom. Keep the zone's palette in [[Zone Line]].
- Wrap the edit in `ChangeHistoryService:TryBeginRecording` / `FinishRecording` so the user can undo it. Check the result with `screen_capture` from above, then tell the user to save the place.

```lua
local template = previousZone.ZoneTemplate:Clone()
template.ZoneEntrance:Destroy()
template:PivotTo(previousZone.ZoneTemplate:GetPivot() + Vector3.new(0, 0, 168))
template.Floor.Color = top
for _, wall in template.Walls:GetChildren() do
	wall.FirstLayerWall.Color = top
	wall.SecondLayerWall.Color = middle
	wall.ThirdLayerWall.Color = bottom
end
```

## 3. Entrance sign

Copy the desert's `ZoneEntrance` into the new `ZoneTemplate`. Put it at the zone's near edge (centre z − 84) and set the `Title` text and style and the `Strength` range ("<First> N to <Third> N Strength"). The range is typed by hand, so update it whenever `RockConfig` changes. Bake the style in Edit with `Typography.ApplyTextStyle`. See [[Forest Zone Entrance]].

## 4. Rocks

- **Models:** follow `model-workflow`, then `rock-model` (Blender build, split, FBX export, Studio wiring). Until the real ones exist, a placeholder is the boulder mesh scaled and tinted, split with `Model_RockSplit_Boulder`, as the desert did.
- **Templates:** `ReplicatedStorage.Assets.Models.Rocks.<Zone>.Model_Rock_<Zone>First/Second/Third`, plus `Model_RockPreview_<Zone>*` for the Index and the zone's `Model_RockSplit_*`, all in that zone folder. Each template keeps its `RockKey`, `SplitModel`, MaterialVariant and rotation, and has no `ChopRock` tag.
- **Code:** `RockConfig` entries (`<Zone>First` etc.: `DisplayName`, `StrengthRequired`, `TemplateKey`), `AssetRegistry` keys for the templates and previews, `IndexConfig` Rocks page zone plus preview keys, and `RockSpawnConfig.Zones.<Zone>` (`RockCount` 10, weights 50 / 30 / 20) plus `SpotColors`. Run `./scripts/check.ps1`.

## 5. Rock spawn area

Add a Part tagged `RockSpawnArea` with the `Zone` attribute set to the `RockSpawnConfig` key, half-transparent blue, in the zone folder. Cover the open floor between the terraces and leave out anything rocks shouldn't sit in (rivers, paths, landmarks). Playtest and turn on admin "Spawn Spots" (Ctrl+Shift+K) to check spots and the rock mix (`studio-playtest`).

## 6. Geode and Roks

- **Rok models:** `model-workflow`, reusing Bloky's eyes ([[Reuse Rok Eyes]]). Add a vault reference note per Rok.
- **Config:** `PetConfig` entries, `GeodeConfig.Geodes.<Zone>` (price, strength, six weighted pets), and an `IndexConfig` Roks page zone with its `GeodeKey`.
- **Shop:** no stand per zone. The geode gets a tab in the lobby Geode Shop from its `TabName` and `Order` (vault [[Geode Shop]]); tint copies of the Basic geode models for it.

## 7. Decoration (user)

The user builds this in Studio. Claude helps with lists, reference prompts and models. Rules to pass on:

- Keep the spawn floor flat and open. Decoration goes on the terraces, at the edges, and in gaps left out of the spawn area. Only collidable parts block spawn spots.
- Props get studs ([[Studs On Models By Default]]). The mood is bright and saturated; see [[Why The Game Looks Blue]] before changing lighting.
- Reference models kept in Workspace only for authoring get the `EditorOnly` tag.

## 8. Not built yet

Zone gates (strength plus a one-time price), teleport pads and the per-zone walk speed step are decided in §06 but have no system yet. Don't fake them per zone; flag them when the zone is otherwise done.

## 9. Record

Update [[Zone Line]], [[Rock Spawning]] (spawn area box) and the vault Index. Studio edits aren't in git, so remind the user to save the place.
