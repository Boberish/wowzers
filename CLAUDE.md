# Project Rift — the game (Godot 4)

**One game:** a co-op raid campaign built on **MMO trinity combat with movement removed**,
replaced by **timed active decisions** (parry / dodge / kick / triage windows). You play one
seat of a 4-seat **warband**; AI raiders (that you build, via Commander) fill every seat a
human doesn't — solo and 4-player co-op are the same fights. Roguelike instances (Hades-style
draft runs over seeded node maps) sit inside a **persistent overworld** (planned — see
`WORLD-PLAN.md`): zones you conquer once, dungeons/raids you re-run forever. Raids are themed
REALMS (Realm 1 "The Takeover" = the ironic AI takeover: Mistral → Gemini → Claude-Mythos).

## ⚠ COORDINATION — read `MASTER-PLAN.md` FIRST
`MASTER-PLAN.md` is the living state: status by section, claims, open ideas, realm bibles.
CLAUDE.md keeps only the stable laws + run-book. Workflow for EVERY task:
1. Read `MASTER-PLAN.md`; claim your work in its Coordination Log before starting.
2. **Code changes** → work in a **git worktree** (`git worktree add ../wow-<task> -b <task>`),
   never directly on `main`; commit early/often; merge `main` into your branch often.
   **Docs-only design work** → commit **straight to `main`** (the "main (docs only)" pattern),
   no worktree needed.
   ⚠ **COMMIT BEFORE YOU STOP — never leave uncommitted work in the shared tree.** That's how
   concurrent sessions clobber each other and lose files. Committing docs needs **no
   permission** (Bill, 2026-07-08): commit your own output as you finish it; don't ask, don't
   pile it up. (Pushing to a remote is still a separate, explicit action.)
3. Verify against your section's acceptance bar (see ACTIVE VERIFICATION below), merge back.
4. **Update `MASTER-PLAN.md` after the work** — status, what changed, what's next.

**Plan-doc index:** `MASTER-PLAN.md` (living state) · `WORLD-PLAN.md` (the world pivot +
COMBAT PILLARS — locked 2026-07-06) · `TEMPO-PLAN.md` (Class Framework v2, Twinfang pilot) ·
`ALCHEMIST-PLAN.md` (the Brew — poison class split OUT of Twinfang 2026-07-06; was `VENOM-PLAN.md`) ·
`MENDER-PLAN.md` (direct-cast healer rework — the Well + BRIM/DRAW twin specs, pair locked 2026-07-07) ·
`TANK-PLAN.md` (tank rework — the Duelist/Warden two-kit core + the Duelist deck, 2026-07-08) ·
`PROGRESSION-PLAN.md` + `GEAR-CATALOG.md` (persistent meta: laws, oaths,
curios) · `ASCENSION-STEAL-PLAN.md` (draft economy) · `SEAL-PILLAR-PLAN.md` (Seal pillar pass) ·
`FERMATA-V5-BRIEF.md` (Fermata v5 as-built brief) · `REFIT-PLAN.md` (structural audit v2 →
the Shell Refit: fix plan + target architecture, 2026-07-07) · `RAID-PLAN.md` (netcode-era reference) ·
`HISTORY.md` (frozen milestone build-up M0→R2.5 + PoC notes — the old CLAUDE.md status list) ·
`PORT-PLAN.md` / `rift-godot-port-brief.md` / `poc/` (origins, historical).

## THE ERA (as of 2026-07-06) — what's live vs frozen
- **ONE GAME · ONE HUD (locked 2026-07-03):** the raid campaign is the game; `raid_hud.gd` is
  THE HUD. The five solo class HUDs + `main_menu` + `*_main.tscn` solo scenes + `stage3d/`
  were **DELETED 2026-07-07 (REFIT P1, ~6.5k lines** — git history has them). Never "port
  solo→raid"; every player-facing system lands on the one HUD, once. Esc outside combat
  goes to the HUD's HOME screen (`_show_home`), never to a scene change.
- **ROSTER REWORK (Class Framework v2):** every class is being rebuilt one at a time onto
  Creeds/Modules/WHEN-THEN (see `TEMPO-PLAN.md`). **Twinfang·Tempo is the active pilot**; the
  rest (Bulwark, Mender, Bloomweaver, Reckoner) are FROZEN — playable in the raid on current
  kits, balance not maintained. **Voidcaller is CUT from the roster plan** (stays in code as
  the frozen caster-seat placeholder until that seat's rework); its interrupt moves to
  **interrupt-by-ability** (WORLD-PLAN pillar #3). **THE SPLIT (2026-07-06):** the Brew /
  Venom spec is now its OWN class (`ALCHEMIST-PLAN.md`, working name filler) — **base minigame
  BUILT & playable same day** as the caster seat's second option (`--autostart=raid:caster:brew`;
  voidcaller stays the default — byte-identical unless picked); creeds/modules/boons follow
  Bill's live playtest. Twinfang owes a rhythm-variant second spec (TEMPO-PLAN §13) — the
  in-code poison-wheel Venom stays the frozen placeholder aspect until then.
- **BOSS REDO INCOMING:** the 15 solo bosses are the casting pool (recast, never rebuilt);
  the 4 Seals (Vorathek / Mistral / Gemini / Mythos) get a PILLAR PASS toward the new combat
  pillars, then deeper reworks later (see MASTER-PLAN §BOSSES).
- **SIM SURFACE = what's worth simming (2026-07-06):** old class/boss sims + dead-HUD smokes
  were **DELETED** (recover from git history if a rework wants one back). Don't gate on
  frozen-kit balance; determinism still gates everything active.

## COMBAT PILLARS (locked 2026-07-06 — full spec in `WORLD-PLAN.md`; reworks must obey)
1. **SINGLE TARGET LAW** — one boss, one telegraph stream, no targeting UI. Multi-target
   flavor = adds / owned adds / split phases / chains only.
2. **DODGE RATION** — universal dodge stays for every seat, but ~3–8 authored beats per
   fight for non-tanks (tanks keep the densest footwork). Every rework defines its
   PERFECT/GOOD payoff and where beats sit in its rhythm. **ONE DODGE VERB (2026-07-08,
   `DODGE-PLAN.md`):** the old two-verb split (SPACE defensive-negate + a separate F
   barrage-dodge) is collapsed into ONE spacebar dodge that answers both shapes, on one cd
   (0.35s recovery / 1.3s whiff). LIVE for **Twinfang · Alchemist · Well**; the rest keep
   the two-verb split byte-identical (opt-in `ClassKit.unified_dodge()`) until reworked —
   every new/reworked kit ships on the one dodge.
3. **INTERRUPT-BY-ABILITY** — no kick button, no kicker class: flagged existing abilities
   (ideally dumps — the *interrupt tax*) kick inside a TIGHT window; per-class carrier
   counts (2/1/0) are comp texture. Sims measure accidental vs deliberate kick rates.
4. **WARBAND LAW** — every fight is tuned for exactly 4 seats (AI backfill). No 1-to-x
   enemy scaling system exists, ever.
5. **OVERWORLD POWER RULE** — zone/event fights = bare kit + persistent unlocks; boons /
   curios / Tokens / charge live in instances only.

## Repo layout & how to run
- `godot/` — the Godot 4.7 project (`res://`). GDScript, GL Compatibility renderer.
- Godot at `~/.local/bin/godot` (4.7-stable, standard build). `tools/windows/` = win64 engine
  (`play-windows.bat`); `server/` = deploy kit (Docker/tunnel, `serve-local.sh`,
  `build-web.sh` → browser WASM client).
- **Fresh checkout: run `godot --headless --path godot --import` first** (builds the
  global-class cache, or `--script` runs can't resolve `class_name`s).
- Play: `godot --path godot` (add `--rendering-driver opengl3` if WSLg struggles).
  Debug jump-ins: `--autostart=raid[:seat[:aspect[:boss]]]` · `raidmap[:seat[:aspect]]` ·
  `gate[:seat[:aspect]]` (more idioms in HISTORY.md).
- Online: `./server/serve-local.sh`, client PLAY ONLINE. ⚠ Protocol is versioned — rebuild +
  redeploy the server together with clients (old versions rejected at handshake by design).

## ACTIVE VERIFICATION (the merge-back bar)
- **THE BAR IN TWO COMMANDS (REFIT P2):** `scripts/verify-all.sh` runs the whole surface
  below headless-parallel (nonzero exit on ANY fail; `SEEDS=300` for heavy claims) ·
  `scripts/ab-gate.sh <sim> [args]` is the byte-identical gate — working tree vs a PINNED
  baseline worktree, so a concurrent session's merge can't false-diff you (replaces the
  cp-to-scratch folklore). `server/preflight.sh` before any deploy (commit+protocol line).
  Shared probe helpers live on `sim/sim_util.gd` (arg/arg_int/fmt_causes — don't re-roll).
- **Balance sims (the live five):** `sim/twinfang_sim.gd` (Tempo pilot loop),
  `sim/raid_sim.gd` (the 4 Seals; `--boss=mythos`, `--caster=alchemist` etc),
  `sim/alchemist_sim.gd` (the Brew base loop), `sim/well_sim.gd` (the Well base loop)
  and `sim/forge_sim.gd` (Forge id-is-recipe certification). Shard across cores with
  **`scripts/psim.sh <sim> [seeds] [jobs] [-- --boss=…]`** (~5×). Fast raid tuning knobs:
  **`./tune.sh`** (`--dmg= --regen= --fortify=`, `--probes=0`).
- **System probes (keep green when you touch their system):** `draft_sim` · `gear_probe` ·
  `commander_probe` · `map_sim` / `raid_map_sim` / `map_check_sim` + map probes ·
  `fight_seed_probe` · `menu_probe` · `meter_probe` · raid probes (`raid_probe`,
  `raid_boon_probe`, `raid_healer_probe`, `raid_bloom_probe`, `raid_reckoner_probe`).
- **Smokes:** `ui_smoke_raid` (THE HUD) · `ui_smoke_map` (the RAID descent walked screen by
  screen — re-hosted onto raid_main in REFIT P1; the solo version died with the solo
  scenes) · `ui_smoke_world` · `net_smoke` / `net_map_smoke`
  (real server + 2 WS clients over loopback, checksum-identical or fail).
- **Visual probes (WSLg, NOT --headless):** `screenshot_*` / `*_tour` scripts → PNGs; use for
  any new screen or `_draw` work. Headless cannot render custom `_draw`.
- **Determinism PASS is non-negotiable everywhere active.** Byte-identical checksum gates
  apply to engine touches and anything guarded-off (flag absent ⇒ identical); the old
  "all six class sims byte-identical" gate is retired with the roster reset.
- Engine/regression A/B across concurrent sessions: **freeze snapshots** (`cp -r godot/` to
  scratch) and compare there — another session's merge mid-gate produces false diffs.

## The one non-negotiable architectural rule
The combat engine (`CombatCore`) is a **pure, deterministic, Node-free reducer**. The *same*
`update(state, dt)` runs in the live client, the authoritative server, and headless batch
sims. Zero rendering, zero wall-clock, zero unseeded randomness, zero mutable module-level
globals. Everything else is a client of it.

### Determinism rules (build in from day one — never retrofit)
1. **Fixed 30 Hz timestep.** Accumulator drains `update(1.0/30.0)`; `render()` reads state.
2. **Integer tick is truth.** Derive `time = tick * DT`; store absolute times as ticks.
3. **One seeded PRNG in state**, advanced only inside `update()` in a fixed order. Cosmetic
   randomness uses a separate client-only RNG. Per-policy AI reads use their own seeded
   `DetRng` streams — never `state.rng`.
4. **Input is a tick-stamped queue** drained at the top of the owning tick.
5. **No hard-coded balance literals** — tuning lives on `TuningConfig` / per-class configs.
   No mutable module-level globals.
- Netcode is **server-paced deterministic lockstep**: the server relays tick-stamped INPUTS;
  every machine steps the identical `RaidNet.step()` from `(seed, spec)`; checksums ride
  every 30th frame **as strings** (63-bit ints don't survive JSON floats). Persistent state
  that touches combat enters as pure data in `(seed, spec)` — like aspects/boons/gear.

## Seat model (human = AI = sim agent)
Every participant is a **seat**: `(role, observation-adapter, action-set, policy, fidelity)`.
`perform(action)` is the single input surface — keyboard/mouse, AI policies, and sim agents
all emit it. Two fidelities: STAT-BLOCK (`dps * f(hp%)`) and FULL (policy drives the real
kit). Classes snap on via `ClassKit` hooks + `seat.vars`; engine features for one class are
**guarded no-ops** for everyone else (byte-identical when unused). Boss scheduler resolves
**only one telegraph per tick**; boss ability timers FREEZE during a telegraph (melee keeps
ticking); a multi-beat string is ONE telegraph to the scheduler.

## Locked platform decisions (2026-07-01, still standing)
Godot 4.x + **GDScript** (web export + iteration; C# rejected) · server-authoritative
dedicated headless Godot server over **WebSocket** (browser + native) · self-hosted Docker +
TLS tunnel (`wss://` for browsers) · **browser (WASM) client first**, native free later ·
balance sims **in-engine, headless** (same code = game + sim) · boss = data-driven
encounters; allies = per-role `policy.act(obs)` on the human input surface, skill = policy
parameter (latency/accuracy).

## Gotchas (hard-won — read before their subsystem)
- **GDScript:** `Dictionary.get(...)` into `:=` = Variant-inference parse error; ONE broken
  parse in a `class_name`'d file cascades ("Failed to compile depended scripts" → statics
  init empty). `const` can't hold `Palette` statics — use `static var`.
- **UI:** set anchors BEFORE `add_child` (place-then-add); `CenterContainer` for centered
  stacks, never `PRESET_CENTER` on the box itself.
- **Godot/net:** Node subclasses must not define `_input(id, msg)` (clashes with the
  virtual). Client sets its phase BEFORE sending join. Probe scripts: start the run at frame
  1 of `_process`, not `_initialize` (HUD `_ready` hasn't run).
- **WSL:** WSLg GUI needs `--rendering-driver opengl3` sometimes; WSL is NAT-mode here —
  Windows clients reach WSL services via the **eth0 IP, not localhost**.
- **Sims:** `RunState` couples every class's content into every sim's compile graph — never
  edit ANY kit while ANY sim runs. `psim.sh` output is byte-identical to a single run.
- **Naming:** the telegraph-answer enum is `AbilityRes.Response` (avoids the `Telegraph`
  class clash). The persistent world map = **ATLAS**; per-run instance maps = **TOPOLOGY** —
  never mix the words.
- **Co-op credit caveats:** feint hold-rewards route via `on_damage_taken` (dmg>0); absorb
  credit is per-seat-pool, last ward-caster owns it (`absorb_owner_i`/HoT `caster_i` are
  INDICES — RefCounted-cycle safe; use the same idiom for any new cross-seat ref).

## History
The full verified build-up (M0 walking skeleton → classes → strings → Gilded Reliquary →
stages → R0–R2.5 online → maps) lives in **`HISTORY.md`** — debug jump-ins, engine notes,
and per-milestone gotchas. Its verify commands may name sims deleted in the 2026-07-06
fresh slate; git history has them.
