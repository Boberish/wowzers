# TANK-PLAN — the tank seat's class onto Framework v2 (two kits: THE DUELIST / THE WARDEN)

**Status (2026-07-12): 🔨 THE TANK-V3 REBUILD BUILT on branch `tank-v3` (slices S1 `717b2a2` → S5) —
attempt 3. tank-v2 (`5af4927`) was still fully buggy in play (notes not showing / flicker / pop-all-over
/ sync wrong) AND broke the other three classes; v3 is the from-the-spec rebuild against §0 THE CHANNEL
CONTRACT v3 (FINAL BUILD SPEC — Design C two surfaces: channel = committed melee, judge/cast bar = raid
globals+casts; full unification REJECTED, DEC-1). What v3 fixed: the STREAM barrier is RETIRED so the
melee flows through every global (the #1 hitch); the octagon projection + render-side `_tempo_vis` are
deleted so comet x is a pure function of eta (no pop/flicker/jump); the judge feed-or-deactivate is
unconditional (the frozen-ghost that broke blade/caster/healer, fixed at source); and THE MERGE-BACK
GATE v2 skipped is honored — `dodge_recovery` reverted 0.8→0.35, the barrage un-collapsed to one beat
per hit, rhythm melee added to Mistral+Gemini. One protocol version carries the whole rebaseline: **v18**.
Verification (S5): `stream_probe` ALL OK incl. the forced-multi-step process-order probe (req 33);
net_smoke/net_map_smoke checksum-identical over loopback; WSLg render confirmed (tank + Alchemist);
`verify-all` SEEDS=300 green with all four classes in one merge. **Bill's per-Seal playtest = the feel
gate.** Deck re-lands per-verdict later; per-Seal texture/busters/LATE authoring = S6.
The tank-v2 status below is kept for history:**

**Status (2026-07-11): 🔨 THE TANK-V2 REWRITE BUILT & MERGED `5af4927` — see §0 THE CHANNEL CONTRACT
v3 (the design of record; wins any diff below). Bill's playtest = the feel gate; every number is a
knob (`duel_*` config · per-body stream profiles · the F9 STREAM TUNER). Deck re-lands per-verdict
AFTER the playtest (S5); per-Seal texture/busters/LATE authoring = S6.** tank-w1 (`62cc09e` + ONE BAR
v1→v1.5) broke the game; this rewrite replaced it from the base. The pre-rewrite status below is kept
for history:

**Status (pre-rewrite):** 🟢 **BASE MINIGAME LOCKED (2026-07-09) — feel/numbers via playtest; Duelist deck v1 AT BILL'S
VERDICT + 3 challenger themes (§7) joined that board 2026-07-10; Warden BRANCH SLATE (§6, 5 themes)
🟡 AT VERDICT 2026-07-10; DUELIST ABILITY PASS (§10 — 3 transforms + EN GARDE CD, the Tempo §17.11
treatment) 🟡 AT VERDICT 2026-07-10.** Locked this session: the two specs matched to 2 buttons (§1b) · **FLOW = the AGGRO meter,
universal, progressive peel (§1c)** · consequences worked/deferred (§1d). Flow-economy *numbers* are left
to a live slice (Bill: "playtest for feel"). The round-5 minigame (tester v5) is the base; the Duelist deck
is on the verdict board:
https://claude.ai/code/artifact/cf273dd1-4169-45e2-b990-47000941d417 — interactive KEEP/TWEAK/CUT,
export blob comes back here. **Nothing is built yet.** Old Bulwark = frozen placeholder, NOT the base.
The Warden's deck is a LATER pass (after the Duelist proves the frame).
**Names open (on the board):** the class (VANGUARD / AEGIS / STALWART / IRONCLAD / Bill's own) and
the fatigue resource (WIND leads — the tester already yells WINDED; BREATH / LEGS / POISE alternates).

**Dodge-unify reconciled (2026-07-08) — design + deck UNCHANGED.** The dodge-unify (one SPACE dodge,
F retired) was scoped to Twinfang/Alchemist/Well and does NOT touch the tank. Nothing on the board
changes. Two rules it makes explicit (§1a): the two kits are the **dodge tank** and the **shield tank**;
the tank runs its OWN dense defensive stream and **skips the universal dodge** every other seat gets —
so parry cleanly reclaims the now-free F, and no card is affected. (Plain words — "move"/"answer",
not "verb" — jargon dropped per the deck-creator pass.)

## §0 · THE CHANNEL CONTRACT v3 (Bill, 2026-07-11) — THE TANK-V2 REWRITE · design of record

**⚠ AMENDED 2026-07-12 (Bill's v3 playtest — THE ONE-BAR VERDICTS, built on the branch
S7–S8b):** five rulings that supersede the matching lines below:
1. **ONE BAR, literally** — the boss dial (the circle) + the shared judge are GONE for the
   tank; GLOBALS (dodge) + targeted BUSTERS (parry) + my telegraph beats ride THE CHANNEL as
   comets (verbatim off the live telegraph, synthetic negative ids); ALL casting (heal/
   empower/kickable/brace) rides the BossCastBar under the boss HP — the one cast surface,
   every seat. LAW 2's "boss spells stay off the channel" survives only for CASTS.
2. **THE MISS AFTERLIFE** — `stream_resolve_slack` 0.15→0.04 (~1 tick of tick-alignment
   fairness): a comet never sits pressable at the line. Unpressed past the line = MISSED —
   it flips crimson + ✗ and KEEPS FLOWING to the bar's end ("I missed it, it kept going").
   The gate draws late-side bands only as wide as the true grace — everything visible is
   pressable. The press ghost rises VERTICALLY (horizontal drift crowded the next tone).
3. **THE PEEL, re-restored to pass 2** — the tank sees + answers EVERY bar regardless of
   aggro (the v3 rebuild had regressed to the stream-pause model): peeled bars ship marked
   (crimson hunt-chevron + "→ VICTIM"), clean answers pay flow/counters (the comeback),
   damage lands on the hunted raider.
4. **THE SONGBOOK** — flat per-bar odds are retired on authored fights: melee dicts carry
   `phrases` (motif library: {weight, rest, steps:[{gap,kind,late}]}), one seeded weighted
   draw per motif — learnable like a song, fresh every pull. Per-Seal songbooks authored
   (Riftmaw drumbeat / Mistral syncopation / Gemini echo-pairs / Mythos full-language);
   packs + spike stay on the legacy odds path.
5. **AAA bar** — the channel matches the Twinfang/healer instrument standard (chrome, glow
   comets, Cinzel words, spawn pops, gate heartbeat, banded target); "not up to the
   standards of the others" is a bug class, not a style note.
6. **ONE CLAIM (playtest round 3, same day)** — Bill: globals "don't register" + "we have
   the overlap problem for sure." The telegraph events (GLOBAL aoe beats · my beats ·
   strikeless BUSTERS) now COMPETE in the press claim with the stream bars — same DEC-14
   window/tie-break, nearest impact wins (the comet the eye is on), judged AT the press on
   the one ladder (parry ±parry_land · DEC-15 legality), payoffs at press, stored mit
   applied at impact (`seat.vars.tg_claims`). **The open-window model is RETIRED** (its
   age knobs marked RETIRED in DuelistConfig); "telegraph busters/globals keep the
   open-window model" in §THE PRESS below is DEAD. Proof: spike's sim checksum is
   byte-identical (no overlaps ⇒ old behavior exactly), dense expert 35%→80% win (the
   stolen presses back). Unanswerable pairs (< dodge_recover apart) remain the per-Seal
   quiet-window authoring's job (S6, owed).
7. **THE GUARD (same round)** — Bill: "author the space around globals, it's every time a
   problem." When the boss commits to an answerable cast (aoe beats · tank-aimed beats ·
   strikeless busters), authored quiet windows [impact − `stream_guard_before` 0.65,
   impact + `stream_guard_after` 0.45] open: committed bars inside SHATTER (the rear-up —
   a rule, like body-death; the runway beyond survives) and both publishers slide future
   beats past (flurries never cross — they degrade to autos). Per-Seal override via melee
   `guard_before`/`guard_after`. Probe law 6 enforces it; guard quiet is never a publish
   halt. Result: dense expert 80%→100% (the unanswerable pairs were the deaths) and the
   long-known ui_smoke pause+codex warden fail HEALED (it was dying to unanswerable
   pressure). This closes the owed "per-Seal stream_breathe quiet windows" item as a
   GENERAL system — `stream_breathe` remains for extra scripted gaps.

**Why this section exists:** tank-w1 (`62cc09e` + the ONE BAR v1→v1.5 patch chain) broke the
game. Bill's call: **full rewrite from the base — kit + engine stream + UI — no patching, no
tech debt.** Root causes: the presentation was never specified; the tank UI forked the shared
StrikeJudge in place; the engine rolled bar size/victim at ARM time while the UI projected
ahead (the pop/morph/jump comet bug class). This contract was confirmed with Bill question by
question on 2026-07-11 and **wins any diff with §1/§1b/§1c below** (their game-design core
survives; specifics amended here). Build slices + gates: the tank-v2 plan (ledger §B).

### LAW 1 — the engine publishes a committed timeline; the UI only draws it
- The engine commits every incoming attack — impact tick, kind/size, victim, flags — the
  moment it enters the visible horizon (~3s), rolled from the seeded stream RNG at PUBLISH
  time, **immutable after publish**. The UI has ZERO prediction logic: comets spawn at the
  channel mouth fully formed and slide at constant px/s into the gate. Nothing can pop,
  morph, or jump — the truth never changes.
- Victim (incl. the aggro-peel roll) is decided AT PUBLISH; flow changes affect future bars.
- Publish respects a **barrier**: no auto may land inside a predicted global's answer window
  (earliest-possible ability fire is derivable from ability timers — conservative, safe).
  The stream visibly thins before a big move; nothing ever overlaps; one press = one bar.

### LAW 2 — ONE channel, one bar at the gate
Everything the tank answers rides ONE bottom-center channel (its own NEW widget — never a
mode-fork of a shared one). Boss SPELLS (incl. future kicks) stay on the cast bar under boss
HP — footwork ≠ spellwork. One grading target at the gate (no dual lanes).

### THE VOCABULARY + ANSWER MATRIX (v3 — light auto deleted, three sizes total)
| Bar | Shape · color | Word | PARRY | DODGE |
|---|---|---|---|---|
| AUTO | diamond | PARRY | ✓ (land/miss) | ✓ any grade |
| HEAVY | hexagon | PARRY | ✓ | **BULLSEYE only** |
| TANK BUSTER (authored) | spiked octagon · tank colors | PARRY | ✓ | **BULLSEYE only** |
| GLOBAL (boss's big move) | spiked octagon · boss colors | DODGE | **never** | ✓ any grade (every seat) |
| FEINT | **disguised as any real bar** · purple tint = the only tell | (lies) | — | — (press = BAITED · ignore = READ; may arrive LATE) |
| UNAVOIDABLE | skull-marked | EAT | — | — (brace; healer moment) |

**Reading law (two lines):** *the word is the recommended answer; purple means don't.* The
gate shows every legal answer (grading bands per bar + a tiny dodge glyph on the center dot
where dodge is bullseye-only). NO barrage/string beats — retired game-wide (see ripples).

### GRADING — one game-wide ladder (coherence law)
**GRAZE (steel) < GOOD (gold) < PERFECT (mint) < BULLSEYE (bright gold)** — Twinfang's
built ladder, names + colors + "tighter toward center = more" identical in every class. The
tank gate is drawn as the SAME banded target the Twinfang rhythm bar uses; the verdict slam
uses the same tier names ("BULLSEYE!").
- **DODGE = the graded button** (1 wind): mit graze .28 / good .55 / perfect .80 /
  bullseye .85 (+ power leak on heavy/buster) — first cuts, all `duel_*` knobs.
- **PARRY = binary by identity** (3.5 wind, land or miss): the ~60ms window is 2 ticks —
  grading is TICK-NATIVE, never float-ms. Land = mit .95 + COUNTER hit-back + ◆ bank + flow
  spike. Miss = token .18 mit, full wind spent, flow drops. Parry is the damage/aggro
  engine; dodge is the economy play — a real choice, parry never pushed.
- HIT (never pressed) = full damage; flow drops for the missed answer, never for damage
  itself. BAITED = flow drop + brief lockout. READ = clean, small flow tick.

### THE STREAM — one timeline, two writers
- **Writer 1, the boss script (authored):** globals on ability timers (unchanged machinery);
  TANK-BUSTER injections at scripted beats (per-Seal, slice S6); LATE placements.
- **Writer 2, the texture generator (per-boss, seeded):** every BODY (boss/add/pack member)
  carries a **texture profile** — cadence `every`, `jig`, heavy/feint/flurry/unavoidable/
  late odds, flurry length, damage band, per-phase overrides — and the bar-by-bar sequence
  is rolled at publish under **grammar rules** (no HEAVY/CRUSH first after a global · no
  flurry against a global · breathing gap after big mechanics · no two busters back-to-back
  · no feint as the fight's opener). Authored texture, generated sequence.
- **Freshness:** stream seed = `(run seed, fight, pull counter)` — every re-pull rolls a
  new sequence; the same pull replays byte-identical.
- **Packs:** field-holder = the active writer (profiles from a small preset library —
  swarm/bruiser/heavy — + per-body overrides; heat-carry/enrage = phase overrides). On a
  body's death/advance its published-unresolved bars **SHATTER** (killing the attacker
  cancels its swings — a rule, not a mutation); walk-in gap before the next opener.

### SPEED LAW + LATE bars
All comets share ONE speed at any moment — per-bar speed variance is forbidden (bars would
collide/reorder). Per-bar difficulty = the **LATE bar**: normal speed, skips the mouth,
pops in at ~40–60% of the track with a flash cue, keeps its type's word/answer.
**Whole-flow tempo shifts ARE allowed**: a global stream-tempo multiplier (eased ramps) for
phases / EN GARDE (+25%) / frenzy — the runway compresses together, deterministic.

### FLURRY = A MODE, not a bar
The channel visibly mode-swaps (color/border + "FLURRY!"), the WHOLE flow speeds up for its
duration (tempo multiplier, never per-note), beats fast and close. Inside: **dodge only ·
parry disabled · wind NOT used** — pure execution, don't miss one; all-or-nothing stands,
clean weave = free RIPOSTE; tempo eases back after. No LATE bars inside a flurry.

### THE PEEL (aggro loss) — loud, and THE COMEBACK (⚠ amended pass 2, Bill's playtest)
**Pass 2 (2026-07-11): the tank SEES AND ANSWERS EVERY BAR, always.** A peeled bar draws
translucent + hunt-ticked on the channel; its damage lands on the VICTIM (undodgeable for
them — `cdd008f`'s rule survives on the damage side), but the tank's clean answer still
pays flow/counters — **answering peeled bars IS how you claw aggro back.** The AGGRO LOST
cue + gold pip + the victim's "IT'S HUNTING YOU" banner all stand. (The pass-1
"stream pauses on a peel" tell is DEAD — it read as missing notes. §1c/§1d's
"peel rides the victim's own dodge bar + grace-delay" stays dead too.)

### THE PRESS (⚠ amended pass 2) — THE TWINFANG MODEL, verbatim
**✅ RESTORED IN V3 (S6, 2026-07-12):** the v3 rebuild had silently regressed this to
judged-at-impact (the union merge carried only guard+easy-aggro) — the source of Bill's
"old slug" report. S6 re-ports the pass-2 semantics into the v3 kit (`stream_answers` +
`stream_resolve_slack`, claim filtered to victim==me per the v3 peel), S6b adds the view
half (tick interpolation · the frozen-pixel press burst: fading line + expanding circle ·
ease-in killed · every press echoes), S6c the AAA channel pass (symmetric banded gate ·
glow/shadow comets · Cinzel words · gilded chrome · rune kick).
Bill: *"the twinfang is super good, do that."* A press **CLAIMS the nearest unanswered bar
within ±`answer_claim` (0.30s) and is judged INSTANTLY, SYMMETRIC around gate-touch**:
`|press − impact| / claim` on the blade's own fractions (`grade_bull_frac .18 ·
grade_perfect_frac .55 · grade_good_frac .80`, graze to the edge; PARRY binary at
±`parry_land` 0.07). Verdict + payoffs fire AT the press with the blade's **±ms readout**;
bars resolve `stream_resolve_slack` (0.15s) after gate-touch so a hair-late press still
connects; the channel interpolates comets between 30 Hz ticks. The pass-1 model
(press-opens-a-window, judged later at impact, early-side only) is DEAD — it graded
hair-late presses as silent misses and read as input lag. Telegraph busters/globals keep
the open-window model (big slow reads). EASY AGGRO first cut rides this pass (slip .05 ·
decay .02 · floor .15 · start .75 — Bill: "easy aggro for now, tune later").

### BINDS + OFF-CHANNEL SURFACES
Binds (kept from `1a03d33`): **1/SPACE/LMB = DODGE · 2/RMB = PARRY · 3 = ⚡DUMP · 4 = ⏱EN
GARDE.** The tank never opts into the universal dodge cd — WIND is the leash. Off-channel:
cast bar · verdict slam (+streak, miss vignette) · grade rail · WIND bubble ("WINDED"
pulse) · ◆ pips · FLOW bar with the 30% lock-line (tank only) · party aggro box.
Keep-list is provisional (Bill: "keep it all for now, can remove later if too much").

### CROSS-CLASS RIPPLES (decided here, executed in tank-v2)
- **BARRAGE RETIREMENT (game-wide):** multi-beat dodge strings are an old artifact — one-
  dodge classes can't weave them. Retire from all boss content (string beats → single
  globals); the non-tank dial loses `feed_strikes`. The tank FLURRY is unaffected.
- **Non-tank dodge cd RAISED:** 0.35s recovery existed to chain barrages — first cut
  ~0.8s recovery (whiff 1.3s stays ≥), final value = Bill's playtest knob.
- **THE CHANNEL IS GLOBAL:** the new widget is class-agnostic — the game's ONE answer
  instrument. Tank = first client; other classes migrate later ("others after"), the dial
  keeps spells only. Grading ladder + colors identical everywhere from day one.
- **Tunability:** all stream numbers are data (profiles + `TuningConfig`); a dev-only
  STREAM TUNER overlay live-tunes the active profile mid-fight and prints the dict back.
- **Deck:** tank-v2 ships DECKLESS (draft offers no duelist cards, must not crash); the
  deck re-lands per-verdict AFTER Bill's base playtest (two-track law). Catalog untouched
  (already 🟡 at verdict — the un-verdicted 62cc09e defaults die with the old kit).

## §1 · THE LOCKED CORE (round 5 — full history in MASTER-PLAN §CLASSES 2026-07-07)

Classic rhythm defense on the HUD's own timing UI: ONE stream of incoming hits drawn as
**vertical bars, height = power** (skinny lines; the only fat bar is the Warden's HOLD).
- **PARTIAL MITIGATION LAW** — even a perfect leaks a sliver (mit cap ~0.90). **No self-heal, ever.**
- **THE HEALER DUET = the scoreboard** — your HP bleeds, a sim healer refills; too little bleed =
  healer idle, too much = you fall.
- **COMBO ◆** = the build-and-spend resource. **FATIGUE** (wind) = the leash.
- Feints (hollow — READ if ignored, BAITED if answered) · consistent stream, no phases ·
  per-boss authored streams (encounter data, Warband Law).
**⚖ THE SPECS MATCH (2026-07-09): each has exactly 2 answer buttons — a MAIN + a SECONDARY — read the
same way; only the flavor differs.** SECONDARY answers small (any rating) / normal (good+), **never
tall**, and **never hits back** (even a perfect leaves a sliver — the healer's never bored). MAIN answers
**any** size incl. tall, and a **PERFECT MAIN hits back** (counter + banks ◆). No third button. *(Which
button is "main" for the dodge tank — PARRY — is Bill's "block for small/med, shield for big" pattern
applied to "dodge for small/med, parry for big"; flip the labels if read backwards.)*
- **THE DUELIST — the dodge tank** (dense/twitch, def+off). **DODGE (secondary) + PARRY (main).** DODGE
  is the bread — a % mitigation that scales with timing, small/normal only, can't take a big one. PARRY
  is the main — tiny ~60ms window, big fatigue cost land-or-miss, answers any size, perfect = hit back.
  A *flurry* = a burst of fast skinny bars → **WEAVE** it (rapid dodges, **all or eat it all**; a clean
  weave opens a free RIPOSTE). **Eats UNAVOIDABLE** bars (the bleed). Skinny bars only. **◆ → ⚡ DUMP =
  damage.** **LOW HP, bar swings FAST** — a build for a quick healer. Fatigue = a **small pool, fast
  recharge** (the "ninja"), a **bubble**; DODGE recovers fast if you time the re-press (fumble → penalty),
  PARRY recovers slow even on a land.
- **THE WARDEN — the shield tank** (heavy/endurance, def-only + off-cd). **BLOCK (secondary) + SHIELD
  (main).** BLOCK is the light tap — small/normal % mitigation. SHIELD is the main — answers any size
  incl. big, is **HELD** across the fat HOLD/flurry bars, and a **PERFECT SHIELD hits back** (= **SHIELD
  SLAM**, the parry-twin). **No dodge** (dropped 2026-07-09). Blocks **everything** — no unavoidables
  (PIERCE = affix knob); bleeds via the partial-mit sliver + hold-drain. **◆ → ⚡ DUMP = damage**,
  off-rhythm. **MORE HP, takes bigger % chunks** — steadier bar. Fatigue = a **big pool, slow recharge**,
  a **bar** (his real leash — over-hold and you're winded). Stream slower + heavier vs the Duelist's
  density. The old hold-blocks-all-free = a module, not base.

### §1a · THE TANK SKIPS THE UNIVERSAL DODGE (post dodge-unify, 2026-07-08)
The tank's bar-stream **IS** the boss's telegraph stream to this seat — dense by design (pillar #2,
"the densest footwork"). So the tank does **NOT** run the separate universal dodge RATION the other
seats get (~3–8 sparse beats bolted onto their kit, `combat_core.gd:104` "every class has it, separate
from the class"). The tank's minigame already **is** its dodge/defense — one stream, not dodging on top
of dodging.
- **Dodge tank** answers each bar with **DODGE (secondary)** or **PARRY (main)**. Parry reclaims the
  now-free F (the universal F-dodge was retired in dodge-unify).
- **Shield tank** answers with **BLOCK (secondary) / SHIELD (main)**. It has **no dodge** and needs none.
- Both **replace** the universal dodge; they never stack on it.
- The Duelist's DODGE stays its OWN graded, height-law dodge **leashed by WIND** (≈1/step), NOT the flat
  universal 0.35s/1.3s cd — the wind pool is the anti-spam, so wind (not a global cooldown) is what
  limits chaining a barrage; keep fast recovery. The tank **never** opts into `ClassKit.unified_dodge()`
  (that hook merges two INPUTS for the three non-tank kits; the tank already runs bespoke parry + dodge).

### §1b · BASE-MINIGAME REFINEMENTS (2026-07-09, Bill) — the two specs, matched
The specs were blurring together; this pins what's DIFFERENT while making the two READ the same. **2
buttons each (MAIN + SECONDARY), no third**, on one rating rule:

| Bar | Dodge tank (2nd DODGE · main PARRY) | Shield tank (2nd BLOCK · main SHIELD) |
|---|---|---|
| small | either button, **any rating** | either button, **any rating** |
| normal | **MAIN any** rating · SECONDARY needs **good+** | **MAIN any** · SECONDARY needs **good+** |
| tall / big | **MAIN only** (PARRY) | **MAIN only** (SHIELD) |
| **flurry** | **WEAVE** — rapid DODGE, **all or eat it all** → clean weave = free RIPOSTE | **HOLD** the SHIELD through it |
| unavoidable | **EAT it** (the bleed) | **SHIELD it** (no unavoidables) |
| feint | READ — don't press | READ — don't waste a press |

- **PERFECT MAIN hits back** (PARRY / SHIELD-SLAM) = counter + banks ◆. The SECONDARY never hits back and
  **even a perfect leaves a sliver** (partial-mit law — the healer always has work).
- **SECONDARY = the bread** you spam through the dense small/normal stream; **MAIN = the commit** for the
  big ones + the hit-back.

**The two specs are leashed DIFFERENTLY (this is the feel-split):**
- **Dodge tank — twitch/recovery leash + LOW HP.** DODGE recovers fast **if you time the re-press**
  (chain the rhythm); fumble → a bigger recovery penalty. PARRY recovers slow even on a land. Fatigue = a
  **small pool, fast recharge** (a **bubble**). HP is **low and swings fast** → a build for a *quick* healer.
- **Shield tank — endurance-pool leash + HIGH HP.** BLOCK/SHIELD recover fine; his real leash is a **big
  pool that recharges slow** (a **bar**) that HOLDING drains fast — over-commit and you're winded. HP is
  **high, taken in bigger % chunks** → a steadier bar for a steadier healer.

**◆ = damage · CD = defense:** both specs spend **◆ → DUMP = pure damage** (tanks are defense-rich /
damage-poor — no defensive ◆-spend; 🛡 GUARD dropped). The mitigation GUARD used to give moves to the
class's **~1-min defensive signature CD** — the `DECK-LAYOUT.md §5` slot every class owes, role-shaped for
the tank as **a wall** (amplifies skill by lining it up with a boss window, never `button = damage`).
Owed, not yet designed. **⚠ Card fallout:** the guard cards (Return to Sender, Cheap Iron) + the Wall rig
re-home to the Warden; SPEND lane is now DUMP-only. Deferred per Bill (branches after the minigame) —
flagged in `CARD-CATALOG.md`.

**FLOW = the AGGRO meter, BASE — see §1c (2026-07-09, Bill).** Supersedes the earlier "flow = a module":
the clean-answer streak is now **base on every tank** and IS the boss's-attention/threat meter. The **FLOW
module** is repurposed as the *upgrade* — "your flow ALSO ramps your DUMP damage" (the aggro-hold becomes a
damage engine). Keep the *slow-mo* flavor to the Ghost keystone (Borrowed Time) so it doesn't double up.

### §1c · THE AGGRO SYSTEM — FLOW is the boss's attention (2026-07-09, Bill) — **UNIVERSAL**
**The reframe:** the tank's clean-answer streak, **FLOW**, IS the aggro/threat meter. Play clean → you
hold the boss's attention; slip → it drifts to the warband. Aggro stops being a damage-threat rotation
(the old "babysit" model Bill parked to raid-land) and becomes a **skill readout on the minigame you
already play**. Lore skin (the takeover): high flow = you hold the boss's *context*; a slip = it *compacts
you out* and wanders (reuses the existing THREAT_DROP = "context-window shift" flavor, MASTER-PLAN §255).

- **FLOW is BASE, not a module** (supersedes the same-day "flow = module" call): every tank always has the
  flow/aggro meter. The **FLOW module** becomes the *upgrade* — flow ALSO ramps your DUMP damage.
- **Universal — one rule everywhere (REVISES the "aggro = raid-only" lock `b2afbca`):** aggro works
  identically in overworld / dungeon / raid — **one habit, learned once**. Only the *ambient numbers*
  (boss damage/HP, via the Depth spine) scale by content — **never how aggro works**. A peel in the open
  world just hurts less; you never relearn it. The full coordination *expression* (tank-swaps, hot-potato
  curses) blooms at raid intensity because the numbers are brutal there, not because the rule changed.
- **The progressive peel (Bill's model):** aggro is a **%** (the tank's normalized flow). **≥ 30%** → the
  boss is locked on the top-threat seat (the tank). **< 30%** → each incoming attack has an **X% chance to
  peel** to another seat, **X rising as aggro falls**. **0%** → fully **random** targeting. ~~A **TAUNT** is
  the hard override (grab it back a few seconds; everyone-has-a-taunt = a DPS can clutch-grab it, hot-potato
  curses force swaps).~~ **⚠ AMENDED 2026-07-10 (Bill — `BOSS-PLAN.md §1`): THE TAUNT BUTTON IS DEAD, on
  every seat.** Aggro is **100% passive**: the only way back is playing clean (flow re-climbs). The
  skill-shaped valve: a **PERFECT MAIN grants a flow SPIKE** (the counter IS the "look at me"), plus an
  aggro **boon lane** (LODESTONE · HARD STARE — 💡 in CARD-CATALOG). Taunt-swaps were judged WoW-import
  risk-erasers; hot-potato choreography re-homes to boss-authored mechanics (the Mythos mark relay).
- **Flow moves on SKILL, never on hits (Bill, locked):** clean answers raise flow; **un-clean answers**
  (miss / whiff / baited) drop it. **Taking damage NEVER lowers flow** — otherwise a tank under heavy fire
  spirals (hit → lose flow → peel → more hits). Flow measures *your play*, not your luck.
- **A peel is telegraphed to the person who catches it (Bill, locked):** a peeled attack rides the
  **victim's OWN dodge bar** + a **warning cue** — so a stray hit is always dodgeable and never a surprise.
  A **small fixed GRACE-DELAY** before a peeled hit lands is the reaction window: the new victim reads the
  warning and dodges~~, AND the tank can **TAUNT it back before it lands** (the peel's recovery valve)~~ —
  **⚠ 2026-07-10: the grace-delay is the VICTIM'S window only** (no taunt-back exists); a peel always costs
  the raid one real answer, which is the risk Bill wants live. It's
  **determinism-safe** — a fixed tick offset (not wall-clock), one telegraph still, melee keeps ticking; it
  just paces the fight a hair during peels. *(Does not break the scheduler.)*
- **UI (Bill):** FLOW gets its **own dedicated bar** (tank only — it's the aggro driver). Everyone's aggro
  shows in a **small shared "aggro box"** = the built party victim-frame extended (a pip/bar per seat, gold
  = current target). Non-tanks have **no flow bar** (their aggro is passive) → no bar-bloat.
- **Reuses the built threat engine wholesale** — `BossState.threat` (by seat index), ~~`taunt_seat_i`~~
  *(dies with the button, 2026-07-10)*, `_threat_target()`, `THREAT_DROP` *(re-based as **FLOW DUMP** —
  the curse zeroes the tank's flow, rebuild by playing clean; `BOSS-PLAN §1`)*, the victim gold-frame +
  aggro-lost banner. We only **change the tank's
  threat SOURCE from damage → flow**; non-tanks keep low passive threat (damage/heals).
- **No tank? it just degrades (Bill's "crazy stuff" for free):** aggro is universal, but **only the tank
  DRIVES it high** (via the flow minigame). Remove the tank → nobody drives it → aggro sits low → the peel
  goes random → everyone shares the incoming, all dodging hard. "3 DPS, no tank" = emergent hard-mode, not
  a special case. **Don't** bolt flow=aggro onto every class (a healer "holding the boss by healing
  cleanly" is off-fantasy) — aggro-% is the universal layer; flow is the tank's driver on top.

**The stream reconciliation (melee vs telegraph) — this IS the built architecture** (`raid_content.gd:8`
"melee chip + Crush/Talon → the TANK parries; Void Volley aoe string → EVERYONE dodges"). One boss stream,
consumed by role:
- **Melee** = the constant, **un-freezable** chip on the aggro-holder (`enc.melee {every,min,max}`) → the
  tank's **skinny small/normal bars** (the SECONDARY dodges/blocks). Only the aggro-holder eats it.
- **Targeted DEFENSIBLE telegraphs** (aimed at the victim) → the **tall bars** (the MAIN parries/shields) =
  the "big hits"; the *same* attack a peeled squishy must dodge.
- **AoE telegraph strings** → the **flurries** (WEAVE / HOLD); everyone dodges each beat on their ration.
- Tank sees melee + every telegraph (dense = "densest footwork"); non-tanks see only what's aimed at them
  (sparse). **Tuning coupling is mild:** melee is *3 scalars* (tempo + damage band), not an authored
  pattern — class tuning (windows/mit/flow) is done ONCE vs a standard melee tempo; each boss authors its
  telegraphs + turns the ONE melee-tempo knob (the difficulty dial, cranked at Gemini/Mythos). They
  **layer** (melee un-freezable; a telegraph freezes ability timers) — one legible seam, not a tangle.
- **Determinism (build constraint):** the peel roll + the 0%-random target MUST draw from a seeded stream
  in fixed order (`state.rng` inside `update()`, or a per-policy `DetRng` — never unseeded). Flow derives
  from deterministic clean-answer counts; checksums/lockstep stay correct for free.

### §1d · RIPPLES from flow-aggro (consequences — status as of 2026-07-09)
- **✅ Non-tank peel survivability — resolved in principle:** a peeled attack rides the **victim's own
  dodge bar + a warning + the grace-delay** (§1c), so it's dodgeable and telegraphed. Remaining = tune
  peel lethality (dangerous-not-instant).
- **🔮 "Perfect tank = static?" — PARKED (Bill not worried):** a good tank holding aggro is the reward, not
  a bug. If a raid ever feels too static, scale the flow **drop-off** harder / add authored "attention-
  breaks" there — a **raid-tunable knob**, not a blocker. Don't over-engineer it now.
- **Healer follows the boss** — the duet now shifts target with aggro (heal whoever's peeled) → more
  dynamic healing; a real consequence for healer design + the AI healer policy. **Deferred (Bill): later.**
- **Tank/healer kit updates** — both need a pass for flow-aggro. **Deferred (Bill): planning only for now.**
- **AI tank reliability is load-bearing** — solo/backfill leans on the AI tank holding flow (playing clean
  does it) + being legible to its policy; a human squishy peeled by a dumb AI slip must not feel unfair.
- **Hold the Line (support)** overlaps the flow/aggro readout — reframe / key it off flow at the deck pass.
- **Crucible module** (fills from damage TAKEN) fills slower while the boss is peeled away — note at the deck pass.
- **Depth affix vocabulary** gains melee-tempo + peel-severity as intensity knobs (same TuningConfig spine).
- **✅ Single-target law (pillar #1)** unaffected — one stream, varying recipient (revised note added to WORLD-PLAN).
- **FLOW as a shared cross-class pattern (Bill's musing):** Twinfang·Tempo + a cascade healer already run a
  "flow"-type clean-rhythm meter; the tank's is the same *family*, doing a role-appropriate job (blade →
  damage, tank → aggro, healer → throughput). **Available where it fits, never forced** (Alchemist maybe
  not — Rule #1 asymmetric content). A framework note for the class-reshape phase (DECK-LAYOUT).
- **🎚 The flow economy — RULES locked, NUMBERS = playtest (Bill, 2026-07-09):** the *rules* are set
  (skill-only, own bar, peel on the victim's dodge bar + grace-delay, the ≥30%/0% shape). The *numbers*
  (what a clean answer ADDS, what a slip SUBTRACTS, decay rate, the exact flow→aggro% curve) are
  **deliberately left to playtest for feel** — the two-track process ([[build-process-two-track]]:
  structure now, feel from the thinnest playable slice). **Not a blocker** — it's the first thing a live
  slice tunes.

- **⚠ CUT HISTORY (don't rebuild):** R2 THREE DOORS/lanes · R3 SHIELD CHARGE-&-PLANT WALL +
  circle-size + THE DUEL/balance/TOPPLE/guard-break + hard phase breaks · R4 shared 3-move kit.

**Tester v5 baseline knobs** (the deck's numbers hang off these; all become `duel_*` config):
parry window 60ms · good 230ms · wind pool 10, regen 1.9/s, dodge 1, parry 3.5 (land or miss) ·
mit: parry .95 / perfect dodge .80 / good .55 (+.30 leak per power over small) / graze .28 /
parry-miss .18 / **cap .90** · ◆ max 5, dump 70/◆ (~~guard 2◆~~ DROPPED 2026-07-09, §1b) · counter 30 ·
healer inflow 26/s · stream: chip gap .5s, real hit ~1.7s, feints .22, unavoidables .20.

## §2 · THE DIALS (the lanes ARE these)

1. **THE READ** — parry-or-dodge-or-ignore per bar; feints and unavoidables live here.
2. **THE SWING** — parry window / cost / the land payoff (counter + ◆).
3. **THE STEP** — dodge grades, the height law, the feint read.
4. **THE WIND** — pool/regen/costs (folded into SWING+STEP lanes as costs).
5. **THE BANK** — ◆ income (parry-only at base) and cap.
6. **THE SPEND** — the DUMP-vs-GUARD fork; guard placement vs unavoidables.
7. **THE DUET** — the bleed vs the healer; the party-facing surface (support card lives here).

## §3 · THE DUELIST DECK v1 (AT VERDICT — this is the hard copy)

**Design brief (Bill, 2026-07-08):** replay-driving, dynamic cards; **DEEP stacked builds, not many
strategies fighting** — every card feeds ≥1 of three named ladders; lanes cross-feed.

**THE THREE LADDERS:**
- **THE HEADSMAN** (bank-and-burst): Wager/Bellows → Whetstone → Heavier Steel · High Line ·
  The Rally · Deep Pockets · Powder Keg · All In → 👑 THE AVALANCHE.
- **THE IRONSIDE** (the guard engine): Veteran/Bellows → ⭐ Crucible → Cheap Iron · Return to
  Sender · Blood Price · Overreach · Deep Pockets → 👑 THE IMPOSSIBLE PARRY.
- **THE GHOST** (the footwork chain): Dancer/Bellows → Scales → Feather Step · Perfect Form ·
  Read the Room · The Rally → 👑 BORROWED TIME.

### CREEDS (pick 1/run — curated)
| Creed | TYPE | Effect |
|---|---|---|
| **The Veteran** | EASE | Window ~74ms; a missed swing refunds half its wind. Counter −25%, ◆ cap 4. The learner's blade — caps itself so you graduate out. |
| **The Wager** | GREED | Parry costs 4.5, a miss leaks +10% — a LAND banks ◆◆ and counter +40%. The greed pole. |
| **The Bellows** | STRAT | Wind regen halved; every clean answer (land or perfect step) +1.5 wind instantly. The rhythm-changer — the pool becomes a chain. |
| **The Dancer** | RULE | **WILD — the parry button is GONE.** A PERFECT dodge IS the parry (counter + ◆ every other perfect); GOOD stays a dodge; baited lockout +0.2s. One button, pure height-reading; the mobile creed. |

### MODULES (Floor-1 pick 1-of-3 · exactly one ⭐)
| Module | TYPE | Effect |
|---|---|---|
| ⭐ **The Crucible** | RULE | TRANSFORMER. Damage TAKEN fills it (the bleed is fuel) → IGNITES: ~6s WHITE STEEL (parries cost 0 wind, lands bank ◆◆, counters ×1.5) → crash (regen dead 4s, gauge empty). Eat-the-unavoidable-now ignite timing is the decision. |
| **The Scales** | STRAT | Balance pan: parries tip crimson, dodges tip blue; near-BALANCE = growing edge (to +12% dealt / −12% taken); pegging a side kills it until re-centred. Anti-autopilot. |
| **The Whetstone** | GREED | Each banked ◆ sharpens over 4s (sharp pip ×1.5 in a dump); an unanswered real hit dulls your sharpest pip. Hold-vs-spend with teeth. |

### BOONS (15 · 4 dial-lanes · H/S/O ladders, base = Haiku · EASE count 3/15 · ≤1 pardon per lane)
**LANE THE SWING:** Heavier Steel POWER (counter +20/30/40%) · Quick Wrists EASE (window
+8/12/16ms, fades while ◆ full — tapers with power) · High Line STRAT (tall-bar land: ◆◆ / +1 wind /
counter ×1.5 vs tall) · Overreach GREED (parry while WINDED for 8/7/6% max-HP blood, never below
10% HP; O: blood-land banks ◆◆ — feeds the Crucible).
**LANE THE STEP:** Feather Step POWER (dodge −25/35/50% wind, floor 0.5 — CARRY) · Perfect Form
STRAT (perfect dodge refunds wind; next parry ≤2s −1/−1.5/−2 — the step-into-swing chain) ·
Read the Room STRAT (a READ: +1 wind, next counter +8/12/16%; O stacks ×2) · Roll With It EASE
(good dodge on tall: leak → 3s bleed, +0.5/0.7/1 wind — the lane's one pardon, dressed for the duet).
**LANE THE BANK:** Deep Pockets POWER (cap +1 / +1 & start 1◆ / +2 & start 1◆ — CARRY) ·
The Rally GREED (every 3rd/3rd/2nd land in an unbroken chain banks double; miss/graze breaks,
dodges don't) · Blood Price STRAT (eat an unavoidable: ◆ / +2 wind / next spend +20%).
**LANE THE SPEND:** Powder Keg POWER (dump +20/30/40%/◆ — CARRY) · All In GREED (full-bank dump
×1.25/1.4/1.5; at full bank take +10%) · Return to Sender STRAT (guard stores 40/55/70% of
prevented damage, hurls it back as a bar when it drops) · Cheap Iron EASE (guard 1◆; cut 45/50/55%).

### RIG (WHEN → THEN · THENs: STRIKE 20 dmg · IRON 2s +20% DR · BREATH +2 wind · PIP +1◆ · BANNER 2.5s warband +5%)
The Tall Land (parry a TALL bar — premium) · The Big Spend (dump ≥4◆) · The Wall (Guard eats a
hit ≥15% max HP — premium) · The Read (correctly ignore a feint). All chooseable/earnable.

### KEYSTONES (elite-only, spectacle — each changes what the gate looks like)
- **THE AVALANCHE** — DUMP becomes a returning string: each ◆ is a bar sailing BACK across the
  gate; press as it crosses = ×2. The offense on the same instrument, reversed.
- **BORROWED TIME** — a full-speed land SLOWS the stream 1.5s (bars crawl); slowed-time lands
  don't refresh (no perma-slow).
- **THE IMPOSSIBLE PARRY** — unavoidables grow a gold sliver: perfect swing at DOUBLE wind cost
  parries them; land = counter ×2 + ◆◆; miss = eat hit + swing. Makes Blood Price a live choice.

### SUPPORT (1)
✦ **Hold the Line** TEAM — while THE LINE HOLDS (no unanswered real hit in last 5s), warband
+6/8/10% damage. Uptime IS the buff; keyed to the core state.

### CARRIES (verbatim on the Warden — verified per-knob)
Feather Step (block cost = same knob) · Deep Pockets · Powder Keg · ✦ Hold the Line.
NOT carried: Blood Price (Warden has no unavoidables) · Read the Room (counter rider dead — no attack).

### Self-audit (deck-creator §3/§1/§4 — for the record)
Anti-pattern sweep clean (no passive wind-ups, no stat keystones, no one-time bonuses, no extra
buttons — the Dancer REMOVES one; Avalanche reuses the same press) · insurance ≤1/lane, dressed
(Roll With It) · greed chosen per use everywhere (no luck-wearing-greed) · offer-trio spot-checks
pass (archetype breads compete; payoffs compete) · every card feeds a ladder, zero ballast ·
wideners taper with power (Quick Wrists) · caps stated on every scaling effect · BROKE/FADED/DEAD/
OPENED n/a (first deck; old Bulwark guard boons are the frozen placeholder's, not this class's).

## §4 · BUILD ORDER (after Bill's verdicts — do NOT start before the export blob lands)

1. **Fold verdicts** into this doc (statuses → STANDS/REWORKED/CUT), lock names (class + wind).
2. **Guarded base kit** (Well idiom): class codename on the tank seat, `--autostart=raid:tank:duelist`,
   old Bulwark stays the default — **byte-identical unless picked** (A/B via `scripts/ab-gate.sh`).
   The kit reducer runs bespoke **parry (F) + dodge (SPACE)** — **no `unified_dodge()` opt-in, and no
   universal dodge ration** (§1a); bars/wind/◆/duet hooks via existing seat surfaces; all numbers
   `duel_*` on the class config. Boss streams = encounter data (authored per Seal, Warband Law).
3. **Deck layers** kit-local + `_fw()` dispatch (creeds/modules/boons/rig per the Well's framework
   wiring); fixed rarities + `ctype` tags per [[card-type-tags]].
4. **Sims:** `duelist_sim` base loop + per-creed/module/build cells (Whetstone hold-EV, Crucible
   ignite timing, Dancer one-button win-rate) · determinism PASS 300 seeds · `raid_sim --tank=` carry.
5. **HUD slice:** the bar-stream on the raid HUD's timing instrument (StrikeJudge idiom) + ◆ pips +
   wind bar + module gauges; WSLg screenshot probe (headless can't render `_draw`). This stream IS the
   boss's telegraph to the tank seat — do NOT also spawn the universal dodge ration/cue (§1a).
6. **Pillar #3 flag:** ⚡ DUMP is the natural interrupt-carrier (burn the bank to kick) — engine-side
   flag with the interrupt-by-ability pass, not before.

## §5 · OPEN / LATER
- The Warden deck pass (same board format) — after the Duelist frame survives contact with Bill.
- Warden module candidates already named: the hold-all wall (old base, too strong) + dump variations.
- Per-boss authored streams for the 4 Seals (encounter data) — with the build, not the deck.
- Online spec-carry `(seed, spec)` — the shared debt every rework owes.

## §6 · THE WARDEN BRANCH SLATE — five build-theme candidates 🟡 AT VERDICT (2026-07-10)

**What this is** (SLATE-PLAN row 1; the corrected branch definition — TEMPO §14 is the worked
reference). A branch = a **build THEME inside the locked Warden kit** (§1b): the base minigame
(BLOCK tap · HELD SHIELD · SLAM · big slow wind pool · ◆→DUMP · FLOW=AGGRO · the DUET) is
untouched — themes ADDRESS its dials, add no buttons (Warden stays 4 touch targets of the
7-ceiling), and never hang identity on a new gauge. Pick **2–3**; the deck pass files the
inherited cards + new cards into the winners. Example cards are ILLUSTRATIONS — no CARD-CATALOG
rows this pass. **How it was made:** knowledge base re-mined through the shield lens (AtO
Magnus/Bree · StS Barricade/Body-Slam · WoW Prot/Brewmaster · Hades Aegis) + fresh sweep
`research/warden-sweep.md` (Lies of P guard-regain · Bloodborne rally · MonHun guard-counter ·
For Honor superior block · Vermintide stamina economy) → 4 lenses → 5 themes → **3 adversarial
skeptic passes (1 theme killed pre-slate, ~11 fixes folded)**.

### The harvest (what the research says, Warden-sized)

1. **"Defense chooses the offense" is the shield-fantasy's best loop** (MonHun Offensive Guard,
   For Honor superior block, Lies of P perfect guard): the clean block is a PROMISE of a counter,
   not a subtraction. The Warden's perfect-SLAM-hits-back core is already this — themes should
   pay it forward (chains, windows, follow-ups), not re-invent it.
2. **The pool is the real health bar** (Vermintide BCR/stamina-tanking): wind economy — drain,
   recovery, brinkmanship — carries a whole build identity on its own.
3. **Stored defense as ammunition is a proven archetype** (StS Barricade→Body-Slam; our parked
   `Return to Sender` is the native seed): block accumulates, then fires, on the player's timing.
4. **The wound-window converts loss into currency** (Bloodborne rally, LoP Guard Regain) — but
   OUR law is no-self-heal, so the legal steal is a short post-leak window where a clean answer
   banks ◆/wind, never HP ("answer the wound" — a boon shape, filed under themes 2/4).
5. **Block-share is the co-op shield's unclaimed crown** (AtO Magnus): four seats + peels
   (§1c) give us a clutch-save surface no solo game has — capped per class rule 5 (SAVE a
   fight, never RUN one).
6. **One-cadence trap check:** the five themes below peak on five clocks — self-set charge
   cycles · the boss's big bars · whole-fight endurance · warband/aggro windows · stream density.

### The Warden's dials (the lanes for this spec — §2 re-read through §1b)

**THE READ** (block-or-shield-or-ignore; feints) · **THE TAP** (block grades/cost) · **THE HOLD**
(the held shield + its drain — the Warden-only dial) · **THE SLAM** (main window, the perfect
hit-back, ◆ income) · **THE WIND** (big pool/slow recharge) · **THE BANK** (◆) · **THE SPEND**
(DUMP) · **THE LINE** (aggro/flow + the healer duet).

### The theme candidates at a glance

| # | Theme | In three words | Mostly |
|---|---|---|---|
| 1 | **THE PAYLOAD** | store it, return it | absorbs the 🔮 parked trio |
| 2 | **THE SLAM** | counters that chain | new cards |
| 3 | **THE RAMPART** | outlast everything | mixed (module seed exists) |
| 4 | **THE BANNERMAN** | the warband's wall | absorbs the support (TEAM) |
| 5 | **THE THORNBACK** | touch me, bleed | new cards (thin — honesty note) |

---

### THEME 1 — THE PAYLOAD · *your shield is a loaded weapon*

**What its cards do:** prevented damage CHARGES the shield — a battery you hurl back on your own
timing. The charge **decays if you sit on it** and a fumbled tap spills a chunk, so the greed is
riding it big and cashing before it drains. Income is DEFENSE (what you stopped), not offense.
**Dials addressed:** the hold (charging) · the spend (the hurl) · the bank. Nothing bends; the
battery reads on the existing shield UI.
**Absorbs:** **Return to Sender** (the seed card — verbatim) · **The Wall** rig WHEN (a stored
hit ≥15% max HP = premium) · **Powder Keg** (carry, spend-side).
**Example new cards:** creed *Ballast* — the battery is live from run start; capacity is modest
until the module deepens it · module *The Coil* — the battery gauge + clean taps also feed 25% ·
boon *Heavy Shipment* (GREED) — capacity +50%, decay +50% · keystone **THE SIEGE** — at full
charge your next SLAM launches the stored total as ONE colossal returning bar across the gate;
press it as it crosses = ×2. *(Skeptic-sharpened vs the Duelist's Avalanche: Avalanche is a
per-◆ STRING of small returning bars; the Siege is one titan bar you spent a whole verse
charging — different clock, different read.)*
**Greed/comfort + EASE knob:** hold-the-charge greed, bite = decay/spill you authored; comfort =
cash early and small. Knob: charge-decay grace.
**Nearest neighbor:** Duelist·Headsman (bank-and-burst — but on ◆ from parries); StS Body-Slam
(the archetype proof). The Payload banks *prevented damage* — a defense-reader, not a swing-reader.

---

### THEME 2 — THE SLAM · *the boss swings; you answer bigger*

**What its cards do:** the guard-counter economy — clean SHIELD mains pay FORWARD. Slams chain:
each perfect main makes the next answer friendlier (wind refunds, tap discounts, bigger
counters); a graze breaks the chain. ◆ income concentrates on the main. The rotation is built ON
the boss's tall bars — you want the big swings to come.
**Dials addressed:** the slam · the bank · the wind (refund shapes). No bends.
**Absorbs:** the "dump variations" module candidate (§5) becomes this theme's module space.
**Example new cards:** creed *The Drumhead* — slam chains grant +1 wind per link from run start ·
module *Aftershock* — a 2s window after every perfect SLAM where taps cost 0 · boon *Offensive
Guard* (POWER, the MonHun steal by name) — after a perfect SHIELD your next DUMP +15/22/30% ·
boon *Meet It Head-On* (GREED) — answering a small/normal bar with the MAIN (full wind price)
banks ◆ — chosen per use, the chain-keeper's tax · keystone **BREAKWATER** — a perfect SLAM on a
tall bar visibly SHOVES the next bar back down the lane (the boss's string staggered, on the same
instrument — the For Honor superior-block steal).
**Greed/comfort + EASE knob:** execution greed (main-on-small commits, chain stakes); comfort =
tap the bread, slam only talls. Knob: slam-window width (tapers with power, Quick-Wrists idiom).
**Nearest neighbor:** the Duelist PARRY (a knife-edge 60ms *swing economy*, priced per press) —
the Slam theme is about CONSECUTIVE clean mains on a slow heavy clock; the payoff is chain-state,
not a single counter number. Interrupt note: DUMP is the tank's pillar-#3 carrier — Aftershock
windows make the deliberate kick-DUMP cheaper to line up (feeds the §4.6 flag, no new rule).

---

### THEME 3 — THE RAMPART · *outlast everything*

**What its cards do:** the endurance engine — the wind pool is the real health bar (the
Vermintide read). Cards buy hold-drain efficiency, cheaper raises, recovery-while-held, and
winded brinkmanship; one boon-shape is the PUSH — pay wind NOW, chosen per use, to blunt the
incoming bar (proactive defense as a move).
**Dials addressed:** the hold · the wind · the read. No bends.
**Absorbs:** **Cheap Iron** (verbatim — cheaper raises) · *Feather Step* carry (block-cost knob)
· the **hold-all wall** module candidate (§5, the old too-strong base) becomes this theme's
module, priced.
**Example new cards:** creed *Deep Keel* — pool +20% but recharge unchanged (a bigger, heavier
bar) from run start · module *The Bulwark Stance* — the priced hold-all wall: while held, ALL
bars blockable, drain +40% (the old base, now a chosen identity) · boon *Second Wind* (STRAT) —
a hold released above half-pool refunds 2 wind · boon *White Knuckles* (GREED) — below 25% wind
your taps mitigate +15% but a whiff empties the pool: brinkmanship you opted into · keystone
**THE IMMOVABLE** — survive a full flurry HOLD without dropping below a quarter pool and the
shield ROOTS: ~4s where the stream visibly bends around you (bars shrink as they arrive), then
the drain debt lands. Enterable only by a clean hold — never a toggle.
**Greed/comfort + EASE knob:** over-hold greed (staying held through bars you could tap);
comfort = tap-first, hold only the fat ones. Knob: hold-drain grace.
**Nearest neighbor:** Fermata's hold (offense — charge-and-CASH on release; the Warden hold
cashes nothing, it endures) · Vermintide stamina-tanking (the proof the pool carries a build).

---

### THEME 4 — THE BANNERMAN · *the wall the warband stands behind* (TEAM)

**What its cards do:** the aggro/duet surface (§1c) becomes the build — flow-UPTIME payoffs,
taunt riders, and capped clutch block-shares. You win by being unmoveable AND making the other
three seats richer for it. Only a 4-seat game with AI backfill can print this theme.
**Dials addressed:** the line · the bank. No bends; rides the aggro layer the base already owns.
**Absorbs:** ✦ **Hold the Line** (the support card — reframed onto flow/aggro per the §1d note:
uptime IS the buff) · TAUNT (base button) gains its riders here.
**Example new cards:** creed *Standard Bearer* — Hold-the-Line-style warband pay from run start,
smaller numbers · boon *Shield Brother* (STRAT, clutch-capped per class rule 5) — a charge:
a peeled ally's incoming hit is blocked at YOUR shield's grade instead (the AtO Magnus
block-share; cross-seat absorb idiom exists in code) · boon *Eyes Front* (GREED) — while aggro is
PEGGED (≥95%), the boss swings +10% harder at you and the warband gains +damage: the ego-tax
greed, chosen by playing clean enough to peg it · keystone **THE STANDARD** — plant it on a
perfect SLAM: ~6s where your banner flies and every seat's answer windows widen a touch;
anything landed under it pays together. *(Skeptic-capped: at most ONE passive-aura card in the
theme; the theme is calls/uptime/clutches, not a stat cloud.)*
**Greed/comfort + EASE knob:** donation/ego greed (your meter dips, the warband shines);
comfort = plain uptime pay. Knob: line-grace (how long a slip stays forgiven before the
uptime buff drops).
**Nearest neighbor:** Tempo's BAND theme (groove-helps-everyone — rhythm-keyed); the Bannerman
pays for AGGRO uptime and clutch saves. **Engine debts flagged honestly:** the raid buff-channel
(already owed — Battle Hymn/Debilitator precedent) + a policy hook for share timing; peel-event
hooks arrive with the §1c build regardless.

---

### THEME 5 — THE THORNBACK · *touch the wall, bleed* (the honesty-note theme)

**What its cards do:** attrition reflect — but **only graded answers chip back** (good+ tap = a
sliver, perfect = a real chip; sloppy blocks reflect NOTHING — the skeptics de-passived it:
reflect is a REWARD for clean presses, never a stat that plays itself). One greed card windows
it into a burst.
**Dials addressed:** the tap · the line (the healer feels the steadier chip economy). No bends.
**Absorbs:** nothing built — the one theme that pays THE TAP dial directly (the bread button
everyone else treats as chores).
**Example new cards:** creed *Barbed Rim* — graded taps chip from run start (small, capped) ·
boon *Bristle* (STRAT) — after 4 consecutive graded taps the next reflect triples · boon *Let
Them Come* (GREED) — reflects double while your wind is under half: invite the pressure ·
keystone **QUILLSTORM** — a perfect HOLD through a full flurry fires every absorbed flurry-hit
back as a visible needle-volley across the gate.
**Greed/comfort + EASE knob:** pressure-greed (reflect scales when you're strained); comfort =
small steady chips. Knob: reflect grade-threshold (good+ vs perfect-only).
**Nearest neighbor:** Return to Sender/Payload (stores-and-hurls on YOUR timing, one big read) —
the Thornback ticks per answered press, no extra button, constant clock. AtO's Bree proves the
archetype carries a build.
**⚠ Honesty note:** the skeptics ranked this last — a reflect build is damage-poor-tank comfort
food and its ceiling is low. It stays in the slate because it's the only TAP-dial payer and the
"the wall fights back" fantasy is real; it earns a pick only if that lands for you.

---

### The existing-pool filing table (proof the themes organize the real cards)

| Card (state) | Files under |
|---|---|
| Return to Sender 🔮 | **PAYLOAD** (the seed) |
| The Wall rig 🔮 | **PAYLOAD** (premium WHEN) / RAMPART |
| Cheap Iron 🔮 | **RAMPART** |
| Feather Step (carry) | **RAMPART** (block-cost knob) |
| Deep Pockets (carry) | generic (BANK) |
| Powder Keg (carry) | generic (SPEND) / PAYLOAD-adjacent |
| ✦ Hold the Line (carry) | **BANNERMAN** (reframed onto flow, §1d) |
| "hold-all wall" module candidate | **RAMPART** (priced as The Bulwark Stance) |
| "dump variations" module candidate | **SLAM** module space |

### SLATE-LEVEL CHECKS + the pick

**Spread:** storage/GREED (Payload) · execution/counter (Slam) · endurance (Rampart) · TEAM
(Bannerman) · attrition/TAP (Thornback) — five clocks, no shared cadence (harvest #6).
**Skeptic record:** 3 passes · **1 pre-slate kill** (see skipped) · ~11 fixes folded (Siege≠
Avalanche sharpened · slam-vs-parry distinction stated · Thornback de-passived + demoted ·
Bannerman aura-capped + clutch-capped (rule 5) · entry-creed law applied to all five · Payload
decay = self-authored bite · Immovable never-a-toggle).
**Skeptic ranking (pick-tension, strongest→weakest):** Payload · Slam · Rampart · Bannerman ·
Thornback.
**Composition notes for a 2–3 pick:** Payload+Slam pair naturally (the Siege fires off a SLAM;
both love tall bars) — but both concentrate on the MAIN, leaving taps plain (add Rampart or
Thornback for tap texture). Rampart+Payload = the fortress (hold-heavy, slowest read). Slam+
Bannerman = the captain (counters + banners — the loudest warband fantasy). Bannerman needs the
buff-channel debt paid whichever pair it joins.
**Engine debts:** Bannerman's buff channel + share hook (flagged above) · everything else rides
existing surfaces (battery/chain/pool/reflect are kit-local state + existing instruments).
**BLOCK-law check (the dodge-law analogue):** no theme makes defense free (partial-mit law
holds; even Thornback's reflect leaves the sliver) · no self-heal anywhere (the rally steal was
converted to ◆/wind at the boon shape) · the healer duet keeps its work in every theme.
**AI-pilotable:** all five are threshold/timing policies (charge %, chain length, pool floor,
aggro %, tap grade) — no theme needs the policy to read anything the sim doesn't already emit.
**Skipped on purpose:** **the Wrecking Crew** (a ◆/DUMP burst theme — the skeptics' kill:
Headsman in a heavier coat, failed the nearest-neighbor bar) · **the Vampire** (rally-as-heal —
violates no-self-heal; its legal remnant is the "answer the wound" boon shape, filed) · **the
Juggernaut** (eat-hits-on-purpose HP-mass — griefs the healer duet and Blood Price is the
Duelist's; survives as at most one boon) · **the Pusher** (a full proactive-wind-spend theme —
too thin alone; folded into Rampart as a boon shape).

**Next:** Bill picks 2–3 → the Warden deck pass (§5 top item; SLATE-PLAN Phase 2 row D1 authors
it around the winners — creeds/modules/boons/rig/keystones/EASE knobs + CARD-CATALOG rows).

## §7 · THE DUELIST CHALLENGER SLATE — 3 challengers vs the v1 ladders 🟡 AT VERDICT (2026-07-10)

**⚠ Read this with the §3 board, not instead of it** (SLATE-PLAN row 2, kind = *challenger
slate*). Deck v1's three ladders ARE branch themes and they are **PITCH #0a/#0b/#0c** below,
restated in the slate anatomy so everything competes at one bar. **This section adds three
CHALLENGERS to the same verdict: Bill still picks 2–3 ladders TOTAL.** Incumbents win → deck v1
stands exactly as authored; a challenger wins → it swaps in at the Phase-2 deck revision (row
D2), inheriting the v1 verdicts that survive. Base kit untouched; example cards are
ILLUSTRATIONS — no CARD-CATALOG rows this pass. **How it was made:** knowledge base re-mined +
fresh sweep `research/duelist-sweep.md` (Sekiro streaks · SF6 Drive/burnout · Punch-Out's bait
puzzle · Nine Sols) → 4 lenses → 3 challengers → **3 skeptic passes (1 kill pre-slate, ~8 fixes
folded)**.

### The harvest (challenger-sized — what v1 leaves on the table)

1. **Nothing in v1 pays the READ.** Feints are a base mechanic (READ/BAITED) and Punch-Out
   proves the bait-puzzle carries a whole game — but v1 files one boon there (Read the Room,
   Ghost lane) and moves on. The biggest unclaimed dial.
2. **Nothing in v1 pays the WEAVE.** The all-or-eat-it-all flurry → free RIPOSTE is the kit's
   most dramatic instrument, and zero cards touch it.
3. **The blood shapes are scattered.** Blood Price + Overreach + Crucible all monetize damage
   taken, but they're filed across three lanes — the vampire-without-healing fantasy is sitting
   there un-assembled.
4. **SF6's burnout confirms the Crucible's crash design** (self-authored overspend penalty) —
   not a new theme; boon material for Ironside if it survives.
5. **Sekiro's escalating deflect streak** is half-present (The Rally); a boss-side posture bar
   stays parked (engine debt) — streaks stay kit-local.

### PITCH #0a — THE HEADSMAN (incumbent) · *bank it, then one huge answer*
Bank-and-burst on ◆: Wager creed → Whetstone → SWING/BANK/SPEND boons → 👑 THE AVALANCHE.
**Dials:** the bank · the spend. **Clock:** self-set hold-then-cash cycles. **Greed:** riding a
full sharp bank. EASE knob: (deck pass — bank-decay grace). *Full spec: §3.*

### PITCH #0b — THE IRONSIDE (incumbent) · *the fire feeds on what you eat*
The damage-taken engine: Veteran/Bellows → ⭐ Crucible → Blood Price/Overreach/Deep Pockets →
👑 THE IMPOSSIBLE PARRY. **Dials:** the wind · the duet. **Clock:** ignite cycles keyed to the
bleed. **Greed:** igniting early / spending to the brink (the SF6-burnout boon shapes land
here). *Full spec: §3. Note: post-GUARD-drop this ladder is purely the Crucible engine — its
old shield cards are the Warden's now (§6 filing table).*

### PITCH #0c — THE GHOST (incumbent) · *never touched, always moving*
The footwork chain: Dancer → Scales → Feather Step/Perfect Form/Read the Room → 👑 BORROWED
TIME. **Dials:** the step · the read (light). **Clock:** whole-fight streak. **Greed:** the
balance edge (Scales). *Full spec: §3.*

---

### CHALLENGER 1 — THE MATADOR · *the fight is won before you press*

**What its cards do:** the bait puzzle becomes the build. Correct READS (ignoring a feint) and
LATE answers (landing in the last slice of a window — deliberate, chosen per bar) build
**insight**; insight makes your next commit bigger. Taunt-grade moments (the boss's feint-heavy
verses) become YOUR verses. Punch-Out's grammar on our instrument.
**Dials addressed:** the read (the unclaimed dial) · the swing (insight's casher). No bends;
insight is a kit-local counter.
**Absorbs:** *Read the Room* (from the Ghost lane — its natural home) · the feint/unavoidable
authored stream (encounter data already carries it).
**Example new cards:** creed *Cold Blood* — reads build insight from run start; feints read a
touch slower (the tell is loud for you) · boon *The Late Answer* (GREED) — a parry landed in the
window's last slice counts double insight, a whiff there costs 2 · boon *Toro* (STRAT) — a
BAITED feint (you pressed) spends 1 insight to forgive the wind loss: the matador's cape-flick,
a play not a pardon · keystone **LA ESTOCADA** — at full insight your next perfect parry is THE
KILL READ: the stream visibly holds its breath (one silent beat), then your counter lands ×3
with the banked insight erupting. Spent, back to zero, earn it again.
**Greed/comfort + EASE knob:** patience-greed (the late answer, the held press); comfort = answer
early and safe, insight trickles anyway. Knob: feint-tell clarity (how loud hollow bars read).
**Skeptic fix folded:** insight also accrues (reduced) from clean reads of ANY bar type, so a
feint-light boss doesn't kill the theme; authored streams guarantee feint density per Seal.
**Nearest neighbor:** Tempo's PUNISH theme (lives on the Opening — offense windows); the Matador
lives on the DEFENSE stream's tells. The Warden has no feint-economy theme. Punch-Out is the
pedigree.

---

### CHALLENGER 2 — THE STORMWEAVE · *the flurry is your favorite part*

**What its cards do:** the weave→riposte instrument gets paid. Flurry appetite (cards that make
weaves richer), riposte riders (the free RIPOSTE becomes a build moment), weave-streak payoffs.
An execution-burst theme for the player who grins when the bars come fast.
**Dials addressed:** the step (weave events ONLY — skeptic-scoped: generic dodge-grade payoffs
stay the Ghost's; this theme keys strictly to weave/riposte events) · the spend (riposte
riders). No bends.
**Absorbs:** nothing — pure new cards on an unpaid instrument (the cleanest filing in the slate).
**Example new cards:** creed *Storm Footing* — clean weaves refund +1 wind from run start ·
boon *Eye of the Storm* (STRAT) — a clean weave's riposte also banks ◆ · boon *Thread the
Needle* (GREED) — your weave windows tighten 15% but a clean weave's riposte hits ×1.5: opt into
the harder dance · keystone **THE TEMPEST ANSWER** — a clean weave through a full flurry turns
your riposte into a mirrored flurry: your counter comes out as the SAME bar-string reflected
back across the gate, each press of it graded. The boss's hardest moment becomes your biggest.
**Greed/comfort + EASE knob:** density-greed (opt-in tighter weaves); comfort = weave at base
width, riders still pay. Knob: riposte-window width.
**Skeptic fix folded:** riposte riders extend at reduced value to parry-counters, so the theme
breathes between authored flurries.
**Nearest neighbor:** the Warden answers the same flurry bars with the HOLD (endurance) — the
Stormweave answers with execution. The Ghost owns generic footwork; composition warning: Ghost +
Stormweave both live on THE STEP — picking both piles one dial (legal, but flagged).

---

### CHALLENGER 3 — THE SCARLET TRADE · *your blood is a currency*

**What its cards do:** assembles the scattered blood shapes into one build — HP spent as a
resource, on YOUR terms. The Duelist already eats unavoidables by design (low HP, fast swings);
this theme makes the eating a ledger: blood spent → value banked, with hard floors and the
healer duet pricing every trade.
**Dials addressed:** the duet · the bank. No bends; no self-heal anywhere (the healer refills —
your job is making the bleed WORTH her time).
**Absorbs:** *Blood Price* (from the Bank lane — its natural capital) · *Overreach* (stays
Swing-filed, double-tagged) · synergizes with (never requires) the Crucible.
**Example new cards:** creed *Red Ledger* — unavoidables bank ◆ from run start (small) · boon
*Paid in Iron* (STRAT) — while below 60% HP your counters +12/18/25% · boon *The Deep Cut*
(GREED) — once per bank-cycle, VOLUNTARILY eat a normal bar unanswered: it banks ◆◆ and +3 wind;
never below 25% HP (chosen per use — the self-cut) · keystone **CRIMSON DIVIDEND** — spending a
full bank while under 40% HP pays the dump ×2 and the gate floods red; the healer's refill of
that dip visibly pours into your next bank (the duet made spectacular).
**Greed/comfort + EASE knob:** literal blood-greed (floors stated on every card); comfort = trade
only what the stream forces. Knob: blood-floor height (how deep the cards let you go).
**Skeptic fixes folded:** every HP-spend card carries a floor (Overreach precedent); the duet
coupling is flagged as tuning surface (a blood build makes the healer's job harder — priced at
the deck pass, and it's TEXTURE for the §1c "healer follows the boss" work, not a conflict).
**Nearest neighbor:** WoW Blood DK (vampiric — ours never self-heals; the warband's healer is
the other half of the trade) · the Warden's skipped "Juggernaut" (eat-on-purpose was WRONG for
the no-unavoidables shield kit; it's native here — the kits stay different, per the §1b split).

---

### SLATE-LEVEL CHECKS + the pick

**Spread across all six:** bank-burst (#0a) · engine/brink (#0b) · streak (#0c) · read (C1) ·
event-burst (C2) · blood ledger (C3) — six clocks, no shared cadence; C1 is the only theme in
the CLASS that pays not-pressing.
**Skeptic record:** 3 passes · 1 pre-slate kill (**the Planted Blade** — Nine Sols
plant-and-detonate: triple-collision with Fermata's Mark / Tempo's Wound / the Warden's Payload)
· ~8 fixes folded (Matador feint-drought valve · Stormweave scoped to weave-events-only + the
Ghost composition warning · Scarlet floors + duet-pricing flag · SF6 burnout filed as Ironside
boon material, not a theme).
**Challenger ranking (pick-tension, strongest→weakest):** Matador · Scarlet Trade · Stormweave.
The slate does NOT re-rank the incumbents — that's the live §3 board; these three are offered
INTO it.
**Composition notes:** Matador + any incumbent composes cleanly (new dial, no collisions).
Scarlet + Ironside is the natural pair (both monetize the bleed — one build, two engines;
flag: check the healer's workload at the deck pass). Ghost + Stormweave piles THE STEP (flagged
above). Headsman + Scarlet both feed THE BANK — legal, rich, watch auto-pick pressure on bank
boons.
**Engine debts:** none for Matador/Scarlet (kit-local counters + existing floors idiom);
Stormweave's mirrored-flurry keystone needs the riposte instrument to render a returning string
(the Avalanche already proves the shape).
**AI-pilotable:** Matador = press-timing offset + feint-classification the policy already does ·
Stormweave = weave-entry decision (threshold) · Scarlet = HP-floor-aware trade timing (threshold)
— all expressible at 3 tiers.
**Skipped on purpose:** **the Planted Blade** (killed — collision, above) · **the Burnout**
(SF6 spend-crash as its own theme — the Crucible IS that cycle; folded to boon shapes) · **the
Posture-Breaker** (Sekiro boss-bar — engine debt, parked with the old Counterpoint pitch) ·
**a Duelist TEAM theme** (the Warden's Bannerman owns the tank class's TEAM lane this round;
two tank TEAM themes would split the same warband surface).

**Next:** these three join the §3 verdict board — Bill picks 2–3 ladders TOTAL across
incumbents + challengers → the Phase-2 deck pass (row D2) authors/revises around the winners.

## §8 · THE WARDEN DECK v1 — full deck around PAYLOAD · SLAM · RAMPART 🟡 AT VERDICT (2026-07-10, Phase-2 D1)

**What this is** (SLATE-PLAN row D1; deck-creator playbook end-to-end; design only). **Winners =
the §6 skeptic ranking's top 3: THE PAYLOAD · THE SLAM · THE RAMPART** (your ✅ picks override —
Bannerman/Thornback cards stay filed in §6 and swap in cheap). Unlike the Duelist this is
FROM-SCRATCH authoring: the only inherited material is the 🔮 re-homed guard trio (Return to
Sender · Cheap Iron · The Wall) + the 4 verified carries. Base kit untouched (§1b); numbers are
first-cut `warden_*` knobs.

### 8.0 DIALS + BUDGET

**Dials:** THE READ · THE TAP · **THE HOLD** (Warden-only) · THE SLAM · THE WIND · THE BANK ·
THE SPEND · THE LINE — plus **THE CHARGE (the Payload's new dial: the battery of prevented
damage)**. **Budget:** buttons = BLOCK · SHIELD · DUMP ~~· TAUNT~~ *(deleted 2026-07-10,
`BOSS-PLAN §1`)* + the owed signature CD ("the
wall", §1b) = 4 of 7; nothing below adds one. Boons land at 12 (in-quota); modules 3 (one per
theme); keystones 3.

### 8.1 CREEDS (pick 1 · pool of 5 — quota shapes all present)

| Creed | Type | Theme | Effect (one line) |
|---|---|---|---|
| **The Sentinel** | EASE | — (the learner) | Block grades ~30% wider · SLAM counter −25% · ◆ cap 4. Caps itself so you graduate out (the Veteran's shield-side twin). |
| **Ballast** | STRAT | PAYLOAD entry | The battery is LIVE from run start (modest cap until the module deepens it); decays per §8.3 law. |
| **The Drumhead** | GREED | SLAM entry | Slam chains grant +1 wind per link; the chain breaks on a graze (not on taps). |
| **Deep Keel** | STRAT | RAMPART entry | Wind pool +20%, recharge unchanged — a bigger, heavier bar; holds run longer, droughts run longer. |
| **THE MONOLITH** | RULE | **WILD** | **BLOCK is GONE** — the SHIELD is your only answer: every bar is HELD through (small ones drain little), taps don't exist. One button, pure hold-reading + drain economy — the mobile creed (the Dancer's shield-side mirror). |

### 8.2 MODULES (Floor-1 pick 1-of-3 · one per theme, no transformer required)

| Module | Type | Theme | Effect |
|---|---|---|---|
| **The Coil** | STRAT | PAYLOAD | The battery GAUGE renders (charge + decay arc); clean taps also feed it at 25%. The hurl decision lives here. |
| **Aftershock** | STRAT | SLAM | A 2s window after every perfect SLAM where BLOCK taps cost 0 wind. The chain's breathing room — earned, rhythmic. |
| **The Bulwark Stance** | GREED | RAMPART | The priced hold-all wall (the old base, §5): while HELD, every bar is blockable — but drain +40%. Opt into the fortress, pay in wind. |

### 8.3 BOONS (12 · by dial-lane · each names its theme · ≥1 greed/lane · 0 pardons)

**THE CHARGE (Payload's lane):**
- **Return to Sender** [STRAT · re-homed 🔮→🟡, verbatim] — the shield stores 40/55/70% of
  prevented damage and HURLS it back as a bar when it drops. The theme's seed.
- **Heavy Shipment** [GREED] — battery capacity +50%, decay +50%: ride it big, cash it hot.
- **Special Delivery** [STRAT] — a hurl released during a tall-bar wind-up pays ×1.25 (H/S/O:
  1.25/1.35/1.5) — read the boss, time the throw.
**THE SLAM:**
- **Offensive Guard** [POWER] — after a perfect SHIELD, your next DUMP +15/22/30% (the MonHun
  steal, named).
- **Meet It Head-On** [GREED] — answering a small/normal bar with the MAIN (full wind price)
  banks ◆ — chosen per bar, the chain-keeper's tax.
- **Drumfire** [STRAT] — every 3rd consecutive clean SLAM banks ◆◆; a graze breaks the count
  (taps never do). *(The Rally's every-3rd idiom on a different instrument — recorded.)*
**THE HOLD / THE WIND (Rampart's lane):**
- **Cheap Iron** [EASE · re-homed 🔮→🟡] — shield raises cost 45/50/55% less.
- **Second Wind** [STRAT] — a hold RELEASED above half-pool refunds 2/3/4 wind — ending the
  hold cleanly is a move.
- **White Knuckles** [GREED] — below 25% wind your taps mitigate +15/20/25%, but a whiffed
  press empties the pool: brinkmanship you opted into.
- **The Push** [STRAT] — pay 2 wind (8s cooldown): the incoming bar is BLUNTED one size
  (tall→normal→small). Proactive defense, chosen per use (the Vermintide push, priced).
**THE BANK / THE SPEND (generic):**
- **Deep Pockets** [POWER · carry] — ◆ cap +1 / +1 & start 1◆ / +2 & start 1◆.
- **Powder Keg** [POWER · carry] — DUMP +20/30/40% per ◆.
**Carries verified:** Feather Step (block-cost knob — subsumed by Cheap Iron's lane; offered
class-wide, not double-stacked: pick-tension pair, both never in one offer... flag for the
build) · ✦ Hold the Line = the SUPPORT (below).

### 8.4 RIG (WHENs → the class THEN table: STRIKE/IRON/BREATH/PIP/BANNER)

- **The Wall** [re-homed 🔮→🟡, premium ~3.5] — WHEN my shield eats a hit ≥15% max HP.
- **The Long Hold** [NEW, ~2.5] — WHEN I hold through a FULL flurry without dropping.
- **The Counterweight** [NEW, ~2.0] — WHEN I SLAM a tall bar (the Duelist's Tall Land shape on
  the shield instrument — same class, shared table, fine).

### 8.5 KEYSTONES (elite-only · pool of 3 · run 1 — all three from §6, engine-checked)

- **THE SIEGE** [PAYLOAD] — at full charge your next SLAM launches the stored total as ONE
  colossal returning bar across the gate; press it as it crosses = ×2. (One titan bar — the
  Avalanche string's opposite, distinctness held.)
- **BREAKWATER** [SLAM] — a perfect SLAM on a tall bar visibly SHOVES the next bar back down
  the lane (the superior-block steal; same-instrument spectacle, no boss-side state).
- **THE IMMOVABLE** [RAMPART] — survive a full flurry HOLD above a quarter pool → the shield
  ROOTS ~4s (bars shrink as they arrive), then the drain debt lands. Earned, never a toggle.

### 8.6 SUPPORT · SIGNATURE CD · EASE

- **Support:** ✦ **Hold the Line** [TEAM · carry] — while THE LINE HOLDS (no unanswered real
  hit 5s), warband +6/8/10%. At build: re-key the uptime read onto FLOW per §1d (aggro-visible).
- **SIGNATURE CD (the owed "wall", §1b — first shape):** **THE GATE** — ~1-min CD: for 4s your
  shield stretches over the warband (all seats' incoming −X%, where X scales with your CURRENT
  wind %). Line it up with a boss window; a drained Warden opens a weak Gate — the CD amplifies
  pool discipline, never button=damage. Carries the dropped-GUARD lineage.
- **EASE dial knobs:** hold-drain grace (Rampart) · charge-decay grace (Payload) · slam-window
  width (Slam — tapers with power) · block-grade threshold. Comfort free / bite +damage, per
  DECK-LAYOUT §4.

### 8.7 COHERENCE-GATE EVIDENCE

**Dream drafts:** *PAYLOAD:* Ballast → The Coil → RtS + Heavy Shipment + Special Delivery →
THE SIEGE — charge from run start → the gauge makes the hurl a read → capacity greed → the
titan bar. Compounds ✓. *SLAM:* Drumhead → Aftershock → Offensive Guard + Meet It Head-On +
Drumfire → BREAKWATER — chains feed wind → free-tap windows → ◆ engine → the shove. ✓
*RAMPART:* Deep Keel → Bulwark Stance → Cheap Iron + Second Wind + White Knuckles + The Push →
THE IMMOVABLE — big pool → hold-all pricing → economy mastery → the root. ✓ *Hybrid
(Payload×Rampart, "the fortress"):* Bulwark Stance holds everything → everything held charges
the battery → one Siege. Stated in §6, now draftable. ✓
**Offer-trio spot-checks:** (Heavy Shipment | Meet It Head-On | White Knuckles) — three greeds,
three pools ✓ · (RtS | Offensive Guard | Second Wind) — three builds ✓ · (Deep Pockets |
Powder Keg | Cheap Iron) — three breads: FLAGGED, the build should weight offers so at most
two breads share a trio (draft-weighting note, not a card change).
**Overlap audit:** Cheap Iron vs Feather Step (same knob!) — resolved: never co-offered, flag
at build ✓ · Second Wind vs Cheap Iron (refund vs discount — different moments: release vs
raise) ✓ · each theme ≥3 exclusive ✓.
**Anti-patterns:** RtS = stored PLAY not passive ✓ · no stat keystones · no new buttons (the
Monolith REMOVES one — Dancer precedent) · caps stated · zero pardons (the partial-mit law
keeps the healer fed; nothing here forgives) ✓.
**AI-pilotability:** Payload = charge-%-and-boss-window thresholds · Slam = chain-length +
commit pricing · Rampart = pool-floor management (the §6 note holds: all threshold policies,
3 tiers natural). Sim cells named: `warden_sim --build=payload|slam|rampart`.

### 8.8 SKEPTIC RECORD (3 passes)

- **Draft-table:** killed **Iron Reserves** (battery-speed POWER bread — bread flooding; its
  job lives in The Coil's 25% feed); found the three-bread trio → draft-weighting flag; pool
  lands at 12.
- **Repack:** the Monolith vs the old hold-all base — priced (drain economy exists now; it's a
  CREED cost, not free); Drumfire vs the Duelist's Rally — same idiom, different instrument +
  break condition, recorded in the distinctness ledger; the Siege/Avalanche split re-verified
  (one titan bar vs a per-◆ string).
- **Fight-clock:** Payload cycles ~15s at zone damage (decay keeps it honest) ✓ · the
  Immovable needs authored flurries — every Seal stream has them; zone packs = the keystone
  sleeps sometimes (acceptable for elite-tier) — noted honestly.

### 8.9 OPEN TENSION POINTS (Bill's calls)

1. **THE MONOLITH** — the one-button wild creed (the Dancer's mirror): ship in pool, or park
   until the mobile pass? (Lean: ship — the pool needs its WILD and the phone case is real.)
2. **THE GATE** — the signature-CD shape (wind-scaled warband wall). Accept? (Lean: yes.)
3. **Feather Step vs Cheap Iron** — keep both with never-co-offered weighting, or fold Feather
   Step to Duelist-only? (Lean: fold to Duelist-only; one block-cost card per spec.)
4. **Drumfire/Rally rhyme** — acceptable sibling idiom or differentiate further? (Lean: accept.)
5. All numbers (◆ cap, drain rates, charge caps) = first-cut knobs; the §1c flow-economy
   playtest rule applies.

**Next:** your verdicts → CARD-CATALOG statuses flip → the Warden build claim (§5 top item)
codes it guarded after the Duelist base proves the frame (Wave-1 order unchanged).

## §9 · THE DUELIST DECK v2 — the reconcile + the swap kits 🟡 AT VERDICT (2026-07-10, Phase-2 D2)

**What this is** (SLATE-PLAN row D2). Deck v1 (§3) is at your LIVE board with no verdicts in
yet — so this pass does NOT re-author it. It ships the two things a v2 owes: **①** the **v1.1
RECONCILE** — errata for everything that moved under v1 since it was written (flow=aggro went
BASE · the EASE-dial law · the GUARD fallout · §1d ripples), and **②** three **SWAP KITS** —
the §7 challengers pre-authored to card level, so WHATEVER 2–3 ladders you pick, the deck is
ready without another design pass. Incumbents (Headsman · Ironside · Ghost) stay the default
top-3. Design only; catalog rows land 🟡.

### 9.1 THE v1.1 RECONCILE (errata to §3 — fold on verdict, none change a card you've rated)

1. **FLOW=AGGRO is BASE now (§1c)** — v1 predates the lock. The repurposed **FLOW module**
   ("your flow ALSO ramps DUMP damage") becomes the **4th Floor-1 candidate** next to
   Crucible/Scales/Whetstone. Modules quota is 2–3 → **tension point: offer 3-of-4 rolled, or
   cut one** (lean: 3-of-4 rolled — the Floor-1 pick gets pick-tension for free).
2. **EASE-dial fold (standing law, DECK-LAYOUT §4):** **Quick Wrists** and **Roll With It**
   leave the boon pool; the ONE EASE dial card replaces them (knobs rolled from: parry-window
   width · dodge-grade grace · wind-regen · The Veteran creed stays curated). Pool 15 → 13 + dial.
3. **✦ Hold the Line** re-keys its uptime read onto FLOW (aggro-visible — §1d; same errata as
   the Warden's copy).
4. **GUARD fallout cross-ref:** Return to Sender · Cheap Iron · The Wall now live in the
   WARDEN deck (§8, 🟡) — the 🔮 park is resolved; v1's SPEND lane stays DUMP-only.
5. **Crucible note (§1d):** fills slower while the boss is peeled away — a natural aggro-skill
   coupling, stated on the card at build.
6. **Interrupt flag (§4.6):** ⚡DUMP is the tank's pillar-#3 carrier — no card change, noted.

### 9.2 THE SWAP KITS (each = a ladder-shaped drop-in: entry creed + boons + keystone)

**Swap rule:** picking a challenger REPLACES one incumbent ladder's exclusive cards; generics
(Deep Pockets · Powder Keg · breads) stay. Kits are sized to the ladder they'd replace.

**KIT M — THE MATADOR** *(natural swap: the Ghost, or a 4th ladder if you expand)*
- creed **Cold Blood** [STRAT] — reads build INSIGHT from run start; feint tells read louder.
- boon **The Late Answer** [GREED] — a parry landed in the window's last slice counts double
  insight; a whiff there costs 2 (H/S/O: ×2/×2+1 wind/×3).
- boon **Toro** [STRAT] — a BAITED feint spends 1 insight to forgive the wind loss — the
  cape-flick, a play not a pardon (≤1 forgiveness in the kit ✓).
- absorbs **Read the Room** (from the Ghost lane — its natural home).
- keystone **LA ESTOCADA** — at full insight your next perfect parry is THE KILL READ: the
  stream holds its breath one beat, then the counter lands ×3. *(⚠ rhyme recorded: the Cold
  Hand's Reckoning Stroke (TEMPO §17) also freeze-frames — two still-beat finishers in the
  roster; tension point 3.)*

**KIT S — THE SCARLET TRADE** *(natural pair/swap: the Ironside — both monetize the bleed)*
- creed **Red Ledger** [STRAT] — unavoidables bank ◆ (small) from run start.
- boon **Paid in Iron** [STRAT] — below 60% HP your counters +12/18/25%.
- boon **The Deep Cut** [GREED] — once per bank-cycle, voluntarily eat a normal bar unanswered:
  banks ◆◆ +3 wind; never below 25% HP (the self-cut, chosen per use).
- absorbs **Blood Price** + **Overreach** (double-filed from v1 lanes).
- keystone **CRIMSON DIVIDEND** — a full-bank dump under 40% HP pays ×2, the gate floods red,
  and the healer's refill of that dip visibly pours into your next bank (the duet spectacular).
  *(Healer-workload pricing flagged for the build, per §7.)*

**KIT W — THE STORMWEAVE** *(natural swap: the Ghost — same dial, flagged in §7)*
- creed **Storm Footing** [STRAT] — clean weaves refund +1 wind from run start.
- boon **Eye of the Storm** [STRAT] — a clean weave's riposte also banks ◆.
- boon **Thread the Needle** [GREED] — weave windows tighten 15%, clean-weave ripostes ×1.5.
- boon **Rolling Thunder** [POWER · NEW] — riposte damage +20/30/40% (the kit's bread rung).
- keystone **THE TEMPEST ANSWER** — a clean weave through a full flurry mirrors it back: your
  riposte comes out as the SAME bar-string reflected across the gate, each press graded.

### 9.3 GATES + SKEPTICS (delta-scope — v1's own audit stands untouched)

**Trios:** each kit internally trio-clean (1 creed + 3–4 boons never share an offer with 3
breads) ✓. **Overlap:** Kit W + Ghost = the flagged same-dial pile (the swap rule makes it
moot — W REPLACES Ghost unless you deliberately run both) · Kit S + Crucible = the bleed-fuel
supermerge (legal, rich, healer-priced — stated). **Anti-patterns:** all §7 fixes carried
(floors, opt-ins, ≤1 forgiveness); Rolling Thunder is the only new card this pass and it's
honest bread. **Distinctness:** Estocada/Reckoning-Stroke freeze-beat rhyme RECORDED (tension
point); Tempest-Answer vs Avalanche/Siege — mirrored STRING vs ◆-string vs titan-bar: three
returning shapes, all different reads, ledger row updated. **AI:** insight/HP-floor/weave-entry
thresholds — all 3-tier expressible (per §7).

### 9.4 TENSION POINTS (Bill's calls)

1. **The module question:** 3-of-4 rolled Floor-1 offer (Crucible/Scales/Whetstone/FLOW), or
   cut one? (Lean: 3-of-4.)
2. **The EASE fold** (Quick Wrists + Roll With It → the dial) — accept? (Lean: yes, standing law.)
3. **The freeze-beat rhyme** — LA ESTOCADA vs the Reckoning Stroke: keep both (different
   classes, similar drama) or re-skin one? (Lean: keep both, different enough in play.)
4. **Swap semantics** — challengers REPLACE a ladder vs EXPAND to 4 ladders? (Lean: replace;
   ~13-card pool can't feed 4 deep ladders.)
5. Your v1 board verdicts remain the gating event — this § folds into §3 the moment the export
   blob lands.

**Next:** your picks (2–3 ladders total across the six) → fold: winning kits' rows flip 🟡→✅,
losing kits park 🔮 with their slate; the build claim proceeds per §4 order unchanged.

## §10 · THE DUELIST ABILITY PASS — transforms, not buttons + EN GARDE 🟡 AT VERDICT (2026-07-10)

**What this is (Bill's direct ask):** the Tempo ability treatment (`TEMPO-PLAN.md §17.10/§17.11` —
the worked reference; `DECK-LAYOUT.md §5` carries the law) applied to the dodge tank. The top-3
ladders stay the incumbents **HEADSMAN · IRONSIDE · GHOST** (the D2 default — your live §3 board
still swaps any of them; the §9.2 swap kits stand untouched, and transforms rewrite BUTTONS, not
ladders, so every pick-combination keeps all three transforms). This pass: **①** the button audit
under the +1/ceiling-6 law, **②** the owed signature CD designed (**EN GARDE**), **③** THREE
ABILITY TRANSFORMS with door sub-boons, **④** the ladders refit so each has a transform affinity.
Design only — no code, catalog rows land 🟡 this commit.

### 10.1 THE BUDGET + THE BUTTON AUDIT (the law, run honestly)

**Touch targets:** DODGE + PARRY + ⚡DUMP + EN GARDE (the CD, designed below) = **4 of the
hard-ceiling 6**. **The +1 allowance slot: THE DUELIST LEAVES IT EMPTY** (Tempo precedent —
freshness comes from transforms, and Bill's steer is anti-bloat). Nothing below adds a button;
doors gate BOONS, never inputs.

**Every button needs a WHEN, not just a WHAT (law rule 4):**
- **DODGE ✓** — graded per bar, height law, the WEAVE. Richest button in the roster.
- **PARRY ✓** — the commit: tall bars, tiny window, land-or-miss. The identity press.
- **⚡DUMP ✗ — the storyless press.** Its only WHEN today is "the bank is full" — that's
  press-when-ready, a passive in a button costume. The v1 deck decorates it (Powder Keg / All In
  scale it) but nothing gives it a MOMENT. **FLÈCHE (transform 3) exists to fix exactly this** —
  the same itch that started Tempo's audit ("nothing about coup").
- **Post-taunt hole (BOSS-PLAN §1):** the taunt died; the tank's only attention tools are passive
  flow + the GAZE boon lane. The signature CD lands on this surface — as an AMPLIFIER, never an
  override (the "only way back is playing clean" law holds).

### 10.2 THE SIGNATURE CD — ⏱ EN GARDE `engarde` (the challenge; the tank's "wall")

~1-min CD. You plant your feet and CALL THE BOSS OUT — a ~4s challenge window:
- **The invitation:** melee tempo at you +~25% while it holds (more bars = more answers — you
  asked for this).
- **The wall (the old GUARD's mitigation, re-homed per §1b):** your leaks and slivers are HALVED
  while the challenge holds.
- **The payoff:** every clean answer pays **DOUBLE flow**; a PERFECT MAIN inside the window banks
  **◆◆**. Two slips and the challenge BREAKS early (the boss loses interest; normal flow drops
  apply).
**Why it's legal:** amplifies skill, never button=damage — it pays NOTHING if you don't answer.
It never touches targeting (no peel-freeze, no taunt costume): if your aggro collapsed, En Garde
doesn't yank the boss back — it doubles the rate at which clean play does. Role-shaped: press it
INTO the burst you see coming (the boss window law). One knob: window length. *(The Warden's THE
GATE stays its own shape — role twins, different instruments.)*

### 10.3 THE TRANSFORM SYSTEM (inherited verbatim from TEMPO §17.11)

A TRANSFORM is a drafted card that REWRITES one existing button. **≤1 transformed ability per
run** · proposed acquisition **1-of-3 at the Floor-2 elevation** (rides Bill's Tempo verdict ③ —
whatever he picks there is the pattern) · **every transform is a DOOR**: taking it gates its 2
sub-boons into later offers (never dead cards) and adds ONE rig WHEN to the wiring board · never
a new touch target. Fencing vocabulary throughout (the class's own words, like Tempo's music).

**THE THREE (parry-weighted — the MAIN is the identity button; DUMP gets the story it lacks):**

1. **PRISE DE FER `prisedefer` (PARRY transform)** — *"take the blade."* A PERFECT parry no
   longer counters instantly: it **SEIZES the bar** — the caught attack hangs at your gate, wind
   draining while you hold (≤ ~1.2s); release **THROWS it back**, damage scaling with the seized
   bar's power and hold length (cap: a full seize of a tall bar ≈ today's counter ×1.5 — the
   ceiling law). Non-perfect parries behave exactly as today. The instant jackpot becomes a
   hold/release read: dump the throw into the stream's gap, or cut it short before the next bar
   arrives. **Affinity: IRONSIDE** (wind-economy pressure; Bellows/Crucible feed the drain).
   - door **Disarm** [STRAT] — a full-length seize DOWNGRADES the boss's next bar one size
     (tall→normal, normal→small).
   - door **Wrenched Steel** [GREED] — seize drains wind ×2, the throw +40% (cap stated).
   - rig WHEN: *"I throw a full seize"* (~×5, inverse-frequency priced).
2. **REMISE `remise` (PARRY transform)** — *"the renewed attack."* Parry becomes **two
   half-presses**: the **PRIME** (~1/3 the wind, early — sets your guard: a primed bar you then
   fail to answer leaks 30% less) and the **COMMIT** inside the window (the remaining cost — full
   parry + counter). You choose commitment mid-flight: prime the bar you're unsure of, commit
   only when it's real; a primed FEINT costs only the prime (the read got cheaper, not free).
   The fixed all-or-nothing becomes a flexible spender — Cadenza's exact grammar on the defense
   side. **Affinity: GHOST** (read-flavored footwork; pairs naturally with Kit M's insight if the
   Matador wins a slot — flagged, not required).
   - door **Second Intention** [STRAT] — a committed remise (both presses landed) banks +1◆
     (the planned second attack pays).
   - door **Beat Parry** [POWER] — the prime alone deflects harder (primed-miss leak −30%→−45%).
   - rig WHEN: *"I commit a remise on a TALL bar"* (~×4.5).
3. **FLÈCHE `fleche` (DUMP transform)** — *"the running attack."* DUMP no longer fires from
   standing: pressing it **LOADS the bank onto your blade** (~2.5s); your next **PERFECT answer**
   (land or step) releases it as the charging strike — the full dump **+25%**, riding the
   counter's moment. If nothing perfect comes before the load expires, **half the ◆ return, the
   rest fizzles** (the greed is choosing WHEN you can afford to promise perfection). The spender
   finally has a WHEN — offense fused onto defense. **Affinity: HEADSMAN** (the one huge answer,
   now skill-stamped) — and the Ghost releases it off perfect steps.
   - door **Running Edge** [POWER] — flèche damage +15/22/30% (cap stated).
   - door **Point in Line** [STRAT] — a flèche released on a TALL-bar land staggers the stream
     half a beat (the follow-up gap widens — a breath you earned).
   - rig WHEN: *"a flèche releases on a perfect answer"* (~×5).

### 10.4 THE LADDER REFIT (the top-3, restated onto the new plan — v1.1 folded as FINAL)

The §9.1 reconcile stops being errata and is adopted here: **Quick Wrists + Roll With It → the
EASE dial** (pool 15→13+dial) · **FLOW module = 4th Floor-1 candidate, offered 3-of-4 rolled** ·
**Hold the Line keys its uptime read to FLOW** · GAZE lane (Lodestone / Hard Stare) is the
aggro insurance · GUARD trio lives with the Warden. Each ladder now reads entry → module → boons
→ **transform** → capstone:

- **THE HEADSMAN** — Wager → Whetstone → Heavier Steel · High Line · Deep Pockets · Powder Keg ·
  All In → **FLÈCHE** (+Running Edge / Point in Line) → 👑 THE AVALANCHE. *Dream draft:* bank fat,
  sharpen it, load the flèche, release it off a tall land — then the Avalanche returns the whole
  string. Every rung raises the promise you have to keep.
- **THE IRONSIDE** — Veteran/Bellows → ⭐ Crucible (or FLOW) → Blood Price · Overreach · Deep
  Pockets → **PRISE DE FER** (+Disarm / Wrenched Steel) → 👑 THE IMPOSSIBLE PARRY. *Dream draft:*
  the bleed fuels the Crucible, the seize spends the wind the Bellows rebuilds, Disarm shrinks
  what you'd have eaten — the engine breathes in hits and breathes out counters.
- **THE GHOST** — Dancer → Scales → Feather Step · Perfect Form · Read the Room → **REMISE**
  (+Second Intention / Beat Parry) → 👑 BORROWED TIME. *Dream draft:* primes ride the footwork
  rhythm, commits land only on the real bars, the Scales stay centred because both buttons pay.
  ⚠ **Dancer×transform law:** under the Dancer (parry button GONE) the two parry transforms have
  no host — the Floor-2 offer EXCLUDES them for Dancer runs (flèche + a re-offer). Stated now so
  the ceremony can't deal a dead card.
- **Cross-feed:** all three transforms read your ladder for nothing — they rewrite the button
  itself; the doors are where the ladder-flavor lives. A swap-kit win (M/S/W) changes NONE of
  this section (kits replace ladder cards, not buttons).

### 10.5 GATES + SKEPTICS (delta-scope — §3/§9 audits stand)

**Anti-patterns:** no new buttons (4 of 6, slot empty) ✓ · no passive wind-ups (the flèche load
is a chosen promise with a priced expiry, not a wait) ✓ · doors never dead (offer-gated on the
transform being held) ✓ · insurance count unchanged (the prime is PRICED cover — wind spent for
partial mitigation, Toro's precedent — not a pardon) ✓ · every scaler capped ✓.
**Trio spot-check (doors enter later offers):** (Disarm | Wrenched Steel | Heavier Steel) — plan
vs greed vs bread, no auto-pick ✓ · (Second Intention | Running Edge | The Rally) — three banks,
three clocks ✓.
**Repack skeptic:** Prise de fer vs Borrowed Time — seize freezes ONE bar you caught; Borrowed
Time slows the whole stream (keystone-scale). Different reads, recorded. Remise vs the Veteran
creed — the creed forgives misses run-long; the prime is a per-bar purchased hedge. Flèche vs
Avalanche — the load times ONE release; the keystone re-plays the string. All three survive.
**Fight-clock skeptic:** all three transforms cycle multiple times inside a 60s zone fight
(seize per perfect parry · prime per bar · load per bank) ✓; nothing hoards across fights ✓.
**Engine debts (small, kit-local):** the seized-bar hold state + thrown-bar render (the
Avalanche's returning-bar shape proves it) · the flèche load timer · En Garde's melee-tempo
window (the §1c "3 scalars" knob, briefly turned — deterministic, tick-counted, no scheduler
change). No new systems.
**AI-pilotability (one sentence each):** Prise de fer — hold-length policy = f(wind, next-bar
ETA), 3 tiers by hold-precision · Remise — prime-rate + commit-threshold on the existing
feint-classifier · Flèche — load only when P(perfect answer < 2.5s) clears a tier-scaled bar.
All on surfaces the tank policy already reads.

### 10.6 TENSION POINTS (Bill's calls)

1. **The three transforms** — Prise de Fer · Remise · Flèche: keep/tweak/cut per card?
2. **EN GARDE as the Duelist CD** — the challenge shape (invite + wall + double flow), and: is
   a pure amplifier ENOUGH of a post-taunt clutch, or does the class want one harder attention
   tool? (Lean: amplifier only — BOSS-PLAN §1's law is yours and it's clean.)
3. **Acquisition** rides your Tempo verdict ③ (Floor-2 ceremony 1-of-3 is the lean there).
4. **The +1 slot stays EMPTY** (transforms carry freshness) — veto adds a spell lane back.
5. **The v1.1 adoption** (EASE fold · FLOW 3-of-4 · Hold-the-Line re-key) — this pass treats it
   as final; say the word if any piece should wait for the v1 board export instead.

**Next:** verdicts → CARD-CATALOG flips (rows landed 🟡 this commit) → transforms build with the
deck layers in §4 step 3 (kit-local, guarded, byte-identical unpicked — same bar as everything).

## §11 · THE BIG-SWING ANSWER — CHARGED PARRY + THE WEAVE REWORK (Bill, 2026-07-14) 🔨 BUILDING

**Bill's read (playtest):** the Seals' big wind-up swings ("big wait up and charge") resolve as
a NORMAL parry — the long castbar makes them *easier and slower* than the stream, the opposite
of a marquee moment. And the weave is "way too slow … always straight": 4 notes, one constant
0.35 gap, no rhythm to read. His steer: **a hold/charge answer for the true single big hit; the
weave — faster, more notes, random rhythms — for everything multi-hit.**

### 11.1 THE CHARGED PARRY (the gather → the release)

The boss charges up — **so do you.** Applies to every **strikeless DEFENSIBLE telegraph aimed
at the tank with size = CRUSH** (keyed off size — zero boss-data edits):

| Seal | The big swing (cast) | Answer now |
|---|---|---|
| Vorathek | Riftmaw Crush (2.5s) | **CHARGE** |
| Mistral | Model Compression (2.4s) | **CHARGE** |
| Gemini | Benchmark Hammer (2.4s) | **CHARGE** |
| Mythos | Alignment Hammer (2.4s) | **CHARGE** |

HEAVY quick swings (Rending Talon 1.8 · Efficient Backhand 1.7 · Red-Team Probe 1.6 · the add
swings) stay tap-parries — they're not "wait-up" offenders. Gemini's Double-Check keeps its
read-string (it's a feint test, not a charge-up). Stream `buster` bars stay tap-parries (they
ride the rhythm).

**The mechanic (two axes: COMMIT + TIMING):**
- **PRESS AND HOLD parry** during the wind-up = the GATHER. Press-down pays `parry_cost` wind
  (the commit). If a claimable stream bar is in ±claim range at press-down, the normal claim
  wins (you wanted that bar) — the gather only arms on a clean press.
- **RELEASE at impact** — graded on the one claim ladder, parry law (top two tiers land).
- **THE COMMIT LAW:** the hold must reach **`charge_min_frac` (0.5) of the wind-up** for the
  release to land at all. A late tap-parry = FLINCH (token `mit_parry_miss`, slip) — the lazy
  "wait and tap" answer is dead. Early release / holding past the late slack = FLINCH too.
- **Payoff on a land:** mit .95 (the one above-cap payout, unchanged) + **CHARGED COUNTER** =
  `counter_dmg × (1 + charge_frac × charge_counter_mult)` + ◆ (**2 pips** at
  `charge_full_frac` ≥ 0.9 — the FULL GATHER — else 1) + the flow spike.
- **The tension:** the stream NEVER pauses (§2 law). While your parry hand is committed,
  **DODGE stays live — and ⯃ HEAVY stream bars become dodge-legal (with the size leak) only
  while charging** (the one SHAPE-LAW relaxation: your parry hand is occupied, footwork is all
  you have). Hold with one finger, weave with the other — that's the fight.
- Unanswered (never pressed) = today's law: full damage + slip.
- `charge_enabled` config bool (default ON) = the playtest A/B.

**New DuelistConfig knobs:** `charge_enabled` · `charge_min_frac 0.5` · `charge_full_frac 0.9`
· `charge_counter_mult 2.0`. First-cut numbers — Bill's playtest supersedes.

**HUD:** the CRUSH buster comet reads **HOLD!**; while gathering, a charge arc fills around the
octagon (obs `charge_frac`); the word flips to **RELEASE** inside the claim window; a full-gather
land slams **CHARGED!**. Flinch = the MISSED treatment + "FLINCHED" stamp.

**Input:** new action `{"type": "defense_release"}` → `ClassKit.on_defense_release` (default
no-op — byte-identical for every other class). Band sends it on key-up/mouse-up of the parry
binds (raid_hud already routes key-ups — the Alchemist pour idiom). Protocol version bumps.

### 11.2 THE WEAVE REWORK (faster · more notes · random rhythm)

Engine (`_stream_push` flurry branch, both the odds + phrase paths):
- **`flurry_n` default 4 → 6**; a phrase step may carry its own `n`.
- **`flurry_gap` default 0.35 → 0.26**, and each gap is drawn per-note from the stream's
  seeded rng: `gap × (1 ± flurry_jig)` (`flurry_jig` default 0.45), **floored at 0.20s**
  (6 ticks — the 30 Hz wall + `flurry_recover` 0.15 headroom). The weave is never straight
  twice.
- **Authored rhythm wins:** a phrase step may carry explicit `gaps` (e.g. `{"kind": "flurry",
  "n": 6, "gaps": [0.3, 0.2, 0.2, 0.45, 0.2]}`) — syncopation as content, cycled if short.
- **The riposte scales with the dance:** `counter_dmg × flurry_riposte_mult × (n / 4)` — a
  6-note weave pays 1.5× the old 4-note. Blown-weave law unchanged (miss one = eat it all).
- Grading/claim unchanged; FLURRY MODE stays wind-free, parry sealed.

**Content:** each Seal gets a weave phrase in its songbook (the "multi-hit big move" seat) —
Vorathek a gentle 4-note teach (authored, slowish) · Mistral a quick 5-note syncopated ·
Gemini twin-pairs (2+2 echo) · Mythos the full 6–7-note seeded-random weave. The training
golem's `the_weave` gets authored syncopation + a random variant; the SPIKE golem gains a CRUSH
telegraph ("Battering Charge") so the trainer teaches the gather.

### 11.3 Build slices (branch `duel-charge`)

S1 engine (release action + flurry rhythm + protocol) → S2 kit (gather state machine) → S3
policy (hold/release AI) → S4 HUD (band input + channel rendering) → S5 content (trainer +
Seal weaves) → S6 verify (duelist_sim/raid_sim low-seed + same-seed det + ui_smoke_raid +
WSLg screenshot) → merge, ledger flip, `C:\Games\v3Tank` deploy. ⚠ Deliberate re-baseline:
every fight checksum shifts (stream rng order) — do NOT chase the diff.
