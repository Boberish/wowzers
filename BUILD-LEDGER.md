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
| `data/raid/raid_content.gd` (626) | Seal beat data · `threat_enabled` (`:625`) · melee/telegraph split (`:8`) · Seal-pillar · aura-add · Trial-Ladder Versions | The whole boss wave edits this. Serialize claims; each shifts fight checksums **on purpose**. |
| `game/draft.gd` (+ `draft_sim`) | Rarity tier-roll engine · rerolls-out · loot two-modes · curse cards · spells reweight · curio-pool v2 · EASE dial knob-roll | One draft/roll pipeline. Serialize claims; keep `draft_sim` green each merge. |
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
- FLOW=AGGRO rewire (tank wave).
- Seal Pillar Pass v1 (dodge-ration nudge).

### Stale / superseded code to RETIRE (not just add-around)

| Old code | Where | Replaced by |
|---|---|---|
| Threat / aggro / taunt system | `threat_enabled` gate (`combat_state.gd:43`, default off) → `combat_core` (44) · `boss_state.gd:57-61` · `tuning_config.gd:56` · `bulwark_kit` Challenge · `raid_hud` T-CHALLENGE (25) · `raid_sim` (17) | **FLOW=AGGRO** (tank wave) — largest single collision surface |
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

**Wave 2 — CLASS RESHAPE (Phase 2)** — cheap once Wave 0 exists: signature CD per class · 3-axis filing · branches · owed HUD gauges (on the shared base) · buff-channel application · dodge migration per class · interrupt-by-ability class-by-class (Tempo first). Finish Cask 2–5, Twinfang owed + 2nd spec, Fermata recode, Well gauges/AI/balance; back-fill CARD-CATALOG as you go.

**Wave 3 — WORLD / META** (`rift_world.cfg` + Atlas): Unlock System (spine) → W3 doors + front-door flip → GEAR-3 Market (the token sink) → rerolls-out → TICKETS v2 / Zone-Remembers / Risk Fork / Quest Board / RESTED / curio-pool v2 / actives socket → W4 living world.

**Wave 4 — DEPTH & TEETH** (`draft.gd` + map + Depth): CONTEST · loot two-modes · curse cards · spells pilot · event-crafting → Trial Ladder (proves scaling hooks) → RAID DEPTH (rides Trial Ladder + vuln stack) → Endless (a *door* on Depth, don't fork).

**Wave 5 — BOSSES & ENDGAME:** Seal Pillar Pass v1 · aura-add second-cast-source · TEAM-COMP schools (rides vuln stack). *Boss-redo era for the 15 solo bosses is on HOLD — don't redesign now.*

**Wave 6 — MMO SHELL:** Gateway / InstanceHost / CampaignEngine — only after P4 rails.

**Cross-cutting, land anytime:** Kill-Switch P3 · MAP-2 depth · code-audit findings · tooling loose ends · graphics re-rig.

---

## 2. THE SLATE — by workstream

### A. Combat-engine cross-cutting (the shared seams)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| Generic boss-vulnerability stack | 🔒 | REFIT-P4 | `CombatCore.damage_boss`, `boss_state` | Build FIRST — TEAM-COMP + Depth + Well-glint ride it. Rebaseline. |
| TEAM-COMP damage-schools | 🔒 | MASTER §OPEN-IDEAS | `damage_boss` amp, `ClassKit.school_of`, `EncounterRes` profiles, HUD pops | Rides vuln stack. Parked behind Commander per Bill. Byte-identical when profile empty. |
| Interrupt-by-ability pillar | 🔒 | WORLD §PILLARS #3 | `AbilityRes.interrupts` flag, tight window, sim diag, HUD rune | Lands class-by-class w/ reworks (Tempo first). Replaces cut Voidcaller kick. Open Q: which Tempo ability carries. |
| Aura-add / 2nd cast source | 🔴 | MASTER §BOSSES | engine 2nd telegraph source | Blocks R3 raid content; also eases the one-telegraph interrupt problem. |

### A½. THE OLD-GAME PURGE (2026-07-10 — Bill; MASTER §GAME SHAPE amendment)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| **THE PURGE** — delete Voidcaller · Mender · Reckoner + the 15 solo bosses + the GATE node kind; defaults flip caster→Alchemist(brew) · healer→Well(brim) | 🔨 in flight (worktree `../wow-purge`) | MASTER §GAME SHAPE 07-10 amendment | `data/{voidcaller,mender,reckoner}/*` · `data/raid/gate_content.gd` · `run_map`/`map_content`/`map_screen`/`raid_hud` gate flow · `class_codex` · `raid_content` seat factories+defaults · `net_server`/`raid_net` (protocol bump) · policies/binds/gauges/rigs · `draft`/`armor_slots` · sims (`raid_sim` defaults · `raid_map_sim` re-baseline · `raid_healer_probe`/`raid_reckoner_probe`) · `verify-all.sh` | **Deliberate re-baseline** (maps regen w/o gates; comp flips; **NO-KICKER interim** until pillar #3). Keeps Twinfang Warden/Executioner as `twinfang_sim` training dummies only. ⚠ Collides with live `cask-policy` + `tempo-pilot` worktrees — merge main often. |
| **Bulwark deletion** (the last fossil) | 🔒 | MASTER §GAME SHAPE 07-10 | `data/bulwark/*` · `raid_tank_policy` · `raid_hud` tank band · the old threat/taunt surface | **Dies in the SAME merge that ships the Duelist base kit (Wave 1) — never before**: it is the only tank in code. Supersedes "retire with the tank wave" phrasing in §0 (now a hard rule). |
| Gate-sourced + dead-class GEAR rows re-home/cut | ⏳ | GEAR-CATALOG banner 07-10 | `game/gear.gd` tables · `gear_probe` | Per class-rework deck (CARD-TRACKING LAW). `gear_probe` re-scopes at the purge merge. |

### B. Tank rework + FLOW=AGGRO (Wave 1 — co-dependent)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| FLOW=AGGRO universal rewire | 🔒 | TANK §1c/1d | built threat engine (source damage→flow), seeded peel roll, `raid_content.gd:8` | Numbers→playtest. Revises "aggro=raid-only" (`b2afbca`) → universal. Rips out `threat_enabled` system. |
| Duelist guarded base kit | 🔒 | TANK §4 | new guarded tank seat, bespoke PARRY+DODGE (no `unified_dodge`/ration) | Numbers→playtest. **Wait for Bill's verdict export blob.** A/B vs Bulwark default. |
| Peel mechanics (progressive + grace-delay) | 🔒 | TANK §1c | aggro-% shape, victim dodge bar, TAUNT hard-override | Part of FLOW=AGGRO. Grace-delay = fixed tick offset (det-safe). |
| Tank defensive signature CD ("the wall") | 💡 | TANK §1b, DECK-LAYOUT §5 | new ~1-min CD, carries dropped GUARD | Not yet designed. Both specs get one. |
| Duelist deck v1 | 🟡 | TANK §3, CARD-CATALOG | kit-local layers, `_fw()` dispatch (Well idiom) | **Whole slate at Bill's board.** GUARD-drop fallout: 3 rig cards 🔮→Warden. **EASE-dial fallout: flat EASE boons (Quick Wrists/Roll With It) fold into one dial** (DECK-LAYOUT §4); The Veteran creed stays. |
| FLOW module (aggro→damage upgrade) | 💡 | TANK §1b | new STRAT module | Competes for Floor-1 module slot. Reconcile at deck reshape. |
| Duelist sims + carry | 🔒 | TANK §4.4 | new `duelist_sim`, `raid_sim --tank=` | After base + deck. |
| Duelist HUD slice | 🔒 | TANK §4.5 | `raid_hud` timing instrument, own FLOW bar, shared aggro box | WSLg screenshot (headless can't `_draw`). Non-tanks get no flow bar. |
| Warden spec (base + deck) | 🟡 | TANK §5 | new — BLOCK/SHIELD/SHIELD-SLAM, no dodge | Base locked; deck = later pass after Duelist proves the frame. Receives re-homed guard cards. |
| **Warden — BRANCH SLATE (5 themes)** | 🟡 | TANK §6 + `research/warden-sweep.md` | design only (deck pass = Phase-2 row D1) | Payload · Slam · Rampart · Bannerman · Thornback — Bill picks 2–3. Absorbs the 🔮 guard trio + carries (filing table). Bannerman flags the buff-channel debt. |
| Tank per-Seal streams + interrupt flag + spec-carry | ⏳ | TANK §4.6 | encounter data per Seal | Ship with build, not deck. Interrupt flag with the pillar-#3 pass. |

### C. Class reshape (Phase 2) + shared class substrate

**Shared substrate — build ONCE, unblocks many classes:**

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| Rarity tier-roll engine (H/S/O + runes) | 🔒 | TEMPO App-A, ALCH v3, CASK §7.4, FERMATA §7 | `game/draft.gd`, per-class boons, runes | **DESIGNED-NOT-BUILT.** Blocks real rarity for Tempo/Fermata/Brew/Cask/Well *simultaneously*. |
| Topology elite-node type (keystone acquisition) | ⏳ | TEMPO A8, FERMATA §13.6, CASK §7.6 | new map node + 1-of-2 keystone reward | Blocks ALL keystone acquisition across classes. |
| raid_hud gauge/meter render pass | ⏳ | TEMPO/FERMATA/MENDER/CASK | `raid_hud` + per-class gauges | Do it on the **shared Gauge base** (P4). WSLg render. |
| Online `(seed,spec)` spec-carry | ⏳ | TEMPO §13.7, ALCH §6, MENDER | `raid_net.gd` | One debt for all reworked classes. Class registry (P4) precondition for arbitrary builds. |
| Raid buff-channel application | ⏳ | TEMPO App-A, FERMATA §7 | raid buff channel | Battle Hymn + Veil Warband + Cask "Round for the House". Debilitator/Shining Hour = precedent. |
| DECK-LAYOUT Phase 2 program | 🔒 | DECK-LAYOUT §7 | every `data/<class>/*.gd` + CARD-CATALOG | Program locked; per-class feel-verdicts open (CD shape, 2-vs-3 branches, keystone generic-vs-category). **2026-07-09: modules = add-ons, transformer requirement DROPPED (no ⭐-transformer owed per class); reshape deepens pools via sub-specs/branches, not flat boons (EASE dial handles de-bloat). ABILITY LAW locked (§5): 7-touch-target ceiling (Well 8) — see the compliance-trim row below.** |
| ABILITY-LAW compliance trims (Alch bar · Well book) | 🔒 | DECK-LAYOUT §5 | `alchemist_boons.gd` `SPELL_CAP`/bar · `well_boons.gd` book+cap · mobile layouts | At each class's reshape, not before. Fully-drafted Brew = 9 targets w/ CD (catalyst button + 3 spells compete for the 2 allowance slots); Well loaded = 10 vs its 8 (trim/fold the book). Retune per-class `SPELL_CAP` to what the ceiling leaves free. |
| Signature CD per class (baseline) | 🔒 | DECK-LAYOUT §5 | new baseline button per class | Schema locked; per-class shapes open. Amplify skill, never button=damage. |
| EASE difficulty-dial (rolled comfort↔bite knob) | 🔒 | DECK-LAYOUT §4 | `draft.gd` knob-roll · per-class minigame knobs (window/speed/grace) · `raid_hud` dial card-face | Replaces flat comfort boons pool-wide (built per-class at reshape). **Rides the rarity tier-roll engine** (bite +dmg is rarity-scaled). **Same knobs Depth/Seal-pillar compress from the boss side — coordinate the caps** (two writers). Tank folds Quick Wrists/Roll With It in. |
| CARD-CATALOG back-fill (stub classes) | ⏳ | CARD-CATALOG | doc only | Tank fully populated; Twinfang/Alchemist/Well/Mender/frozen = stubs. `dump-cards.sh` deferred. |

**Per-class reshape work:**

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| **ALL-CLASS BRANCH SLATES — THE SLATE MACHINE (queue of 8)** | 🔄 in flight (15-min session loop) | SLATE-PLAN §0–§4 | design only — per pass: a slate § in the target's plan doc + `research/<target>-sweep.md` (+ NEW `BLOOM-PLAN.md` at row 3) | Generalizes TEMPO §14 to every class/spec, ONE at a time: Warden → Duelist → Bloomweaver → Cask → Brim → Draw → Brew → Fermata. Each slate lands 🟡 at Bill's board. Duelist/Fermata/Brew slates treat their existing decks as PITCH #0. Loop restart in a new session: `/slate-loop`. |
| **PHASE 2 — THE DECK MACHINE (9 full decks, design only)** | ⏳ gated (own 15-min cron; opens when every slate row lands) | SLATE-PLAN §5–§6 + deck-creator skill | design only — deck § per plan doc + **CARD-CATALOG rows at 🟡** + SLATE-PLAN §5 distinctness ledger; the BUILD of each deck stays a later coded claim touching `data/<class>/*` | Full deck per target around its slate's **top-3-ranked branches** (Bill's ✅ picks override). Coherence gates (dream-draft walkthroughs · offer-trio · in-deck overlap audit · anti-pattern sweep · AI-pilotability) + cross-deck distinctness ledger + 3 skeptics. Existing decks (Duelist v1 / Well / Brew / Fermata v5) = REVISIONS, absorb-don't-duplicate. All decks land 🟡 at Bill's board. |
| **Twinfang·Tempo — deck rebuild: BRANCH-THEME SLATE (6 themes)** | 🟡 | TEMPO §14 (corrected) + `research/` | design only this pass (deck pass later: `data/twinfang/*` · `draft.gd` EASE knobs) | **REDONE 2026-07-10 under the corrected branch=THEME definition (Bill)** — base minigame untouched; themes: Wound · Finish · Swift · Edge · Punish · Band. Bill picks 2–3 → deck pass files old+new cards into the winners. The six rewire pitches → TEMPO §15 parking 🔮 (future spec/aspect ideas; Coup-as-interrupt + CD-shape notes stay live inputs to §3 verdicts). |
| Twinfang — Through-Line + On the Beat cards | 🔒 / 🟡 | TEMPO A1/A6 | `twinfang_boons.gd` | Through-Line "design owed" despite build banner (drift). On the Beat at verdict. **Both fold into the deck-rebuild pass above.** |
| Twinfang — 2nd rhythm-variant spec (FERMATA) | 🔨 `f5d5397` | TEMPO §13, FERMATA-BRIEF | fermata kit + slate | Built & merged (verb + deck v5). Stale "design owed" corrected 2026-07-09; residual wiring on the row below. |
| Twinfang — Creed/Module wire TODO + killingEdge rig | 🔒 | `twinfang_content.gd:163` | twinfang kit | Only real actionable code TODO in repo. |
| Fermata v5 — owed wiring (HUD meters · elite acq · spec-carry) | ⏳ | FERMATA-BRIEF | shared passes (gauges/elite/`raid_net`) | Verb + slate BUILT (`f5d5397`, grades by depth — stale "recode owed" corrected 2026-07-09); what remains rides the shared substrate rows above. |
| Alchemist — Cask slices 2–5 | 🔒 | ALCH §7.7 | `AlchemistPolicy` + HUD + `data/alchemist` + `alchemist_sim` | Slice 1 built. Slate verdicted 24/6. Tune `cask_base`→Seal parity. |
| Alchemist — Brew review pass (11 proposals) | 🟡 | ALCH §8 | one guarded slice, config knobs | Live deck untouched until verdict. |
| Alchemist — open design calls F1/F2/F3/F20 | 🟡 | ALCH §OPEN | design; F3 would touch dodge/ClassKit | F3 (auto-evasion) gates Cask under-fire risk. |
| Well — module gauges + AI spell-policy | ⏳ | MENDER | `well_gauge.gd`, `well_policy.gd` | Deck already built. AI can't use Meditate/Boiling Over yet. |
| Well — Glint 3-tier ladder + tuning | 🟡 | MENDER §8 | `data/well/*` knobs | Built as 2-tier; full Good/Perfect/Bullseye at verdict. |
| Well — balance at real fightlen bands | ⏳ | MENDER | `well_sim`, `raid_sim --healer` | Run at 3–5min/~10min, not 60–142s — closes the inert-healer finding. |
| Dodge-unify migration (frozen classes) | ⏳ | DODGE-PLAN | `ClassKit.unified_dodge()`, drop F | **Bloomweaver only after THE PURGE** (Voidcaller/Mender/Reckoner deleted 2026-07-10; Bulwark moot — dies with Duelist). |
| Commander AI-caster toggle | ⏳ | ALCH §6 | Commander party screen | Brew + Cask. |
| Class names + puppets/art | ⏳ | ALCH/MENDER | class puppet art (voidcaller rig filler) | Filler-grade. Names are working titles. |

### D. Overworld / progression / meta (`rift_world.cfg` + Atlas)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
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
| GEAR-3 — Market + extraction | 🔒 | PROGRESSION §3, GEAR §Rollout | Market node, extraction schematics | **NEXT unclaimed.** The token sink rerolls-out needs. Curio-Economy-v2 reframe rides here. |
| GEAR-4 — raid personal loot + Seal tables | 🔒 | PROGRESSION §4 | per-seat seeded loot, Ledger pages | Crests/standing need accounts→later. VERSION rows need Trial Ladder. |
| Universal Curio Pool v2 (~18 curios) | 🟡 | GEAR §POOL-v2 | `gear_catalog.gd` | Approved-not-final. Cut 10 welded, keep 6, add 18 cross-spec. |
| Actives socket + paper active items | 🔒 | GEAR §Rollout | 1–2 sockets, G/H keys | Unlocks RELAY BATON/MUTE/ROLLBACK/UNPLUGGING etc. Some gated on Seal page (GEAR-4). |
| Escort/volatile tickets follow-up | ⏳ | WORLD §MEWGENICS ① | burden flavor, lane-law reward | Slice built (`ESCORT_PREVIEW`). Burden flavor needs interrupt pillar. |
| Armor set presentation panel | 💡 | PROGRESSION §ARMORY | `armor_doll.gd` paper-doll | Presentation only; reads existing draft state. |
| Unlock banking rule (win-only checkmark) | ⏳ | PROGRESSION §Drops | `rift_gear.cfg` persistence | First-kill checkmark banks on WIN; oaths bank win-or-lose. |
| E.5 oath drop-dedication | 🔒 | MASTER §SYSTEMS-E.5 | `beneficiary_seat_i` on oath state | Byte-identical self-default. Ties to Depth curation-capacity. |
| Raid wipe budget + floor checkpoint | 🔒 | WORLD §STAKES-MODEL | `RunState`/descent save-resume, `RunDirector`, raid loss-mode | Answers open-Q#6. Numbers→playtest. Needs descent-checkpoint plumbing. Dungeon stays 1-life. |
| Attempt tokens (Death-Defiance consumable) | 🔒 | WORLD §STAKES-MODEL | budget counter, Market (GEAR-3), TICKETS node reward, `draft.gd` | +1 attempt, any surface. Token sink — rides GEAR-3 + TICKETS v2. |
| Boon/curio battle-rez layer | 💡 | WORLD §STAKES-MODEL | `gear_catalog`, existing `revive` ClassKit hook | Healer Rekindle already BUILT; extend beyond healer so healer-less comps aren't hard-locked. |

### E. Depth & Teeth (`game/draft.gd` + map + Depth)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| Rerolls-out + Tokens→Market | 🔒 | TEETH §REROLLS | `draft.gd`, ASCENSION-STEAL | Reroll→earned charge; retires LOCK, keeps UPSELL. **Reframe Hot Reload + Hashgrinder curios.** Needs GEAR-3 sink. |
| CONTEST primitive (skill-check node) | 🔒 | TEETH §CONTEST | new node + scoring over `strike_judge.gd` | Reuses CAPTCHA + lockstep (first slice). Open: scoring rule. Co-design w/ interrupt window. |
| Loot two-modes (need/greed + AI banter-roll) | 🔒 | TEETH §LOOT | `raid_hud._after_drop` | Reuses rarity+pity roll. Solves AI-gear blocker (AI allies roll & banter). |
| Spells & depth reweight (pilot one class) | 🔒 | TEETH §SPELLS | `type:"spell"` draft weight | Open: which class pilots. NOT a tank spec until tank lands. Folds into next rework. |
| Curse cards (biting blessings) | 🔒 | TEETH §CURSE | welded-downside boons + poisoned-ability flag | Open: bite magnitudes. Pairs w/ rerolls-out. |
| Event-crafting (elite→extract→keystone unlock) | 🔒 | TEETH §crafting | event shape, oath-gated unlock | Partially reverses crafting-cut; counter-grind stays cut. |
| Endless door | 🟡 | TEETH §ENDLESS | new Atlas node chaining Depth | **Do NOT fork Depth** — sync with the Depth thread, frame endless as its presentation. |

### F. Endgame & bosses (`raid_content` + `raid_sim` + `TuningConfig`)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| Trial Ladder ("Versions") | 🔴 | MASTER §MODES | `TuningConfig` + strings, version dial on door | Author the mechanic-adds. Proves Depth's scaling hooks. Unlocks VERSION-row gear. |
| RAID DEPTH — infinite endgame | 🔒 | MASTER §MODES | `spec.depth` scalar, affix-intensity knob | Rides Trial Ladder + vuln stack. **Compress windows, never stat-inflate.** No persistent gear power. |
| Seal Pillar Pass v1 (dodge-ration) | 🔒 | SEAL-PILLAR-PLAN | `raid_content` Seal beats, `raid_sim` Phase-A instrument | **Rebaseline.** HANDS OFF kick chains / Double-Check / ULTRATHINK. |
| Boss-redo era (15 solo bosses) | ⏸ HOLD | MASTER §BOSSES | — | Bill unsure of end state — **do NOT redesign now.** Only 4 Seals maintained. |
| OPUS Helpful/Harmless/Honest phases | 💡 | MASTER §BOSSES | `phase_res` | Open idea. |

### G. Infra / REFIT-P4 / server-MMO (`net_server` / `run_director` / `world_shell`)

| Item | St | Specced | Touches | Blocks on / note |
|---|---|---|---|---|
| REFIT Phase 4 — SCALE RAILS | 🔨 in flight (worktree `../wow-rails`, infra subset) | REFIT §3 P4 | class registry · ClassBand+Gauge base · vuln stack · save unification (+roster) · offline `run_seed` · Split-law guard · twinfang kit split (1451L) | **Wave-0 rails.** Bill's go-code 2026-07-10 lifts the verdict hold for the INFRA subset: save unification + roster persistence + offline `run_seed` + split-law guard (in flight). DEFERRED until `purge-oldgame` merges: class registry · ClassBand+Gauge · vuln stack · kit split (§0 collision). Class registry gates net spec-carry. |
| MMO SHELL (§4 server era) | 🔴 | REFIT §4/§5 | Gateway/Session · InstanceHost (extract `_tick_room`+`RaidNet.step`) · server CampaignEngine · Profile store move | After P4. Combat never notices (already `(seed,spec)` pure). Needs a netcode-era plan when claimed. |
| Kill-Switch P3 (live UNPLUG + charge tuning) | ⏳ | MASTER §MAPS | `raid_marks.gd`, gear-picker for sacrifice path | P1/P2 merged (proto v11). Charge economy too generous (walker 40→96%) — needs a probe. |
| MAP-2 depth (ELITE/MARKET/secret/events/art) | ⏳ | MASTER §MAPS | map content | MARKET needs GEAR-3; ELITE needs aura-add. |
| Code-audit parked findings (grouped) | ⏳/💡 | MASTER §CODE-AUDIT, REFIT §2 | desync checksum coverage · `seat.casting`→`target_i` · WASM determinism cert probe · `net_server` hardening · boon×aspect sweep · Esc-teardown leak audit · save versioning | Several fold into P4/§4 — coordinate, don't double-build. |
| Tooling loose ends (grouped) | ⏳ | MASTER §TOOLING, REFIT P3 | auto-post sim bands · replay files (leaderboards) · CSV home · **7 `screenshot_*` re-hosts onto `world_shell.tscn`** · state-ownership lift off `raid_hud` | Screenshot scripts error loudly until re-hosted. Replay files unlock ghost-races/bounty. |
| SIM-PLAN balance ladder S1–S5 + THE SOAK | 🔴 | **SIM-PLAN.md** (2026-07-10) | per-class policies (creed branches + module verbs) · `sim_util.gd` card-delta harness · `draft.gd`-driven build sampler · raid per-seat meters/ablation · `scripts/soak.sh` + digest | **Triggered, not scheduled:** S1 rides EACH class rework (card-visibility rule) · S3 cheap-anytime · S2 after 2nd creed-aware policy · S5 with tank/aggro rebaseline · S4 per class after DECK-LAYOUT reshape · soak last. No hard balance gates ever (determinism stays the only PASS/FAIL). |
| Graphics — robot re-rig + 2D art pass | 💡/⏳ | MASTER §GRAPHICS | per-boss silhouettes via `Actor2D.make()` factory | Give gauges a shared base + stable obs contract first (P4). Classic-parry-perfect payoff = byte-gate. |

### H. Parking lot (💡 unclaimed — promote when claimed)

| Item | Specced | Note |
|---|---|---|
| MMO-feel levers | MASTER §OPEN-IDEAS | warband lending · Bastion bounty board · ghost-replay races · co-op cosmetic standing. Needs P4 roster persistence + replay files + W4 presence. |
| Future realms | MASTER §OPEN-IDEAS | Bureaucracy · Undercroft · Deep · Clockwork Court · Kaiju Weather Station (each = Seals ladder + map skin). |
| New-class seeds | MASTER §CLASSES | redline self-brink DPS · over-defend tank layer · imposed-rhythm caster. |
| 2nd Module slot at Ring 1/0 | WORLD §INSTANCES | for long raids; run-pacing plumbing. |
| Game title lock | MASTER §OPEN-IDEAS | UNPLUGGED / KILLSWITCH / Ctrl+Alt+DEFEAT / … |

---

## 3. AWAITING BILL'S VERDICT (decide before building)

The 🟡 pull-list — open decisions that will rot the plan if left. Grouped:

- **Tank·Duelist deck v1** — the whole slate is at your board (KEEP/TWEAK/CUT per card).
- **Warden deck** — later pass, but confirm the frame after Duelist.
- **Alchemist·Brew review** — 11 proposals (§8).
- **Alchemist open calls** — F1 (Opening interaction) · F2 (active-vs-idle patience) · F3 (auto-evasion identity — gates Cask under-fire) · F20 (grow VIAL non-minigame).
- **Well** — Glint 3-tier ladder vs built 2-tier.
- **Twinfang** — "On the Beat" card.
- **Curio Pool v2** — approved-but-not-final (~18 curios).
- **Teeth feel-verdicts** — CONTEST scoring rule · curse magnitudes · spells-reweight pilot class · Endless framing (Depth coordination).
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
