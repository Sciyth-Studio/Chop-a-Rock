---
description: Every Rok uses Bloky's eye and pupil meshes copied as they are; never model eyes from scratch.
type: preference
---
# Reuse Rok eyes

The user doesn't want Rok eyes made from scratch (2026-10-04, while building Shroomy). Every Rok gets copies of `Bloky_Eyes` and `Bloky_Pupils` from the Blender `Rok` collection.

How to apply:
- Copy the mesh data, then only translate it to suit the new body: front face distance (Bloky's front is y -0.48) and a little height so they sit near the middle of the face. Don't resize or reshape them.
- Name the copies `<Rok>_Eyes` and `<Rok>_Pupils` so the colours stay on separate parts.
- If the eyes themselves ever change, change Bloky's and re-copy.

Related: [[Bloky Reference]], [[Roks Stay Rocks]], [[Shroomy Reference]]
