Set up an Obsidian vault in this repo as the project's knowledge base for agentic Roblox development. You (the agent) will read it at the start of every task and write to it whenever you learn something worth keeping. It replaces your built-in auto-memory for this project.

## 1. Create the vault

Make a `Vault/` folder at the repo root with this layout:

```
Vault/
  Index.md            entry point, read at the start of every task
  <Game Name>.md      what the game is, repos, place/universe ids, design source of truth
  Preferences/        how I want things done (style, workflow, art direction)
  Reference/          facts, gotchas, reference images, how something in Studio works
  Systems/            one note per game system as it gets worked on
  Decisions/          dated "chose X because Y" notes
  Inbox/              unsorted learnings for me to review
  Attachments/        every image, and only images
  .obsidian/app.json  {"attachmentFolderPath": "Attachments"}
```

Add `Vault/.obsidian/workspace.json` to `.gitignore`. Commit the rest of the vault.

## 2. Write Index.md

Frontmatter with a one-line `description`, then:

- **How you use this vault** (the rules in section 3, written as instructions to yourself).
- One heading per folder, with a bullet per note: `- [[Note Name]] — one-line hook that says when to open it`.

Keep Index.md short. It is a map, not the content. Leave empty sections with a one-line italic placeholder.

## 3. Rules for notes

- One idea per note, titled as a plain phrase (`Studio Live Editing vs Rojo`, `UI Text Style`).
- Frontmatter on every note:
  ```
  ---
  description: one line, specific enough to decide relevance without opening the note
  type: preference | reference | system | decision | project
  ---
  ```
- Preferences and decisions say **why** and **how to apply**. Quote my words when I state a preference.
- Use absolute dates (`2026-10-04`), never "today" or "last week".
- Link related notes with `[[Note Name]]` and end with a `Related:` line. A link to a note that doesn't exist yet is fine.
- Before writing, check for an existing note on the topic and update it instead of duplicating. Delete notes that turn out to be wrong.
- Every image lives in `Attachments/` and is embedded (`![[file.png]]`) in a note that says what to take from it ("Take from it: ..."). Only open images through their note.
- When you add a note, add it to Index.md and tell me in one line.
- Don't record what the code or git history already shows. Record what is non-obvious: things that live only in the place file, why something is the way it is, and what went wrong last time.
- Step-by-step procedures belong in skills (`.claude/skills/`), not the vault. The vault can point to them.

## 4. Wire it into the agent config

- In `CLAUDE.md` (and `AGENTS.md` if there is one), add: "Read `Vault/Index.md` before starting a task and open the notes relevant to it. When you learn something worth keeping, write it there as described in the index, not in auto-memory."
- Replace your auto-memory index for this project with one line pointing at `Vault/Index.md`.

## 5. Seed it

Don't invent content. Fill the vault from what is actually here:

1. Scan the repo: README, CLAUDE.md/AGENTS.md, design docs, the Rojo project file, `wally.toml`/`aftman.toml`, scripts, and any existing skills.
2. Write the `<Game Name>` project note: genre, core loop, repos, place and universe ids, group or user ownership, and where the design source of truth lives.
3. Write Reference notes for Roblox-specific facts that trip agents up, where they apply to this project:
   - What Rojo syncs vs what is authored and saved only in Studio (Workspace, Lighting, UI, meshes), so the agent checks Studio before calling something "missing".
   - Rojo port and how to confirm a sync landed, plus whether Team Create live scripting is on.
   - How assets are referenced (asset ids in config vs folders in Studio), and who owns them (user vs group).
   - Studio MCP / playtest limits you know about.
4. Then ask me a short round of questions, and write a Preferences note for each answer:
   - Code style rules (comments, strict mode, whole files vs diffs, scope).
   - UI and art direction (colours, fonts, text style, studs/materials, modelling tools).
   - Workflow (propose before changing player-facing things? commit rules? parallel sessions?).
   - Anything you've had to correct an AI on more than once.
5. Show me the finished Index.md and the list of notes created.

From then on, whenever I correct you, confirm a non-obvious approach, make a design decision, or share a reference image, capture it in the vault in the same turn.
