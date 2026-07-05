# TEMPO-PLAN — the Tempo Rogue redesign + the Creed / Module / Level framework

**Status:** DESIGN + BUILD IN FLIGHT (2026-07-04). **The Opening** merged (`4f071bd`); the **risk-core slice**
(combo-fix + Flow-dial + Creeds/Modules scaffold) is building on branch `tempo-pilot`. The audit-iteration
decisions (see the ✅ block below) are folded into this doc — reconcile them into the build when that slice merges.
**Scope:** this reworks the **Twinfang · Tempo** aspect into a risk/reward "greed dial," AND introduces a
class-framework (Creeds · Modules · WHEN/THEN clarity · per-class levels) that is meant to **generalize to
every class** later — Tempo is the pilot. Companion docs: `PROGRESSION-PLAN.md` (meta), `GEAR-CATALOG.md`
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
- **⚠ BRANCH RECONCILIATION:** two parallel Tempo branches must merge — `tempo-pilot` (my Creed/Module/
  core + the verb_board GUI) and `tempo-boons` (the agent's graded window + address-organized card slate,
  UNCOMMITTED in `../wow-tempo-boons`). Note: the new card slate **removed the WHEN/THEN draft buckets**
  (they became the single §5 combo-rig), so the **verb_board GUI reads now-empty buckets** — it must be
  re-pointed at the rig, and the rig system itself confirmed/built.

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
3. ~~Which Modules ship v1~~ → **Opening + Edge + Deathmark**.
4. **The Edge — Module or baked-in?** (still leaning Module — open).
5. **Creed/Module rarity flavor?** (open — a wild legendary Creed, or all flavor-equal?).
6. ~~The WHEN/THEN menu~~ → **redefined to the single Combo rig** (§5); offense-only WHENs, no +Flow THEN. Exact
   per-WHEN numbers still to sim.
7. **Level unlock ladder** — what event unlocks what, and the starter pool (open).
8. **Graded-window numbers** (§2c) — Bullseye / Perfect / Good widths at base + max Flow, to sim.
9. **Dancer's Grace's effect** (auto-Perfect next Strike) — cut as a *dodge* boon; re-home it on an offensive
   trigger (a Peak, or an Opus) or drop entirely? (parked — the effect is good, only its dodge trigger was cut.)

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
