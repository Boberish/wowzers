# METER-PLAN — the combat meter, leveled up (Recount → beyond)

**What this is:** the design plan for growing the in-combat damage/heal meter
(`game/ui/meter_panel.gd`) from "a good Recount clone" into the number-heavy game's
**live coaching surface**. Bill's ask (2026-07-10): *"make it nice like Recount so I can
see more details; plan what the next level up is."*

**Status:** 🔨 **L1 + ⚡AMPLIFY BUILT & MERGED** (`cce7c92`, 2026-07-10) · L2 tail + L3–L5 🟡
design. The engine data already exists for most of L1–L2 (STATS PAGE v2 laid the accounting);
this is largely a **view-layer** plan, so nearly all of it is **byte-identical / diag-family**
work (L1+AMPLIFY proved `ab-gate raid_sim` BYTE-IDENTICAL).

**Doc of record:** the meter's *design* lives here; the *card/boon* meanings live in
`CARD-CATALOG.md`; the post-fight FULL REPORT is `stats_page.gd` (STATS PAGE v2, built) — this
doc is its live-combat twin. Tracking rows: `BUILD-LEDGER.md §G`, MASTER-PLAN Coordination Log.

---

## 0 · WHAT'S SHIPPED — the L0 baseline (`5a6e4ad` 2026-07-03, `330 ln`)

`MeterPanel` is already a real Recount: a right-rail glass plaque that reads engine truth
(`state.meter`) every frame, never writes state (lockstep-safe online), never checksummed.

- **COMPACT** — ranked combatant bars (bar ∝ leader), name · total · rate column (DPS/HPS).
  Player marked ◆, dead seats dimmed, bar tinted by class accent.
- **DETAIL** — one combatant's per-**source** breakdown: total · share% · `n× · avg · max` ·
  crit count (dmg) / % overheal (heal).
- **4 modes** header-cycles: DAMAGE / HEALING / SHIELDING / DAMAGE TAKEN. Rolling **NOW** rate
  over ~5 s. `M` cycles compact → detail → hidden chip (session-sticky). Healers default HEALING.
- **Frozen recap** variant on the end screens (static, click-drills).

**The accounting is already deep** (STATS PAGE v2, `4b58d0b`): `state.meter` per-source
(`total/n/max/crit_n/over`), `state.boon_meter` per-boon marginal impact (incl. the raid-amp
pool at index −1), `state.series` 1 Hz damage-over-time, `seat.diag` grade/interrupt/aggro
counters. **The live meter reads only the first of these.** That gap is the whole opportunity:
the numbers exist; the live view doesn't show them yet.

---

## 1 · DESIGN LAWS (every level obeys)

1. **View-only, engine-truth.** The meter reads `state.*`, never writes. Everything here is
   **diag-family** (never checksummed) → the byte-identical gate passes for free. This is why
   the meter can grow fast: it's not engine risk.
2. **Single-target law (COMBAT PILLAR #1).** One boss, one telegraph stream. So **no
   per-target sprawl** — the one exception is adds / owned-adds (DESCENT), which get at most a
   "boss vs adds" split, never a target grid.
3. **One HUD law.** There is one meter, on the one game HUD. No solo/raid fork, ever.
4. **Legible over complete.** Recount drowns you in tabs; our edge is *plain language* (STATS
   PAGE v2 already does "89% autos", "you left X on the table"). Every new number earns its
   pixels or it's a drill-down, not a default.
5. **Kits own their labels.** Source pretty-names and class accents must come from the kit
   (`ClassKit` hooks), not a central dict the meter has to chase — see L1. A new class should
   light up correctly the day it merges, with zero meter edits.

---

## 2 · THE GAPS (why it isn't "nice like Recount" yet)

**Staleness (actively wrong today):**
- `_accent()` only knows Bulwark / Twinfang / Bloomweaver. **Alchemist and the Well — the two
  post-purge DEFAULT seats — have no color identity**; they render in generic STEEL. The
  Duelist will land the same way.
- `PRETTY` source-label dict still lists deleted classes (`void_dot`, siphon, mender sources)
  and is **missing** Tempo v4 (Wound/Edge/Finish), Alchemist brew, and Well brim/draw sources —
  so those show raw `snake_case.capitalize()`.

**Detail the data supports but the live view hides:**
- **Boon impact** (`boon_meter`) — "the damage your Sunder enabled for the raid" is computed
  live for the stats page but invisible in combat.
- **Discipline** (`seat.diag`) — interrupts landed, casts let finish, times-hit, aggro strays,
  dodge/parry grades. Recount has Interrupts/Dispels/Deaths tabs; we have the data, no mode.
- **Time shape** (`series`) — no per-row sparkline, no live dmg-over-time.

**Recount features we lack entirely:**
- **Segments / history** — Recount's Current / Overall / per-pull dropdown. We're per-fight
  only; nothing persists across the descent (the deferred run-recap, `BUILD-LEDGER.md:270` 🔴).
- **Death log** — who died, to what.
- **Window chrome** — fixed 300 px right-rail; no drag / resize / reposition / second window /
  report-export.

---

## 3 · THE LEVELS — the next-level-up roadmap

Ordered by value-per-effort. Each level is a shippable slice; L1 alone makes it "nice."

### ✅ L1 — POLISH & DE-STALE — *"make it nice"* — **BUILT `cce7c92`**
The cheap, high-impact pass. No new engine data.
- ✅ **Killed the accent switch.** New `ClassKit.accent() -> Color` hook (built-in Color — the
  data layer never imports Palette/UI; sibling to `recap_spec()`); `_accent()` calls it.
  Backfilled all 5 kits (Twinfang cyan · Alchemist ember · Well water · Bloomweaver jade ·
  Bulwark gold). **Fixed the live bug: Alchemist + Well now have identity** (were steel).
- ✅ **Compact row polish (the "Recount look"):** rank number (#1 gilded), share **%** column,
  player-row wash, brighter bar leading-edge cap.
- ⏳ **L2 tail — deferred:** `ClassKit.src_label()` per-kit hook — the active kits emit
  `attack/boil/poison/red_harvest/ward`, all of which `capitalize()` already reads fine, so the
  central `PRETTY` de-stale was low-value; do it when a kit ships a src that needs prettifying.
- ⏳ **L2 tail — deferred:** overkill on the detail line; **activity %** (needs a cheap
  first/last-hit tick span on the meter row — a small engine field, so not pure view).
- **Verified:** `ab-gate.sh raid_sim` **BYTE-IDENTICAL PASS**, project imports clean. (Visual
  `screenshot_meter` skipped — Bill paused the sim/verify bar mid-build.)
- **Files touched:** `meter_panel.gd`, `class_kit.gd` + 5 kit overrides. **Size: S.**

### L2 — MORE MODES — *"see more details"* (surface data already captured)
The richest untapped seams. Each is a new header-cycle mode reading existing state.
- ✅ **⚡ AMPLIFY mode — BUILT `cce7c92`** (the standout — *Recount can't do this*). Reads
  `boon_meter` as a new header-cycle mode: ranks each seat's OWN boon lift + a synthetic **RAID
  AMPS** row for the −1 pool (Sunder/Glint/Debilitate — the engine credits these raid-wide, not
  to the applier, so the row is honest as "raid" not mis-attributed); drill a row → per-boon
  "≈ +X dmg/heal". Answers Bill's *why* directly. The live twin of STATS PAGE v2's BOON IMPACT.
- ⏳ **🎯 DISCIPLINE mode.** Reads `seat.diag`: interrupts landed · casts let finish
  (`kick_open_missed`) · times-hit · aggro strays · dodge/parry grade mix. Recount's Interrupts
  + a "are they playing clean?" scoreboard, in one column. **Next candidate.**
- ⏳ **Per-row sparkline.** A tiny live DPS trace per compact row from `series` — the shape of
  the fight at a glance.
- **Verify:** same as L1 (all diag-family). **Files:** `meter_panel.gd` only. **Size: S–M.**

### L3 — SEGMENTS & RUN HISTORY — Recount's killer feature (needs the deferred accumulator)
Recount's Current / Overall / per-pull dropdown. This **is** the deferred run-recap
(`BUILD-LEDGER.md:270` 🔴) — build the accumulator once, and both the run-summary screen *and*
the live meter's segment dropdown fall out of it.
- `run_state` gathers each fight's `meter`/`boon_meter`/`diag` snapshot on fight-end.
- Live meter gains a segment selector: **This Fight · Whole Run · ‹pick a past fight›**
  ("Vorathek", "Elite pack 2", …). "Whole Run" sums the snapshots.
- **Dependency:** the run-level accumulator (class-agnostic data, low drift). **Do this
  together with the run-summary screen** — same data, two front-ends.
- **Verify:** `ab-gate` (accumulator is diag-family too) · new `map_sim`/run smoke that a
  cleared run produces N segments. **Files:** `run_state.gd`, `run_director.gd`, `meter_panel.gd`,
  + the run-summary screen. **Size: M.**

### L4 — WINDOW CHROME — make it feel like a real addon
Where it stops being a fixed panel and becomes a thing you own.
- **Drag / resize / reposition**, position saved to profile. Snap to the right rail by default.
- **Two windows at once** (a DMG meter + an HPS meter, Recount-style), each with its own mode.
- **Report / export** — a text dump of the current segment (and, in co-op, paste-to-chat: "link
  the meters"). Rides the same snapshot data as L3.
- **Compare band** — overlay the sim's *good-tier* band (SIM-PLAN) or your last kill, so a
  number reads as "ahead / behind", not just absolute.
- **Verify:** UI smoke for drag/persist. **Files:** `meter_panel.gd`, HUD placement,
  profile store. **Size: M.**

### L5 — THE TEACHING LAYER — our differentiator (beyond Recount)
The meter as a coach, not just a scoreboard. Leans on STATS PAGE v2's missed-ops + grades.
- **Live "left on the table"** nudge (throttled) from missed-ops — the coaching lines already
  exist post-fight; surface the top one live when it spikes.
- **Grade-tint rows** — optionally color a row by *how clean* (diag grades), not just by class,
  so sloppy play is visible mid-fight (ties to aggro = threat in the tank rework).
- **Boon-lift callouts** — "Sunder is carrying 12% of raid damage" as a passive teach.
- **Damage-school grouping** — the speculated `ClassKit.school_of(src)` hook (MASTER-PLAN),
  groups sources by school for a higher-level read. **Size: M, exploratory.**

---

## 4 · RECOMMENDED FIRST SLICE

**Ship L1 + the AMPLIFY mode from L2 as one branch (`wow-meter`).** Rationale:
- L1 fixes a *live correctness bug* (two default classes are colorless) and delivers the whole
  "make it nice" feel for S effort.
- AMPLIFY is the single most on-brand feature — it directly answers Bill's *"see what boons
  work"* — and its data is already computed and reconciled (`boon_meter`, `meter_probe [8]`).
- Both are view-only → the byte gate is free, so it merges without balance risk.

Then Bill feels it and picks the L2 tail (DISCIPLINE / sparklines) vs jumping to L3 segments.

---

## 5 · WIREFRAME (target compact + amplify + detail)

```
┌ ◆ DAMAGE DONE ──────────── 1:24.6 · NOW 4.1k/s ┐   ┌ ◆ ⚡ AMPLIFY ─────── who enables the raid ┐
│ 1. Twinfang ◆   ▓▓▓▓▓▓▓▓  128k  42% · 1.5k ⌁   │   │ 1. Alchemist   ▓▓▓▓▓  ≈+9.2k  Sunder,Vuln │
│ 2. Alchemist    ▓▓▓▓▓     71k   23% · 0.8k ⌁   │   │ 2. Well        ▓▓     ≈+2.1k  Glint       │
│ 3. Well  (heal) ▓▓▓       38k   12% · 0.4k     │   │ · raid amps credited to who applied them  │
│ 4. Bulwark      ▓▓        22k    7% · 0.3k     │   └───────────────────────────────────────────┘
│                                                │   ┌ ‹ Twinfang — DPS 1.5k ─────────────────────┐
│ M · view    click title · column               │   │ Wound        ▓▓▓▓  52k 41%  310× avg168 max…│
└────────────────────────────────────────────────┘   │ Perfect      ▓▓▓   38k 30%  120× · 44 crit   │
   rank# · class-accent bar · share% · sparkline⌁     │ Finish       ▓▓    22k 17%  …               │
   (L1 adds #/%/glyph/⌁; L2 adds the ⚡ mode)          └───────────────────────────────────────────┘
```

---

## 6 · VERIFICATION & TRACKING

- **The bar:** `scripts/ab-gate.sh raid_sim` (+ `twinfang_sim`) **byte-identical** for every
  level — all meter data is diag-family, so any diff is a bug. `sim/meter_probe.gd` green
  (extend its reconcile if a level adds an accounting funnel — L3 only). `screenshot_meter`
  visual probe (WSLg, not headless) for any `_draw` change.
- **Tracking:** slate/collision rows in `BUILD-LEDGER.md §G` (this doc's row + the existing
  run-recap `:270` row, which L3 consumes). Decisions → MASTER-PLAN Coordination Log. No cards,
  so no `CARD-CATALOG.md` touch.
- **Standing rule inherited:** kits already owe `credit_boon_factors` + `recap_spec()` (STATS
  PAGE v2 rule) — L1's new `accent()` / `src_label()` hooks join that per-kit checklist so the
  frozen kits (Bulwark/Bloomweaver) get backfilled when they rework.
