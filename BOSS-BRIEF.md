# BOSS-BRIEF — the Seal-rework build brief: THE FOUR FIGHTS (v1, 2026-07-10)

**What this is.** The implementation plan for **THE SEAL REWORK** — the whole BOSS-PLAN build
(engine addenda E1–E9 · SealTune · sim instrumentation · the four re-authored Seal fights ·
HUD widgets · the kick re-tune), written for the session that BUILDS it (Bill: *"make a plan
to implement this… after will hand it off to Opus"*). Design of record: **`BOSS-PLAN.md`**
(§0 laws · §1 aggro/taunt-delete · §1½ kick contract · §2 SealTune · §3 density ramp · §4
visual lanes · §6 fight scripts · §7 addenda · §V verdicts) · `DESCENT-PLAN.md §4` (the timer
contract) · `TANK-PLAN.md §1b/§1c` (the tank grammar + flow-aggro the fights author against) ·
`DUELIST-BRIEF.md` (Wave 1 — the flow/peel/taunt-funeral engine this build CONSUMES, never
re-implements) · collisions: `BUILD-LEDGER.md §0/§F`. Work in a worktree
(`git worktree add ../wow-seals -b seal-rework`), merge main OFTEN, gate every slice.
⚠ Line numbers in this brief drift with concurrent merges — **grep the symbol, never trust
the number.** Fresh worktree: `godot --headless --path godot --import` FIRST.

## 0 · SCOPE GATE — what's OPEN vs what BLOCKS (state as of 2026-07-10 · pass 5 — tank-w1 recon)

**✅ GATE ③ CLEARED — ALL 11 VERDICTS DECIDED** (Bill, 2026-07-10: *"v1–10 is build with your
recs"* + V11(b)). The RECOMMENDED option of every verdict is now the build spec (BOSS-PLAN §V
record). S2–S5 author the recs directly — no per-slice verdict lookups needed.

**✅ S0 BUILT & gate-clean** on `seal-rework` (`d8bc675`, byte-identical, det PASS ×4; baseline
in MASTER §BOSSES). Reconcile note (§1a below): S0 re-applies on the union with a trivial
`raid_sim.gd` merge (tank-w1 renamed the band's `taunts` col → `peels`; keep that + the S0
`inst_by_skill`/`_accum_inst`/`_print_instrumentation` additions — they're in different funcs).

**✅ GATE ① CLEARED** — the DESCENT map bang + fight ladder are in main (`a59ffa4`/`cf3f8d9`).

**⛔ THE ONE REMAINING GATE — the UNION BASE (tank-w1 ⊕ new-main).** tank-w1 is **COMPLETE
(Bill, 2026-07-10 — "just doing sims to verify")** but **NOT merged, and forked from an OLDER
main** (merge-base `c6738ff`). So neither base alone is buildable: new-main has the descent
fight-ladder but no flow engine; tank-w1 has flow but lacks new-main's +62-line `combat_core`
change (descent/meter/tempo) + the descent `raid_content` ladder. **S1's addenda edit
`combat_core` → they need the UNION.** The union forms when **tank-w1 merges main → lands in
main** (the tank session's own reconcile — do NOT front-run it in `seal-rework`; that
duplicates the drift-merge and risks divergence). **The moment tank-w1 is in main: rebase
`seal-rework` onto main, re-apply S0, and S1–S5 run turnkey off §1a.**
- Verified conflict-free once the union exists: **tank-w1 touches `raid_content.gd` only for
  party naming** (Bulwark→Duelist tank fixture), NOT the `make_*` Seal builders → S2–S5 content
  collides with neither tank-w1 nor descent (different regions of the file).

**BUILD ORDER (post-union): rebase seal-rework → reconcile S0 → S1 (E1–E9 addenda, one merge)
→ S2 → S3 → S4 → S5 → S6 → S7 (rides the first class `interrupts` flag).** Each of S2–S5 is
its own deliberate re-baseline — **untouched Seals must stay byte-identical per slice.**

### 0a · RESOLVED BLOCKS — the real tank-w1 APIs S1/S5 hook into (recon 2026-07-10)
Every engine block this brief flagged is BUILT in tank-w1 (worktree `../wow-tank-w1`), and
cleaner than assumed. Build against THESE names, not the placeholders in older brief text:

| Block (was) | RESOLVED in tank-w1 — the real API | Used by |
|---|---|---|
| flow state | **`seat.vars["flow"]`** (0..1) on the tank seat; `CombatCore._flow_aggro(s)` reads it (0 if no tank) | S5 Compaction · aggro accounting |
| boss focus | **`CombatCore._threat_target(s)`** — pure read of flow, NO rng (kept by name; safe to call often) | HUD/observe · content |
| the peel roll | **`CombatCore._aggro_peel(s, base)`** — per-attack rng (`s.rng.next_float()/next_u32()`, fixed order), guarded by `s.threat_enabled`; called at `combat_core.gd:240` (melee victim) + **`:1237`** (targeted-strike victim = "the peel path") | **E5 mark relay · E7 LISTENING counter** route a hit onto a chosen victim by reusing this selection |
| flow config | `TuningConfig`: **`flow_lock_floor 0.30`** · `flow_gain_perfect .10`/`good .06`/`graze .02` · `flow_slip .14` · **`flow_spike .20`** · `flow_decay .05`/s | SealTune (E4) may per-Seal-override; **V#9 valve = `flow_spike`, ALREADY BUILT** |
| taunt | **DELETED** — `taunt_seat_i`/`taunt_until_tick`/`taunt()`/`use_challenge` gone; no taunt-back anywhere | — (the §1 contract, done) |
| THREAT_DROP → FLOW DUMP | **ALREADY re-based** (`combat_core.gd` ~`:426`): `Effect.THREAT_DROP` resolve zeroes `tk.vars["flow"] = 0.0` + `curse_dropped` diag + `threat_drop` event | **S5 Context Compaction just USES `Effect.THREAT_DROP`** (the `_curse` builder) — ZERO new code |
| melee-victim accounting | `_note_melee_victim` + `s.boss.last_melee_victim_i` (diag `stray_hit`/`aggro_pulled`, never checksummed) | S0 already reads `aggro_pulled` (renamed `peels` col) |
| party fixture | tank seat = `DuelistKit`/`DuelistPolicy`, `vars {flow, wind, combo}` (Bulwark retired to a sim/gear fixture) | sim comp — no content dependency |

**Consequence for the slice specs:** S5's "re-point `_curse` resolve … to `flow = 0`" is
**already done** — Mythos Compaction = a normal `_curse` with `Effect.THREAT_DROP`. E5/E7 route
their personal hits via **`_aggro_peel`-style victim selection at `combat_core.gd:1237`**, not a
new peel subsystem. The V#9 flow-spike is a config knob that already exists — nothing to build.
S1 still owns E1 (gate filter) · E2 (stance) · E3 (BREAK) · E4 (SealTune) · E6 (deny-empower) ·
E8 (kick-window) · E9 (pips) on the union `combat_core`.

---

## 1 · SLICES

### S0 · SIM INSTRUMENTATION (byte-identical — absorbs SEAL-PILLAR Phase A)
All in `sim/raid_sim.gd` (+ `sim/sim_util.gd` helpers if shared). ZERO engine files. Print,
per Seal per skill tier:
1. **Beat-budget table** per seat (tank/blade/caster/healer): `presented`
   (perfect+good+graze+miss), each grade, feints (baited+read) — aggregate `seat.diag`
   (`CombatCore._bump_diag` feeds it; see `combat_core.gd` grep `_bump_diag`).
2. **Per-source cast counts** — count sim-side by watching `state.telegraph` transitions in
   the sim step loop (id of `telegraph.src`); do NOT add engine counters.
3. **TTK line vs contract**: measured good-tier median TTK vs target (V 300 s · M 420 · G 540 ·
   MY 720), flag `⚠ OFF-TARGET` outside ±20%. Report line, not a hard fail (until Bill locks).
4. **Act/valley timeline**: tick-stamps of phase flips / add spawns+deaths / (later: stance
   flips, breaks, act gates — the fields land in S1; print what exists now) + valley % (ticks
   with a no-strike telegraph or PACK walk-in / total).
5. **Verse table** (§1½ gate): per verse-id — casts · landed · kicked (0 until the class flag
   exists) · per-seat answer coverage. Wire now, reads zeros now, S7 flips it live.
**Gate:** determinism probes PASS ×4 Seals AND checksums byte-identical to pre-change (print
cannot move state — if checksums moved, you touched something). Record the baseline tables in
MASTER §BOSSES. ⚠ 7 GB box: concurrent verify-alls OOM-kill sims → phantom FAILs; re-run solo.

### S1 · ENGINE ADDENDA E1–E4 + E6 + E8 + E9 (one merge, byte-identical)
All guarded: **flag absent ⇒ identical behavior, checksum-neutral.** Prove with the full sim
surface + `scripts/ab-gate.sh` per sim. New RNG: NONE in this slice (E5's re-roll at S5 is
the only new draw in the project — see there). Sites by symbol (all `core/combat_core.gd`
unless said):

- **E1 · Gated ability sets.** `AbilityRes.gate: Dictionary = {}` — keys `phase_from:int`
  (eligible when current phase index ≥ N; pair with `phase_until`), `stance:int` (eligible
  when `boss.stance == N`), `featured:bool` (eligible when this gate's `stance ==
  boss.featured`). Filter in `_boss_think`'s pick loop (grep `danger and not best`): skip
  ineligible abilities in the PICK only — **timers tick regardless** (dormant-then-due is
  handled by `re_stagger`, E4). Empty dict ⇒ always eligible (no allocation on the hot path —
  check `gate.is_empty()` first). `BossState.stance:int = 0` + `featured:int = -1`; both join
  the checksum sum (0/-1 baseline contributes a constant — verify byte-identity on ALL
  existing content, incl. net_smoke string checksums).
- **E2 · Stance cycler.** `AbilityRes.Effect.STANCE_SHIFT`: on resolve in `_resolve_telegraph`
  → `boss.stance = (boss.stance + 1) % enc.stance_count` (`EncounterRes.stance_count:int=0`),
  banner = ability name, short cast (~4 s, the stance-turn valley), no strikes. Deterministic
  via its own cd (= `SealTune.stance_period`). V#4(c) variant (clean-answer nudge): subtract
  ticks from its timer on PERFECT grades — build ONLY if Bill picks (c).
- **E3 · BREAK (dialogue curtain).** `Effect.BREAK`: long cast (SealTune `break_len`), no
  strikes, resolve = no-op; new `AbilityRes.script_lines: PackedStringArray` (display-only —
  NEVER in checksum, NEVER read by `update()` logic). Freezes ability timers by existing
  telegraph semantics — that IS the curtain. HUD renders the letterbox card off
  `telegraph.src.effect == BREAK` (see §5). Trigger at act gates via E1 `phase_from` + a
  one-shot cd trick (cd ≥ fight length so it fires once on unlock).
- **E4 · SealTune.** `EncounterRes.tune: Dictionary = {}` — keys per BOSS-PLAN §2 (`hp_mult
  dmg_mult cd_mult melee window_mult phase_fracs act_gates stance_period break_len beats_scale
  kick_window kick_window_mult verse_miss_mult enrage_at enrage_visible re_stagger`). Apply in
  ONE place: `RaidContent._apply_tune(e)` post-build (scale hp/amounts/cds/melee/enrage;
  neutral defaults = no-op — prove byte-identity with tune absent AND with explicit-neutral
  tune). `window_mult`: one multiplier where boss strikes grade (grep `_strike_mult` /
  `_answer_strike`), default 1.0. **`re_stagger`**: after any BREAK / STANCE_SHIFT / act-gate
  unlock, re-stagger all due ability timers (the same math as `create_state`'s opener stagger
  — grep `stagger`) so banked timers don't burst-train the instant the scheduler frees
  (engine-inventory gotcha). `tune.sh`: add `--bosslen= --bossdmg= --bosscd= --stance=
  --break= --kickwin=` pass-through to a runtime overlay on `make_state`.
- **E6 · Deny-race empower.** During an `EMPOWER_BOSS` (or absorb-beat) cast: accumulate
  damage dealt to the boss in `BossState.deny_dmg` (reset at cast start in
  `_start_telegraph`); on resolve, `buff *= clamp(1.0 - deny_dmg / deny_denom, floor, 1.0)`
  (`AbilityRes.deny_denom/deny_floor`, absent ⇒ multiplier 1.0 = today). Pure accumulation,
  no RNG.
- **E8 · Kick-window slice.** `AbilityRes.kick_window: float = 0.0` — a kick lands ONLY when
  `remaining_cast ≤ kick_window` (0.0 = whole-cast kickable = legacy, byte-identical). The
  accept site is the existing kick path (grep `INTERRUPTIBLE` / `stagger_boss`) — the
  class-side `interrupts` press is NOT this build (it lands with class reworks; DUELIST-BRIEF
  / TEMPO own it). Castbar renders the lit slice (§5).
- **E9 · Charge-counter pips (Batch Job).** `AbilityRes.pips: int = 0`: during the cast,
  every PERFECT grade by any seat decrements `telegraph.pips_left` (init = `pips`); on
  resolve, scale the payload — fire only the last `pips_left` strikes of the string (or
  `amount × pips_left / pips` for single-hit). Grades are already deterministic state — no
  RNG. Banner renders pip chips (§5). 0 ⇒ no-op.

**Gate:** import clean · ALL sims byte-identical (`verify-all` + `ab-gate.sh` on raid_sim,
twinfang_sim, alchemist_sim, well_sim, forge_sim) · `raid_probe` extended with one assert per
addendum (gate filters · stance wrap · BREAK freezes+resolves clean · tune neutral no-op ·
deny clamp · kick_window accept/reject · pips decrement+scale) · net_smoke (checksum strings
unchanged on existing content).

### S2 · VORATHEK v2 — THE AXE (first content re-baseline; proves the whole grammar)
`data/raid/raid_content.gd make_riftmaw()` re-author + `FLOORS`/entry wiring intact.
- **Cuts (V#2):** Riftrot (`_dot` riftrot) + Baleful Curse (`_curse curse`) OUT (comment-park
  with a `# 🔮 parked (BOSS-PLAN V#2)` marker; ids retired from the fight, not renamed).
- **Keeps:** crush/rend talls · volley (3 beats, wide windows) · cataclysm nova.
- **NEW — Devouring Chant v2 (V#11b, the kick kindergarten):** un-chained `_chant`
  (`HEAL_BOSS`, INTERRUPTIBLE), cast 4.0 s, cd ~100±10 (≈2 casts/fight), `kick_window` = base
  0.6 × **1.5** (widest in the raid). **INTERIM heal (uncontested era): ~1700 (~3% of pool)**
  — the shape teaches, the sting waits; S7 raises it to ~8% ("restoring from checkpoint" —
  the felt chunk). Wordless growl-cast: `tag="Stop generating!"` stays, no script_lines.
- **NEW — Overload Slam (S3 steal):** windup 3.0 s → ONE near-lethal aoe beat (frac 1.0,
  CRUSH, `danger`) → **STUN ~4 s = a BREAK-shaped no-strike follow-up** in a 2-link chain
  (windup+beat, then the stun link) rendering as a printed OPENING (the warband dumps).
  cd ~45±4. Uses E3 mechanics with an OPENING banner skin, not dialogue.
- **Structure:** walk-in pack ON for the Seal node (2 riftspawn via the existing packroll
  lightweights — `_roll_map_pack` currently EXCLUDES the Seal; add a Seal-pack opt-in flagged
  per-encounter, default off = byte-identical elsewhere) · **add wave @60%** `_add_wave(0.6,
  "broodmaw", …)` hp ~2600, melee light, ONE 2-beat aoe string · P3 @30%: speed 1.2 + Volley
  gains a 4th beat via E1 `phase_from:2` on a `volley4` variant (S14 accretion; `volley`
  gets `phase_until:2`).
- **First-cut numbers:** hp 38750 → **~56000** · melee {1.15, 34, 44} · enrage 390 s (hidden,
  `enrage_visible:false`) · phases 1.0/0.6/0.3, mult 1.0/1.15/1.3, speed 1.0/1.1/1.2. Chant
  heal rides `verse_miss_mult`.
- **Targets at gate:** TTK good ≈ 300 s ±20% · non-tank beats 3–5 · valley ≥25%.
**Gate (every content slice):** determinism ×4 · **Mistral/Gemini/Mythos byte-identical**
(`ab-gate.sh raid_sim -- --boss=<seal>` each) · fresh 300-seed bands via
`scripts/psim.sh raid_sim 300 8` recorded in MASTER §BOSSES (Vorathek stays the ~100/100/~97
teaching Seal) · S0 tables within targets · `ui_smoke_raid` · `net_smoke` · WSLg screenshot
tour of the fight (banners, stun-Opening, add walk-in — headless can't `_draw`).

### S3 · MISTRAL v2 — THE EXPERTS
`make_mistral()` re-author. `stance_count = 3`, `stance_period` ~80 s (V#4 rec: timed).
- **Experts via E1/E2:** every ability gains `gate.stance` — **FISTS (0):** flurry strings
  (new `_tank_string` flurries, small/normal bars, WEAVE/HOLD food) + `mist_fists`
  rand-barrage · **WEIGHTS (1):** `mist_compress` CRUSH talls, slow + **mirror-read**: dumps
  into its windup are "quantized" — reuse E6 accumulate to print a `QUANTIZED` floater and
  reduce (never reflect) · **ROUTER (2):** rand-target singles announced per-victim (peel
  grammar rehearsal). STANCE_SHIFT ability = "Routing…" (~4 s turn).
- **Batch Job (E9):** cast 6.0 s, `pips 3`, payload = 3-beat aoe string, cd ~70±6. Perfects
  visibly defuse it.
- **Verse:** License chain (2 verses, the first CHAIN) — `kick_window` ×1.25 · INTERIM
  amounts as today (26/30); S7 raises the landed blast to fight-biggest.
- **Enrage VISIBLE (S5 steal):** `enrage_visible:true` → HUD counts down "FREE TIER: M:SS".
- **First cut:** hp 33750 → **~95000** (⚠ the one structure-light growth — the re-texture
  cadence carries it; if playtest reads sponge, the release valve is a LE CHAT cameo add,
  flag for Bill, don't build) · melee {0.95, 34, 44} · enrage 540 s · phases 1.0/0.55/0.25 +
  MIXTURE act @0.25 via E1 `phase_from` (experts interleave: drop stance gates on a final-act
  variant set). TTK ≈ 420 s ±20% · beats 4–6.
**Gate:** as S2 (+V/G/MY byte-identical · stance-sigil + countdown WSLg shots).

### S4 · GEMINI v2 — THE TWINS
`make_gemini()` re-author. `stance_count = 2` (FLASH 0 / PRO 1), `stance_period` ~70 s.
- **Voices via E1/E2:** FLASH = paired light beats (2-beat strings, tight spacing) + A/B Test
  (paired victims — two `rand_target` beats back-to-back, "cohort A/B" tags) · PRO =
  `gem_hammer` talls + **Double-Check kept verbatim** (SEAL-PILLAR carve-out; it GROWS one
  beat in act 3 via a `phase_from` variant — S14).
- **MODEL PROMOTION (V#5 rec: seeded):** at the 50% act gate, roll `boss.featured =
  state.rng` draw (⚠ THE one new RNG draw of S4 — inside `update()`, at the gate resolve,
  fixed order; document it in the slice log). Featured voice's abilities get `gate.featured`
  variants: +1 beat, windows ×0.9, cd ×0.85. Banner "MODEL PROMOTION".
- **Mini-BREAK (V#6 rec):** E3, ~8 s, script_lines = the AI-Overview gag, at the 50% gate
  (fires before the promotion banner).
- **Adds ×2:** BARD @72% (hp ~5200, kept kit) · **BARD-redux @30%** (hp ~6000, sonnet cd
  11→9, melee +15% — "un-deprecated. It is not happy.").
- **Verse:** Overview 3-chain + Merge (E6 deny-race on the Merge: `deny_denom` ~4000,
  floor 0.5) — `kick_window` ×1.0 · INTERIM Merge buff 0.10; S7: 0.12 + the blast re-tune.
- **Armed-banner doubles (S8 steal, act 3):** decoy banner is VIEW-ONLY (a second banner
  drawn from `AbilityRes.decoy_name` display field; no state) — the armed one is the live
  telegraph; existing feint grading punishes wrong presses. Zero engine.
- **First cut:** hp 41250 → **~85000** · melee {1.10, 27, 37} · enrage 690 s · phases
  1.0/0.6/0.3 + act gates 0.72/0.5/0.3/0.25. TTK ≈ 540 ±20% · beats 5–7.
**Gate:** as S2 (+ promotion determinism: same seed ⇒ same featured voice, assert in
`raid_probe`; break-card + NOW-SERVING sigil WSLg shots).

### S5 · MYTHOS v2 — THE THREE ACTS (+ E5/E7 if V#7/V#8 land as rec'd)
`make_mythos()` re-author onto E1 act sets (acts 1.0 / 0.65 / 0.32 — phases become acts;
keep mult/speed mild inside acts, the SET change is the escalation).
- **ACT I HELPFUL:** align/probe talls · CoT 3-chain (`kick_window` ×0.85 — the exam; E6 on
  the Conclusion, INTERIM buff 0.12) · Fan-Out light (3-beat variant, `phase_until:0`).
- **CURTAIN 1 (E3, ~12 s, @0.65)** → SONNET wave (hp ~3200; `sonnet_tools` flipped
  `rand_target` per SEAL-PILLAR's own note).
- **ACT II HARMLESS:** **LISTENING (E7, V#7):** `boss.listening_until` — while live, any
  OFFENSIVE input (ability/dump `perform()`) queues a telegraphed personal counter onto the
  presser via the peel path; defensive answers stay legal (melee still ticks on the tank —
  the lock is offense-only; expose `hold_offense` in `observe()` for policies). ~6 s, ~2/act.
  · **THE ESCALATION (E5, V#8):** `boss.mark_seat_i/mark_until/mark_fuse` — an `Effect.MARK`
  cast starts it; every ~6 s the marked seat gets a HANDOFF beat on their own dodge bar
  (peel-path render + grace); answered in-window ⇒ re-roll target (state.rng, fixed order,
  exclude current — the S5 new draws, document) + fuse resets; missed ⇒ detonation (big
  personal hit + raid splash). One relay per act II/III. · **ULTRATHINK untouched** (id, 3
  beats, 42±4 — verbatim; the marquee). · absorb-beat at each act gate (E6-shaped invuln
  ~3 s, deny shrinks the incoming act's mult).
- **CURTAIN 2 (E3, ~15 s, @0.32)** → OPUS wave (hp ~4200; **Hotfix INTERIM heal +540 as
  today**; S7: ~7% pool — the raid's worst miss).
- **ACT III HONEST:** melee → {0.90, 26, 36} · Fan-Out full 5 beats (`phase_from:2`) ·
  **Context Compaction = FLOW DUMP — a normal `_curse` with `Effect.THREAT_DROP`; the flow-zero
  is ALREADY built in tank-w1** (§0a — `combat_core` resolve zeroes `tk.vars["flow"]`), so this
  is pure data authoring, no engine change · enrage VISIBLE "USAGE LIMIT" · CoT double-time
  (cd ×0.8 variant).
- **First cut:** hp 47500 → **~92000** · enrage 900 s. TTK ≈ 720 ±20% · beats 6–8 +
  ULTRATHINK exception.
**Gate:** as S2 (+ relay/LISTENING probes: mark passes deterministically, offense-lock
queues exactly one counter, curtain re_stagger holds; full act WSLg tour; net_smoke with a
mythos fight — new state fields ride the checksum, both replicas identical).

### S6 · THE CROSS-RAID SWEEP + the record
Run the full descent context: packs-on-floors + retightened enrages + all four v2 Seals.
`psim.sh raid_sim 300 8` per Seal + combined · `twinfang_sim`/`alchemist_sim`/`well_sim`
still green (RunState coupling — you touched no kits; prove it) · `verify-all` (SEEDS=300)
ALL GREEN · record the band table + S0 tables + knob values in MASTER §BOSSES · re-pin
`ab-gate.sh` baselines · flip ledger rows 🔨+SHA · BOSS-PLAN §V statuses → the record.

### S7 · THE KICK RE-TUNE (rides the FIRST class-side `interrupts` flag — whenever a class
rework lands it; coordinate, don't build the flag here)
Flip `verse_miss_mult` to the §1½ ladder finals: Chant heal ~3%→**8%** · License blast →
**fight-biggest** · Merge buff →0.12 stacking re-check · Hotfix +540→**~7% pool** · window
mults finalized (V 1.5 / M 1.25 / G 1.0 / MY 0.85 × base 0.6 s) · S0 verse table goes live:
targets **accidental <10% · deliberate >85%** at good tier (WORLD-PLAN numbers; with
early-press-fires-as-dump, accidental should read ≈0) · AI policies hold dumps for lit
windows (tier-gated accuracy — sloppy AI misses kicks, that's comp texture) · fresh bands.

---

## 2 · FIRST-CUT NUMBERS (one table — everything SealTune-loose, tune.sh converges)

| | VORATHEK | MISTRAL | GEMINI | MYTHOS |
|---|---|---|---|---|
| TTK target (good) | 300 s | 420 s | 540 s | 720 s |
| hp (from → first cut) | 38750 → 56000 | 33750 → 95000 | 41250 → 85000 | 47500 → 92000 |
| melee {every,min,max} | {1.15,34,44} | {0.95,34,44} | {1.10,27,37} | {1.00,26,36}→{0.90,…} act III |
| enrage (visible?) | 390 s (no) | 540 s (**yes** "FREE TIER") | 690 s (no) | 900 s (**yes** act III) |
| phases / acts | 1.0/.6/.3 | 1.0/.55/.25 + MIXTURE@.25 | 1.0/.6/.3 + gates .72/.5/.3/.25 | ACTS 1.0/.65/.32 |
| stance_count / period | — | 3 / ~80 s | 2 / ~70 s | — (acts instead) |
| adds | pack 2×riftspawn + broodmaw 2600@60% | none (valve: LE CHAT cameo — Bill-gated) | BARD 5200@72% · redux 6000@30% | SONNET 3200@65% · OPUS 4200@32% |
| verses (kick_window ×) | Chant ×2 casts (×1.5) | License 2-chain (×1.25) | Overview 3-chain+Merge (×1.0) | CoT 3-chain + Hotfix (×0.85) |
| interim → S7 miss cost | heal 3% → 8% | blast 26/30 → fight-biggest | Merge .10 → .12 + blasts | Hotfix 540 → ~7% pool |
| breaks (E3) | stun-Opening only | none | mini 8 s @50% | curtains 12 s@65 · 15 s@32 |
| beats/non-tank | 3–5 | 4–6 | 5–7 | 6–8 + ULTRATHINK |

## 3 · HUD SLICE (rides each content slice — `game/raid_hud.gd` COMBAT region + `game/ui/`)
New widgets, all view-only, each lands with the Seal that first uses it: **castbar lit slice**
(kick_window fraction highlighted, S2) · **stance sigil** (chip by the boss plate, palette
tints banners, S3) · **countdown pips** (E9 chips + enrage-visible M:SS, S3) · **break card**
(letterbox, script_lines paged, S4) · **mark fuse** (pip chain on the marked frame + handoff
beat, S5). Rig: stance/act flips = PoseRig pose+palette swap; adds enter on the walk-in idiom.
⚠ `raid_hud.gd` collision: `tempo-art` owns the post-fx node in the combat region — merge
main often, keep widgets in their own nodes. Every widget: WSLg screenshot probe before merge
(headless can't render `_draw`). Esc stays HOME (`_show_home`), never a scene change.

## 4 · VERIFICATION MATRIX (per slice AND merge-back)
`scripts/verify-all.sh` (nonzero on ANY fail; SEEDS=300 at S6) · `scripts/ab-gate.sh <sim>`
vs PINNED baseline (concurrent merges can't false-diff you) · determinism ×4 Seals every
slice · **untouched-Seal byte-identity per content slice** · `raid_probe` grows one assert
per addendum · `ui_smoke_raid` + `net_smoke` (content shifts fight checksums ON PURPOSE —
both replicas share the commit; protocol untouched, no version bump; grep "SCRIPT ERROR" on
solo runs, "ALL OK" tails lie) · WSLg visual tour per new surface · bands: keep expert ≈100
and the M→G→MY curve order; sloppy Mythos must still lose hard (≤50). Gate on determinism +
tables + curve ORDER, not ±pp (blade seat mid-rework).

## 5 · GOTCHAS (wave-specific + hard-won)
- **One live telegraph EVER** — chains/BREAKs freeze the whole roster their entire length;
  melee never freezes; **adds can't spawn mid-cast** (`_update_form` gates on
  `telegraph == null`) → order act-gate content: curtain resolves, THEN the wave's `at`
  crosses. Check every act boundary for this ordering.
- **Banked burst-train:** overdue abilities queue and fire back-to-back the instant a long
  cast/BREAK clears — `re_stagger` (E4) after every curtain/stance/act flip, and verify in
  the S0 timeline that no post-break tick fires >1 ability.
- **Array order is an implicit priority** beneath `danger` in the pick loop — author each
  `abilities` array intentionally; document order in the builder comment.
- **New RNG draws** (S4 promotion, S5 relay re-roll): `state.rng` inside `update()`, fixed
  call order, documented; NEVER in view code. Cosmetics use the client-only RNG.
- **Single DoT slot per seat** — no stacking-debuff mechanics (Riftrot is parked anyway).
- **Checksums are strings** over the wire (63-bit ints don't survive JSON); new BossState
  fields join the sum with zero-baseline neutrality — prove on existing content.
- **`RunState` couples every kit into every sim's compile graph** — never edit ANY kit while
  ANY sim runs; this build shouldn't touch kits at all (flow spike = Wave 1's).
- **Worktree flow:** commit in the worktree, merge from the MAIN repo in a separate call
  (never `cd worktree && git merge` chains); un-piped merge commands (pipes mask conflicts).
- **`Dictionary.get` into `:=`** = Variant parse error; one broken parse in a `class_name`
  file cascades ("Failed to compile depended scripts"). Place-then-add for UI anchors.
  Probe scripts start at frame 1 of `_process`, not `_initialize`.
- **Fiction strings:** Vorathek's first-bound-wonder re-hang + all dialogue = display fields
  only, ids never rename, sims byte-identical to the slice's own baseline. No "rift" in new
  fiction strings. Combat never the joke; bosses polite; view-only banter.

## 6 · DO NOT TOUCH
**ULTRATHINK** (id/beats/cd — the marquee, forever) · the class-side `interrupts` flag
(DUELIST-BRIEF/Tempo territory — S7 only consumes it) · flow/peel/threat internals (Wave 1's;
this build reads `seat.vars["flow"]`, writes it ONLY in the Compaction re-point) ·
`run_map.gd` / draft / JAILBREAK files (descent-s2/s3 own them live) · the 15 solo bosses ·
aura-add second-cast-source (stays parked — nothing here needs a 2nd telegraph source) ·
Kill-Switch mechanics (P3 cash-in hooks in later) · net protocol version.

## 7 · STATUS FLOW (a slice isn't done until the docs say so)
Per slice: MASTER §BOSSES (results, bands, knobs old→new) + Coordination Log tick ·
BUILD-LEDGER §F row → 🔨+SHA at S6 · BOSS-PLAN §V → the record as verdicts confirm ·
CARD-CATALOG untouched (the aggro boons ride the tank deck, not this) · memory update.
Claim the build in the Coordination Log BEFORE starting (worktree `wow-seals`, branch
`seal-rework`); merge main daily — descent-s2/s3, tank-w1, tempo-art are all live.
