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

### Phase 0 — PAPER CUTS — ✅ BUILT 2026-07-07 (branch `refit-p012`)
- ✅ CLAUDE.md sims-list drift + plan-doc index; psim.sh help string (with the audit).
- ✅ `server_main.gd`: `Engine.max_fps = 60` — no more idle 100%-CPU on the always-on box.
- ✅ `net_server.gd`: `MAX_PEERS` / `MAX_ROOMS` / `MSG_BUDGET_PER_SEC` (refuse at welcome ·
  no room-minting past the cap · rolling 1 s per-peer budget, 4× over = cut) — every bound
  far above legitimate 4-seat × 30 Hz traffic, so the net smokes ride unchanged.
- ✅ Net hygiene: duplicate spec line dropped, phase comment fixed, protocol header now
  matches the real taxonomy (phantom hello/bye out; class/arm/arming in).
- ✅ stale `godot/out/` deleted-sim results cleaned (main repo, at merge).

### Phase 1 — THE BIG DELETE — ✅ BUILT 2026-07-07 (net −6,854 lines · 50 files deleted)
1. ✅ `raid_hud.gd` Esc outside combat → `_show_home()` (the only live doorway severed;
   Esc no longer dumps you in the dead menu).
2. ✅ `sim/ui_smoke_map.gd` RE-HOSTED onto `raid_main.tscn` — now a multi-frame RAID
   descent driver: map → stops/events → ledger oaths → arming → burst-won pulls → drops →
   boon-draft chains → PRIVILEGE ELEVATED. Flow smoke (routing invariants, fixed map
   seed); this is its documented NEW BASELINE — the old solo walk died with the scenes.
3. ✅ Deleted: 5 solo HUDs · `main_menu.gd` · 6 dead `.tscn` · `stage3d/` entire ·
   `stage2d/combat_stage_2d.gd` · `gcd_cursor`/`litany_pips` · 6 dead screenshot/tour
   sims · `gauge_gallery.gd` (stale Tempo-era gauge API — git history has it) ·
   `tank_policy.gd` + `m0_content.gd` · `screenshot_meter.gd` trimmed raid-only.
   Residual-ref grep CLEAN (every remaining hit is the live raid surface).
4. ☐ Later, coordinated: trim kit `observe()` keys that only fed dead HUDs (engine+HUD
   together; deliberately NOT in the delete sweep).
   Note: `map_content.event_ids()` looks dead but anchors `map_sim` determinism — KEPT.

### Phase 2 — GATES IN A BOX — ✅ BUILT 2026-07-07
- ✅ `sim/sim_util.gd` — `arg`/`arg_int`/`arg_float`/`fmt_causes` hoisted; 7 sims migrated
  (raid/twinfang/alchemist/raid_map + well/healer/net), well_sim's already-diverged copy
  folded back in. **As-built correction to the parked §711 note:** the `_write_csv`
  bodies are NOT identical anymore — schemas legitimately differ per sim — so CSV
  writers stay per-sim by design; only the true duplicates were hoisted.
- ✅ `scripts/verify-all.sh` — the whole bar, one command: 5 balance sims + 26 probes +
  3 UI smokes in parallel across cores, net smokes serialized on the loopback port,
  per-script logs, nonzero exit on ANY fail / script-error / missing sim.
- ✅ `scripts/ab-gate.sh <sim> [args]` — byte-identical A/B vs a worktree PINNED at
  merge-base (a concurrent session's merge cannot false-diff), full-stdout diff +
  fresh-CSV md5.
- ✅ `server/preflight.sh` — refuses dirty deploys; prints the commit+protocol line to
  compare against "version mismatch" reports.

### Phase 3 — THE THREE EXTRACTIONS (the shell inversion; the heart of the refit)
Each its own worktree/claim, in this order:
1. **RunDirector** — lift the campaign/run state machine out of `raid_hud.gd` (`:1564–2838`)
   into a shared headless module, and make `net_server.gd:413–798` consume the SAME module
   (kills the ":501 mirror" duplication — one extraction closes two HIGH findings).
   Precedent that it detaches cleanly: bulwark_hud carried a standalone copy for solo.
   **P3.1a ✅ BUILT 2026-07-07 (branch `refit-p3`) — THE MIRROR IS DEAD:**
   `game/campaign_core.gd` is the ONE campaign rulebook — node entry (visited/shard/
   TICKET/key), ticket open/close (+stub/purse returns), post-fight writeback
   (+ verdict-keyed `writeback_exam` for gates — faithfulness caught in review: a healer
   can lose an exam while standing), skirmish ⏻ scavenge, cooling/cache fx consts, and
   `resolve_event_choice` (moved verbatim off NetServer; 6 probe callers repointed).
   Both `net_server.gd` (`_ticket_srv` DELETED, writeback/cooling/cache/resolve consume
   the core) and `raid_hud.gd` (`_ticket_at` DELETED; `_cp_view`/`_cp_writeback` bridge
   the members to the shared rulebook) step it. raid_map_sim's walker = documented
   diagnostic simplification, not a mirror. GATES: raid_map_sim + map_sim ab-gate
   BYTE-IDENTICAL · all map probes green · net smokes + ui smokes ALL OK. Bonus: 2 of
   main's 3 stale probes REVIVED as deliberate updates (`map_advance_probe` now drives
   ledger/recap/rig/module ceremonies; `raid_boon_probe` presses through the recap) —
   `fightlen_probe` remains the open expectations claim.
   **P3.1b ✅ BUILT 2026-07-07 — the state move:** `game/run_director.gd` owns the
   descent's 31 members (Topology floor/fracs/wounds/mana/tickets · ⚡/📁/flags/⏻ meta ·
   GEAR curios/purse/unlocks/drop-rng · boon runs + COMMANDER party · oaths) +
   `cp_view()/cp_sync()` (the bridge moved off the HUD). raid_hud holds ONE `_d` and
   renders it — word-boundary rewrite across the HUD + 11 probes/smokes (`hud._d.…`).
   **Design decision vs the original sketch:** the SERVER keeps its campaign dict — it
   natively IS the cp-view shape (the rulebook can't tell the sides apart), and a
   serializable dict is what the persistence/rejoin era wants server-side; forcing the
   RefCounted object there would be churn against that future. RunDirector is the
   CLIENT-side descent state the WorldShell (P3.2) will hold.
2. **WorldShell** — a persistent shell scene that OWNS atlas/zone/bastion (AtlasScreen/
   ZoneScreen adopt as-is; give Bastion a real screen class) + the screen router, and
   *launches* the combat HUD as an instance surface. Autostart becomes "drive the shell"
   (one dev-harness entry, not a parallel boot path). raid_hud shrinks toward ~2k lines of
   combat-only HUD.
   **P3.2a ✅ BUILT 2026-07-07 — the ownership inversion:** `game/world_shell.gd` +
   `world_shell.tscn` is THE BOOT SCENE (`run/main_scene`); it raises raid_hud as its
   instance surface and owns ALL dev autostart idioms (`drive_autostart`, moved verbatim
   off `raid_hud._ready`; `--fightlen=` stays HUD-side as an instance feel-scalar). New
   `sim/shell_probe.gd` proves the chain (boot→HOME + all 5 idioms → right screen),
   wired into verify-all. Probes/smokes loading `raid_main.tscn` directly are untouched
   by design — the HUD stays self-contained. GATES: shell_probe + menu_probe + all 3 ui
   smokes + both net smokes ALL OK.
   **P3.2b-1 ✅ BUILT 2026-07-07 — the helper prereq:** `UiKit.title_in`/`UiKit.place`
   hoisted off raid_hud (121 call sites); the shell's screens build on the same helpers.
   Also with this slice: `fightlen_probe` FIXED (the LAST stale probe — its zone
   expectation was a hardcoded bard snapshot from before THE FORGE took the Gildfields
   nodes; it now derives from `encounter_by_id(node.fight)`, testing the SCALAR not a
   content snapshot; ALL OK ×1.00 and ×2.50). **All three of the audit's stale probes
   are now revived — the open-claim item is CLOSED; verify-all runs 35/35.**
   **P3.2b-2 ✅ BUILT 2026-07-07 — THE SCREENS MOVED UP:** all 23 world-layer functions
   (home/`_menu_button`/class select/raid select/aspect pick/party + `_start_world_pick`/
   atlas/dev-reset/pin-router/bastion(+stops)/zone(+enter/stops/simple-stops)/conquest
   writeback/autosave) moved to `world_shell.gd` in ONE contiguous cut, instance state
   reached via a TYPED `hud` (`const RaidHud := preload(...)` — raid_hud has no
   class_name; typing keeps `:=` inference alive in the moved bodies). The shell owns
   its own `_ui` overlay (mouse_filter IGNORE so an empty surface never eats instance
   clicks) + `_clear()` with the two-surface discipline: shell builders stamp
   `_screen` → `_clear()` snapshots/restores it around `hud._clear()`, whose leaf
   callback `_clear_shell_ui()` stamps "instance" when the HUD takes the stage.
   raid_hud keeps FOUR routing stubs (`_show_home`/`_show_select`/`_show_zone`/
   `_zone_clear_node` — the only names its own flows still call; Esc, fight ends, zone
   conquest route UP through them; standalone probe boots no-op). raid_hud is down to
   ~4,700 lines (from 5,309 at P3 start). Probes re-hosted: `menu_probe` (shell
   ceremony asserts) · `ui_smoke_world` (full flow through the shell + a two-surface
   `_scr()` reader for its walker + the _initialize/_ready frame-1 gotcha fixed) ·
   `ui_smoke_raid` (shell aspect/party drives, shell-wide `_press`) · `shell_probe`
   (world/zone idioms assert `shell._screen`). GATES: shell/menu/world/raid/map smokes
   + map_advance + commander + BOTH net smokes ALL OK + full verify-all.
   **OWED (logged, not gating):** 7 `screenshot_*` WSLg scripts still load raid_main
   for world-screen shots — they will error LOUDLY at the next visual pass (deliberate:
   loud beats silently-blank PNGs); re-host them onto `world_shell.tscn` then. State
   ownership (`_d`/WorldSave/zone members off the hud) lifts in a later tightening.
3. **Online split** — the lobby/connect/netmap UX out of raid_hud into a shell-owned
   controller. "PLAY ONLINE" the screen dies here; connectivity becomes a shell property
   (presence), fights become instances you enter from the world.
   **P3.3 ✅ BUILT 2026-07-07 — the seam that held:** the CONNECTION LIFECYCLE (connect
   form `_show_online`/`_edit` + the full lobby `_show_lobby`/`_on_room_shell`) moved to
   the shell — the presence door; the online DESCENT screens (net map/stops/draft/
   arming/wait + `_launch_online` + the replica controller) STAY on the instance
   surface — they are the online run, mirroring exactly where the offline descent
   screens live. `_me()` stayed HUD-side (a state reader over `_room`/`_net`); the
   `_on_net_dropped` router reads the SHELL's screen for lobby drops; 3 new stubs
   (`_show_online`/`_show_lobby`/`_on_room`) keep the net-signal wiring and home-button
   paths routing UP. GATES: net_smoke + net_map_smoke checksum-clean through the
   shell-owned lobby · shell/menu/raid/world/map smokes ALL OK.
   **PHASE 3 COMPLETE.** Still owed from its ledger: 7 screenshot_* WSLg re-hosts (next
   visual pass) · state-ownership lift (`_d`/WorldSave/`_net` off the hud) — natural
   P4 companion work.

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
| ~~P0 net/server paper cuts~~ | ✅ 2026-07-07 | `refit-p012` | ab-gates + net smokes green |
| ~~P1 THE BIG DELETE~~ | ✅ 2026-07-07 | `refit-p012` (−6,854 lines) | verify-all green, sims byte-identical |
| ~~P2 GATES IN A BOX~~ | ✅ 2026-07-07 | `refit-p012` | dogfooded on this very merge |
| P3.1 RunDirector | 1–2 sessions | P1 (less to move), P2 (safety) | byte-identical + net_smoke/net_map_smoke |
| P3.2 WorldShell | 1–2 sessions | P3.1 | ui_smoke_raid/world + WSLg tour |
| P3.3 Online split | 1 session | P3.2 | net smokes checksum-identical |
| P4 items | 1 session each | P2; vuln-stack + glint = deliberate rebaseline | per-item; registry/DRY = byte-identical |
| MMO shell (§4) | the next era | P3 complete | new netcode-era plan when claimed |

2026-07-03 parked items, disposition: checksum-coverage → §4 InstanceHost (net-layer hash,
option b stands); `seat.casting` index fix → P4 (with the seat.vars schema work); sim DRY →
P2; HUD factories DRY → P1+P4 (wider than parked); hardening → P0 first cut + §4 gateway;
WASM determinism → §4 watch item (unswept, still the sharpest lockstep risk).
