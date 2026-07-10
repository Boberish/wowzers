# BUILD LEDGER — the execution tracker (Project Rift)

> **What this is.** The one forward-facing list of *planned-but-not-yet-built* work, so the
> coming code phase doesn't clobber itself. Born 2026-07-09 after ~60 commits of docs-only
> design across ~15 plan docs left the "what still needs code" pile scattered with no unified
> view. **It tracks; it does not design.** Design detail lives in the plan docs; card-level
> status lives in `CARD-CATALOG.md`; decision *history* lives in the MASTER-PLAN Coordination
> Log. This doc sits above them and answers only four questions per item: **what's unbuilt ·
> where it's specced · what code it touches · what it collides with / waits on.**
>
> **Maintain it** (see §4): when a design locks, add/flip a row here in the *same commit*; when
> code merges, flip to 🔨 + SHA. This is a living doc through the planning week — update, don't
> let it rot. It is an INDEX, never a second spec — if you're tempted to write design here,
> write it in the plan doc and link.

**Sibling docs:** `MASTER-PLAN.md` (living state + decision log) · `CARD-CATALOG.md` (per-card
status) · `DECK-LAYOUT.md` (deck anatomy) · plan docs per system (WORLD / TANK / TEMPO /
ALCHEMIST / MENDER / PROGRESSION / GEAR / TEETH / REFIT / SEAL-PILLAR).

---

## LEGEND

| Glyph | Means | |
|---|---|---|
| 🔒 | **ready** | design locked — buildable now |
| 🟡 | **verdict** | waiting on a Bill decision before build (see §3) |
| 🔴 | **design** | captured only — design itself not finished |
| ⏳ | **owed** | base is built; this piece is the owed follow-up |
| 💡 | **idea** | parking lot — unclaimed, not decided |
| 🔨 | **wip / built** | in progress or merged (record SHA) |

**Playtest ≠ verdict.** Some 🔒 items (tank/flow numbers) are *design-locked, tune-on-feel* —
build them, then dial. That's not a §3 blocker.

---

## 0. READ FIRST — THE COLLISION MAP

The planned work is **not ~70 independent tasks.** It piles onto a handful of core files. Build
blind and two claims fight over the same reducer. These are the hotspots, ranked by centrality ×
incoming load.

### Core-file hotspots

| File (lines) | What's landing on it | Sequencing rule |
|---|---|---|
| `core/combat_core.gd` (1148) | FLOW=AGGRO rewire (threat, 44 refs) · dodge-unify finish (`:83-114`) · interrupt-by-ability flag · `perform()` input surface | **#1.** Aggro + dodge + interrupt all edit the reducer. Serialize. Aggro is a *deliberate* checksum rebaseline. |
| `game/raid_hud.gd` (4496) | Every class gauge · aggro box (25 refs) · voidcaller (15) · two-verb hint (`:2414`) · per-seat `_verb()` (`:2181`) · tank/dodge/drop UI | Land **ClassBand registry + shared Gauge base (REFIT-P4) FIRST**, or the per-class meter wave makes this unmaintainable. |
| `data/raid/raid_content.gd` (626) | Seal beat data · `threat_enabled` (`:625`) · melee/telegraph split (`:8`) · **THE SEAL REWORK (`BOSS-PLAN.md` S2–S5 — supersedes Seal-pillar)** · aura-add · Trial-Ladder Versions | The whole boss wave edits this. Serialize claims; each shifts fight checksums **on purpose**. ⚠ `wow-descent-map` owns it live — SEAL REWORK content lands only after that merge. |
| `game/draft.gd` (+ `draft_sim`) | Rarity tier-roll engine · rerolls-out/REGENERATE · loot two-modes · curse cards→JAILBREAK deals · spells reweight · curio-pool v2 · EASE dial knob-roll · Market stock + shared bank (§I) | One draft/roll pipeline. Serialize claims; keep `draft_sim` green each merge. |
| **map layer**: `game/run_map.gd` · `game/map_content.gd` · `game/campaign_core.gd` · `sim/raid_map_sim.gd` | **THE DESCENT REBUILD (§I)**: 4-floor inputs · new node kinds (MARKET/JAILBREAK/CAPTCHA/BENCHMARK/SERVER ROOM/PATCH BAY/WILD) · GATE retirement · ticket shapes/re-price · seed-from-run-seed | **ONE deliberate re-baseline bang** (§I header). Land AFTER `purge-oldgame`. New kinds touch `to_dict`/`from_dict`/fingerprint/server-broadcast together; walker + `CampaignCore.ticket_at` move together (divergence trap). |
| `net/net_server.gd` (798) · `net/raid_net.gd` (220) | Online `(seed,spec)` spec-carry · Depth `spec.depth` · §4 MMO extraction | Versioned protocol — rebuild+redeploy coupled. **Class registry (P4) gates spec-carry of arbitrary builds.** |
| world save `rift_world.cfg` + Atlas screens | Unlock Tree · TICKETS v2 · Zone-Remembers · W3 front-door · W4 write-back | Interlocked — all serialize state onto one save + one Atlas UI. **Unlock System is the spine.** |
| `core/boss_state.gd` (61) · `core/combat_state.gd` (73) · `data/tuning_config.gd` (70) | Threat state + master flags (`threat_enabled`, tuning) | The tank/aggro rework edits all three together. |
| `core/class_kit.gd` (101) · `data/class_codex.gd` (402) | New kit hooks per reworked class · per-class doc strings (stale "SPACE/F") | Every class rework touches both. |
| `data/bulwark/bulwark_kit.gd` (473) | Old `Challenge` taunt (aggro) **+** two-verb dodge **+** being replaced by the new tank | **Highest per-file collision — but moot: retire it with the tank wave, don't invest.** |

### The deliberate-rebaseline cluster ⚠

These intentionally **change fight checksums** (byte-identical A/B does NOT apply — they alter
behavior on purpose). Sequence them so the sim baseline resets **as few times as possible**,
and re-pin `ab-gate.sh` baselines right after each:

- Generic boss-vulnerability stack (REFIT-P4) — then TEAM-COMP + Depth + Well-glint ride it (one reset, not three).
- FLOW=AGGRO rewire (tank wave) — **now also deletes the taunt button outright (`BOSS-PLAN §1`, 2026-07-10)**.
- ~~Seal Pillar Pass v1 (dodge-ration nudge)~~ → **THE SEAL REWORK (`BOSS-PLAN.md` §8, 2026-07-10)** — one bang per Seal slice S2–S5, untouched Seals byte-identical per slice; S0 instrumentation is byte-identical.
- **THE DESCENT REBUILD map bang (§I)** — floors/quotas/kinds/seeding in ONE `raid_map_sim` re-baseline (post-purge).

### Stale / superseded code to RETIRE (not just add-around)

| Old code | Where | Replaced by |
|---|---|---|
| Threat / aggro / taunt system | `threat_enabled` gate (`combat_state.gd:43`, default off) → `combat_core` (44) · `boss_state.gd:57-61` · `tuning_config.gd:56` · `bulwark_kit` Challenge · `raid_hud` T-CHALLENGE (25) · `raid_sim` (17) | **FLOW=AGGRO** (tank wave) — largest single collision surface. **⚠ 07-10: taunt = FULL DELETE (no repurpose — `CombatCore.taunt()`/`taunt_seat_i` die; aggro 100% passive, `BOSS-PLAN §1`); `BossState.threat`/`_threat_target()` survive re-sourced; THREAT_DROP re-bases as FLOW DUMP.** |
| Two-verb dodge (SPACE+F) | `combat_core.gd:83-114` elif · stale "SPACE/F" in `class_codex` + `raid_hud:2414` hint | **dodge-unify** — done for twinfang/alch/well; owed for bulwark*/mender/bloomweaver/reckoner/voidcaller, per rework |
| Voidcaller (full class, wired) | `data/voidcaller/*` + `raid_hud` (15) + run_state/draft/gauge | ~~frozen until interrupt-by-ability~~ → **DELETED NOW (THE PURGE 2026-07-10, §A½)** — Mender + Reckoner + solo bosses/gates go with it |
| `verdance_gauge.gd:19-20` DEPRECATED compat vars | Bloomweaver gauge | Dead surface — delete on next Bloomweaver touch |

\* Bulwark's dodge migration is **moot** — the whole kit is being replaced by the new tank.

### Doc-drift to reconcile (found during this audit)

- **MASTER §SYSTEMS-E (line ~670):** calls GEAR-2 "the open follow-up" — but GEAR-2 **merged** (`gear2`). Real open = **GEAR-3 (Market)**.
- **MASTER OVERALL PROGRESS (line ~27):** lists the pre-rework roster as "✅ playable + verified" — stale framing in the rework era.
- **MASTER §GRAPHICS:** "Wire the other 4 HUDs to CombatStage3D" — **dead** (4 solo HUDs + `stage3d/` deleted in REFIT P1).
- **Twinfang "Through-Line":** merge banner (`67f5efc`) says built; card annotations (TEMPO A1/A6) say "design owed." **Treat as unbuilt** until reconciled.
- **Well "Reservoir rework" (MENDER §8.4):** listed open, but deck banner shows it built (re-homed SPILL→SURGE). Stale open item.
- **Well DECK:** **built in code** (`well-deck`, `500334f`) — but `CARD-CATALOG` shows it "not authored," meaning *not back-filled into the catalog format*, **not** un-built. Clarify in CARD-CATALOG.

---

## 1. THE DEPENDENCY SPINE (what unblocks what)

Not a mandate — Bill picks slices (thinnest-flagged-first, feel-verdict before breadth). This is
the **prerequisite logic** so any slice you pick, you know what must land under it.

**Wave 0 — RAILS FIRST (de-risk the whole content wave; mostly REFIT-P4).** These are the
build-once seams that five separate class reworks and the endgame all need:
- Generic boss-vulnerability stack · Class registry (`class_id→factory`) · Save unification (one Profile incl. roster) + reproducible offline `run_seed` · ClassBand registry + shared Gauge base · Rarity tier-roll engine (`draft.gd`) · Topology elite-node type (keystones) · Online `(seed,spec)` spec-carry.

**Wave 1 — TANK + AGGRO** (co-dependent — flow has no driver without the tank minigame; aggro rewires the tank's threat source): FLOW=AGGRO + Duelist base kit together → sims + HUD → Duelist deck (after §3 verdict) → Warden → per-Seal streams + tank interrupt flag. *Retire old taunt + Bulwark here.*

**Wave 2 — CLASS RESHAPE (Phase 2)** — cheap once Wave 0 exists: signature CD per class · 3-axis filing · branches · owed HUD gauges (on the shared base) · buff-channel application · dodge migration per class · interrupt-by-ability class-by-class (Tempo first). Finish Cask 2–5, Twinfang owed + 2nd spec, Fermata recode, Well gauges/AI/balance; back-fill CARD-CATALOG as you go. **⚠ 07-10: the ABILITY-LAW allowance tightened +2→+1 (ceiling 6, DECK-LAYOUT §5) — every reshape's button math re-runs; Alchemist's catalyst + 3 spells now compete for ONE slot; freshness beyond it = ABILITY TRANSFORMS (Tempo pilots, TEMPO §17.11).**

**Wave 3 — WORLD / META** (`rift_world.cfg` + Atlas): Unlock System (spine) → W3 doors + front-door flip → GEAR-3 Market (the token sink) → rerolls-out → TICKETS v2 / Zone-Remembers / Risk Fork / Quest Board / RESTED / curio-pool v2 / actives socket → W4 living world.

**Wave 4 — DEPTH & TEETH** (`draft.gd` + map + Depth): CONTEST · loot two-modes · curse cards · spells pilot · event-crafting → Trial Ladder (proves scaling hooks) → RAID DEPTH (rides Trial Ladder + vuln stack) → Endless (a *door* on Depth, don't fork).

**Wave 5 — BOSSES & ENDGAME:** **THE SEAL REWORK (`BOSS-PLAN.md` — supersedes Seal Pillar Pass v1; S0 sim-side now, content S2–S5 after descent-map + Wave-1)** · aura-add second-cast-source (still parked — BOSS-PLAN v1 needs no 2nd telegraph source) · TEAM-COMP schools (rides vuln stack). *Boss-redo era for the 15 solo bosses is on HOLD — don't redesign now.*

**Wave 6 — MMO SHELL:** Gateway / InstanceHost / CampaignEngine — only after P4 rails.

**Cross-cutting, land anytime:** Kill-Switch P3 · MAP-2 depth · code-audit findings · tooling loose ends · graphics re-rig.

---

## 2. THE SLATE — by workstream

### A. Combat-engine cross-cutting (the shared seams)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| Generic boss-vulnerability stack | 🔨 `855ac2f` | REFIT-P4 | `CombatCore.add_vuln/vuln_mult` · `boss_state.vulns` · Well glint migrated · dead boss-level expose retired | BUILT — rebaseline landed (twinfang/alch ab-gates byte-identical; well/raid shifted on purpose). TEAM-COMP + Depth fold slots ready; `vuln_probe` guards. |
| TEAM-COMP damage-schools | 🔒 | MASTER §OPEN-IDEAS | `damage_boss` amp, `ClassKit.school_of`, `EncounterRes` profiles, HUD pops | Rides vuln stack. Parked behind Commander per Bill. Byte-identical when profile empty. |
| Interrupt-by-ability pillar | 🔒 | WORLD §PILLARS #3 | `AbilityRes.interrupts` flag, tight window, sim diag, HUD rune | Lands class-by-class w/ reworks (Tempo first). Replaces cut Voidcaller kick. Open Q: which Tempo ability carries — **proposal 🟡 at Bill (TEMPO §17.10, 07-10): Evis = standard carrier (dump tax), Coup = premium kick.** |
| Aura-add / 2nd cast source | 🔴 | MASTER §BOSSES | engine 2nd telegraph source | Blocks R3 raid content; also eases the one-telegraph interrupt problem. |

### A½. THE OLD-GAME PURGE (2026-07-10 — Bill; MASTER §GAME SHAPE amendment)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| **THE PURGE** — delete Voidcaller · Mender · Reckoner + the 15 solo bosses + the GATE node kind; defaults flip caster→Alchemist(brew) · healer→Well(brim) | 🔨 **MERGED `0582294`** (2026-07-10; protocol v13; full verify surface green; bands re-baselined — WORLD-PLAN §Length-bands) | MASTER §GAME SHAPE 07-10 amendment | `data/{voidcaller,mender,reckoner}/*` · `data/raid/gate_content.gd` · `run_map`/`map_content`/`map_screen`/`raid_hud` gate flow · `class_codex` · `raid_content` seat factories+defaults · `net_server`/`raid_net` (protocol bump) · policies/binds/gauges/rigs · `draft`/`armor_slots` · sims (`raid_sim` defaults · `raid_map_sim` re-baseline · `raid_healer_probe`/`raid_reckoner_probe`) · `verify-all.sh` | **Deliberate re-baseline** (maps regen w/o gates; comp flips; **NO-KICKER interim** until pillar #3). Keeps Twinfang Warden/Executioner as `twinfang_sim` training dummies only. ⚠ Collides with live `cask-policy` + `tempo-pilot` worktrees — merge main often. |
| **Bulwark deletion** (the last fossil) | 🔒 | MASTER §GAME SHAPE 07-10 | `data/bulwark/*` · `raid_tank_policy` · `raid_hud` tank band · the old threat/taunt surface | **Dies in the SAME merge that ships the Duelist base kit (Wave 1) — never before**: it is the only tank in code. Supersedes "retire with the tank wave" phrasing in §0 (now a hard rule). |
| Gate-sourced + dead-class GEAR rows re-home/cut | ⏳ | GEAR-CATALOG banner 07-10 | `game/gear.gd` tables · `gear_probe` | Per class-rework deck (CARD-TRACKING LAW). `gear_probe` re-scopes at the purge merge. |

### B. Tank rework + FLOW=AGGRO (Wave 1 — co-dependent) · ⚒ build brief: `DUELIST-BRIEF.md` (2026-07-10 — slices S0–S8; S0–S4 verdict-free, S5–S7 gate on Bill's §3 board + §10.6)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| FLOW=AGGRO universal rewire | 🔒 | TANK §1c/1d | built threat engine (source damage→flow), seeded peel roll, `raid_content.gd:8` | Numbers→playtest. Revises "aggro=raid-only" (`b2afbca`) → universal. Rips out `threat_enabled` system. |
| Duelist guarded base kit | 🔒 | TANK §4 + **brief S1** | new `data/duelist/*`, bespoke PARRY+DODGE (no `unified_dodge`/ration) | Numbers→playtest. **Verdict-free (base carries no cards — brief §0; the board gate moved to the deck slices S5–S7).** A/B on-branch; Bulwark dies at the same merge (§A½). |
| Peel mechanics (progressive + grace-delay) | 🔒 | TANK §1c **+ BOSS-PLAN §1** | aggro-% shape, victim dodge bar, ~~TAUNT hard-override~~ **NO TAUNT (07-10)** — valve = perfect-MAIN flow spike + THE GAZE boon lane | Part of FLOW=AGGRO. Grace-delay = the VICTIM'S window only (det-safe fixed tick offset). |
| Tank defensive signature CD ("the wall") | 🟡 | TANK §1b, **§10.2 (designed 2026-07-10)**, DECK-LAYOUT §5 | new ~1-min CD, carries dropped GUARD | **Duelist's is DESIGNED: ⏱ EN GARDE** (invite +25% melee tempo · leaks halved · double flow · perfect-MAIN ◆◆ · 2 slips break it; amplifier never override — the post-taunt clutch question at Bill). Warden keeps THE GATE (§8.6). |
| Duelist deck v1 **+ v2 revision (D2, 2026-07-10)** | 🟡 | TANK §3 + **§9**, CARD-CATALOG | kit-local layers, `_fw()` dispatch (Well idiom) | **Whole slate at Bill's board** — §9 adds the v1.1 reconcile (EASE fold executed · FLOW = 4th Floor-1 candidate · Hold-the-Line→FLOW re-key) + 3 challenger SWAP KITS pre-authored (any pick = ready deck). GUARD trio resolved → Warden §8. Estocada/Reckoning-Stroke freeze-beat rhyme at Bill. |
| **Duelist — ABILITY PASS (3 transforms + doors, TEMPO-§17.11 treatment)** | 🟡 | **TANK §10** (2026-07-10) + CARD-CATALOG | kit-local — same touch set as the deck (transform layer on the kit reducer; seize hold-state + flèche load timer; Floor-2 ceremony offer) | **PRISE DE FER** (parry seize/throw) · **REMISE** (prime/commit two-press) · **FLÈCHE** (dump loads onto next perfect answer), each a DOOR w/ 2 sub-boons + 1 rig WHEN; +1 slot EMPTY (4 of 6 targets). Dancer runs exclude the parry transforms from the offer. **Acquisition pattern LOCKED by the Tempo GO 07-10 (Floor-2 1-of-3 ceremony)** — cards still 🟡 (§10.6). Brief S7. |
| FLOW module (aggro→damage upgrade) | 💡 | TANK §1b | new STRAT module | Competes for Floor-1 module slot. Reconcile at deck reshape. |
| Duelist sims + carry | 🔒 | TANK §4.4 | new `duelist_sim`, `raid_sim --tank=` | After base + deck. |
| Duelist HUD slice | 🔒 | TANK §4.5 | `raid_hud` timing instrument, own FLOW bar, shared aggro box | WSLg screenshot (headless can't `_draw`). Non-tanks get no flow bar. |
| Warden spec (base + deck) | 🟡 | TANK §5 + **§8 DECK v1 (D1, 2026-07-10)** | new — BLOCK/SHIELD/SHIELD-SLAM, no dodge | Base locked; **deck NOW AUTHORED 🟡** (Payload·Slam·Rampart; 🔮 guard trio re-homed; MONOLITH wild creed; THE GATE CD shape). Build still waits for the Duelist frame (Wave-1 order). CARD-CATALOG rows landed. |
| **Warden — BRANCH SLATE (5 themes)** | 🟡 | TANK §6 + `research/warden-sweep.md` | design only (deck pass = Phase-2 row D1) | Payload · Slam · Rampart · Bannerman · Thornback — Bill picks 2–3. Absorbs the 🔮 guard trio + carries (filing table). Bannerman flags the buff-channel debt. |
| **Duelist — CHALLENGER SLATE (3 vs the v1 ladders)** | 🟡 | TANK §7 + `research/duelist-sweep.md` | design only (deck revision = Phase-2 row D2) | Matador · Stormweave · Scarlet Trade join the SAME §3 verdict board as deck v1 (incumbents = PITCH #0a/b/c); Bill picks 2–3 ladders total. 1 kill (Planted Blade — collision), ~8 fixes. |
| Tank per-Seal streams + interrupt flag + spec-carry | ⏳ | TANK §4.6 | encounter data per Seal | Ship with build, not deck. Interrupt flag with the pillar-#3 pass. |
| **Bloomweaver — CLASS SLATE (4 core candidates)** | 🟡 | `BLOOM-PLAN.md` (NEW) + `research/bloom-sweep.md` | design only — winning core later builds as a guarded class (Well pattern) + deck (Phase-2 row D3) | Orchard Clock · Trellis · Briar · Pruning, 2 spec seeds each; Bill picks ONE core. Do-not-merge (07-06) honored; Trellis HUD lift + Pruning rule-4 death-clause flagged. |
| **Bloomweaver — ORCHARD CLOCK DECK v0 (D3)** | 🟡 | BLOOM §4 + CARD-CATALOG section | design only — PROVISIONAL on core A (core pick B/C/D = free re-run); build waits on core pick + feel tester | 4 creeds (WILD ROWS) · Almanac (⚠ the roster's first forward-timeline gauge — HUD cost flagged) · Cider Press · 11 boons · Full Bloom/Orchard Eternal keystones · THE SEASON CD · Harvest Home support. Orchard-Eternal ends on WILT (hits-taken pricing avoided). |

### C. Class reshape (Phase 2) + shared class substrate

**Shared substrate — build ONCE, unblocks many classes:**

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| Rarity tier-roll engine (H/S/O + runes) | 🔒 | TEMPO App-A, ALCH v3, CASK §7.4, FERMATA §7 | `game/draft.gd`, per-class boons, runes | **DESIGNED-NOT-BUILT.** Blocks real rarity for Tempo/Fermata/Brew/Cask/Well *simultaneously*. |
| Topology elite-node type (keystone acquisition) | ⏳ | TEMPO A8, FERMATA §13.6, CASK §7.6 + **DESCENT §5** | new map node + 1-of-2 keystone reward | Blocks ALL keystone acquisition across classes. **Design settled in DESCENT (elective, pay-printed, post-purge drop-roll site; elective-vs-mandatory = DESCENT V#3) — build with §I.** |
| raid_hud gauge/meter render pass | ⏳ | TEMPO/FERMATA/MENDER/CASK | `raid_hud` + per-class gauges | Do it on the **shared Gauge base** (P4). WSLg render. |
| Online `(seed,spec)` spec-carry | ⏳ | TEMPO §13.7, ALCH §6, MENDER | `raid_net.gd` | One debt for all reworked classes. Class registry (P4) precondition for arbitrary builds. |
| Raid buff-channel application | ⏳ | TEMPO App-A, FERMATA §7 | raid buff channel | Battle Hymn + Veil Warband + Cask "Round for the House". Debilitator/Shining Hour = precedent. |
| DECK-LAYOUT Phase 2 program | 🔒 | DECK-LAYOUT §7 | every `data/<class>/*.gd` + CARD-CATALOG | Program locked; per-class feel-verdicts open (CD shape, 2-vs-3 branches, keystone generic-vs-category). **2026-07-09: modules = add-ons, transformer requirement DROPPED (no ⭐-transformer owed per class); reshape deepens pools via sub-specs/branches, not flat boons (EASE dial handles de-bloat). ABILITY LAW locked (§5): 7-touch-target ceiling (Well 8) — see the compliance-trim row below.** |
| ABILITY-LAW compliance trims (Alch bar · Well book) | 🔒 | DECK-LAYOUT §5 | `alchemist_boons.gd` `SPELL_CAP`/bar · `well_boons.gd` book+cap · mobile layouts | At each class's reshape, not before. Fully-drafted Brew = 9 targets w/ CD (catalyst button + 3 spells compete for the 2 allowance slots); Well loaded = 10 vs its 8 — **now 11 with SKIN (MENDER §13, 2026-07-10); trim explicitly PARKED per Bill ("don't worry bout 8 cap"), stays this row's job**. Retune per-class `SPELL_CAP` to what the ceiling leaves free. |
| Signature CD per class (baseline) | 🔒 | DECK-LAYOUT §5 | new baseline button per class | Schema locked; per-class shapes open. Amplify skill, never button=damage. |
| EASE difficulty-dial (rolled comfort↔bite knob) | 🔒 | DECK-LAYOUT §4 | `draft.gd` knob-roll · per-class minigame knobs (window/speed/grace) · `raid_hud` dial card-face | Replaces flat comfort boons pool-wide (built per-class at reshape). **Rides the rarity tier-roll engine** (bite +dmg is rarity-scaled). **Same knobs Depth/Seal-pillar compress from the boss side — coordinate the caps** (two writers). Tank folds Quick Wrists/Roll With It in. |
| CARD-CATALOG back-fill (stub classes) | ⏳ | CARD-CATALOG | doc only | Tank fully populated; Twinfang/Alchemist/Well/Mender/frozen = stubs. `dump-cards.sh` deferred. |

**Per-class reshape work:**

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| **ALL-CLASS BRANCH SLATES — THE SLATE MACHINE (queue of 8)** | ✅ **COMPLETE 2026-07-10** — all 9 slates landed 🟡 | SLATE-PLAN §0–§4 | design only — 9 slate §§ + 8 `research/*-sweep.md` files + NEW `BLOOM-PLAN.md` | Tempo(redone) · Warden · Duelist · Bloomweaver(class) · Cask · Brim · Draw · Brew · Fermata — every slate at Bill's board with skeptic records + filing tables. Crons retired; the `/slate-loop` skill remains for any future re-run. |
| **PHASE 2 — THE DECK MACHINE (9 full decks, design only)** | ✅ **COMPLETE 2026-07-10** — all 9 rows landed 🟡 | SLATE-PLAN §5–§6 | design only — every deck § + CARD-CATALOG rows landed | D0 Tempo v3 · D1 Warden v1 · D2 Duelist v2 (reconcile+swap kits) · D3 Bloomweaver v0 (core-A provisional) · D4 Cask assembly · D5 Brim reshape · D6 Draw reshape (Millrace demote) · D7 Brew merged board · D8 Fermata v6. Cross-deck distinctness ledger complete (9 rows); catalog back-fills closed (Cask/Brew/Well/Fermata). **What remains = Bill's verdicts → build claims.** |
| **Twinfang·Tempo — deck rebuild: BRANCH-THEME SLATE (6 themes)** | 🟡 | TEMPO §14 (corrected) + `research/` | design only this pass (deck pass later: `data/twinfang/*` · `draft.gd` EASE knobs) | **REDONE 2026-07-10 under the corrected branch=THEME definition (Bill)** — base minigame untouched; themes: Wound · Finish · Swift · Edge · Punish · Band. Bill picks 2–3 → deck pass files old+new cards into the winners. The six rewire pitches → TEMPO §15 parking 🔮 (future spec/aspect ideas; Coup-as-interrupt + CD-shape notes stay live inputs to §3 verdicts). |
| Twinfang — Through-Line + On the Beat cards | 🟡 | TEMPO §17.3 | `twinfang_boons.gd` | **FOLDED into DECK v3 (D0):** Through-Line AUTHORED (drift closed); On the Beat = 🟡 candidate in SWIFT's lane. |
| **Twinfang·Tempo — DECK v4 (Phase-2 D0)** | ✅ **GO** (07-10 — build per `TEMPO-D0-BRIEF.md`: S0→S5→S1→S2→S4; S3 duos + S6 Set Piece DEFERRED) | TEMPO §17 (+§17.12 GO record) + CARD-CATALOG rows + `TEMPO-D0-BRIEF.md` | build touches `data/twinfang/*` (config/kit/boons/modules/rig) · `draft.gd` (theme tags · door/duo offer-gating · EASE roll) · `raid_hud` (Floor-2 transform ceremony · build-panel chip) · elite offers | Full deck around **Wound · Swift · Finish** (Bill's archetypes; ✅ picks swap cheap): 2 new creeds (Uptempo · Open Veins) · Hemorrhage module · 6 new boons · 2 keystones (Coda · Exsanguinate, engine-free) · Deep Cash WHEN · **THE SET PIECE signature CD** (the §5 slot's first shape) · EASE knob list · trim table (4 parks proposed) + 7 tension points. Coherence gates + 3 skeptics run in-doc. **+ 07-10 ABILITY AUDIT (TEMPO §17.10, Bill's pass):** 4 spell candidates for the ABILITY-LAW +2 slots (Sforzando · Rondo · Count-In · Pickup) · abilities-as-DOORS gating law (gated boons + ability rig WHENs) · RESONANCE/DUO over stat set-bonuses · **SPEED GOVERNOR** (`beat_rate_cap`/`window_min` on `twinfang_config`, all sources asymptotic) + **Double Time v2 ghost notes** (v1 beat-doubling cut at the 30 Hz wall) · Evis/Coup kick-carrier proposal → 5 new verdict points at Bill. **+ PASS 2 (TEMPO §17.11, Bill's steer same day):** spells REJECTED ("not great / button bloat") → **ABILITY TRANSFORMS** (Cadenza · Rondo · Tremolo — rewrite Coup/Evis, ≤1/run, each a door; Floor-2 ceremony lean) · **ABILITY LAW tightened +2→+1, ceiling 6** (DECK-LAYOUT §5 amended — Alchemist reshape trims to ONE slot) · Tempo's +1 slot left EMPTY (Count-In parked) · **v4 branch proposal: SWIFT → generics/EASE, THE EDGE in** (Whetstone creed + The Strop module new; Double Time v2 re-slots class-generic). 5 v2 verdict points. **+ PASS 3 (TEMPO §17.12, Bill's artifact notes 07-10): GOVERNOR ✅ · RESONANCE ✅ · DUO ✅ ("make this rich") → 4-duo slate 🟡 (bloodCoda·redEdge·grandFinale·reprise, ≥2-from-each-theme arming) · NO-SINGLE-NEXT-HIT LAW (fencersLine REWORK 🟡 · killingEdge fallback → 3-strike) · Grand Pause reworded · ⚒ BUILD BRIEF ON MAIN `TEMPO-D0-BRIEF.md` (slices S0 governor → S5 laws → S1 deck data → S2 resonance → S3 duos → S4 transforms · S6 Set Piece deferrable). S0+S5 buildable NOW; gates: ① v4 lock ② trim ③ transform trio.** |
| Twinfang — 2nd rhythm-variant spec (FERMATA) | 🔨 `f5d5397` | TEMPO §13, FERMATA-BRIEF | fermata kit + slate | Built & merged (verb + deck v5). Stale "design owed" corrected 2026-07-09; residual wiring on the row below. |
| Twinfang — Creed/Module wire TODO + killingEdge rig | 🔒 | `twinfang_content.gd:163` | twinfang kit | Only real actionable code TODO in repo. |
| Fermata v5 — owed wiring (HUD meters · elite acq · spec-carry) | ⏳ | FERMATA-BRIEF | shared passes (gauges/elite/`raid_net`) | Verb + slate BUILT (`f5d5397`, grades by depth — stale "recode owed" corrected 2026-07-09); what remains rides the shared substrate rows above. |
| **Fermata — CHALLENGER SLATE (filing + 2 additive themes)** | 🟡 | TEMPO §16 + `research/fermata-sweep.md` | design only (deck revision = Phase-2 row D8) | v5 ladders named (Brinkman · Rested Blade · Window-Setter); additive: Afterimage (echo — coded Twin Echo/Phantom anchors) · Cold Hand (Good-band CP + branded Evis — the Brinkman polarity). 3 kills (all law-violations — no v5-cut resurrections), ~5 fixes. **PHASE 1 OF THE SLATE MACHINE DRAINED.** |
| Alchemist — Cask slices 2–5 | 🔒 | ALCH §7.7 | `AlchemistPolicy` + HUD + `data/alchemist` + `alchemist_sim` | Slice 1 built. Slate verdicted 24/6. Tune `cask_base`→Seal parity. |
| **Cask — BRANCH SLATE (filing + 3 additive themes)** | 🟡 | ALCH §9 + `research/cask-sweep.md` | design only (deck pass = Phase-2 row D4) | Locked pool filed (Blend Line · Gauntlet · Tap List); additive: Twin Casks (homes parked Double Barrel) · House Recipe · Taproom (buff-channel debt). §7 verdicts NOT re-opened. Storm Brewer killed pending F3. |
| **Cask — DECK ASSEMBLY (D4)** | ✅/🟡 | ALCH §11 + CARD-CATALOG Cask section | design only — slices 3–5 (§7.7) now have the complete card list | Locked slate hard-copied to catalog at ✅ (24 cards — back-fill drift closed); kits T/H/R at 🟡 (CLOSING TIME renamed — Brew Last-Call collision); EASE knobs listed; Solera×Recipe tune flag. |
| **Brew — BRANCH SLATE (filing + 3 additive themes)** | 🟡 | ALCH §10 + `research/brew-sweep.md` | design only (deck pass = Phase-2 row D7) | Live pool filed (Slow Boil · Cannonade · Anchor); additive: Tightrope (low-catch wobble greed) · Sidearm (dart weave; kick cards parked on the pillar-#3 flag) · Prognosis (fight-arc, HP-milestone based). §8's 11 slot into the ladders. 1 kill (Flash Boil), ~7 fixes. |
| **Brew — DECK ASSEMBLY (D7)** | 🔨/🟡 | ALCH §12 + CARD-CATALOG Brew section | design only — build = the planned `brew-review` slice + picked kits | ONE merged board: built pool 🔨 (back-fill drift closed for the Brew) · §8's 11 slotted 🟡 · kits G/P/S 🟡 (Silencer/Fusillade ⏸ pillar-parked) · **keystone-pool math flagged** (6 candidates; cap-5 theme-weighted proposed) · Cask Practiced-Hands→MUSCLE MEMORY rename. |
| Alchemist — Brew review pass (11 proposals) | 🟡 | ALCH §8 | one guarded slice, config knobs | Live deck untouched until verdict. |
| Alchemist — open design calls F1/F2/F3/F20 | 🟡 | ALCH §OPEN | design; F3 would touch dodge/ClassKit | F3 (auto-evasion) gates Cask under-fire risk. |
| Well — module gauges + AI spell-policy | ⏳ | MENDER | `well_gauge.gd`, `well_policy.gd` | Deck already built. AI can't use Meditate/Boiling Over yet. **`WELL-DRAW-BRIEF.md` S4 offers the fold-in.** |
| **Brim — BRANCH SLATE (filing + 4 themes)** | 🟡 | MENDER §9 + `research/brim-sweep.md` | design only (deck reshape = Phase-2 row D5) | Low Catch (Brink-anchored) · Overflow Engine (⭐Reservoir) · Glintsmith (TEAM — Glint ladder + Shining Hour + blindfold) · THE PULSE (pulse rhythm; renamed from "Deep Well" — built boon name collision, §10.7). 1 kill (Surgeon), ~7 fixes; distinctness vs Payload/Taproom/Bannerman recorded. |
| **Brim — DECK RESHAPE (D5)** | 🟡 | MENDER §11 + CARD-CATALOG Well section | design only — new cards are kit-local boons on built `_fw()` wiring | Built pool filed 🔨 to catalog (back-fill drift CLOSED for shared+Brim); 6 new cards + Undertow/Floodgate/Gilded Hour keystones 🟡; Wide Brim→EASE fold; Blind Pour killed (built-Blindfold dupe) · Cool Head rename (Brew P8 collision). |
| **Draw — BRANCH SLATE (filing + 4 themes + built-pool addendum)** | 🟡 | MENDER §10 + `research/draw-sweep.md` | design only (deck reshape = Phase-2 row D6) | Rapids (Current ladder — ⚠ Millrace vs pitched Flume: one capstone absorbs the other) · Vigil (held heals, transformer promoted) · Skim (priced quick-sips, anti-Current pole) · Eddy (drift reads). §10.7 files ALL 24 built boons (corrects both filing tables). 1 kill (Whirlpool), ~6 fixes. |
| **Draw — DECK RESHAPE (D6)** | 🟡 | MENDER §12 + CARD-CATALOG Draw rows · **⚒ build brief: `WELL-DRAW-BRIEF.md` (2026-07-10, slices S1–S2 + S4)** | design only — ⭐Vigil module = the one real kit addition; rest boon-local | Vigil·Rapids·Eddy; **MILLRACE DEMOTE proposal** (built keystone → boon; THE FLUME crowned — the §10.7 reconcile resolved at Bill); Ride-the-Tremble rename (Warden collision); unfiled-built-boons effect-filing owed at build. Brief §0 defaults = the doc leans; Bill starting the build = GO. |
| **Draw — ABILITY PASS (SKIN + 3 cast transforms, TEMPO-§17.11 treatment)** | 🟡 | **MENDER §13** (2026-07-10) + CARD-CATALOG Draw rows · **⚒ build brief: `WELL-DRAW-BRIEF.md` (2026-07-10, slices S0 + S3)** | `data/well/*` (one new cast + per-seat defer buffer in the reducer, guarded) · `well_binds`/`well_gauge` (skin cast + film read) · transform layer on the built release machinery | **SKIN** (the missing-heal film — defers a share of each hit into a ~3s drip; never absorbs/heals; Bill's playtest gap) · **CUPPED HAND** (Flash from the Current, instant/ungraded) · **DEEP DRAW** (Mend's second band, gutter past it) · **THE BRAID** (Cascade as a 3-release string), each a DOOR w/ 2 sub-boons + 1 rig WHEN. Well loaded-count 10→11 — **the 8-cap trim stays PARKED per Bill** (rides the compliance-trims row). ⚠ S3 transforms WAIT on the `wow-tempo-d0` merge (reuse its Floor-2 ceremony + door offer-gating). |
| Well — Glint 3-tier ladder + tuning | 🟡 | MENDER §8 | `data/well/*` knobs | Built as 2-tier; full Good/Perfect/Bullseye at verdict. |
| Well — balance at real fightlen bands | ⏳ | MENDER | `well_sim`, `raid_sim --healer` | Run at 3–5min/~10min, not 60–142s — closes the inert-healer finding. |
| Dodge-unify migration (frozen classes) | ⏳ | DODGE-PLAN | `ClassKit.unified_dodge()`, drop F | **Bloomweaver only after THE PURGE** (Voidcaller/Mender/Reckoner deleted 2026-07-10; Bulwark moot — dies with Duelist). |
| Commander AI-caster toggle | ⏳ | ALCH §6 | Commander party screen | Brew + Cask. |
| Class names + puppets/art | ⏳ | ALCH/MENDER | class puppet art (voidcaller rig filler) | Filler-grade. Names are working titles. |

### D. Overworld / progression / meta (`rift_world.cfg` + Atlas)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| THE SETTING — world fiction + NAMING pass | 🟡 | THEME-PLAN §1–4 | display strings only: rarity labels (`draft.gd` display layer), door-dial name, tooltip nouns, armory renames, Bastion/ticket flavor | Riff v0 at Bill's 7-dial board (THEME §6). Rename via display fields NEVER ids — sims byte-identical (MASTER §REALMS bar). Reverses the global haiku/sonnet/opus wink → Realm-1-local. Fiction dressing rides W2 quest board. |
| THE UNLOCK SYSTEM (tree + one XP meter) | 🔒 | PROGRESSION §UNLOCK | world save, tree UI, per-surface stacks, crest gates | **The meta spine.** Supersedes §LEVELS. Big interlocked build (W2/W3). |
| W3 — doors + front-door flip (PLAY→ATLAS) | 🔒 | WORLD §PHASES | Dungeon 1, Versions dial, raid door, route attunement | Amends GAME SHAPE. Removes old realm-card flow. |
| W4 — living world (online) | 🔒 | WORLD §PHASES | co-op traversal, presence rooms, world-event scheduler, Vorathek world boss | Additive protocol (combat frames untouched). Mid-fight join stays parked. |
| W5 — breadth + retune | 🔒 | WORLD §PHASES | Zone 2 + Dungeon 2, interrupt retune, dodge-ration audit | Later phase. |
| TICKETS v2 (ROUTE/DEED/DOOR/EVENT) | 🔒 | WORLD §QUESTS | world save; reuse ESCORT tech + oath detectors | ESCORT built. EVENT needs W4. Rewards = access/pool/standing, never stats. |
| ELITE nodes = mutator fights | 🔒 | WORLD §ELITE | Forge affix knobs, `forge_sim` | Modifier on enemy side (bare-kit law). |
| THE ZONE REMEMBERS (full flags) | ⏳ | WORLD §ZONE-REMEMBERS | permanent flags on world save | Teaser shipped (W1). Fight-flags enter as `(seed,spec)`. Guest rule needs W4 write-back. |
| Quest Board station (Bastion) | 🔒 | WORLD §MEWGENICS ② | Bastion station | W2. Needs TICKETS v2 grammar. |
| THE RISK FORK | 🔒 | WORLD §MEWGENICS ③ | authored node beat | W2. Needs ELITE mutators. |
| RESTED (real-time XP mult) | 🔒 | TEETH §RESTED | the one XP meter | Multiplies earned XP only, never hands out unlocks. |
| GEAR-3 — Market + extraction | 🔒→🟡 | PROGRESSION §3, GEAR §Rollout | Market node, extraction schematics | **ABSORBED into DESCENT §I** (PROMPT MARKET node + post-Seal phase; schematics at CACHE/SERVER ROOM; ≤1/act-vs-≥1/floor conflict resolved: 1/floor). Build via §I. |
| GEAR-4 — raid personal loot + Seal tables | 🔒 | PROGRESSION §4 | per-seat seeded loot, Ledger pages | Crests/standing need accounts→later. VERSION rows need Trial Ladder. |
| Universal Curio Pool v2 (~18 curios) | 🟡 | GEAR §POOL-v2 | `gear_catalog.gd` | Approved-not-final. Cut 10 welded, keep 6, add 18 cross-spec. |
| CURIO ARMORY v3 — the big slate (~40 rows) | 🟡 | GEAR §ARMORY-v3 | `gear_catalog.gd` (+ per row: BACKUPS §9 · JAILBREAK §7 · BENCHMARK §I · foil/temp-slot micro-mechanics) | At Bill's narrowing verdict (target keep ~15–20). Adds the FEEL BAR (every row names its MOMENT). Additive to v2 pool; obeys v2 hard rules; no G/H actives. |
| Actives socket + paper active items | 🔒 | GEAR §Rollout | 1–2 sockets, G/H keys | Unlocks RELAY BATON/MUTE/ROLLBACK/UNPLUGGING etc. Some gated on Seal page (GEAR-4). |
| Escort/volatile tickets follow-up | ⏳ | WORLD §MEWGENICS ① | burden flavor, lane-law reward | Slice built (`ESCORT_PREVIEW`). Burden flavor needs interrupt pillar. |
| Armor set presentation panel | 💡 | PROGRESSION §ARMORY | `armor_doll.gd` paper-doll | Presentation only; reads existing draft state. |
| Unlock banking rule (win-only checkmark) | ⏳ | PROGRESSION §Drops | `rift_gear.cfg` persistence | First-kill checkmark banks on WIN; oaths bank win-or-lose. |
| E.5 oath drop-dedication | 🔒 | MASTER §SYSTEMS-E.5 | `beneficiary_seat_i` on oath state | Byte-identical self-default. Ties to Depth curation-capacity. |
| Raid wipe budget + floor checkpoint | 🔒 | WORLD §STAKES-MODEL | `RunState`/descent save-resume, `RunDirector`, raid loss-mode | Answers open-Q#6. Numbers→playtest. Needs descent-checkpoint plumbing. Dungeon stays 1-life. **Kept verbatim in DESCENT, re-fictioned BACKUPS (§9) — build with §I.** |
| Attempt tokens (Death-Defiance consumable) | 🔒 | WORLD §STAKES-MODEL | budget counter, Market (GEAR-3), TICKETS node reward, `draft.gd` | +1 attempt, any surface. Token sink — rides the PROMPT MARKET (§I) + the ticket turn-in fork (DESCENT §10). |
| Boon/curio battle-rez layer | 💡 | WORLD §STAKES-MODEL | `gear_catalog`, existing `revive` ClassKit hook | Healer Rekindle already BUILT; extend beyond healer so healer-less comps aren't hard-locked. |

### E. Depth & Teeth (`game/draft.gd` + map + Depth)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| Rerolls-out + Tokens→Market | 🔒 | TEETH §REROLLS | `draft.gd`, ASCENSION-STEAL | Reroll→earned charge; retires LOCK, keeps UPSELL. **Reframe Hot Reload + Hashgrinder curios.** **Lands via DESCENT §I (REGENERATE charges + Market slot 3).** |
| CONTEST primitive (skill-check node) | 🔒→🟡 | TEETH §CONTEST | new node + scoring over `strike_judge.gd` | **Lands via DESCENT §I as BENCHMARK** (scoring rule = DESCENT V#5; co-op + contest modes). Reuses CAPTCHA + lockstep. |
| Loot two-modes (need/greed + AI banter-roll) | 🔒 | TEETH §LOOT | `raid_hud._after_drop` | Reuses rarity+pity roll. Solves AI-gear blocker (AI allies roll & banter). |
| Spells & depth reweight (pilot one class) | 🔒 | TEETH §SPELLS | `type:"spell"` draft weight | Open: which class pilots. NOT a tank spec until tank lands. Folds into next rework. |
| Curse cards (biting blessings) | 🔒→🟡 | TEETH §CURSE | welded-downside boons + poisoned-ability flag | **Lands via DESCENT §I as THE JAILBREAK** (design now exists: §7 bite vocabulary + no-run-long-timing hard rule; magnitudes = DESCENT V#4). |
| Event-crafting (elite→extract→keystone unlock) | 🔒 | TEETH §crafting | event shape, oath-gated unlock | Partially reverses crafting-cut; counter-grind stays cut. |
| Endless door | 🟡 | TEETH §ENDLESS | new Atlas node chaining Depth | **Do NOT fork Depth** — sync with the Depth thread, frame endless as its presentation. |

### F. Endgame & bosses (`raid_content` + `raid_sim` + `TuningConfig`)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| Trial Ladder ("Versions") | 🔴 | MASTER §MODES | `TuningConfig` + strings, version dial on door | Author the mechanic-adds. Proves Depth's scaling hooks. Unlocks VERSION-row gear. |
| RAID DEPTH — infinite endgame | 🔒 | MASTER §MODES | `spec.depth` scalar, affix-intensity knob | Rides Trial Ladder + vuln stack. **Compress windows, never stat-inflate.** No persistent gear power. |
| ~~Seal Pillar Pass v1 (dodge-ration)~~ | ✂️ | SEAL-PILLAR-PLAN | — | **SUPERSEDED 2026-07-10 by THE SEAL REWORK (below)** — never executed; Phase A instrumentation absorbed as its S0. |
| **THE SEAL REWORK v1 (the 4-boss redo)** | 🟡 | **`BOSS-PLAN.md`** (10 verdicts §V) | `raid_content` (all 4 Seals re-authored) · `combat_core`+`boss_state` (E1 gates · E2 stance · E3 BREAK · E5 mark · E6 deny-empower · E7 listening — all guarded) · `encounter_res`+new `SealTune` (E4) · `raid_sim` gates · `raid_hud` (stance sigil · countdown pips · break card · mark fuse) · `tune.sh` flags | Fills DESCENT §4 contract 5/7/9/12 **with structure, never +HP**. **Blocks on: `wow-descent-map` merge + Wave-1 FLOW=AGGRO/Duelist (taunt dies there).** S0 (sim-side, byte-identical) claimable now. One rebaseline bang per Seal slice; untouched Seals byte-identical per slice. ULTRATHINK untouched forever. |
| Boss-redo era (15 solo bosses) | ⏸ HOLD | MASTER §BOSSES | — | Bill unsure of end state — **do NOT redesign now.** Only 4 Seals maintained (and reworked per BOSS-PLAN). |
| ~~OPUS Helpful/Harmless/Honest phases~~ | ✂️ | MASTER §BOSSES | — | **FOLDED into BOSS-PLAN §6 Mythos THREE ACTS (2026-07-10).** |

### G. Infra / REFIT-P4 / server-MMO (`net_server` / `run_director` / `world_shell`)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| REFIT Phase 4 — SCALE RAILS | 🔨 **DONE** (`b17ff52` `855ac2f` `fcee675` `94b1147` `b4e8d26` `ee58124` `784e365` + `4779f59` v14) | REFIT §3 P4 | ~~save unification (+roster) · offline `run_seed` · Split-law guard~~ `b17ff52` · ~~vuln stack~~ `855ac2f` · ~~class registry~~ `fcee675` · ~~ClassKit hoists~~ `94b1147` · ~~ClassBand registry~~ `b4e8d26` (`game/ui/bands/`, raid_hud −630) · ~~shared Gauge base~~ `ee58124` (`class_gauge.gd`, 7 widgets) · ~~TuningConfig literals sweep~~ `784e365` (last 6 engine hard-codes) · twinfang kit split → **DEFERRED INTO the Twinfang rework** (same restructure, avoids conflicting with the class wave) | **Wave-0 rails COMPLETE (2026-07-10, one day).** Class reworks land into band slots + registry rows; net spec-carry unblocked; replay/ghost-races unblocked; TEAM-COMP/Depth fold slots ready. |
| MMO SHELL (§4 server era) | 🔴 | REFIT §4/§5 | Gateway/Session · InstanceHost (extract `_tick_room`+`RaidNet.step`) · server CampaignEngine · Profile store move | After P4. Combat never notices (already `(seed,spec)` pure). Needs a netcode-era plan when claimed. |
| Kill-Switch P3 (live UNPLUG + charge tuning) | ⏳ | MASTER §MAPS | `raid_marks.gd`, gear-picker for sacrifice path | P1/P2 merged (proto v11). Charge economy too generous (walker 40→96%) — needs a probe. |
| MAP-2 depth (ELITE/MARKET/secret/events/art) | ⏳→🟡 | MASTER §MAPS | map content | **SUPERSEDED by DESCENT §I** — ELITE/MARKET/secret-room (SERVER ROOM)/legibility all land there; only the events content pass + map art remain here. |
| Code-audit parked findings (grouped) | ⏳/💡 | MASTER §CODE-AUDIT, REFIT §2 | ~~desync checksum coverage~~ 🔨 `4779f59` (protocol v14 `ih`) · ~~save versioning~~ 🔨 `b17ff52` (Profile aggregate) · `seat.casting`→`target_i` · WASM determinism cert probe · `net_server` hardening · boon×aspect sweep · Esc-teardown leak audit | Several fold into P4/§4 — coordinate, don't double-build. |
| Tooling loose ends (grouped) | ⏳ | MASTER §TOOLING, REFIT P3 | auto-post sim bands · replay files (leaderboards) · CSV home · **7 `screenshot_*` re-hosts onto `world_shell.tscn`** · state-ownership lift off `raid_hud` | Screenshot scripts error loudly until re-hosted. Replay files unlock ghost-races/bounty. |
| SIM-PLAN balance ladder S1–S5 + THE SOAK | 🔴 | **SIM-PLAN.md** (2026-07-10) | per-class policies (creed branches + module verbs) · `sim_util.gd` card-delta harness · `draft.gd`-driven build sampler · raid per-seat meters/ablation · `scripts/soak.sh` + digest | **Triggered, not scheduled:** S1 rides EACH class rework (card-visibility rule) · S3 cheap-anytime · S2 after 2nd creed-aware policy · S5 with tank/aggro rebaseline · S4 per class after DECK-LAYOUT reshape · soak last. No hard balance gates ever (determinism stays the only PASS/FAIL). |
| Graphics — robot re-rig + 2D art pass | 💡/⏳ | MASTER §GRAPHICS | per-boss silhouettes via `Actor2D.make()` factory | Give gauges a shared base + stable obs contract first (P4). Classic-parry-perfect payoff = byte-gate. |
| Twinfang art pass v1 (juice → painted skin → flipbook FX) | 🔨 | MASTER §GRAPHICS (2026-07-10) | `raid_hud` post-fx node (combat region — ⚠ descent-map claim owns the map region, same file) · `screen_post.gdshader` wire · `stage2d/pose_rig_2d` tex limbs + `twinfang_skin_rig_2d` NEW · `raid_stage_2d` hit-stop/smears/lunge · `damage_numbers` styles · `game/art/actors/twinfang/*` NEW | Branch `tempo-art`. View-only, never checksummed (ab-gate raid_sim anyway). Foundation verdict: native skeleton; **Spine Pro = per-actor upgrade door** behind `Actor2D` (same layer cuts rig in later). Art = AI AtO-cel now; THEME re-skin risk accepted. |
| **STATS PAGE v2 — the full post-fight report** | 🔨 `4b58d0b` (2026-07-10) | MASTER §COORD (stats claim) | `combat_core` (`meter_boon`/`_credit_amps`/`credit_boon_factors`/`_note_melee_victim`/`_sample_series` + uncontested-cast counter — ALL diag-family) · `combat_state`+`boss_state` (`boon_meter`/`series`/`last_melee_victim_i`) · `class_kit.recap_spec()` + twinfang/alch/well overrides · twinfang `_deal` boon-factor credit · `game/ui/stats_page.gd` NEW · `raid_hud` FULL REPORT button + `_show_stats_page` · `meter_probe [8]` · `screenshot_stats` NEW | **BUILT & MERGED.** Per-fight only (run recap deferred → row below). **BYTE-IDENTICAL** (diag-family; raid_sim+twinfang_sim serial A/B vs `3ec9a06`; meter_probe determinism + checksum unchanged). Boon impact: **Twinfang inline full**; Alchemist/Well proc-src + raid-amp paths (ramp/heal boons → SIM-PLAN S4 card-lift). **STANDING RULE:** every future kit rework adds its `credit_boon_factors` lines. ⚠ additive on `combat_core`/`combat_state`/`boss_state` — coexists with the `tuning-sweep` claim (no line overlap). |
| Run-level recap (aggregate across the descent) | 🔴 | MASTER §COORD (stats claim, deferred) | `run_state` per-fight results accumulator · new run-summary screen on campaign-clear / wipe (fold each fight's totals+grades) · class-agnostic data | **Fast-follow to STATS PAGE v2** (Bill: per-fight first). Low drift; nothing persists combat stats past one fight today. **⚠ shared with METER-PLAN L3** (segments dropdown consumes the same accumulator — build once, two front-ends). |
| **METER-PLAN — live meter leveled up (L1→L5)** | 🔨 `cce7c92` L1+⚡AMPLIFY (2026-07-10) · L3–L5 🟡 | **METER-PLAN.md** (2026-07-10) | ~~**L1** `class_kit.accent()` hook + 5 kit overrides (accent bug fixed) + compact polish (rank#/share%/player-wash)~~ · ~~**L2 ⚡AMPLIFY** `meter_panel.gd` (from `boon_meter` — who enables the raid + per-boon drill)~~ · **L2 tail** DISCIPLINE (`seat.diag`) · sparkline (`series`) · `src_label()` hook (deferred — `capitalize()` reads fine) · **L3** `run_state`/`run_director` + segment dropdown (= the run-recap row above) · **L4** window chrome + profile store · **L5** teaching layer (`school_of` hook) | **L1 + AMPLIFY BUILT & MERGED** (`0859b2b`→`cce7c92`). View-only/diag-family; **ab-gate raid_sim BYTE-IDENTICAL PASS** (pre-verify-pause), project imports clean; visual probe skipped per Bill's sim-pause. Data for the L2 tail already exists (STATS PAGE v2). Duelist accent lands with its kit. **Next: L2 tail or L3.** |

### I. THE DESCENT REBUILD (`DESCENT-PLAN.md` — SLICE 1 🔨 MERGED `ee18e05` 2026-07-10; slices 2–6 next)

**Verdict record:** V1–V6/V10/V12 at the recommendations · V7 **NO 2nd module** · V8 **STANDING/
Prior deleted entirely** (no fold — fresh runs stay fresh) · V9 **WILD ~10%** (2/floor on F2–4,
out of EVENT quota) · V11 per-seat earned wallets. Numbers = tune-on-feel, not blockers.

**SLICE 1 = THE MAP BANG, shipped:** the one `raid_map_sim` re-baseline is DONE (walker +
`CampaignCore` moved together · descent invariants proven in-sim · per-fight ttk column · Prior
term dropped in the same bang · protocol v15 · solo `map_sim`/`raid_sim` byte-identical). The
new node kinds exist ON the map now with honest stub interiors — slices 3–5 flip
`RunMap.MARKET_LIVE / JAILBREAK_LIVE / MINIGAME_LIVE` without regenerating a single map.

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| 4-floor restructure (Vorathek→F1 Seal, Rings 3-2-1-0) | 🔨 `ee18e05` | DESCENT §1–2 | `raid_content.FLOORS` (+quota/minigame/tier/packroll per row = the ONE source) · `run_map` · `raid_hud` · `net_server` · `raid_map_sim` | SHIPPED: rows 6/8/8/9, ring-1 split from the ROOT alias, salvage `1:`, grant ladder holds (module F1 · re-wire F2 · NO 2nd module V#7). |
| ELITE node (REINFORCED trio + bounty + curio-roll drop event) | 🔨 `ee18e05` (keystone slot ⏳) | DESCENT §5 | `run_map`, `raid_hud` packroll/win path | SHIPPED elective + pinned-reachable. **Keystone 1-of-2 = reserved slot** — lands with the per-class deck slices (no class ships a granter-ready pool yet; §C elite-node row tracks it). |
| WILD nodes (~10%, payload rolled at gen, tier printed) | 🔨 `ee18e05` | DESCENT §5 | `run_map`, resolve layers | SHIPPED (V#9). |
| Node contracts + legibility UI pass — **SLICE 2, next** | 🔒 | DESCENT §5/§9 | `map_screen`, `map_event_panel`, header meters/pips | Kind faces/tags/glyphs shipped w/ slice 1; still owed: one-line contracts on doors + fight-tier ▮ pips + both-legs check hints + renames (LUCK/BACKUPS/REGENERATE/DEPRECATE) + **the raid integrity kill + ticket re-price**. |
| PROMPT MARKET interior + post-Seal market phase — SLICE 3 | 🔒 (V#11: per-seat wallets) | DESCENT §6 | flip `RunMap.MARKET_LIVE`, `run_state` tokens→per-seat, `draft.gd` (mint `state.diag`→`seat.diag` + deposit to earner, UPSELL spends own), `raid_hud` (shop UI + AI director + AUTO), `gear_catalog` reframes | Node exists (stub=CACHE). **= GEAR-3 absorbed.** AI seats START EARNING. `tokens@market` sim diag. |
| THE JAILBREAK interior — SLICE 4 | 🔒 (V#4: mixed, lean gentle) | DESCENT §7 | flip `JAILBREAK_LIVE`, deal content, `draft.gd` welded-downside, curse pips, Cooling purge fork | Node exists (stub=EVENT). **= TEETH curse-cards.** No run-long timing curse. |
| Minigame interiors: CAPTCHA · BENCHMARK (+ SERVER ROOM · PATCH BAY · 2 reserved) — SLICE 5 | 🔒 (V#5: best-of-N) | DESCENT §8 | flip `MINIGAME_LIVE`, scoring over `strike_judge`/lockstep, backdoor room | Nodes exist (stub=EVENT, flavor field already rolled per floor). Bonus-tier pay only. |
| THE QUEUE + DEED/ESCORT ticket shapes + turn-in fork — SLICE 6 | 🔒 (V#10: SEV-1 parked v1.1) | DESCENT §10 | `map_content` tickets, `CampaignCore.ticket_at` + sim walker, `seat.diag` | One-grammar/two-ledgers verdict. ESCORT port inherits `escort-ticket` lane-law debt. |
| Packs on raid floors + enrage retighten + the fight ladder | 🔨 `ee18e05` (Forge enrages ⏳) | DESCENT §3 | `raid_content` packroll/FLOORS, skirmish enrages | SHIPPED: F1 55/35/10 → F4 15/45/40; skirmishes 150/175→95/110. **Forge body enrages untouched** (zone-shared — the balance pass owns them). |
| Seal budget contract (5/7/9/12 min) | 🔒 (V#12: ship structure at ~2h) | DESCENT §4 | (the later boss pass) | The contract the boss redo fills — structure beats, NEVER +HP. Not built by this cluster. |
| Map-seed-from-run-seed | 🔨 (was P4) | DESCENT §2 | — | Offline was ALREADY run_seed-derived (P4 rails); verified in slice 1. Online keeps the server-minted per-descent seed (deterministic within a descent; server has no profile). |
| V#8 Prior/STANDING deletion | 🔨 `ee18e05` | DESCENT §9 | (14 files swept) | SHIPPED: `luck_profile.gd` deleted, baseline ⚡ open, prior fx→entropy, prior gate→entropy gate. Remaining §9 renames/meters ride slice 2. |
| Server pack pass (online elite promotion + packs) | ⏳ | DESCENT §5 | `net_server` spec build | Online elite currently fights its captain solo (flagged in code); packs are offline-only today (pre-existing). |
| Ceremony-time probe (the unmeasured ~34 min band) | 💡 | DESCENT §13 | new probe over menus/drafts | The one un-instrumented slice of the §1 time budget. |

### J. THE DUNGEON STRUCTURE (`DUNGEON-PLAN.md` — 🟡 the cluster at Bill's 8-verdict board §V, 2026-07-10)

⚠ **Sequencing:** land AFTER the §I one-bang re-baseline (the dungeon is a `run_map` PRESET on the
same inputs/invariants — piggyback its shape assert on that suite, no second baseline). Dungeon 1
content authoring (nodes + THE TALLYMAN) stays the W3 claim (§D row) — this cluster de-risks it
to content work. Adds **ZERO rows to the `draft.gd` claim queue** by design.

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| Dungeon map preset (7 rows/~17 nodes/1 Seal + quota bag + invariants) | 🟡 V#1 | DUNGEON §2–3 | `run_map` inputs preset, map-sim invariants, `RunDirector` run-shape | Rides §I's re-baseline bang. Farm-lap ~25 / push-lap ~29 min budget. |
| THE DOOR CONTRACT screen (Version+Depth dials · affix preview · best standing · subset banner) | 🟡 V#7 | DUNGEON §2 | `world_shell` door screen, `rift_world.cfg` per-door standing | Depth thread owns the scalar — this RENDERS its output. Endless door plugs in here later (don't fork). |
| Keystone-at-elite (dungeon) + 1-life/ATTEMPTS wiring | 🟡 V#3 | DUNGEON §5/§7 | keystone grant site, loss-mode path, attempt-token spend | **AMENDs PROGRESSION §UNLOCK-2** "after the 1st boss" wording. Raid BACKUPS row (§D) shares the consumable. |
| The skin table (~8 world-skin display strings) | 🟡 V#2 | DUNGEON §5 | one lookup fn over market/curse/skill-node/attempt strings | Realm doors keep DESCENT names; bound: ONE world column ever. |
| Subset table config (per-dungeon system toggles) | 🟡 V#5 | DUNGEON §9 | run-spec subset flags, door banner | Creed-only first (D1) · Module-not-Creed (D2, W5). Byte-identical where a system is off. |
| Dungeon Seal contract (6–7 min named boss) + QUEUE-lite board | 🟡 V#6/#8 | DUNGEON §4/§8 | (the boss pass) · ticket board reuse | Contract only — THE TALLYMAN kit + Versions ladder = W3/boss-pass work. DEED-weighted ticket mix. |

### H. Parking lot (💡 unclaimed — promote when claimed)

| Item | Specced | Note |
|---|---|---|
| MMO-feel levers | MASTER §OPEN-IDEAS | warband lending · Bastion bounty board · ghost-replay races · co-op cosmetic standing. Needs P4 roster persistence + replay files + W4 presence. |
| Future realms | MASTER §OPEN-IDEAS | Bureaucracy · Undercroft · Deep · Clockwork Court · Kaiju Weather Station (each = Seals ladder + map skin). |
| New-class seeds | MASTER §CLASSES | redline self-brink DPS · over-defend tank layer · imposed-rhythm caster. |
| ~~2nd Module slot at Ring 1/0~~ | WORLD §INSTANCES | **DECLINED (DESCENT V#7 ✅, Bill 07-10)** — one module per run stands; boons carry the late game. Dead, don't re-derive. |
| Game title lock | MASTER §OPEN-IDEAS | UNPLUGGED / KILLSWITCH / Ctrl+Alt+DEFEAT / … |

---

## 3. AWAITING BILL'S VERDICT (decide before building)

The 🟡 pull-list — open decisions that will rot the plan if left. Grouped:

- ~~**THE DESCENT REBUILD**~~ — **✅ ALL 12 DECIDED (Bill, 07-10), cluster flipped 🔒 (§I).**
  Notables: NO 2nd module (V7) · STANDING/Prior deleted entirely (V8) · WILD ~10% (V9) ·
  per-seat wallets (V11). Also closes the old Teeth feel-verdicts for CONTEST scoring
  (best-of-N) + curse magnitudes (mixed menu, lean gentle) below.
- **THE SETTING (THEME-PLAN §6)** — 7 dials: origin (made-wonders recommended) · why-now ·
  rarity tier names · module rename · title · org · mystery volume. Unblocks the naming
  pass (§D row); riff-stage, keep riffing before ruling.
- **Tank·Duelist deck v1** — the whole slate is at your board (KEEP/TWEAK/CUT per card).
- **Warden deck** — later pass, but confirm the frame after Duelist.
- **Alchemist·Brew review** — 11 proposals (§8).
- **Alchemist open calls** — F1 (Opening interaction) · F2 (active-vs-idle patience) · F3 (auto-evasion identity — gates Cask under-fire) · F20 (grow VIAL non-minigame).
- **Well** — Glint 3-tier ladder vs built 2-tier.
- **Twinfang** — "On the Beat" card.
- **Curio Pool v2** — approved-but-not-final (~18 curios).
- **CURIO ARMORY v3** — the ~40-row big slate at GEAR-CATALOG §ARMORY-v3 (keep ~15–20; 5 rows carry ⚠ flags needing a ruling).
- **Teeth feel-verdicts** — ~~CONTEST scoring · curse magnitudes~~ (✅ closed by DESCENT V#5/V#4) · still open: spells-reweight pilot class · Endless framing (Depth coordination).
- **Deck-reshape (per class)** — CD shape · 2-vs-3 branches · keystone generic-vs-category · map reward-legibility mix · curse-card × EASE interplay.
- **Interrupt-by-ability** — which Tempo ability carries the kick.
- **REFIT Phase 4** — the P4 claim table is at your verdict (§CODE AUDIT).

*Playtest-tune (build then dial, not blockers): FLOW-economy numbers · Duelist minigame numbers · all reworked-class balance bands.*

---

## 4. HOW TO MAINTAIN THIS DOC

1. **Design locks** → add/flip the row here in the **same commit** as the plan-doc change (mirror CARD-CATALOG's law).
2. **Code merges** → flip `St` to 🔨 + short SHA; when fully shipped, strike the row or move it to a "Shipped" tail (keep it lean).
3. **Never write design here** — if you're tempted, write it in the plan doc and link. This is an index.
4. **Re-run the audit** (the 5-scout sweep that built this) after a big planning burst to catch new scatter and doc-drift.
5. **§0 collision map is the point** — when you claim a file in the hotspot table, check who else is queued on it and serialize.
