---
description: The user runs the decor reference-sheet prompts in ChatGPT with no images attached, so the prompts describe colour, finish and lighting in words.
type: preference
---
# Decor prompts without attached images

The user (2026-10-17) generates the zone decor reference sheets in ChatGPT without attaching any inspiration images or game screenshots. A prompt that says "using the attached reference images" doesn't fit how they work.

How to apply:
- Decor prompts (`assets/Decor/Prompts.md`) carry a STYLE block instead: smooth matte plastic toy render, highly saturated named colours, soft even lighting.
- Don't tell the user to attach colour or finish references for decor.
- The sheets that come back are still the references Claude models from; `batch-model` runs as usual from step 2.

Related: [[Keep Decor Simple]], [[High Saturation Colors]]
