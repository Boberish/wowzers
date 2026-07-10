# TEMPO-PLAN — the Tempo Rogue redesign + the Creed / Module / Level framework

**Status:** DESIGN + BUILD IN FLIGHT (2026-07-04). **The Opening** merged (`4f071bd`); the **risk-core slice**
(combo-fix + Flow-dial + Creeds/Modules scaffold) is building on branch `tempo-pilot`. The audit-iteration
decisions (see the ✅ block below) are folded into this doc — reconcile them into the build when that slice merges.
**⚡ 2026-07-06 — THE SPLIT + full spec-audit verdicts triaged (see the ⚖ block below):** Venom / the Brew
LEAVES Twinfang to become its own class (**`ALCHEMIST-PLAN.md`**); Twinfang owes a rhythm-variant SECOND
SPEC (§13, design owed).
**Scope:** this reworks the **Twinfang · Tempo** aspect into a risk/reward "greed dial," AND introduces a
class-framework (Creeds · Modules · WHEN/THEN clarity · per-class levels) that is meant to **generalize to
every class** later — Tempo is the pilot. Companion docs: `ALCHEMIST-PLAN.md` (the Brew — the poison class
split out 2026-07-06), `PROGRESSION-PLAN.md` (meta), `GEAR-CATALOG.md`
(curios). Design artifacts: **Tempo redesign** https://claude.ai/code/artifact/2cd281f6-552b-4746-9512-44925d369254
· **Boon clarity (WHEN/THEN)** https://claude.ai/code/artifact/802aad53-6017-4455-b4e3-145cbc2930f8
· **System codex** https://claude.ai/code/artifact/d89a2854-0101-4db5-ac60-5f73f7351bb1

Legend: **🔒 LOCKED** (decided with Bill) · **🟡 OPEN** (Bill tuning / to lock before build) · **🔮 FUTURE** (parked).

---

## ✅ AUDIT ITERATION — what locked 2026-07-04

A full triage of every Twinfang element (audit board:
https://claude.ai/code/artifact/884e4af5-5831-469b-971f-eb63405e5038) plus a design pass on the trigger system.
Headlines — details folded into the sections below:

- **WHEN/THEN redefined → ONE Combo rig per run** (§5). Wire 1 WHEN → 1 THEN at the first draft; re-wire once at
  end of Floor 2; scales with floor; never stacks. The stackable "any WHEN fires the whole board" model is CUT.
- **Dodge is NOT Twinfang's verb.** Dodge stays a bare safety verb; every dodge-feeds-offense boon is cut
  (Riposte, Ghost Step, Beat Dancer, Twin Step, Dancer's Grace). WHENs are **offense-only**.
- **The Perfect window is GRADED** (§2c, Option B): Bullseye / Perfect / Good, base tightened.
- **Drumline pays its safety as a wider window** (§3) — so the base window can run firm.
- **Tier-2 combo bonus removed** (over Flow 5 = +energy only, not +combo); Syncopation stays.
- **Le Chat's Bell → start warm with Flow (~3–4), not resources.**
- **CUT (10):** Riposte · Dancer's Grace · Ghost Step · Beat Dancer · Quickblood · Red Harvest · Twin Step ·
  Virtuoso (blunts the Creeds) · Powder Vial · Riftmaw's Hunger.
- **RECYCLE/FOLD:** Wide Tempo → classic · Razor Echo → the Echo THEN · Killing Tempo → the Full-Finisher WHEN.
- **BALANCE-WATCH (kept):** Second Opinion (doubles a rig fire) · Grace Period (shouldn't save Flow on Flourish)
  · Killer's Eye (could go Bullseye-flavored).
- **Classics stay the draft bread; spells stay the rare treat** (add 1–2 more so Flurry isn't lonely).

---

## ✅ MODULE / CURIO / VENOM RECONCILIATION — locked 2026-07-05 (with Bill)

Grounded in a full cross-spec + layer-fit audit (workflow `wf_1bdad49f`). Bill's calls:

- **Modules are PER-SPEC, not cross-spec.** For the pilot, **The Opening is Tempo's ONE module**;
  Edge / Deathmark / Metronome / Hemorrhage are **PARKED as drafts** (dormant code/ideas, NOT offered) —
  we decide later whether any become shared, per-spec, or fold into cards. So the Floor-1 "pick 1 of 3
  modules" flow + the `specs` cross-spec filter are **shelved** until there's a real module roster. (Pull
  the Edge/Deathmark mechanics out of the *offered* module set; they can stay in the kit, gated off.)
  **⚠ SUPERSEDED 2026-07-06 (audit F1/F6/I1, accepted):** the Opening is promoted OUT of the module slot
  to Tempo's always-on baseline VERB; Edge + Deathmark UN-PARK into a real Floor-1 1-of-3 alongside the
  new ⭐ OVERDRIVE transformer — see the ⚖ audit block + §4.
- **⚠ Edge leak to fix if kept live:** the +25% Perfect-damage mult is NOT aspect-gated (only the window
  narrow is) — a Venom seat equipping Edge would get the damage free. Gate it, or leave Edge parked.
- **MODULE ↔ CURIO lane rule = DECISION OF RECORD.** **Module** = transforms the class VERB (curated,
  1/run, no drop, not a trinket). **Curio** = FORTUNE + an OFF-VERB button (rarity-printed, 2 trinket
  sockets, dropped as events) that **NEVER touches Flow / the Perfect(-graded) window / the strike-result
  hook / Marks** — those are Creed/Module/rig territory. Curios make the *loot* fun; the verb stays sacred.
  - **Curios currently VIOLATING the lane → cut/rework:** Powder Vial (keep CUT — +Flow on Kick) · Encore
    Bell (forces the window WIDE = literal anti-Edge → re-flavor to a verb-neutral finisher reward) · LE
    CHAT's Bell (do NOT adopt "start with Flow ~3-4"; keep it an ENERGY warm-start — fix the doc, code is
    already energy) · Grace Period (Flow survives a slip → guts Flourish; make Creed-aware or narrow) ·
    Second Opinion (must NOT double a rig proc — only the base grade reward).
  - **Bill's open design ask:** *what SHOULD curios do that's fun, in the fortune/off-verb lane?* → a
    dedicated design pass is running (workflow `wf_cb1ef961` — economy/luck · survival · off-rhythm gadgets
    · ability-economy · big gambles/theme). Menu folds in here when it lands.
- **VENOMANCER = a complete future clean-slate remake.** Ignore the current Venom entirely for now.
  **Creeds are Tempo-only** (Flow-based); Venom gets its own risk temperament (wheel/synergy) in its remake.
  **→ 2026-07-06 went further: the remake is its OWN CLASS now** (audit F10 — `ALCHEMIST-PLAN.md`);
  Twinfang's second spec becomes a rhythm variation instead (§13).
- **~~⚠ BRANCH RECONCILIATION~~ — RESOLVED 2026-07-05 (stale; kept for history):** `tempo-boons` was
  committed and MERGED TO MAIN the same day (`fe4d109` → merge `8c845ca`), the §5 combo-rig was BUILT +
  merged (`d1515e7`/`ecfbb75`, build-out `2277d15`), and the dead verb_board GUI was RETIRED/deleted
  (`42575b5`). Everything is on origin/main — see `godot/data/twinfang/twinfang_boons.gd` (the
  address-organized slate) + `twinfang_rig.gd`.

---

## ⚖ SPEC AUDIT — BILL'S VERDICTS, 2026-07-06 (0 reject · 12 tweak · 24 accept of 36)

Full-board audit of BOTH specs (8-agent panel, adversarially verified/deduped; board:
https://claude.ai/code/artifact/168429ee-6039-40e0-a3aa-7d8658a30a9c). Venom-side verdicts are folded
into `ALCHEMIST-PLAN.md`. **THE HEADLINE — F10, THE SPLIT:** the Brew reads as "a stationary chemist,
not the melee BLADE," and Bill's call was not to re-skin it — **remove it from Twinfang and make it its
own class** (working name THE ALCHEMIST — filler). Twinfang's second spec becomes a **rhythm VARIATION
of Tempo** (§13). The in-code poison-wheel Venom stays the frozen placeholder aspect until §13 lands.

**ACCEPTED (Tempo + framework — fold into the build):**
- **F1 · The Opening → the class's BASELINE VERB** (always-on; dumps ride it; Punish stays the premium
  rig WHEN; frees its module slot). Supersedes 2026-07-05's "Opening is Tempo's ONE module."
- **F6 + I1 · a real module 1-of-3 + the owed ⭐ TRANSFORMER = THE OVERDRIVE:** un-park Edge + Deathmark
  (already built, only the pick-UI gates them); Overdrive = at max Flow the multiplier stops and fills an
  OVERDRIVE meter — tap for a short FEVER (window locks all-green, every Strike hits Coup-tier and
  auto-chains) then crash to a seed and rebuild. Bank→blow→rebuild; the mirror of the Alchemist's Still.
- **F8 · high-Flow is a double trap on mobile:** GOOD MAINTAINS (a Good pauses Flow decay that beat —
  "held it") + the accelerando tightening ASYMPTOTES to a floor that stays thumb-hittable.
- **F11 · energy starves the fantasy at its peak:** base Perfect (especially Bullseye) refunds some
  energy — clean play self-fuels (Efficiency/Syncopation existing as boons was the smell).
- **F12 · weak cash-out tension:** surface combo cap-waste (Overkill) as a soft pull to SPEND NOW;
  Coup's Flow seed scales with how cleanly you've been striking — a hot run Coups confidently.
- **F15 · Bullseye must punch:** strict superset of Perfect's rewards + its own signature juice
  (sound/flash/refund) — dead-centre is the class's dopamine spike, no drafted boons needed.
- **F17 · Held Breath dead-cards / Double Time runaway:** the 2s tight-window lockout counts as a CRASH
  EVENT for crash-keyed cards (Shatterfall / Staccato Fury / Double Time), or those cards filter from
  Held Breath offers (creed-aware drafts — same fix family as F7).
- **F19 · Drumline + wideners = opt out of the bet:** window-wideners TAPER with Flow (help most at low
  Flow, fade at the top) so comfort never replaces the climb.
- **F26 · Syncopation:** the Opus rune stays the jackpot; the base rune only removes energy cost, never
  grade risk.
- **F24 · Flow and Combo never talk:** combo state lightly COLORS the loop (full combo primes a subtle
  window cue) — reduce reads on the thumb HUD, don't add them.
- **F14 + I2 · the owed SUPPORT boon = BATTLE HYMN:** while you hold high Flow the whole raid rides your
  tempo — a party haste/CD aura scaling with your Flow tier, blinking OFF the instant you crash. Flow
  uptime IS the raid buff; no extra button. (Pays the §5 framework debt.)
- **F25 · the rig premium must be real:** verify rare WHENs are EV-POSITIVE vs the can't-miss Riff (the
  §5.0 curve exists — prove it delivers) and the wiring board shows TOTALS, not just per-fire numbers.
- **F23 · thin lanes:** fold COUP into FLOW; ENERGY gets a second card that does something visible, or
  folds into STRIKE.

**TWEAKED (Bill-steered, open):**
- **F27 · crit needs a real think (→ §10):** STRIKE is mono-theme (all four cards are crit). Bill: "idk
  what to do about crit — should crit be a 'build'? how do crits scale/work? should we add other crit
  cards?" — a design pass, not a one-card patch.
- **F22 · kick → INTERRUPT-BY-ABILITY:** the shared Kick button both redesigns silently dropped is being
  rethought globally (WORLD-PLAN pillar 3): certain class spells carry "this interrupts" as a side
  effect — LESS frequent, TIGHTER window than the old kick. Document carriers per class at rework time.
- **I7 · SWAN SONG (→ §10):** liked — but either BAKE it into the class or GENERALIZE it: not
  final-phase-only; Bill floated an overall auto-dodge boon as the more-fun version.
- **I8 · ALL IN — PARKED:** Bill likes the double-or-nothing arm-tap, but "this is flowing too fast — I
  don't think we can execute it." Recorded, don't build.

**~~⚠ Card-slate verdicts need the other machine~~ — FALSE ALARM (corrected 2026-07-06):** the
`tempo-boons` slate was merged to main 2026-07-05 (`fe4d109`/`8c845ca`) and is on origin — every card
named above lives in `godot/data/twinfang/twinfang_boons.gd`, the rig in `twinfang_rig.gd`, the
creed/module/rig plumbing in `raid_hud.gd`. **Card-level verdicts are actionable NOW, on main.**

---

## 0. Why (the diagnosis that started this)

1. **Verbs felt tank/dodge-centric.** M7 bolted one defensive timing mechanic (dodge/parry→riposte) onto every
   role, so DPS/heal play felt same-y. Fix = each class gets its OWN timing minigame; dodge stays a light shared safety.
2. **Boons are mostly flat stats** (the "quality lever" — see `combat-upgrade-load` memory). The *quantity* of
   per-run choices is fine (~1 aspect + ~10 drafts + 2 curios); the *quality* is the problem — too many invisible
   `+30%` bumps, too few "hammers" that change the minigame.
3. **The system was hard to explain** ("couldn't explain it to my wife"). Trigger/Payload/Property/"proc" is
   engineer-speak, buried in a tooltip.

Tempo is the deep-dive that fixes all three: make the abilities *fun* (a greed dial + real hammers) and make the
build *legible* (WHEN/THEN board + tutorial).

---

## 1. The vision — Tempo is a GREED DIAL 🔒

A bladedancer who plays faster and tighter for exponential payoff, one slip from disaster. The whole kit is a
risk knob, and the game lets you **choose how much you're betting**. Skill = how hard you push.

**Flow stays the spine** (unchanged core): build it with Perfects, it multiplies ALL your damage (`+8%/pt`,
cap 6), a slip costs it. Accelerando stays: as Flow climbs the window slides earlier + tightens (`0.35s → 0.22s`).

Three layered ways to push the dial:
1. **Ride high** — baked in (the accelerando). Riding max Flow *is* the base bet.
2. **Swear a Creed** — §3, how a slip is punished.
3. **Slot the Edge** — §4, a module that lets you narrow the window for a damage spike.

---

## 2. Core-loop fixes 🔒

### 2a. Combo is a WIND-UP, not an always-full bar 🔒
**Bug Bill noticed:** combo builds far too fast — a Perfect gives **+2** (and **+3** at Tempo Tier-2), the cap is
**5**, and only Eviscerate spends it, so it pins at cap and you constantly waste generation. An always-full
resource is a **dead resource** (no build→spend decision).
**Fix:** a Perfect gives **+1** (not +2); **drop the Tier-2 combo bonus**. You build to 5 over ~4–5 Perfects,
and the finisher becomes a *timed release* — spend it now, or hold it for the boss's Opening / to detonate a
Deathmark. (Small config change in `twinfang_config`/`twinfang_kit`; sim to confirm the new curve.)

### 2b. Triggers come OFF the auto-attack 🔒
**Decision:** REMOVE the innate "every Perfect Strike" proc moment. A proc that fires ~every 0.7s turns any
payload into a passive stat trickle AND makes the big moments (Peak / max Flow) meaningless because you're
already proccing constantly.
**Consequences (all intended):**
- Triggers are now **only earned moments** (§5). You **draft** them; they are the whole show.
- Because they fire less often, **payloads hit bigger per proc** — a Riff for 20 is an event; "deal 6 every
  second" is wallpaper.
- The build gains a spine: **a payload needs a trigger to fire** → your combo is a real "assemble a WHEN + a
  THEN" decision. Onboarding: the first draft hands a matched WHEN+THEN pair; the draft synergy-slot keeps
  pairing them.
- It *rescues* the big moments — Peak becomes worth building around because it's rare, not constant.

### 2c. The Perfect window is GRADED, not binary 🔒 (Option B, locked 2026-07-04)
Today a Strike is Perfect-or-nothing and the green is **generous (~0.35s)** — at low Flow the beat barely tests
you. Fix: **tighten the base window** and **split it into skill tiers**, so nailing the beat is a real read and
the tiers themselves become the board's timing moments:
- **Bullseye** — dead center (~0.05s): the tightest read → a rare **WHEN**, the best payoffs.
- **Perfect** — the core (~0.14s): full ×1.6 + Flow + the Aspect tier-kickers (today's Perfect).
- **Good** — the flanks (~0.08s/side): it LANDS, partial damage, little/no Flow (no double-hit).
- **Early / Late** — outside: base hit only (today's non-Perfect behavior).

You rarely *whiff*, but *nailing Perfect* takes skill — and the split hands the board three ready-made timing
WHENs (Bullseye / Perfect / Good). The accelerando still slides + tightens the whole stack with Flow. Because
**Drumline** (§3) now pays its safety as a **wider window**, the base can run firm — sloppy players opt into the
loose beat; everyone else earns the tight one. Numbers illustrative — sim the feel.

---

## 3. CREEDS — how you pay for a slip 🔒 (rules) / 🟡 (which ship)

A **slip** = mistiming a Strike or eating a swing. The Creed sets the *currency* of the mistake, and pairs a
matching reward so the punishing ones also pay the most. The penalty is your **groove / blood / window** — never
a boring damage number.

**Rules 🔒**
- You **draft 1 of 3 RANDOM Creeds** at run start, from your **per-class unlocked pool** (§7).
- An **EVENT NODE** can re-draft your Creed mid-run **for a penalty** — reuse the map wound economy: a
  **CORRUPTED SECTOR** wound (−max HP until a Cooling Station) or a chunk of Tokens.
- Ship a **starter pool of ~3–4** unlocked from level 1 so the 3-random draft always works.
- Creeds are **curated picks, NOT rarity-weighted** (like Hades aspects — flavor, not a rarity roll). See §6.

**The menu (numbers illustrative — tune in-engine) 🟡**
| Creed | Temperament | A slip does… | Paired reward |
|---|---|---|---|
| **The Flourish** | Glass | Flow → 0 **and** knocked to walking pace (window snaps wide, rebuild the ramp) | each Flow point pays **+50%** more |
| **The Drumline** | Steady (default) | **−2 Flow**, nothing else — stumble, keep dancing | **a wider Perfect window** (safety is opt-in → lets the base window run tight, §2c) + baseline Flow value; the forgiving learner Creed |
| **The Held Breath** | Tempo-cost | **freezes Flow** (no loss/decay) but **locks the tight window 2s** | progress paused, never lost; recovery-window play |

*(Bloodwaltz — the "cut yourself + Expose the boss" Creed — CUT by Bill 2026-07-04.)*

**v1 recommendation:** ship **Flourish + Drumline** first (the clean risk/safe pair); add Held Breath after the
core feels right.

---

## 4. MODULES — the Hades-style UI addons 🔒 (rules) / 🟡 (which ship)

Each Module **adds a gauge to the HUD** and a new way to play. A run = Tempo + **one** Module → a different
screen and feel every run. This is the "variance in the UI." It also makes the Opening feel *chosen*, not
permanent wallpaper.

**Rules 🔒**
- You pick **1 Module** at the **END OF FLOOR 1** (Ring 3→2 elevation reward). **NOT** two, **NOT** at start
  (Bill: "2 at start is too much"). One heavy identity pick at the start (Creed), one a floor in (Module).
- Modules are **mostly available from the start** (unlock by first-clearing their boss, like curios), so the
  Floor-1 pick always offers 3.
- Curated picks, **not rarity-weighted** (§6).

**The menu 🟡 (re-cut 2026-07-06 per audit F1/F6/I1)**
| Module | Role | What it adds | Status |
|---|---|---|---|
| ~~**The Opening**~~ | — | **PROMOTED OUT (audit F1): now the class's always-on baseline VERB** — boss swing overextends → punish window for dumps (×1.9). No longer occupies a module slot | ✅ BUILT (as the verb) |
| **The Edge** | greed dial | **Commit** (hold/tap): window shrinks to Perfect-only, hits deal more + build Flow faster; a heat gauge shows the push. *(the "narrow the perfect for more dmg" lever)* | built, UN-PARKED (F6) |
| **The Deathmark** | combo layer | Perfects stamp a Mark; a full mark → next dump **detonates** for a burst | built, UN-PARKED (F6) |
| **THE OVERDRIVE ⭐** | transformer | at max Flow the multiplier stops and fills an OVERDRIVE meter; tap → short FEVER (all-green window, Coup-tier auto-chaining Strikes) → crash to a seed, rebuild | accepted (I1), design |
| **The Metronome** | 2nd rhythm | an external steady beat; Strikes landed ON it bonus — polyrhythm (highest skill) | parked |
| **The Hemorrhage** | sustain | Perfects open a stacking bleed; a dump reopens it for a spike | parked |

**v1 module pick = Edge + Deathmark + Overdrive ⭐** — the real Floor-1 1-of-3 (F6), with the transformer
slot paid (I1). The Opening is everyone's, always (F1).

**🟡 open:** is **The Edge** a Module (equip the greed) or baked into base Tempo for everyone? Leaning **Module**
(keeps base Tempo clean; the greedy narrow-window play is a run choice).

**Notes (2026-07-04 audit):**
- The base rhythm is **self-timed taps** — no external metronome; each landed Strike resets the window (see the
  input-mechanic breakdown). **The Metronome module** is precisely the "true continuous beat you play ON" layer;
  the default stays quickdraw-timed. *(If a running beat should ever be the DEFAULT feel, that's a core change,
  not a module — decide before the risk-core locks the loop.)*
- **Deathmark owns the Detonate WHEN + Mark +1 THEN** — they enter the Combo board **only when Deathmark is
  equipped**, so you never draft a dead card.
- **Edge vs Bullseye vs accelerando** all mean "tighter = more" — keep them distinct (Edge = a togglable heat
  you push; Bullseye = the graded-window center; accelerando = passive), or Edge should absorb Bullseye.
- **Hemorrhage vs a Rend THEN** overlap — bleeds are a Module identity OR a board effect, not both.

---

## 5. THE COMBO — the WHEN/THEN mechanic, REDEFINED 🔒 (single-rig model, 2026-07-04)

**The pivot (locked with Bill):** the stackable "any WHEN fires the whole THEN board" model is **CUT**. It
re-created the trickle §2b kills (5 pieces all firing = wallpaper again) and produced the exact failure Bill
named — *"side-effect damage is killing the boss and I don't know why."* Replaced with **ONE Combo rig per
run**: a single, legible circuit you wire, watch light up, and know cold. It's **another milestone ceremony**
(same species as Creed/Module), NOT a growing system.

### 5.0 ✅ BUILT & MERGED 2026-07-05 (`ecfbb75`) — the greed-dial payout
The rig ships. **The balancer AND the reason to reach for rare WHENs, in one system:** a THEN's magnitude is
**computed from the WHEN it's plugged into** (`base × mult`), so frequent WHENs pay small and rare WHENs pay a
**premium — collectible only if you actually LAND them** (the rig is itself a small greed dial, on theme). One
formula in `data/twinfang/twinfang_rig.gd`, **no pairing rules**; the wiring board shows the number before you commit.
- **WHENs** (`mult` ≈ inverse-frequency × premium): Riff 1.0 · Bullseye 1.9 · Finale 4.4 · Punish 6.5 · Peak 6.9 ·
  Coup 8.4.  **THENs** (`base` at Riff): Echo 12 dmg · Second Wind 5 energy · Killing Edge crit-charges ·
  Bloodletter 8 bleed · Overcharge 6% next-dump (the Coup build-up) · Expose 3%. *(v1 numbers — tune by playtest
  feel; all in one table.)*
- Wired at the **first draft** (`_show_rig_wire` 3+3 board, ButtonGroup + live readout), **re-wired at end of
  Floor 2**; folded into the blade kit via `_inject_boons` (blade/Tempo human only, else empty). Shows
  persistently in the **build panel** + pops "<THEN> +N" on fire.
- Power = **SIDE BOOST** (Mythos ~4% TTK / ~10% of the blade's own damage). Determinism PASS; `raid_sim --rig=when:then`.
- **Trimmed vs 5b/5c below:** the greed-dial premium REPLACES the floor version-bump as the "stays-relevant"
  mechanism (no floor-scaling in v1); the Detonate/Mark WHENs (module-gated) are parked with the module roster.

### 5a. The rename 🔒
Retire the jargon: Trigger → **WHEN** · Payload → **THEN** · Property → **ALWAYS** — and ALWAYS pieces are now
just **classics** (the property slot is retired; see the audit). A rig reads as one sentence:
*"**WHEN** I land a Riff → **THEN** the boss bleeds."* You plugged the wire, so you know why the damage lands.

### 5b. One rig, wired by you 🔒
- **Wire ONE WHEN → ONE THEN** at your **first draft** (after fight 1) — a small board: ~3 WHENs left, ~3 THENs
  right, plug a single wire.
- **The THEN's number is set by the WHEN it's wired to** — Echo hits ~16 on Riff (frequent), ~45 on Peak (once
  a ramp). Frequent-small vs rare-huge is the player's decision, and balance is **one lookup table**, not
  combinatorics. *(This is where Model-A frequency-scaling actually lives — §6.)*
- **It does NOT grow within a run** — no Amplify / second-wire ladder (that was the sprawl). One rig, whole run.
- **Re-wire once, at end of Floor 2** — optionally swap the WHEN and/or THEN, free ("change it up" for the
  finale). The only mid-run change; it never bloats.
- **The rig's numbers scale with FLOOR** (baked, not drafted) so a never-touched rig stays relevant into Floor
  3. Realm-1 flavor: a **version bump** at each elevation — *"Combo v2.0 — Echo damage increased. No other
  changes."*

### 5c. The menus — OFFENSE ONLY 🔒/🟡 (dodge is not Twinfang's verb)
**Dodge stays a bare safety verb** (audit lock 2026-07-04). Every dodge-feeds-offense boon was cut, so
**Clean Dodge is OFF the WHEN menu** — Twinfang's moments are pure offense.
- **WHEN (earned offense moments — no auto-attack proc):** Riff (3 Perfects) · Full Finisher (a 5-cp dump) ·
  Peak (reach max Flow) · Bullseye (dead-center Strike — the graded-window core, §2c) · Punish (a dump in the
  Opening) · Detonate (pop a Deathmark — Deathmark module only, §4).
- **THEN (identity effects — show on the boss or feed the tempo):** Echo (delayed phantom hit — ex-Razor Echo) ·
  Rend (open/refresh a bleed) · Quicken (tighten window / +tempo 3s) · Expose (boss takes +% one beat) ·
  Mark +1 (Deathmark module only). **No +Flow ("Surge") THEN** — Flow is earned by clean Perfects only, or the
  greed dial dies (audit landmine). Heal/energy-trickle THENs are CUT (Quickblood / Red Harvest).
- **ALWAYS → folded into classics** (Wide Tempo, etc.). The three-slot trigger/payload/property taxonomy is
  **retired**; recycled pieces (Killing Tempo → the Full-Finisher WHEN · Razor Echo → the Echo THEN) become the
  board's card pool.

### 5d. Tutorial 🔒
Build it in front of the player: the **first draft IS the wiring screen** — plug one wire, watch it fire, a
one-line coach mark names the shape. No wall of text. Done.

---

## 6. Rarity model 🟡 (Model A recommended, confirm pending)

**Scope:** rarity applies to the **drafted boons** (WHEN/THEN/ALWAYS pieces) only. **Creeds and Modules are
curated picks — NOT rarity-weighted.**

**Model A — rarity = how build-DEFINING, not bigger numbers** *(recommended; it's what the game half-does today)*
- **Common (Haiku):** reliable pieces — a solid WHEN or THEN. The bread.
- **Rare (Sonnet):** pieces with a hook — a bigger moment, or an effect with a condition/synergy.
- **Legendary (Opus):** transformers — change a rule, or fuse a WHEN+THEN into a signature (the "hammer").
- **Numbers scale to TRIGGER FREQUENCY, not rarity** — a payload on a rare once-a-ramp trigger hits harder than
  one on a frequent trigger *because it fires less often*. A common-frequent build stays competitive with a
  rare-punchy one → preserves the **Monotonic Pool Law** (an unlock never makes a run worse; no "Opus always wins").

**Model B — rarity = power tiers** (same effect, bigger at higher rarity; ARPG loot). Familiar, but triples
content, risks trivializing, and fights the monotonic law. **Not recommended.**

Draft frequencies stay as-is (`draft.gd`): Haiku .70 / Sonnet .25 / Opus .05, synergy slot 0, opus pity, LOCK /
REROLL / UPSELL funded by Tokens.

**🟡 open:** confirm Model A. And: do Creeds/Modules carry any rarity *flavor* (e.g., one wild "legendary" Creed
unlocked late), or stay flavor-equal like Hades aspects?

---

## 7. Meta-progression — levels & unlocks 🔒

- **Per-class level = a NUMBER that quantifies your unlocks in that class** (event-driven unlocks — first-kills,
  sworn oaths, run clears — the level is a **readout / side-effect**, NOT a grind XP bar). "Twinfang Lv 7" = 7
  unlocks earned on it.
- **Overall level = the SUM of every class's level.** One free headline number.
- This is the existing `PROGRESSION-PLAN.md` **Rank track made visible** — no account currency, no parallel grind
  (the plan deliberately cut account XP). Creeds / Modules / curios are the unlockables.

**Run-flow timeline** (Tempo example — updated 2026-07-04):
| When | Choice |
|---|---|
| between runs | level up → **unlock more Creeds/Modules** into your pools |
| run start | draft **1 of 3 random Creeds** + your Aspect |
| **first draft (after fight 1)** | **wire your Combo** — 1 WHEN + 1 THEN (§5) |
| every won fight | 1-of-3 **classic** boon draft (classics + spells only — no board pieces) |
| some event nodes | **re-draft your Creed** for a penalty |
| **end of Floor 1** | pick **1 Module** |
| **end of Floor 2** | **re-wire the Combo** (optional free swap) |
| Floors 2–3 | keep drafting classics; Creed + Module + Combo ride with you |

---

## 8. This is a FRAMEWORK, not just Tempo 🔒

Creeds · Modules · the WHEN/THEN board · per-class levels are meant to **generalize to every class** (Guard /
Kick / Triage / Garden get their own Creeds & Modules over time). **Tempo is the pilot** — prove the shape here,
then port. The same board serves all five verbs; only the card words change.

---

## 9. FUTURE VISION 🔮 (parked — record, don't build)

- **Titles** tied to level / milestones / oaths.
- **Cosmetic transmog** — wear unlocked gear/curios cosmetically.
- **Social lobbies / hub areas** — online spaces to hang out & show off gear (rides on the existing netcode
  foundation once gear + accounts mature).

---

## 10. OPEN decisions 🟡 (several CLOSED 2026-07-04 — see §5 + the audit summary up top)

1. ~~Rarity Model A vs B~~ → **A** (frequency-scaling now lives in the Combo's WHEN→THEN number table, §5b).
2. ~~Which Creeds ship v1~~ → **Flourish + Drumline** (Drumline's reward = a wider window); Held Breath v1.1.
3. ~~Which Modules ship v1~~ → ~~Opening + Edge + Deathmark~~ → **Edge + Deathmark + Overdrive ⭐**
   (2026-07-06: the Opening promoted to the baseline verb — audit F1/F6/I1).
4. **The Edge — Module or baked-in?** (still leaning Module — open).
5. **Creed/Module rarity flavor?** (open — a wild legendary Creed, or all flavor-equal?).
6. ~~The WHEN/THEN menu~~ → **redefined to the single Combo rig** (§5); offense-only WHENs, no +Flow THEN. Exact
   per-WHEN numbers still to sim.
7. **Level unlock ladder** — what event unlocks what, and the starter pool (open).
8. **Graded-window numbers** (§2c) — Bullseye / Perfect / Good widths at base + max Flow, to sim.
9. **Dancer's Grace's effect** (auto-Perfect next Strike) — cut as a *dodge* boon; re-home it on an offensive
   trigger (a Peak, or an Opus) or drop entirely? (parked — the effect is good, only its dodge trigger was cut.)
10. **CRIT (audit F27, 2026-07-06):** the STRIKE lane is all-crit — needs a real design pass with Bill:
    is crit a BUILD? how do crits scale/work? more crit cards, or non-crit STRIKE cards that engage the
    graded window (consecutive-Perfect escalation, Goods banking)? *(blocked on the `wow-tempo-boons` slate.)*
11. **SWAN SONG's home (audit I7, 2026-07-06):** bake the "Flow can't be crashed by swings" moment into
    the class, or generalize it past final-phase — Bill floated an overall auto-dodge boon as the fun version.

---

## 11. Build order (recommended slices)

1. **Risk core** — combo-fix (§2a) + Flow-as-greed-dial + **Flourish + Drumline** Creeds, **simmed**. Proves the
   feel of pushing & slipping. *(start here)*
2. **Modules** — the Floor-1 pick flow + **Edge + Deathmark** on top of the shipped Opening.
3. **Clarity** — the WHEN/THEN board (draft preview + HUD strip) + the build-it-in-front tutorial; rename in code.
4. **Boon rework** — rebuild the trigger/payload pool for the no-auto-trigger model (§5c), tuned to frequency.
5. **Leveling** — the per-class unlock ledger + level readout (Rank track surfacing).

## 12. Systems touched (for implementers)

`data/twinfang/{twinfang_config,twinfang_kit,twinfang_policy,twinfang_boons}.gd` (core + boons + AI) ·
`game/draft.gd` (WHEN/THEN pools, no innate proc) · `game/raid_hud.gd` (Creed-draft screen at run start, Module
pick at Floor-1 elevation, the WHEN/THEN board + HUD strip) · a new **unlock/level store** (extend `gear_store`
/ progression) · reconcile with `PROGRESSION-PLAN.md` (Rank track). Keep the CombatCore reducer pure; Creeds /
Modules express through `seat.vars` + ClassKit hooks like every other class mechanic. Regression bar as always:
other classes byte-identical, determinism PASS, sims + smokes green.

---

## 13. FERMATA — Twinfang's second spec 🟢 (BUILT 2026-07-07 — worktree `fermata`)

> ### ✅ CODED — the whole deck is real, deterministic, byte-identical when unpicked
> Bill: "yeah go ahead and build this fully." Done in worktree `fermata` (kit-local, aspect-gated).
> **The verb:** Strike COILS — `coil` (press) / `release` (resolve) routed through `on_action`; a
> release < the sharpen floor UNRAVELS (no strike, ~0.35s stagger, no Flow loss); the AI policy
> presses early and releases on the centre-aim (same latency gradient as Tempo, split across two
> inputs). **Shared with Tempo** via `_tempo_family()` — Flow, combo, Coup, the Opening, the A7
> crit package, Understudy, Efficiency, the WINDOW bread all carry unchanged. **Built:** 4 creeds
> (Patient Knife / Fleeting Shade / Long Night / Tutti) · 2 modules (⭐Shadow Dance duration-gated
> bullet-time + The Mark brand→Evis cash) · 11 boons in COIL/VEIL/RELEASE + On the Beat on the
> Tempo side · 3 keystones (Unseen Blade / Eclipse / Phantom) · 3 rig WHENs (on-edge / deep-coil /
> unravel). **VERIFY:** twinfang_sim base+fat fermata determinism PASS; @expert base fermata =
> 25.7 bullseyes/run (coil lands dead-centre, = Tempo's ~22), @good smears to Perfect (same
> gradient), 0 unravels from the clean AI; **Tempo `4932869838389671587` + Venom
> `7876031242436484463` checksums MATCH main byte-for-byte**; raid_sim `--blade=fermata` Mistral
> determinism PASS + 100% win/skill (distinct from venom's checksum & TTK); ui_smoke_raid OK.
> **SIM SIMPLIFICATIONS (feel lives in the HUD, flagged for the render pass):** TUTTI's every-
> button-coil + coiled-kick is modelled as "dumps take the live window grade mult" (the coil
> delay/kick-tax is a control-feel thing the instant-dump AI can't express); PHANTOM is a flat
> Bullseye twin-strike (no two-blades-crossing UI in sim); VEIL OVER THE WARBAND publishes
> `veil_warband_active` but the ally application is OWED (same raid-buff channel as Battle Hymn).
> **HUD INPUT WIRED (2026-07-07, `fermata-hud`):** the first playtest hit "picked Fermata, got
> Tempo" — root cause: the HUD only sent an instant `strike` tap, and `_strike(from_release=false)`
> IS the Tempo strike, so the coil verb was never invoked. Fixed: key 1 DOWN → `coil`, key 1 UP →
> `release` (mirrors the Alchemist hold); AbilityRune gained `held`/`released` signals so the slot-0
> rune coils on touch/mouse too; the RhythmBar draws the coil charge ring (violet fill → white-hot
> SHNK) + coil cues; the TwinfangGauge shows Fermata's Flow tier-gems, not the poison wheel. Verified
> by `fermata_input_check` (sharp=dmg / early=unravel / bare=no-op) + WSLg shots. Applies to the
> world preview too (shared HUD).
> **THE ROAMING WINDOW (2026-07-07, `fermata-window` — Bill: "the artifact game had the window
> moving"):** the green now RELOCATES after every resolve — a per-beat shift (s.rng, fermata-only
> draw) multiplies the accelerando'd window CENTRE in ONE spot at the end of `_edge_window` (width
> + every boon/creed effect preserved; policy/HUD/grading all read through it automatically),
> clamped reachable (mouth ≥ coil floor + 0.10s read margin; far edge on the ruler). Fermata gets
> a FIXED 1.8s ruler so the bar never rescales — the band jumps around on it, tester-style. Knobs:
> `fermata_shift_min/max 0.75/1.85 · fermata_ruler_sec 1.80`. Charge ring moved OFF the needle to
> a fixed socket at the left end-cap (the coiling needle tints umbra instead). Probe asserts the
> roam (4 distinct centres / 4 beats); checksums still byte-identical; expert AI tracks the roam
> (24 bulls/run); cadence is now irregular by design (expert TTK 16→20s — far windows = long beats).
> **THE DRAW (pacing pass, 2026-07-07 `fermata-pace` — Bill: "it takes all focus, can't cast my
> spells… maybe I have to start holding down for it to start? less far-left windows unless high
> Flow"):** the sweep is now PRESS-relative — the clock only runs while you hold; idle is genuinely
> calm (Flow decay is the only pacing nudge) so dumps/kicks are cast between draws. Near windows
> are EARNED: `fermata_near_slack 0.30s` extra keep-away at Flow 0 → 0 at max Flow (short twitchy
> draws only inside a hot streak). Knock-on: Patient Knife / Patient Edge re-anchored to the
> FAR-WINDOW fraction (`fermata_far_pivot 0.8 / far_span 0.6`) since draw length is now decided by
> where the window lands; Patient Knife also raises its own shift floor (`patient_shift_min 1.30`
> — the knife waits). Bar: idle cue "HOLD 1 — start the draw", parked needle, "too early" region =
> the un-sharp coil floor. Verified: probe 4/4 PASS, checksums byte-identical, patient measurably
> slower than base (22.0s vs 20.2s @expert), idle/charging/sharp WSLg shots clean.
> **V4 DECK RE-AUDIT (2026-07-07 — DESIGN ONLY, at Bill's verdict; the CODE still holds the
> stopgaps until he rules).** Bill: "you can no longer CHOOSE how long to charge the coil — the
> window decides; rerun your ideas, better explanations, tags." Every card re-read under the Draw
> (artifact 3c01d3ed, v4 — WHAT/WHY/FEELS + greed/ease/speed/control/etc tags per card):
> - **BROKE (hold-length greed became roll-luck):** Patient Knife → **OVERTIME creed** (every
>   window grows an amber tail ~40% past the green; releasing there = flat Perfect +20%, no Bull;
>   past the tail = miss; far floor + unravel-crash kept) · Patient Edge → **DEEP EDGE** (damage
>   grows the deeper past the plumb you release, up to +12/18/25% at the far lip — chosen
>   micro-hold, deliberately fights the Bullseye centre) · Unseen Blade → **Shades bank while you
>   REST** (1/0.7s idle, max 5, +6% each on the next release — the rest-vs-chain greed dial).
> - **FADED (sharpen-speed is no longer the bottleneck):** Feint → **THE REROLL** (an unravel
>   re-rolls the window; H stagger stays / S free / O biased near — the direct answer to "if it's
>   close I can't pick") · Quiet Fuse → floor-lowerer reframe · First Pass (DEGENERATE: every draw
>   is now "first after SHNK" ⇒ permanent widener) → **FIRST NOTE** (rest ≥1.5s → that window
>   +20/30/40% wider).
> - **DEAD:** rig WHEN Deep Coil (draws top out ~1.4s) → **THE RESTED DRAW** (begin a draw after
>   resting 1.5s+). On-the-Edge WHEN re-read: now only possible on floor-tight windows (rarer =
>   premium, fine). Unravel WHEN: watch Feint-reroll abuse in sims.
> - **NEW (the dials the Draw opened — REST / ROLL / OVERTIME):** **Composure** (Flow doesn't
>   decay for 2/3/4s after a Perfect+ release — the cast-in-the-calm card) · **Refrain** (a
>   Bullseye HOLDS the window in place for the next draw; repeat +0/10/20%) · **Stretto**
>   (windows roll nearer ~15/25/35%; S+ trims the low-Flow slack — the speed build's placement
>   dial, opposite pole of the Knife).
> - **Keystone text fix:** Eclipse chains now guarantee the chained window lands NEAR (a far roll
>   would kill the dance). Tutti re-stated for the Draw: dumps fired mid-draw take the sweep's
>   live grade; off-green −15%.
> Boon lanes reorganized to teach the model: THE ROLL / THE DRAW / THE RELEASE / THE REST.
> **OPEN — BILL'S EDGE-BULLSEYE IDEA (mid-verdict, 2026-07-07):** move the Bullseye to the
> window's FAR LIP with damage ramping toward it (entry = weak-but-safe, lip = bull against the
> miss cliff; crossing the lip = auto-SNAP). NOT visual variance — it splits greed from safety
> (centre model: best aim = safest aim; edge model: best aim = zero late-margin), restores chosen
> hold-depth AT BASE, and splits identity from Tempo (precision vs NERVE). If adopted: Deep Edge
> is absorbed into base (cut), Patient Knife's Overtime = "the ramp continues past the lip",
> wideners must add ENTRY runway only (never move the lip). Band widths unchanged (good 45 /
> perfect 37 / bull 18) so a bull is the same-size target — overshooting one just costs a miss
> now. A/B live in the tester (⚙ CENTER ⇄ EDGE, default EDGE): artifact e920ea01…
>
> **EDGE LOCKED + V5 REDESIGN + THE DECK-CREATOR SKILL (2026-07-07 — Bill: "edge is way better,
> this feels great, lets do a redesign, and you should make a deck creator skill").**
> - **The verb is now THE RAMP & THE SNAP:** inside the window damage ramps entry→lip (GOOD 45% /
>   PERFECT 37% / BULLSEYE last 18% against the cliff); crossing the lip auto-SNAPS (miss + Flow
>   crash, no dead-note state); release before the window = plain miss. Widener law: forgiveness
>   adds ENTRY runway only — the lip and bull band never move. **CODE OWED:** the kit still grades
>   centre — recode `_strike_grade` (fermata branch), the snap state, policy depth-aim, HUD ramp
>   bands (thin slice; after the v5 deck verdicts, recode verb + slate together).
> - **THE SKILL:** `.claude/skills/deck-creator/SKILL.md` — the reusable card-design playbook for
>   EVERY class slate: the Framework slots + quotas (one WILD creed, one ⭐transformer, elite-only
>   spectacle keystones, ≥1 greed / ≤1 insurance per lane), THE PICK-TENSION LAW (design the
>   offer-trio dilemma, not the card), the fun hierarchy (greed > payoff > control > pacing >
>   bread > insurance — never ship insurance raw, dress it as a play), the anti-pattern list from
>   Bill's real cut history, coherence rules (dials→lanes, polarity pairs, 2–4 named archetypes,
>   the BROKE/FADED/DEAD/OPENED sweep on verb changes), numbers/rarity rules, and the
>   design→verdict→build process.
> - **DECK v5 (artifact 3c01d3ed — first slate authored under the skill):** CUT Deep Edge
>   (absorbed by the base verb) + the On-the-Edge WHEN (near-SHNK releases are now the safe play —
>   rewarding them pays spam). REWORKED: Patient Knife = THE LONG RAMP (+40% ramp past the lip,
>   deep lip +20%, snap = crash + 0.5s stagger, far windows) · Shadow Dance = 3s of NO SNAP
>   (fearless lip-riding fever) · Fleeting Shade = snap/miss −2 Flow (its net now covers the
>   cliff). NEW: **Cold Cut** (GOOD-band releases +1 CP, S refund 4 energy — the shallow-safe
>   release made productive; the insurance rule applied) · **The Brink** (nerve-streak meter:
>   +3% per PERFECT-or-deeper release, cap 5, a snap zeroes it) · **The Razor** rig WHEN (a
>   release in the last ~0.05s before the lip — the jackpot moment). Named archetypes: the Speed
>   Knife (Stretto·Fleeting·Quiet Fuse·Eclipse) / the Slow Nuke (Patient·Unseen Blade·First
>   Note·Rested Draw) / the Safe Butcher (Cold Cut·Composure·Mark) / the Fearless Dance (Shadow
>   Dance·Brink·Killing Whisper). Offer-trio audit ran: no auto-picks, no auto-skips.
> - **V5 VERDICTS IN (Bill, 2026-07-07): everything KEEP except `feint` CUT ("no time or reason
>   to veto") and `shadowstep` CUT ("one block card only" — Vanish is the one defense card; the
>   dodge-breaks-the-draw law now bites unsoftened, his call). The Unravel rig WHEN stays
>   (accident-only consolation now).** Slate LOCKED → **build brief for the implementing agent:
>   `FERMATA-V5-BRIEF.md`** (repo root — the verb spec, the full slate table with per-card code
>   status, file-by-file code map, work order with checksum gates, verification matrix, gotchas).
>
> ### ✅ V5 EDGE BUILT — merged to main `f5d5397` (2026-07-07, worktree `fermata-edge`)
> The whole EDGE verb + v5 slate is real, deterministic, byte-identical when unpicked. Releases
> grade by DEPTH (`_ramp_grade`); the lip auto-SNAPS (`_snap`); wideners are entry-only. Patient =
> THE LONG RAMP, Fleeting snap-net, Shadow Dance = 3s NO-SNAP fever; feint/shadowstep/patientEdge/
> firstPass CUT; NEW Stretto/Refrain/Cold Cut/The Brink/Composure/First Note; rig Razor + Rested;
> Unseen Blade rest-banks, Eclipse chains near. Policy = fractional depth-aim + latency jitter.
> HUD = ramp bands + crimson lip cliff + snap flash. VERIFY: Tempo `4932869838389671587` / Venom
> `7876031242436484463` byte-identical - det PASS (base/fat/mixed) - input_check 5/5 incl SNAP -
> raid `--blade=fermata` det PASS - smoke 0 errors - nerve gradient (expert ~0 snaps/100%, sloppy
> 10+/50-70%). OWED (other layers): Brink/Shade/Mark/Dance HUD meters - shadow-dim - keystone
> elite acquisition - Veil warband application - online spec-carry. `FERMATA-V5-BRIEF.md` = as-built.
> **STILL OWED (other layers):** shadow-dim while coiling · Shade/Mark/Dance meter gauges ·
> elite acquisition for the 3 keystones (Topology elite node) · online spec-carry in `(seed, spec)`.
> The frozen poison-wheel Venom stays as the AI-only legacy aspect (poison is the Alchemist now);
> the blade lobby shows Tempo + Fermata.

_Original design below (verb locked via feel-tester 2026-07-06 — the deck Bill verdicted)._

The Brew left to become its own class (audit F10 → `ALCHEMIST-PLAN.md`), so Twinfang owes a second
Aspect. The hunt (2026-07-06): MOTIF rejected ("no strategy, too similar to the warrior") · OSTINATO
rejected ("novel but strategies aren't jumping out; less complex") · Vol.2 rubber-band/pot/spring trio
rejected ("too far from just the tempo variation — but I liked the hold"). **LOCKED: a TRUE small
variation — Tempo with a HOLD instead of a TAP.** Bill played the Fermata tester and likes it.
The in-code poison-wheel Venom stays the FROZEN placeholder aspect until this ships.

**Fantasy = WoW Subtlety steal.** The hold IS stealth: press = coil into shadow (world dims), release
in the window = the strike from the dark. Name **FERMATA** (musical: the held note) — alt UMBRA.
Tempo attacks *on* the beat; Fermata attacks *out of the silence between beats*. Same bar, same music
metaphor, opposite temperament. The design win: **a tap is an instant, a coil is a STATE** — the whole
deck keys off "while coiled", a condition dimension Tempo's boons can't touch.

### 13.1 THE VERB (base kit — tester-verified feel)
- Same bar, **one-way sweep left→right** (wraps), same graded window as Tempo (Bull 18%/×1.8 ·
  Perfect 55%/×1.6 · Good ×1.0 · Miss = slip). **The strike happens on the RELEASE.**
- **Min coil 0.35s**: hold until the blade SHARPENS (charge ring fills → SHNK flash + chime). Release
  early = the shadow UNRAVELS: no strike, ~0.35s stagger, no Flow loss. Kills the click-cheat dead.
- Base has **NO hold-length bonus** — coil-duration payoffs are build territory only (boons/creed).
- **Dodge rule (base):** a dodge input mid-coil BREAKS the coil (you just lose the charge, no stagger).
  Creeds/boons soften this — never the base.
- Tester baseline knobs (Bill's ⚙ sliders may retune): sweep 0.55 bar/s · flow speed-up +3%/pt ·
  window 0.17 · miss stagger 0.45s. Tester: `scratchpad/fermata-tester.html` (+ HOLD⇄TAP A/B toggle),
  artifact e920ea01… Charge ring on the marker was "kinda distracting" — HUD pass should try the ring
  OFF-marker (fixed gauge position) vs on-blade fill only.
- Class chassis carries in full: Flow 0–6 +8%/pt · combo points → Eviscerate (Bullseye +1 CP) · base
  energy refund on Perfect/Bull (F11) · **Opening = class base verb** (dumps ×1.9) · Whetted-Edge crit
  package (A7) is CLASS-level and works unchanged (Edge builds from sharp Perfect/Bull releases).
- **DUMPS ARE INSTANT AT BASE (verdict pass 1, Bill 2026-07-06):** only STRIKES coil; Eviscerate +
  utility stay instant-press (the Tempo idiom) — base Fermata is the true small variation. The
  kit-wide coil was KEPT but demoted to the **TUTTI creed** (Bill: "i like it but it changes a bunch,
  maybe creed"). Kick at base = the class standard (instant flagged dump inside the tight window);
  the COILED KICK lives inside Tutti.

### 13.2 CREEDS (pick 1 — coil temperament)
- **THE PATIENT KNIFE `patient`** — the coil keeps charging past sharp: +1.5%/0.1s, cap +20%. Cost:
  an unravel = a FULL slip (Flow crash). Greed on the hold dimension; pairs with the keystone nuke.
- **THE FLEETING SHADE `fleeting`** — min coil 0.20s, unravel painless, a Miss loses 2 Flow instead of
  crashing. Cost: Flow cap 4. The fast, forgiving crossover creed for Tempo hands.
- **THE LONG NIGHT `longnight`** — sweep ×0.75, windows ×0.75, releases ×1.20. The Largo mirror
  (reuses largo knobs) — slow, small, heavy. Precision posture.
- **TUTTI `tutti`** [verdict pass 1 — Bill's creed-demotion of every-button-is-a-coil] — EVERY button
  coils: Evis, utility, the kick, all hold→sharpen→release. Payoff: **sharp dumps get the window
  grade multiplier** (a Bullseye Evis ×1.8). Cost is inherent (min-coil delay + grade risk on dumps;
  un-sharp release = unravel, no fire). The COILED KICK rule applies here: the flagged ability kicks
  only when released sharp inside the kick window — being coiled is being ready. Balance lever = the
  dump grade mults; sims A/B dump uptime vs the other creeds. (Creed pool is now 4, like Alchemist.)

### 13.3 MODULES (Floor-1 pick · one ⭐transformer, per class law)
- ⭐ **SHADOW DANCE `shadowdance` (transformer)** — gauge fills from sharp Perfect/Bull releases at
  Flow ≥ 4 (Overdrive's fill idiom); at 6 the next coil triggers THE DANCE: **3s of sweep ×0.5**
  (bullet time — bullseyes become pickable, min coil instant), then crash to Flow 2. A skill
  AMPLIFIER, not free damage — you choose when to enter it by coiling.
- **THE MARK `mark`** — sharp Bullseye releases brand the boss, tier I→III (one small brand icon);
  **Eviscerate consumes the brand: +12%/tier.** Active finisher decision (Evis at II or push for III?)
  — Deathmark done right: a dial, not a passive.

### 13.4 BOONS (address rule — categoried by the part of the coil they touch; ALL roll H/S/O per offer)
**COIL** *(the hold itself)*
- Patient Edge `patientEdge` — releases +2%/0.1s coiled beyond sharp · cap +18/26/35% (stacks with
  Patient Knife's baked bonus by raising the cap, not the rate)
- Restless Dark `restlessDark` — energy regen +30/45/60% while coiled
- Quiet Fuse `quietFuse` — min coil −0.08/−0.12s / O: also removes the unravel stagger
- Feint `feint` [2nd pass] — an unravel PRIMES your next coil: it sharpens 50/75/100% faster. Failure
  becomes tempo — and opens deliberate-unravel play with the rig's unravel WHEN
**VEIL** *(defense-in-shadow — the auto-dodge home)*
- Vanish `vanish` — the first boss hit per coil: −50% dmg / fully dodged / fully dodged AND the coil
  stays sharp (Bill's requested auto-dodge boon, living where the fantasy puts it)
- Shadowstep `shadowstep` [reworked from Shadowmeld — Bill: "i dont get it"] — **dodging no longer
  costs you your coil**: H keeps the coil at half progress / S keeps it fully / O keeps it AND it
  sharpens instantly. The clean softener for the dodge-breaks-coil base law
- Veil Over the Warband `veilWarband` **[SUPPORT]** — while you're coiled the whole warband takes
  −4/6/9% damage (the shadow stretches over allies; Fermata's Battle-Hymn counterpart)
**RELEASE** *(the strike)*
- Killing Whisper `killingWhisper` — Bullseye releases +15/22/30%
- Twin Echo `twinEcho` — releases at max Flow echo a second strike at 30/45/60%
- First Blood `firstBlood` — first release after any Miss/unravel: auto-Perfect / +1 CP / auto-Bullseye
- First Pass `firstPass` [2nd pass] — the FIRST time the marker crosses the window after your SHNK,
  the window is +20/30/40% wider. Rewards decisive releases — the explicit counter-axis to Patient
  builds (fast-release vs slow-release is now a real build choice, not a solved answer)
**AMBUSH lane CUT (verdict pass 1, Bill 2026-07-06)** — Ambush / Cheap Shot / Curtain Call all cut:
no Opening/dodge-interplay boons for now. (Design preserved here if the lane ever reopens: release
into an Opening from a pre-Opening coil +25/35/50% · post-PERFECT-dodge release auto-Bulls · sharp
Evis inside an Opening +30/45/60%.)
**SHARED-POOL CARRIES** *(class-level cards both specs draft — verdict per card)*: the A7 crit package
(Hone keystone · Heartseeker · Serrated · Assassin's Note) · Crescendo · Da Capo · Understudy ·
Efficiency · **[2nd pass] the WINDOW lane bread carries too** — Wide Tempo / Fencer's Line / Rubato
address the window itself, and Fermata uses the SAME window, so they work unchanged (this was
Fermata's missing wideners lane; no new cards needed). Battle Hymn stays Tempo-flavored (Fermata's
support = Veil Over the Warband).

### 13.5 RIG (new WHENs — slot into the existing class THEN table)
- WHEN I stay coiled ≥ 1.5s · WHEN I unravel · WHEN I release within 0.3s of the SHNK ("on the edge")

### 13.6 KEYSTONES (A8 — elite-node drops, never in normal drafts; pool = these 2 + shared Hone)
- **THE UNSEEN BLADE `unseenBlade`** — while coiled, gain a SHADE every 0.5s (max 5); each Shade = +6%
  on your next release; Shades are a STANDING battery (persist until a release spends them). The
  slow-nuke build-definer; pairs with Patient Knife + Patient Edge into the one-giant-release build.
- ~~NIGHTFALL~~ **CUT (verdict pass 1)** — Bill: "keystones need to be way more fun than open kick
  window." **The fun bar for keystones is now explicit: spectacle-grade build-definers, never a
  stat.** 2nd keystone OWED; candidates for Bill's react:
  - **ECLIPSE `eclipse`** — a sharp Bullseye release instantly RE-COILS you, already sharp. Chain the
    dance: release-release-release, perpetual shadow, until a miss ends it.
  - **PHANTOM `phantom`** — while coiled, a phantom blade sweeps in from the RIGHT; the window is
    wherever the two blades CROSS — release on the crossing for a twin strike ×2. Rewrites the bar's
    timing read entirely; elite-drop spectacle.

### 13.7 BUILD ORDER + ENGINE NOTES (after Bill's deck verdicts)
1. Kit base: aspect `fermata` guarded on twinfang_kit (byte-identical unless picked — the Brew idiom);
   **input surface gains press/release** — `perform()` needs a coil_press/coil_release action pair
   (tick-stamped queue already supports it; AI policies emit both with tier-scaled coil timing).
2. `twinfang_sim` fermata cells (verb determinism + creed A/Bs) → 3. creeds → 4. modules → 5. boons →
   6. rig WHENs → 7. HUD (charge ring OFF-marker per Bill; shadow dim on THE HUD; brand icon).
Owed same-as-Tempo wiring: HUD gauges · elite acquisition (A8) · online spec-carry in `(seed, spec)`.

---

## 14. THE TEMPO BRANCHES — six build-theme candidates 🟡 AT VERDICT (2026-07-10)

**What this is (corrected pass — Bill, 2026-07-10).** A BRANCH is a **build theme inside the
existing spec** (the tank's Headsman/Ironside/Ghost precedent): a general category that cards,
creeds and modules FEED, so drafts coalesce into synergy. **Tempo's base minigame and identity are
untouched** — no dial bends, no new buttons, no identity gauges. Pick **2–3 themes**; the deck
pass then files the existing pool + new cards into the winners (each winner gets its chain: entry
creed → module → boons → capstone keystone, per `DECK-LAYOUT.md §3`). Example cards below are
ILLUSTRATIONS, not proposals — no CARD-CATALOG rows this pass.

*(The first version of this section pitched six minigame-REWIRE ideas — those were the wrong
altitude for "branch" and are parked as future SPEC/ASPECT ideas in §15, per Bill: "this is cool,
we can have more spec ideas, but I want to keep my current specs.")*

**Ground:** the `research/` knowledge base + the four lens digests from the first pass (the theme-
grade material carries over); the existing built pool from Appendix A / `twinfang_boons.gd`.

### The theme candidates at a glance

| # | Theme | In three words | Mostly |
|---|---|---|---|
| 1 | **THE WOUND** | bleed, then cash | new cards |
| 2 | **THE FINISH** | fewer, bigger hits | names existing cards |
| 3 | **SWIFT** | more, faster hits | mixed |
| 4 | **THE EDGE** | cleanliness becomes crits | names existing cards (A7) |
| 5 | **THE PUNISH** | live for the Opening | mixed |
| 6 | **THE BAND** | your groove helps everyone | new cards (thin — maybe texture) |

*(Poison is deliberately absent — that's the Alchemist's lane. Bleeds are the Twinfang-legal cut.)*

---

### THEME 1 — THE WOUND · *bleed, then cash*

**What its cards do:** clean cuts keep cutting. Bullseyes leave short bleeds (a few beats each);
boons deepen and extend them; Eviscerate can consume the live bleeds for a burst. The game is
keeping the pot boiling and cashing before it cools.
**Dials addressed:** the grade (bleeds key to Bullseye/Perfect) · Eviscerate (the casher). Nothing
bends; a small wound-counter rides the boss frame.
**Absorbs from the existing pool:** the `bloodletter` rig THEN (the bleed payoff already in code) ·
the unbuilt `hemorrhage` module data (becomes this theme's module seed).
**Example new cards:** creed *Open Veins* — Bullseyes leave a bleed from run start · module
*Hemorrhage* — the wound counter + bleeds tick +1 beat longer · boon *Deep Cuts* (STRAT) —
Perfects also bleed · boon *Arterial Note* (GREED) — bleeds tick 30% harder but expire 1 beat
sooner · keystone *EXSANGUINATE* — consuming 5+ live bleeds in one Eviscerate erupts in a
blood-burst that staggers the boss.
**Greed/comfort + EASE knob:** greed = riding bleeds long before cashing; knob = bleed duration
grace.
**Nearest neighbor:** Alchemist poison (brewed vials, potency, sustained rot) — bleeds are
physical, short-lived, and cashed in bursts; Fermata's Mark (brand tiers on hold-grammar) — this
is tap-grammar with expiry pressure.

---

### THEME 2 — THE FINISH · *fewer, bigger hits*

**What its cards do:** weight the payoff end of the loop — max-combo Eviscerates, heavier Coups,
payoff timing. The Largo player's natural home: slow hands, huge punctuation.
**Dials addressed:** combo points (hold them) · Eviscerate/Coup (make them enormous). Nothing bends.
**Absorbs from the existing pool:** the whole EVISCERATE lane (*eviPlus · execute · overkill ·
staccato*) + the COUP lane (*crescendo · daCapo · syncopation*) + **Largo** as the natural entry
creed. This theme mostly NAMES a ladder the pool already implies.
**Example new cards:** boon *Grand Pause* (STRAT) — an Eviscerate at exactly max combo hits +35% ·
boon *Heavy Ink* (GREED) — combo points above 3 each add +10% to the next finisher but decay one
per missed beat · keystone *THE CODA* — a max-combo Eviscerate inside an Opening echoes as a
second, free finisher (the double-hit fills the screen).
**Greed/comfort + EASE knob:** greed = holding combo for the perfect moment; knob = finisher-beat
width.
**Nearest neighbor:** Fermata (patience as a SPEC) — Fermata holds the *input*; the Finish holds
the *resource* while the hands stay Tempo-fast. And THE WOUND (also cashes via Eviscerate) — Wound
cashes a dot-pot, Finish cashes combo weight; they cross-feed rather than collide.

---

### THEME 3 — SWIFT · *more, faster hits*

**What its cards do:** strike frequency — energy refunds, uptempo windows, streaks of Perfects.
The anti-Largo pole.
**Dials addressed:** energy (refunds make it a real economy) · the beat (uptempo riders on
existing knobs). Nothing bends — cards ride the accelerando that already exists.
**Absorbs from the existing pool:** *pressAdvantage · coldOpen* (the STRIKE bread) · the
FLOW-generic boons (*tightrope · encore · shatterfall* file here first-pass) · **doubleTime**
(already keystone-class in the pool — becomes this theme's capstone).
**Example new cards:** creed *Uptempo* — the beat runs faster baseline, Perfects refund +2 energy ·
boon *Quickstep* (GREED) — each Perfect speeds your next window AND tightens it · boon *Momentum*
(POWER) — consecutive Perfects +1% each, cap 10, resets on a miss · keystone *DOUBLE TIME*
(absorbed) — the beat doubles for a stretch after sustained clean play.
**Greed/comfort + EASE knob:** greed = self-tightening for speed; knob = beat speed.
**Nearest neighbor:** THE EDGE (both love clean taps) — Swift pays *frequency* (more notes), Edge
pays *quality* (each note crits harder). Distinct poles; natural cross-feed pair.

---

### THEME 4 — THE EDGE · *cleanliness becomes crits*

**What its cards do:** convert clean play into crit quality. This theme ALREADY EXISTS as the A7
"Whetted Edge" package — naming it as a branch legitimizes the ladder and gives the deck pass its
filing. Cheapest theme to build.
**Dials addressed:** the grade → the EDGE meter (already in code, opt-in via Hone). Nothing bends.
**Absorbs from the existing pool:** *hone* (the keystone) · *heartseeker* (Bullseyes always crit) ·
*serrated* (+crit damage) · *assassinsNote* (+crit in the Opening — soft-feeds THE PUNISH too:
the worked example of a card feeding two themes) · the *killingEdge* rig THEN (banked crit
charges).
**Example new cards:** creed *Whetstone* — a crit-flavored temperament (crits steady the beat: the
window doesn't tighten on the beat after a crit) · boon *Stropped* (POWER) — +EDGE gain from
Bullseyes.
**Greed/comfort + EASE knob:** greed = the meter's slip penalty is real (−3); knob = EDGE-decay
grace.
**Nearest neighbor:** SWIFT (see above). Base Tempo law intact — **no crits without opting into
this ladder** (locked law, honored: the whole theme is opt-in via its creed/keystone).

---

### THEME 5 — THE PUNISH · *live for the Opening*

**What its cards do:** feed Opening play — arrive loaded, hit the punish harder, get paid for
clean kicks. Keys to boss events, not your resources.
**Dials addressed:** the Opening (bigger/better use of the window that already exists) · Coup (the
dump that carries the interrupt tax). Nothing bends — the Opening stays one graded punish window
exactly as built.
**Absorbs from the existing pool:** the *punish/peak* rig WHENs · *assassinsNote* (shared with
EDGE) · the interrupt-by-ability texture when it lands (TEMPO §10).
**Example new cards:** creed *Predator's Rest* — Flow doesn't decay while a boss telegraph is
winding up (you coil INTO the window; plain-words: waiting for the boss stops costing you) · boon
*Seize the Gap* (POWER) — Opening hits +20% · boon *Aftershock* (STRAT) — a Peak-grade punish
extends the Opening half a beat · keystone *THE GUILLOTINE* — a Peak-grade punish on a cast you
just kicked hits execute-grade with a visible flourish.
**Greed/comfort + EASE knob:** greed = saving your dump for the Peak (miss the centre and the
bonus is gone); knob = Opening width.
**Nearest neighbor:** THE FINISH (both burst) — Punish keys to *boss events*, Finish keys to
*your combo*. Cross-feed: a max-combo finisher inside an Opening is both — that overlap is the
soft-branch point, not a collision.

---

### THEME 6 — THE BAND · *your groove helps everyone*

**What its cards do:** warband texture — your clean rhythm throws small windows and echoes to the
other three seats. The one TEAM-flavored direction.
**Dials addressed:** Flow uptime + your finishers, mirrored outward. Nothing bends; rides the
already-owed raid buff channel (Battle Hymn's application debt).
**Absorbs from the existing pool:** *battleHymn* (the existing support card — this theme is its
family).
**Example new cards:** boon *Encore Call* (TEAM) — after your finisher, the next ally's big hit
echoes 15% of it · boon *Steady Drummer* (TEAM) — while your Flow ≥4, allies' windows shrink
slower · keystone *THE ANTHEM* — at Flow 6 the aura visibly pulses across all four seats and
Openings you punish linger longer for allies.
**Greed/comfort + EASE knob:** the donation trade (your meter dips, the warband's rises); knob =
none natural — flagged.
**Honesty flag:** thinnest candidate — may be a 2–3 card TEXTURE inside other builds rather than
a full branch with its own ladder; also gated on the buff-channel debt. In the slate because TEAM
is otherwise unrepresented.

---

### THE EXISTING-POOL FILING (first pass — proof the themes organize the real deck)

| Built card (lane) | Files under |
|---|---|
| heartseeker · serrated · hone · killingEdge (STRIKE/rig) | THE EDGE |
| assassinsNote (STRIKE) | THE EDGE + THE PUNISH (soft, feeds both) |
| pressAdvantage · coldOpen (STRIKE bread) | SWIFT |
| eviPlus · execute · overkill · staccato (EVISCERATE) | THE FINISH |
| crescendo · daCapo · syncopation (COUP) | THE FINISH |
| tightrope · encore · shatterfall · flowCap (FLOW) | SWIFT first-pass; some stay generic |
| doubleTime (FLOW, keystone-class) | SWIFT (capstone) |
| battleHymn (FLOW, support) | THE BAND |
| bloodletter (rig THEN) · hemorrhage (unbuilt module data) | THE WOUND |
| wideTempo · fencersLine · rubato (WINDOW wideners) | none — fold into the EASE dial at the deck pass (standing rule) |
| understudy (auto-dodge) | generic — the one insurance card, belongs to no theme (allowed) |
| Largo (creed) | THE FINISH (entry creed) |
| flourish · drumline · heldbreath (creeds) | generic temperaments — stay theme-free |
| Overdrive ⭐ (module) | untouched — stays the spec's module regardless of picks |

### Slate checks (inline skeptic pass, small)

- **Distinctness:** SWIFT vs EDGE = frequency vs quality (flagged, resolved as poles). WOUND vs
  FINISH share the cash button (Eviscerate) but cash different things (dot-pot vs combo weight) —
  cross-feed, not collision. PUNISH vs FINISH = boss-event vs own-resource. All six answer "what
  do your cards care about?" differently.
- **Coverage:** every built card files into a theme, the EASE fold, or explicit generic — no
  orphans; no theme exists only on paper except THE BAND (flagged honestly).
- **Anti-patterns:** no luck-greed (all greed chosen per card), one insurance card total
  (understudy, pre-existing), no new buttons anywhere, no identity gauges (Hemorrhage's counter
  is module-tier and the WOUND plays fine without it).
- **Spread:** 2 name-the-existing (EDGE, FINISH) · 2 new-blood (WOUND, BAND) · 2 mixed (SWIFT,
  PUNISH). Bill's examples covered: bleeds = WOUND · fast attacks = SWIFT · slow big ones =
  FINISH · poison = excluded (Alchemist's lane).

**Next:** Bill picks 2–3 themes → the deck pass (deck-creator skill) files old + new cards into
the winners' ladders, builds each chain (entry creed → module → boons → capstone keystone),
authors the EASE dial's knob list, and hard-copies the slate into CARD-CATALOG.

---

## 15. TEMPO SPEC/ASPECT IDEA PARKING 🔮 (six rewire pitches, 2026-07-09 — re-homed 2026-07-10)

**What this is.** The first branch-slate pass pitched six MINIGAME-REWIRE ideas — the wrong
altitude for "branch" (they change how Tempo plays, not how its cards file). Bill's verdict:
*"this is cool, we can have more specs ideas, but I want to keep my current specs."* So they are
PARKED here as future spec/aspect/keystone-scale material — record, don't build. Everything below
is the original text (research provenance intact; the skeptic fixes are folded in).

### The harvest (what the research says, one page)

1. **Sub-specs everywhere are "same buttons, different engine."** WoW's three rogues share
   Energy+CP but own different fight-phases; Hades' memorable weapon aspects REWIRE what a press
   means, and its stat-lean aspects are forgotten. Rule adopted: every branch changes the timing
   shape or what a press does — never just numbers.
2. **The meter's LAW is the identity.** Bank it (StS2 Regent) vs decay it (Hellsinger Fury) vs
   reset it (NecroDancer groove) — one "clean play fills a meter," three completely different
   feels. The branches below give Flow-adjacent meters different laws instead of five new resources.
3. **Defense-feeds-offense is the decade's best melee loop** (Sekiro posture, Nioh ki pulse, E33
   parry) — rerouted here through THE OPENING and through PRESERVING streaks, because our dodge is
   defensive by law.
4. **Greed must be chosen per use, with a bite you authored yourself** (Pact of Punishment, StS
   boss relics, Balatro skips). A reward keyed to a roll you didn't influence is a lottery ticket.
5. **The one-cadence trap** (FFXIV's 2-minute meta): branches that peak on the same clock
   homogenize. The six below trigger on six different rhythms — ramp clock, self-set burns, boss
   events, ally windows, whole-fight streak, constant density.
6. **Warband duos are unclaimed space.** Hades/StS/E33 are solo or parallel-co-op; nobody has
   cross-SEAT build payoffs on one shared telegraph stream. Four seats + AI backfill = ours.

### Slate rules (stated once, apply to all six)

- **The entry CREED carries the branch identity from run start; the module deepens it** (the
  DECK-LAYOUT chain, and the skeptics' recurring fix — a branch that only exists after the Floor-1
  module pick is dead cards for half a run).
- **Every branch contributes KNOBS to the EASE dial's roll — never flat comfort cards.**
  (Motif → resolve-beat width · Redline → burn rate · Counterpoint → chain-entry width ·
  Conductor → cue window · Soloist → rank-drop grace · Polyrhythm → ghost-pip size.)
- Touch targets at full build: 5 everywhere except Redline (6 of 7 — IGNITE via the module door).
- Three keystones touch beat-speed in different ways (True Redline accelerates · Crescendo locks ·
  Tempo Spike aligns) — acknowledged so the pick is made knowingly.

---

### PITCH 1 — THE MOTIF · *write the kill before you play it*

**The twist:** your damage becomes a promissory note. Clean strikes inscribe WOUNDS on the boss —
a visible stack that does nothing yet. Pressing Eviscerate ON a downbeat *resolves* the stack:
a clean resolve cashes everything; a fumbled resolve press **burns half the stack**. Land the
resolve inside an Opening and it counts double. Patience → one number that dwarfs the fight.

**What you're for:** the ramp player. You stop caring about per-hit damage; you care about stack
count and when to cash. Verses (inscribe) and a chorus (resolve) — and the chorus itself is a
graded press with real stakes.

**Dials:** THE GRADE (only Bullseye/Perfect inscribe) · the downbeat (the resolve press) · the
OPENING (the doubler, not the gate). Wounds live from run start on the entry creed; the module
adds the deepening layer. No core dial bend.

**Example cards (illustrative):** *Deep Cuts* (STRAT) — Bullseyes inscribe 2 wounds. ·
*Let It Deepen* (GREED) — unresolved wounds grow +8%/beat, cap +50%; a fumbled dodge tears 3 off.
· *Resolving Chord* (POWER) — resolved wounds hit 25% harder. · *Second Verse* (RULE) — after a
resolve, your next 3 strikes auto-inscribe (even Goods).

**Capstone keystone — THE CATALYST CHORD:** a resolve landed on an Opening's Peak doesn't just
cash — the stack ERUPTS across the next 3 beats as a chained detonation and the blast staggers
the boss, stretching the window. The minigame visibly changes: three beats of fireworks you earned
over a whole verse.

**Greed/comfort:** hold-the-stack greed; the bite is burning wounds on a fumbled resolve or losing
them to a phase change. Comfort face: cash early and often, smaller but safe.

**Not the Alchemist, not Fermata's Mark:** nothing ticks, nothing poisons — wounds are inert until
your press; and where Fermata's Mark cashes its brands freely, the Motif's identity IS the growth
clock plus a stake-carrying graded resolve.

**Sources:** WoW Assassination's ramp identity · StS Catalyst · AtO Dark-detonation.
**Pillar check:** single-target native · no new buttons (5 targets) · dodge untouched ·
meta-taste ADMITTED (ramp→spend) but the graded, stake-carrying resolve press exists only here.

---

### PITCH 2 — REDLINE · *light the furnace; it only burns while you feed it*

**The twist:** the energy bar — dead weight today — becomes FUEL. While the furnace is lit, every
strike hits harder but every beat burns energy faster than it regenerates; the fire dying dry is a
hard crash. The escape hatch is skill: after a finisher while lit, a **reclaim pip** flashes on
the beat lane — nail it to claw energy back, and the tighter the tap, the bigger the refund.

**What you're for:** engine management. Choose ignition windows, ride as long as you dare,
reclaim-tap to extend, douse on a downbeat to bank a clean exit. Sustain greed, entirely self-set.

**Dials:** BENDS the ENERGY dial (inert → the branch's fuel economy) + adds the reclaim micro-beat
(rides the existing lane). The entry creed seeds a weak auto-lit state (auto-ignites during
Openings, so the branch plays from fight 1); the module adds IGNITE — the chosen-ignition button —
through the one sanctioned module-button door (6 of 7 targets; its WHEN is the ignition read).

**Example cards (illustrative):** *Stoked Blades* (POWER) — lit strikes +20%. · *Flashpoint*
(STRAT) — igniting as an Opening starts refunds 30 energy. · *Oil the Fire* (GREED) — the fire
burns 30% hotter and 30% thirstier. · *Backdraft* (RULE) — dousing on a Bullseye banks 2 combo
points (the exit is a move, not a pardon).

**Capstone keystone — TRUE REDLINE:** keep one burn alive past 10s and the beat accelerates past
its normal floor, the ring glows red-hot, every strike echoes. The longest burn you've ever held,
visible and audible.

**⚠ Absorbs Overdrive:** the FEVER→crash cycle becomes the furnace's life cycle — this branch
REPLACES Tempo's only built module, so the other picks must supply the 2–3 module slots.

**Greed/comfort:** duration greed; the bite is the dry crash, chosen at every ignition. Comfort:
short controlled burns.

**Sources:** Frost DK Breath of Sindragosa · Nioh Ki Pulse/Flux (the research's single most
transferable steal) · Hellsinger decay.
**Pillar check:** single-target · dodge untouched · one button via the legal door with a real
WHEN · trivially AI-pilotable (ignite near an Opening at high energy, reclaim on schedule).

---

### PITCH 3 — COUNTERPOINT · *the boss's swing is your best weapon*

**The twist:** the Opening stops being a one-tap bonus. Every boss telegraph becomes a STRING you
play through — answer its beats in tempo and a Pressure meter climbs, converting the punish window
into an escalating burst. And this branch carries the kick: a dump pressed **Perfect-or-better**
inside a cast's kick-window IS the interrupt; a Bullseye-grade kick pays extra on top.

**What you're for:** you live for the boss's turns. Modest groove between telegraphs; when the
boss winds up, you lean in while everyone else leans away.

**Dials:** BENDS THE OPENING (one tap → a multi-beat answer-chain with a Pressure bar that lives
only inside the window); leans the GRADE and Coup. The keystone adds a boss-side bar.

**Example cards (illustrative):** *Answering Blade* (POWER) — Opening hits +20%. · *Perfect
Rebuttal* (STRAT) — a Bullseye-grade kick opens a private 3s Opening only you can punish. ·
*Last Word* (GREED) — enter an answer-chain at Flow 6 and its final beat counts double Pressure,
but any fumble inside the chain slips 2 Flow. (The draft's skip-a-dodge card was CUT by the
skeptics — nothing here ever prices eating a hit.)

**Capstone keystone — DEATHBLOW:** a boss POISE bar only your chain-answers and clean kicks fill
(it recovers faster at high boss HP — no turtling). Break it inside an Opening: the boss staggers
to its knees and the telegraph stream freezes for a private massacre window — yours; the warband
gets a short rider, not the crown (that's the Conductor's).

**Interrupt angle (feeds the open §10 verdict):** proposes COUP DE GRÂCE as Tempo's carrier —
Perfect-or-better to kick keeps deliberate-vs-accidental falling out of the grade itself, tuned to
clear the pillar's >85%-deliberate bar at good-tier.

**Greed/comfort:** execution greed (Last Word); the bite is fumbling mid-chain, never damage taken.

**Sources:** Sekiro posture/deflect-chains · E33 Break bar + parry-strings · WoW interrupt
rotations.
**Pillar check:** answer-chains are STRIKE presses — the dodge stays purely defensive · a
multi-beat string is ONE telegraph to the scheduler (safe) · no new buttons (5 targets) ·
meta-taste ADMITTED (riposte) but a graded answer-string on a deterministic telegraph stream
exists nowhere else. Engine debt flagged: the poise bar + stagger state.

---

### PITCH 4 — THE CONDUCTOR · *the warband keeps your time*

**The twist:** the first support-rogue. Your rhythm is a resource the other three seats ride —
and the spine is ACTIVE: you *call* windows (choose the moment, choose the beneficiary), you
don't radiate a passive aura. Hades and StS literally cannot build this; we have four seats and
AI backfill.

**What you're for:** keep your own clean groove, and spend it on calls: a Bullseye inside an
Opening CUES the warband — everyone hits the note you called.

**Dials:** leans FLOW (the fuel for calls) and THE OPENING (the call moments). No core dial bend.
Flagged honestly: needs the cross-seat plumbing (the already-owed raid buff channel + one new
policy hook; the cross-seat credit idiom exists in code).

**Example cards (illustrative):** *The Downbeat* (TEAM) — your Bullseye inside an Opening extends
the window half a beat for every seat (once per Opening). · *Section Leader* (STRAT) — while your
Flow ≥4, the AI seats play tighter (their policies gain timing accuracy). The band follows the
leader — only a game with AI raiders can print this card. · *Give Them the Beat* (GREED) — donate
2 Flow to double your next call; your own damage dips while they shine. · *Encore Call* (RULE) —
after your finisher, the next ally's big hit echoes 30% of it. (The draft's always-on aura was
demoted by the skeptics — at most one boon carries a passive aura; the branch is the calls.)

**Capstone keystone — THE TEMPO SPIKE:** for 6 seconds every seat sees YOUR ring overlaid on
their kit — their windows widen, and anything landed on your downbeat pays out together. Four
kits visibly answering one rhythm — without re-clocking anyone's minigame (the skeptics priced
the full re-clock out; this overlay keeps the fantasy at a tenth the engine cost).

**Signature-CD note:** this branch's fantasy doubles as the strongest CD-shape candidate for
Tempo (a group tempo-call you line up with a boss window).

**Greed/comfort:** donation greed — give your power away and win on warband speed; the ego tax
(your meter looks worse) is real and chosen.

**Sources:** WoW Bloodlust + Augmentation's buff-donation · E33 shared Gradient · AtO cross-seat
setter/spender.
**Pillar check:** warband-law native · single-target · no new buttons (5 targets) · flagged: sim
work to prove AI seats ride the calls + the buff-channel debt + the policy-accuracy hook.

---

### PITCH 5 — THE SOLOIST · *the song grows as you go untouched*

**The twist:** a performance rank — D → C → B → A → S — where **each rank visibly ADDS an accent
pip to your beat lane**: the song literally gets richer as you perform. Accent pips pay bonus
damage/Flow when hit. Eat an answerable telegraph and you drop a rank — and the lane audibly,
visibly loses a voice. Rank climbs on clean beats; clean dodges and correctly-ignored feints
PRESERVE it (the dodge never deals damage — law intact); only answerable hits strip it.

**What you're for:** whole-fight streak tension where the stakes are the music itself. At S the
lane is full, the spotlight finds you, and one eaten swing silences a voice you spent minutes
earning.

**Dials:** leans the DODGE BEATS (as stakes, never as offense) + the beat lane (accents are new
pips on the existing lane). The rank is one overlay gauge; no core dial bend.

**Example cards (illustrative):** *Stage Presence* (POWER) — finishers +6% per rank. · *Encore of
Nerves* (GREED) — at rank A/S the windows tighten 15% but Bullseyes pay double Flow: bite you
opted into, exactly when you're proudest. · *Intermission* (STRAT) — dropping a rank grants 3
beats of double Flow gain: the comeback verse is a play, not a pardon. · *The Held Note* (STRAT) —
correctly ignoring a feint counts as a clean beat for the rank.

**Capstone keystone — THE CRESCENDO:** hold S for 10 seconds and enter the Solo: ~8s where the
beat locks at full speed, every tap counts Bullseye-tier, Flow can't decay. Enterable only by
flawless play — never a toggle.

**Greed/comfort:** defense-greed; the bite keys ONLY to answerable telegraphs (chip you couldn't
answer never drops rank). Comfort knob: rank-drop grace.

**⚠ Honesty note:** the skeptics ranked this pitch weakest even after its fixes — the accent-lane
rework is what keeps it in the slate (a plain no-hit multiplier was judged a rank costume on a
stat). It's here because the fantasy is strong; it earns a pick only if the growing-song hook
lands for you.

**Sources:** E33 Verso Perfection Rank · DMC style meter · NecroDancer groove · Hades
Thanatos-Mortality shape.
**Pillar check:** dodge preserves, never grants (Bill's rework cut ALL dodge-feeds-offense —
honored) · single-target · no new buttons (5 targets) · distinct from Flourish (taps missed) —
this bets on hits taken.

---

### PITCH 6 — POLYRHYTHM · *two blades, two beats, one finger*

**The twist:** the dual-blade fantasy made literal — as rhythm, not buttons. Optional GHOST NOTES
appear between main beats at high Flow: an expert doubles the rhythm, a casual never has to (a
whiff inside a lit ghost pip is a no-slip grace — stated law, so Flourish can't crash you for
trying). The capstone splits the lane into two interleaved rings — left blade, right blade —
**both riding the ONE Strike key**: the split lives in the alternating cadence you read, not in a
second button (the skeptics killed the extra input; this is better anyway — it's pure reading
skill, and the phone layout doesn't change).

**What you're for:** the expression branch — you find Flow 6 comfortable and want a 16th-note
ceiling. Raises the ceiling; never touches the floor.

**Dials:** BENDS THE BEAT — the opt-in ghost-note sublane (zero new buttons, zero new gauges; pips
live on the existing lane). No touch-target change (5).

**Example cards (illustrative):** *Grace Note* (STRAT) — ghost notes grant +1 combo point (no
Flow). · *Syncopate* (RULE) — hitting a ghost note makes your next main beat visibly slower: you
reshape your own song mid-fight. · *Double Stop* (GREED) — ghost + main back-to-back Bullseyes
form a CHORD (+30% on the pair); attempting the chord and missing the main beat slips Flow.

**Capstone keystone — THE TWO-HANDED SONG:** the lane splits into two interleaved rings, one per
blade, alternating; each keeps its own mini-groove and matching both fills chord finishers. The
minigame looks like a different instrument — the aspect-grade rewire of the slate.

**Greed/comfort:** density greed — the bite is attention overload, entirely opt-in (skip the
ghosts, keep the floor). Comfort knob: ghost-pip size.

**Sources:** Hi-Fi Rush subdivisions · NecroDancer lanes · Monoco's deterministic wheel · Hades'
transformative-aspect standard.
**Pillar check:** single-target · dodge untouched · zero new buttons after the skeptic fix ·
Fermata-distinct (taps, never holds) · AI-pilotable (policy gains optional extra taps).

---

### SLATE-LEVEL CHECKS + the pick

**Spread:** GREED ×2 on orthogonal surfaces (Redline = fuel · Soloist = streak) · ramp/STRAT
(Motif) · boss-answer (Counterpoint) · TEAM (Conductor) · expression/RULE (Polyrhythm). Six
different clocks — no shared cadence.
**Skeptic ranking (pick-tension, strongest→weakest):** Conductor · Redline · Counterpoint ·
Polyrhythm · Motif · Soloist. Zero kills; ~17 fixes folded above.
**Composition notes for a 2–3 pick:** Motif + Counterpoint both want Opening seconds (eased by the
Motif fix — its resolve is any downbeat now) · Redline + Polyrhythm together is an attention
stress-test (soft branches make it self-inflicted, but flagged) · Soloist + Counterpoint conflict
DISSOLVED by the fixes (nothing prices eating hits anymore).
**Engine debts (priced by skeptic 2):** Counterpoint's poise/stagger state · Conductor's
cross-seat channel + policy-accuracy hook (buff channel already owed) · everything else rides
existing surfaces.
**Skipped on purpose:** the Gambler (every version drifted into luck-wearing-greed's clothes) ·
the Executioner (stock meta, failed the twist bar — execute riders can be boons inside
Motif/Redline) · the Hoarder/Star Bank (branch-scale banking brushed Fermata's hold-for-more;
survives as a signature-CD shape: bank the CD by nailing marked phrase beats) · the Pendulum
(Eclipse-style mode flip — good, but didn't beat any of the six; fold-able later as a module).

**Status:** PARKED 🔮 (2026-07-10) — no picks pending here. Any of the six may return as a future
spec/aspect (the roster owes second specs elsewhere), or shrink to keystone/module-scale ideas
inside the real branch themes (§14). The Hoarder→signature-CD note and Counterpoint's
Coup-as-interrupt proposal remain live inputs to their own open verdicts.

---

## APPENDIX A — THE TEMPO CARD LEDGER (v2 · Bill's ledger verdicts 2026-07-06 folded)

> ### ✅ THE WHOLE PLAN IS NOW CODED — merged to main `67f5efc` (2026-07-06)
> Bill: "code everything, make it real, the whole tempo plan." Done, kit-local + deterministic:
> **cuts/folds** (Opportunist·Held Note·spells·Killer's Eye gone; Edge→Largo, Deathmark cut;
> Opening = class base) · **base-kit** (F11 base energy · F15 Bullseye superset · F8 Good-maintains ·
> F19 wideners taper · F26 Syncopation cost-only · F17 Held-Breath crash-event) · **crit rework A7**
> (no base crits; Heartseeker always-crit + HONE's standing Edge meter + Serrated + Assassin's Note) ·
> **Largo creed** · **Through-Line** · **Understudy** · **Overdrive module** (fever verified firing) ·
> **Battle Hymn** signal. VERIFY: twinfang_sim ALL determinism PASS · crit build 90→100% / 41.6→29.1s ·
> Overdrive fevers/run 1.00 @expert · ui_smoke_raid ALL OK · raid_sim --blade=tempo 4 Seals det PASS.
> **STILL owed (need other layers):** HUD gauges (Edge meter / Overdrive / Understudy pips) = raid_hud
> render work · Battle Hymn's party-aura *application* = raid buff channel · A8 keystone/elite
> *acquisition* = Topology elite-node type. Mechanics are real & simmed; these three are wiring.

**Why this exists:** the complete card state so no session loses it. Source of truth for behavior =
`godot/data/twinfang/` (boons/config/kit/rig/creeds/modules) — this ledger adds the DESIGN intent
(ladders, addresses, verdicts) the code doesn't carry. **v2 (Bill, 2026-07-06 evening):** Opportunist /
Held Note / Flurry / Grace Note / Coda CUT · Fencer's Line capped ~+35% · energy refund goes BASE +
Efficiency boosted · Opening = class BASE (never a module) · Edge module → folded into the new LARGO
creed · Deathmark CUT ("a passive, not extra UI") · modules = OVERDRIVE ONLY for now · **crit = opt-in
build (A7), no crits at base.**

**Design laws recap:** every card must bend MANY attacks (one-time bonuses are invisible → cut) ·
cards are CATEGORIED by the button/dial they touch (the address rule) · **rarity architecture (Slice 2,
DESIGNED NOT BUILT):** every card ROLLS Haiku/Sonnet/Opus per offer — numeric cards scale the number,
rule-changers scale via authored RUNES; today's code ships fixed rarities + base numbers on the old
Draft-2.0 engine. UPSELL→tier-bump + Market tier-up/fine-tune = same deferred slice.

### A1 · Boons (v2 pool · id · base numbers · designed H/S/O ladder)
**STRIKE** *(crit cards moved to the A7 opt-in package; the lane's non-crit bread now = the 2 BUILT cards below + Through-Line owed)*
- **Press the Advantage `pressAdvantage` [BUILT `c1071bd`]** — basic Strikes landed inside the Opening
  deal +30% (`press_advantage_mult 0.30`; `_deal` gates kind perfect/strike on `_in_opening`). Keep
  drumming the punish, don't just wait for the dump. · ladder 30/45/65%
- **Cold Open `coldOpen` [BUILT `c1071bd`]** — Strikes at Flow ≤ 2 deal +25% (`cold_open_mult 0.25`,
  `cold_open_flow_max 2`) — the low-Flow mirror of Tightrope; a post-crash rebuild bet. · ladder 25/35/50%
- Through-Line `throughline` [design owed] — consecutive Perfects escalate +2%/stack, cap 5, reset on Miss · ladder +2%c5/+3%c5/+3%c8
- On the Beat `onTheBeat` [CANDIDATE — Bill's idea from the Fermata verdict pass, verdict owed] —
  dumps fired INSIDE the strike window gain the window's grade multiplier (a Bullseye Evis ×1.8).
  Bar-side timing for dumps — the Tempo mirror of Fermata's TUTTI creed, at the boon layer (opt-in
  greed; deliberately harder than dumping into the Opening) · ladder ×grade at 60%/80%/100% effect
  · VERIFY (both built cards): twinfang_sim determinism PASS + boonless CSV byte-identical (guarded no-op);
    strike A/B cell 90.0%/43.8s → 95.0%/41.7s; ui_smoke_raid ALL OK; raid_sim --blade=tempo 4 Seals det PASS.
**WINDOW**
- Wide Tempo `wideTempo` — window +15%/side (`wide_pad 0.15`) · ladder 15/22/34% · ⚠ F19: wideners TAPER with Flow
- Fencer's Line `fencersLine` — a Bullseye widens the NEXT window (`fencer_pad`, one-shot) · **ladder 15/25/35% (Bill: was too big at 25/40/60)**
- Rubato `rubato` — window sits 0.05s EARLIER (`rubato_shift`, floor-clamped) · ladder 0.04/0.06/0.09
**FLOW** *(Held Note CUT — Bill 07-06)*
- Momentum `flowCap` — Flow cap +2 · ladder +1/+2/+3
- Tightrope `tightrope` — +15% dmg at max Flow (`tightrope_mult`) · ladder 15/22/34%
- Encore `encore` — double-hit tier at Flow 2 · ladder T1@2 / +T2@4 / +Coup@5 ⚠sim
- Shatterfall `shatterfall` — a 4+ crash detonates 25/pt lost · ladder 25/38/56 · pay-AFTER-the-slap law
- Double Time `doubleTime` [RULE-CHANGER] — at max Flow each Perfect tightens + stacks +4% until crash · runes: +3%c4 no-tighten / +4%c6 / +4% uncapped floor .08s
- Battle Hymn `battleHymn` [SUPPORT, designed/owed F14+I2] — hold high Flow → raid haste/CD aura by Flow tier, OFF on crash · ladder aura/+tier/+Coup-pulse
**EVISCERATE**
- Deep Cuts `eviPlus` — Evisc +8/cp · ladder 8/12/18
- Finish It `execute` — Evisc +35% below 35% boss HP · ladder 30/45/67%
- Overkill `overkill` — over-cap combo banks into next Evisc, +6 each max 3 · ladder 6/9/13
- Staccato Fury `staccato` — post-crash next Evisc FREE +50% · ladder free/+40/+80%
**COUP** *(F23: folding into FLOW)*
- Crescendo `crescendo` — Coup +40% · ladder 40/60/90%
- Da Capo `daCapo` — Coup Flow-seed +1 · ladder +1/+2/+2&+20en ⚠sim
**ENERGY** *(v2: refund is BASE now — F11 locked by Bill: "energy refund as a base")*
- BASE KIT: Perfect refunds ~4 energy, Bullseye ~6 (knobs TBD in build) — clean play self-fuels.
- Efficiency `strikeEnergy` [BOOSTED] — Perfect refunds MORE on top of base · ladder +6/+9/+13
- Syncopation `syncopation` [RULE-CHANGER] — max-Flow Strikes cost 0 · runes: half/free/free+Goods-grade-up · ⚠ F26: base rune never removes grade risk
**SPELLS — LANE REMOVED (Bill 07-06: Flurry / Grace Note / Coda all CUT).** New buttons only return if a design earns one.

### A2 · The graded window + core knobs (BUILT)
Bullseye = centre 18% (×1.8) · Perfect = centre 55% (×1.6, +1 Flow, +1 cp) · Good = flanks (×1.0, NO
Flow, no slip) · Miss = base + Creed slip. `grade_bull_frac .18 · grade_perfect_frac .55 · bull_mult
1.8 · good_mult 1.0`. ⚠ F8: GOOD-maintains + tighten-asymptote to a thumb floor. ⚠ F15: Bullseye =
strict superset + signature juice. **v2 BASE additions:** energy refund on Perfect/Bullseye (above) ·
THE OPENING is part of the base class (see A3).

### A3 · Creeds / Modules / Rig (v2)
- **THE OPENING = CLASS BASE 🔒 (Bill: "a standard base of the class, not a module"):** boss swings
  open a vulnerability window; dumps ride it up to ×1.9 Punish. Always on, tutorialized as core verb.
- **Creeds:** drumline (slip −2; designed wider-window reward still owed) · flourish (slip→0,
  +50%/Flow pt) · heldbreath (slip freezes Flow + 2s window lock; ⚠ F17 lockout counts as crash event)
  · **LARGO [NEW, design — Bill's ask: "slows things down, smaller windows, not so twitchy" + absorbs
  the Edge module]: the rhythm runs SLOW — beats land ~30-40% farther apart and the accelerando is
  tamed — but the window is ~×0.7 TIGHTER and Perfects/Bullseyes hit ~×1.25 harder. Fewer, weightier,
  more precise strikes — the deliberate seat. Slip = −2 (Drumline-grade).** ⚠ Altitude note: Largo is
  a pace-posture, not a slip-temperament — sanctioned by the asymmetric-classes rule.
- **Modules = THE OVERDRIVE ONLY (v2):** Edge module CUT (folded into Largo) · Deathmark CUT ("meh, a
  passive, not extra UI") · supersedes F6's "un-park into a 1-of-3." **⭐ OVERDRIVE** stays: at max
  Flow the multiplier stops and fills a meter — tap for FEVER (all-green window, Coup-tier auto-chain
  strikes), then crash to a seed. Bank → blow → rebuild. Floor-1 flow: offer Overdrive vs "no module"
  until more modules earn their way in (design more later, incl. a possible crit module — see A7).
- **Combo Rig** (BUILT + wired): WHENs riff 1.0 · bullseye 1.9 · finale 4.4 · punish 6.5 · peak 6.9 ·
  coup 8.4; THENs echo 12 · secondwind 5en · **killingEdge → REWORK (dead under no-base-crits: make it
  grant EDGE points if Hone is drafted, else a flat next-strike bonus)** · bloodletter 8 · overcharge
  6% · expose 3%. ⚠ F25: prove rare WHENs EV-positive; board shows TOTALS.

### A4 · Curio verdicts (unchanged)
KEPT/WATCH: Encore Bell (re-flavor) · Grace Period (creed-aware) · Second Opinion (no rig-doubling) ·
Le Chat's Bell (energy warm-start). CUT: Powder Vial · Riftmaw's Hunger. PARKED: Marked Deck · Tuning
Fork · The Set List · Curtain Call.

### A5 · Cut ledger (do not resurrect without cause)
07-04 audit: Riposte · Dancer's Grace · Ghost Step · Beat Dancer · Quickblood · Red Harvest · Twin
Step · Virtuoso. 07-05 playtest: Ambush · Rude Interruption. **07-06 ledger pass (Bill): Opportunist
("wind-ups is meh") · Held Note · Flurry · Grace Note · Coda · The Edge module (→Largo creed) · The
Deathmark module.** Parked: All In (I8). Dead plumbing in kit (inert): `_tf_trigger`/`_rhythm_proc`/
`tfTrig*`/`mod_*` — sweep later.

### A6 · Open build-slice (v2)
F1 Opening→class base 🔒 · Overdrive module (solo) · F8 Good-maintains + asymptote · **F11 base
refund 🔒 + Efficiency boost** · F12 cash-out tension · F15 Bullseye superset · F17 crash-event ·
F19 taper · F26 rune floor · F24 combo colors loop · F14+I2 Battle Hymn · F25 rig EV proof · F23
lane folds · Fencer's cap 35% · Held Note/spells removal · **A7 crit build** · LARGO creed ·
Through-Line. **✓ BUILT `c1071bd`: Press the Advantage + Cold Open (STRIKE lane bread).** Open DESIGN:
I7 Swan-Song/auto-dodge · §13 second spec · Through-Line + more STRIKE bread if drafts feel samey.

### A7 · THE WHETTED EDGE — crit as an OPT-IN BUILD (v2, Bill-steered 07-06 evening)
**Law: base Tempo has NO crits.** Crit is a build you opt into — and the big unlock is EARNED, not drafted.
- **HONE [KEYSTONE — elite drop, see A8]** — unlocks the **EDGE meter (0–10)**: Perfect +1 · Bullseye
  +2 · a slip dulls −3. **Standing meter, nothing consumed** (v2 — Bill: a missed Evisc must not
  waste the build): while Edge is up, ALL attacks (strikes AND dumps) carry crit chance ≈ 4–5%/pt
  (seeded `s.rng`), crit = ×2. Dumps double-dip naturally (big base × crit); the aimed jackpot =
  dump into the Opening at high Edge. Runes: 4%/pt · 5%/pt · 5%/pt + slips dull only −2.
- **Package (offer-gated on ANY crit source):**
  Heartseeker v2 [STANDALONE entry, normal pool] — Bullseyes ALWAYS crit · +Perfects 50% · +Perfects
  always (Goods never crit — treading water stays treading water) ·
  Serrated Fate — crit dmg +40/60/90% ·
  Assassin's Note [capstone] — crits inside the Opening +50/75/110%.
- **Killer's Eye CUT (folded):** strikes critting IS base Hone now. Rig killingEdge THEN → grants
  +2 Edge per fire (if any crit source) else flat next-strike bonus.
- **Synergies:** Overdrive FEVER auto-chain hones fast · Largo's fewer-but-Perfect strikes hone
  reliably (slow assassin build = Largo + Hone + Assassin's Note).

### A8 · KEYSTONES & ELITES — the acquisition layer (NEW, Bill 07-06: "it shouldn't just be in there")
**Problem:** build-defining rule-changers sitting in normal 1-of-3 drafts crowd out bread ("why would
you pick something else"). **Fix — the layer cake gets a 5th tier:**
- **KEYSTONE class** = the build-definers: **Hone · Double Time · Syncopation** (graduated OUT of the
  normal boon pool). One keystone per run (v1).
- **Acquired from ELITE encounters** — a new risk node type on the Topology: harder fight, reward =
  a 1-of-2 KEYSTONE pick. Take the dangerous road, earn the build. (Map-side dependency: elite node
  type + reward hook — design owed to the Topology/map system.)
- Layers: run-start = CREED · Floor 1 = MODULE · normal drafts = bread + hammers · **elites =
  KEYSTONES** · boss = rig wire/re-wire.
- **BALANCE GATE (Bill): build-parity EV check** — when built, `twinfang_sim` compares crit build vs
  Flow-stack vs rig variants at expert AND sloppy policies. Acceptance: no build >~15% EV-dominant at
  equal skill; keystone-less runs stay viable. (F25's EV-proof, generalized.)

### A9 · UNDERSTUDY — the auto-dodge boon (I7 resolved, Bill 07-06)
New GUARD (utility) lane: **Understudy** — auto-perfect-dodges the next authored dodge beat;
recharges ~25s · ladder 1/2/3 charges. Defense-QoL only — never feeds offense (dodge law intact).
Replaces Swan Song (cut from the idea list). Fits the DODGE RATION pillar (3–8 beats/fight) and gives
non-tank seats a "less defense juggling" draft option.

---

## 16. THE FERMATA BRANCH SLATE — v5 ladders filed + two additive themes 🟡 AT VERDICT (2026-07-10)

**What this is** (SLATE-PLAN row 8, the queue's LAST slate; branch = build THEME). The v5 deck
is BUILT (`FERMATA-V5-BRIEF.md` is the truth — its CUTS are law: Feint · Shadowstep · Deep Edge
stay dead, nothing here resurrects them). This pass names the ladders the built deck already
forms (PITCH #0) and pitches TWO additive themes — v5 is a tight deck; two honest themes beat
three padded ones. Verb untouched (the Ramp & the Snap); example cards are ILLUSTRATIONS — no
CARD-CATALOG rows. **Sibling wall:** none of this re-skins Tempo's §14 six (Wound/Finish/Swift/
Edge/Punish/Band). **How it was made:** the v5 brief + §13 re-read + fresh sweep
`research/fermata-sweep.md` (Superhot stillness · Guile charge economy) → 4 lenses → pitches →
**3 skeptic passes (3 kills — the record so far — ~5 fixes folded)**.

### 16.1 THE FILING TABLE — the v5 ladders, named (PITCH #0a/b/c)

| Ladder | The fantasy | Built v5 cards that feed it |
|---|---|---|
| **#0a THE BRINKMAN** — live at the lip | the closer the cliff, the sharper the blade | the Long Ramp creed (entry) · theBrink meter · the Razor WHEN · Killing Whisper · Quiet Fuse |
| **#0b THE RESTED BLADE** — the pause IS the move | stillness, then one perfect draw | First Note · the Rested WHEN · rest-bank Unseen Blade (keystone) · Composure · Restless Dark |
| **#0c THE WINDOW-SETTER** — put the note where you want it | the stage obeys the knife | Stretto · Refrain · the widener carries (Wide Tempo/Fencer's Line/Rubato, entry-side law) · Eclipse near-chain (keystone) |
| Minor lines (feed multiple) | — | the Mark module + Cold Cut (finisher economy — see the COLD HAND below) · Vanish/Veil-Warband (the one block card + the support) · Fleeting/Tutti creeds (temperament, any ladder) |

Zero orphans; each ladder enters from a creed or base machinery (law 5 holds). The Superhot/
Guile sweep confirms the shapes: every banked state here leaks or cliffs (Brink zeroes on snap ·
Shades spend on release · the coil snaps past the lip) — nothing parks safely.

### 16.2 ADDITIVE THEME 1 — THE AFTERIMAGE · *one draw, many shadows*

**What its cards do:** the echo build — result multiplication, never press multiplication (the
fewer-presses soul kept; Tempo's SWIFT owns press-count). Anchored by TWO CODED cards: Twin
Echo (max-Flow releases echo 30%) and the Phantom keystone (Bull = phantom twin). New cards
deepen the shadow: echoes of deeper releases echo harder; shadows stack on consecutive clean
draws.
**Dials addressed:** the release (echo riders keyed to grade/Flow) · Flow (the echo gate).
**Example cards:** creed *The Doubled Dark* — Twin Echo's effect at half strength is your
run-start baseline (entry law; the boon upgrades it) · boon *Deep Shadow* (POWER) — echoes
inherit depth: a Bullseye's echo echoes at 45% instead of 30% · boon *Procession* (GREED) —
each consecutive Perfect-or-deeper release adds +1 echo to the NEXT release (cap 3); any
snap/unravel clears the procession · keystone **THE COMPANY OF KNIVES** — at full procession,
your next Bullseye release brings the whole company: every banked echo lands as a visible
blade-flight across the gate, each graded a half-step softer than the last.
**Greed/comfort + EASE knob:** streak-greed (the procession); comfort = flat Twin-Echo value.
Knob: procession-break grace (unravel doesn't clear at the comfort end; snap always does).
**Nearest neighbor:** Tempo's SWIFT (more presses — this is more RESULTS per press) · the
Cask's Twin Casks (two objects in flight — this is one strike, many images). Recorded.

### 16.3 ADDITIVE THEME 2 — THE COLD HAND · *build shallow, cash branded*

**What its cards do:** names the archetype the v5 deck implies but never ladders: the
GOOD-band economy. Cold Cut pays shallow releases in CP; the Mark brands on Bulls; Evis cashes
brands — so the build is a SPLIT HAND: deliberate shallow draws for CP volume (safe, fast, no
Brink), then one branded Eviscerate cashed deep or in an Opening. The counter-axis to the
Brinkman made a real ladder — the two builds read the same ramp opposite ways.
**Dials addressed:** the release (shallow-on-purpose) · CP/Evis (the cash) · the Mark tiers.
**Example cards:** creed *The Ledger* — Good-band releases +1 CP from run start (Cold Cut's
baseline; the boon becomes its upgrade) · boon *Patient Books* (STRAT) — Evis at 5 CP consumes
the Mark at +1 tier (cash a II as a III) · boon *No Flourishes* (GREED) — while your Brink is 0
(never built), Evis +25%: commit to the shallow book, the lip pays you nothing · keystone
**THE RECKONING STROKE** — an Evis that cashes a tier-III brand at 5 CP inside an Opening
stops the sweep for a breath: one still frame, then the number (the accountant's guillotine).
**Greed/comfort + EASE knob:** commitment-greed (No Flourishes locks you off the lip);
comfort = mixed hands, smaller cashes. Knob: Good-band width (entry-side only, the widener law).
**Nearest neighbor:** Tempo's FINISH (fewer-bigger presses — the Cold Hand is MANY-shallow +
one cash) · the Prognosis's Called Shot (commitment greed on fight-arc — this commits to a
GRAMMAR). Recorded.

### 16.4 SLATE-LEVEL CHECKS + the pick

**Spread (all five):** lip-greed (#0a) · rest economy (#0b) · window control (#0c) · echo
spectacle (Afterimage) · shallow-build/branded-cash (Cold Hand) — five clocks; Brinkman vs
Cold Hand is the slate's designed polarity (the same ramp read opposite ways — real
pick-tension, stated).
**Skeptic record:** 3 passes · **3 KILLS** (the slate's job was mostly to say no): **the
Misdirection** (deliberate-unravel economy — built on the CUT Feint; resurrection without
cause) · **the Unbroken Line** (dodge-then-re-draw chains — dodge-feeds-offense one step
removed; Bill's rework cut that whole family) · **the Snap Dancer** (profit-from-snapping —
the snap must stay a cliff, not a slide; Fleeting's snap-net is the only sanctioned softener)
· ~5 fixes folded (Afterimage scoped to releases only, never autos · procession clears on
snap ALWAYS · Cold Hand's No Flourishes gates on Brink-0 so the polarity is chosen, not
accidental · Doubled Dark entry law · Reckoning Stroke earned-only).
**Skeptic ranking (pick-tension, strongest→weakest):** Cold Hand · Afterimage.
**Composition notes:** either additive theme + any #0 ladder composes; Cold Hand + Brinkman
in one run is the two-handed read (legal, spicy — the trio test at the deck pass should
confirm their cards repel per-draft); Afterimage + Rested Blade is the cinematic build (long
stillness, then a company of knives).
**Engine debts:** none — Twin Echo/Phantom/Mark/Cold Cut are coded; procession/ledger are
kit-local counters.
**Skipped on purpose:** the three kills above · **a TEAM theme** (Veil Over the Warband is
the support card and Bill already has three TEAM shapes at verdict this cycle) · **charge
partitioning as a theme** (keep-the-coil-through-X stays Opus-tier tech per the Vanish-Opus
precedent — a card family, not a ladder) · **any far-window/Deep-Edge revival** (v5 deleted
the far-fraction path; the widener law stands).

**Next:** Bill picks (the additive themes are 0–2 alongside the #0 ladder naming) → Phase-2
row D8 authors the v6 revision around the winners, inside the v5 verdicts.

**⚡ PHASE 1 OF THE SLATE MACHINE DRAINS HERE** — all 9 queue rows 🟡. The deck machine
(SLATE-PLAN §5–§6) opens on its next tick.

---

## 17. THE TEMPO DECK v3 — full deck around WOUND · SWIFT · FINISH 🟡 AT VERDICT (2026-07-10, Phase-2 D0)

**What this is** (SLATE-PLAN row D0 — the first DECK MACHINE pass; deck-creator playbook
followed end-to-end; design only, no code). **The winners:** no skeptic ranking was recorded in
the corrected §14, so the pass takes the three archetypes BILL HIMSELF named in the correction
("bleeds, fast attacks, slow big ones") = **THE WOUND · SWIFT · THE FINISH** — also the three
most grounded (Finish/Swift mostly name built cards; Wound is the one new engine). **Your ✅
picks override:** swap any winner and row D0 re-runs cheaply — the filing below keeps EDGE
(the A7 crit package, untouched, still opt-in law), PUNISH, and BAND cards alive regardless.
This is a REVISION of the built v2 pool (Appendix A) — every existing card is filed below;
Bill's prior verdicts (cuts, caps, laws) carry forward untouched.

### 17.0 DIALS + BUDGET (written first, per the playbook)

**The dials a card may address:** the GRADE (Bull/Perfect/Good/Miss) · FLOW (0–6 + accelerando
+ crash) · ENERGY (base refunds) · COMBO→EVISCERATE (build-cash) · COUP (execute) · THE OPENING
(class-base punish) · the BEAT (speed) · **the WOUND-POT (the one NEW dial: short bleeds on the
boss frame, press-cashed)** · [module] Overdrive's fever · [opt-in] the A7 EDGE meter.
**Budget:** touch targets unchanged (Strike · Eviscerate · Coup · dodge · signature CD when it
lands = 5 of 7; nothing below adds a button) · boon pool target 10–16 (see the trim table —
the honest count is the pass's one quota fight) · modules 2 · keystone pool grows to 5 with an
offer rule (tension point 4).

### 17.1 CREEDS (pick 1 · proposed pool of 5)

| Creed | Type | Status | Effect (one line) |
|---|---|---|---|
| **Drumline** | EASE-ish | STANDS | slip −2 — the forgiving temperament (wider-window reward still owed). |
| **Flourish** | GREED | STANDS | slip→0 Flow but +50%/Flow pt — the glass temperament. |
| **Largo** | STRAT | STANDS | slow heavy beats, tighter windows, ×1.25 hits — **THE FINISH's entry.** |
| **Uptempo** | GREED | **NEW** | the beat runs ~15% faster baseline and Perfects refund +2 energy — **SWIFT's entry.** The fast pole Largo never had; cap: the accelerando's existing asymptote (F8) is the ceiling, Uptempo never tightens windows further. |
| **Open Veins** | STRAT | **NEW** | Bullseyes inscribe a BLEED from run start (2 beats, modest tick) — **THE WOUND's entry.** No counter UI at creed level (the module adds it); the pot just ticks. |
| ~~Held Breath~~ | — | **PROPOSED PARK 🔮** | the slip-freeze temperament — niche since F17 made its lockout a crash event, and the pool needs the slot (quota 3–5). Bill's call. |

*Quota check: forgiving (Drumline) ✓ · greed pole (Flourish) ✓ · rhythm-changers (Largo/Uptempo
— the pace polarity) ✓ · **WILD creed: NONE** — Tempo still lacks a Tutti-class rewrite creed;
deliberately NOT forced this pass (tension point 1).*

### 17.2 MODULES (Floor-1 pick · pool of 2)

| Module | Type | Status | Effect |
|---|---|---|---|
| ⭐ **Overdrive** | RULE | STANDS | max-Flow banks the multiplier → tap for FEVER → crash to a seed. Swift-adjacent but build-agnostic — untouched. |
| **Hemorrhage** | STRAT | **NEW (builds the unbuilt `hemorrhage` data)** | the WOUND COUNTER: a visible pot on the boss frame (count + total); bleeds tick +1 beat longer; **Eviscerate may CASH the pot** (consumes all live bleeds, pays their remaining value instantly + 10% per bleed consumed). The gauge EARNS its pixels: cash-now-or-let-it-tick is a per-Evis decision. |

*Floor-1 offer: Overdrive vs Hemorrhage vs none. The Wound plays fine bare (creed bleeds tick
out unassisted); the module is where the CASH decision lives — chain intact: creed carries,
module deepens.*

### 17.3 BOONS (the pool, by dial-lane — 20 on the table, trim table below)

**WOUND (new lane — ≥1 greed ✓, 0 insurance):**
- **Lacerate** [STRAT · NEW] — Perfects also inscribe (half-value bleeds). Widens income beyond Bulls. H/S/O: half/two-thirds/full-value.
- **Slow Bleed** [POWER · NEW] — bleeds last +1/+2/+2 beats & tick +10% (cap: 5 beats total).
- **Arterial Note** [GREED · NEW] — bleeds tick +30/40/55% harder but expire 1 beat sooner: a hotter, shorter pot you must cash in rhythm.
**STRIKE (SWIFT's lane — ≥1 greed ✓):**
- Press the Advantage [POWER · STANDS, built] · Cold Open [STRAT · STANDS, built]
- **Through-Line** [STRAT · AUTHORED (was design-owed)] — consecutive Perfect-or-better strikes +2%/stack, cap 5, reset on Miss (not on Good — Goods tread water). H/S/O per A1.
- **Quickstep** [GREED · NEW] — each Perfect speeds your next window's arrival ~8% AND tightens it ~8% (self-bite for speed; caps at the F8 thumb floor; taper: never tightens below it).
- On the Beat [GREED · CANDIDATE 🟡 (Bill's own, unverdicted)] — dumps fired inside the strike window take the window's grade multiplier.
**FLOW (mixed/generic):**
- Tightrope [GREED · STANDS] · Encore [STRAT · STANDS] · Shatterfall [STRAT · STANDS, pay-after-the-slap]
- Momentum/`flowCap` [POWER · **PROPOSED PARK 🔮** — pure cap bread; Through-Line does its job with a pulse]
**EVISCERATE (THE FINISH's lane — ≥1 greed ✓):**
- Deep Cuts/`eviPlus` [POWER · STANDS] · Finish It/`execute` [POWER · STANDS] · Overkill [STRAT · STANDS] · Staccato Fury [STRAT · STANDS]
- **Grand Pause** [STRAT · NEW] — an Eviscerate at EXACTLY max combo hits +25/30/35% (the cap law; §14's illustration priced down from +35 base).
- **Heavy Ink** [GREED · NEW] — combo points above 3 each add +10% to the next finisher, and one decays per missed beat: hold the fat hand in rhythm or watch it drip.
**COUP:**
- Crescendo [POWER · STANDS] · Da Capo [POWER · **PROPOSED PARK 🔮** — seed bread, weakest trio-survivor]
**ENERGY:**
- Efficiency [POWER · STANDS — base refund exists; this is the boost]
**GUARD (insurance, class total = 1 ✓):** Understudy [EASE · STANDS].

**THE TRIM TABLE (the quota fight, Bill's call):** the honest pool above = 20. Proposed parks
to land at 16: **Momentum/`flowCap`** · **Da Capo** · plus EITHER **Encore** or **Efficiency**
(pick one to keep; the pass leans keep-Encore, park-Efficiency — base refunds already self-fuel)
· and **On the Beat** stays a 🟡 candidate outside the count until you verdict it. Wideners
(Wide Tempo · Fencer's Line · Rubato) are already OUT of the pool — folded into the EASE dial
per the standing rule.

### 17.4 RIG (WHENs — one addition)

Existing WHENs/THENs stand (riff/bullseye/finale/punish/peak/coup · echo/secondwind/bloodletter/
overcharge/expose; killingEdge rework note A3 stands). **NEW WHEN: "The Deep Cash" — WHEN I
consume 4+ bleeds in one Eviscerate (~×4.5, inverse-frequency priced)** — the Wound's earned
moment; only fires with the pot built (chooseable by construction). Bloodletter THEN naturally
cross-feeds the Wound (it already bleeds).

### 17.5 KEYSTONES (elite-only · pool of 5 · run 1)

| Keystone | Ladder | Status | The spectacle |
|---|---|---|---|
| **Double Time** | SWIFT | STANDS (graduated, A8) | the beat DOUBLES for a stretch after sustained clean play. |
| **THE CODA** | FINISH | **NEW** | a max-combo Eviscerate inside an Opening ECHOES as a second, free finisher — the double-hit fills the screen. |
| **EXSANGUINATE** | WOUND | **NEW** | an Eviscerate consuming 5+ live bleeds ERUPTS: the pot detonates as a chained blood-burst across the next 3 beats. *(§14's boss-stagger rider is DROPPED — engine-free version ships; the stagger variant is a Seal-pillar question, not a card.)* |
| Hone | EDGE (class) | STANDS (A7/A8) | unlocks the EDGE meter — the crit ladder's door. |
| Syncopation | class | STANDS (A8) | max-Flow strikes cost 0 (runes per A1). |
**Offer rule (new, tension point 4):** elite nodes offer 1-of-2 drawn theme-weighted (a Wound
build sees Exsanguinate more often) — the Hades god-routing steal, map-legibility friendly.

### 17.6 SUPPORT · CARRIES · SIGNATURE CD · EASE

- **Support:** Battle Hymn STANDS (Flow-tier raid aura; application still rides the owed buff
  channel — unchanged debt).
- **Carries:** Understudy (the one insurance) · curio verdicts A4 unchanged.
- **SIGNATURE CD (the owed DECK-LAYOUT §5 slot — first shape proposal):** **THE SET PIECE** —
  ~1-min CD; pressing it MARKS the next 4 beats as a phrase; landing all 4 Perfect-or-better
  cashes a finisher-grade flourish (auto-scaled to your build: bleeds pulse, combo refunds,
  Flow locks 2s). Amplifies skill, never button=damage; the §14 Hoarder note honored (bank-the-
  CD-by-nailing-beats). One knob: phrase length.
- **EASE (the dial archetype, DECK-LAYOUT §4):** on drop, rolls 2–3 of: window width (the
  folded wideners) · beat speed · Flow-crash grace · bleed duration (Wound) · finisher-beat
  width (Finish). Player slides ONE toward COMFORT (free) or BITE (+damage). Knob list is the
  deck's official EASE surface.

### 17.7 COHERENCE-GATE EVIDENCE (run, not claimed)

**Dream drafts (the archetype walkthroughs):**
- *THE WOUND:* Open Veins → Hemorrhage → Lacerate + Slow Bleed + Arterial Note → Exsanguinate.
  Bulls seed the pot → Perfects widen income → the module makes cashing a decision → Arterial
  heats it → the keystone erupts it. Every step raises BOTH the pot and the pressure to cash
  clean — compounds, never just adds. ✓
- *SWIFT:* Uptempo → Overdrive → Press the Advantage + Quickstep + Through-Line → Double Time.
  Faster beat → refunds feed the tempo → streaks stack → fever/doubling is the earned ceiling.
  The build self-tightens (Quickstep) — the greed is the build. ✓
- *THE FINISH:* Largo → (module-free or Overdrive) → Deep Cuts + Grand Pause + Heavy Ink +
  Finish It → The Coda. Slow weighty hands → hold the fat combo against decay → cash exact-max
  in an Opening → the echo doubles it. ✓
- *Hybrid (Wound×Finish):* Open Veins + Largo's boons — the pot ticks while combo builds; one
  Evis cashes both (§14's stated cross-feed, now draftable). ✓
**Offer-trio spot-checks (dealt honestly):** (Lacerate | Quickstep | Deep Cuts) — three builds,
no auto-pick ✓ · (Arterial Note | Heavy Ink | Tightrope) — three greeds on three surfaces ✓ ·
(Da Capo | Cold Open | Slow Bleed) — Da Capo auto-skips in two of three builds → evidence FOR
its park ✓ (the trio test found the trim).
**Overlap audit:** Quickstep vs Double Time (both speed — boon rung vs keystone ceiling, same
ladder: legal) · Through-Line vs Heavy Ink (streak-stack vs combo-hold: different dials, both
GREED-adjacent — flagged as the deck's greed-density spot) · each theme ≥3 exclusive cards ✓.
**Anti-pattern sweep:** no passive wind-ups · Hemorrhage's gauge creates a decision (cash) ✓ ·
no stat keystones (Exsanguinate/Coda are spectacles) · no one-time bonuses · caps stated on all
scalers · no new buttons · one insurance total · no luck-greed (every bite chosen). ✓
**AI-pilotability:** Wound = pot-value + bleed-TTL cash thresholds · Swift = the existing
streak/tempo policy params · Finish = combo-hold threshold + Opening sync (policy already times
dumps). All three expressible at 3 tiers; sim cells named: `--build=wound|swift|finish`. ✓

### 17.8 SKEPTIC RECORD (3 passes)

- **Draft-table skeptic:** found the 20-card quota breach → the trim table; found Da Capo's
  auto-skip → park; demanded Grand Pause price-down (+35→+25 base) — folded.
- **Repack skeptic:** Wound vs Alchemist DoTs — bleeds are SHORT (beats), press-seeded,
  press-cashed, no vials/no balance meter: distinct, and poison stays excluded ✓. Heavy Ink vs
  Fermata's Brink (both standing meters) — Ink is combo-HELD value with per-beat decay, Brink
  is release-grade stacks zeroed by a snap: different clocks, recorded in the distinctness
  ledger. Exsanguinate's stagger rider = engine debt → DROPPED (engine-free version ships).
- **Fight-clock skeptic:** bleeds die in short zone fights? — they're beat-scale (seconds),
  the pot cycles 3–4 times in a 60s fight ✓; the Coda needs an Opening — every authored fight
  has them ✓; Heavy Ink in a 7-node run arc — decay is per-missed-beat, not per-fight: no
  cross-fight hoarding ✓.

### 17.9 OPEN TENSION POINTS (the calls only Bill can make)

1. **The WILD creed gap** — Tempo has no Tutti-class core-rewrite creed. Author one later, or
   accept the gap? (Lean: later, with the mobile-layout pass — don't force it.)
2. **The trim table** (17.3): park Momentum + Da Capo + one of Encore/Efficiency? (Lean: yes,
   park all three named; 16-card pool.)
3. **Held Breath → 🔮 park** to keep the creed pool at 5? (Lean: park.)
4. **Keystone pool = 5 with theme-weighted 1-of-2 elite offers** — accept the offer rule?
   (Lean: yes; it makes elite routing legible.)
5. **THE SET PIECE** as Tempo's signature-CD shape? (Lean: yes — it's the strongest CD-shape
   candidate the §14 pass surfaced.)
6. **On the Beat** — your own candidate, still unverdicted; it slots into SWIFT's lane cleanly.
7. **Winner swap** — if you'd rather have EDGE or PUNISH in over any of the three, say the
   word: the filing keeps their cards warm and D0 re-runs cheap.

**Next:** your verdicts → statuses flip in CARD-CATALOG (rows landed 🟡 this pass) → the build
claim codes it kit-local + guarded (A/B byte-identical, sim cells per build, HUD after).

### 17.10 THE ABILITY AUDIT — Bill's D0 pass 🟡 AT VERDICT (2026-07-10)

**Bill's audit (his asks, triaged):** the deck is solid but the ABILITIES aren't clean —
everything keys to Eviscerate, *"nothing about coup and no other abilities"*; the ABILITY LAW
leaves **+2 button slots** — design some, from a re-read of the other-games research; decide
whether abilities are ISOLATED or MIX with boons (*"could even have a thing that if you have the
ability it opens up extra boons"*); verdict the SET-BONUS idea (same-group boons/keystones pay
small extras — or does that over-reward single-path builds?); and the SWIFT worry — *"double time
and stuff… there are limits to how fast it can/should go"* — dial back or re-look at the other
branch options. Ground re-read: `research/wow-retail.md` (rogue chassis · tier-set lesson ·
Symbols-of-Death windup · Restless Blades) + `research/hades.md` (duo/legendary pulls · Infusion
thresholds · Omega-hold) + §14/§15 live inputs. Board: the Slate-Machine artifact, D0 tab
(AUDIT sections). One honest read first: the Evis-centring is half by design — Evis is the cash
button for two of three themes — the fixes below give COUP its own story and add non-Evis moments.

**A · THE +2 BUTTON BUDGET — the ability slate (4 candidates, hold ≤2).** Chassis today = Strike ·
Evis · Coup · dodge + the Set Piece CD when it lands (5 of the hard-ceiling 7). New buttons enter
ONLY through the existing doors (drafted spells `type:"spell"`, ≤1 module button) and every one
must carry a WHEN, not just a WHAT (DECK-LAYOUT §5).
- **SFORZANDO `sforzando` (STRAT, spell)** — arm it: your NEXT strike is the accent — land it
  Perfect-or-better and it hits ×1.9 (H/S/O ×1.6/1.9/2.2) and pays the build's own currency
  (Wound: double inscribe · Finish: +2 combo · Edge-if-Honed: +2 EDGE); a slipped accent fizzles
  (energy lost). ~12s cd. The WHEN = the one beat YOU chose to accent (arm it into an Opening / a
  full pot / a fat combo). ⚠ rhyme-flag vs the Set Piece (one note vs the 4-note phrase, 12s vs
  ~1min) — if Bill feels overlap, Sforzando is the cut (or folds in as the Set Piece's Haiku rune).
- **THE RONDO `rondo` (STRAT, spell)** — lights ONLY in the post-Coup valley (~6s while Flow
  rebuilds from the seed): press ON a beat → an echo of the Coup you just cashed at 40/55/70%,
  graded by the beat you land it on. Coup becomes a two-act story (cash → the theme returns) and
  the crash valley becomes playable. Crescendo scales both; **Da Capo's proposed park REVERSES
  into this card's door** (§B). Not press-on-cd by construction — valley-gated and beat-graded.
- **THE COUNT-IN `countIn` (TEAM, spell)** — press during a boss wind-up: you call the beat —
  every seat's next window widens ~20% and ally hits landed on your call echo a slice of your
  Flow-mult. The §15 Conductor pitch at one-button scale = THE BAND's texture without spending a
  branch. Debt: rides the owed raid buff channel (same as Battle Hymn).
- **THE PICKUP `pickup` (GREED, spell)** — press between beats to pull your next window ~40%
  earlier AND ~20% tighter: chosen, per-press speed (never a roll), governor-clamped (§D).
  SWIFT-gated — only enters offers if SWIFT stays a picked theme.
- **THE KICK — a role, not a button (the pillar-#3 carrier proposal):** **Eviscerate = the
  standard interrupt** (a dump landed inside the verse's tight kick window IS the kick — the dump
  tax, affordable at any combo) · **Coup = the premium kick** (a max-Flow cash that also kicks
  staggers the verse longer). Grade-gated so deliberate-vs-accidental falls out of the grade
  itself (§15 Counterpoint's live input); sims measure per the pillar bar. Answers "nothing about
  Coup" at the ROLE level for zero buttons and closes BUILD-LEDGER's open "which Tempo ability
  carries" once verdicted.

**B · INTERACTION MODEL — abilities are DOORS (recommended), not islands.** Three options:
1. *Isolated* — self-contained buttons, cards never mention them. Cheapest — but the deck's only
   dead-end content, and a button no card feeds drifts toward press-on-cd (the law's anti-pattern).
2. **DOORS (lean — Bill's own instinct, and the deck's precedent: Hone offer-gates the whole A7
   crit package; Deathmark's cards entered the board only when equipped).** Holding an ability
   (a) unlocks its 2 gated boons into later offers — never dead cards by construction; (b) adds
   one rig WHEN to the wiring board (*WHEN I land the accent* ~×5.5 · *WHEN I Rondo ≥ half the
   Coup* ~×6.0 — inverse-frequency priced like every WHEN); (c) the ability itself reads your
   picked themes for its payoff currency (§A). Gated pairs (💡): Sforzando → *Fortissimo* (GREED —
   accent window −20%, payoff +30%) · *Marcato* (STRAT — a Bullseye accent stretches the Opening
   half a beat) ·· Rondo → *Second Theme* (POWER — echo tier up) · **Da Capo un-parked as the
   door's sister** (+1 Flow seed is exactly this build's card) ·· Count-In → *Section Leader*
   (TEAM — AI seats play tighter during your call) · *Tutti Chord* (GREED — all four seats land
   the call → the boss takes +8% for one beat).
3. *Full weave* — abilities × creeds/modules/keystones interaction matrix. Rejected: combinatorial
   authoring + balance surface for a side layer; DOORS + the rig buy the synergy feel at a tenth
   the cost.

**C · SET BONUSES — verdict NO on stat sets; RESONANCE (+ optional DUO) instead.** The deck
already pays path-commitment three ways — the synergy draft-slot pulls you deeper, elites offer
theme-weighted keystones, map nodes advertise their theme — and branches are soft by law
(committing already peaks higher than splitting). A passive 2pc/4pc stat set adds a FOURTH reward
on the same behavior and creates the threshold trap: drafting a worse card just to complete the
set (the auto-pick failure at slate level). The research says it plainly: WoW tier sets only work
because they're ROTATIONAL (and seasonal); Hades pairs its mono-lane payoff (Legendary) against a
cross-lane pull (Duo) so neither cages. So, two shaped versions of the "ding":
- **RESONANCE 🟡 (lean yes)** — at **3 cards of one theme**, that theme's ONE authored perk
  auto-lights (build-panel chip: *"WOUND 3/3 — resonance"*); rotational + tiny, one per theme,
  never stacks: Wound — expiring bleeds leave one after-tick · Swift — a 5-Perfect streak pulses
  2 energy · Finish — the exact-max Evis shows its phrase-mark (a read cue). The Hades-2 Infusion
  steal, deterministic thresholds, zero hand-authored combos.
- **THE DUO 💡 (the optional counterweight)** — 1–2 cross-theme capstone boons needing cards from
  TWO themes (the Hades duo steal): *Blood Coda* (Wound+Finish) — an Evis cashing 4+ bleeds at
  exactly max combo pays both bonuses ×1.25. Mixing keeps its own jackpot, so resonance never
  reads as a single-path cage.

**D · THE SPEED WALL — the governor + DOUBLE TIME v2 + the swap menu.** The worry is real, and
it's the ENGINE's before it's the thumb's: the sim runs 30 Hz (≈33ms ticks). Double Time v1's
deepest rune floors the window at 0.08s ≈ 2.4 ticks — the 18% Bullseye centre inside it is
SUB-TICK (ungradeable), and mobile touch latency (the spike's +Nms gauge) eats the remainder.
Stacked sources (Uptempo ×1.15 · Quickstep +8%/Perfect · the accelerando · fever · beat-doubling)
each clamp alone (F8/F19) but MULTIPLY together — every speed build pins at the floor and the
speed cards stop differing there (dead deltas at the top).
- **THE SPEED GOVERNOR 🟡 (a law, not a card)** — one clamp pair on `twinfang_config`
  (`beat_rate_cap` ~×1.6 base · `window_min` ~0.15s ≈ 4–5 ticks, keeping the Bullseye band ≥ ~1
  tick + read margin); ALL speed sources route through ONE function and combine ASYMPTOTICALLY
  (each extra source buys less near the wall — F8's asymptote generalized from the accelerando to
  the SUM of sources), so stacks approach the ceiling but every card keeps a visible delta.
  Numbers are sim knobs (`twinfang_sim --build=swift` cells).
- **DOUBLE TIME v2 🟡 — ghost notes.** v1 "the beat doubles" is the wall-breaker — cut. v2:
  sustained clean play opens ~8s where GHOST half-beat pips light BETWEEN your beats; each ghost
  landed = a free bonus strike (half damage, no Flow risk, purely optional). "Double time"
  musically = twice the NOTES — the beat never passes the governor and the player chooses the
  density. Spectacle intact (the lane visibly fills); casuals ignore the ghosts; AI = optional
  taps at tiered accuracy. (§15 Polyrhythm shrunk to keystone scale, exactly as its parking note
  sanctioned.)
- **The swap menu (D0 re-runs cheap — §17.9 point 7 stands):** SWIFT → **THE EDGE** (cheapest:
  the A7 package is built, deck becomes all-quality, speed stays base accelerando; flag — its
  capstone Hone is class-shared, not branch-authored) · SWIFT → **THE PUNISH** (Predator's Rest ·
  Seize the Gap · Aftershock · THE GUILLOTINE — pairs exactly with Coup-as-kick and the Set
  Piece; the structural pick if the audit itch is "abilities and Coup should matter") · **THE
  BAND — don't branch it** (take the Count-In spell + Battle Hymn instead; the slate already
  flagged it thinnest).

**Verdict points (Bill):** ① which spells enter the pool (lean **Sforzando + Rondo**; Count-In if
you want the team texture; Pickup only if SWIFT stays) · ② interaction model = **DOORS**? ·
③ set bonuses: none / **resonance (lean)** / resonance + duo · ④ SWIFT: **governor + Double Time
v2 (lean)** or swap → EDGE / PUNISH · ⑤ the kick carriers: **Evis standard + Coup premium**?
Catalog rows landed 🟡/💡 this pass (CARD-TRACKING LAW); the BUILD-LEDGER D0 row + pillar-#3 row
are amended in the same commit (LEDGER LAW).

---

## 18. THE FERMATA DECK v6 — the assembly (v5 built + two kits) 🔨/🟡 (2026-07-10, Phase-2 D8 — the deck queue's LAST row)

**What this is** (SLATE-PLAN row D8). The v5 deck is BUILT (`f5d5397` — the v5 brief is the
truth) and the §16 slate named its ladders + pitched two additive themes. The v6 "revision" is
therefore an ASSEMBLY: **①** the v5 pool → CARD-CATALOG at 🔨 with §16.1 ladder tags
(Brinkman · Rested Blade · Window-Setter), **②** the two theme kits formalized at 🟡, **③** the
reconciles. **One rename from the distinctness table:** the Cold Hand's entry creed "The
Ledger" → **KEPT BOOKS** (the Duelist's Scarlet kit owns *Red Ledger* — creed-name family kept
apart). Recorded, not new: the Reckoning-Stroke/Estocada freeze-beat rhyme is already at your
board from D2.

### 18.1 The assembly record

- **v5 pool → 🔨 `f5d5397`, ladder-tagged:** creeds the Long Ramp [Brinkman entry] · the
  Fleeting Shade [generic/snap-net] · the Long Night [Brinkman-adjacent] · Tutti [wild] —
  modules ⭐Shadow Dance (no-snap fever) · the Mark [Cold-Hand-adjacent] — boons stretto +
  refrain [Window-Setter] · coldCut [Cold Hand anchor] · theBrink + killingWhisper + quietFuse
  [Brinkman] · firstNote + composure + restlessDark [Rested Blade] · vanish [the block card] ·
  twinEcho + firstBlood [Afterimage anchors / generic] · ✦veilWarband [support] — rig rested ·
  razor · unravel — keystones unseenBlade [Rested Blade] · eclipse [Window-Setter] · phantom
  [Afterimage anchor].
- **KIT A — THE AFTERIMAGE (🟡):** creed *The Doubled Dark* — Twin Echo's effect at half
  strength as the run-start baseline · *Deep Shadow* [POWER] — echoes inherit depth (Bull
  echoes at 45%) · *Procession* [GREED] — consecutive Perfect+ releases add +1 echo to the
  NEXT release (cap 3); any snap/unravel clears · keystone **THE COMPANY OF KNIVES** — a full-
  procession Bullseye brings every banked echo as a visible blade-flight, each graded a half-
  step softer. *(Procession vs Tempo's Through-Line: same trigger family, different payoff —
  echo-count vs +%/stack; recorded.)*
- **KIT C — THE COLD HAND (🟡):** creed **Kept Books** [renamed] — Good-band releases +1 CP
  from run start · *Patient Books* [STRAT] — Evis at 5 CP consumes the Mark at +1 tier ·
  *No Flourishes* [GREED] — while your Brink is 0 (never built), Evis +25% · keystone **THE
  RECKONING STROKE** — a tier-III-brand, 5-CP Evis inside an Opening: one still frame, then
  the number.
- **Keystone pool math:** built 3 (unseenBlade/eclipse/phantom) + 2 kit = 5 → the cap-5
  theme-weighted offer rule (now proposed on four decks — accept once, it's the pattern).
- **EASE knobs (Fermata):** window entry-pad (the widener law's safe side) · snap-lock grace ·
  unravel-stagger grace · ghost... no — drift is Draw's; the fourth knob = min-coil comfort.

### 18.2 Gates + skeptics (delta-scope)

**Dream drafts:** *BRINKMAN:* Long Ramp → (Shadow Dance) → theBrink + killingWhisper +
quietFuse → razor WHENs — deep lips, the Brink meter climbing, no-snap fever for the greed
window ✓ · *COLD HAND:* Kept Books → the Mark → coldCut + Patient Books + No Flourishes →
THE RECKONING STROKE (shallow book, branded cash — the Brinkman read backwards) ✓ ·
*AFTERIMAGE:* The Doubled Dark → ⭐Shadow Dance → Deep Shadow + Procession + twinEcho →
THE COMPANY OF KNIVES (one draw, a procession of shadows) ✓.
**Trios:** (No Flourishes | theBrink | Procession) — three greeds on three meters, and No
Flourishes literally REFUSES theBrink (the polarity is draft-visible) ✓ · (Deep Shadow |
Patient Books | stretto) three STRAT/POWER builds ✓.
**Skeptics:** the Kept-Books rename (Red-Ledger family) · Procession/Through-Line family
recorded · No-Flourishes' Brink-0 gate re-checked (chosen commitment, not luck — you never
build the meter, so the bonus is authored) ✓ · nothing prices snapping (the §16 law holds
through both kits) ✓ · zero new buttons, zero pardons added (vanish stays the one block) ✓.
**AI:** echo-procession = streak counter · Cold Hand = CP/brand thresholds — both on existing
policy surfaces (the v5 policy already coils/releases at tiered timing).

### 18.3 Tension points (Bill)

1. Kit picks (§16 ranking: Cold Hand · Afterimage; 0–2 enter).
2. **Kept Books rename** (veto restores "The Ledger").
3. The cap-5 theme-weighted keystone rule — the fourth and last deck proposing it.
4. The freeze-beat rhyme (D2's open point — if you re-skin one, the Reckoning Stroke is the
   younger card).

**Next:** your verdicts → catalog flips → the v6 build is a light slice on the built v5 kit
(kits are boon-local + one creed each; the Company of Knives is the one render moment).

---

**⚡ THE DECK MACHINE DRAINS HERE** — all 9 deck rows 🟡/✅-ready at Bill's board. Both
SLATE-PLAN queues are complete; the machine's crons are retired.
