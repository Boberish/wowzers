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

## 13. THE SECOND SPEC — Twinfang's other half 🟡 (opened by the split, 2026-07-06 — DESIGN OWED)

The Brew left to become its own class (audit F10 → `ALCHEMIST-PLAN.md`), so Twinfang owes a second
Aspect. **Bill's steer:** redo the poison/DoT slot *"with something that goes more RHYTHM based — not a
copy of Tempo, but a variation — not a whole new thing"* (like the Brew was).
- Same timing-family chassis as Tempo — the class keeps its complexity-budget spot: **deep minigame,
  3-button kit** (CLASS DESIGN RULE #2). A VARIATION on the beat (different groove, different reward
  shape), not a second foreign minigame bolted onto the class.
- The **in-code poison-wheel Venom stays the FROZEN placeholder aspect** (playable in the raid) until
  this is designed + built — same idiom as the frozen roster classes.
- **Sequencing:** design AFTER the Tempo pilot's audit fixes land — don't design spec 2 against a moving
  spec 1. Framework chassis applies in full (Creed slot · 1 Module · the rig · a support boon ·
  AI-pilotable at 3 tiers).
- Name/fantasy: open — filler-grade until the design pass (poison/DoT flavor optional, not required).

---

## APPENDIX A — THE TEMPO CARD LEDGER (v2 · Bill's ledger verdicts 2026-07-06 folded)

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
**STRIKE** *(crit cards moved to the A7 opt-in package — lane needs 1-2 non-crit bread cards, design owed)*
- Through-Line `throughline` [NEW, design] — consecutive Perfects escalate +2%/stack, cap 5, reset on Miss · ladder +2%c5/+3%c5/+3%c8
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
Through-Line. Open DESIGN: I7 Swan-Song/auto-dodge · §13 second spec · STRIKE lane bread.

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
