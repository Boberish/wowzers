# DUELIST-BRIEF — the Wave-1 build brief: THE DUELIST + FLOW=AGGRO (v1, 2026-07-10)

**What this is.** The implementation plan for the dodge tank — the whole BUILD-LEDGER **Wave 1**
(FLOW=AGGRO rewire + the Duelist base kit + Bulwark/taunt deletion + policy + sims + HUD + deck +
the §10 ability pass), written for the session that BUILDS it (Bill: *"make a plan to implement
the new dodge tank class… when ready I'll start you with Opus to do the code"*). Design of
record: `TANK-PLAN.md` **§1–§1d** (base minigame · spec match · tank-skips-ration · FLOW=AGGRO ·
ripples) · **§3 + §9** (deck v1 + the v2 reconcile/swap kits) · **§10** (the ability pass — EN
GARDE + 3 transforms + the ladder refit; treated here as the plan of record) · `BOSS-PLAN.md §1`
(taunt = FULL DELETE) · statuses: `CARD-CATALOG.md §TANK·THE DUELIST` · laws: `DECK-LAYOUT.md`
(esp. §5 ABILITY LAW +1/ceiling-6 + TRANSFORMS) · wave order + collisions: `BUILD-LEDGER.md
§0/§A½/§B`. Work in a worktree (`git worktree add ../wow-tank-w1 -b tank-w1`), merge main often,
gate every slice.

## 0 · SCOPE GATE — what's OPEN vs what still BLOCKS

**✅ OPEN (locked design — buildable the moment the session starts):**
- The round-5 **BASE MINIGAME** (§1, locked 07-09) + the 2-button spec match (§1b: DODGE
  secondary / PARRY main, WEAVE, feints, unavoidables, ◆→DUMP, partial-mit cap .90, no
  self-heal) + the tester-v5 knob table (§1 end). Numbers = first-cut knobs; playtest tunes
  ([[build-process-two-track]]).
- **FLOW=AGGRO universal** (§1c) + **THE TAUNT BUTTON IS DEAD on every seat** (BOSS-PLAN §1,
  07-10) + progressive peel (≥30% locked / <30% rising peel-chance / 0% random) + the
  grace-delay (the VICTIM'S window only — no taunt-back exists). Rules locked, numbers playtest.
- **Bulwark deletion** — ledger §A½ HARD RULE: dies in the SAME merge that ships the base kit,
  never before. The taunt engine dies with it.
- The transform **ACQUISITION pattern** — Floor-2 elevation, 1-of-3, ≤1/run: LOCKED by the
  Tempo GO (07-10 evening, verdict ③). §10.3's "rides Tempo verdict ③" is resolved.
- **Slices S0–S4 carry no card content** — they need no deck verdicts at all.

**🟡 STILL AT BILL'S BOARD (gates for the card slices S5–S7):**
- **Gate ① THE DECK BOARD** — §3 v1 KEEP/TWEAK/CUT per card + the ladder pick (2–3 TOTAL from
  Headsman/Ironside/Ghost incumbents + Matador/Scarlet/Stormweave challengers, §7/§9.2). If no
  export blob lands, building the DEFAULTS (incumbent top-3, v1 cards as authored, §10.4 refit)
  needs Bill's explicit say-so — one sentence from him opens it.
- **Gate ② the §10.6 tension points** — the three transforms per-card (Prise de Fer · Remise ·
  Flèche) · EN GARDE accepted as the Duelist CD (lean: yes, amplifier-only) · the +1 slot stays
  EMPTY · the v1.1 adoption as FINAL (EASE fold · FLOW module 3-of-4 · Hold-the-Line→FLOW).
- **Names** — the class (VANGUARD / AEGIS / STALWART / IRONCLAD / Bill's own) + the resource
  (WIND leads; BREATH/LEGS/POISE alternates). Build under working ids (class `duelist`, resource
  `wind`) — ids stay stable, display strings rename cheap (Alchemist precedent).

**BUILD ORDER: S0+S1 (ONE merge) → S2 → S3 → S4 → [gates ①②] S5 → S6 → S7 → S8.**
S0+S1 are co-dependent (flow has no driver without the tank minigame; the minigame has no aggro
consequence without flow) — stage them as commits on the branch, merge to main together.

## 1 · SLICES

### S0 · FLOW=AGGRO — the engine rewire + the taunt funeral (with S1, one merge)
The threat engine survives re-sourced; the taunt dies whole. Touch set (ledger §B row):
- `core/combat_state.gd:43` — **`threat_enabled` system is RIPPED OUT** (aggro is universal
  now; every fight runs it — ONE habit, learned once; only ambient numbers scale by content).
  Every `if s.threat_enabled` guard in `combat_core.gd` (:191, :238, :349, :421, :872) folds
  to always-on.
- `core/boss_state.gd:72-74` — `threat` (by seat INDEX) stays; **`taunt_seat_i` /
  `taunt_until_tick` DELETED**. `CombatCore.taunt()` (:894) + `_threat_target()`'s forced-taunt
  branch (:917-920) deleted; `_threat_target()` survives as the pure top-threat read.
- **The tank's threat SOURCE swaps damage → FLOW:** `seat.vars["flow"]` on the tank seat
  (0..1 normalized), moved ONLY by skill — clean answers raise it, un-clean answers (miss /
  whiff / BAITED) drop it, **taking damage NEVER lowers it** (§1c, locked). Tank threat derives
  from flow each tick; non-tanks keep low passive threat (damage/heals — today's path).
- **The progressive peel:** aggro% = the tank's normalized flow. ≥30% → locked on the tank.
  <30% → per incoming attack, peel-chance rises as aggro falls; 0% → fully random. **Peel roll
  + random-target draw from `state.rng` inside `update()`, fixed order** — never unseeded
  (lockstep law). A peeled attack rides the VICTIM'S own dodge bar + a warning cue + a **fixed
  tick-offset GRACE-DELAY** before it lands (det-safe; still ONE telegraph to the scheduler).
- **THREAT_DROP re-bases as FLOW DUMP** (:419-429 — the curse zeroes the tank's flow, rebuild
  by playing clean; the "context-window shift" flavor keeps its line).
- **A PERFECT MAIN grants a flow SPIKE** — the skill-shaped valve that replaced the taunt.
- `data/tuning_config.gd` — taunt knobs (`taunt_dur`, `taunt_threat_bonus`, :56 area) die; new
  knobs: flow gain/slip/decay · peel floor (0.30) + chance curve · grace ticks · flow-spike
  size. All shared aggro knobs live HERE (they outlive any one class); minigame numbers live on
  the class config (S1).
- ⚠ **GEAR-2 deed detector** (`combat_core.gd:904` — "a taunt within 2s of a THREAT_DROP
  answers the curse"): the taunt is gone, so this curio deed re-homes (proposal: the FLOW-DUMP
  curse is answered by re-climbing flow above the peel floor within a window — same fantasy,
  passive-flow shaped) or retires. Check `GEAR-CATALOG.md` for the owning curio; one-line
  verdict from Bill if retiring.
- `game/raid_hud.gd:2766-2773` — the aggro banner texts reference the taunt ("CHALLENGE IT
  BACK (T)") — reword to the passive-flow truth ("PLAY CLEAN — IT DRIFTS BACK"); T unbinds.
- **Gates:** determinism PASS everywhere · **expect ONE coordinated re-baseline bang** across
  raid-facing sims at this merge (threat re-sourced + taunt gone = real behavior change; pin a
  baseline worktree BEFORE branching and document the expected diff causes) · `raid_sim`
  STATS-v2 aggro/stray-shot accounting (:238) keeps counting under the new source.

### S1 · THE DUELIST BASE KIT (guarded) + Bulwark deletion (merges WITH S0)
- **New `godot/data/duelist/`** (Well idiom, the file shape of `data/well/`):
  `duelist_config.gd` — tester-v5 numbers verbatim as first-cut knobs: parry window 60ms ·
  good 230ms · wind pool 10, regen 1.9/s, dodge 1, parry 3.5 land-or-miss · mit parry .95 /
  perfect dodge .80 / good .55 (+.30 leak per power over small) / graze .28 / parry-miss .18 /
  **cap .90** · ◆ max 5, dump 70/◆ · counter 30 · stream chip gap .5s, real ~1.7s, feints .22,
  unavoidables .20. `duelist_kit.gd` — pure ClassKit reducer, all state in `seat.vars`:
  the bar stream · parry/dodge grading (height law: small=any, normal=main-any/secondary-good+,
  tall=PARRY only) · the WEAVE (flurry = all-or-eat-it-all → clean weave opens a free RIPOSTE) ·
  feints (READ/BAITED) · unavoidables (EAT — the bleed) · wind economy (fast recharge bubble;
  timed re-press recovery, fumble penalty; parry slow even on land) · ◆ bank + ⚡DUMP ·
  **flow feed** (clean/unclean answer events → S0's meter). `duelist_content.gd` — seat factory.
- **The stream IS the built architecture** (§1c reconciliation, `raid_content.gd:8`): melee =
  skinny small/normal bars (un-freezable chip, aggro-holder only) · targeted DEFENSIBLE
  telegraphs = the TALL bars · AoE strings = the FLURRIES · feint/unavoidable flags authored
  per encounter (first pass: knob-driven rates over existing streams; per-Seal authoring = S8).
- **Buttons: SPACE = DODGE · F = PARRY · DUMP** (+ EN GARDE at S6) = 4 of 6, **+1 slot EMPTY**.
  The tank **never** opts into `unified_dodge()` and **skips the universal dodge ration** (§1a):
  route the tank seat's "dodge"/"defense" actions (`combat_core.gd:83-115`) into the kit's
  bespoke grading via a kit hook (the `unified_dodge()` seam precedent — e.g.
  `bespoke_defense() -> bool`); wind is the anti-spam, not the flat 0.35s/1.3s cd.
- `data/class_registry.gd` — new class entry (working id `duelist`, seat "tank", aspects
  `["duelist"]` — the Warden joins later; policy Callable → S2's DuelistPolicy with its own
  DetRng salt — **a NEW salt, never Bulwark's** — byte-exact-history rule) ·
  `--autostart=raid:tank:duelist` resolves through it.
- **Bulwark dies in this merge:** `data/bulwark/*` (4 files) · `sim/policies/bulwark_policy.gd`
  + `raid_tank_policy.gd` · the registry entry · `class_codex` lines · `raid_hud` T-CHALLENGE /
  tank-band remnants. Recover-from-git is the attic; never port.
- **STATS PAGE v2 standing rule:** wire `recap_spec()` + `credit_boon_factors` lines for the
  new kit (grades/%, damage mix, missed-ops for parry/weave/read).
- **Gates:** det PASS 300 seeds · during the branch, A/B against the PINNED pre-branch baseline
  (`scripts/ab-gate.sh`) with the S0/S1 re-baseline causes documented · non-raid guarded
  surfaces (other classes' kits, forge, maps, world) byte-identical · `verify-all.sh` green.

### S2 · DUELIST POLICY (the AI seat — load-bearing, §1d)
`sim/policies/duelist_policy.gd`, 3 tiers on the existing latency/accuracy grammar: per-bar
answer choice (secondary vs main by bar size + wind state) · weave entry/execution · feint
classification (READ vs press) · dump timing · flow-consciousness (playing clean IS holding
aggro — no special aggro code needed, legibility is the requirement: a human squishy peeled by
an AI slip must read WHY from the flow bar). Per-policy `DetRng` streams only — never
`state.rng`. Registry Callable swaps in. **Gates:** `raid_sim` det PASS · tier separation
visible (win/deaths/peel-rate by tier) · peel rate at @sloppy stays survivable (§1d fairness).

### S3 · `duelist_sim` + the carry
`sim/duelist_sim.gd` on the `well_sim.gd` template: tiers × seeds × two raid-style encounters ·
economy meters (flow uptime + peel count · wind floor/starvation · ◆ throughput · parry
land/miss/graze rates · weave clean% · duet load — reuse raid_sim's hlMana/hlIdle idiom for the
healer side) · `--load` deck cells stubbed until S5 · determinism on shard 0 · `psim.sh`
shardable. `raid_sim`: tank seat now runs the Duelist (`--tank=duelist` default; flag survives
for the Warden later). **Gates:** det PASS 300 · `fightlen_probe`/`meter_probe` green ·
skill gradient visible across tiers.

### S4 · THE HUD SLICE (the ClassBand rail is BUILT — ride it)
`game/ui/bands/duelist_band.gd` extends `ClassBand` (+ `class_gauge.gd` gauges;
`ClassBand.for_hud` picks it up): the **bar-stream instrument** (vertical bars, height=power,
hollow = feint, marked = unavoidable, clustered = flurry — StrikeJudge idiom, `raid_hud.gd:2096`)
· wind bubble · ◆ pips · **the FLOW bar (tank seat ONLY — non-tanks never get one)**. Shared
surfaces on `raid_hud`: the **aggro box** = the built party victim-frames extended (a pip/bar
per seat, gold = current victim, :2733-2763) · the **peel warning cue** on the victim's own
dodge bar (+ grace-delay countdown) · the S0 banner rewording. **Gates:** `ui_smoke_raid` 0
errors · **WSLg screenshot probes, NOT headless** (`screenshot_duelist_raid.gd` on the
`screenshot_well_raid.gd` model): stream + flow bar + aggro box + a peel moment.

### S5 · DECK DATA — ⛔ gate ① (the board export, or Bill's "build the defaults")
`duelist_creeds.gd` · `duelist_modules.gd` · `duelist_boons.gd` · `duelist_rig.gd` (Well file
shape; `_cr()`/`_m()`/`_b()`/`_rig_fire()` guarded reads — **deckless = byte-identical to S1,
the ab-gate proves it**). Content per the verdict-folded §3/§9/§10.4: creeds (Veteran · Wager ·
Bellows · Dancer-WILD) · Floor-1 modules **offered 3-of-4 rolled** (⭐Crucible · Scales ·
Whetstone · FLOW) · boons by lane with **the EASE fold executed** (Quick Wrists + Roll With It
leave → the ONE EASE dial card, knobs: parry-window width / dodge-grade grace / wind-regen;
pool 15→13+dial) · **THE GAZE lane** (Lodestone · Hard Stare — catalog 💡, the taunt-shaped
insurance; include, they're BOSS-PLAN §1's other half) · rig WHENs (Tall Land · Big Spend ·
Read) + the THEN table (STRIKE/IRON/BREATH/PIP/BANNER) · keystones (Avalanche · Borrowed Time ·
Impossible Parry — elite-only, run 1) · ✦ Hold the Line **keyed to FLOW uptime** (§1d re-key) ·
swap kits M/S/W ONLY if Bill's picks swap them in. Fixed rarities + `ctype` tags
([[card-type-tags]]). Draft side: theme/lane tags + offer weighting (the draft flow lives in
`raid_hud` `_inject_boons`/`_show_boon_draft`, :796/:851). **Gates:** deckless byte-identical ·
per-build cells in `duelist_sim` (`--build=headsman|ironside|ghost`) det PASS · Crucible
ignite-EV + Whetstone hold-EV + Dancer one-button win-rate cells sane · catalog rows flip
🟡→✅ on Bill's verdicts (SAME commit) and ✅→🔨+SHA per merged slice.

### S6 · ⏱ EN GARDE — the signature CD (gate ② lean: accept)
**The FIRST signature-CD chassis game-wide** (Tempo's Set Piece deferred — this builds the
seam): a generic CD slot on the kit/seat (ready-tick + duration state) + a HUD rune on the
band, shaped so the Set Piece reuses it. Mechanics (§10.2): ~1-min CD, ~4s challenge — melee
tempo at you +~25% (the §1c "3 scalars" knob turned briefly — deterministic, tick-counted, no
scheduler change) · leaks/slivers HALVED (the old GUARD's mitigation re-homed) · clean answers
pay DOUBLE flow · a perfect MAIN banks ◆◆ · two slips break it early. **Never touches
targeting** — amplifier, not override. One knob: window length. **Gates:** unpressed =
byte-identical · pressed cells det PASS · the double-flow path visibly recovers aggro in a
peel-state sim cell.

### S7 · TRANSFORMS + DOORS + THE CEREMONY — gate ② (pattern already locked via Tempo GO)
- **Ceremony:** 1-of-3 at the Floor-2 elevation (mirror `_show_module_pick` :1831 /
  `_show_rig_wire` :1878 flow); ≤1 transformed ability/run; un-rerollable. **Dancer law:** a
  Dancer run (parry button GONE) excludes both parry transforms from the offer — flèche + a
  re-offer; the ceremony must never deal a dead card (§10.4).
- **Kit branches** (guarded no-ops, byte-identical unpicked — the Brew idiom):
  **PRISE DE FER** `prisedefer` — perfect parry SEIZES the bar (hold ≤~1.2s, wind drains);
  release THROWS it back, scaling with bar power + hold length, cap ≈ counter ×1.5; non-perfect
  parries unchanged. The thrown-bar render = the Avalanche's returning-bar shape (proven).
  **REMISE** `remise` — parry becomes PRIME (~1/3 wind, early; a primed-then-unanswered bar
  leaks 30% less; a primed FEINT costs only the prime) + COMMIT in-window (rest of cost, full
  parry + counter). **FLÈCHE** `fleche` — DUMP loads the bank onto the blade (~2.5s); the next
  PERFECT answer releases it as the charging strike (full dump +25%); expiry = half the ◆
  return, rest fizzles. The seize hold-state + flèche load timer are kit-local tick-counted
  state — no new systems.
- **Doors** (offer-gated on the transform held): Disarm · Wrenched Steel (prise) · Second
  Intention · Beat Parry (remise) · Running Edge · Point in Line (flèche) + the 3 rig WHENs
  (full-seize throw ~×5 · tall-bar commit ~×4.5 · perfect-release flèche ~×5).
- **AI:** prise — hold-length = f(wind, next-bar ETA) · remise — prime-rate + commit-threshold
  on the existing feint-classifier · flèche — load when P(perfect answer < 2.5s) clears a
  tier-scaled bar. All on surfaces the policy already reads (§10.5).
- **Gates:** unpicked byte-identical (all three) · per-transform det cells · Dancer-run offers
  never contain a parry transform (probe cell) · doors never offered without their transform.

### S8 · PER-SEAL STREAMS + the wave close-out
Author the tank-facing texture per Seal in `data/raid/raid_content.gd` encounter data: feint +
unavoidable placement · flurry strings · the ONE melee-tempo knob per boss (cranked at
Gemini/Mythos — the difficulty dial, §1c). ⚠ **Keep these edits minimal and mechanical** — the
SEAL REWORK (`BOSS-PLAN.md`, 🟡) re-authors all 4 Seals right after this wave and BLOCKS ON this
merge; don't pre-empt its structure work (ledger §252 row). **Deferred OUT of this wave:** the
interrupt flag on ⚡DUMP (pillar-#3 pass — engine-side, not before) · the Warden (D1 — after the
Duelist frame survives Bill's feel pass) · healer-follows-the-boss duet pass (Bill: later) ·
online spec-carry `(seed, spec)` (the shared debt) · swap kits not picked · run-recap ledger §G.

## 2 · VERIFICATION MATRIX (the repo bar — per slice AND at merge-back)
`scripts/verify-all.sh` green (SEEDS=300 for base-kit + transform claims) · `scripts/ab-gate.sh`
byte-identical for every guarded-off surface (deckless S5 · unpicked S7 · unpressed S6) · the
S0+S1 merge = ONE documented re-baseline (pin the baseline worktree FIRST; everything after
gates clean) · `duelist_sim` det PASS all cells · `raid_sim` all 4 Seals det PASS ·
`ui_smoke_raid` + `ui_smoke_map` 0 errors · `net_smoke` checksum-identical (flow/peel state is
plain CombatState data — lockstep holds if determinism holds; **protocol version bumps with the
roster change** — server + clients rebuild together, `server/preflight.sh` before any deploy) ·
WSLg screenshots: stream instrument · flow bar + aggro box · a peel with grace countdown ·
Floor-2 transform ceremony · En Garde window.

## 3 · GOTCHAS (hard-won + wave-specific)
- **The 30 Hz wall:** parry window 60ms ≈ **2 ticks** — windows quantize to ticks (input is a
  tick-stamped queue; effective resolution IS the tick). Keep the perfect band ≥1 tick + read
  margin (the Tempo governor precedent set `window_min` for exactly this); the knob is playtest
  anyway, but build the grading tick-native, never float-ms.
- The grace-delay is a **fixed tick offset**, one telegraph still, melee keeps ticking; a
  flurry string is ONE telegraph to the scheduler (boss ability timers freeze during it —
  melee does NOT).
- Peel roll + 0%-random target: `state.rng` in fixed order inside `update()`. Policies read
  their OWN `DetRng` streams. Flow derives from deterministic counts.
- Cross-seat refs (peel victim marking, riposte credit): seat **INDICES**, never object refs
  (`absorb_owner_i` idiom — RefCounted-cycle safe).
- `RunState` couples every kit into every sim's compile graph — never edit ANY kit while ANY
  sim runs. One broken parse in a `class_name`'d file cascades. `Dictionary.get(...)` into
  `:=` = Variant parse error. UI: place-then-add; `CenterContainer` for centered stacks.
- Probe scripts start at frame 1 of `_process`, not `_initialize` (HUD `_ready` hasn't run).
- The registry's policy seed salts are **byte-exact history** — give DuelistPolicy a NEW salt;
  never reuse Bulwark's constants for a different policy.
- Deleting Bulwark deletes the only `taunt()` caller — delete the ENGINE surface too (dead
  code is a lie in a determinism codebase), and sweep `class_codex`/HUD strings for "SPACE/F"
  and "CHALLENGE" leftovers (blanket-rename law: grep, don't trust the tail).
- The GEAR-2 taunt-deed (combat_core:904) — re-home or retire BEFORE deleting taunt, not
  after a red `gear_probe` surprises you.

## 4 · STATUS FLOW
Each merged slice: flip `CARD-CATALOG.md` rows (🟡→✅ on Bill's verdict, SAME commit as the
decision; ✅→🔨+SHA on merge) · tick the `BUILD-LEDGER.md` §B rows (+§A½ Bulwark row + §0
collision map — the taunt/threat rows resolve) · MASTER-PLAN Coordination Log entry ·
`TANK-PLAN.md` status line. Gate ① (the deck board) and gate ② (§10.6) are Bill's — S0–S4 need
neither; do NOT build S5–S7 without them (or Bill's explicit "build the defaults").
