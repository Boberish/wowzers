# FERMATA V5 — EXECUTION BRIEF (the EDGE build)

**For the implementing agent.** This is a self-contained handoff: Bill verdicted the v5 deck
(2026-07-07: everything KEEP except **Feint** CUT — "no time or reason to veto" — and
**Shadowstep** CUT — "one block card only"). Your job: make the EDGE verb + the locked slate
REAL in the kit, replacing the coded stopgaps. Design context lives in `TEMPO-PLAN.md` §13;
this brief is the build truth. Follow `CLAUDE.md` law: claim in MASTER-PLAN's Coordination Log,
work in a worktree (`git worktree add ../wow-fermata-edge -b fermata-edge`), verify, merge from
the MAIN repo dir (never `cd worktree && git merge` — see the cwd trap below), update
MASTER-PLAN after. Fresh checkout: `godot --headless --path godot --import` first.

---

## 1 · THE VERB — the Ramp & the Snap (replaces centre grading for fermata ONLY)

Current code: fermata releases are graded by `TwinfangKit._strike_grade()` — CENTRE-distance
bands shared with Tempo. Replace for fermata only; **Tempo's grading must not move**.

- A release at depth `d = (since - lo) / (hi - lo)` within the window `[lo, hi]`:
  - `d < 0` → **MISS** (released before the window) → creed slip (these creeds: −2 Flow).
  - `0 ≤ d < 0.45` → **GOOD** (×1.0 dmg, no Flow, no slip; F8 decay-pause applies).
  - `0.45 ≤ d < 0.82` → **PERFECT** (×1.6, +1 Flow, refunds — the full perfect branch).
  - `0.82 ≤ d ≤ 1.0` → **BULLSEYE** (×1.8, superset of Perfect: +bonus CP, bigger refund).
- **THE SNAP:** while coiling, the moment `coil_ticks` passes the lip (`> hi`), the note breaks
  AUTOMATICALLY (checked in the fermata upkeep or the coil-hold path — NOT on release; there is
  no dead-note state): coiling ends, **Flow crashes to 0** (base), `strike_lock_until = tick +
  tt(snap_lock 0.40)`, diag `snap`, event `{"t":"snap"}`, and the window re-rolls (same roll
  code as a resolve). Creeds override the crash (see §2). A snap is NOT a strike — no damage,
  no CP, no energy cost.
- **Unravel unchanged:** release before the SHNK (`coil_min`) = no strike, 0.35s stagger, no
  Flow loss (this is separate from and gentler than a snap).
- **The widener law:** anything that widens a fermata window extends the ENTRY side only —
  `lo` moves earlier; `hi` (the lip) and the band fractions never move. Applies to Wide Tempo /
  Fencer's Line / First Note / Shadow-Dance-adjacent effects. (Rubato shifts both edges earlier
  — that's a shift, not a widen; it's fine as-is.)
- New config (all `@export` on `TwinfangConfig`, fermata-prefixed, commented):
  `fermata_good_frac 0.45 · fermata_perfect_frac 0.37` (bull = remainder) · `snap_lock 0.40`.
- Existing geometry stays: roam (`window_shift` roll in `_strike`, s.rng, fermata-only),
  earned-near slack, the fixed 1.8s ruler, the press-relative clock (`from_release` /
  `coil_ticks` path in `_strike`), Draw/idle model, dumps instant, dodge breaks the draw.

## 2 · THE SLATE — final, post-verdict (base numbers = the Haiku rung; H/S/O ladders are
Slice-2 DESIGN — put them in the card `desc`/comments, code the base number as a knob)

### Creeds (`twinfang_creeds.gd` fermata pool — all four exist; two get reworked)
| id | change | spec |
|---|---|---|
| `patient` | **REWORK → THE LONG RAMP** | Window gains an extension past the lip: `ext = width × patient_ramp_ext (0.40)`. Releases in the extension grade BULLSEYE with an extra bonus scaling 0→`patient_deep_mult (0.20)` across it. The SNAP moves to the extension's end and is harsher: crash + `patient_snap_stagger (0.5s)` lock. Keep the far shift floor (`patient_shift_min 1.30`, already coded). DELETE the old far-fraction bonus (see §4 removals). Creed keys suggested: `ramp_ext`, `snap:"crash"`, `snap_stagger`. |
| `fleeting` | **REWORK (snap net)** | Already: `coil_min 0.20`, `flow_cap 4`, miss −2. ADD: a SNAP also loses only 2 Flow instead of crashing (`snap:"flow_loss", snap_amt:2`). |
| `longnight` | keep | Largo-mirror knobs as coded (beat ×1.35 · window ×0.7 · hits ×1.25). The tighter window = a shorter ramp = everything closer to the cliff, automatically. |
| `tutti` | keep | `_dump_beat_bonus` already reads the press-relative clock; RE-GRADE it through the new ramp function so a deep-timed dump takes the depth grade (off-window −15% via `tutti_off_mult` unchanged). |

### Modules (`twinfang_modules.gd` — both exist; one rework)
| id | change | spec |
|---|---|---|
| `shadowdance` ⭐ | **REWORK → the NO-SNAP fever** | During the Dance (3s, fill 6 sharp Perf/Bull at Flow ≥4, crash to 2 — all coded): (a) the SNAP is disabled — riding past the lip does NOT break the note; a release past the lip grades PERFECT; (b) grade floor PERFECT inside the window (exists); (c) instant sharpen (exists via `_dance_active`). |
| `mark` | keep | Bull brands I→III, Evis cashes +12%/tier — coded, unchanged. |

### Boons (`twinfang_boons.gd` FERMATA pool — final 13)
CUT from pool AND kit: **feint** (+ `feint_sharpen`, the `coil_primed` prime in `_coil_min` and
`_coil_release`) · **shadowstep** (the `on_dodge_press` keep-branch; dodge now always breaks
the draw at base — Vanish-Opus keeping the coil vs a HIT is unaffected) · **patientEdge/Deep
Edge** (the whole far-fraction path: `fermata_far_pivot/span`, `patient_edge_cap`, its branch
in `_coil_release_bonus`).

| id | status | spec (base rung) |
|---|---|---|
| `stretto` | **NEW** | Windows land nearer: effective shift = `lerp(rolled_shift, fermata_shift_min, stretto_bias 0.15)`. (S/O design: 0.25/0.35 + trim `fermata_near_slack` ×0.5/×0.) |
| `refrain` | **NEW** | A BULLSEYE holds the window: skip the shift re-roll once (`refrain_hold` flag consumed on the next resolve). (S/O design: the repeat release +10/+20% — code the flag + a `refrain_bonus 0.0` knob so the rune can set it.) |
| `coldCut` | **NEW** | A GOOD-band release grants +1 extra CP (`cold_cut_cp 1`). (S/O design: +1 CP & 4 energy / +2 CP & 4 energy — code `cold_cut_refund 0.0` knob.) |
| `theBrink` | **NEW** | Standing meter `brink`: +1 per PERFECT-or-deeper release (cap `brink_cap 5`); all outgoing damage ×(1 + `brink_per 0.03` × stacks) in `_deal` (all kinds, like a fermata Through-Line); a SNAP zeroes it; a plain miss holds it. |
| `killingWhisper` | coded ✓ | Bull +15%. |
| `restlessDark` | coded ✓ | +30% regen while drawing. |
| `quietFuse` | coded ✓ | SHNK −0.08s; Opus rune = no unravel stagger (knob exists). |
| `vanish` | coded ✓ | First hit per draw −50%; Opus keeps the coil sharp (knob exists). |
| `composure` | **NEW** | After a PERFECT-or-deeper release: Flow decay paused for `composure_sec 2.0` (set `composure_until`; the upkeep decay block skips while live). |
| `firstNote` | **NEW (replaces firstPass — DELETE firstPass)** | If the coil press comes ≥1.5s after the previous resolve (`s.tick - last_strike_tick ≥ tt(1.5)`), that draw's window entry extends: `lo -= width × first_note_pad (0.20)` (clamped to the coil floor; the lip fixed). Consumed on resolve. The old `firstPass`/`first_pass_widen`/`first_pass_ready` are degenerate under the Draw — remove entirely. |
| `twinEcho` | coded ✓ | Max-Flow releases echo 30%. |
| `firstBlood` | **VERIFY — likely NOT implemented** | The FERMATA pool lists it but the kit may have no logic. Implement: after any miss/snap/unravel set `first_blood_ready`; the next release grades at least PERFECT (consume flag). (S/O design: +1 CP / auto-BULL.) |
| `veilWarband` | coded ✓ | Publishes `veil_warband_active` (party application still owed elsewhere). |

### Rig (`twinfang_rig.gd` — fermata WHENs)
- **DELETE `onedge`** (rewards the safe shallow release now — pays spam).
- **`deepcoil` → `rested`** ("The Rested Draw"): fires on a coil PRESS that comes ≥1.5s after
  the previous resolve (same test as First Note — share the helper). Suggested mult 2.4.
- **NEW `razor`** ("The Razor"): a release within `razor_sec 0.05` BEFORE the lip. Rare by
  nature → mult 6.0 (the inverse-frequency law).
- **`unravel`** keep as-is. (With Feint cut it only fires on accidents — accepted.)

### Keystones (elite-pool; draftable via boons dict for sims)
| id | change | spec |
|---|---|---|
| `unseenBlade` | **REWORK → rest-bank** | Shades accrue while IDLE (not coiling): 1 per `unseen_shade_every 0.7s`, max 5; the next release spends all (+6% each — the spend half is coded; MOVE the accrual from the coiling branch of `_fermata_upkeep` to the idle path). |
| `eclipse` | **REWORK (near-chain)** | On a sharp Bull: instant re-coil already sharp (coded) AND the chained window lands NEAR — after the shift roll, override `window_shift = fermata_shift_min`. |
| `phantom` | coded ✓ | Bull = phantom twin at ×1.0. |

### Carries — verify only
Hone/Heartseeker/Serrated/Assassin's Note, Crescendo, Da Capo, Understudy, Efficiency, Wide
Tempo / Fencer's Line / Rubato: confirm each still compiles against the ramp (wideners must go
through the entry-only rule). No new code expected.

## 3 · CODE MAP (file → work)

- `godot/data/twinfang/twinfang_config.gd` — add/remove knobs per §1–2. Every number a
  documented `@export`; no literals in the kit.
- `godot/data/twinfang/twinfang_kit.gd` — the core: fermata ramp grading (branch inside
  `_strike` where `from_release` — compute depth vs `[lo,hi]`, map to the existing
  G_GOOD/G_PERFECT/G_BULL flow so ALL downstream branches — refunds, Flow, CP, hone, rig,
  modules — keep working); the SNAP check while coiling; patient extension in `_edge_window`
  (fermata block) + deep-lip bonus; First Note entry-pad; refrain hold; stretto bias at the
  shift roll; eclipse shift override; brink meter in `_deal` + reset on snap; coldCut CP;
  composure gate in the upkeep decay; firstBlood floor; unseenBlade accrual move; ALL removals.
- `godot/data/twinfang/twinfang_creeds.gd` — patient/fleeting reworked keys + blurbs.
- `godot/data/twinfang/twinfang_modules.gd` — shadowdance blurb.
- `godot/data/twinfang/twinfang_boons.gd` — pool edits (cut 3, add 6, retitle), plain-language
  descs with H/S/O ladders in the text.
- `godot/data/twinfang/twinfang_rig.gd` — WHEN table edits.
- `godot/sim/policies/twinfang_policy.gd` — depth-aim: `target = lo + (hi−lo) ×
  clamp(0.88 − 0.02×latency_ticks, 0.55, 0.90)` (+ the existing latency smear). Expert rides
  the bull band with rare snaps; sloppy sits mid-ramp. Verify the gradient in the sim.
- `godot/data/twinfang/twinfang_kit.gd observe()` — publish `fermata_ramp: true`, the fermata
  band fractions, the patient extension (`ramp_ext_hi` tick when active), dance-no-snap state.
- `godot/game/ui/rhythm_bar.gd` — fermata band layout: stacked GOOD→PERFECT→BULL rising to the
  lip; bold cliff line (crimson + white hairline) at the lip; NO centre plumb for fermata;
  extension zone (patient) drawn amber past the lip; the cliff line hidden/dimmed during the
  Dance (fearless read); SNAP verdict flash ("SNAPPED — too deep"); "RIDE IT — deeper pays"
  cue while sharp-in-window. Feed via `raid_hud._update` like the existing coil fields.
- `godot/sim/twinfang_sim.gd` — update `_prove_fermata`: cells for patient/fleeting/stretto/
  refrain/coldCut+brink/composure+firstNote/keystones; report `snaps/run` and `s_bull` per
  skill; keep both determinism lines.
- `godot/sim/fermata_input_check.gd` — update: deep sharp release = dmg; pre-window release =
  miss; **hold past the lip = auto-SNAP** (new assertion: no damage, flow 0, diag snap+1);
  roam assertion stays.
- `godot/sim/screenshot_fermata_raid.gd` — re-run as-is (idle/charging/sharp), plus one shot
  mid-window so the ramp bands + lip are visible. VIEW the PNGs (WSLg, never --headless).

## 4 · ORDER OF WORK (gate between each slice)

1. **Verb slice**: ramp grading + snap + config + input_check update → run input_check + the
   two determinism lines. GATE: Tempo `4932869838389671587` / Venom `7876031242436484463`
   on the Warden/Executioner determinism lines MUST match main byte-for-byte.
2. **Creeds/modules**: patient long-ramp, fleeting snap-net, dance no-snap → sim creed cells.
3. **Boon cuts + adds** (feint/shadowstep/deepEdge out; stretto/refrain/coldCut/brink/
   composure/firstNote in; firstBlood verify) → sim boon cells + fat-build determinism.
4. **Rig + keystones + policy depth-aim** → full `twinfang_sim --seeds=40`, then
   `raid_sim --blade=fermata --boss=mistral` det PASS, `ui_smoke_raid` 0 script errors.
5. **HUD slice** (rhythm_bar ramp + snap flash) → screenshots, VIEW them.
6. Merge (from the main repo dir), MASTER-PLAN log entry, tick TEMPO-PLAN §13 banner.

## 5 · VERIFICATION MATRIX

```
godot --headless --path godot --script res://sim/fermata_input_check.gd      # all PASS incl. SNAP
godot --headless --path godot --script res://sim/twinfang_sim.gd -- --seeds=40
  # gates: Warden/Tempo checksum 4932869838389671587 · Venom 7876031242436484463
  #        base+fat fermata determinism PASS · expert bulls high + snaps low · sloppy snaps > 0
godot --headless --path godot --script res://sim/raid_sim.gd -- --blade=fermata --boss=mistral --seeds=5
godot --headless --path godot --script res://sim/ui_smoke_raid.gd            # 0 SCRIPT ERROR (col_std pre-existing)
godot --path godot --rendering-driver opengl3 --script res://sim/screenshot_fermata_raid.gd -- --out=<dir>
```

## 6 · GOTCHAS (hard-won — read before coding)

- `_strike` is SHARED with Tempo/Venom: every new branch must be gated `from_release` or
  `_fermata()`. The two checksums above are the tripwire.
- The shift roll draws from `s.rng` INSIDE `_strike` — keep the draw order stable; new fermata
  draws are fine (fermata-only stream) but never add a draw on the tempo path.
- GDScript: `Dictionary.get(...)` into `:=` = Variant parse error; one broken parse in a
  `class_name` file cascades ("Failed to compile depended scripts").
- Bulk text edits: bash heredocs mangle em-dashes — write a `.py` to the scratchpad and run it.
- Never edit ANY kit while ANY sim runs (RunState couples the compile graph).
- Worktree: commit inside it, then merge from `/home/bill/projects/Wowzers` — chaining
  `cd worktree && git merge` resets cwd and has bitten before.
- Headless can't render `_draw` — screenshots need WSLg.
- Probe scripts start at frame 1 of `_process`, not `_initialize`.

## 7 · OUT OF SCOPE (owed elsewhere — do NOT build here)

Brink/Shade/Mark/Dance HUD meters (raid_hud gauge pass) · shadow-dim while coiling · keystone
ELITE acquisition (Topology elite node) · Veil warband APPLICATION (raid buff channel, with
Battle Hymn) · online spec-carry `(seed, spec)` · Slice-2 rarity engine (H/S/O rolls + runes).
