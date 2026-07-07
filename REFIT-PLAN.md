# REFIT-PLAN — Structural Audit v2 → THE SHELL REFIT (2026-07-07)

Five-agent structural audit (engine/data · net/server · UI/HUD · world/meta/persistence ·
sims/tooling) run 2026-07-07 against the post-pivot era: **world preview = the real game
shell** (grows into the MMO layer: lobbies, parties, presence), **one centrally hosted
server** replaces the old PLAY ONLINE model, **raid autostart = dev harness**, 2D art pass
someday. Scope was structure/tech-debt, NOT individual bugs/balance/art. This doc is the
audit of record + the fix plan + the target architecture. The 2026-07-03 audit's parked
items (MASTER-PLAN §CODE AUDIT) are folded in where they overlap.

## THE VERDICT (one paragraph)

**The foundation is sound; the shell around it is the debt.** The three hard laws are
genuinely holding — CombatCore purity (zero Node/wall-clock/unseeded-random hits across
core/ + all 8 kits), the `(seed, spec)` combat-entry contract (all persistent state crosses
as pure data), and the seed→content chain (Forge/RunMap/packroll all DetRng-from-id,
certified by probes). What's wrong is everything wrapped AROUND that engine: `raid_hud.gd`
(5,245 lines) is four programs in a trenchcoat (screen router + campaign director + combat
HUD + online lobby) and is where the world shell currently lives; `net_server.gd` carries a
duplicated copy of the campaign engine and has no persistence/identity/reconnect; ~6.5k
lines of declared-dead solo code are still in-tree, held reachable by ONE line; saves are 8
ad-hoc unversioned files; and the "non-negotiable" byte-identical gate is folklore with no
script. None of this is surprising for early alpha with this many pivots — but the pivots
are now locked, so this is the moment to refit the shell to match them.

## §1 WHAT'S SOUND (the protected list — never regress these)

- **CombatCore purity is real, not aspirational.** Grep-verified zero rendering/wall-clock/
  unseeded-random/mutable-global leaks in `core/` + all kits. Crown jewel #1.
- **`net/raid_net.gd` (220 ln)** — the pure `(seed, spec) → build → step → checksum`
  lockstep core, shared byte-identically by client/server/sims. Crown jewel #2. The whole
  MMO future bolts onto this UNTOUCHED.
- **ClassKit is a real interface** (18 no-op hooks, disciplined subclasses), not 8 dialects.
- **Index-not-ref discipline** (`absorb_owner_i`, HoT `caster_i`, threat/meter by seat index)
  honored everywhere checked.
- **Pure-data Resource schema** (`ability_res`/`encounter_res`/`strike_res`/`phase_res`) with
  one-`match` effect dispatch — data-driven bosses are already possible, just unused.
- **State→visual separation:** `raid_hud` has ZERO `_draw`; widgets are pure obs-readers
  (one-directional; a gauge cannot break determinism). `Actor2D.make()` factory +
  `sprite_actor_2d` is ALREADY the 2D-art swap seam — puppets swap with zero logic change.
- **`world_save.gd` is the model persistence citizen** — versioned (v1), canonical sorted-key
  JSON, disk-inert headless. Everything else should copy it.
- **World data/state/render split** (WorldContent / WorldSave / AtlasScreen+ZoneScreen) is
  clean and headless-testable; WorldSave is never cross-written from run flow (the
  economy/permanence line holds by construction).
- **Multi-room-per-process already works** in `net_server.gd` — the instance-multiplexing the
  hosted future needs is half-built.
- **Repo hygiene basics:** .gitignore correct (no committed artifacts), sims uniformly
  `extends SceneTree`, `_initialize` vs frame-1 split is intentional per the HUD gotcha.

## §2 WHAT'S WRONG (converged findings, ranked)

### HIGH — the five structural blockers

1. **`game/raid_hud.gd` (5,245 ln, 208 funcs, ~60 members) is a god file fusing four
   programs** — flagged independently by three auditors as the #1 blocker:
   (a) screen-flow router: an 18-state string machine (`_screen`, 30+ assignment sites,
   ~20 `_show_*` methods rebuilding one `_ui` Control); (b) run/campaign director
   (Topology floors/nodes/tickets/gear/drafts, `:1564–2838`); (c) the combat HUD proper
   (`:2932–3477` build, `:4097–4720` render, `:3668–3977` input); (d) the online
   lobby/netmap (`:1012–1500`). The world shell (atlas `:726` / bastion `:767` / zone
   `:815`) and Commander (`:160–193`, `:1604–1631`) are *modes of the combat HUD*. The
   stated future is the inverse: the world owns the HUD.
2. **`net/net_server.gd` (826 ln) is a raid-descent state machine, not a session host.**
   Lines 413–798 are a full server-side copy of the Topology campaign engine — self-admitted
   at `:501` "*Mirror of raid_hud._ticket_at, server-side*". Plus: **zero persistence** (a
   restart wipes every fight/campaign), **no reconnect/rejoin** (a returning player is a
   stranger), **client-trusted identity** (`:242` trusts the client's `prior`), **hard
   version cutover** (bump `VERSION` ⇒ 100% of clients kicked, no drain/N-1), **unbounded
   rooms/connections/message rates**, and an **uncapped headless loop** (100% of a core,
   idle).
3. **~6,518 lines of declared-DEAD code still in-tree, held live by ONE line.**
   `raid_hud.gd:3757` (Esc outside combat → `change_scene_to_file("res://game/main.tscn")`)
   is the only doorway into the whole solo cluster: 5 solo HUDs (4,366) + `main_menu.gd` +
   6 dead .tscn (250) + `stage3d/` entire (1,387) + `stage2d/combat_stage_2d.gd` (429) +
   solo-only widgets `gcd_cursor`/`litany_pips` (86). Plus orphans: 6 screenshot/tour sims
   that load ONLY dead scenes, `sim/policies/tank_policy.gd` + `data/m0_content.gd` (dead
   pair, zero live refs). **Worse: an ACTIVE merge gate tests dead code** —
   `sim/ui_smoke_map.gd:17` boots `bulwark_main.tscn` and drives the SOLO map machinery
   (false confidence; CLAUDE.md believes dead-HUD smokes were deleted 2026-07-06).
4. **No unified save system.** 8 ad-hoc `user://` files, only WorldSave versioned
   (`rift_gear.cfg`, `rift_prior.cfg`, `rift_ui.cfg`, `rift_net.cfg`, 3× `*_binds.json`
   unversioned); **Commander roster not persisted at all** (`_party`/`_ai_runs` are HUD
   dicts). For the server-side-state future there is no Profile aggregate, no migration
   ladder, no single authority. (Widens the 07-03 parked "save versioning" note.)
5. **The verification law is folklore.** No one-command "run the gates" script and no
   byte-identical A/B script — the non-negotiable gate is `cp -r godot/` + eyeballing.
   `tools/verify-all.sh` has been "Next up" in MASTER-PLAN §TOOLING and is unbuilt.
   Sim-harness copy-paste is now DRIFTING (6 md5-identical `_arg` copies + 1 diverged in
   `well_sim`), exactly the failure the parked DRY item predicted.

### MED — the scaling debts (hurt at 2× content)

- **Compile-graph fan-out hubs:** `game/run_state.gd:38–78` + `data/raid/raid_content.gd`
  hard-reference ALL 8 classes' Kit/Config/Content class_names → touching any kit dirties
  the graph every sim/HUD depends on (the CLAUDE.md gotcha, structural cause). Fix = class
  registry (`class_id → factory`), also the precondition for net spec-carry of arbitrary
  builds.
- **Per-class leaks in the shared engine:** 6 class-named fields on generic `boss_state.gd:18–32`
  (silence/expose/dmg_buff/sunder/debilitate), 3 stacked amp branches in `damage_boss`
  (`combat_core.gd:680–685`), and one hook-bypassing string read — the reducer reads Well's
  `seat.vars["glint_until"]` directly (`combat_core.gd:829`). Missing abstraction: ONE
  generic boss-vulnerability stack (also what the parked TEAM-COMP schools layer wants).
- **Per-class if/elif ladders in THE HUD:** each class = `_build_band_X` + `_render_band_X`
  + `_X_key` + ~6 dispatch sites + a nullable member gauge (~30 of the ~60 members). No
  ClassBand interface/registry; class #9 = copy-a-block + a fresh bespoke 400–600 ln
  `_draw` gauge (no shared Gauge base).
- **`seat.vars` = ~160 untyped magic-string keys** (twinfang ~70) with no
  namespace/schema/registry; `observe()` emits 14–42 stringly keys per kit consumed by dict
  lookup. The fragile boundary once builds carry over the network / into saves.
- **The Split law is convention, not structure:** `RaidNet.make_spec` accepts `seat_boons`
  for ANY fight; zones stay bare-kit only because `_launch_zone_fight` chooses to pass `{}`.
  One careless caller silently violates a locked pillar.
- **Offline `run_seed` is wall-clock** (`Time.get_ticks_usec()`, raid_hud `:956/:981/:1979`)
  — blocks the replay/ghost-race/leaderboard ambitions that the deterministic engine
  otherwise gives for free (online is fine — server seed).
- **Content is code despite a data-ready schema:** every boss/encounter imperatively built
  in `*_content.gd`; the planned `.tres` authoring path was never built. Zone authoring is
  semi-bespoke (Zone 2 forks the Gildfields flavor consts, `world_content.gd:249–266` are
  not per-zone keyed).
- **`data/twinfang/twinfang_kit.gd` (1,451 ln)** carries 3 aspects in one file — 2.5× the
  next kit; the template the next multi-spec class will copy unless split per-spec.

### LOW (worth a line each)

- Kit boilerplate duplicated 8× (`_b`, `_tt`; `_has_payloads` ×5) — belongs on ClassKit base.
- Hardcoded balance literals in the "no literals" reducer (`combat_core.gd:384/398/807`;
  the `0.55` cap double-sourced with `raid_marks.gd:14`).
- Live-widget helper dialects beyond the parked §712 item (`_label`/`_title`/`_gap` re-rolled
  in atlas/zone/map/draft/boss_select/arming/map_event) — the UiKit hoist is bigger than parked.
- `forge.gd:76` uses `String.hash()` in seed mix — same cross-build determinism watch-class
  as Dictionary-iteration order (safe while the version gate guarantees identical builds).
- Doc drift (FIXED with this audit): CLAUDE.md said "the only three" balance sims (live =
  five), psim.sh help omitted forge_sim, plan-doc index missed SEAL-PILLAR/FERMATA briefs.
- `godot/out/` = 1.9 MB local cruft incl. deleted-sim results (gitignored; just clean it).
- Net hygiene: duplicate `room["spec"]` (net_server `:772–773`), phantom `hello/bye` in
  net_protocol docs, `_make_room` phase comment stale.
- 14 root .md ≈ 590 KB; HISTORY/PORT-PLAN/port-brief/poc//rift.html are self-labeled
  historical → `archive/` candidates.

## §3 THE FIX PLAN (phased; each phase = one claimable session-sized chunk)

Ordering logic: **delete before extracting** (less to move), **tooling before refactors**
(the gates make the refactors safe), **extractions before MMO features** (the shell must
exist before lobbies/parties land on it). Acceptance bar for every phase: determinism PASS;
byte-identical where the change is meant to be neutral; smokes green; WSLg screenshots for
anything visual.

### Phase 0 — PAPER CUTS (same-day, no gameplay effect) — ✅ doc items DONE with this audit
- ✅ CLAUDE.md sims-list drift + plan-doc index; psim.sh help string.
- ☐ `server_main.gd`: cap the headless loop (`Engine.max_fps` or physics-tick) — one line,
  stops idle 100%-CPU on the always-on box.
- ☐ `net_server.gd`: `_rooms` cap + connection cap + per-peer message-rate guard in
  `_handle` (`:233`) — the cheap DoS floor (first cut of the parked hardening item).
- ☐ Net hygiene: duplicate spec line, phase comment, phantom hello/bye doc.
- ☐ `rm godot/out/*` stale results (+ optional `--clean` in psim.sh).

### Phase 1 — THE BIG DELETE (~6.5k lines; one session; byte-identical gate)
1. `raid_hud.gd:3757` Esc → `_show_home()` (severs the ONLY live doorway; also fixes
   Esc-dumps-you-in-a-dead-menu).
2. Re-host `sim/ui_smoke_map.gd` on `raid_main.tscn` driving the RAID map flow (an active
   gate must not test dead code) — prerequisite for deleting bulwark_hud.
3. Delete: 5 solo HUDs + `main_menu.gd` + `main.tscn` + 5 `*_main.tscn` + `stage3d/` +
   `stage2d/combat_stage_2d.gd` + `ui/gcd_cursor.gd` + `ui/litany_pips.gd` + the 6
   dead-scene screenshot/tour sims + `sim/policies/tank_policy.gd` + `data/m0_content.gd`
   (+ verify-then-delete `gauge_gallery.gd`; `screenshot_meter.gd` loses its twinfang half).
4. Later, coordinated: trim kit `observe()` keys that only fed dead HUDs (engine+HUD
   together; NOT part of the delete sweep).
   Note: `map_content.event_ids()` looks dead but anchors `map_sim` determinism — KEEP.

### Phase 2 — GATES IN A BOX (the tooling that makes everything after safe)
- `sim/sim_util.gd` — shared arg-parse/seed-loop/CSV/checksum-band printer (the parked §711
  item, now overdue: one copy already diverged). New probe ≈ 30 lines, canonical checksum
  format.
- `scripts/verify-all.sh` — the merge-back bar as ONE command: 5 balance sims + system
  probes + 4 smokes, headless, nonzero exit on any FAIL/parse error.
- `scripts/ab-gate.sh <sim> [args]` — byte-identical A/B as a script: working tree vs
  baseline (git worktree at merge-base or frozen snapshot), diff checksum/CSV md5, print
  PASS/FAIL. Kills the `cp -r` folklore.
- `server/preflight.sh` — assert protocol VERSION + build hash match before deploy (the
  handshake-rejection design makes silent mismatch a real hazard).

### Phase 3 — THE THREE EXTRACTIONS (the shell inversion; the heart of the refit)
Each its own worktree/claim, in this order:
1. **RunDirector** — lift the campaign/run state machine out of `raid_hud.gd` (`:1564–2838`)
   into a shared headless module, and make `net_server.gd:413–798` consume the SAME module
   (kills the ":501 mirror" duplication — one extraction closes two HIGH findings).
   Precedent that it detaches cleanly: bulwark_hud carried a standalone copy for solo.
2. **WorldShell** — a persistent shell scene that OWNS atlas/zone/bastion (AtlasScreen/
   ZoneScreen adopt as-is; give Bastion a real screen class) + the screen router, and
   *launches* the combat HUD as an instance surface. Autostart becomes "drive the shell"
   (one dev-harness entry, not a parallel boot path). raid_hud shrinks toward ~2k lines of
   combat-only HUD.
3. **Online split** — the lobby/connect/netmap UX out of raid_hud into a shell-owned
   controller. "PLAY ONLINE" the screen dies here; connectivity becomes a shell property
   (presence), fights become instances you enter from the world.

### Phase 4 — SCALE RAILS (before the roster/content wave; each independent)
- **Class registry** (`class_id → factory`) breaking the RunState/RaidContent fan-out.
- **ClassBand registry** in the HUD (build/render/key strategy per class) — deletes the
  if/elif ladders + ~30 nullable members; add a shared Gauge base for the common shell.
- **ClassKit hoists** (`_b`/`_tt`/`_has_payloads`) + TuningConfig literals sweep.
- **Generic boss-vulnerability stack** (sunder/debilitate/expose → one funnel) + route
  Well's glint through a proper hook (deliberate rebaseline — checksums shift).
- **Save unification:** one versioned Profile aggregate (WorldSave's pattern) owning
  world/gear/prior/binds/**roster**; version-check GearStore/LuckProfile/binds now (4-line
  copy); persist the Commander roster (also unblocks warband lending).
- **Reproducible offline `run_seed`** (persisted seed, not wall-clock) — unlocks
  replay/ghost-races.
- **Split-law guard:** make zone/world fight contexts structurally refuse `seat_boons`
  (assert or context enum in `make_spec`) so the pillar can't be violated silently.
- **Per-spec kit split** for twinfang (shared base + Tempo/Fermata/Venom modules) before
  the next multi-spec class copies the 1,451-line shape.

## §4 THE FUTURE ARCHITECTURE (the MMO-shell era — where the refit is pointed)

**Client shape:** `WorldShell` (own scene, the front door) owns presence, party UI, atlas/
zones/bastion, Commander, and the save Profile; it *launches* instances (raid/dungeon/zone
fights) whose surface is the slimmed combat HUD. RunDirector is a shared module both the
shell and the server step. The dev autostart drives the shell.

**Server shape (the lockstep law untouched end-to-end):**
1. **Gateway/Session layer (persistent):** owns connections + auth (token → player-id that
   survives reconnect; today's client-trusted `prior` dies here), presence ("in the world,
   not in a fight" — a state that doesn't exist today), party primitives
   (invite/accept/decline as a new message family; party ≠ fight room), and instance
   spawn/matchmaking (server-minted instance ids, not user-typed room codes).
2. **InstanceHost (ephemeral):** today's `_tick_room` + `RaidNet.step` + 30-tick
   checksum-as-string cadence, extracted verbatim, spawned per fight/descent. `(seed, spec)`
   minted by the session layer with account-linked seats — the ONLY bootstrap change.
3. **CampaignEngine:** the Phase-3 RunDirector module, stepped server-side, its state
   persisted in a server store → restarts survive, rejoin works (grace window + seat
   reclaim; needs a small per-instance frame ring to fast-forward a returning replica).
4. **Profile store:** the Phase-4 Profile aggregate moves from `user://` to the server as
   the authority (client keeps a cache). Combat never notices — persistent state already
   enters as pure `(seed, spec)` data. This is a storage/authority move, NOT a combat
   refactor: the audit's best news.
5. **Rollout:** N/N-1 protocol tolerance OR a drain broadcast ("server updating — reconnect
   in X") + a health/version line, so ONE central server can deploy without kicking everyone
   mid-fight. Version-gate stays as the build-identity guarantee.

**Content pipeline:** build the `.tres` loader the schema was designed for (designers/tools
author encounters as data; the Forge already proves generated-content-as-ids); a zone
schema/loader with per-zone-keyed flavor so Zone 2+ is data, not a fork of Gildfields
functions; Forge palettes are the model.

**2D art pass readiness:** actor layer is DONE (drop art .tscn into the Actor2D factory
seam). Gauges/widgets stay procedural `_draw` until the art era, but give them the shared
base + stable obs contract first so retheme is once, not 35 times. Screenshot tours (not
headless sims) remain the verification for this layer — keep them repointed at raid_main.

**Determinism watch (pre-hosted-server):** cross-platform WASM-vs-native float /
`Dictionary`-iteration / `String.hash()` behavior is the real lockstep risk once one central
server serves mixed clients — worth a dedicated certification probe before the server goes
always-on. (Carries forward the 07-03 parked item; `forge.gd:76` added to its list.)

## §5 CLAIM GUIDE

| Claim | Size | Depends on | Gate |
|---|---|---|---|
| P0 net/server paper cuts | hours | — | byte-identical (guarded) + net_smoke |
| P1 THE BIG DELETE | 1 session | P0 Esc repoint first | verify surface green, byte-identical sims |
| P2 GATES IN A BOX | 1 session | — (parallel-safe with P1) | self-proving (the scripts ARE the gate) |
| P3.1 RunDirector | 1–2 sessions | P1 (less to move), P2 (safety) | byte-identical + net_smoke/net_map_smoke |
| P3.2 WorldShell | 1–2 sessions | P3.1 | ui_smoke_raid/world + WSLg tour |
| P3.3 Online split | 1 session | P3.2 | net smokes checksum-identical |
| P4 items | 1 session each | P2; vuln-stack + glint = deliberate rebaseline | per-item; registry/DRY = byte-identical |
| MMO shell (§4) | the next era | P3 complete | new netcode-era plan when claimed |

2026-07-03 parked items, disposition: checksum-coverage → §4 InstanceHost (net-layer hash,
option b stands); `seat.casting` index fix → P4 (with the seat.vars schema work); sim DRY →
P2; HUD factories DRY → P1+P4 (wider than parked); hardening → P0 first cut + §4 gateway;
WASM determinism → §4 watch item (unswept, still the sharpest lockstep risk).
