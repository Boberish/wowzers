# SIM-PLAN.md — THE BALANCE LADDER (how much balance we can automate, within reason)

> **Status: PLANNED, NOT BUILT** (Bill, 2026-07-09: *"do nothing now, but let's make a future
> plan for how we can balance the most possible within reason"*). This doc is the plan for the
> sim surface we grow INTO as the roster stabilizes — not a claim to build today.
>
> **The honest frame (Bill's, agreed):** "the game is auto-balanced" is not a real goal — even
> mega-studios don't have it. What IS achievable: **sims that FLAG, a human who JUDGES.** The
> machine finds outliers (dominant builds, dead cards, a seat being carried); Bill reads a
> ranked digest and turns dials. The only hard PASS/FAIL stays **determinism** — balance
> thresholds are soft flags in a report, never merge gates.

**Sibling docs:** `MASTER-PLAN.md` §TOOLING · `BUILD-LEDGER.md` §G (the row) · `DECK-LAYOUT.md`
(what a deck IS — the sampler samples it) · `TEMPO-PLAN.md` §BALANCE GATE (the ~15% EV-parity
idea this plan absorbs) · CLAUDE.md §ACTIVE VERIFICATION (the bar today).

---

## 0. WHAT WE HAVE TODAY (inventory, 2026-07-09 audit — so the plan builds on truth)

| Piece | What it does | What it does NOT do |
|---|---|---|
| Skill bands (expert/good/sloppy) | Latency knob on hand-authored policy ladders; expert = lat 0 = flawless TIMING | Does NOT change the ROTATION — all bands run the same ability script; expert is perfect reflexes on a fixed brain |
| Rotation policies (all seats) | Real priority ladders for every seat (blade/tank/caster/healer — tank+healer thinner, blade+alchemist richest) | No search/optimization; no active-module verbs (Deathmark's gauge is never spent); blade is CREED-BLIND (Alchemist is the only creed-aware policy) |
| Balance output | win-rate + avg TTK per (boss × skill) cell, per-seed CSV | No DPS scalar; no variance/spread; no per-seat attribution in the raid |
| Boon testing | `alchemist_sim._boon_ab()` = single-card ΔTTK vs base (ONE class); twinfang/well A/B fixed hand-picked packages | No other class has per-card delta; NOTHING samples drafted builds; raid_sim runs a BARE kit (no creeds/modules/boons) |
| Healer metrics | hlMana/hlOver/hlIdle read-only columns (the "is the healer a real constraint" read) | Ranges are a comment, not a check |
| Determinism | Hard gate everywhere (checksum ×2, byte-identical A/B via `ab-gate.sh`) | — (this is the one real gate; keep it that way) |
| Throughput | `psim.sh` shards seeds ~5×; `verify-all.sh` = the merge bar; `tune.sh` = live dials | No long-run harness, no report/digest, no trend-vs-last-week |

**Calibration (measured 2026-07-09):** `raid_sim --seeds=6` = 72 fights (4 Seals × 3 skills ×
6 seeds) in **117.7s single-core ⇒ ~1.6s per raid fight** (300s tick-cap). Solo-class fights
(180s cap) are cheaper. On an 8-shard desktop via `psim.sh` ⇒ **~5 fights/sec ⇒ ~400k raid
fights per 24h** (more with more cores). That's the soak's budget envelope — a day-long weekly
run buys a *huge* matrix; the constraint is designing what's worth spending it on, not compute.

---

## 1. THE PRINCIPLE — TWO SPEEDS

- **THE QUICK GATE (minutes, every merge — exists today, keep):** `verify-all.sh` + determinism
  + the 3-band win/TTK read + per-class card-delta tables (S3 below folds in here). Answers
  "did I break anything / is this card sane."
- **THE SOAK (day-long, weekly, Bill's desktop — §3):** the full matrix — sampled drafted
  builds, creed grids, per-seat ablations, all Seals, big seeds — ending in a **ranked digest**
  of red flags + a trend line vs last week's soak. Answers "what's quietly broken at scale."

Everything below slots into one of those two speeds.

---

## 2. THE LADDER — S0→S5 (each rung has a prerequisite and a trigger; build in order)

### S0 · The quick gate (BUILT — today's bar)
Keep. Nothing above replaces it; determinism stays the only hard gate.

### S1 · POLICY COMPLETENESS — deck-aware AI (the gate for EVERYTHING above it)
The 2026-07-09 audit's core finding: the sim player has perfect reflexes but can't PLAY the
deck. Until the policy can play a card, simming that card measures nothing. So:

- **THE CARD-VISIBILITY RULE (new law for reworks):** *a card does not exist to the sim until
  the policy can play it.* Every class rework ships its policy work IN the rework, not after:
  1. **Creed-aware branches** — the policy reads the equipped creed and shifts greed
     (`alchemist_policy.gd` Purist/Steady/Anchorite branches = the template; the blade is the
     worst offender — zero creed reads).
  2. **Active-module verbs** — any card needing an active press gets a policy branch (today:
     Deathmark's `marks` gauge is exposed and never spent — that build's payoff simply doesn't
     happen in sims).
  3. **Passive cards** ride generic obs fields (window bounds, flow, charges) — already work;
     just confirm the obs surface exposes them.
- **The coverage probe (small, buildable early):** each card in a class catalog declares
  `sim: "passive"` or `sim: "verb:<name>"` (one dict field); a probe walks the catalog and
  fails on any card with no declared surface OR a verb the policy never emits. Cheap, and it
  turns "the AI can't play half the deck" from a discovery into a lint.
- **Where the rotation ladders stand:** every seat already HAS one (blade rich, tank/healer
  thin) — Twinfang's rotation is fine as Bill judged. The S1 work is deck-awareness, plus a
  fresh ladder whenever a rework replaces a kit (Duelist/Warden tank, etc.). Hand-authored
  ladders STAY (see §6 non-goals — no optimizer AIs).

**Trigger:** rides each class rework (Phase-2 deck reshapes per `DECK-LAYOUT.md`). Never a
separate project — it's a rework deliverable.

### S2 · THE CREED MATRIX (cheap — Bill: "a creed tester should be easy." Correct.)
Once a class's policy is creed-aware: run **creeds × skills × seeds** (e.g. 4 × 3 × 200 ≈
2.4k fights ≈ minutes sharded). Read (soft flags, not gates):
- No creed >~10% win/TTK-dominant at equal skill (else it's a stat stick, not a temperament).
- The RISK SHAPE shows: greedy creeds should gain MORE from expert and lose MORE at sloppy
  (spread widens); if a greedy creed is flat across bands, its risk isn't real.
- Quick-tier: default creed only. Soak-tier: full grid per class.

**Trigger:** ≥2 classes creed-aware (Alchemist is already; blade is the natural second).

### S3 · CARD DELTA — generalize `_boon_ab()` to every class (quick-tier)
The Alchemist's base-vs-base+1-card ΔTTK table becomes a shared harness (it lives naturally on
`sim_util.gd`): every class sim gets a `--cards` pass printing win%/ΔTTK per single card at
good-lat. Catches **dead cards** (Δ≈0) and **overtuned singles** early, per class, in minutes.
- Healer/tank classes read a different Δ: deaths avoided / mana floor / damage-eaten shift,
  not TTK alone — the harness takes a per-class "score" callback, not a hardcoded TTK.
- This is the everyday tool while designing decks; it does NOT answer combos — that's S4.

**Trigger:** anytime; cheapest rung on the ladder. Build it the first time a second class
wants what the Alchemist has.

### S4 · THE BUILD SAMPLER + CARD LIFT (the combo answer — Bill: "boons will be hard, so many combos")
Right worry, wrong shape: **don't enumerate combos — sample real drafts and compute per-card
statistics over the sample.** 2^18 subsets is impossible; 2k *reachable* builds is an evening.

- **Monte Carlo drafts through the REAL pipeline:** drive `draft.gd` itself (`roll_offers` —
  rarity weights, synergy slot, opus pity) with 2–3 simple picker policies (greedy-tag-synergy /
  random / rarity-greedy) over a seeded stream → K drafted builds per class (e.g. 2,000). Every
  sampled build is one players can actually reach, weighted by real offer rates — testing the
  *distribution the game deals*, not an abstract powerset.
- **Run each build** at good-lat over a seed batch (e.g. 2,000 builds × 20 seeds = 40k fights
  ≈ 2-3h sharded — soak-tier, per class).
- **CARD LIFT (the key stat):** for each card, mean win%/TTK of sampled builds CONTAINING it
  minus builds without it (deck-tracker style). Flags what single-card delta can't: a card
  that's fine alone but warps every build it enters, or one that's dead *in context*.
- **PAIR LIFT (targeted superadditivity):** only for pairs sharing a synergy tag (the `tags`
  vocabulary keeps this ~hundreds, not thousands): lift(A+B) vs lift(A)+lift(B). Flags degenerate
  combos specifically.
- **DOMINANCE FLAG:** any sampled build >~15% ahead of the sampled median at equal skill
  (absorbs TEMPO-PLAN §BALANCE-GATE's unbuilt EV-parity check, generalized) · keystone-less
  builds must stay viable.

**Prereq:** S1 for that class (sampling builds the AI can't play measures noise).
**Trigger:** a class's deck is reshaped onto `DECK-LAYOUT.md` and stable — building this
against decks mid-reshape is wasted work.

### S5 · RAID ATTRIBUTION — per-seat truth inside the 4-seat win rate (Bill: "we can't know
the per-class info — maybe something incredibly unbalanced but something else covers for it")
Three read-only instruments (the checksum-safe sampling pattern already established):
1. **Per-seat meters** in the raid CSV: damage share, deaths, damage-taken, healing done/
   received, overheal — the raw "who's actually doing what."
2. **THE ABLATION MATRIX (the real answer to "who's carried"):** 5 cells per boss — all-expert
   baseline + (one seat dropped to sloppy, others expert) × 4 seats. The win-rate drop when
   seat *i* degrades = that seat's **CARRY INDEX**. If sloppy-healer barely moves the number,
   the healer doesn't bite; if sloppy-tank alone wipes it, the tank is carrying. ~5× today's
   raid cost — quick-tier at small seeds, full grid in the soak.
3. **SEAT-SWAP PARITY:** same comp, swap one seat's class (caster: voidcaller↔alchemist;
   healer: mender↔well↔bloomweaver) at identical bands — cross-class parity per role, the
   raid-side complement to solo TTK.

**Trigger:** after the tank/FLOW=AGGRO rework merges (it deliberately rebaselines raid
checksums anyway — land the instruments in that wave, one rebaseline instead of two).

---

## 3. THE SOAK — the weekly day-long desktop run

- **What:** one script (`scripts/soak.sh`) that runs the full matrix overnight-into-a-day:
  per-class card-delta at big seeds · creed grids (S2) · build sampler + lift stats (S4, the
  budget hog — rotate 2-3 classes/week if needed) · raid ablation + swap grids (S5) · all-Seal
  bands at `SEEDS=1000+`. Budget-check: ~400k fights/24h envelope vs ~100-150k for the full
  menu above — fits with headroom; size up until it doesn't.
- **From a PINNED WORKTREE, always** — the `ab-gate.sh` lesson: a day-long run in the shared
  tree WILL get clobbered by a concurrent session (and the RunState compile-coupling gotcha
  means any kit edit mid-run poisons it). `soak.sh` clones/pins first, runs there, writes
  results back to `out/soak/<date>/`.
- **THE DIGEST (the actual product):** raw CSVs are for machines; the deliverable is a short
  ranked report (markdown, generated at the end): red flags first — dominant builds, top/bottom
  card lifts, creed dominance, carry-index anomalies, healer-bite ranges out of band — each
  with the one number and where it came from. **Plus the TREND:** keep every soak's summary;
  diff vs last week so a slow drift (a retune quietly buffing one build 3 weeks running) is
  visible. Bill reads 40 lines on Sunday, not 40k rows.
- **Cadence:** manual kick or a weekend cron; quick gate stays the everyday/merge bar. A soak
  is NEVER a merge prerequisite.

---

## 4. WHAT "BALANCED" MEANS — the soft-threshold table (flags in the digest, not gates)

| Surface | The flag fires when | Why this shape |
|---|---|---|
| Skill gradient | expert ≉ ~100% on-farm, or sloppy ≥ expert anywhere | The game IS the execution test; a fight sloppy clears at expert rates has no teeth (today's live read: Mythos 100/67/0 = the intended shape) |
| Creeds | any creed >~10% dominant at equal skill · greedy creed's band-spread ≤ safe creed's | Temperaments, not stat sticks; greed must actually risk |
| Single cards | ΔTTK ≈ 0 (dead) · Δ > ~2× the slate median (overtuned single) | Every card earns its slot; rarity is FREQUENCY, never a power cap |
| Builds (sampled) | any build >~15% over sampled median at equal skill · keystone-less non-viable | The absorbed TEMPO-PLAN parity bar — no dominant net-deck, no mandatory keystone |
| Card-in-context | lift sign contradicts solo delta (fine alone, warping in builds — or vice versa) | The combo problem, caught statistically instead of enumerated |
| Healer bite | hlIdle high + hlMana pinned ~100 (the "inert healer" signature) · or mana floor ≈ 0 at GOOD (OOM-wall) | Busy, not wasteful, genuinely resource-constrained — the established read, now watched every week |
| Raid seats | carry index ≈ 0 for any seat (doesn't matter) or ≫ others (sole carry) · swap-parity gap >~10% per role | Every seat's skill must move the outcome; classes in one role stay comparable |

Numbers are first-cut dials — the digest prints them; Bill moves them.

---

## 5. BUILD ORDER (each rung waits for its trigger — nothing starts now)

1. **S1 policy-completeness** — folded into every class rework from here on (rule + coverage
   probe land with the first one).
2. **S3 card-delta harness** — first time a second class wants the Alchemist's table (cheap,
   quick-tier).
3. **S2 creed matrix** — once the blade (or any second class) goes creed-aware.
4. **S5 raid attribution** — with the tank/aggro rework's rebaseline wave.
5. **S4 build sampler** — per class, as each deck lands on `DECK-LAYOUT.md` and stops moving.
6. **§3 soak + digest** — once ≥2 rungs above exist to feed it (a soak over today's bare-kit
   surface would just re-run the quick gate slower).

## 6. NON-GOALS (decided now so nobody builds them by accident)
- **No optimizer/RL policies.** Hand-authored ladders stay — they're deterministic, debuggable,
  cheap, and "competent human," which is the right measuring stick. (Known cost: sims measure
  a good player, not the ceiling; accept it.)
- **No auto-tuning.** Sims flag; `tune.sh` dials stay in Bill's hands.
- **No hard balance gates.** Determinism remains the only PASS/FAIL; everything else is digest.
- **No combinatorial enumeration.** Sampling + lift statistics, per §S4, always.
