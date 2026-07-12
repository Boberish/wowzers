# Codex working guide — Project Rift / Wowzers

This is the Codex-facing companion to `CLAUDE.md`, not a replacement for it. Claude and Codex
share this repository. Preserve Claude-owned files, claims, worktrees, settings, and in-progress
artifacts. Never rewrite `CLAUDE.md`, `.claude/`, or another agent's planning/implementation work
unless Bill explicitly asks for that exact change.

The checkout is `/home/bill/projects/Wowzers` in WSL Ubuntu. The directory name has a capital
`W`. The Godot project root is `godot/` (`res://`).

## Start every task here

1. Read the live `MASTER-PLAN.md` first. Its Coordination Log is the current shared state; old
   sections deliberately preserve superseded history.
2. Run `git status --short --branch`, `git worktree list`, and inspect recent commits before
   deciding what is free to touch. Claude may be working concurrently.
3. Read the relevant source-of-truth docs:
   - `GAME-LOOPS.md` — quickest read of what the player does, from beat to warband.
   - `BUILD-LEDGER.md` — forward-looking unbuilt work, dependencies, and collision hotspots.
   - `CARD-CATALOG.md` — canonical card slate and lifecycle/status.
   - `DECK-LAYOUT.md` — canonical deck anatomy and run grant order.
   - `GRAPHICS-PLAN.md` — visual-system owner: AI art, modular scenes, dashboard, actors, VFX,
     approval gates, and Claude/Codex packet boundaries. `ART-PLAN.md` v1 is superseded.
   - The named subsystem/class plan — the actual design of record.
   - `CLAUDE.md` — stable architecture, verification rules, run book, and hard-won gotchas.
4. Check the Coordination Log for an active owner. Do not touch a claimed surface or another
   worktree's files. If work is available, claim it using the repository's existing convention.
5. Code changes belong in a dedicated worktree/branch, never directly on `main`. Docs-only work
   may go directly to `main` under the project's current convention. Commit only files created or
   changed for the task; never sweep up unrelated modifications or untracked files.
6. Before stopping, verify proportionally, commit the task's own output, then update the tracking
   docs required by the laws below. Do not push unless Bill explicitly asks.

`MASTER-PLAN.md` is large and chronological. Trust the newest dated amendment, current
Coordination Log entries, and the owning plan over an older summary. Do not "clean up" apparent
contradictions until checking whether they are intentional history.

## Project in one paragraph

Project Rift is one Godot 4.7 game: a four-seat co-op warband plays MMO-trinity combat with
movement removed and replaced by timed active answers. Bill controls one seat; deterministic AI
policies fill all empty seats, so solo and co-op run the same fights. The inner loop is graded
telegraph timing; fights sit inside roguelike dungeon/raid runs with drafts, and those doors sit
inside a persistent overworld whose zones are conquered once. The world grows the collection;
instances build the temporary deck. The long-term aim is authored Versions plus unbounded Depth,
with player skill—not an item-level treadmill—as the durable progression.

## Current live shape — re-check the plans before relying on this snapshot

Snapshot: 2026-07-12, `main` around `0d33f42`.

- Entry scene: `res://game/world_shell.tscn`; the world shell is the game's front door.
- Exactly one player-facing combat HUD: `godot/game/raid_hud.gd`. The word `raid` in its name is
  legacy; do not create or revive parallel solo HUDs.
- Exactly four seats per fight. Human, AI, and sim agents use the same `perform(action)` surface.
- Active roster in code: Duelist (tank), Twinfang (blade), Alchemist (caster), Well (healer), and
  Bloomweaver (healer toggle/frozen rework target). Voidcaller, Mender, Reckoner, Bulwark, solo
  bosses, and GATE nodes were purged; git history is their attic. Some fossil art or old prose can
  remain, so filenames alone are not proof that a feature is live.
- Tank v3's one-bar/channel and Songbook line is merged. Known follow-ups include Duelist deck
  re-landing, per-Seal stream/buster/LATE authoring, and clearing any explicitly recorded legacy
  smoke expectation—not weakening tests merely to turn them green.
- Realm 1's AI parody is local to that raid. The newer world fiction in `THEME-PLAN.md` owns the
  global setting and naming law; old "rift tears" or global Haiku/Sonnet/Opus prose can be stale.
- `DEV · BOSS TEST` is available in debug builds from the home screen for a fast single-Seal jump.
- Full verification is intentionally paused by `~/.rift-verify-paused`; targeted sims/probes still
  run. Respect the pause. Do not force the ~40-process suite unless Bill asks or the current task's
  explicit acceptance bar requires it.

## Non-negotiable game laws

1. One game, one HUD. Never reintroduce solo-vs-raid product surfaces or port features between
   duplicate HUDs.
2. Single-target combat: one boss and one authored telegraph stream. Multi-target flavour uses
   tightly specified adds/split structures, not targeting UI.
3. Four-seat warband always. No enemy scaling by human player count; AI backfills.
4. Universal dodge is rationed into authored moments. New/reworked kits use one SPACE dodge.
5. Interrupts ride flagged existing abilities in a tight end-of-cast window. No generic kick
   button and no dedicated kicker class; healers do not carry the interrupt tax.
6. Overworld fights use the bare kit plus persistent unlocks. Boons, curios, run currency, and
   charge are instance-only.
7. Uniform interfaces, asymmetric classes. Share the chassis, not cookie-cutter rotations.
8. Every kit must be fun bare, AI-pilotable at three skill tiers, and show a meaningful skill
   gradient. Roles stay hard; off-role utility may save a fight, never run one.

## Architecture that must not bend

`CombatCore` is a pure, deterministic, Node-free reducer used by the live client, authoritative
server, and headless sims.

- Fixed 30 Hz simulation; integer `tick` is truth. Derive time from ticks.
- Inputs are tick-stamped and drained at the owning tick.
- Sim randomness comes from seeded `DetRng` state and advances in a stable order. Cosmetic RNG is
  client-only; policy RNG uses separate seeded streams and never consumes `state.rng`.
- No rendering, nodes, wall clock, unseeded randomness, or mutable module-level globals in the
  reducer.
- Balance numbers live in `TuningConfig` or per-class config, never as reducer literals.
- Class-specific engine hooks are guarded no-ops for all other classes; dormant behaviour must be
  byte-identical.
- Netcode is server-paced deterministic lockstep. Combat state enters through pure `(seed, spec)`
  data, and checksums travel as strings. Any protocol change couples server and client rebuilds.
- The boss scheduler resolves one telegraph per tick; ability timers freeze during a telegraph
  while melee can continue. A multi-beat string is one scheduler telegraph.

## Code map

- `godot/core/` — reducer state and laws: `combat_core.gd`, `combat_state.gd`, `boss_state.gd`,
  `seat.gd`, `class_kit.gd`, `policy.gd`, `rng.gd`, raid marks, and telegraphs.
- `godot/data/` — authored encounter and class content/config. Live class folders are
  `duelist/`, `twinfang/`, `alchemist/`, `well/`, and `bloomweaver/`; `raid/` owns Seals and
  party construction; `world/` owns world content/Forge.
- `godot/game/world_shell.gd` — app shell and front door.
- `godot/game/raid_hud.gd` — the single gameplay HUD and a major collision hotspot.
- `godot/game/campaign_core.gd`, `run_map.gd`, `map_content.gd`, `run_director.gd`, and
  `run_state.gd` — topology, run flow, rewards, and carried run state.
- `godot/game/ui/` — reusable presentation; custom `_draw` work requires visual verification.
- `godot/game/stage2d/` — actors, rigs, and the combat stage.
- `godot/net/` — lockstep networking and the versioned protocol.
- `godot/sim/` — balance sims, policies, probes, smokes, and screenshot tours.
- `scripts/` — verification and sharded sim wrappers.
- `server/` — WebSocket server/deploy kit; run `server/preflight.sh` before deployment.

Before shared-engine, HUD, map, draft, networking, or save work, read `BUILD-LEDGER.md` §0's
collision map. These surfaces serialize several planned changes and are where concurrent work is
most dangerous.

## Run and inspect

From WSL Ubuntu:

```bash
cd /home/bill/projects/Wowzers

# Fresh checkout/worktree only: build Godot's global class cache.
~/.local/bin/godot --headless --path godot --import

# Editor or game under WSLg.
~/.local/bin/godot --path godot --editor --rendering-driver opengl3
~/.local/bin/godot --path godot --rendering-driver opengl3

# Useful debug starts.
~/.local/bin/godot --path godot -- --autostart=world
~/.local/bin/godot --path godot -- --autostart=raid:tank
~/.local/bin/godot --path godot -- --autostart=raid:blade:tempo:mythos
~/.local/bin/godot --path godot -- --autostart=raidmap:blade:tempo
```

The exact accepted autostart grammar can evolve; search `world_shell.gd` and current Coordination
Log entries before inventing a new form. Windows launch helpers live at the repository root.

## Verification discipline

Choose checks by the surface touched and record the exact commands/results. Do not claim a gate
that was skipped, paused, or only inferred.

```bash
# Full suite (currently no-ops while ~/.rift-verify-paused exists).
scripts/verify-all.sh

# Explicit byte-identical working-tree vs pinned-baseline gate.
scripts/ab-gate.sh <sim> [args]

# Sharded balance sim; arguments after -- go to the sim.
scripts/psim.sh <sim> [seeds] [jobs] [-- --boss=mythos]
```

Live balance surfaces listed by the project are `twinfang_sim`, `raid_sim`, `alchemist_sim`,
`well_sim`, and `forge_sim`, plus the subsystem probes and UI/net smokes named in `CLAUDE.md`.
The Duelist/tank line also has `duelist_sim` and `stream_probe`; consult current scripts rather
than treating an old list as exhaustive.

- Engine change: determinism plus a pinned A/B baseline unless the task is an explicitly approved
  deliberate rebaseline. Guarded-off paths must remain byte-identical.
- Map/draft/save change: targeted map/draft/progression probes and serialization round trips.
- UI logic: relevant headless smoke.
- `_draw`, shader, stage, animation, or layout: run a non-headless WSLg screenshot/tour and inspect
  the image. Headless success does not verify drawing.
- Network change: protocol review, `net_smoke`/`net_map_smoke`, and server preflight where relevant.
- During concurrent work, use pinned baselines/frozen snapshots. A moving `main` can create false
  diffs.

## Tracking laws

- Any card proposal/decision/build/cut updates `CARD-CATALOG.md` in the same commit. The catalog
  owns card status and wins card-level disagreements.
- Any planning change that creates, changes, removes, or re-homes planned-but-unbuilt cross-file
  work updates `BUILD-LEDGER.md` (slate row and §0 collision map when file ownership moves) in the
  same commit.
- A loop-shape change updates `GAME-LOOPS.md` as a thin pointer/index, not as a second spec.
- Decision history and claims belong in the `MASTER-PLAN.md` Coordination Log.
- Design detail remains in the owning plan. Index docs point; they do not duplicate specs.

## Coexist safely with Claude and other agents

- Never stage with `git add -A` or `git add .` in the shared main checkout. Stage explicit paths.
- Never delete, rename, format, revert, stash, or commit another agent's files.
- Treat every unexpected diff or untracked file as owned by someone else until proven otherwise.
- Re-check status immediately before editing, before committing, and after committing.
- Keep a code task isolated in its worktree; merge `main` into it before final verification and
  merge-back, resolving only the conflicts owned by the task.
- Do not remove old worktrees merely because they look stale; the Coordination Log may rely on
  them. Do not prune baseline worktrees during active A/B work.
- Do not push, deploy, alter live services, or update Windows installs unless Bill asks or the
  accepted task explicitly includes that action.
- If current code and prose disagree, investigate git history and the latest dated amendment.
  Report uncertainty instead of silently choosing the more convenient interpretation.

## Hard-won implementation gotchas

- `Dictionary.get(...)` assigned with `:=` can trigger Variant-inference parse errors in
  GDScript. A broken `class_name` file causes misleading cascading compile failures.
- `const` cannot hold `Palette` statics; use `static var`.
- For UI construction, set anchors before `add_child`; use `CenterContainer` for centered stacks.
- A Node subclass must not define `_input(id, msg)` because that collides with Godot's virtual.
- Network clients set phase before sending join.
- Probe scripts start the run on frame 1 of `_process`, not `_initialize`; HUD `_ready` has not
  run during initialization.
- `RunState` couples class content into the sim compile graph. Do not edit kits while sims are
  running.
- WSL networking is NAT-mode here: Windows reaches WSL services via the WSL `eth0` address, not
  `localhost`.
- Persistent world map = ATLAS. Per-run instance map = TOPOLOGY. Keep the terms distinct.
- Cross-seat owners are indices (`caster_i`, `absorb_owner_i`), not object references, to avoid
  RefCounted cycles.

The concise mental model: preserve determinism at L0, preserve the one-HUD/four-seat laws at L1,
preserve run/world economy separation at L3–L4, and preserve ownership/claims at the repository
level. When in doubt, read the live plan before touching code.
