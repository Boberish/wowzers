# WELL-DRAW-BRIEF — the Draw healer build brief (v1, 2026-07-10)

**What this is.** The implementation plan for finishing the Well's **DRAW** spec — the D6 deck
reshape + the §13 ability pass (SKIN + 3 cast transforms) — written for the session that BUILDS
it (Bill: *"make a plan to implement the draw healer, then ill hand it off to opus"*). Design of
record: `MENDER-PLAN.md §10 / §12 / §13` (inside the ⚖ board verdicts) · slate + statuses:
`CARD-CATALOG.md §THE WELL` (DRAW rows + ABILITY PASS rows) · laws: `DECK-LAYOUT.md §5` (ABILITY
LAW — the Well's 8-cap trim stays **PARKED** per Bill; §13.6 pt 6 says so twice, believe it) ·
sibling wall: **Brim's D5 (§11) is NOT this claim** — nothing here touches landings or
party-read surfaces (SKIN is shared-book and ships Brim-plain; that one Brim-visible surface is
stated, not expanded). Work in a worktree (`git worktree add ../wow-well-draw -b well-draw`),
merge main often, gate every slice.

## 0 · SCOPE GATE — the defaults (all rows are 🟡; Bill starting the build session = "build the defaults" unless he answers a line below)

Each default is the doc'd lean — a cheap per-line veto for Bill, not a re-litigation:
1. **Winners = VIGIL · RAPIDS · EDDY** (§10 skeptic ranking). The Skim parks with its theme:
   **`shortPour` + `looseGrip` LEAVE the Draw offer pool** (machinery stays in code, guarded —
   the EASE release-band knob is looseGrip's replacement, the same widener law as Wide Brim).
2. **THE MILLRACE DEMOTES** keystone→boon (rarity opus→sonnet, id unchanged) and **THE FLUME is
   crowned** the Rapids keystone (§12.5 pt 1 — "economy in a keystone slot fails the locked bar").
3. **⭐ THE VIGIL ships as the module** (§12.5 pt 2 — the §1 transformer candidate made real).
   First per-spec module gate: it is Draw-only machinery (Brim has no overruns) — offer it only
   when `_aspect == "draw"` (a small `_fw` module-offer filter; the other three stay class-wide).
4. **SKIN ships in the BASE BOOK**, Draw-graded / **Brim-plain** (§13.6 pts 1/2/4). Loaded count
   10→11 — counted, flagged, **NOT trimmed** (the trim rides the ledger compliance-trims row).
5. **Transform trio ships as designed** (Cupped Hand · Deep Draw · Braid, each a DOOR with 2
   sub-boons + 1 rig WHEN). Acquisition = Floor-2 1-of-3 ceremony, ≤1 transformed cast per run —
   **already LOCKED by the Tempo GO (verdict ③), not an open point.**
6. **Effect-filing of the unfiled built boons** (§12.1): Cool Hand · Double Draw stay generic
   release-bread (no theme tag) · **Deep Still → Eddy** (a wider Still Point is the hunt's EASE) ·
   **Last Drops → Vigil** (dregs-greed suits the hold build) — the two leans; swap free.

**Sequencing gate ⚠ (the one hard dependency):** S3 needs the **Floor-2 transform ceremony +
door offer-gating machinery** the live `wow-tempo-d0` worktree is building (TEMPO-D0-BRIEF S4,
`raid_hud` ceremony + `draft.gd` gating). **Wait for the tempo-d0 merge, then REUSE it —
generalize class-agnostic if it landed twinfang-local.** Everything else here is
`data/well/*`-local (+ `well_gauge`/`well_binds`/`well_policy`) and collision-free against the
live worktrees (descent-s2 = map region · tempo-art = combat-region render · rails = tuning ·
cask-policy = alchemist). ⚠ THE PURGE made **Well·Brim the DEFAULT raid healer** — `raid_sim`'s
default comp now contains an AI Well; the byte-identical gates below lean on that.

**BUILD ORDER: S0 → S1 → S2 → [tempo-d0 merge] → S3 → S4 → S5 (deferrable).**

## 1 · SLICES (commit + gate each before the next)

### S0 · SKIN — the missing heal (start here: Bill's own diagnosed gap, fastest playtest value)
The water's film (§13.2): quick cast (~Flash speed), **1 ◍**, graded release like everything;
for ~6s the ally's incoming hits are SOFTENED — a share of each hit **defers into a ~3s drip**
instead of landing at once. Clean **35%** · plain/overrun **20%** · Still Point **45% + Glint**.
Never absorbs, never heals — every point still arrives, late. One skin per ally; recast refreshes.
- `well_config.gd`: book entry `"skin"` (charges 1, cast ~1.4s, target true) + knobs
  `skin_dur` / `skin_drip_sec` / `skin_defer_clean|plain|still` — ALL `well_skin_*`-prefixed
  exports so sims sweep them. Add `"skin"` to `loadout()` (shared book — it appears on Brim's
  bar too, casting plain there by design).
- **The ONE engine touch** (mirror the absorb idiom, guarded): victim-seat fields
  (`skin_until_tick` · `skin_frac` · `skin_caster_i` INDEX for credit · a drip pool/array) —
  at damage application, if a live skin covers the victim, move `frac` of the post-absorb hit
  into the drip pool; drain the pool per tick over `skin_drip_sec` as late damage. **Flag
  absent ⇒ zero fields, zero work, byte-identical** (the Glint/Shining Hour bar). Fixed
  iteration order on the pool; death/fight-end clears it; drip damage can still kill (it
  defers, it never pardons). Diag: bump a `skin_defer` counter (total deferred) + a
  `recap_spec` row, so the stats page and sims can see saves.
- Kit: resolution rides `_resolve`/`_direct_heal`-adjacent plumbing but heals ZERO — grade via
  the existing release path (`_release` modes map to the three defer tiers; Still Point also
  fires `_glint`). Brim casts it plain (20%) — no landing grade, stated.
- Bind: the book's `"key"` field (lean: `e`) + a WellBinds chord (lean: **Sh+Mid** — the one
  free chord). HUD read (minimal, this slice): a film sheen on the ally frame + the drip
  visible as a trailing sliver on their bar (the target-bar recent-damage trail idiom).
- **Gates:** determinism PASS both specs · `ab-gate.sh well_sim` + `ab-gate.sh raid_sim`
  **byte-identical** (policy doesn't cast skin yet — S4 is the behavior bang) · ui_smoke_raid
  ALL OK · WSLg shot of the film + drip.

### S1 · D6 DECK DATA (the reshape — `data/well/*` only)
- `well_boons.gd` DRAW pool: add `theme:"vigil"|"rapids"|"eddy"` tags (generics untagged —
  tags are DATA for offer-weighting/door-gating/build-panel only; do NOT import Tempo's
  resonance system, nobody asked). New boons: `secondhand` · `ridetremble` (Vigil) ·
  `whitewater` · `shootgap` · `eddyline` (Rapids) · `currentreading` · `deepeddy` (Eddy).
  New keystones as opus-rarity relics (the built High Tide idiom — the shared elite-offer
  machinery is a ledger row, not this claim): `loosedatlast` · `flume` · `glassriver`.
  **Millrace demote:** rarity `"opus"`→`"sonnet"`, keystone framing off the desc.
  **Park the Skim pair:** `shortPour` + `looseGrip` leave the DRAW offer array.
- Kit effects (all guarded by `_b()`, all knobs on `well_config.gd`): whitewater (+heal/stack
  in `_draw_clean_bonus`) · shootgap (still-tag mult at max Current) · eddyline (per-10s
  internal cd: undercook downgrades Current −1 instead of `_current_break`; the sip stays
  weak — priced, never pardoned) · currentreading (release in the band's FIRST third → +1
  extra Current — see the drift gotcha in §3) · deepeddy (eddy drift range ×2 · still tags
  ×1.5) · flume (track full-Current-since tick; 12s held → ~6s all releases grade clean,
  then Current 0 — earned, never toggled) · glassriver (3 consecutive still tags → ~5s drift
  frozen + every release Still-Point-graded) · loosedatlast (held heal released within 0.2s
  of the ally being hit = full heal + 2s absorb — needs a per-seat last-hit-tick read, §3).
- `well_rig.gd`: no new WHENs this slice (the door WHENs come with S3).
- EASE knobs land as config exports only (release-band width · Current ebb-grace · gutter
  onset delay · drift speed) — the EASE dial machinery is a shared debt; if it isn't built,
  the knobs simply wait (the Tempo-brief precedent).
- **Gates:** undrafted byte-identical (`ab-gate.sh well_sim` + `raid_sim`) · `well_sim --load`
  det PASS + the deck still shows a real skill gradient (the draw maw 72/57/15 precedent) ·
  draft_sim ALL OK · determinism PASS.

### S2 · ⭐ THE VIGIL module (the one real kit mechanic of the reshape)
Generalize the Patient Hand machinery (`well_kit.gd:169-179` — creed-gated today) into a
module: **every overrun on a holdable cast becomes a HELD heal** (~3s), released instant,
gutter = charge + cast wasted. Patient Hand (creed) keeps its own gate — module OR creed
arms the hold; they stack to nothing extra (same state, stated).
- `well_modules.gd`: `vigil` entry, `built: true`, gauge `"hold"`; **offer-gated to Draw**
  (the §0 pt 3 filter). `well_kit.gd`: the hold path checks `_m("vigil") or _cr_b("patient_hold")`;
  add the TREMBLE — a deterministic sway read derived from ticks-held (view reads it via
  `observe()`; no RNG) that steepens toward the gutter. `ridetremble` (+8%/half-second held)
  and `secondhand` (Flash castable while holding — the stance; scope: Flash ONLY) key off it.
- `well_gauge.gd`: held-state read — the target bar shows the cocked heal + tremble; the
  gutter approach reads as the water shaking (WSLg pass; fire-moment events now, meters fine).
- **Gates:** module un-equipped byte-identical · Patient Hand runs byte-identical to its
  pre-slice behavior (the creed path must not move) · determinism PASS · ui_smoke_raid.

### S3 · TRANSFORMS (after the tempo-d0 merge — reuse its ceremony + door gating)
Kit branches = aspect-gated guarded rewrites of casts the book already has (the Brew idiom —
byte-identical unpicked). ≤1 per run · Floor-2 1-of-3 ceremony · un-rerollable · doors enter
later offers only while their transform is held · each adds ONE rig WHEN to `well_rig.gd`.
- **`cuppedhand` (Flash → Rapids):** with the transform held, Current ≥1, and the cast bar
  BUSY, a Flash press throws the cupped flash — spend 1 Current stack, lands INSTANTLY,
  ungraded (plain heal, never clean, never a Glint), never feeds the Current; idle Flash
  casts normally (the busy-bar discriminator is the lean — it needs no new input and fires
  exactly in the emergency it exists for; note it intercepts `on_action` BEFORE the
  `casting.is_empty()` early-out at `well_kit.gd:200`). Doors: `handfulafter` (+15/22/30%,
  capped) · `returnriver` (a CLEAN release within ~2s restores the spent stack). Rig WHEN:
  *cupped flash lands on an ally <30%* (~×4.5).
- **`deepdraw` (Mend → Vigil):** Mend's bar gains a DEEP band PAST the clean band — upkeep's
  auto-complete is suppressed for transformed Mend; the bar draws on into an extension zone
  (knob: `deep_band_at`/`deep_band_width`/`deep_mult` ×1.6); release in the deep band = ×1.6,
  past its end = **GUTTER** (charge + cast wasted — drawing past clean surrenders the free
  overrun). With the hold armed (⭐Vigil module OR Patient Hand creed — same rule, one line):
  a missed deep band becomes a HELD heal at plain value instead of guttering. Doors:
  `pearldiver` (deep band −30% size, ×2, capped) · `cameupsinging` (+2 Current on a deep
  catch — the Vigil↔Rapids bridge). Rig WHEN: *I catch the deep band* (~×4).
- **`braid` (Cascade → Eddy):** Cascade's 3 arcs become 3 graded releases — a short string,
  one band per arc, each on its own beat (presses ride the existing `release` action).
  **Tremolo's law verbatim:** ONE cast for boon/charge math · grades per press · boon math
  reads the FIRST press · Current gain caps at +1 for the whole string · string ends on the
  3rd press, an empty hand, or phrase timeout. Under the Eddy creed the per-arc band centres
  re-drift between arcs (re-derive from arc-start tick — the built hash idiom, no RNG);
  all-clean → 3rd arc +40%. Doors: `tightbraid` (bands −25%, bonus →+70%) · `crossingstreams`
  (each arc re-aims at release to the CURRENT lowest ally). Rig WHEN: *all-clean braid* (~×5).
- **Ceremony:** the tempo-d0 Floor-2 pick screen, re-pointed at the Well's trio when the
  healer seat is Draw (generalize the offer source per class registry if D0 shipped it
  twinfang-local). Door boons ride the same offer-gating draft.gd path D0 built.
- **Gates:** unpicked byte-identical (all three, `ab-gate.sh well_sim` + `raid_sim`) ·
  per-transform det cells · braid grade distribution sane at expert/good/sloppy ·
  ui_smoke_raid + WSLg of the ceremony and each rewritten bar.

### S4 · POLICY + SIMS (the ONE deliberate re-baseline — fold every behavior change here)
- `well_policy.gd`: **skin** pre-cast on the predicted spike target off the telegraph schedule
  it already reads (both specs — this is what re-baselines the default comp, on purpose) ·
  **hold release** on a spike forecast (Vigil — the existing `_plan_release` + a hold branch) ·
  **cupped flash** as the emergency valve (ally-HP threshold while casting) · **deep draw**
  go/no-go on an incoming-damage forecast tier · **braid** = `_plan_release` ×3 with per-tier
  jitter · Current-preservation thresholds (don't undercook at high Current unless critical).
  Optional fold-in (it's the same file and the ledger row is open): teach the policy Meditate
  + Boiling Over. Skill knob stays `latency_ticks` — tiers must separate (expert holds/skims
  clean; sloppy gutters).
- `well_sim.gd`: cells for `--build=vigil|rapids|eddy` (drafted-theme loadouts) + per-transform
  cells; keep `--load`. Run the balance look at real fightlen bands (3–5 min / ~10 min — the
  inert-healer close-out), not the 60–142s legacy bands.
- **Gates:** determinism PASS every cell (`psim.sh well_sim 300`) · `raid_sim --healer=well`
  (and the DEFAULT comp) det PASS — **checksums SHIFT here by design; re-pin `ab-gate.sh`
  baselines right after the merge** · tier gradient proven in-band · verify-all green.

### S5 · RENDER POLISH (deferrable — own claim if the queue is hot)
The AAA pass on the new reads, on the S0/S2/S3 minimal versions: the film's material render
(UiKit glow/grad toolkit) · tremble sway on the CastChannel · the deep band as a darker zone
past the clean glass · braid arc pips on the channel · ceremony chrome. Pure view code;
WSLg screenshots both specs; zero draw errors.

## 2 · VERIFICATION MATRIX (the repo bar — per slice AND at merge-back)
`scripts/verify-all.sh` green (SEEDS=300 for braid/timing claims) · `scripts/ab-gate.sh
well_sim` + `ab-gate.sh raid_sim` byte-identical for every guarded-off surface (S0–S3; S4 is
the one sanctioned shift — re-pin after) · `well_sim` det PASS all cells · `raid_sim
--healer=well --caster=alchemist` across all 4 Seals · draft_sim + menu_probe green (pool +
bar changed) · ui_smoke_raid ALL OK · WSLg shots: film+drip · tremble · deep band · braid
string · ceremony (headless can't render `_draw`).

## 3 · GOTCHAS (hard-won + found writing this brief)
- **The drift is per-cast STATIC** (`well_kit.gd:263-266` — centre offset hashed from the
  cast's start tick; it does not move mid-cast). Current Reading's "first third of drift" =
  the release landing in the band's earliest third — do NOT build mid-cast band movement
  (that's the parked "osu drift-ticks" idea, §10.6 skipped-on-purpose).
- **Loosed at Last needs a victim last-hit-tick read** — a tiny guarded seat field stamped in
  the damage path (diag-family, like STATS-v2's `last_melee_victim_i`). Keep it an INDEX/tick,
  never an object ref (the co-op credit idiom, CLAUDE.md).
- **Two overrun rewriters coexist**: the hold (module/creed) and Deep Draw both claim the
  cast's end. Rule of record: transformed Mend resolves Deep Draw FIRST (deep band → gutter),
  and the hold catches the miss (held at plain). One code path, one order, stated.
- SKIN drip pool: fixed iteration order; drain at 30 Hz inside `update()`; drip is LATE
  damage, not a HoT and not an absorb — it must still credit the original hit's source and
  can still kill.
- `RunState` couples every kit into every sim's compile graph — never edit a kit while a sim
  runs. One broken parse in a `class_name`'d file cascades. `Dictionary.get(...)` into `:=`
  = Variant parse error. UI: place-then-add; `CenterContainer` for centered stacks.
- The Well's release input is already tick-stamped (`"release"` on the perform surface) —
  braid presses reuse it; do not add a second input path.
- `well_policy` release aim carries `RELEASE_BIAS = 1` (input-enqueue compensation) — braid
  and deep-draw planners need the same bias or the AI systematically undercooks.
- Default comp contains an AI Well·Brim since THE PURGE — a "brim-only" assumption in a gate
  is stale; guard by aspect, prove byte-identical on BOTH sims.

## 4 · STATUS FLOW
Each merged slice: flip the CARD-CATALOG Draw/ability-pass rows 🟡→✅→🔨+SHA (the ✅ moment is
Bill's §0 defaults standing at build-start; record it in the flip note) · tick the
BUILD-LEDGER §C rows (Draw D6 · Draw ability pass · the module-gauges/AI row if S4 folds it) ·
MASTER-PLAN Coordination Log entry per merge · MENDER-PLAN banner gains the built line.
Do NOT build: the Skim theme · Brim's D5 cards · a Well resonance system · the 8-cap trim ·
mid-cast drift. The deferred shelf stays deferred without a new verdict.
