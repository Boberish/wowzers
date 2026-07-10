# MENDER-PLAN — the direct-cast healer onto Framework v2 (the Well · twin graded specs BRIM / DRAW)

> **2026-07-10:** BOTH branch slates are 🟡 AT VERDICT — **BRIM §9** (Low Catch · Overflow
> Engine · Glintsmith · the Pulse) and **DRAW §10** (the Rapids · the Vigil · the Skim · the
> Eddy), plus the **§10.7 built-pool addendum** filing all 24 built boons (Millrace-vs-Flume
> reconcile flagged for the deck passes).

**Status:** 🟢 **BASE BUILT & MERGED 2026-07-07** (branch `mender-rework` → main). The reworked
healer ships as a guarded class **`well`** (codename — Bill's name pick open) on the healer seat,
Alchemist idiom: byte-identical unless picked. Both specs playable — **`--autostart=raid:healer:brim`**
(TARGET · grade the landing) / **`raid:healer:draw`** (SPEED · grade the release, ride THE CURRENT).
Built: CHARGES economy · pure-cast book (flash/mend/cascade/wellspring/dispel/rekindle) · BRIM
pour/spill grade + landing preview · DRAW clean/still/undercook + THE CURRENT · the personal GLINT ·
the WellGauge HUD (charge vessel · Current pips · release band + Still Point · verdict rail) · per-ally
✦ Glint chip · `well_sim` + `raid_sim --healer=well` + net carry. **Gates:** determinism PASS both
specs · default comp byte-identical to main across all 4 Seals (6880/8987/8338/4838) · well plays+wins
the Seals · ui_smoke_raid ALL OK · WSLg shots verified. **DECK: ✅ BUILT 2026-07-07 (see the DECK
banner below).** Files: `godot/data/well/*` · `godot/sim/policies/well_policy.gd` ·
`godot/sim/well_sim.gd` · `godot/game/ui/well_gauge.gd` · `godot/game/well_binds.gd` ·
raid_hud/raid_frame/raid_content/raid_net/raid_sim wiring.

**⚡ THE DECK BUILT & VERIFIED 2026-07-07** (branch `well-deck` → main). The owed deck (§2–§5) is
CODED + wired into the framework ceremony/draft/run — ALL guarded (empty creed + no modules + no
boons + no rig ⇒ byte-identical base, proven). **CREEDS** (per-spec pools, `well_creeds.gd`):
_Brim_ = The Brink (heals scale on the bloodied + the pour band drops LOW — the flagship greed) ·
Foresight (pours bank stacks while the party is topped; a dip crashes them) · The Levee (low band +
a pour leaves an absorb, but a weaker Glint — the learner) · The Shallows (tight/high band, but a
brighter Glint — glass). _Draw_ = The Patient Hand (an overrun becomes a HELD heal, released on the
spike) · The Long Draw (slow/big/tight — the Largo mirror) · The Narrows (a release OUTSIDE the band
heals ZERO, in-band much stronger) · The Eddy (the band's centre drifts each cast — deterministic
from the cast's start tick, no RNG). **MODULES** (Floor-1 pick 1-of-3, all AUTO-FIRE, `well_modules.gd`):
⭐ **The Reservoir** (SPILL banks → SURGE a burst heal at full + re-bank a share — the Tidecaller
flywheel, re-homed) · **Triage Protocol** (bloodied allies build NERVE → auto LAST STAND: party heal
+ a raid-wide DR window) · **Benediction** (good grades light PIPS → the 5th cashes a party BLOOM).
**BOONS** (24, fixed rarities + `ctype` card-type tags per [[card-type-tags]], `well_boons.gd`):
_SHARED_ = Deep Well · Steady Pulse · **Meditate** (the drafted battery spell) · **The Kept Light**
(Glint lasts longer + extends) · **Brink Bell** (emergency absorb when an ally drops low) · ✦ **The
Shining Hour** (the TEAM aura — warband +dmg while everyone is topped; the ONE engine touch, guarded
exactly like the Glint) · **Boiling Over** (the clutch damage-dump spell) · Warm Rekindle. _BRIM_ =
Wide Brim · Second Ring · Overflowing Cup · Still Water · Low Catch · Cadence of Mend · The Blindfold ·
**High Tide** (keystone — a pour glints the WHOLE party while topped). _DRAW_ = Loose Grip · Short Pour ·
Cool Hand · Double Draw · Deep Still · Last Drops · **Strong Pull** (max-Current clean heals +30%) ·
**The Millrace** (keystone — every 3rd cast free at full Current). **RIG** (`well_rig.gd`): per-spec
WHENs (_Brim_: Sweet Pour / Spillover / Low Catch · _Draw_: Clean Draw / High Water / Still Point) →
shared THENs (Mend / Ward / Bloom / Draught / Gleam), greed-dial magnitudes shown before you commit.
**Framework wiring:** `_fw()` + all `_fw_*` dispatch (per-spec creed & rig offers by `_aspect`),
`_inject_boons`, the build-panel rig line + REFORGE pools, `Draft.catalog` + `SIG_KEY`, and
`RunState.start_well` all handle `"well"`. **Gates (all green):** determinism PASS **base AND a
fully-loaded deck** (both specs) · **default comp byte-identical — 4-Seal checksums UNCHANGED
(6880/8987/8338/4838)** · well plays+wins the Seals · `well_sim --load` reads the deck bands (the
deck lifts survival AND shows a real skill gradient — draw maw 72/57/15 expert/good/sloppy) ·
ui_smoke_raid ALL OK **+ a new WELL-framework ceremony assertion** · draft_sim ALL OK.
**OWED (follow-ups, not blockers):** the module-gauge METERS on the WellGauge (reserve/nerve/bene/
foresight fill — the fire-moment event flashes ship now; the anticipation meters need a WSLg pass) ·
AI-policy use of the two drafted spells (Meditate / Boiling Over — passives + modules are AI-piloted
today) · **balance playtest (Bill's lever)** · class NAME lock · online creed/module/rig carry
(the shared Twinfang debt).
**⚡ CONTROLS + SHARED HEALER UI (Bill's feel pass, 2026-07-07):** healers share ONE base healing
UI — hover-a-frame click-cast chords (WellBinds: L flash · R mend · Mid cascade · Sh+L spring ·
Sh+R dispel), the **shared CastChannel** (now carries an optional graded release window + idle
track + tap-to-release — Bloom/Mender rendering unchanged, and their reworks reuse it), the ally
frames carry the class read overlays (Brim's gilded pour band on EVERY frame, always visible), and
the WellGauge got **THE TARGET BAR** — the hovered/cast ally writ large with the window + the
in-flight heal's ghost landing. **DRAW casts both ways:** tap/click starts → tap/click again
releases, OR hold past ~250ms and release on key-up.
**⚡ AAA UI SWEEP (Bill's feel pass #3, 2026-07-07, `f356bad`):** "base seems much better" → big/clear/
fancy pass, pure view code. **CastChannel scales with control height** (s = size.y/60 — Mender/Bloom
60-tall placements stay pixel-identical; the Well places it 660×116, everything doubles): the DRAW
release window rebuilt — steel CLEAN zone w/ breathing shimmer + entry-gate brackets, gold Still-Point
sliver crowned by a diamond gem, engraved RELEASE WINDOW caption, a **playhead needle** at the fill
edge (white on approach → gold inside the window) + in-zone RELEASE ▸ flare. **WellGauge rewritten:**
the charge blocks are now glass **WATER ORBS** (wavy waterline, rising bubbles, gilded rims, eased
fill/drain so pours visibly drain water, newest-orb glow, DRY crimson pulse); Current pips carry a
travelling light (the current flows); **THE TARGET BAR is a jeweled glass health bar** (glass_bar_draw
+ HP numerals in Cinzel, recent-damage trail, brighter ghost landing + landing hairline/marker, POUR
entry gate + crowning gem + plaque, breathing glint aura); the verdict banner lands centre-stage on a
dark chip, history rail = fading diamonds. Palette gains WATER / WATER_DEEP. Verified: ui_smoke_raid
ALL OK · WSLg shots both specs clean.
**⚡ AAA PASS #2 — MATERIAL RENDERING (Bill's feel pass #4, 2026-07-07, `9eeaa41`):** Bill: "better but
far from AAA — basic line borders, squares, no different colors, the text flashing up is covering the
mana, the bubbles look childish." Answer = rebuild the RENDERING, not the layout. **UiKit gains the
material toolkit** (shared, additive): `glow_tex()`/`glow()` — a cached radial-falloff texture tinted
per draw = bloom-like light inside `_draw` with no shaders — and `grad_rect`/`grad_rect_h` per-vertex
gradient fills. **The gauge is ONE reliquary console:** glass slab (drop shadow, filigree corners,
water-blue crown glow, engraved header divider) holding a recessed POOL (deep-water gradient, drifting
surface light) — the orbs are **lit liquid spheres set into metal sockets** (layered depth toward the
virtual light, refraction rim-light, soft+hard specular, one drifting light-mote; the cartoon bubble
rings are GONE), the Current is a chevron stream the light visibly flows through, the target bar is a
hero bar (gradient fill, glowing leading edge, bevel + diamond finials). **The CastChannel sits on a
glass pill** (no bare floating rect), gradient fill + glowing leading edge, zone glass glows when hot;
**DRAW's channel wears Palette.WATER** — spec color identity (BRIM gold / DRAW water). **The verdict
banner rises ABOVE the whole channel** (glow + pop-in chip) — it can never cover the charges or the
live window again. Verified: ui_smoke_raid ALL OK · WSLg both specs, zero draw errors.
**Scope:** rebuilds the **Mender** — the healer seat's direct-cast class — onto Creeds / Modules /
WHEN-THEN. The Bloomweaver is NOT part of this (its framework re-clothing is its own later pass);
the **damage-healer is a 3rd healer-seat class, future**, with its own two specs.
**Artifacts:** design board https://claude.ai/code/artifact/68b0c28c-cc3a-4655-b9d5-fdc67e929e24 ·
**live verb tester** https://claude.ai/code/artifact/80b2169b-3f38-488e-a31c-d9b49a718b25
(BRIM ⇄ DRAW A/B + ⚙ knobs; source `brim-tester.html`, session scratchpad) ·
**⭐ VERDICT BOARD (2026-07-07, out with Bill):** https://claude.ai/code/artifact/958cdbe8-7c92-48cb-bf95-eae69b3994c1
— the FULL idea slate as rateable cards (BRIM tab 25 · DRAW tab 25 · CLASS tab 9: verb base rules,
4 creeds + 3 modules + 10 boons + 4 rig WHENs + 1 keystone per spec, shared Well/support/comp-texture/
names), 1–5 stars + comments, in-browser saves, EXPORT → paste-back. §2–§4 sketches below are
superseded by that slate wherever they differ; Bill's export = the card verdicts of record.
Companions: `TEMPO-PLAN.md` (framework + Fermata precedent) · `ALCHEMIST-PLAN.md` (build idiom) ·
MASTER-PLAN §CLASS FRAMEWORK v2 (the 7 design rules).

Legend: **🔒 LOCKED** (decided with Bill) · **🟡 OPEN** (settle before/at build) · **🔮 FUTURE** (parked).

---

## ⚖ THE BOARD VERDICTS — Bill's full export, 2026-07-07 (66/66 rated; the record — §§ below are patched to match)

**LOCKED CORE (5★):** Clean Draw + THE CURRENT · THE BRINK (flagship Brim creed) · the shared BOOK
concept · CHARGES as the resource name ("for now") · HIGH TIDE keystone · STRONG PULL · THE KEPT
LIGHT · BRINK BELL · THE SHINING HOUR (class support boon).

**~~THE CRIT MODEL~~ → ⚡ SUPERSEDED same day — THE GLINT (Bill: "i don't like the crit, it kills
the planning for the brim — tear that out completely; not mana, not healing, already using it for
the cascade").** Precision mana-refunds stay DEAD, and now crit/bigger-heals are dead too; the
CD/big-button lane is taken (Cool Hand / Plumb Line feed Cascade). **The perfect reward points
OUTWARD: ✧ THE GLINT — PERSONAL (Bill: "just for the person we are healing, not everyone"):** a
perfect (Brim pour · Draw Still Point) makes **the healed ally's** weapon catch the Well's light:
**that ally +~40% damage for ~4s** (refresh, not stack; a Still-Point Cascade glints all three it
healed). Non-mana, non-heal, non-CD — and it pays the economy *indirectly*: harder hits → shorter
fight → fewer charges spent. Being personal puts the Glint INSIDE the triage game: WHO you bless
matters (a glinted striker ≈ 3× a glinted tank, but the striker has to need the heal) — perfect
target-selection texture for Brim. Draw's plain clean = +Current only; Still Point = Current +
Glint; Millrace = the only literal economy valve. The SHINING HOUR boon (5★) becomes the Glint's
amplifier lane. Runner-up on file: THE GILD (perfect braces the target — next boss hit −25%, one
charge). 🟡 numbers (+%/duration/threat) at ⚙; 🟡 the 3-tier Good/Perfect/Bullseye ladder (D-B2
note) still open.

**BOOK REWORK (C-6, C-9, C-7):** identity = **ALL heals are casted direct heals** — **Ward CUT ·
Renew CUT · Meditate CUT from base → a draftable battery BOON** ("you need to manage mana"; the
Well refills by pulse alone). Drafted shields/HoTs stay legal (Brink Bell 5★, Still Water/Afterflow
4★ — the cut is base-book-only). **REKINDLE: no cooldown, long cast, big cost** — "if they die and
you have the time and mana, go for it." Base book: Flash · Mend · Cascade · Wellspring · Dispel ·
Rekindle.

**COMP TEXTURE:** healer carries **NO KICK** (Rebuke 1★) — the 0 of the 2/1/0 distribution.

**ACCEPTS (4★, tuned where noted):** Perfect Pour/Spill/base rules · Foresight · Long Draw ·
Patient Hand ("cool bank") · Benediction · Plumb Line · Siphon · Triage Protocol · Wide Brim ·
Second Ring · Overflowing Cup · Cool Hand · Low Catch · Cadence of Mend · Loose Grip · Short Pour ·
Bucket Brigade · Last Drops · Still Water · Afterflow · Crest · Boiling Over ("a good healer can
pick this if it's too easy") · Still Point (reward → crit) · pour/catch/spill/clean-draw WHENs ·
Millrace. **Landing preview = BASE + a "blindfold" boon** (remove the preview, bigger rewards —
B-V3). **BRIMFUL: yes, but only on the big cooldown buttons** (Cascade/Wellspring tier), never the
bread casts (B-V4). **Double Draw tuned:** chain-cast bonus ~25–30%, "half is too much."

**CUTS:** Deep Refund ("mana back? lame") · Runoff · Steady Arm · Edge of the Lip (fights the
Still Point) + its edge WHEN · held-heal WHEN · Rebuke/kick · Slow Water (2★ — parked as a
maybe-creed/module concept, "would need to be thought out more").

**REWORKS OWED:**
- **QUICK PULL → THE NARROWS** (Bill's spec): band smaller, a release OUTSIDE the band heals
  ZERO, in-band heals much stronger. All-or-nothing precision creed.
- **DEAD RECKONING → THE EDDY** (Bill's spec): don't hide the bar ("abusable once you get the
  timing") — MOVE the band: its position drifts cast-to-cast (mid-bar, small jitter); you tag it
  as it passes and the heal still resolves at cast end. Fresh timing every cast.
- **⭐ RESERVOIR (3★ + the Ward cut guts its shield output):** rework pass owed — spill banks →
  Surge as a burst HEAL, or park; Levee/Shallows (3★) tune with the creed pass.
- **Undercook (3★):** reframed per Bill as the deliberate quick-sip tool ("super fast heal, way
  less effective") — Short Pour 4★ is its boon lane. **Overrun (3★):** stays free — "you have so
  much to gain by doing it" that enforcement isn't needed.

**NAMES:** spec dev-labels **TARGET** (=Brim) and **SPEED** (=Draw) — "so i know the play
difference, figure out later." Resource = **CHARGES**. Class name still open (2★ on the card).

---

## 0. The diagnosis + the fork (locked 2026-07-06)

- Bill's read, confirmed by code: **heal-low and overheal are boons, not specs.** The two aspects
  differ by ONE inverted Litany condition (`mender_kit.gd:167` — pip when a heal *leaves* the target
  ≥60% vs when it *caught* them ≤40%); everything else is payoff plumbing (Reservoir flywheel /
  brink ×2.5 scaling + Nerve). They demote into the framework (§2, §3).
- **NO MERGE with the Bloomweaver** (Split law F10): cast-bar triage and seed-gardening are
  different games; framework decks are per-spec so a merge saves nothing; the healer seat toggle
  already offers both classes.

## 1. THE CLASS 🔒

**Complexity budget (rule 2, stated):** the Mender sits at the **kit-breadth end** — the ~10-spell
click-cast book IS the class, the per-press minigame stays light, and the depth is triage choice
under pressure. One book, one Well, two specs = **the same grade in two places**.

- **THE WELL (base, both specs):** mana is a visible vessel — casts draw from it, it refills in
  **pulses** (never a flat trickle), overheal **SPILLS** (wasted; banking spill is module
  territory), Meditate is the battery decision, and DRY is a visible state. The Well is the class
  instrument on THE HUD. **🔒 DISCRETE, named CHARGES (board C-10, 5★ "charges for now"):**
  the Well holds **~12 CHARGES**: Mend 1 ◍ · Flash 2 ◍ · Cascade 3 ◍; the pulse drops in 1 ◍ and
  is the ONLY base refill (Meditate cut → a draftable battery boon; precision refunds dead per the
  crit model). There is NO separate mana — the Well IS the mana, quantized. Boon ladders speak in
  charges ("every 3rd pour returns 2").
- **SPEC 1 · BRIM (dev-label TARGET) — grade the LANDING.** Casts stay completely normal; every
  direct heal is graded by where the target's HP lands. In the brim band (default ≥90%) with zero
  spill = **PERFECT POUR** — fires **✧ THE GLINT on the healed ally** (+damage ~4s; the class proc
  moment) · overshoot = **SPILL** (counted waste) · land low = safe, unpaid. The graded window lives on the **ally's bar**; the skill is sizing Flash vs
  Mend vs Cascade against incoming damage. **Landing preview = BASE** (🔒 B-V3) + a blindfold boon
  (preview off, bigger rewards). **BRIMFUL** (dead-full landing tier) = big CD buttons only (B-V4).
- **SPEC 2 · DRAW (dev-label SPEED) — grade the RELEASE, ride THE CURRENT.** Casts complete
  **manually**: release inside the end band = **CLEAN DRAW** (full heal, **+Current**) · early =
  **UNDERCOOKED** (heal × p^1.5 — the deliberate quick-sip, per Bill) ·
  overrun = auto-completes plain (stays free — "so much to gain by releasing"). **THE CURRENT**
  (max 5): each stack casts **+6% faster**. An undercook BREAKS it; running the Well **DRY**
  breaks it; it ebbs after ~4s idle. Faster casting burns charges faster with no refund valve, so
  the rush throttles itself. **Payoff split of record: clean rhythm pays INWARD (the Current);
  precision tops pay OUTWARD (✧ the Glint) on both specs.** Shield / HoT / stronger-heal payoffs
  live in the boon slate (STILL WATER / AFTERFLOW / THE CREST, board D-B11–13).
  **🔒 THE STILL POINT (the min-max tier):** a hairline sliver dead-centre of the band (~4% of the
  bar, ≈100ms); tagging it = clean draw AND **✧ a Glint** (strict superset, F15 Bullseye law — the
  dram-back and crit rewards both died on Bill's verdicts). Self-balancing: the Current speeds the
  bar, so the Still Point hardens as you ride higher.
  The window lives on **your cast bar**; attention inverts — Brim reads the party, Draw reads your
  own hands. The Tempo/Fermata symmetry on the healing side.
- **Shared by both specs:** the book — **Flash / Mend / Cascade / Wellspring / Dispel / Rekindle**
  (🔒 C-6: ALL heals are casted direct heals — Ward, Renew, Meditate cut from base; Rekindle =
  no-CD long-cast big-cost), the Well, the GCD, and **cast-vs-dodge discipline** (a dodge cancels
  the cast; the healer's dodge-ration beats stay its test).
- **VIGIL (the hold) folds into DRAW build territory** 🔮 — a creed/module turns the overrun into a
  HELD state you walk around with and release on the spike. (Was the recommended spec 2; superseded
  by Bill's tester verdict. The good idea survives as Draw's transformer candidate.)

## 2. CREEDS 🟡 (per-spec pools — Tempo/Fermata precedent)

**Brim pool (⚖ verdicted 2026-07-07):**
- **THE BRINK** 🔒 5★ flagship — play BEHIND: heals scale on the bloodied (the ×2.5-at-0 machinery
  exists), the band moves DOWN (perfect = the low catch), overtopping is the slip.
- **FORESIGHT** 🔒 4★ — play AHEAD: pours build stacks while nobody sits below 50%; a dip crashes
  them.
- **THE LEVEE / THE SHALLOWS** 🟡 both 3★ — keep the slots, tune with the creed pass (Levee's
  double-refund hook is dead with the crit model — rework its payoff).

**Draw pool (⚖ verdicted 2026-07-07):**
- **THE PATIENT HAND** 🔒 4★ "cool bank" — the overrun becomes a HELD heal in your hands (~3s,
  instant release on the spike; gutters after — charge + cast wasted). Held releases don't feed
  the Current.
- **THE LONG DRAW** 🔒 4★ — the Largo mirror: casts ×1.3 slower, heals ×1.35, band ×0.75.
- **THE NARROWS** 🟡 (reworked from Quick Pull 2★, Bill's spec) — band smaller, a release OUTSIDE
  the band heals ZERO, in-band heals much stronger. All-or-nothing.
- **THE EDDY** 🟡 (reworked from Dead Reckoning 3★, Bill's spec) — the band's position DRIFTS
  cast-to-cast (mid-bar, small jitter); tag it as it passes, the heal still resolves at cast end.
  Fresh timing every cast — reading beats rhythm-memory.

## 3. MODULES 🟡 (Floor-1 pick 1-of-3 · one ⭐ transformer · all three re-homed coded machinery)

- ⭐ **THE RESERVOIR** (transformer; was Tidecaller's engine) — spill banks into a second chamber on
  the Well; **SURGE** spends it as shields; shields re-bank a share of what they eat (the flywheel
  in `mender_kit.on_absorb`). Overheal stops being waste and becomes a second currency — the
  overheal build, opt-in.
- **TRIAGE PROTOCOL** (was Brinkwarden's other half) — bloodied allies build Nerve → **LAST STAND**
  (party heal + DR spend).
- **BENEDICTION** (was Litany) — in-condition heals light pips; the 5th cashes the party bloom.
- 🟡 module pool shared class-wide vs per-spec WHEN wording (the three are condition-flavored and
  read fine under either spec).

## 4. DECK 🔮 (after the base build proves)

- **WHEN dimensions come free per spec:** Brim keys off landings (WHEN I perfect-pour · WHEN I
  catch ≤40% · WHEN I spill); Draw keys off releases (WHEN I clean-draw · WHEN I undercook · WHEN I
  release a held heal). Rig slots the class THEN table like every other class.
- **Support boon sketch — THE SHINING HOUR:** while every ally stands ≥ ~80%, the warband gains
  damage. Topping the team IS the raid buff; no extra button (Battle-Hymn analog, pointed the other
  way because the healer is already support).
- 🟡 rule-5 clutch tool (one CD-gated damage dump?) · 🟡 interrupt carrier (the healer is the 1 or
  the 0 of the 2/1/0 comp texture).

## 5. Framework-law compliance (MASTER-PLAN ⚖ rules)

1 chassis ✓ (ClassKit hooks + `perform()` + universal dodge + creed/module/rig shape) · 2 budget
stated ✓ (§1) · 3 AI-pilotable ✓ — Brim tiers = sizing error, Draw tiers = release-timing jitter
(tick-stamped release action; Fermata is adding press/release plumbing to `perform()` anyway) ·
4 skill moves outcomes — tester separates hands on efficiency/pours; sim bands must reproduce it ·
5 role hard, off-role = clutch-capped · 6 fun bare — the book + one grade must carry a boonless
zone skirmish · 7 n/a.

## 6. ⚙ TESTER BASELINE (the numbers Bill played — his slider drags supersede)

brim band 90% · pour refund 25% · Well 900, pulse +18 / 2.0s · draw band 15% (undercook = ×p^1.5) ·
book: flash 33☽/1.5s/70 · mend 24☽/2.6s/95 · renew 27☽/HoT 72 · cascade 58☽/2.0s/45×3-lowest/8s cd ·
medit +160/25s (tester-shortened; the kit's is 160/55s) · GCD 1.2s · pressure script: melee
8–14/1.4s · buster 90/12s (2.5s tele) · nova 15–25 all/9s (1.8s tele) · hex dot 8×6 ticks/10s.

## 7. Build order (Alchemist idiom — the OLD Mender stays the frozen default until the verdict swap)

1. **Guarded kit base:** the spec pair rides the aspect slot (`--autostart=raid:healer:brim|draw`,
   the `raid:caster:brew` precedent); old tidecaller/brinkwarden stay the default — **byte-identical
   unless picked**. Draw needs the release action on the input surface (share Fermata's
   press/release idiom + AI policy release-jitter).
2. New healer sim (the rework loop) joins `psim.sh`; `raid_sim --healer` cells; determinism PASS
   both specs.
3. Creeds → 4. Modules (re-homes) → 5. deck + rig WHENs →
6. **HUD instrument:** the Well vessel panel + brim rings on the raid frames + the draw band on the
   player cast bar (StrikeJudge compact keeps the boss side) →
7. Balance at `--fightlen` bands (3–5 min mid / ~10 min late) — **never against today's 60–142s
   fights**; this is where the inert-healer finding finally gets closed.

## 8. OPEN 🟡 (post-verdict remainder — most of the old list resolved by the ⚖ block)

1. **Class name** — MENDER unloved (2★), no candidate yet. Specs ride dev-labels TARGET / SPEED;
   resource = CHARGES. Figure out later, before the HUD pass.
2. **Glint numbers** — +40% on one ally? 4s? refresh-vs-stack? Does a glinted tank gain threat?
   The full Good/Perfect/Bullseye 3-tier ladder ("go full in, like tempo") vs the built 2-tier?
   ⚙ tester + build-time sims (Glint = measurable in raid_sim: kill-time delta per pour).
3. **The Current's numbers** — +6%/stack (max 5)? Undercook full crash vs −2 (creed territory)?
   Idle ebb 4s? ⚙ tester calls.
4. **⭐ Reservoir rework** — 3★ + the Ward cut guts its shields: spill→Surge as burst heal, or
   park and find a new Brim transformer.
5. **The Narrows / the Eddy** — numbers + build (Bill-specced reworks, §2).
6. **Blindfold boon** (preview off, bigger rewards) + **Brimful on the big buttons** — design at
   the boon pass.
7. **Meditate-as-boon** — the battery's shape (charges +N? pulse burst?) in the boon slate.
~~Landing preview~~ → BASE 🔒 · ~~Interrupt~~ → NO KICK 🔒 · ~~Ward/Dry-Ward~~ → Ward CUT 🔒 ·
~~Clutch dump~~ → Boiling Over kept 4★ 🔒 · ~~resource name~~ → CHARGES 🔒.

---

## 9. THE BRIM BRANCH SLATE — four build-theme candidates 🟡 AT VERDICT (2026-07-10)

**What this is** (SLATE-PLAN row 5; branch = build THEME, dials addressed never bent). The Brim's
deck exists in code but is branch-thin — this pass names the ladders the verdicted material
already implies (filing) and pitches the theme layer for the Phase-2 deck pass (row D5). Base
kit untouched (the charges Well · the book · the landing grade · ✧ the Glint); example cards are
ILLUSTRATIONS — no CARD-CATALOG rows. **How it was made:** §§0–8 + the ⚖ board re-read + fresh
sweep `research/brim-sweep.md` (Trauma Center graded-chores · the FFXIV green-DPS warning ·
Ana's no-free-value) → 4 lenses → 4 themes → **3 skeptic passes (1 kill, ~7 fixes folded)**.

### 9.1 The harvest (Brim-sized)

1. **Idle time is the class's known wound** (raid healer idle 93–98%, memory'd) — the best theme
   gives quiet minutes a JOB, not a filler nuke (the FFXIV green-DPS warning): all outward
   damage rides ✧ Glints THROUGH allies, never a healer rotation.
2. **Grading chores is the tension engine** (Trauma Center) — precision themes can chain pours
   into operation-shaped sequences; the blindfold boon already owns the no-free-value pole (Ana).
3. **The spec's own module fights its own grade** — perfect pour = ZERO spill, but ⭐Reservoir
   BANKS spill. That fork (Glint or bank, chosen per cast) isn't a bug; it's the overflow
   build's identity, stated out loud.
4. **The Brink is pre-validated** (Bill's 5★ flagship creed) — the play-behind theme starts from
   the strongest verdict in the class.

### 9.2 THE FILING TABLE (verdicted material → the themes below; zero orphans)

| Existing (state) | Files under |
|---|---|
| THE BRINK creed 🔒5★ | **LOW CATCH** (the entry creed) |
| FORESIGHT creed 🔒4★ | **GLINTSMITH** (play-ahead keeps the party topped) |
| LEVEE / SHALLOWS creeds 🟡 (rework owed) | **THE PULSE** candidates (Levee's dead refund hook → the pulse-refund rework below) |
| ⭐ THE RESERVOIR module | **OVERFLOW ENGINE** (the transformer) |
| TRIAGE PROTOCOL module | **LOW CATCH** |
| BENEDICTION module | generic (any theme's 5th-pip rhythm) |
| ✧ Glint 3-tier ladder (🟡 ledger) | **GLINTSMITH** (the spine) |
| THE SHINING HOUR support sketch | **GLINTSMITH** (the TEAM card) |
| Blindfold boon (B-V3 rider) | **GLINTSMITH** (the greed pole) |
| Battery boon (Meditate remnant) | **THE PULSE** |
| WHEN sketches (perfect-pour · catch ≤40% · spill) | Low Catch / Overflow / Glintsmith respectively |

### 9.3 THEME 1 — THE LOW CATCH · *the save is the point*

**What its cards do:** play-behind, formalized — the Brink's moved-down band becomes a build:
catches (landings into a LOW band) pay escalating value, Nerve/Last Stand machinery feeds it,
catch-WHENs premium. **Skeptic fix folded:** the theme keys off BAND-POSITION catches (the
Brink moves the band down — self-authored lows), not only ally-HP crises, so zone fights don't
put it to sleep.
**Dials addressed:** the landing (band position) · the pour (sizing into small remaining gaps).
**Example cards:** boon *Knife's Edge* (GREED) — the band drops another 10%, catches +25% ·
boon *Steady Under Fire* (STRAT) — a catch during a boss telegraph string also refunds 1 ◍ ·
keystone **THE UNDERTOW** — three consecutive catches with zero spill pull the whole party's
bars up 10% in one visible wave.
**Greed/comfort + EASE knob:** depth-greed (how low the band rides); comfort = Foresight-style
topping instead. Knob: catch-band width.
**Nearest neighbor:** the Scarlet Trade (the DUELIST spends his own HP; the Low Catch surfs
ALLIES' lows — reading the party, never pricing it).

### 9.4 THEME 2 — THE OVERFLOW ENGINE · *waste is a second currency*

**What its cards do:** the ⭐Reservoir ladder named — deliberate overshoot banks spill →
SURGE shields → the flywheel re-banks. The per-cast fork IS the build: Glint (clean) or bank
(spill), chosen against the fight's next 10 seconds.
**Dials addressed:** the landing (overshoot as a choice) · the Well (the second chamber).
**Example cards:** boon *Runneth Over* (STRAT) — spill banks at 130% rate on Cascade (the
big-pour engine) · boon *Pressure Head* (GREED) — while the Reservoir is over half, pours cost
+1 ◍ but Surge shields ×1.4 · keystone **THE FLOODGATE** — a full Reservoir can be opened as
one party-wide shield wall; every point it absorbs re-banks at half.
**Greed/comfort + EASE knob:** bank-greed (riding a full chamber); comfort = drip it as small
shields. Knob: spill-bank rate.
**Nearest neighbor + ledger flag:** the Warden's PAYLOAD (banks prevented damage, hurls it as
DAMAGE on his timing) — the Overflow banks overheal into SHIELDS on an auto-flywheel; recorded
in the SLATE-PLAN §5 distinctness ledger for the deck passes.

### 9.5 THEME 3 — THE GLINTSMITH · *your healing is the warband's whetstone* (TEAM)

**What its cards do:** the outward build — ✧ Glint uptime as the job (the 3-tier ladder is the
spine), Shining Hour as the TEAM card, the blindfold as the greed pole, and the Ana-grenade
two-beat: PRIME an ally (short amplified-landing window), then size the pour into it. The
FFXIV-warning answer: the healer's damage is delivered through clean healing, full stop.
**Dials addressed:** the Glint (duration/tiers/targets) · the landing (primed windows).
**Example cards:** boon *Whetstone Waters* (POWER) — Glints +1s and stack to 2 allies · boon
*Blind Pour* (GREED) — landing preview OFF, perfect pours Glint at tier+1 (the no-free-value
pole) · boon *The Primed Vein* (STRAT) — prime an ally: their next landing window widens ×1.5
and a perfect there Glints the WHOLE party for 1s · keystone **THE GILDED HOUR** — while all
four Glints are live at once, time gilds: every ally's next clean answer crits.
**Greed/comfort + EASE knob:** precision-greed (blindfold); comfort = preview on, small steady
Glints. Knob: Glint grace-window on near-perfect landings.
**Nearest neighbor + ledger flag:** the Cask's TAPROOM (thrown consumables on ally timing) and
the Warden's BANNERMAN (aggro uptime) — the Glintsmith's buffs are AUTOMATIC procs of clean
healing, no handoff, no uptime bar; third TEAM shape, recorded in the distinctness ledger.

### 9.6 THEME 4 — THE PULSE · *the vessel itself is the instrument*
*(renamed from "the Deep Well" — a built SHARED boon already carries that name, see §10.7)*

**What its cards do:** the charge/pulse economy made a build — and the skeptics' bar was "no
bread wearing a theme's costume," so every card here creates a DECISION: casting ON the pulse
beat (the Well's refill moment) refunds; the LAST charge carries a premium (dry-flirting);
batteries are chosen moments, not passive regen.
**Dials addressed:** the Well (pulse timing, charge counts) · the pour (cost sizing).
**Example cards:** creed *THE TIDE* (the Levee rework candidate) — the pulse drops 2 ◍ but
arrives half as often: feast-and-famine banking · boon *On the Beat* (STRAT) — a cast released
within 0.3s of a pulse refunds 1 ◍ (the Well becomes a rhythm surface) · boon *The Last Drop*
(GREED) — your final charge heals ×1.5 but going DRY locks the next pulse · keystone **THE
ARTESIAN** — five on-the-beat casts in a row and the Well runs artesian: ~6s of free-flowing
casts, no charge cost, then the vessel gasps (next 2 pulses skip).
**Greed/comfort + EASE knob:** dry-flirting greed; comfort = big battery, never below 3 ◍.
Knob: pulse-beat window width.
**Nearest neighbor:** SF6 burnout / the Crucible (self-authored crash cycles) — the Artesian
crash is the healer-safe version (missed refills, never missed heals); Draw's Current (sibling)
is cast-RHYTHM — the Deep Well is REFILL-rhythm; distinct clocks, stated.

### 9.7 SLATE-LEVEL CHECKS + the pick

**Spread:** crisis surfing (Low Catch) · waste banking (Overflow) · outward TEAM (Glintsmith) ·
vessel economy (the Pulse) — four clocks (spikes · spill cycles · uptime · the pulse), none
shared with Draw's Current (sibling distinctness stated per theme).
**Skeptic record:** 3 passes · **1 kill** (**the Surgeon** — a Trauma-Center operation theme:
chained multi-ally pour sequences as the core; killed because sequence-chaining re-invents
Draw's rhythm identity on Brim's bar — the operation SHAPE survives as single cards inside
Glintsmith/Low Catch) · ~7 fixes folded (Low Catch band-position fix · Deep Well
decisions-not-bread bar · blindfold homed as Glintsmith's greed pole · Ana-grenade shaped as
PRIME, no new button · Overflow fork stated as identity · Artesian crash healer-safe · TEAM
distinctness vs Taproom/Bannerman recorded).
**Skeptic ranking (pick-tension, strongest→weakest):** Low Catch · Overflow Engine · Glintsmith
· the Pulse.
**Composition notes:** Low Catch + Overflow is the classic pair (crisis + banking — both love
Cascade). Glintsmith + the Pulse is the metronome build (pulse-beat casts feeding Glint uptime).
Low Catch + Glintsmith fight over band position (down vs topped) — legal, spicy, flagged.
All four leave the book and the grade untouched.
**Engine debts:** none new — Reservoir/Nerve/pips/Glint machinery is coded; Shining Hour is a
party-state check; PRIME is a kit-local ally flag.
**Skipped on purpose:** **the Surgeon** (killed, above) · **a healer damage lane** (the FFXIV
warning made law — Glints or nothing) · **an Ana anti-heal/debuff shape** (boss-facing debuffs
are the Debilitator/support lane, and off-fantasy here) · **VIGIL/held-cast territory** (Draw's
transformer candidate — the sibling owns holds).

**Next:** Bill picks 2–3 themes → Phase-2 row D5 authors the Brim deck reshape around them
(filing hard-copied, CARD-CATALOG rows, EASE knobs per theme), inside the ⚖ board verdicts.

---

## 10. THE DRAW BRANCH SLATE — four build-theme candidates 🟡 AT VERDICT (2026-07-10)

**What this is** (SLATE-PLAN row 6; branch = build THEME). The sibling law is the hard wall:
**Brim reads the party (§9); Draw reads your own hands** — every theme below lives on the
release/rhythm/hold surface and none touches landings. Base kit untouched (manual completion ·
the Current · the Still Point · the gutter); example cards are ILLUSTRATIONS — no CARD-CATALOG
rows. **How it was made:** §§0–8 + the ⚖ Draw creed verdicts + fresh sweep
`research/draw-sweep.md` (GH extended sustains · osu slider-follow · archery over-hold) →
4 lenses → 4 themes → **3 skeptic passes (1 kill, ~6 fixes folded)**.

### 10.1 THE FILING TABLE (verdicted Draw material → themes; zero orphans)

| Existing (state) | Files under |
|---|---|
| THE CURRENT (base machinery) | **THE RAPIDS** (its named ladder) |
| THE PATIENT HAND creed 🔒4★ | **THE VIGIL** (the entry creed) |
| VIGIL transformer candidate (§1 🔮) | **THE VIGIL** (the module, promoted) |
| THE LONG DRAW creed 🔒4★ | **THE VIGIL** / generic (slow-big suits holds) |
| THE NARROWS creed 🟡 | **THE RAPIDS** (all-or-nothing suits speed) |
| THE EDDY creed 🟡 | **THE EDDY** (the entry creed) |
| THE STILL POINT (base tier) | **THE EDDY** (the hunt) / generic |
| Undercook rule (base) | **THE SKIM** (the priced quick-sip, built on) |
| WHEN sketches (clean-draw · undercook · held release) | Rapids / Skim / Vigil respectively |

### 10.2 THEME 1 — THE RAPIDS · *never let the river slow*

**What its cards do:** the Current named as a ladder — stack protection, speed payoffs, streak
premiums. At Current 5 the Still Point hardens (base, self-balancing): the theme's ceiling is
riding the hardest version of your own bar.
**Dials addressed:** the Current (uptime/stacks) · the release (streak grades).
**Example cards:** boon *Whitewater* (POWER) — heals +4% per Current stack · boon *Shoot the
Gap* (GREED) — at Current 5, Still-Point tags heal ×1.3 (the hardened sliver is the payout) ·
boon *Eddyline* (STRAT) — one undercook per 10s downgrades the Current by 1 instead of breaking
it: a play, not a pardon — it costs the stack AND the sip is still weak.
**Spectacle keystone:** **THE FLUME** — hold Current 5 for 12s and the river runs white: ~6s
where every release is auto-clean and the party's bars visibly ride the flow; then the Current
resets to 0 (earned, never toggled).
**Greed/comfort + EASE knob:** streak-greed; comfort = ride at Current 2–3. Knob: Current
ebb-grace (idle seconds before it fades).
**Nearest neighbor:** Tempo's SWIFT theme (more-faster on offense) — this is the inward healer
mirror; recorded. The Pulse (Brim §9) is REFILL-rhythm — the Rapids is CAST-rhythm.

### 10.3 THEME 2 — THE VIGIL · *walk with the drawn arrow*

**What its cards do:** the held-heal build — Patient Hand enters it; the promoted VIGIL module
turns every overrun into a HELD state (walk with it, release on the spike, gutter if you camp).
The archery steal: the held heal visibly TREMBLES toward its gutter — tension you read, never a
hidden timer. The GH steal (module-tier): Flash-size casts stay available while holding.
**Dials addressed:** the release (held) · the gutter curve · the Well (holds park charges).
**Example cards:** module *THE VIGIL* ⭐ — overruns become held heals (~3s, tremble-telegraphed;
release = instant, gutter = charge + cast wasted) · boon *Second Hand* (STRAT) — Flash remains
castable while holding (the stance, not the lockout) · boon *White Knuckle Draw* (GREED) — a
held heal releases +8% stronger per half-second held: ride the tremble to the brink ·
keystone **LOOSED AT LAST** — a held heal released within 0.2s of the ally's hit lands as a
PERFECT INTERCEPT: full heal + the overflow becomes a 2s shield (the archer's photo-finish).
**Greed/comfort + EASE knob:** tremble-greed (holding longer); comfort = release early and
plain. Knob: gutter onset delay.
**Nearest neighbor + ledger flag:** FERMATA (offensive hold/release — cashes damage on ITS
schedule); the Vigil holds a HEAL for someone else's worst moment — different job, same grammar
family; recorded in the distinctness ledger.

### 10.4 THEME 3 — THE SKIM · *a hundred shallow cups*

**What its cards do:** the undercook made a chosen tool — the anti-Current pole. Skim builds
never ride the Current (it stays broken, the cost stands); they get paid in volume: skimmed
casts finish fast, and the theme's cards give sips WAKES (small trailing HoTs), never bigger
sips for free. Triage tempo over rhythm — the deliberate opposite of everything else on the bar.
**Dials addressed:** the release (early, priced) · the pour tempo.
**Example cards:** boon *The Wake* (STRAT) — a skimmed heal leaves 30% of its skipped value as
a 3s trickle · boon *Skipping Stone* (GREED) — every 3rd consecutive skim, the wake doubles;
a full clean draw resets the count (commitment: stay shallow) · boon *Cold Water* (POWER) —
skims cost 1 ◍ flat regardless of spell.
**Spectacle keystone:** **THE SQUALL** — six wakes live at once burst into rain: every ally
under a wake heals its remaining value instantly, the bars mist over.
**Greed/comfort + EASE knob:** tempo-greed (spamming shallow under pressure); comfort = skim
only when the spike demands. Knob: wake duration.
**Skeptic fix folded:** the pardon-smell check — skims stay × p^1.5 ALWAYS (no card restores
full value); the build is paid in wakes and tempo, never forgiven the sip.
**Nearest neighbor:** Bloomweaver's MEADOW seed (many-small on gardens); the Skim is many-small
on the CAST BAR — no planting, pure release tempo.

### 10.5 THEME 4 — THE EDDY · *read the water every single cast*

**What its cards do:** the drifting-band creed grown into the read build — the osu steal:
press-and-FOLLOW. Bands drift; you track and tag them fresh every cast (anti-rhythm-memory,
the reading pole of the spec). Still-Point hunting pays double here because the sliver moves.
**Dials addressed:** the band (position/drift) · the Still Point.
**Example cards:** creed *THE EDDY* (verdicted 🟡, the entry) — the band drifts cast-to-cast ·
boon *Current Reading* (STRAT) — tagging the band in its first third of drift grants +1 Current
(reading fast pays rhythm) · boon *Deep Eddy* (GREED) — drift range doubles, Still-Point tags
×1.5 · keystone **THE GLASS RIVER** — three moving Still-Point tags in a row FREEZE the water:
~5s where bands stop drifting and every release is Still-Point-graded (the reward for reading
is stillness).
**Greed/comfort + EASE knob:** drift-greed (wider wander); comfort = slow drift, wide band.
Knob: drift speed.
**Nearest neighbor:** the Matador (reads on the boss's DEFENSE stream — insight from
not-pressing); the Eddy reads your OWN moving bar, every press. Recorded.

### 10.6 SLATE-LEVEL CHECKS + the pick

**Spread:** streak (Rapids) · hold/spike (Vigil) · volume/tempo (Skim) · fresh-read (Eddy) —
four clocks; the Rapids/Skim polarity (protect the Current vs abandon it) is the slate's
pick-tension centerpiece. Zero overlap with Brim §9 (landings/party surfaces untouched —
sibling law held).
**Skeptic record:** 3 passes · **1 kill** (**the Whirlpool** — a channel that drains the whole
Well into one giant heal: it's Rekindle's job wearing a keystone, and the bank-and-dump shape
is the Warden Payload's; died at the nearest-neighbor bar) · ~6 fixes folded (Skim pardon-check
· Eddyline priced as downgrade-not-forgiveness · Vigil tremble made visible · Second Hand
scoped to Flash only · Flume/Glass River earned-never-toggled · Rapids/Deep-Well clock
distinction recorded).
**Skeptic ranking (pick-tension, strongest→weakest):** Vigil · Rapids · Eddy · Skim.
**Composition notes:** Vigil + Rapids is the classic pair (ride fast, hold the overrun);
Vigil + Eddy is the hardest-hands build (moving bands AND held heals — flagged attention
stress); Rapids + Skim is ILLEGAL-adjacent (the polarity — legal to draft, self-defeating;
the deck pass should let the trio-test confirm they repel).
**Engine debts:** none new — held-state is Patient Hand machinery; drift is a band parameter;
wakes are small HoTs (coded idiom).
**Skipped on purpose:** **the Whirlpool** (killed, above) · **a party-facing TEAM theme**
(Brim's Glintsmith owns the healer's outward lane this round; Draw stays the inward spec by
design) · **osu drift-ticks mid-cast** (micro-grades during one cast — real depth, too fiddly
for v1; noted for the deck pass as an Eddy Opus candidate).

**Next:** Bill picks 2–3 themes → Phase-2 row D6 authors the Draw deck reshape around them,
inside the ⚖ board verdicts.

### 10.7 THE BUILT-POOL ADDENDUM (both specs — corrects §9.2 + §10.1)

The DECK banner (top of this doc) records **24 BUILT boons + built rig/keystones** the two
filing tables above under-counted (they filed only the ⚖-verdicted creeds/modules/sketches).
The built pool files as follows — **the Phase-2 deck passes (D5/D6) inherit THIS table and run
the deck-creator BROKE/FADED/DEAD/OPENED sweep when themes land:**

| Built card | Files under |
|---|---|
| _SHARED_ Deep Well · Steady Pulse · **Meditate** (battery) | **THE PULSE** (§9 — and the theme was RENAMED from "Deep Well" to clear this very boon's name) |
| _SHARED_ The Kept Light · ✦ The Shining Hour (BUILT, not a sketch) | **GLINTSMITH** (§9) |
| _SHARED_ Brink Bell (the emergency absorb) | **LOW CATCH** (§9) — ⚠ it is the lane's ONE pardon; the deck pass counts it against the ≤1-insurance law |
| _SHARED_ Boiling Over (clutch damage dump) · Warm Rekindle | generic (rule-5 clutch · bread) |
| _BRIM_ Overflowing Cup · Still Water | **OVERFLOW ENGINE** (§9) |
| _BRIM_ **Low Catch** (built boon) | **LOW CATCH** (§9) — the theme is named FOR it; the boon becomes its bread rung |
| _BRIM_ The Blindfold · **High Tide** (built keystone) | **GLINTSMITH** (§9) |
| _BRIM_ Wide Brim · Second Ring · Cadence of Mend | generic pour bread — deck pass re-files by effect |
| _DRAW_ **Strong Pull** · **The Millrace** (built keystone) | **THE RAPIDS** (§10) — ⚠ Millrace and the pitched FLUME compete for the same capstone slot; ONE absorbs the other at the deck pass |
| _DRAW_ Short Pour · Loose Grip | **THE SKIM** (§10, by name — deck pass confirms by effect) |
| _DRAW_ Deep Still · Last Drops | **THE EDDY** / **THE VIGIL** (§10, by effect at deck pass) |
| _DRAW_ Cool Hand · Double Draw | generic release bread — deck pass re-files |
| Built rig WHENs (Brim: Sweet Pour/Spillover/Low Catch · Draw: Clean Draw/High Water/Still Point) | map 1:1 onto §9/§10 themes (Spillover→Overflow · Low Catch→Low Catch · Still Point→Eddy etc.) |
| Built creeds The Levee / The Shallows (coded versions differ from the §2 rework notes) | Levee (absorb-leaver) → **OVERFLOW ENGINE** adjacency, NOT the Pulse — the §9.2 Levee row is corrected by this table; Shallows (bright Glint glass) → **GLINTSMITH** |

**Net effect:** every built card now files somewhere; the two slates' theme sets survive the
full pool contact unchanged — the only casualties were the theme NAME (Deep Well → the Pulse)
and the Levee's filing (Overflow, not the Pulse). Stated so the deck passes don't re-discover it.

---

## 11. THE BRIM DECK RESHAPE — around LOW CATCH · OVERFLOW · GLINTSMITH 🟡 (2026-07-10, Phase-2 D5)

**What this is** (SLATE-PLAN row D5; deck-creator reshape law — the Well's deck is BUILT
(`well-deck` `500334f`), so this is absorb-don't-duplicate: the built pool files into the §9
winners, new cards land only in OPENED space, and the pass runs the BROKE/FADED/DEAD/OPENED
sweep). Winners = the §9 ranking's top 3 (the Pulse is 4th; your ✅ picks swap free). Two
skeptic catches this pass: **Blind Pour CUT before birth** (it duplicated the BUILT Blindfold —
the greed pole already exists in code) and **"Steady Under Fire" renamed COOL HEAD** (the Brew's
§8 P8 proposal owns that name).

### 11.1 THE SWEEP (base unchanged → light form)

- **BROKE:** nothing (the core didn't move; themes are a filing layer).
- **FADED:** *Wide Brim* — a pure widener → **folds into the EASE dial** (standing law), leaves
  the pool. *Cadence of Mend* — generic bread, stays but flagged low-tension.
- **DEAD:** none.
- **OPENED:** the three theme lanes — every built creed happens to enter one (§10.7 filing):
  **The Brink → LOW CATCH · The Levee → OVERFLOW · The Shallows → GLINTSMITH.** Entry law
  satisfied by cards already in code — the reshape's luckiest fact.

### 11.2 THE THEME LANES (built cards filed 🔨 · new cards 🟡 — full rows in CARD-CATALOG)

**LOW CATCH** (entry: The Brink 🔨): built — *Low Catch* (the boon the theme is named for),
*Brink Bell* (⚠ the lane's ONE pardon, counted), Triage Protocol module. New 🟡 — **Knife's
Edge** [GREED] the band drops another 10%, catches +25% · **Cool Head** [STRAT, renamed] a
catch during a boss telegraph string refunds 1 ◍ · keystone **THE UNDERTOW** — three
consecutive catches with zero spill pull the whole party's bars up 10% in one visible wave.
**OVERFLOW ENGINE** (entry: The Levee 🔨): built — ⭐Reservoir module, *Overflowing Cup*,
*Still Water*. New 🟡 — **Runneth Over** [STRAT] spill banks at 130% on Cascade · **Pressure
Head** [GREED] over half Reservoir: pours +1 ◍ cost, Surge shields ×1.4 · keystone **THE
FLOODGATE** — a full Reservoir opens as one party-wide shield wall; absorbs re-bank at half.
**GLINTSMITH** (entry: The Shallows 🔨): built — *The Blindfold* (the greed pole — Blind Pour
died to it), *The Kept Light*, *High Tide* (the BUILT capstone), ✦*The Shining Hour* (the TEAM
card), Benediction module. New 🟡 — **Whetstone Waters** [POWER] Glints +1s, stack to 2 allies
· **The Primed Vein** [STRAT] PRIME an ally: their next landing window ×1.5, a perfect there
Glints the party 1s · keystone **THE GILDED HOUR** — all four Glints live at once: every
ally's next clean answer crits.
**Generic/shared (stay):** Deep Well · Steady Pulse · Meditate · Boiling Over · Warm Rekindle ·
Second Ring · Cadence of Mend (the Pulse's cards wait with their theme).

### 11.3 KEYSTONES · EASE · the counts

- **Keystone pool:** High Tide 🔨 + Undertow/Floodgate/Gilded Hour 🟡 = 4, theme-weighted
  1-of-2 elite offers (the same rule proposed at D0/D4).
- **EASE knobs (Brim):** brim-band width (Wide Brim's fold) · landing-preview strength ·
  catch-band width · Glint grace.
- **Counts:** pool after fold = 14 built + 6 new = within quota with the Pulse's cards parked;
  insurance total = 1 (Brink Bell) ✓; no new buttons ✓.

### 11.4 GATES + SKEPTICS (evidence, delta-scope)

**Dream drafts:** *LOW CATCH:* Brink → Triage Protocol → Knife's Edge + Cool Head + Low Catch
→ THE UNDERTOW (the band sinks, the saves escalate, the wave crowns it) ✓ · *OVERFLOW:* Levee
→ Reservoir → Runneth Over + Pressure Head + Overflowing Cup → THE FLOODGATE (waste becomes a
wall) ✓ · *GLINTSMITH:* Shallows → Benediction → Whetstone Waters + Primed Vein + Blindfold →
THE GILDED HOUR (precision becomes the warband's crit hour) ✓ · *Hybrid:* Brink + Reservoir
(catch low, bank the rebound spill) — legal, rich ✓.
**Trios:** (Knife's Edge | Pressure Head | Blindfold) three greeds three surfaces ✓ · (Cool
Head | Runneth Over | Whetstone Waters) three STRAT/POWER, build-dependent ✓.
**Overlap/skeptics:** **Blind Pour KILLED** (duplicate of the built Blindfold — caught at the
distinctness table) · **Cool Head renamed** (Brew P8 owns "Steady Under Fire") · Undertow vs
Benediction's bloom (both party-heals-on-streak) — elite-tier wave vs module pip-cash, ladder
rungs not duplicates, recorded · the FADED fold (Wide Brim → dial) executed · no pardons added
(Brink Bell stays the counted one) ✓.
**AI:** catch-band thresholds · Reservoir-level triggers · Glint-uptime scheduling — the built
`well_policy` already reads all three surfaces; 3 tiers natural.

### 11.5 TENSION POINTS (Bill)

1. Winners = Low Catch · Overflow · Glintsmith (the §9 ranking) — swap the Pulse in? (Its
   cards wait, filed.)
2. **Wide Brim → EASE fold** (leaves the pool) — accept? (Lean: yes, standing law.)
3. The keystone offer rule (third deck proposing it — if you accept once, it's the pattern).
4. High Tide vs Gilded Hour BOTH in Glintsmith's pool — two capstones in one theme (lean:
   fine — one built, one elite-priced; the trio test keeps them apart).

**Next:** your picks → catalog flips; the build claim is a light slice (new cards are kit-local
boons + two module-adjacent effects; the Well's `_fw()` wiring is already in).

---

## 12. THE DRAW DECK RESHAPE — around THE VIGIL · THE RAPIDS · THE EDDY 🟡 (2026-07-10, Phase-2 D6)

**What this is** (SLATE-PLAN row D6; reshape law — the Draw pool is BUILT (`500334f`), so:
built cards file, new cards fill OPENED space only, sweep run). Winners = the §10 ranking's
top 3 (the Skim's cards park with their theme; your ✅ picks swap free). **The headline
reconcile: MILLRACE vs THE FLUME** (flagged in §10.7) — resolved below as a demote-and-crown
proposal. Sibling gate held: nothing here touches landings or the party surface (Brim's §11).

### 12.1 THE SWEEP

- **BROKE / DEAD:** none (base untouched).
- **FADED → THE KEYSTONE RECONCILE:** the built **Millrace** (every 3rd cast free at full
  Current) is an ECONOMY effect wearing a keystone slot — it fails the keystone bar ("way more
  fun than open kick window"; the same bar that killed Nightfall). **Proposal: Millrace
  DEMOTES to a Rapids boon** (honest, strong economy card) **and THE FLUME is crowned the
  Rapids keystone** (the spectacle: the river runs white). Your call — it's the pass's biggest
  status change and it touches a built card.
- **OPENED:** the three lanes. Entries: **Patient Hand → Vigil** (built) · **The Narrows →
  Rapids** (built; all-or-nothing suits speed, §10.1) · **The Eddy → Eddy** (built). Entry law
  again satisfied from code.
- **Unfiled built boons** (Loose Grip · Short Pour · Cool Hand · Double Draw · Deep Still ·
  Last Drops): banner names only — **the build claim files them by effect** from
  `well_boons.gd` (Short Pour/Loose Grip presumptively the Skim's, parked with it). Honest gap,
  stated.

### 12.2 THE THEME LANES (built 🔨 · new 🟡)

**THE VIGIL** (entry: Patient Hand 🔨 · Long Draw 🔨 files here too — slow/big suits holds):
- module ⭐ **THE VIGIL** [NEW 🟡 — the §1 transformer candidate, promoted]: every overrun
  becomes a HELD heal (~3s), the hold visibly TREMBLES toward its gutter (archery sway —
  tension you read); release = instant; gutter = charge + cast wasted.
- **Second Hand** [STRAT 🟡] — Flash stays castable while holding (the stance, not a lockout).
- **Ride the Tremble** [GREED 🟡, renamed from "White Knuckle Draw" — the Warden owns White
  Knuckles] — a held heal releases +8%/half-second held: surf the sway to the brink.
- keystone **LOOSED AT LAST** [🟡] — a held heal released within 0.2s of the ally's hit lands
  as a PERFECT INTERCEPT: full heal + the overflow becomes a 2s shield.
**THE RAPIDS** (entry: The Narrows 🔨):
- **Strong Pull** [🔨, files here] — max-Current clean heals +30%.
- **The Millrace** [🔨 → **proposed DEMOTE to boon**] — every 3rd cast free at full Current.
- **Whitewater** [POWER 🟡] — heals +4% per Current stack.
- **Shoot the Gap** [GREED 🟡] — at Current 5, Still-Point tags ×1.3 (the hardened sliver pays).
- **Eddyline** [STRAT 🟡] — one undercook per 10s DOWNGRADES the Current by 1 instead of
  breaking it: costs the stack AND the sip stays weak — a play, never a pardon.
- keystone **THE FLUME** [🟡, crowned] — hold Current 5 for 12s: ~6s where the river runs
  white (every release auto-clean, the party's bars visibly ride the flow), then Current 0.
**THE EDDY** (entry: The Eddy creed 🔨):
- **Current Reading** [STRAT 🟡] — tagging the band in its first third of drift grants +1
  Current (reading fast pays rhythm — the cross-theme bridge).
- **Deep Eddy** [GREED 🟡] — drift range doubles, Still-Point tags ×1.5.
- keystone **THE GLASS RIVER** [🟡] — three moving Still-Point tags in a row FREEZE the water:
  ~5s of still bands, every release Still-Point-graded.
**Generic (stay 🔨):** Deep Still · Last Drops · Cool Hand · Double Draw (effect-filing at
build) · the Skim's presumptive pair parks with its theme.

### 12.3 KEYSTONES · EASE · counts

- **Keystone pool (post-reconcile):** Loosed at Last · the Flume · the Glass River = 3 🟡
  (Millrace leaves the tier if the demote stands) — theme-weighted 1-of-2 offers, same rule.
- **EASE knobs (Draw):** release-band width · Current ebb-grace · gutter onset delay · drift
  speed. (Brim's four are §11's — the dial rolls per spec.)
- **Counts:** ~14 active + parked Skim pair; insurance 0 added (the spec's forgiveness lives
  in base rules — overrun auto-completes plain) ✓; no new buttons (the Vigil holds ride the
  existing two-way cast input) ✓.

### 12.4 GATES + SKEPTICS

**Dream drafts:** *VIGIL:* Patient Hand → ⭐Vigil → Second Hand + Ride the Tremble + Long Draw
→ LOOSED AT LAST (walk with the drawn arrow, answer the spike) ✓ · *RAPIDS:* Narrows →
(module-free) → Whitewater + Strong Pull + Millrace(boon) + Eddyline → THE FLUME (all-or-
nothing feeds the streak; the river whitens) ✓ · *EDDY:* Eddy → ⭐Vigil or none → Current
Reading + Deep Eddy + Shoot the Gap → THE GLASS RIVER (read the water until it stills) ✓ ·
*Hybrid:* Eddy + Rapids via Current Reading (drift-reads feed the streak — the designed bridge)
✓.
**Trios:** (Ride the Tremble | Shoot the Gap | Deep Eddy) three greeds, three surfaces ✓ ·
(Whitewater | Strong Pull | Millrace-as-boon) three Rapids POWERs — **the same three-bread flag
as the Warden's**: offer-weighting note, not a card change.
**Skeptic record:** the **Millrace demotion** is the pass's judgment call (economy-in-a-
keystone-slot fails the locked bar — proposed, not imposed; it's a built card so YOUR verdict
flips it) · **Ride the Tremble rename** (Warden collision) · Eddyline's pardon-check re-run
(costs stack + weak sip = priced ✓) · sibling gate: zero landing/party cards ✓ · Vigil-vs-
Fermata hold distinction re-verified at deck level (heal held for someone else's moment vs
damage cashed on your own — recorded).
**AI:** hold-release timing (the policy's existing release model + a spike-forecast trigger) ·
Current-preservation thresholds · drift-tracking (the built Eddy creed is already policy-read).

### 12.5 TENSION POINTS (Bill)

1. **THE MILLRACE DEMOTION** — economy keystone → boon; the Flume crowned. (Lean: demote —
   the keystone bar is your own law.)
2. **The Vigil module ships as the ⭐** — the §1 "VIGIL folds into Draw build territory" note
   made real. Accept?
3. The unfiled-built-boons gap (effect-filing at build — Short Pour/Loose Grip presumed Skim).
4. Winners = Vigil · Rapids · Eddy; the Skim's kit is filed and waiting if you want the
   anti-Current pole instead.

**Next:** your verdicts → catalog flips; build = a light slice on the Well's wiring (the Vigil
module is the one real kit-mechanic addition; everything else is boon-local).
