# MENDER-PLAN — the direct-cast healer onto Framework v2 (the Well · twin graded specs BRIM / DRAW)

> **2026-07-10:** the BRIM BRANCH SLATE (§9) is 🟡 AT VERDICT — verdicted material filed + four
> themes (Low Catch · Overflow Engine · Glintsmith · Deep Well). Draw's slate is queue row 6.

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
| LEVEE / SHALLOWS creeds 🟡 (rework owed) | **DEEP WELL** candidates (Levee's dead refund hook → the pulse-refund rework below) |
| ⭐ THE RESERVOIR module | **OVERFLOW ENGINE** (the transformer) |
| TRIAGE PROTOCOL module | **LOW CATCH** |
| BENEDICTION module | generic (any theme's 5th-pip rhythm) |
| ✧ Glint 3-tier ladder (🟡 ledger) | **GLINTSMITH** (the spine) |
| THE SHINING HOUR support sketch | **GLINTSMITH** (the TEAM card) |
| Blindfold boon (B-V3 rider) | **GLINTSMITH** (the greed pole) |
| Battery boon (Meditate remnant) | **DEEP WELL** |
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

### 9.6 THEME 4 — THE DEEP WELL · *the vessel itself is the instrument*

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
vessel economy (Deep Well) — four clocks (spikes · spill cycles · uptime · the pulse), none
shared with Draw's Current (sibling distinctness stated per theme).
**Skeptic record:** 3 passes · **1 kill** (**the Surgeon** — a Trauma-Center operation theme:
chained multi-ally pour sequences as the core; killed because sequence-chaining re-invents
Draw's rhythm identity on Brim's bar — the operation SHAPE survives as single cards inside
Glintsmith/Low Catch) · ~7 fixes folded (Low Catch band-position fix · Deep Well
decisions-not-bread bar · blindfold homed as Glintsmith's greed pole · Ana-grenade shaped as
PRIME, no new button · Overflow fork stated as identity · Artesian crash healer-safe · TEAM
distinctness vs Taproom/Bannerman recorded).
**Skeptic ranking (pick-tension, strongest→weakest):** Low Catch · Overflow Engine · Glintsmith
· Deep Well.
**Composition notes:** Low Catch + Overflow is the classic pair (crisis + banking — both love
Cascade). Glintsmith + Deep Well is the metronome build (pulse-beat casts feeding Glint uptime).
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
