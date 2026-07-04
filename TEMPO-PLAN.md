# TEMPO-PLAN — the Tempo Rogue redesign + the Creed / Module / Level framework

**Status:** DESIGN (2026-07-04). Nothing built yet except **The Opening** (merged, `4f071bd`).
**Scope:** this reworks the **Twinfang · Tempo** aspect into a risk/reward "greed dial," AND introduces a
class-framework (Creeds · Modules · WHEN/THEN clarity · per-class levels) that is meant to **generalize to
every class** later — Tempo is the pilot. Companion docs: `PROGRESSION-PLAN.md` (meta), `GEAR-CATALOG.md`
(curios). Design artifacts: **Tempo redesign** https://claude.ai/code/artifact/2cd281f6-552b-4746-9512-44925d369254
· **Boon clarity (WHEN/THEN)** https://claude.ai/code/artifact/802aad53-6017-4455-b4e3-145cbc2930f8
· **System codex** https://claude.ai/code/artifact/d89a2854-0101-4db5-ac60-5f73f7351bb1

Legend: **🔒 LOCKED** (decided with Bill) · **🟡 OPEN** (Bill tuning / to lock before build) · **🔮 FUTURE** (parked).

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
| **The Drumline** | Steady (default) | **−2 Flow**, nothing else — stumble, keep dancing | baseline Flow value; the forgiving learner Creed |
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

**The menu 🟡**
| Module | Role | What it adds | Status |
|---|---|---|---|
| **The Opening** | offense timing | boss swing overextends → punish window for dumps (×1.9) | ✅ BUILT |
| **The Edge** | greed dial | **Commit** (hold/tap): window shrinks to Perfect-only, hits deal more + build Flow faster; a heat gauge shows the push. *(the "narrow the perfect for more dmg" lever)* | design |
| **The Deathmark** | combo layer | Perfects stamp a Mark; a full mark → next dump **detonates** for a burst | design |
| **The Metronome** | 2nd rhythm | an external steady beat; Strikes landed ON it bonus — polyrhythm (highest skill) | design |
| **The Hemorrhage** | sustain | Perfects open a stacking bleed; a dump reopens it for a spike | design |

**v1 recommendation:** Opening (built) + **Edge + Deathmark** (Deathmark = the "cool trigger" Bill wanted;
Edge = the greed dial). Metronome / Hemorrhage later.

**🟡 open:** is **The Edge** a Module (equip the greed) or baked into base Tempo for everyone? Leaning **Module**
(keeps base Tempo clean; the greedy narrow-window play is a run choice).

---

## 5. WHEN / THEN / ALWAYS — the boon system, made legible 🔒 (rules) / 🟡 (content, Bill tuning)

### 5a. The rename 🔒
Retire the jargon. Trigger → **WHEN** · Payload → **THEN** · Property → **ALWAYS**. The whole build reads as one
sentence: *"**WHEN** a Riff or a Peak → **THEN** mark the boss and quicken; **ALWAYS** a wider window."*

### 5b. The board 🔒
A visual panel (draft-screen live preview + a compact HUD strip + the Spellbook): every **WHEN** on the left,
every **THEN** on the right, arrows showing the crux the old tooltip hid — **any single WHEN fires the entire
THEN stack.** The HUD node **pulses + floats its number** each time a moment fires (you *see* your build work).

### 5c. The menus (illustrative — Bill is fine-tuning these) 🟡
**WHEN (earned moments — no auto-attack):** Riff (3 Perfects) · Peak (reach max Flow) · Bullseye (dead-center
strike, tighter than Perfect) · Punish (a dump lands in the Opening) · Detonate (pop a Deathmark / execute a low
boss) · Full Finisher · Clean Dodge.
**THEN (effects with identity — show on the boss or feed the tempo):** Mark +1 · Echo (delayed phantom hit) ·
Quicken (tighten window / +tempo 3s) · Expose (boss takes +% one beat) · Rend (open/refresh a bleed) · Surge
(+1 Flow). *Retire heal / energy trickle to a rare utility slot.*
**ALWAYS (reshape a rule):** Wider window · Second dodge charge · (transform-tier pieces).

### 5d. Tutorial 🔒
No wall of text — **build it in front of the player**: draft 1 hands a matched WHEN+THEN and lets it fire; the
next draft adds a WHEN and the arrows converge ("oh, my dodge fires it too"); a one-line coach mark names the
shape. Done.

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

**Run-flow timeline** (Tempo example):
| When | Choice |
|---|---|
| between runs | level up → **unlock more Creeds/Modules** into your pools |
| run start | draft **1 of 3 random Creeds** + your Aspect |
| every won fight | 1-of-3 boon draft *(exists)* |
| some event nodes | **re-draft your Creed** for a penalty |
| **end of Floor 1** | pick **1 Module** |
| Floors 2–3 | keep drafting boons; Creed + Module ride with you |

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

## 10. OPEN decisions to lock before/at build 🟡

1. **Rarity Model A vs B** (recommend A).
2. **Which Creeds ship v1** (recommend Flourish + Drumline).
3. **Which Modules ship v1** (recommend Opening + Edge + Deathmark).
4. **The Edge — Module or baked-in?** (leaning Module).
5. **Creed/Module rarity flavor?** (a wild legendary Creed, or all flavor-equal?).
6. **The WHEN/THEN menu + numbers** — Bill is fine-tuning triggers/effects; lock the shipping set.
7. **Level unlock ladder** — what event unlocks what, and the starter pool.

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
