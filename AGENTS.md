# AGENTS.md — Elvaren: Crystals of the Fallen Realms

## Project Overview

A top-down 16-bit action/puzzle/RPG with exploration, combat, and item-gated progression. Set in the land of **Elvaren**, an evil **ghoul from the north** has corrupted eight kingdoms and imprisoned **eight maidens**. Each maiden carries the **crystal of the next realm**. The hero wields a sword as his main weapon and finds a **new secondary weapon** in each dungeon to defeat that realm's boss and free the maiden. The final captive is the **princess**, who the hero grew up with and never knew was royalty; the ghoul holds her in his northern citadel.

## Purpose of this File

This is the living design document **and** agent instruction set. It is the source of truth for code conventions, design decisions, and AI behavior while working on this repo.

## Story & World

- **Hero:** A young traveler with a sword, raised in the southern borderlands.
- **Eight Kingdoms & Maidens:** Each corrupted kingdom has a dungeon; inside is a cursed boss and a caged maiden. Rescuing her rewards the **crystal of the next kingdom**.
- **Secondary Weapons:** Each dungeon hides a new secondary weapon — confirmed examples include **Bow, Boomerang, Bombs, Portal Gun, Fire Rod**, etc. — used for puzzles and combat.
- **Main Ghoul & Princess:** The northern ghoul captured the princess; she is the final maiden, and her rescue is the climax.

## Design Pillars

- **Item-gated progression:** Linear dungeons; each dungeon gives a new **secondary weapon** and a **crystal** (from the rescued maiden) that open the next overworld area and solve new puzzles.
- **Top-down with slight angle:** 2D movement, `YSort`/depth, 8-directional art and animation.
- **16-bit pixel art:** Low base resolution, SNES-like color palette, tile-based world.
- **Feel first:** Combat and movement must be snappy and responsive; puzzles are concise and room-based.
- **Placeholder-friendly:** User art will replace generated placeholder assets; structure and naming must remain stable.

## Agent Rules

1. **Always update the todo list** at the start and end of a work block.
2. **Do not install Godot, tools, or system dependencies** without explicit user approval.
3. **Prefer minimal, focused changes** over large refactors.
4. **Read existing code** before editing; do not guess at existing APIs.
5. **Keep GDScript idiomatic:** strong typing, typed signals, `class_name` for shared types, node groups for cross-object messaging.
6. **Use the project structure** defined below; do not create ad-hoc folders.
7. **Document design changes** in this file and, if user-facing, in `docs/GDD.md`.
8. **No hard-coded magic numbers.** Export constants and use `@export` for tunable values.
9. **Use `user://` for save files;** never write to `res://` at runtime.
10. **Keep the player in control.** Avoid input lag and long unskippable sequences in the vertical slice.
11. **Scenes and scripts together:** Pair a `.tscn` with its primary `.gd` script in the same folder path under `scenes/` and `scripts/`.
12. **Prefer composition:** Use child nodes and small component scripts rather than deep inheritance trees.
13. **When the user authorizes an implementation phase,** execute the approved plan and keep the user informed; for actions outside the plan (e.g., installing new tools), seek approval first.

## Tech Stack

- **Engine:** Godot 4.x (targeting 4.3)
- **Language:** GDScript
- **Platforms:** macOS, Linux, Web
- **Base resolution:** 384 × 288 (4:3)
- **Window size:** 1152 × 864 or 1536 × 1152 (3× or 4× integer scale)
- **Stretch mode:** `canvas_items`, `keep` aspect, nearest-neighbor filtering
- **Renderer:** `gl_compatibility` for broad web/low-end support
- **Tile world:** 16×16 logical base tiles, deterministic screen generation, collision bodies, and `YSort` for actors

## Project Structure

```
res://
  autoload/              # Singletons
  scenes/                # .tscn files
    player/
    enemies/
    world/
    dungeons/
    ui/
    props/
  scripts/               # .gd files
    state_machines/
    components/
    data_classes/
  assets/
    art/                 # Runtime tilesets, sprites, animations (PNG/WEBP/SVG)
    audio/               # Music, SFX
    fonts/               # Pixel fonts
    src/                 # Source art files (XCF, PSD, Aseprite) — export to art/
  data/                  # JSON data: items, enemies, dialog
  docs/                  # Design docs
  icon.svg
  project.godot
```

## Coding Standards

- **Files / variables / signals / functions:** `snake_case`
- **Classes / node type names:** `PascalCase`
- **Private methods and vars:** prefix with `_`
- **Class names:** Use `class_name` for data classes and shared components (e.g., `class_name ItemData`)
- **Typing:** Use `: Type` and `-> ReturnType` everywhere reasonable.
- **Signals:** `signal damage_taken(amount: int)` — typed where possible.
- **Avoid deep inheritance:** Prefer `Node` groups and component nodes.
- **Resources:** Item, enemy, and dialog data are `Resource` classes or JSON; do not hard-code in scripts.

## Design Conventions

- **Health:** 1 heart = 4 mini-units. Player starts with 3 hearts (12 units).
- **Enemy loot:** Every defeated combat enemy has an independent 25% chance to drop a health pickup. The default pickup restores 1 heart (4 mini-units) and disappears after 10 seconds. Use the shared `HealthDropper` component and exported values for per-enemy overrides.
- **Combat:** Sword is the main weapon. Sword slash has a short arc, slight hitstop, knockback. Enemies flash and bounce back. Secondary weapons (items) are equipped and used with a dedicated button.
- **Items:** Items are `Resource` files. Equippable items go in a hotbar; key items are tracked in `GameState` flags.
- **Save/Load:** JSON in `user://` via `SaveManager`. Stores inventory, flags, health, position, current scene.
- **Dialog:** Sequential dialog boxes driven by `DialogManager` and JSON data.
- **Progress flags:** `GameState` holds boolean flags like `crystal_thornveil_collected`, `dungeon_2_unlocked`, etc.
- **Rooms:** Dungeons are built from reusable 16×16 tiles with 1-tile-thick walls and clear doorways.
- **Overworld:** The high-level map is an 8×8 grid of 64 screen-sized regions. Each region occupies one 384×288 gameplay screen, uses a 24×18 grid of 16×16 base tiles, and transitions at aligned edge passages.
- **Generation:** Overworld regions are deterministic from a fixed seed. Biomes, water, roads, obstacles, and enemy positions remain stable across visits and saved games; story landmarks are authored prefabs layered into generated regions.
- **Enemy variety:** Every overworld screen contains a deterministic mixture of at least three enemy archetypes rather than a single repeated type. Meadows use blobs, bats, and snakes; forests add skeletons; deserts emphasize sandworms, snakes, and skeletons; coasts mix blobs, bats, and skeletons; swamps mix blobs, snakes, bats, and skeletons; northern snow/highland regions emphasize skeletons and bats.
- **Enemy architecture:** Shared wandering, chase, contact-damage, knockback, death, and health-drop behavior belongs in `RoamingEnemy`. Individual enemy scenes configure sprite-sheet layout and combat tuning.
- **Enemy collision:** Every enemy archetype, including flying silhouettes such as bats, collides with the World and Enemy physics layers. Enemies cannot pass through trees, rocks, shrubs, water boundaries, walls, closed doors, or one another. Player and enemy movement bodies overlap instead of hard-blocking; contact damage and knockback handle combat so crowds cannot trap the player.
- **Enemy placement:** Generated enemy spawn points must be clear of all solid obstacle footprints and water, with separation between enemies. Never spawn an enemy inside decorative terrain.

## Asset Conventions

- **Sprite size:** Player 16 × 24; enemies 16 × 16 or 24 × 24; tiles 16 × 16.
- **Placeholder style:** Colored blocks with 1-pixel outlines, readable silhouettes, no gradients.
- **Palette:** 16-bit SNES-like; user art keeps the same structure and filenames.
- **Cover art:** `assets/art/cover.png` is the canonical cover image and appears on the main menu and near the top of `README.md`.
- **Source files:** Store working files (XCF, PSD, Aseprite, etc.) in `assets/src/` and export to `assets/art/` as PNG, WEBP, or SVG for Godot.
- **Runtime formats:** Godot cannot import XCF/PSD/Aseprite directly. Use PNG/WEBP for sprites, SVG for vector UI.
- **Audio:** Placeholder SFX can be short generated beeps/boops; music is optional in the vertical slice.

## Input Map

`InputEvents` autoload registers **keyboard** and **Xbox-style controller** actions at `_ready()` and provides typed helpers:

- **Move:** left stick, D-pad, or WASD
- **Attack:** keyboard `X` / controller `X`
- **Action / Interact:** keyboard `Z` / controller `A`
- **Item (secondary weapon):** keyboard `C` / controller `B`
- **Roll / Dash:** keyboard `V` / controller `RB`
- **Menu:** keyboard `Esc` / controller `Start`
- **Start:** controller `Start`

Actions: `move_left`, `move_right`, `move_up`, `move_down`, `action`, `attack`, `item`, `roll`, `menu`, `start`.

This keeps input centralized and version-friendly in one script.

## Current Milestone

**Vertical Slice — Thornveil:**

1. `project.godot` + folder structure
2. `InputEvents` autoload
3. Player controller with sword and roll
4. Deterministic 8×8 screen-based overworld and Thornveil dungeon
5. Bramble Lord boss
6. Forest Bow secondary weapon + switch puzzle
7. Save/load and main menu
8. Reusable enemy loot drops with a 25% health-drop chance
9. Biome-specific mixed enemy populations using blobs, bats, snakes, skeletons, and sandworms
10. Cover-art presentation on the main menu and README

## Overworld Expansion Roadmap

1. **Thornveil** — forest kingdom; current vertical-slice region and forest castle.
2. **Sunglass Dunes** — desert kingdom with sandstorms, ruins, and a desert castle.
3. **Aqualis Reach** — water kingdom with rivers, islands, flooded routes, and a water castle.
4. **Skyrend Heights** — sky kingdom with elevated paths, wind hazards, and a sky castle.
5. **Frostcrown** — ice kingdom with frozen terrain, sliding routes, and an ice castle.
6. **Stoneheart Peaks** — mountain kingdom with cliffs, caves, vertical routes, and a mountain castle.
7. **Cinderwake** — fire kingdom with volcanic terrain, lava hazards, and a fire castle.
8. **Umbral North** — shadow kingdom containing the northern citadel, the main ghoul, and the captive princess.

### Planned Region Requirements

- Each kingdom occupies a visually and mechanically distinct overworld region and contains one themed castle dungeon.
- Every region after Thornveil is protected by a crystal-gated barrier tied to progression from the previous kingdom.
- Approaching a locked barrier displays: `You shall not pass until you have the crystal of <region>.`
- Inhabited regions include houses, villages, residents, and useful services.
- Every castle has a themed exterior approach and a unique item- or environment-based entry puzzle.
- Castle entry puzzles must foreshadow the region's dungeon mechanics without duplicating the dungeon's primary puzzle.
- These roadmap items remain planned work and should not be implemented until the user authorizes the corresponding phase.
- Enemies will be themed by region (sand worm in desert, fire blob in fire kingdom, etc.) and will have color themes based on that as well (gray / white tinit in winter, etc.).

### Transition Safety Rule

- Area exits begin with monitoring disabled and activate only after player relocation has reached the physics server. This prevents stale edge overlaps from disabling the same directional exit in the next screen.
