---
description: 2026-10-31 the user renamed "Roks" to "Pets" everywhere (code, Studio, assets, vault, skills), with no save migration.
type: decision
---
# Roks renamed to Pets

On 2026-10-31 the user asked for "Rok" to become "Pet" everywhere, code included. Every `Rok` became `Pet`: modules (`PetSize`, `PetModifier`, `PetMotionConfig`, `PetsConfig`, the `Pets` screen), Studio instances (`Assets.Models.Pets`, `Model_Pet_<Name>`, `Assets.VFX.Pet.VFX_Pet_GoldAura`, `StarterGui.Pets`, `PetsToggle`, `PetName`), UI text, `assets/Pets/`, vault notes and skills.

- `PetsConfig` (the Pets screen) and `PetConfig` (pet stats) are separate modules.
- The admin command that grants a chosen pet is `GrantPet` (alias `pet`). The one that grants a random pet is `GrantRandomPet` (alias `randompet`, Ctrl+Shift+P).
- No save migration: pets queued under the old `PendingRoks` save field before the rename are dropped. The user OK'd this because the 11 players so far are all people they know.
- Blender files under `assets/Pets/` still have object names with "Rok" inside them. Uploaded Roblox assets keep their old names.

Related: [[Pets Stay Rocks]]
