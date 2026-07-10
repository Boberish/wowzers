# TEMPO-D0-BRIEF — the D0 build brief (v1, 2026-07-10)

**What this is.** The implementation plan for the Tempo DECK v3/v4 + ability-audit outcome —
written for the session that BUILDS it (Bill: *"idk like to get this into code and test it. when
your done with the plan to implement, let me know and ill start it"*). Design of record:
`TEMPO-PLAN.md §17–§17.12` · slate + statuses: `CARD-CATALOG.md §TWINFANG·TEMPO` · laws:
`DECK-LAYOUT.md` (esp. §5 ABILITY LAW, +1/ceiling-6 + TRANSFORMS) · board: the Slate-Machine
artifact, D0 tab. Work in a worktree (`git worktree add ../wow-tempo-d0 -b tempo-d0`), merge
main often, gate every slice.

## 0 · SCOPE GATE — what's approved vs what each slice waits on

**✅ APPROVED (Bill, 07-10 artifact notes):** the SPEED GOVERNOR ("good") · RESONANCE ("yeah, no
set bonus") · THE DUO system ("yes we need this, make this rich and nice") · Pickup stays cut
("meh") · the NO-SINGLE-NEXT-HIT LAW (from his Sforzando/Count-In notes) + its two built-card
reworks · Grand Pause reword (clarity).
**🟡 GATED (each blocks only its own slice — listed in §7):** ① the v4 branch lock (WOUND ·
EDGE · FINISH — Bill proposed it; resonance perks + duo pairs below assume it; if SWIFT stays
instead, swap tables per §17.10) · ② the trim table · ③ the transform trio + Floor-2 acquisition.
**Deferred fine:** kick carriers (pillar #3 unbuilt) · THE SET PIECE CD (S6, deferrable).

## 1 · SLICES (build in this order; commit + gate each before the next)

### S0 · THE SPEED GOVERNOR ✅ (small, standalone — start here)
- `data/twinfang/twinfang_config.gd`: `beat_rate_cap := 1.6` · `window_min := 0.15` (≈4–5 ticks
  at 30 Hz; keeps the 18% Bullseye band ≥ ~1 tick + read margin). All numbers = knobs, sims sweep.
- `twinfang_kit.gd`: ONE combiner both the beat interval and `_edge_window` route through
  (the Fermata roaming-window precedent: modify in ONE spot at the end). Sources — accelerando ·
  quickstep stacks · Overdrive fever · doubleTime · (later: the EASE beat-speed knob) — fold
  ASYMPTOTICALLY, e.g. `push = Σ(src_i − 1)`; `rate = 1 + (cap−1)·(1 − exp(−k·push))`, `k`
  a knob. Deterministic, zero rng, no per-source clamps left behind (delete them — one wall).
- **Gates:** boonless byte-identical (`scripts/ab-gate.sh twinfang_sim` + `raid_sim
  --blade=tempo`) · speed-stacked cells assert `window ≥ window_min` and `interval ≥ base/cap`
  across seeds (`psim.sh twinfang_sim 300`) · det PASS everywhere.

### S5 · THE LAW REWORKS ✅ (small — do with S0; re-baseline expected)
NO-SINGLE-NEXT-HIT LAW (§17.12): at Tempo's tap pace a rider on "the single next strike/window"
is imperceptible — riders must cover a DURATION (~seconds) or a COUNT (X strikes). Next-DUMP
riders are fine (dumps are chosen). Fermata's hold grammar is exempt.
- `fencersLine` (built): one-shot next-window widener → **"a Bullseye widens your windows for
  the next 3 strikes"** (+15/25/35%, F19 taper stands). Cells re-baseline (real behavior change).
- `killingEdge` rig THEN fallback (A3 note): "flat next-strike bonus" → **"next 3 strikes"**.
- `grandPause` (data desc only): → **"A full-combo (5/5) Eviscerate hits +25/30/35%."** (No
  mechanic change — you can't hold more than full; Overkill's over-cap bank is a separate pot
  that rides on top.)

### S1 · D0 DECK DATA 🟡→ (needs gate ① v4 lock + gate ② trim)
- `twinfang_boons.gd`: add `theme:"wound"|"edge"|"finish"` tags to EVERY pool card (generics
  untagged); new cards — boons `lacerate` · `slowBleed` · `arterialNote` · `throughline` ·
  `quickstep` · `heavyInk` (+ `grandPause` reword from S5); creeds `openVeins` · `whetstone`
  (find the creed table via `grep -rn "largo" godot/data/twinfang/`); modules `hemorrhage` ·
  `strop` (in `twinfang_modules.gd`, Overdrive's dict shape); keystones `exsanguinate` ·
  `theCoda` + `doubleTime` REWORK → ghost-note v2 (class-generic); rig WHEN `deepcash`.
- **The wound pot** (kit state): `seat.vars["wounds"] : Array[{end_tick, tick_dmg}]` — FIXED
  iteration order (determinism); inscribe on Bullseye (creed) / Perfect (lacerate); tick in
  `update()`; Evis cash hook when `hemorrhage` held. **The KEEN meter** (strop): int stack on
  Perfect+, consumed by the next crit.
- **Trim applied** (gate ②): park `flowCap`/Momentum · `heldbreath` · one of Encore/Efficiency;
  `daCapo` leaves the open pool → Rondo door (S4). Uptempo does NOT ship as a creed (absorbed
  by the EASE dial — if EASE machinery isn't built yet, beat-speed simply isn't available:
  fine, the governor still guards the rest).
- **Gates:** undrafted byte-identical · per-build sim cells `--build=wound|edge|finish` det
  PASS + win% sane vs base · A8 EV-parity spot-check (no build >~15% dominant at equal skill).

### S2 · RESONANCE ✅ (needs S1's theme tags)
- Draft-side: count drafted theme cards where the run build lives (follow `_inject_boons`
  upstream to the run/campaign store); at **3 of a theme** set `seat.vars["res_<theme>"]=true`.
- Kit hooks (tiny, rotational): **Wound** — an expiring bleed leaves ONE extra tick · **Edge** —
  the window doesn't tighten on the beat after a crit (the old Whetstone flavor, re-homed) ·
  **Finish** — the exact-max Evis shows its phrase-mark (read cue; render debt OK to stub).
- Build-panel chip ("WOUND 3/3 — resonance"). HUD render may defer to the gauge pass (P4 base).
- **Gates:** threshold fires deterministically per seed · no-resonance runs byte-identical.

### S3 · THE DUO ✅ system (needs S1 tags; the slate per CARD-CATALOG, all 🟡 cards)
- **System:** a duo enters later offers ONLY while armed — **≥2 drafted cards from EACH of its
  two themes** (the A7 `_crit_source` offer-gating idiom); rolls in the Opus slot; distinct
  two-tone frame (draft render — flag if deferred). No run cap (prereqs + rarity gate it).
  ⚠ Duos are BOONS with kit hooks — NEVER a second rig circuit (the no-stacking law).
- **The slate:** `bloodCoda` (Wound×Finish — an Evis cashing 4+ live bleeds at full combo pays
  both ×1.15/1.25/1.4) · `redEdge` (Wound×Edge — every crit pulses ALL live bleeds one extra
  immediate tick) · `grandFinale` (Edge×Finish — a full-combo finisher with your crit build hot
  is a GUARANTEED crit, +50% crit dmg, the screen holds a half-beat on the number) · `reprise`
  (Rondo-transform×Wound — during the Return, each re-strike re-opens one expired bleed; ships
  with S4, proves transforms join the duo grammar).
- **Gates:** never offered unarmed (probe cell) · undrafted byte-identical · det PASS.

### S4 · TRANSFORMS 🟡→ (needs gate ③)
- **Ceremony:** 1-of-3 at the Floor-2 elevation (mirror the module pick / `_show_rig_wire`
  flow in `raid_hud`); ≤1 transformed ability per run; un-rerollable.
- **Kit branches** (aspect-gated guarded no-ops, byte-identical unpicked — the Brew idiom):
  `cadenza` — `_coup` gate `flow ≥ 2` (was max-only), damage scales with Flow consumed (knob
  curve; full-Flow = today's exact numbers) · `rondo` — post-Coup RETURN state: 4 beats; each
  Perfect+ re-strikes 15% (Bull 25%) of the stored Coup hit · `tremolo` — Evis string state:
  ≤3 presses, 2 cp each, per-press grade; **boon math reads the FIRST press** (grandPause /
  heavyInk snapshot); string ends on the 3rd press, an empty hand, or phrase timeout.
- **Doors:** `dalSegno` · `bravura` (cadenza) · `secondTheme` · `daCapo` (rondo) · `triplet` ·
  `rolledChord` (tremolo) — offer-gated on the transform held; rig WHEN `returnWhen` (rondo).
- **AI policy:** cadenza — legal unchanged (cash at max), better: threshold knob per tier;
  rondo — free value on existing striking; tremolo — string presses at tiered timing accuracy.
- **Gates:** unpicked byte-identical (all three) · per-transform det cells · tremolo grade
  distribution sane at @expert/@good/@sloppy.

### S6 · THE SET PIECE (signature CD) — DEFERRABLE, own claim
First signature-CD build game-wide (DECK-LAYOUT §5 slot): a baseline button (chassis-legal),
4-beat marked phrase, build-scaled flourish. New engine surface (CD framework + HUD rune) —
recommend its own claim after S0–S4 land.

## 2 · VERIFICATION MATRIX (the repo bar — per slice AND at merge-back)
`scripts/verify-all.sh` green (SEEDS=300 for governor/tremolo claims) · `scripts/ab-gate.sh`
byte-identical for every guarded-off surface · `twinfang_sim` det PASS all cells ·
`raid_sim --blade=tempo` 4 Seals det PASS · `ui_smoke_raid` 0 errors · WSLg `screenshot_*` for:
build-panel resonance chip · duo draft frame · transform pick screen · wound pot on the boss
frame (headless can't render `_draw`).

## 3 · GOTCHAS (hard-won, this build will hit them)
- `RunState` couples every kit into every sim's compile graph — never edit a kit while a sim runs.
- Wound-pot arrays + KEEN: fixed iteration order; crit rolls on `s.rng` ONLY, fixed order.
- One broken parse in a `class_name`'d file cascades ("Failed to compile depended scripts").
- `Dictionary.get(...)` into `:=` = Variant parse error.
- UI: place-then-add; `CenterContainer` for centered stacks.
- Cross-seat refs (if any duo ever goes warband-side): INDICES, never object refs.
- The governor deletes per-source clamps — expect and accept re-baselines on speed cells;
  everything ELSE must ab-gate clean.

## 4 · STATUS FLOW
Each merged slice: flip CARD-CATALOG rows ✅→🔨+SHA · tick the BUILD-LEDGER D0 row per slice ·
MASTER-PLAN Coordination Log entry. Gated slices wait for their §0 verdict — do NOT build ahead
of gate ① on branch-dependent content.
