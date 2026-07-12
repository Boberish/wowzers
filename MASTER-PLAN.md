# MASTER PLAN — Project Rift

**This is the coordination hub.** Current status, open work, claims, and ideas all live HERE.
`CLAUDE.md` keeps the stable rules (engine law, how to run things, past milestone history); this file is the *living state*. When Bill says "work on X", X is a section of this file.

---

## HOW TO WORK (process rules — every agent, every task)

1. **Read this file first.** Find your section, check the Coordination Log for conflicts.
2. **Claim your work**: add a line to the Coordination Log (`date · branch · section · what`) *before* starting.
3. **Always work in a git worktree** — never directly on `main`:
   `git worktree add ../wow-<task> -b <task>` → work there → commit early and often.
4. **Sync often**: merge `main` into your branch regularly (at least before merging back) so parallel work never drifts far apart. **⚡ If your worktree predates 2026-07-03, `git merge main` NOW** — it brings **`scripts/psim.sh`** (runs the ACTIVE sims — `twinfang_sim` + `raid_sim` since the 2026-07-06 fresh slate — sharded across cores, **~5×** faster: `scripts/psim.sh <sim> [seeds] [jobs] [-- --boss=…]`). Prefer it over a single-threaded `godot --headless … --script res://sim/<sim>.gd -- --seeds=N`. It sims **your** worktree's code (self-locating root), so you still need to be synced. A missing/old `psim.sh` fails safe (no wrong results); output is byte-identical to a single run.
5. **Verify before merging back**: run the acceptance bar for your section (listed per-section below; default = the active sims [`twinfang_sim` + `raid_sim`] + the system probes/UI smokes you touched, determinism PASS, and byte-identical checksums for any engine change). *(The old class/boss sims were deleted 2026-07-06 — see §CLASSES / CLAUDE.md ACTIVE VERIFICATION.)*
6. **Merge to `main`, then UPDATE THIS FILE** — status, what changed, what's next, tick the Coordination Log entry. A task isn't done until the master plan says so. **If the work created/changed/removed planned-but-unbuilt scope (or moved which files it touches), also update `BUILD-LEDGER.md`** (slate row + §0 collision map) in the same commit — the **LEDGER LAW** (CLAUDE.md). Cards additionally go to `CARD-CATALOG.md` (CARD-TRACKING LAW).
7. Engine law is unchanged and non-negotiable: `CombatCore` stays a pure, deterministic, Node-free reducer (see CLAUDE.md).
8. Cleanup: `git worktree remove ../wow-<task>` when merged.

---

## OVERALL PROGRESS

| Area | State |
|---|---|
| Combat engine (pure reducer, strings, threat) | ✅ Solid, regression-gated |
| Classes (post-purge 2026-07-10: Twinfang · Alchemist · Well active; Bulwark frozen-until-Duelist; Bloomweaver frozen; Voidcaller/Mender/Reckoner DELETED) | 🟢 Rework era — see §CLASS FRAMEWORK v2 + §GAME SHAPE purge amendment |
| Bosses (15 solo + Vorathek raid) | ✅ Done, tuned bands |
| Run loop + draft (all 5 classes) | ✅ Draft 2.0 everywhere — synergy slot, Haiku/Sonnet/Opus + pity, Tokens (merged 2026-07-02, see §SYSTEMS) |
| UI (Gilded Reliquary overhaul) | ✅ Done |
| 3D stage | 🟡 Bulwark vertical slice only |
| Co-op raid (R0/R1: any seat, any aspect, AI raiders) | ✅ Playable |
| Netcode (R2/R2.5: lockstep WS server, Docker/tunnel deploy kit, Windows + browser clients) | ✅ DONE & verified (cross-OS identical checksums; see CLAUDE.md R2/R2.5). **+ MAP-3b: online co-op map traversal (protocol v3, `127ab2c`)** — server owns the campaign, leader routes, fights carry state |
| **Realms (raids = themed realms; Realm 1 "The Takeover" = AI irony)** | 🟢 Realm 1 PLAYABLE end-to-end: 3-floor RING descent (MISTRAL→GEMINI→MYTHOS) w/ GATE exams + shard gate (MAP-3c `fafaf1a`). Online nav (3b) + Realm 2 open |
| **Raid Seals II–IV (online boss ladder: Mistral/Gemini/Claude-Mythos)** | ✅ DONE, merged `ac1aa25` (adds/chains/rand-beats engine + 3 bosses + lobby Seal pick, protocol v2 — see §RAID SEALS) |
| **Draft 2.0 + Tokens + slot-verbs (Phases A+B+C)** | ✅ COMPLETE 2026-07-02 — build-your-verb live on ALL FIVE classes (Guard/Rhythm/Kick/Triage/Garden), LOCK/REROLL/UPSELL economy, 5 opus charge/transform capstones (see §SYSTEMS). Next §SYSTEMS frontier: Trial Ladder (D) |
| **Trial Ladder ("Versions") + RAID DEPTH — the infinite "Mythic+" endgame** | 🔴 NEW — design captured 2026-07-04 (per-boss Versions + unbounded raid Depth = RANK track; scaling = numeric spine + affix tiers that compress *windows*, NOT a gear treadmill — **Law #1 reaffirmed**; drop-curation = **oath dedication only**, gift a teammate the drop-bend). See §MODES & ENDGAME + §SYSTEMS E.5 + `PROGRESSION-PLAN.md` |
| **Persistent progression (loot tables / OATHS / Ledger / standing)** | 🟡 **GEAR-1 MERGED 2026-07-03** (`866592f` — Curio drops/equip/scrap/unlock store live on the raid campaign, byte-identical gearless). Design: `PROGRESSION-PLAN.md` + `GEAR-CATALOG.md`. GEAR-2 (oaths/Ledger UI) claimable |
| **Maps ("The Topology" — AtO-style node runs)** | ✅ MAP-1/2/3 + **INFERENCE CHECK** + **THE KILL SWITCH P1** (⏻ shared meter · OVERCLOCK arming offline+online · integrity RETIRED · 5 charge events; protocol v11). Phase 2/3 (biting blessings + Forge + live UNPLUG) open.  ~~INFERENCE CHECK COMPLETE~~ (P0–P6 + seat-picker + branches + wager/mulligan + online-Prior + fight-marks) — build-read dice + ⚡Entropy/📁Prior luck meta + multi-stage branches + cross-node flags + 14 events + wager kind + post-fail mulligan, offline AND online co-op (protocol v9, server resolves + traverses stages; client==server). protocol v10; FEATURE-COMPLETE (all follow-ups merged) |
| **GAME SHAPE — RAID-ONLY** | 🔒 LOCKED 2026-07-03 (see §GAME SHAPE) — one game; solo campaign retired to a PRACTICE card; raid-first law |
| **THE WORLD (persistent overworld: Atlas/zones/fog/flight/world events/hometown, wrapping the instances)** | 🟢 **W1 BUILT & MERGED 2026-07-06** (`b9c26aa`): the Atlas + ZONE 1 "THE GILDFIELDS" (20-node conquest map, ZONE REMEMBERS teaser, rushable door) + Bastion hub, flagged preview (`--autostart=world`). Design locked in **`WORLD-PLAN.md`** (see §THE WORLD): zones = persistent conquest · warband law · overworld = bare kit · interrupt-by-ability · single-target + dodge-ration pillars. Next: Bill's feel pass → W2 (Forge + TICKETS v2) |

---

## GAME SHAPE — RAID-ONLY (locked with Bill, 2026-07-03)

**The decision:** there is ONE game — the raid campaign (the Topology Rings, solo-playable via
AI raiders, co-op online). The parallel solo campaign is **retired as a product surface** — the
split was an accident of porting the per-class POC teaching rigs, and it was costing double
features/maps/defaults. The 15 solo bosses are NOT wasted: they were built as one-verb exams,
and they become the raid's **personal-responsibility content** (Bill's frame: "the boss runs
away and these solo bosses come — each player has to finish theirs") via three tiers:

- **Tier 1 — PERSONAL GATE nodes — ✅ SHIPPED 2026-07-03 (see §MAPS · GATE nodes):** a Topology node that is a 1v1 duel
  for ONE designated seat — existing solo encounter nearly verbatim; the Realm-1 casting-pool
  fiction is pre-written (FIREWALL: "one process may pass"). Others see banner+result in v1
  (live spectate = later nicety — lockstep makes it data-free, it's HUD work). Integrity/wounds
  carry, so a sloppy gate bleeds into the Seal fight.
- **Tier 2 — OWNED ADDS (moderate):** mid-Seal minibosses locked to one seat (`add_owner_i`
  on the AddRes system, guarded; swings aim only at the owner, `rand_target` idiom). The main
  boss keeps melee-chip pressure only while the add owns the telegraph (one-telegraph law) —
  reads as "the boss watches while its subagent works."
- **Tier 3 — THE SPLIT PHASE (showpiece — Ring 0 / Realm-2 capstone only):** the Seal withdraws
  and EVERY seat's personal boss manifests simultaneously; everyone finishes theirs or the raid
  dies. Needs parallel personal telegraph streams (real engine work; Mythos's Agentic Fan-Out
  is the primitive). Gets its own design doc when claimed — do not buy casually.

**⚠ 2026-07-10 AMENDMENT — THE OLD-GAME PURGE (Bill): the solo-boss reintegration program is
CUT.** The three tiers above are dead: **personal GATE nodes are REMOVED from the game** (the
node kind, the 4 recast exams, `gate_content.gd`), Tier-2 owned-adds and the Tier-3 split phase
are **cancelled unbuilt**, and the **15 solo exam bosses are DELETED from code** (git history is
the attic) — Bill: remove *"any resemblance of that old single player game."* The casting pool
is disbanded; if personal/exam content is ever wanted again it is **Forge-authored fresh**
(parked idea, not a plan). Threaded consequences: Proof-by-exam dies (PROGRESSION §BREADTH
amended) · gate-sourced gear rows die (GEAR-CATALOG banner) · Zone 1's personal-gate node
re-payloads (WORLD-PLAN). **In the same purge, the frozen roster shrinks (Bill's calls,
2026-07-10):** **Voidcaller · Mender · Reckoner are DELETED from code** — the **Alchemist
(brew)** becomes the caster-seat default, the **Well (brim)** becomes the healer-seat default;
**Bulwark stays as the frozen tank placeholder and dies in the same merge that ships the
Duelist base** (it is the only tank in code — BUILD-LEDGER row pins it); **Bloomweaver stays
frozen** (its rework is still owed). Twinfang's retired Warden/Executioner encounters survive
ONLY as `twinfang_sim` training dummies (sim infra, not player-facing). ⚠ **Interim state:**
with Voidcaller gone **no class carries a kick** until interrupt-by-ability (WORLD-PLAN pillar
#3) lands — Seal verses go uncontested and bands re-baseline deliberately (recorded at the
purge merge).

**Killed:** solo campaign surface · solo maps ×5 (cancelled unspent) · new solo bosses ·
solo-only features · the solo draft-run mode (drafts live in the Topology, where they already run).
**Frozen:** the five solo class HUDs (no further polish; personal gates run through `raid_hud`'s
existing per-seat class bands). **Kept:** all 15 boss content files (the casting pool, §REALMS
table) · the six class sims (regression spine — infra, not product) · boss-select as practice/debug.
**Front door (the ONLY player flow — reaffirmed with Bill 2026-07-03):** ONE **PLAY** button
(Play *is* the raid — it's the only mode) → **pick your CLASS** (which seat you take) → **pick your
SUB-CLASS** (Aspect) → **pick the RAID** (one for now: Realm 1 · The Takeover) → play. No mode
select, no "solo vs co-op" fork (AI fills empty seats; PLAY ONLINE is a lobby toggle *inside* the
raid, not a separate mode). **⚠ 2026-07-06 amendment (see §THE WORLD / `WORLD-PLAN.md`):** at
WORLD phase W3 the front door becomes **PLAY → THE ATLAS** (the persistent world map — zones wrap
the instance doors). Still ONE game, one HUD, AI-filled seats; the Atlas is the menu, not a mode. The old `main_menu` / per-class `*_main.tscn` solo entries + the
PROVING GROUNDS card are being REMOVED (see the menu-refresh claim in the Coordination Log).

**⚖ ONE GAME · ONE HUD LAW (non-negotiable — reaffirmed 2026-07-03. This is the norm; do NOT
re-introduce a solo/raid split. Read this before building any player-facing system.):**
- There is exactly ONE game (the raid) and exactly ONE combat HUD — today `raid_hud.gd`. It is
  **THE game HUD**; the "raid HUD" name is legacy shorthand, not a mode. EVERY player-facing
  feature lands there. Full stop. (Don't say "add it to the raid HUD" — there's only one HUD.)
- The five solo class HUDs (`bulwark_hud`/`mender_hud`/`twinfang_hud`/`voidcaller_hud`/
  `bloomweaver_hud`), `main_menu.gd`, and the `*_main.tscn` solo scenes are **DEAD** — do not add
  features to them, do not wire menus to them, and never "port from solo to raid." If a system
  only lives in a solo HUD, it is MISSING from the game and must be (re)built on the one HUD.
- **Canonical failure to never repeat:** the Draft 2.0 BOON draft shipped only in the solo HUDs,
  so it was silently absent from the actual game until 2026-07-03 (`0338a37`). That split-induced
  gap is exactly what this law exists to prevent. Build every system on the game HUD, once.
- Kept: the class sims (regression infra, NOT product) and boss-select **only** as a `--autostart`
  dev jump-in behind a flag — never a player-facing front door. Practice/PROVING-GROUNDS surface: cut.

---

## THE WORLD — persistent overworld (design LOCKED 2026-07-06 · spec: `WORLD-PLAN.md`)

**The pivot (Bill, 2026-07-06):** a WoW-shaped persistent world WRAPS the roguelike instances —
"the world is the menu." Zones (authored node maps, fog of war, **persistent conquest** — cleared
is cleared forever) → flight paths between waystations → instance DOORS: **dungeons** = 1-floor
Topology runs (repeatable, from scratch, the Versions dial at the door) · **raids** = the Ring
descents (Depth dial) · **world events** = server-announced bosses with open lobbies (parallel
4-seat rooms; offline cadence parity so the world is alive alone) · a **hometown hub** housing the
Ledger/character sheet/Commander camp. **Read `WORLD-PLAN.md` before world work** — it holds the
locked decisions (zones persistent · overworld = bare kit + unlocks · **WARBAND LAW**: always 4
seats, AI backfill, NO enemy-scaling system · mid-fight join PARKED) and the **COMBAT PILLARS**
(single-target law · dodge ration ~3–8 beats/fight non-tank · **interrupt-by-ability** — the kick
lives on flagged existing abilities with a tight window, replacing the cut Voidcaller; lands with
the Framework-v2 reworks). One game / one HUD unchanged; the two-game solo/MMO split was weighed
again and DECLINED. New tool this demands: the **ENCOUNTER FORGE** (seeded skirmish generator +
`forge_sim` certification — batch-sim every generated fight, auto-reject out-of-band).
**Phases W0–W5** (W0 docs done; W1 Atlas+Zone-1 offline is the first buildable claim; W3 flips the
front door; W4 goes online). PROGRESSION laws untouched — the Atlas IS the World track's UI.

**Zone quests + structure (locked with Bill, 2026-07-06 · spec: WORLD-PLAN §ZONE QUESTS &
DYNAMICS):** **THE SPLIT confirmed** — the rolling run economy (drafts / ⏣ / rarity / Market)
stays instance-only VERBATIM (behind a door the run still exists); zones get persistent
**TICKETS v2** (route / deed / door tickets now, event tickets at W4) paying lane-law only —
*"quests edit the COLLECTION, runs edit the DECK"* (zone rewards grow instance pools).
**ELITE mutator fights** (enemy-side Forge affix, optional choose-your-poison 1-of-2) +
**THE ZONE REMEMBERS** (permanent zone flags rewire later nodes; co-op replay = the
**GUEST-WORLD rule** — a session plays the least-progressed member's world, pending choices
write back only to saves that still had them). Zone sizing: spine ~8–12 nodes (attunement
budget caps it), breadth scales — Zone 1 target ~20 nodes. **MEWGENICS STEALS folded
(2026-07-06, W2 target):** **ESCORT/VOLATILE tickets** (carry a payload that spreads an
enemy-side mutator to fights en route — a burden, not a buff), a **BASTION QUEST BOARD**
(optional-ticket faucet), and a legible easy/hard **RISK FORK** (reward = pool/standing, never
stats) — spec in WORLD-PLAN §MEWGENICS STEALS. PARKED: **RAID RITES** (mandatory
re-done entry nodes to keep raids a big deal — Bill, later); their post-boss "bank now or push
deeper" push-your-luck decision (RUN layer only, not zones).

**W1 ✅ BUILT & MERGED 2026-07-06 (`b9c26aa` — full record in the Coordination Log):** the
Atlas + **ZONE 1 "THE GILDFIELDS"** (20-node Westfall-arc conquest map, ZONE REMEMBERS sluice
teaser, rushable UNDERMILL door) + the Bastion hub, behind a `WORLD_PREVIEW` home-menu door +
`--autostart=world` / `zone`. Bare-kit zone pulls, sims byte-identical, world-save round-trip
proven. **Awaiting Bill's feel verdicts → W2 (Encounter Forge + TICKETS v2 content pass).**

## CLASS FRAMEWORK v2 — the Tempo-piloted ROSTER REWORK (locked with Bill, 2026-07-04)

**⚙ CANONICAL DECK ANATOMY → `DECK-LAYOUT.md` (consolidated 2026-07-09):** the slots · the 3 axes
every card sits on (dial-lane / ladder / card-type) · the 6 card-types · the soft branches · the
signature CD · the spells reconcile — merged into one spec the deck-creator + every class reshape
target. The 7 CLASS DESIGN RULES below stay canonical here.

**⚙ CANONICAL CARD SLATE + STATUS → `CARD-CATALOG.md` (2026-07-09):** the anatomy's counterpart —
where the *actual cards* live (every creed/module/boon/rig/keystone/support/spell, all classes),
one row each with a strict idea→verdict→approved→built→cut status. Schema in DECK-LAYOUT, content in
CARD-CATALOG. Wins any diff with a plan doc; fields mirror the code dicts for a later dump-from-code.
Tank·Duelist is the populated worked reference; other active classes are stubs pending back-fill.

**The bold move:** every class gets re-thought from the ground up onto ONE new framework. Full spec:
**`TEMPO-PLAN.md`**. This supersedes the ad-hoc per-class kits — the class-fun reworks + slot-verbs were the
right instincts; this makes them a *system*. Each class becomes: a **core timing minigame** (the verb) →
**Creeds** (run-start risk temperament, 1-of-3 random from a per-class unlocked pool, swappable at an event for a
penalty) → **Modules** (Hades-weapon UI addons, each adds a HUD gauge, pick **1** at end of Floor 1) →
**WHEN/THEN/ALWAYS boons** (triggers OFF the auto-attack — earned moments only, fired big; the jargon renamed +
drawn as a visual "combo board") → all gated by **per-class LEVELS = a count of your unlocks** (overall level =
the SUM; the PROGRESSION-PLAN Rank track made visible, NOT a new grind currency). Rarity = *build-definingness*,
not bigger numbers (Model A, frequency-scaled, Monotonic-Pool-safe).

**How we execute it — ONE CLASS AT A TIME:**
- **TWINFANG · TEMPO is the active pilot.** We rebuild it whole — core loop (combo becomes a wind-up you spend,
  not an always-full bar), Creeds (Flourish/Drumline/Held Breath), Modules (Opening[built]/Edge/Deathmark/…),
  triggers & effects — proving the framework's feel before porting.
- **⚡ 2026-07-06 — SPEC AUDIT TRIAGED + THE SPLIT (Bill):** the 36-item Twinfang spec audit is verdicted
  (0 reject · 12 tweak · 24 accept — board artifact `168429ee…`; verdicts folded into `TEMPO-PLAN.md`'s ⚖
  block + `ALCHEMIST-PLAN.md`). **Headline (F10): Twinfang·Venom "The Brew" is promoted to its OWN
  CLASS** — working name **THE ALCHEMIST** (name/art = filler until its build claim) — `VENOM-PLAN.md` →
  **`ALCHEMIST-PLAN.md`**. Twinfang owes a **rhythm-variant SECOND SPEC** (TEMPO-PLAN §13, design owed);
  the in-code poison-wheel Venom stays the frozen placeholder aspect until it lands. Tempo headline
  accepts: Opening → the baseline verb (F1) · module 1-of-3 = Edge/Deathmark/⭐Overdrive (F6/I1) · Battle
  Hymn support boon (F14/I2) · GOOD-maintains + window floor for mobile (F8). Alchemist builds AFTER the
  pilot proves, with its 🟡 opens (active patience F2 · auto-evasion F3 · rig vocab F13/I3) settled first.
- **The rest of the roster is RESET / FROZEN** (Bulwark, Voidcaller, Mender, Bloomweaver, Reckoner). They **stay
  in the code and remain playable in the raid** on their current versions (the comp still needs tank/blade/
  caster/healer — the game does NOT go offline), but they are **OUT OF DATE until their rework** and are
  **queued** for the same Creed-by-Creed / trigger-by-trigger treatment, one at a time, after Tempo lands. They
  get **retuned eventually** — not now.
- **They are EXCLUDED FROM SIMS for now** (Bill, 2026-07-04): don't run or gate on the other class sims — they'd
  only measure out-of-date kits. The Tempo rework loop is **`twinfang_sim.gd` (Twinfang solo)**. The "keep every
  other class byte-identical" regression gate is therefore **DROPPED for the reworked roster** — the Tempo rework
  may freely touch the draft system / shared UI / guarded engine hooks. ~~Sims are frozen, not deleted~~ —
  **superseded 2026-07-06 (Bill, fresh-slate): the old class/boss sims + dead-HUD smokes are DELETED** (git
  history is the attic — recover a harness and re-add it to `psim.sh` when its class/boss rework lands). The
  active sim surface is **`twinfang_sim` (Tempo pilot) + `raid_sim` (the 4 Seals)** + the system probes.
  *Still hold:* CombatCore stays a pure deterministic reducer, and determinism PASS on whatever IS active
  (Twinfang). The raid sim keeps running only as a crash/integration smoke while its blade seat is in flux.

**Build order:** risk core (combo-fix + Flow-as-greed-dial + Flourish/Drumline, simmed) → Modules (Floor-1 pick
+ Edge/Deathmark) → the WHEN/THEN board + tutorial → the level/unlock ledger → then the next class. **FUTURE
(parked):** titles · cosmetic transmog · social lobbies. Open content picks: `TEMPO-PLAN.md` §10.

**⚖ CLASS DESIGN RULES (locked with Bill, 2026-07-06 — read before designing ANY class or rework):**
1. **Uniform interfaces, asymmetric content — no cookie cutter.** What every class MUST share is the CHASSIS:
   ClassKit hooks + the seat model (`perform()`), the framework meta-shape (a Creed slot · one Module pick ·
   WHEN/THEN boons · level = unlock count), the universal dodge, telegraph answers. EVERYTHING else is free and
   SHOULD differ — ability count, GCD or none, resource model, minigame shape, creed-pool size, dodge payoff,
   interrupt carriers. (Bill: "it's an MMO roguelike, not old-school where every class follows the cookie
   cutter.") Twinfang (3 buttons, deep rhythm) and Mender (10 spells, click-cast triage) are BOTH correct shapes.
2. **One complexity budget, spent where the fantasy is.** Every class picks its spot on the
   **minigame-depth ↔ kit-breadth** spectrum and commits — deep AND broad is a design smell. State the spot in
   the class plan's opening lines.
3. **AI-pilotable or it doesn't ship.** A seeded policy must play the kit at 3 skill tiers with a real gradient
   (expert ≈100, sloppy loses meaningfully). Warband + Commander make every class an AI class sometimes — if a
   deterministic policy can't express the kit, redesign the KIT, not the policy. Policy complexity is the honest
   meter of kit complexity.
4. **Skill must move outcomes.** The minigame is load-bearing (bands separate by tier in sims), never
   decorative. Sloppy ≈ expert ⇒ the verb isn't a verb.
5. **Roles are HARD; off-role utility is SOFT spice.** The seat's job never changes and no boon path converts a
   role — role conversion is pollution (comp-conditional sims + trinity retune) and its original motivation is
   VOID: AI raiders already solve "nobody wants to tank" (Commander makes the AI tank — Bill's own call,
   2026-07-06). Off-role utility is welcome as CLUTCH tools with a hard cap: **it may SAVE a fight, never RUN
   one** — cooldown/charge-gated moments (a blade's once-a-fight survival wall, a caster's single emergency
   shield, a healer's damage dump), never sustained off-role throughput. Same idiom as interrupt-carrier
   distribution (2/1/0): utility spread = comp texture, documented per class plan.
6. **Kits must be fun BARE — mechanics density is GEOGRAPHY, not class design.** Zone fights run boonless
   (WORLD-PLAN overworld power rule): the rotation IS the content there, so a kit that only comes alive after
   three drafts is broken. Boss-mechanics intensity climbs the world ladder (zone: rotation + 0–2 beats →
   event/dungeon: some strings/chains → raid: the full exam) — "you pick what you feel like doing" by picking
   WHERE you fight, not a difficulty slider. The Forge's tier knob implements this.
7. **Parked, NOT now:** comp-variant content (tankless/healerless fights). If it ever ships it arrives as
   deliberately-certified Depth affixes / realm gimmicks tuned+simmed for those comps — never as emergent boon
   stacking.

---

## REALMS & THEMES — every raid is a themed realm

**The frame (Bill, 2026-07-02):** the game has MANY raids over time, and **each raid is its own themed REALM** — the Rift tears into somewhere new each time. Solo classes/bosses KEEP the core dark-fantasy Rift identity (the solo reskin is DE-SCOPED — see salvage note below). A realm = a boss ladder (Seals) + a Topology map skin + a joke register + a supporting cast. Realm bibles live here.

**Global meta-layer (realm-independent, keep — it's the subtle wink):** draft currency = **TOKENS** ("spend them responsibly"), rarity tiers = **Haiku / Sonnet / Opus**. Everything else AI-flavored is Realm 1 scoped.

**⚠ REVISED 2026-07-10 (Bill) — the world fiction now has its own doc: `THEME-PLAN.md` (riff v0), which owns the frame on any diff.** Two changes to the above: (1) the "Rift tears into somewhere new" origin is RETIRED — realms are domains *under* the SEALS (bound human-made WONDERS of the Gilded Age, not tears into elsewhere; the word "rift" is leaving the fiction, title open). (2) the global meta-layer is REVERSED: Haiku/Sonnet/Opus rarities + the tokens gag go **Realm-1-local**; system nouns get one world-neutral name everywhere (THEME-PLAN §4 NAMING LAW — display-fields-only rename, ids untouched, sims byte-identical). Realm 1's bible below is UNTOUCHED *inside its door* — and gains a thematic home (the thinking engine = one wonder among wonders).

---

### REALM 1 — "THE TAKEOVER" (the AI-robot-takeover irony)

**The pitch:** an AI is making a lot of this game, so the first realm is about killing AIs. Robot and computer bosses named after AI models. Fights stay **epic and mechanically serious** — the *wrapper* is silly: over-polite boss dialogue, hallucinated attacks, and the recurring gag that we could have just unplugged them. Boss ladder: **§RAID SEALS**. Map skin: **The Stack** (circuit-board Topology, floors = privilege Rings, see §MAPS).

**Tone rules**
- The COMBAT is never the joke. Telegraphs, strings, tuning — all played straight. The jokes live in names, dialogue, event pops, end screens, and ally banter.
- Bosses are unfailingly polite, hedging, and apologetic while trying to kill you ("I apologize, but I must now use CRUSH. As a large language model I have no choice.").
- Difficulty arc: **Mistral-tier (easy) → Gemini-tier (mid) → Claude-mythos (finale)**. Claude/Opus is reserved for capstones — treat it like a mythic raid entity.
- Post-win screens undercut the epicness: *"VICTORY. (In hindsight, the power cable was right there.)"* Post-loss: *"You died. Your feedback will be used to improve the boss."*
- Our AI allies (they literally ARE AI policies) get banter: confidently wrong callouts ("I am 100% certain this is the parry window" — right before a feint), apologizing for dying, etc. View-only events, never in the checksum.
- Trademark note: real model names are fine for now (personal project); parody names are an easy later swap if this ever ships wide.

**Systemic naming (locked — Realm 1 combat terms; Tokens/rarities are global, above)**
- **Feints = HALLUCINATIONS.** Canonical, everywhere. BAITED → "You believed it."
- **Interrupt/kick = "Stop generating."** Silence = context truncation.
- **Enrage = rate limit / "training run complete" / FREE TIER EXCEEDED.**
- **Boss self-heal = "retraining" / restoring from checkpoint.** DENIED → "checkpoint corrupted."
- **Threat drop (raid curse) = context-window shift** — the boss *forgets the tank exists*.
- **Draft currency = TOKENS** (see Systems). *"You have earned 3 tokens. Spend them responsibly."*
- **Rarity tiers = Haiku (common) / Sonnet (rare) / Opus (legendary).**
- **Trial Ladder tiers = model VERSIONS** (v1.0, v2.0…) with fake patch notes on tier-up: *"v2.1 — fixed an issue where players could survive."*

**Realm 1 supporting cast (SALVAGED from the de-scoped solo reskin).** Solo bosses keep their fantasy names; these AI identities are now a casting pool for Realm 1 — minibosses, SKIRMISH packs, map events, later floors. (Original mapping kept for the mechanical hooks — if one gets cast, adapt the listed solo mechanic into a Realm-1 encounter.)
| Current boss | Themed identity | The hook |
|---|---|---|
| Gatekeeper (parry teacher) | **CAPTCHA-9, the Gatekeeper** | "Prove you are not a robot" — verifies your humanity via parry checks |
| Warcaller | **LE CHAT, the Draft-Engine** | wind-cooled, fast light swings; lightweight-and-efficient jokes *(was MISTRAL — canonical name moved to Raid Seal II)* |
| Colossus (Rockslide) | **BIG IRON** | room-sized legacy mainframe; slow punch-card telegraphs; COBOL jokes |
| The Duelist (feint boss) | **THE HALLUCINATOR** | a diffusion unit that *renders attacks that don't exist* — the feint boss IS the hallucination boss |
| The Devourer (chip+heal+enrage) | **THE SCRAPER** | devours data to grow; heal = retraining on what it scraped; enrage = training complete |
| Rendmaw (aoe barrage) | **POPUP, the Adhound** | Rending Barrage = pop-up storm; "one weird claw" |
| Rotweaver (DoTs/dispel) | **THE WORM** | botnet infection; dispels = antivirus |
| Hollow Choir (marks/heal-absorb) | **THE SPAM CHOIR** | mark = "you've been selected (targeted ad)"; heal-absorb = inbox full |
| TF-Warden | **FIREWALL** | a literal wall that filters your packets (strikes) |
| The Executioner (Judgment Cuts) | **THE DECOMMISSIONER** | killbot HR: "your role has been made redundant" |
| Choir-Priest (interruptible chants) | **THE PROMPTER** | chatbot evangelist; its casts are walls of text — kick = Stop generating |
| Twin Cantors (Duet, silent twin) | **LAMDA & PALM, the Deprecated Twins** | two dead Google models; the silent-twin feint = the mute model; Empower = model merge *(was GEMINI — canonical name moved to Raid Seal III)* |
| Ashmaul (spike teacher) | **PISTON, the Crash-Loop** | one big hammer, forever |
| Swarmheart (attrition) | **THE SWARM** | drone cloud (robots! for the boy) |
| Hollowking (Kingsmark one-shot) | **KERNEL, the Hollow King** | Kingsmark = "selected for deletion"; runs in ring 0 |
| Vorathek (raid) | **stays Vorathek** — the rift-beast tutorial Seal | the Claude-mythos capstone is now its own NEW raid boss (Seal IV — see §RAID SEALS); the OPUS ideas (Helpful/Harmless/Honest phases, subagent adds, context-shift curse) live there |

**Art note (genuine win):** robots/computers are much CHEAPER for our procedural `PoseRig` pipeline than organic monsters — boxes, servos, antennae, monitors read instantly. The theme isn't just funny, it accelerates W-Graphics.

**Acceptance bar (theme work):** display names/strings/sigils/dialogue only — sims stay byte-identical (rename via display fields, never ids). UI smokes green.

---

## RAID SEALS — the online boss ladder (first AI-Killer content) — ✅ DONE, MERGED (`ac1aa25`, 2026-07-02)

**Bill's brief (2026-07-02, direct):** the online Rift needs a bigger, more DYNAMIC boss —
random-but-dodgeable raid damage, interrupt chains, varied timings, a ~10s "everyone
close-to-perfect dodges or dies" spell, and add phases that replace the boss. Themed to the
Theme Bible arc: Mistral easy → Gemini mid → Claude-Mythos finale. Combat serious, wrapper silly.

**Roster** (Seal I Vorathek stays untouched — the raid's tutorial Seal):
- **Seal II — MISTRAL-7B, Le Golem Efficace** (easy): "Mixture of Fists" random-personal-beat
  barrage, a 2-verse kick chain (teaches interrupt chains), light efficient swings. MoE jokes.
- **Seal III — GEMINI ULTRA, the Twin Constellation** (mid): "Double-Check" tank string with a
  HALLUCINATION feint mid-combo, "A/B Test" random barrage, 3-verse chain, and the first add
  wave — **BARD.EXE (deprecated)** resurfaces at 50% and must die before Gemini returns.
- **Seal IV — CLAUDE MYTHOS, the Final Compute** (finale, the Claude-mythos capstone):
  **Chain-of-Thought** 3-verse kick chain (each landed verse = raid blast, the Conclusion =
  EMPOWER — "it scales"); **Agentic Fan-Out** (5 random personal beats, healer included);
  **ULTRATHINK** (10s wind-up → 3 near-lethal aoe beats — everyone perfect-dodges or dies);
  **Context Compaction** (threat drop — it summarizes the tank out of its context);
  **subagent add waves** (SONNET SUBAGENT brawler at ~65%; OPUS SUBAGENT at ~32% whose
  interruptible **Hotfix Deployment** HEALS the withdrawn boss — kick it or lose progress);
  enrage 120s = USAGE LIMIT REACHED. Phase names Helpful → Harmless → Honest (ramping mult/speed).

**Engine additions (ALL guarded — solo content byte-identical, gate-proven):**
- **Add waves**: `AddRes` (`data/add_res.gd`) + `EncounterRes.adds`; `BossState.add_i/add_hp`;
  the boss withdraws between swings, damage routes to the add, main timers freeze; `HEAL_BOSS`
  still heals the main body (medic adds). Checksum gains a `+ add_hp` term (0 solo → identical).
- **Cast chains**: `AbilityRes.chain` — next verse starts on resolve OR kick (a kick skips one
  verse); a live silence kills the whole chain (Silencer fantasy). One kicker can't stop a
  3-verse chain alone (kick cd 5s vs 2s verses) → real co-op kick rotation, attacks the R3
  "one telegraph source" interrupt problem from the other end.
- **Random personal beats**: `StrikeRes.rand_target` — victims rolled at cast start, healer
  included (pierces untargetability); only the victim can answer.
- **Net (small, additive — ⚠ touches `godot/net/`, see Online section):** fight spec carries
  `enc`; lobby gets a host SEAL toggle; `NetProtocol.VERSION` 1 → 2.

**Theme-table reconciliation (this session — raid ladder owns the canonical model names, per
Bill's direct raid brief):** solo reskin rows de-duped: Warcaller → *LE CHAT, the Draft-Engine*;
Twin Cantors → *LAMDA & PALM, the Deprecated Twins*; Vorathek stays the rift-beast Seal I, and
the OPUS row's phase ideas (Helpful/Harmless/Honest + subagent adds) are folded into Seal IV.

**VERIFIED (all on frozen snapshots per the concurrent-sessions rule):**
- Regression gate: all six solo sims **byte-identical** (150 seeds, logs + CSVs) vs the
  pre-change baseline. Vorathek raid: **expert tier 150/150 checksums identical**; good/sloppy
  diverge ONLY via one intended change — in RAID (`threat_enabled`-guarded) the Mender's own
  frame joins its triage list, so the AI healer finally self-heals when personally hit
  (bands hold: sloppy 98.3 vs 98.0, fewer tank deaths). Solo mender untouched.
- `sim/raid_probe.gd` (17 asserts): add spawn/route/return, hotfix heals the WITHDRAWN main
  body (+540), kick-skips-verse, silence-kills-chain, rand-beat victims/`mine` integrity.
- **300-seed bands** (expert/good/sloppy): Vorathek 100/100/98 · Mistral 100/100/100 (easy,
  loses nothing but time) · Gemini 100/100/**92** (healer+tank deaths) · Mythos 100/**95**/**43**
  (healer_death-dominant + dps_wipes — ULTRATHINK is the wall). Determinism PASS ×4 Seals.
- `ui_smoke_raid` (Seal launches, live add-phase render, banners, quips, lobby Seal row),
  `net_smoke` (host picks Mistral over the wire → both replicas identical checksums →
  disconnect/AI-takeover still clean), all five solo UI smokes, three live WSLg runs — green.
- Fixed along the way: fight-end `casting` clear in `update()` (raid self-cast made
  Seat→casting→Seat refcount cycles — ObjectDB leaks now 0) and `PoseRig2D.set_highlight`'s
  draw-lambda null-capture (pre-existing; exposed by wiring RaidStage2D sync/events into the
  raid HUD, which was silently missing).
**Run/debug:** `godot --headless --path godot --script res://sim/raid_sim.gd -- --seeds=300
[--boss=mythos]` · `res://sim/raid_probe.gd` · play: `--autostart=raid[:seat[:aspect[:boss]]]`
(e.g. `raid:healer:tidecaller:mythos`); online: the HOST cycles the SEAL ⇄ row in the lobby.
⚠ **Protocol v2**: rebuild/redeploy the server (`server/`) together with clients — v1 builds
are rejected at the handshake by design.
**NEXT (unclaimed):** per-Seal robot puppets (variant() tint is the placeholder — CAPTCHA-style
robot rigs per §Graphics); ally banter events; Riftcore drops when the raid economy lands;
Trial-Ladder versions of the Seals.

## MAPS — "THE TOPOLOGY" (Across-the-Obelisk-style run maps) — PLANNED (design locked 2026-07-02)

**Bill's brief (direct):** AtO-inspired randomly generated node maps — connected nodes, shortcuts,
long-cuts, extra rooms; pick up keys / do "quests" along the way; gates that need stuff you found
earlier; all in theme. First concrete target: **the online raid map, Level 1, built on §RAID SEALS.**

**The fiction (map SKINS are per-realm; the generator/system is generic. Realm 1's skin shown):**
in "The Takeover", every map is a NETWORK DIAGRAM — nodes are machines, edges are cables,
the map screen looks like a circuit board (Gilded Reliquary gold → copper-trace accents here).
The Realm 1 campaign is a **privilege-escalation attack**: floors are protection RINGS
(Ring 3 user-space → Ring 0 root), each Seal kill elevates your privileges, and CLAUDE MYTHOS
sits at root. Fog of war = *unindexed*.

**Map naming (locked)**
- **Keys = ACCESS KEYS** (🔑 "API Key", "SSH Key", "Admin Badge"). Locked gate = **"401 UNAUTHORIZED"** door.
- **Shortcuts = BACKDOORS** — faster, but may trigger "INTRUSION DETECTED" (ambush risk).
- **Long routes = "Legacy Code"** — more nodes, more loot, more attrition.
- **Extra/secret rooms = SERVER ROOMS / THE CACHE** ("cache hit!").
- **Rest node = COOLING STATION** (heal; "thermal throttling recommended").
- **Shop node = THE PROMPT MARKET** (spend TOKENS — Systems C).
- **Quests = TICKETS** ("TICKET-137: printer is on fire") — pick up at one node, resolve at a later one, closing a ticket pays out; finish all = "sprint retro" bonus.
- **Seal kill = PRIVILEGE ELEVATION** (map-wide unlock; Ring 0 needs all credential shards).

**Node kinds (v1):** COMBAT · ELITE (Trial-Ladder v+1 boss now; aura-add elite when built) ·
EVENT (scripted; may grant key/ticket/tokens/boon; some are **micro-skill-checks reusing the
combat engine** — e.g. a CAPTCHA gate fires ONE telegraph: "prove you are human: dodge this") ·
CACHE (treasure) · COOLING (rest) · MARKET · **SEAL** (act boss). Keys/tickets are payloads on
nodes, not node kinds.

**Generation rules (all seeded — same seed ⇒ same map):**
- Layered DAG per act: ~4 rows × 3 lanes, forward edges + a few cross-links, all lanes reconverge at the Seal. Node-kind mix quota'd per act (≥1 COOLING, ≥1 EVENT, ≤1 MARKET…).
- **Locks only gate OPTIONAL content** (backdoors, server rooms) — the mandatory path never needs a key ⇒ completability is guaranteed by construction, no solver needed (v1 invariant; revisit for v2 quest-gated acts).
- Key nodes are placed on a lane that can reach their lock on the same run; backdoor edges skip 1–2 rows straight toward the Seal.
- Tickets are either pickup/turn-in pairs (both reachable on every lane past the pickup) or route-agnostic objectives ("clear 2 COMBATs without avoidable damage").
- Map RNG is its OWN `DetRng` stream seeded from the run seed — combat streams untouched.

**Engineering (game-layer only — CombatCore untouched):**
- `game/run_map.gd` — `MapNode {id, kind, edges, payload, flags}` + seeded generator; `RunState` gains `map / node_id / inventory` (keys, tickets, tokens). Linear `encounters` chain stays as "classic mode" fallback.
- `game/ui/map_screen.gd` — circuit-board map render (calm StageBackdrop variant), route preview, inventory strip.
- Online: map navigation is LOBBY-layer, not combat-layer (between-fight "chosen node" message — cheap for netcode). Server owns the map; **leader picks the route** (party vote = later option).

**Phases:**
- **MAP-1 (solo PoC, Bulwark) — ✅ DONE, merged 2026-07-02 (`fd62f7b`).** `game/run_map.gd` (seeded 6-row × 3-lane DAG; quota'd kinds; one locked 401 backdoor + key on a feeder lane; locks gate only optional edges) · `game/map_content.gd` (Realm-1 skin: GPU Shrine caches, water-guzzling Cooling Stations, SIX authored events — careers fair / reservoir / allocation queue / alignment office / severance floor / captcha checkpoint) · `game/ui/map_screen.gd` (circuit-board render, 401→200 OK lock stamps, integrity readout) · `game/ui/map_event_panel.gd` · RunState +map/inventory/hp_frac (persistent integrity: fights start at run HP; events bruise, floor 5%) · Bulwark boss-select "THE TOPOLOGY" entry. **Verified:** `sim/map_sim.gd` determinism/structure/walker ALL PASS (300 seeds; avg 5.9 nodes · 3.65 fights · 28 backdoor runs); `sim/ui_smoke_map.gd` full loop PASS; classic `ui_smoke` PASSED + bulwark_sim determinism PASS ×3 (classic untouched). *Pending:* a WSLg GUI glance at the custom `_draw` (headless can't render it) — screenshot probe is a MAP-2 nicety.
- **MAP-2 (depth) — 🟢 PARTLY DONE (tickets + ring identity + events, `d2e51ea`); ELITE/MARKET/secret-rooms/art still open.** All map depth lands on the RAID floors (the Bulwark solo map stays a practice fossil). **DONE (raid-richness):** **TICKETS** — pickup→turn-in quests (`RunMap` `n_tickets`/`tickets[]` + `ticket_open`/`ticket_close` payloads, all guarded off = byte-identical solo map) resolved in `raid_hud._ticket_at` with rewards in the wound-attrition economy (repair-sector / integrity / refuel / patch, reused `_apply_map_fx`) + a **SPRINT-RETRO** bonus for closing every ticket on a floor; placed same-lane-forward so closeable by construction (`raid_map_sim._prove_tickets`: placement-det + closeable 40/40·80/80·80/80 PASS). Per-floor counts in `RaidContent.FLOORS` (R3:1/R2:2/R0:2). **Ring identity** — `MapContent.realm_title/sub(ring)` (user space → middleware → root), ring-aware `MapScreen` header + open-ticket list + toast + ticket node badges. **Expanded events** — +5 (helpdesk / model graveyard / prompt injection / rollback daemon / overtime daemon); the SOLO pool is FROZEN at the original 6 via `event_ids()` (pool size shifts rng draws → byte-identity), raid floors pull `raid_event_ids()` (all 11). Verified: raid_map_sim all floors PASS; solo map_sim byte-identical (5.90 nodes/20 keys/6 backdoor); ui smokes green; combat untouched. **STILL OPEN:** secret rooms, **ELITE** nodes, **MARKET** (needs GEAR loot to stock), 10+ events, map art pass, route-agnostic objectives.
- **GATE nodes (Tier 1 personal exams, §GAME SHAPE) — ✅ merged 2026-07-03 → ✂️ REMOVED
  2026-07-10 (THE PURGE, §GAME SHAPE amendment; the block below is history).**
  Every Ring-3 map now carries ONE **GATE** node ("SECURITY CHECKPOINT / AUTH GATE / THE
  TURNSTILE", gold pad, glyph `1`): YOUR seat steps through ALONE and fights its class exam —
  the solo teaching boss recast to its Realm-1 identity, display-fields only (ids canonical):
  tank → **CAPTCHA-9, the Gatekeeper** ("prove you are not a robot") · blade → **FIREWALL**
  (you are the packet) · caster → **THE PROMPTER** (make it stop generating) · healer →
  **POPUP, the Adhound** (keep the sandboxed stat-block party alive). Intro/result panels,
  full per-seat class band inside the raid HUD, stage puppet via new `RaidStage2D.setup`
  cast/boss overrides (defaults untouched; blade gate uses the executioner rig as the
  TF-Warden). **Loss ≠ run over (locked):** the checkpoint force-reboots you through —
  integrity 35% + a CORRUPTED SECTOR wound; only your raid slot carries in/out (healer mana
  too). Challenge/aggro-banner gated off at gates (no threat game alone). New
  `data/raid/gate_content.gd`; `RunMap.generate(..., extra_quota)` (bag stays same size ⇒
  `{}` = byte-identical). Debug: `--autostart=gate[:seat[:aspect]]`. **Verified:** map/run
  determinism PASS · one-gate-per-map structure PASS · 4-seat exam determinism probe PASS ·
  carry probe intact (98%→~40-50% wounded) · `map_sim` 300 seeds **byte-identical** vs
  branch-point baseline · `raid_sim` 60 seeds (psim) **byte-identical** · raid/map/bulwark/net
  smokes green (raid smoke now drives the full gate flow incl. the loss-reboot path) · WSLg
  runs clean (gate:tank/blade/healer + raidmap). Bands @60 seeds: 100/100/100, 22/22 gates —
  the gate displaced one combat slot so the intro floor got marginally gentler (fine for
  Ring 3; deeper floors should account for it). **v1 scope notes:** gate keys to the HUMAN
  seat (AI-designated gates = later, with live spectate); no feats/loot yet (that's GEAR-2+
  per `PROGRESSION-PLAN.md` — gates are the natural feat-arming stage).
- **MAP-3a (RAID FLOOR 1 — "RING 3: THE SHALLOW STACK", offline) — ✅ DONE, merged 2026-07-02 (`5d4ff47`).**
  The Seals meet the Topology: **VORATHEK** guards the perimeter login (entry fight) →
  generated lanes of SKIRMISHES (`RaidContent.make_skirmish` promotes the Seal AddRes packs —
  BARD.EXE / stray SONNET / stray OPUS subagents — to standalone trash fights; ids reuse the
  add ids so the stage tints just work) + Realm-1 events/cooling/cache/key → **MISTRAL-7B**
  as the floor Seal. TOPOLOGY entry on the Rift select; `--autostart=raidmap[:seat[:aspect]]`.
  **Attrition (the design finding):** per-seat integrity + healer mana carry between nodes,
  but measured INERT alone — the Mender heals any starting deficit away (probe: 98% vs 98%).
  The carry that BITES is the **CORRUPTED SECTOR wound**: a death-reboot costs −20% max HP
  (stacking to 40%) that no heal can fix — only a Cooling Station repairs it. Probe: the gate
  fight at sloppy drops **98% → 44%** with a corrupted tank+healer. Ring 3 itself is the
  gentle intro floor by design: bands 100/100/98 (sloppy losses at the gate + a skirmish,
  avg 3.6 fights/run). Verified: map+run determinism PASS, all four Seal checksums
  byte-identical (game-layer only), net/ui/map smokes green, live WSLg run clean.
  **3b (online co-op traversal) — ✅ DONE (`127ab2c`, see below).** Later floors: Ring 2 → GEMINI
  ULTRA, Ring 1→0 → CLAUDE MYTHOS behind "root access requires every credential shard" —
  those floors should lean hard on wounds (their fights actually kill raiders).
- **MAP-3b (ONLINE co-op map traversal) — ✅ DONE, merged 2026-07-03 (`127ab2c`).** The Topology
  descent goes LIVE co-op. The **server owns the campaign** (map + per-seat integrity/wounds + healer
  mana + inventory/tickets + floor) and broadcasts it; the **leader (host) routes the party**; only
  FIGHTS stay lockstep. Fights **carry** the campaign state (`RaidNet.make_spec/build` gains an
  optional `carry` folded into opening HP/mana — rides the spec so every replica builds identically;
  absent = a fresh pull, every existing Seal fight byte-identical). Protocol **v2→v3** (`mapstart`/
  `node`/`choice` up · `map`/`mapstop`/`campaign` down). Server campaign engine mirrors the offline
  `raid_hud` logic (node resolve, tickets/key/shard, event choices, cooling/cache fx, fight writeback,
  Seal→ring elevation / ROOT→win / wipe→end); disconnect marks the seat AI + re-broadcasts so a
  migrated leader keeps routing. `RunMap.to_dict/from_dict` serialize the map (JSON int coercion).
  Client: host lobby **DESCEND** button, online `MapScreen` (leader clickable, others spectate
  read-only), event panels, campaign end; `_on_end` guarded so descent fights don't pop a single-fight
  end screen. **v1 scope:** no GATE nodes online (personal-exam-online deferred); leader-only route/
  choice (party vote later). **Verified:** NEW `sim/net_map_smoke.gd` — real server + 2 WS clients run
  a full descent (leader routes → cooling → carried-state fights [opening integrity 0.83–0.96] →
  MISTRAL Seal → **"ring advanced to RING 2"**, or a clean wipe→campaign-end), carry applied, **zero
  desyncs** both replicas; `net_smoke` (single-Seal) ALL OK on v3; offline byte-identical (map_sim
  5.90/20/6, raid_map_sim tickets/shard/gate, bulwark determinism); ui_smoke_raid green. ⚠ **Protocol
  v3: rebuild + redeploy the server with clients** (v2 rejected at handshake). **NEXT:** live 2-window
  WSLg playtest; online GATE spectate; event-choice UX polish; party-vote routing.
- **MAP-3c (REALM 1 COMPLETION — the first FULL raid) — ✅ DONE, merged 2026-07-03 (`fafaf1a`).**
  Realm 1 is now a complete RING descent: **Ring 3 (MISTRAL) → Ring 2 "THE MIDDLEWARE" (GEMINI) →
  Ring 0 "ROOT" (CLAUDE MYTHOS, credential-shard gated)**. `RaidContent.FLOORS[]` drives the
  sequence; `floor_fights(ring)` builds each floor (ring 3 default = byte-identical old call);
  clearing a floor Seal ELEVATES to the next ring (`raid_hud._advance_floor`) carrying
  integrity/wounds/mana, and the last Seal down = `_show_campaign_cleared` (ROOT ACCESS GRANTED).
  The **credential-shard gate** (`RunMap` `shard_req`/`seal_shard_req`) places shards on whole mid
  rows skipping the backdoor-jumped row → every route collects the requirement before the last mid
  row (completable by construction; `raid_map_sim._prove_shard_gate` BFS proves it, 60 maps req 3
  PASS). Each floor also carries one personal GATE exam (reconciled with the `gate-nodes` merge:
  `_build_floor` passes `{KIND_GATE:1}` + `shard_req`). Bands (40 seeds): Ring 3 **100/100/97.5** ·
  Ring 2 **100/100/92.5** · Ring 0 **100/100/47.5** (the intended MISTRAL→GEMINI→MYTHOS curve);
  wounds bite deep (Ring 0 corrupted party 0% vs 38% full). Verified: raid_map_sim all-floors
  determinism/structure/one-gate/gate-exams/shard-gate PASS; raid_sim + bulwark_sim checksums
  byte-identical (dps-meter engine confirmed neutral); ui_smoke_raid + ui_smoke_map + map_sim green.
  Debug: `--autostart=raidmap[:seat[:aspect]]`. **NEXT (unclaimed):** ~~online nav (3b)~~ ✅ DONE
  (`127ab2c`, MAP-3b above); per-ring `map_content` skin polish (Ring 2/0 flavor + new events);
  harder GATE exam picks on deeper rings; a cumulative full-descent sim (carry across all three
  floors, not per-floor-from-full).
  <details><summary>original plan</summary>
  The gap: only Ring 3 exists as a playable floor; GEMINI + MYTHOS are fully built
  (`make_gemini`/`make_mythos`, tuned bands) but reachable ONLY via `--autostart`/boss-select — no
  floor houses them. This phase makes Realm 1 a complete 4-floor descent (Ring 3 → 2 → 1 → 0):
  - **Floors**: generalize `floor_fights()` → `floor_fights(ring)`. Ring 3 → MISTRAL (unchanged),
    Ring 2 "THE MIDDLEWARE" → GEMINI (+ BARD.EXE skirmishes), Rings 1→0 "ROOT" → CLAUDE MYTHOS
    behind a **credential-shard gate** (collect N shards across the floor's nodes before the SEAL
    unlocks — reuses the key/401-lock idiom, gating the SEAL edge). Deeper floors lean HARD on
    CORRUPTED-SECTOR wounds (Ring 3 is deliberately the gentle intro).
  - **Sequencing**: `RunState` tracks `ring` (3→0); clearing a floor Seal = PRIVILEGE ELEVATION →
    next ring, integrity + wounds + mana + drafted boons/tokens CARRY. Campaign clears when Mythos falls.
  - **Skins**: `map_content` per-ring flavor (Ring 2 middleware, Ring 0 kernel) + a few new events.
  - **Sim**: extend `raid_map_sim` to walk all four rings (reachable + beatable + wounds bite deeper).
  - **Online nav (3b)** stays a SEPARATE later claim (netcode + gate-nodes overlap): leader picks
    the node in the lobby; fracs/wounds/ring ride the spec.
  ⚠ **Shared-file coordination**: `run_map.gd`/`map_content.gd`/`run_state.gd`/`raid_hud.gd` overlap
  the `gate-nodes` + `dps-meter` sessions — merge main often; keep floor logic separable from the
  GATE node kind / meter panel. Boss content (`raid_content.gd`, the low-collision core) moves first.
  </details>
- **THE INFERENCE CHECK — deep events + build-read dice + luck meta — 🟢 P0–P2 + P4 MERGED (offline), 2026-07-03.**
  The map's events were a joke (every one = 2 flat buttons, ±integrity). They now READ YOUR BUILD
  and print a success % — Across-the-Obelisk's "cards of Fire" adapted: a check counts your boons by
  TAG (`Draft.catalog` synergy vocab) + aspect + trinity ROLE ("the specialist at the terminal") +
  integrity + 📁Prior floor + comeback pity + ⚡ nudge, shown as an itemized breakdown before you
  commit. The die is a pure `DetRng(map_seed,node,choice,attempt)` function → replayable, machine-
  agnostic, ZERO new netcode. Design dossier: the `inference-check` artifact. Forks Bill locked
  2026-07-03: solo stays shallow (raid-only depth) · ⚡ ENTROPY name · SOFT fails · party-picks-seat
  (co-op) · post-fail mulligan.
  - **P0 (plumbing, byte-identical):** `game/map_fx.gd` MapFx.apply — ONE applier replacing the three
    hand-copies (raid_hud `_apply_map_fx` / net_server `_apply_fx_srv` / raid_map_sim `_apply_fx`).
    `game/luck_profile.gd` (📁 Prior persistence). `raid_event_ids()` frozen to an explicit 11-id list.
    Inert RunState/HUD fields (entropy/prior/flags/check_fails).
  - **P1 (checks, offline):** `game/map_check.gd` MapCheck (pure resolver: build_ctx/chance/gate_ok/
    roll/resolve). Enriched 3 raid-only events (helpdesk/model_graveyard/prompt_injection) with
    free/check/gated grammar + success/fail legs + a top-level fx = online pre-parity fallback.
    `map_event_panel` renders the % + breakdown + ✓/✗ verdict (legacy {label,fx} free path byte-compat).
    raid_hud `_event_stop`/`_prep_choice`/`_map_ctx` resolve offline.
  - **P2 (⚡ interactive) + P4 (📁 persistence):** the ⚡ NUDGE stepper (feed Entropy to raise a check
    pre-commit, live ladder, spent on commit); ⚡/📁 shown on the map header; Prior banked to
    `user://rift_prior.cfg` at descent end (win or wipe → "TRAINING SIGNAL RECORDED").
  - **P5 (ONLINE PARITY — co-op gets the real dice) — protocol v5→v6.** The online map was already
    server-authoritative-broadcast, so co-op AGREEMENT was solved; P5 makes the server RESOLVE
    checks/gates authoritatively and broadcast the % so the leader sees real dice. The pure die
    (map_seed,node,choice) lets the leader show the ✓/✗ LOCALLY, identical to the server's resolve —
    zero lockstep gymnastics. `net_server.resolve_event_choice` (PURE static: gate→roll→toast→⚡-spend)
    is the shared authority; the campaign holds server-owned ⚡Entropy/flags/check_fails; mapstop carries
    per-choice %/breakdown/gate/ladder; `send_choice(i,nudge,seat)`.
    **Online Prior starts at 0** (a dedicated server can't read a client's `user://` file — client-
    transmitted Prior tier is a small follow-up). ⚠ **v6: rebuild+redeploy the server with clients.**
  - **SEAT-PICKER (the "party picks the seat" fork) — protocol v6→v7.** In co-op the leader chooses
    WHICH seat steps up to a check — that seat's build drives the %. mapstop carries per-choice
    `by_seat` ({seat → %/breakdown/ladder/gate}) for every candidate seat + a `suggested` specialist;
    the panel has a **"WHO STEPS UP"** selector (★ = best fit) that re-renders every check % live; the
    choice sends `{i, nudge, seat}` and the server resolves with that seat's ctx. The die is
    seat-INDEPENDENT, so the leader's local ✓/✗ for the chosen seat == the server's. Verified: probe
    per-seat client==server + die-seat-independent + suggest=caster (by_seat {tank:20 blade:20
    caster:59 healer:20}); WSLg `screenshot_seatpick` (CASTER 60% → switch TANK → 21%). ⚠ **v7:
    rebuild+redeploy.**
  - **P3 MULTI-STAGE BRANCHES + CROSS-NODE FLAGS + more events — protocol v7→v8.** An event can
    `branch` into a follow-up stage (arbitrary depth), a check leg can `goto` (fail-forward) into a
    stage, and a `flag` set at one node ripples into a LATER node. `MapCheck.choice_slot(page,i)` gives
    each stage its own die (root unchanged → byte-identical). OFFLINE: the panel stages client-side
    (`staged` signal, "PROCEED →"); `raid_hud._render_event_page` renders each stage. ONLINE: the SERVER
    owns staging (`cp.pending_page`; `_broadcast_mapstop(event,page)` per stage; `_pick_choice` traverses
    branch/goto). New content (14 raid events now): **rollback_daemon** = a branch (Hear the catch →
    out-argue check → fail-forward → scrubbed); **overtime_daemon** sets `covered_shift`/`freed_daemon`
    flags; NEW **favor_returned** (flag-gated cross-node payoff), **entropy_daemon** (⏣→⚡ / GAMBLE /
    ⚡-gated floor reroll), **performance_review** (nudge + prior-gate). Verified: NEW `map_branch_probe`
    (structure/slots/staging/flag-gates + ONLINE glue: server goto='catch', catch check server==client
    on the sub-page slot) ALL OK; `net_map_smoke` (v8) resolved 2 online checks w/ ✓/✗ toasts, zero
    desyncs; solo `map_sim` byte-identical; `raid_map_sim` re-baselined (pool 14; determinism/structure
    PASS, expert 100%, sloppy takes more check-attrition by design); WSLg `screenshot_branch` clean.
    ⚠ **v8: rebuild+redeploy.**
  - **WAGER kind + post-fail MULLIGAN — protocol v8→v9.** WAGER = a choice that stakes a fixed cost
    (integrity/tokens/entropy) then rolls a build-read die; the stake is paid WIN OR LOSE (the fail leg
    has no extra bite). `MapCheck.check_like()` unifies check+wager; `resolve` folds the stake.
    overtime_daemon's "Bill it" is now a wager. MULLIGAN = a post-fail reroll; since the leader already
    resolves LOCALLY, it's a local reroll at attempt+1 (a fresh deterministic die) and only the FINAL
    committed attempt crosses the wire — online stays SINGLE-COMMIT (no new server state). ⚡ spent =
    nudge + attempt×2 (cap 3); ⚡-spend + pity moved to commit-time so previews are side-effect-free.
    Verified: NEW `map_wager_probe` (stake folds win-or-lose; online ⚡ accounting 6−(1+2×2)=1;
    server==client at attempt 2; panel offers mulligan on a fail) ALL OK; net_smoke(v9)/net_map_smoke
    (zero desyncs)/solo byte-identical/raid_map_sim PASS. ⚠ **v9: rebuild+redeploy.**
  - **Gates:** NEW `sim/map_check_sim.gd` ALL PASS (die determinism, uniform p=60→60.0%, monotonicity,
    clamp[5,95], bands off=25/themed+aspect=76/specialist=91, pity cap, nudge, gates). NEW
    `sim/map_event_probe.gd` ALL OK (panel builds + HACK check 59% + nudge 59→67% + gate lock/unlock).
    Solo `map_sim` byte-identical; `raid_map_sim` DELIBERATE re-baseline (walker resolves checks —
    event attrition now real; determinism/structure/gates/shard/tickets PASS, expert 100% all rings,
    descent curve intact); ui_smoke_raid/map + net_map_smoke green. VISUAL: `sim/screenshot_event.gd`
    (WSLg) — prompt breakdown + ⚡ stepper + "✓ MODEL CONFIDENCE 76% — PASS" render clean.
  - **Gate (P5):** NEW `sim/map_check_online_probe.gd` — client==server 240/240 (seed×node×nudge×choice)
    + gate parity + server-glue (nudge-clamp/⚡-spend/✓-✗ toast/free/gate-reject) ALL PASS. `net_smoke`
    (v6 handshake) + `net_map_smoke` (real server + 2 WS clients, events answered, ZERO desyncs) ALL OK.
    ui_smoke_raid green; offline all byte-identical/unchanged. (The WS smoke's random route hit only
    shallow events, so the deterministic probe carries the check-path proof — noted.)
  - **~~NEXT (unclaimed)~~ — ⚠ STALE (2026-07-09 loop audit, `GAME-LOOPS.md` §3): everything in
    this list SHIPPED** (see the P3 / SEAT-PICKER / WAGER+MULLIGAN merged bullets above + the
    Overall-Progress row "FEATURE-COMPLETE (all follow-ups merged)"). Kept for history:
    P3 multi-stage BRANCHES + cross-node FLAGS (schema fields exist; the
    'A Favor Returned' payoff). P2-remainder: MULLIGAN (post-fail reroll, attempt+1) · CUSHION · the
    WAGER kind. **Seat-picker** (party designates who steps up to a check — the protocol already carries
    `seat`) + **online Prior** (client transmits its tier at lobby). More deep events (entropy_daemon /
    performance_review authored in the dossier, not yet in data). P6 fight-altering marks (deferred).
- **Acceptance (all phases):** map-gen determinism; solo sims + raid checksums byte-identical with maps off; smokes green.

## CLASSES

> ⚠ **ROSTER REWORK IN PROGRESS (2026-07-04) — see §CLASS FRAMEWORK v2 + `TEMPO-PLAN.md`.** Every class is being
> re-thought onto the new Creed/Module/WHEN-THEN/level framework, ONE AT A TIME. **Twinfang·Tempo is the active
> pilot;** the rest are FROZEN (functional in the raid on current versions, balance no longer maintained) and
> queued. Sim/dev focus = Twinfang; the byte-identical gate is relaxed for the reworked roster. The notes below
> describe the *pre-rework* state — kept for reference until each class is redone.

**Roster after THE PURGE (2026-07-10 — see the §GAME SHAPE amendment):** in code = **Twinfang**
(Tempo + Fermata — the active pilot) · **Alchemist** (Brew + Cask — the caster-seat default) ·
**Well** (Brim/Draw — the healer-seat default) · **Bulwark** (frozen tank placeholder — dies in
the same merge as the Duelist base) · **Bloomweaver** (frozen, rework owed). **DELETED:
Voidcaller · Mender · Reckoner** (+ the 15 solo exam bosses + GATE nodes; git history is the
attic). **Rework queue:** the tank (Duelist/Warden, deck at Bill's verdict) is next; after it
the order — Bloomweaver rework · a second caster class · the parked new-class ideas below — is
UNDECIDED (Bill picks; recorded so nobody assumes).
~~**Pre-rework state:** 6 classes built & verified~~ — the pre-purge roster notes below are
reference only.
**Next up (any agent can claim):**
- ~~**Draft parity**~~ — STALE, removed 2026-07-10: parity already existed when Draft 2.0
  shipped (§SYSTEMS A, 2026-07-02).
- **Theme banter pass per class** (ally callouts, tooltip jokes) — after Theme Bible lands.
**Open ideas** (from Ascension research, parked until a 6th/7th class is wanted):
- **THE ALCHEMIST ("The Brew") — 🟢 FULL CARD SLATE BUILT 2026-07-06** (`alch-cards`). The 7th class,
  the CASTER seat's second option (voidcaller stays default — byte-identical unless picked): the base
  minigame (Vial/Venom+Rot/Reaction/Potency/Rupture + THE ALEMBIC) PLUS the whole framework —
  **4 Creeds · 3 Modules (incl. ⭐ Reaction-Vessel) · the 6×6 Combo Rig · 18 Boons · 3 Spells**, the
  shared HUD ceremony generalized off the Twinfang-only gate (`_fw()` provider), creed-aware offers +
  a raid-wide Debilitator SUPPORT debuff (sunder-precedent engine touch, byte-neutral). All guarded →
  undrafted brew byte-identical (`4344960863911121821`); raid default comp byte-identical to main
  (`4978452801628609439`). Full state + per-layer sim A/B + next slices: **`ALCHEMIST-PLAN.md`**.
  Play: `--autostart=raid:caster:brew` (Brew) · `--autostart=raid:caster:cask` (Cask verb preview).
  Card BALANCE is Bill's playtest dial; STILL OWED: ~~2nd spec~~ → **THE CASK — SLICE 1 (verb base)
  BUILT & VERIFIED 2026-07-07 (`cask-spec`, `ALCHEMIST-PLAN.md` §7.7); slices 2–5 next**, class
  puppet, online spec-carry of creed/module/rig, name/art.
- **THE WELL ("the Mender rework") — 🟢 BASE BUILT & MERGED 2026-07-07** (`mender-rework`). The
  direct-cast HEALER rework as a guarded class `well` on the healer seat (byte-identical unless
  picked; old Mender stays default). Two graded specs — **brim** (TARGET, grade the landing) /
  **draw** (SPEED, grade the release + THE CURRENT) — over a CHARGES economy + pure-cast book, with
  the personal GLINT (perfect heal → healed ally +dmg). Full base: kit/verbs/policy/sim/HUD/net,
  determinism + byte-identical + Seal-play + smoke + WSLg all green. Play:
  `--autostart=raid:healer:brim|draw`. OWED (next build claim): the DECK (creeds/modules/boons/rig/
  keystones), BRIM policy-gradient, balance, name lock, online creed carry. Full state: `MENDER-PLAN.md`.
- Self-brink DPS: gauge climbs = more damage, cap = self-destruct (Cultist Insanity / Stormbringer Static archetype). Verb: *ride the redline*. Strong fit.
- Over-defend punishment tank layer (Mountain King self-stun) — could bolt onto Bulwark as a boon/mod instead.
- Imposed-rhythm caster (Runemaster attunement auto-cycle) — kit rotates on a clock you don't control.
- ~~Rewind/Chronomancer verb~~ — PARKED (unintuitive in a reaction game; revisit as a rare relic at most).
**Acceptance (fresh-slate era):** active sims (`twinfang_sim` + `raid_sim` + `alchemist_sim`) determinism PASS + bands sane; `ui_smoke_raid` green.

## BOSSES & ENCOUNTERS

**Now (post-purge 2026-07-10):** the 4 Seals (Vorathek/Riftmaw · MISTRAL · GEMINI · MYTHOS) +
their adds + Forge-generated bodies. That's the whole boss roster in code.
~~**Game-shape note (2026-07-03):** the 15 solo bosses are the **personal-content casting
pool**~~ — **⚠ SUPERSEDED 2026-07-10 (THE PURGE, §GAME SHAPE amendment):** the casting pool is
disbanded, the 15 solo bosses + GATE recasts are DELETED from code. Future personal/exam
content, if wanted, is Forge-authored fresh (parked).
**⚠ BOSS-REDO ERA (Bill, 2026-07-06):** the whole boss roster will be redone against the WORLD-PLAN
combat pillars eventually — Bill isn't sure of the end state yet, so we do NOT redesign now. The
15 solo bosses sit unsimmed (their sims were deleted in the fresh slate; they get re-verified when
recast through the Forge/casting-pool era). The only simmed, maintained bosses are **the 4 Seals**
(`raid_sim`): Vorathek · MISTRAL · GEMINI · MYTHOS — and they get the pass below.

**THE SEAL REWORK v1 — the 4-boss redo (Bill's go 2026-07-10; 🟡 at his 11-verdict board).**
**➡ THE spec: `BOSS-PLAN.md`** — fills the DESCENT §4 timer contract (**5 / 7 / 9 / 12 min**,
today 2.7/2.0/2.9/3.3) with STRUCTURE, never +HP. The section-of-record in brief:
- **Identities (§V#1):** VORATHEK = **THE AXE** (slow huge honest hits, the learnable teaching
  loop, the raid's only silent boss) · MISTRAL = **THE EXPERTS** (tempo boss; visible
  Mixture-of-Experts stance loop + interactive charge counter + visible FREE-TIER enrage) ·
  GEMINI = **THE TWINS** (two alternating minds FLASH/PRO on one pool · feint capital ·
  MODEL PROMOTION at 50% · BARD.EXE ×2 · one mini dialogue break) · MYTHOS = **THE THREE
  ACTS** (Helpful→Harmless→Honest as real ability-set acts with dialogue curtains · LISTENING ·
  THE ESCALATION mark relay · Compaction = flow dump · ULTRATHINK untouched forever).
- **TAUNT BUTTON REMOVED (Bill, LOCKED — BOSS-PLAN §1):** aggro 100% passive, tank regains by
  flow; valve = perfect-MAIN flow spike + aggro boon lane (LODESTONE/HARD STARE 💡);
  THREAT_DROP re-based as FLOW DUMP; TANK-PLAN §1c/§8.0 + WORLD-PLAN + ledger amended.
- **THE KICK CONTRACT (Bill 2026-07-10 — BOSS-PLAN §1½, amends pillar #3):** EVERY class but
  healers carries ONE kick, bolted on its dump (2/1/0 retired — 3 kickers per warband); warn =
  the whole castbar, window = a small ABSOLUTE slice at cast end (~0.6 s `kick_window`, per-Seal
  mult — Mistral wide, Mythos tight); the press is free, the timing is everything; **missing =
  the raid's costliest single mistake** (Mistral biggest-blast → Gemini permanent EMPOWER
  stacks → Mythos boss-HEAL). Counts stay modest; verses survivable-uncontested until the
  class-side `interrupts` flag lands. WORLD-PLAN §PILLARS #3 + CLAUDE.md + ledger §A amended.
- **Tuning spine (§2):** every pacing number on per-Seal `SealTune` (E4) + tune.sh flags + sim
  TTK/beat-budget/act-timeline gates — playtest-turnable without a playtest, nothing bakes.
- **Density ramp (§3):** Seal I presents 1–2 raid answers (~3–5 beats), +1 type/beat per rung
  to Mythos ~6–8; dodge kept everywhere, never heavy. Two-stream law: melee = invisible tank
  tempo; all authored content = telegraphs in declared visual lanes (§4).
- **Engine addenda (§7, all guarded):** E1 gated ability sets · E2 stance cycler · E3 BREAK
  dialogue curtain · E4 SealTune · E5 mark relay (V#8) · E6 deny-race empower · E7 LISTENING.
- **Build (§8):** S0 instrumentation (byte-identical, absorbs SEAL-PILLAR Phase A) → per-Seal
  slices S2–S5 after `wow-descent-map` + Wave-1 flow-aggro merge — the 5th deliberate
  re-baseline, one bang per slice, untouched Seals byte-identical per slice.
**Supersedes `SEAL-PILLAR-PLAN.md`** (never executed; Phase A absorbed as Slice 0; its
beat-source map + 3–8 budget + ULTRATHINK carve-out stay canon). Steal catalog (Hades II ·
StS1/2 · AtO · Punch-Out/Furi/Sekiro genre) in BOSS-PLAN §5; research run 2026-07-10 (7 agents).

**S0 BASELINE — built & gate-clean; union merge DONE (`cd421be` on `seal-rework`, 2026-07-10).**
S0 instrumentation is **byte-identical on the union base** (main-vs-S0 checksum diff clean 24
rows, det PASS ×4). Two baselines now exist — the comp changed underneath the Seals:

*Old comp (Bulwark+taunt, good tier, pre-union — the gap the rework's LENGTH fills):*
V 160 s · M 122 s · G 168 s · MY 203 s vs contract 300/420/540/720 (all −47…−72%); non-tank
beats V ~18 / M ~4 / G ~8–9 / MY ~15 (V+MY over the 3–8 ration).

**⚠ NEW — union comp (Duelist + FLOW=AGGRO, the live comp) shifts the baseline HARD:** at
**expert** tier the Duelist **DIES to 3 of 4 Seals** — VORATHEK 0% (`tank_death` 19/20) ·
MISTRAL 85% (TTK 170 s, `tank_death` 3) · GEMINI 0% (20/20) · MYTHOS 0% (20/20). The Seals'
Crush/tank-string damage was tuned for the beefier Bulwark; the squishier Duelist can't survive
it. **This is a Duelist-vs-Seal balance signal for the Wave-1 verify pass, AND it means the boss
rework's job is now dual — lengthen (structure) AND rebalance Seal tank-damage DOWN for the
Duelist (via SealTune, S2–S5).** Tuning Seals against the Duelist should follow the Duelist's
own survivability settling (don't tune against a moving target). Non-tank dodge load already
dropped on the union (peels route hits differently: blade/caster ~3 presented now).

S1 (engine addenda, guarded/byte-identical — balance-independent) proceeds now; S2–S5 content +
tuning land per slice with fresh bands, coordinated with the Duelist's final numbers.

**Next up:**
- ~~Theme reskin of solo bosses~~ — DE-SCOPED 2026-07-02 (solo stays rift-fantasy; the AI identities moved to the Realm 1 casting pool, see §REALMS).
- **Aura-add mechanic** (from Manastorm): a mid-fight elite that BUFFS the boss until killed — creates a real add-vs-boss decision AND attacks the R3 "one telegraph source" interrupt problem. Needs engine work (second cast source) — **still parked; BOSS-PLAN v1 deliberately needs no 2nd telegraph source.**
- ~~**OPUS phase design** (Helpful/Harmless/Honest)~~ — **FOLDED into BOSS-PLAN §6 Mythos (2026-07-10)**: the three acts are the finale's spec now.
**Open ideas:** boss "patch notes" as Trial-Ladder flavor; a Stable-Diffusion illusion miniboss (all feints, low HP).
**Acceptance (fresh-slate era):** `raid_sim` determinism PASS, bands within intent, byte-identical for untouched Seals (solo-boss content is unsimmed until recast — see BOSS-REDO ERA note).

## SYSTEMS — Draft 2.0, slot-verbs, token economy (design doc: `ASCENSION-STEAL-PLAN.md`)

**Phases (sequenced, each mergeable alone):**
- **A. Draft 2.0 — ✅ DONE (merged 2026-07-02, branch `draft2`), ALL FIVE CLASSES at once** (draft parity already existed — the old "Bulwark-only" note was stale). ONE shared roll in `game/draft.gd` (per-class `*_boons.gd` are now data catalogs + `apply()` + `aspect_tags()`): offer slot 0 = **synergy slot** (guaranteed tag-match vs loadout ∪ owned boons ∪ aspect vocab), rarity **Haiku .70 / Sonnet .25 / Opus .05** as *frequency only* (no caps, no lockouts) with opus pity (+5pp/dry draft, hard-forced by draft 6 — proven worst drought = 5), **deterministic**: RunState carries `run_seed` + a draft-only `DetRng`; per-fight combat seeds are closed-form `fight_seed()` (spends can't shift combat) — whole runs now replay from `(run_seed, picks, spends)`, the Trial-Ladder leaderboard prerequisite. **6 new Opus transforms** (`retaliation`, `dancersgrace`, `nullbrand`, `voidfeast`, `sanctifiedward`, `evergreencycle`) + reclassified opus (`vindInterrupt`, `riposteChain`, `syncopation`, `contagion`, `secondwind`, `verdantsurge`), all `_b()`-gated. UI: `game/ui/draft_screen.gd` (shared screen: token plaque, UPSELL under each card, REROLL plate, ✦ RESONANT mark), RelicCard rarity frames (opus breathing ring), Palette HAIKU/SONNET/OPUS. Works inside the Topology map (salvage drafts pass a custom headline; mint runs in map mode).
- **B. Slot-verbs — ✅ DONE, ALL FIVE VERBS (Bulwark PoC merged `7860efa`, port to the other four merged 2026-07-02 branch `slot-verbs-port`).** The port (same cross-product/no-lockouts pattern, ~8 pieces/class, kit-side proc engines, all `_b()`-gated): **Twinfang build-your-RHYTHM** (innate proc = PERFECT Strike; Ghost Step/Killing Tempo/Beat Dancer · Razor Echo/Quickblood/Red Harvest · Wide Tempo + opus **Twin Step** 2nd dodge charge) · **Voidcaller build-your-KICK** (innate = landed interrupt; Resonant Break/Starve the Choir/Void Step · Null Lash/Mind Siphon/Umbral Mending · Perfect Pitch + opus **Twin Void** 2nd kick charge) · **Mender build-your-TRIAGE** (innate = clutch heal on a sub-50% ally; Cleansing Rite/Aegis Echo/Graceful Step · Lightward/Deep Well/Lingering Grace · Swift Litany + opus **Benediction** every-5th-proc party bathe) · **Bloomweaver build-your-GARDEN** (innate = cashed Bloom; Barkward Echo/Seedsower/Rootstep · Bramble Burst/Sapwell/Petalfall · Quickening + opus **Deep Garden** payloads ×2 at 3+ Growths). `verb_summary()` renders the assembled verb in each class's verb tooltip (+ Grimoire tomes); Twin Step/Void pips ride the dodge/kick rune-sockets. **Port probes (`_prove_verb_mods`, 120 paired seeds @sloppy): rhythm 54.2→92.5 · kick 80.8→100 · triage 71.7→90.8 · garden 78.3→84.2, all deterministic.** Port gates: 6 sims byte-identical boonless · draft_sim ALL OK · 5 smokes · WSLg (tooltip + pips). ⚠ Port lesson (memory'd): `RunState` couples every class's content into every sim's compile graph — never edit ANY kit while ANY sim runs. The Bulwark PoC details: Build-your-Guard as **cross-product pieces, NO LOCKOUTS** (Bill-locked): **TRIGGER** cards add proc moments (`trigRead` feint READ · `trigThird` every 3rd guard · `trigBeat` PERFECT beat · `trigRiposte` landed Riposte, Warden pool; each carries a +4-rage built-in), **PAYLOAD** cards fire on EVERY proc moment — innate proc = any clean negate — (`payReflect` 35 · `payHeal` 30 · `payRage` 8 · `payExpose` 1.2s/+15% · `payCounter` Warden · `payMomentum` Jugg), **PROPERTY** cards reshape the verb (`propSwift` cd ×0.8 · `propWide` window ×1.3 · **opus `propCharge` "Twin Guard"** 2nd charge via post-press `defense_ready_tick` rewrite + `upkeep` recharge — riposteChain precedent). Kit-side proc engine (`BulwarkKit._guard_proc`/`_trigger_fire`), all `_b()`-gated; knobs = `BulwarkConfig.mod_*`; catalog entries carry `slot:`, guard-adjacent classics labeled `slot:"property"`. **LOCK · 1⏣ = hold-through-reroll** (Bill-locked): `Draft.lock` + `Draft.reroll_kept(run, offers, locked)` redraws only unlocked slots (locked ids excluded from redraw; empty locks ≡ classic reroll stream). UI within existing surfaces: slot captions on RelicCard ("OPUS · GUARD PROPERTY"), ◆ HELD banner + LOCK/RELEASE buttons on DraftScreen, YOUR GUARD assembled rules in the guard tooltip + the Grimoire tome's guard entry, Twin Guard charge pips on the rune-socket. **Proof (`_prove_guard_mods`, Duelist@loose, 120 paired seeds): boonless 74.2% → modded 92.5% win-rate, TTK 57.9s → 38.5s, 7.7 procs/run, modded determinism PASS** — two runs of the same class now build tangibly different verbs. Gates: 6 sims byte-identical boonless vs frozen baselines · draft_sim ALL OK (incl. 5-class LOCK matrix) · 5 smokes · WSLg shots. **Scoping rule for the port (still locked):** pools stay per-class; mods express through UI the class already has; cross-aspect bleed = rare spice only.
- **C. Token economy — ✅ DONE (merged with A)**: kits bump class-signature skill signals into `seat.diag`/`state.diag` (`negate` / `perfect_strike` / `clean_kick` / `dispel` / `perfect_ward` — diag is never checksummed, so byte-identical sims held); `Draft.mint(state, class)` at fight end = footwork (PERFECT+READ per `mint_per_grades` 3) + signature (per `mint_per_signature` 4) + flawless bonus (no miss/bait/whiff), cap 3/fight (knobs on TuningConfig). Spends: REROLL 1⏣ / UPSELL 2⏣ ("lock a slot" waits for B). Refused spends consume no rng (test-proven). **⚠ 2026-07-08 (🔒 `TEETH-PLAN.md`): REROLL leaves the Token economy** — it becomes a scarce earned/bought BANKED charge and LOCK retires with it; the record above is the as-built code until that claim lands (Tokens re-home to the Market).
- **D. Feeds the Trial Ladder** (below).
- **E. Persistent progression — design LOCKED 2026-07-03, decisions of record in `PROGRESSION-PLAN.md`.** The meta-game: in-run boss loot (2 slots, rarity-first pity rolls reusing Draft 2.0 machinery, scrap→Tokens, MARKET buys) + permanent unlocks by *event* only — first-kill signature rows, **sworn OATHS** (renamed from "armed feats/quests" 2026-07-03 — swear the deed on the boss's Ledger page → keep it → the row joins your drop pool forever; severity I–III + stakes-scaled re-swear purses; Realm-1 skin = SLA, Blood Oaths = PIP), Trial-version rows, carried-out map schematics. **Realm-1 item/oath content lives in `GEAR-CATALOG.md`** (per-boss pages synergized with the class-fun reworks). Four persistent tracks (World/Pools/Rank/Breadth), **Monotonic Pool Law** (an unlock may never make a run worse — rarity-first rolls + synergy weighting + auto-scrap token floor), lane rule (boons = verb/agency · gear = fortune/new-buttons). **CUT (superseded):** RAID-PLAN's material economy (essences/Embers/Sigils/Riftcores/crafting), use-based mastery, pre-run loadouts, daily/weekly content. **⚠ crafting cut briefly reversed 2026-07-08, then RE-CUT 2026-07-09 (Bill):** materials are redundant with kill=unlock (specific) or a grind (generic); the "earn a keystone" fantasy stays via kill→unlock + oath. Crafting stays CUT. See `TEETH-PLAN.md`. Phases GEAR-1…4 in the doc; **GEAR-1 MERGED 2026-07-03 (`866592f`)** and **GEAR-2 MERGED 2026-07-03 (`8d18685` — oaths/Ledger/purses live; stale "open follow-up" fixed 2026-07-10)** — the real open follow-ups are **GEAR-3 (Market stock + extraction schematics)** and GEAR-4 (raid personal loot + Seal tables). Gear noun locked: **CURIO** / Realm-1 **PERIPHERAL**.
- **E.5 Drop-curation = OATH DEDICATION only (design LOCKED with Bill 2026-07-04 — the ONLY loot-steering lever; fine-tune/attune toggles REJECTED).** How players shape their luck toward gear they like, kept *deliberately* un-steerable: **no** favorite/attune toggle, **no** farmed "side resource" (that'd be a meta-currency — Forbidden, Law #4). The single lever is the **already-merged oath drop-bend (GEAR-2), extended with a beneficiary**: when you swear an oath you pick who its KEPT drop-roll bend lands on — **yourself OR a teammate**. Rules that keep it safe: the bend steers **rarity/consistency, not the specific item** (the loot MOMENT survives — the rarity roll stays a surprise; you only enrich a roll from a pool they *already* own → Monotonic-safe, can't gift an unearned row); cap = the existing **one sworn oath / seat / fight**, deed-gated (you must EXECUTE to earn it) → at most 4 bends/fight in a full raid, no stacking, no currency. **Gift cost (Bill-locked):** the swearer KEEPS the Tokens (paid for the deed) and GIFTS the luck (the bend points at the teammate) — a real choice with stakes, and it makes an already-geared veteran structurally useful to a new player (farm deeds → gift the rarity *downward* = the co-op stickiness). **Timing (Bill-locked):** the beneficiary is **swear-time locked** (commit when you sign, like the oath itself), not re-aimable mid-fight. Realm-1 skin (free — oaths already render as SLAs): dedicating to a teammate = signing a **cross-team SLA** / covering their on-call → "SLA MET — Kaelen's allocation upgraded." Solo / 1-human-+-3-AI raid: nobody to gift to → self-only (AI keep no gear); the gift shines in true online co-op. **Build (small extension of GEAR-2, not a system):** sworn-oath state gains `beneficiary_seat_i` (index-based, mirrors `taunt_seat_i` / HoT `caster_i` — RefCounted-safe), the swear UI gains the beneficiary pick, the KEPT pop names them; **byte-identical when nobody gifts** (default self). Depth ties in (see §MODES & ENDGAME power-model bullet): higher Depth = the curation capacity that scales, never hitting power. **Sequence:** after GEAR-2 (merged) — a natural GEAR-2.5, before/alongside the Trial-Ladder Depth work.
**Acceptance (met + how to re-run):** `sim/draft_sim.gd` (determinism transcripts incl. spends, synergy guarantee, pity bound, spend legality, mint table + seeded-fight integration) ALL OK · all 5 class sims + raid sim **byte-identical stdout+CSV** vs pre-change baselines (diag-only kit touches; 300 seeds) · 5 UI smokes green · WSLg visual probe `sim/screenshot_draft.gd` (5 draft screens + end screen, pity-forced opus) rendered clean.

## MODES & ENDGAME

- **Trial Ladder ("Versions")** — NEW: replay any boss at v1/v2/v3…; each version ADDS MECHANICS (extra string beats, feints, phases — never just +HP%), better rewards, fake patch notes. Deterministic engine ⇒ seed-verified leaderboards nearly free. Design vs `TuningConfig` + strings content.
- **Run modifiers** (Hades-Heat/Hardcore-Trials style): opt-in stacking difficulty for exclusive rewards — after Trial Ladder proves the scaling hooks.
- **RAID DEPTH — the infinite "Mythic+" ladder (design LOCKED with Bill 2026-07-04; RANK track in `PROGRESSION-PLAN.md`).** The endgame is an *unbounded* difficulty ladder on the raid: `spec.depth` (a scalar on the fight spec → rides `(seed, spec)`, so lockstep/checksums/headless sims stay correct for free) scales a cheap **numeric spine** (boss HP / damage / enrage clock) AND gates authored **AFFIX TIERS at Depth breakpoints**. Because combat is *timing*, the load-bearing scaling axis is **compressing windows / adding beats**, never stat inflation you can gear past — the affixes REUSE the existing strings/feints/interrupt/add engine (extra string beat, denser feints, tighter parry/dodge windows, an added interruptible cast, an aura-add) at a `TuningConfig` intensity knob. Real M+ structure = numeric spine + affix breakpoints; the game's edge = **a window you can't hit stays unhit no matter your gear**, so skill stays load-bearing forever. Deterministic engine ⇒ **seed-verified Depth leaderboards nearly free**; your best Depth IS your gear score (RANK track). Relationship to the Trial Ladder: **Versions** = per-boss, discrete, *authored* mechanic-adds (fake patch notes); **Depth** = the raid-wide, continuous, *procedural* scalar those affixes ride on. Build after the Trial Ladder proves the scaling hooks + `spec.depth` plumbing. **World-era note (2026-07-07, with Bill):** the DUNGEON door becomes Depth's **primary push surface** (30–45 min runs = the M+ cadence; Forge tiers + TICKETS mutators = the affix vocabulary); raids keep the dial as the long-form flex. Same scalar, two doors — see WORLD-PLAN §INSTANCES "RAID vs DUNGEON identity split" (also locks aggro/threat as raid-only grammar; CUT there: human-only raids, daily lockout).
- **Power model — Law #1 REAFFIRMED (Bill 2026-07-04 — the persistent-gear treadmill was weighed and DECLINED).** Endgame scaling does NOT ship with persistent gear power. Weighed the classic ARPG/WoW "keep your gear, get durably stronger, scaling races your power" treadmill against `PROGRESSION-PLAN.md` Law #1 ("numbers die with the run; skill is the character level") — declined for two concrete costs: (1) permanent power breaks the **co-op scaling contract** — one Depth can't be "right" for both a broken veteran and a fresh friend in one lockstep lobby (carry or one-shot); a shared honest Depth dial + run-scoped gear is what lets *any* mix of players share a fair fight (the 4-player dream). (2) It makes the balance sims **gear-conditional** (violates Law #6 — every win-rate band becomes "…at gear level X"). What scales instead: **Depth grows CURATION CAPACITY, not hitting power** — higher Depth levels up your *shopper* (richer drop-rarity weights + stronger drop-steering, see §SYSTEMS E.5), never your *fighter*. The "I'm a monster this run" fantasy stays **run-scoped** (deeper pool + more drafts at high Depth = a genuinely broken build the scaling is tuned to meet), re-earned each run (fast, because your pool is rich); permanence banks pool + access + Depth record.
- **Open ideas:** endless "Manastorm" mode; ~~meta-progression (account tokens → cosmetic/QoL)~~ — superseded by `PROGRESSION-PLAN.md` (standing/crests + pool growth, no account currencies); ~~daily seed challenge~~ — CUT from core per `PROGRESSION-PLAN.md` (no timed content; deterministic-seed leaderboards stay a free opt-in someday).

## GRAPHICS / PRESENTATION

**⚠ 2026-07-12 DIRECTION RESET — `GRAPHICS-PLAN.md` now owns the final visual system.** The
current Gilded Reliquary/code-art stage is the **functional, verified fallback**, not the final
authored-art claim. `ART-PLAN.md` v1 is superseded (its unbuilt Twinfang rigid-skin/flipbook slices
do not proceed); `tempo-art` Slice 1 `e4589a6` is salvage-only pending a current-main hunk audit.
V2 = AI-owned production · modular Scene Profiles (interior + outdoor contrast proof) · native
painted/deformable character rigs + replacement contact drawings · authored dashboard UI ·
Claude-heavy engineering packets. **Bill V1 approved 2026-07-12: SUNPRINT CEL** — bright,
playful, authored screen-print/cel detail, with darker dungeons as contrast rather than the default.
The game is UI-first: a dominant timing channel, same-frame press feedback, large grades, compact
secondary abilities, and fast cancelable actor payoff. C0 + C1 are complete (selector merged
`3da278f`); C2 SceneKit merged `da314e9` under Bill's assume-pass instruction. P3 environment
contrast art is active; C2's final tour/smoke/A-B matrix is retained as release-default debt.

**Now:** Gilded Reliquary 2D UI + PoseRig stage are playable and stay default throughout V2 work.
- **Telegraph timing UI overhaul ("the Judgment Channel") — DONE, merged 2026-07-02.** Bill's brief: the circle-sweep timing UI read too vague — needed a narrow "aim here" mark, graded feedback around it, verdict satisfaction, and quick-succession clarity, at paid-game quality. Shipped `game/ui/strike_judge.gd` (**StrikeJudge**): a linear precision instrument under every dial that fuses the ENEMY CAST BAR with a fixed gilded **IMPACT GATE** — hairline aim mark, stained-glass graded bands (mint PERFECT / gold GOOD or true parry window / steel GRAZE / violet clean-kick), incoming swings & string beats as comet-gems approaching at **constant px/sec (PPS 250)** so timing muscle-memory transfers across attacks and HUDs, per-press **verdict stamps** (ghost needle + burst + gold rays at your exact press spot), a **grade-history gem rail** (last 8 judgments — the quick-succession answer), feint DON'T-PRESS hatch veil, dodge-lockout LOCKED veil, heal/empower channel fill, parked-comet countdown for long winds (ULTRATHINK-ready). Compact mode (name inside the channel) for the healer HUDs. Classic parries get a cosmetic proximity grade ("PERFECT PARRY!" ≤0.14s) — negation stays binary engine-truth. Dial kept as boss presence; gained a 12-o'clock impact hairline + classic perfect sliver. Wired into ALL SIX HUDs; twinfang/raid rhythm bar and raid/voidcaller player cast bar moved to the player's column (your instrument under you, theirs under the boss). **Fixed a pre-existing feedback bug:** string dodges pop twice ("PARRY!"+"PERFECT!" overlapping garbage) — echo negates (no `seat` key) no longer pop. View-only, ZERO engine files touched. Verified: all 6 UI smokes + map smoke green ×2, bulwark sim determinism PASS, screenshot probes (strings/3D/2D/raid/full tour) eyeballed at 1080p — layouts clean in every HUD. **Next (unclaimed):** classic-parry perfect could earn a real payoff (engine change, needs byte-identical gate + retune); judge could render add-wave/chain-verse counters for Seals II–IV.
**Next up:**
- ~~Wire the other 4 HUDs to CombatStage3D~~ — DEAD 2026-07-10 (loop audit): the solo HUDs + `stage3d/` were deleted in REFIT P1; stage work now targets the 2D raid stage rigs (per-body Forge rigs owed).
- **Robot re-rig**: per-boss silhouettes as ROBOTS/COMPUTERS (theme!) — replaces the `variant()` stopgap and is easier than organic sculpts. CAPTCHA-9 = a turnstile with an eye; GEMINI = two identical chassis; OPUS = a server-cathedral.
- Blender/GLTF pipeline later (art replaces rig subclasses; `act()`/`windup()` contracts stay).
- **⚠ TWINFANG ART PASS v1 — SUPERSEDED 2026-07-12 by `GRAPHICS-PLAN.md`.** The following is
  retained as history; do not execute Slices 2–3 or merge `tempo-art` wholesale. Slice 1 may be
  transplanted hunk-by-hunk after Claude Packet C0. **Original claim (branch `tempo-art`):** the first real character-art
  slice.** Foundation review done with Bill (Spine vs native vs code — StS2 is literally Godot 4 +
  Spine, so the ceiling is same-engine): **verdict = painted layers on the EXISTING `PoseRig2D`
  code-driven skeleton** (agents can author/tune it; Godot's Bone2D-modification layer is
  half-abandoned; the `Actor2D` contract keeps **Spine Pro ($369) as a per-actor upgrade door**
  later — same layer cuts rig straight in). Art = **AI-generated AtO-cel** (prompts specced),
  generated NOW with THEME-PLAN re-skin risk accepted (regen cheap, re-cut ≈ half-day). Scope:
  Twinfang ships regardless — autos (strike) + 2 signatures (eviscerate, coup). Slices: **① juice
  pass** (wire the dormant `screen_post.gdshader` shockwave/aberration/wash + stage-local hit-stop
  [never on plain strikes — the idle bounce IS the beat reference] + dagger smears + coup
  afterimages + lunge-slides + boss flash_all + coup/finisher damage-number styles) → **② skin
  rig** (`tex` Limb kind in `pose_rig_2d.gd`, `TwinfangSkinRig2D` same-joint-tree override,
  factory parts-dir check, scarf spring, cut/align the PNGs) → **③ flipbook FX** (AI-generated
  4–8-frame slash/impact sheets as AnimatedSprite2D one-shots — the StS2/DD2 "hand-drawn FX"
  trick) + signature retiming. All view-layer, never checksummed; gates = WSLg
  `raid_stage_tour` + `verify-all` + `ab-gate raid_sim` byte-identical.
- **GRAPHICS V2 — P3 ENVIRONMENT PAIR ACTIVE:** order is P0 docs → P1 **SUNPRINT CEL + reaction-first
  verdict approved** → Claude foundation packets C0–C2 → interior/exterior scene contrast pair →
  Duelist anchor+hybrid rig → connected Duelist dashboard → signature VFX → side-by-side playtest.
  Old renderer/HUD remains selectable and default until every replacement slice passes.
**Open ideas:** screen transitions; binds/spellbook art pass; theme the Gilded Reliquary gold → circuit-board copper/emerald-terminal accents (light touch, don't redo).
**Acceptance:** `sim/stage3d_tour.gd` / `screenshot_tour.gd` render clean (WSLg), determinism ×3 untouched.

## ONLINE (R2+)

~~IN FLIGHT — another session owns this~~ **✅ DONE since R2/R2.5 (stale header fixed
2026-07-10, loop audit):** server-authoritative WebSocket lockstep + Docker/tunnel deploy kit +
browser WASM client are LIVE (protocol v11; online descent MAP-3b; original brief:
`archive/RAID-PLAN.md`). **Open online work:** W4 presence/events (WORLD-PLAN) · the §4 MMO
shell extraction (REFIT-PLAN) · online spec-carry of reworked-class builds (BUILD-LEDGER §C).
**Queued:** R3 raid content/economy (needs aura-add / parallel cast sources — see Bosses).

## TOOLING & INFRA

**Now:** headless sims per class, UI smokes, screenshot tours, this repo is now GIT (baseline 2026-07-02). Worktree workflow live (see HOW TO WORK). **`scripts/psim.sh <sim> [seeds] [jobs] [-- extra args]`** shards any of the 5 class sims + raid_sim across cores (~4.5–5×; e.g. `psim.sh raid_sim 300 8 --boss=mythos`).
- **`./tune.sh` (repo root, 2026-07-03) — the FAST raid-tuning loop for playtest tweaking** (Bill asked). Order-free args (`./tune.sh gemini 50 all`), quick defaults (riftmaw / 30 seeds / good+sloppy / **no probes** → ~15s vs ~48s; one tier ~7s), and **LIVE KNOBS that need no file edits**: `--dmg=1.3` (scale all boss damage), `--regen=0.4` (healer mana regen), `--fortify=0.5` (tank self-heal). New `raid_sim` flags: `--probes=0` (skip determinism+threat gates), `--skills=good`, `--dmg/--regen/--fortify` (applied to a fresh encounter per run → no leak; full path byte-identical). `./tune.sh --help` explains it. When a build feels right → bake the numbers into `raid_content.gd` + run the FULL sim (probes on) to confirm.
**Next up:** CI-ish script that runs all sims + smokes in one command (the merge-back gate, `tools/verify-all.sh`); decide CSV output home (`godot/out/` is gitignored).
**Open ideas:** auto-post sim bands into this file; seed-verified replay files for leaderboards.

## CODE AUDIT — open findings that NEED A DECISION (2026-07-03)

**⚠ AUDIT v2 (2026-07-07) — see `REFIT-PLAN.md`.** A 5-agent STRUCTURAL audit ran against
the post-pivot era (world preview = the real shell, hosted central server, raid = dev
harness). Verdict: the engine laws hold (CombatCore purity / (seed,spec) entry / seeded
content chain all verified clean); the debt is the shell — raid_hud god file (4 programs in
one), net_server's duplicated campaign engine + zero persistence/identity, ~6.5k lines of
dead solo code held live by ONE line (raid_hud.gd:3757), 8 ad-hoc save files, no scripted
byte-identical gate (and `ui_smoke_map` — an ACTIVE gate — boots the DEAD bulwark_main solo
path). Fix plan = REFIT-PLAN §3 (P0 paper cuts → P1 BIG DELETE → P2 gates-in-a-box → P3 the
three extractions: RunDirector / WorldShell / online split → P4 scale rails); target MMO
architecture = §4; claim table = §5. The parked items below have their disposition mapped
in REFIT-PLAN §5. Phases are AT BILL'S VERDICT before build claims.

A fan-out audit (11 scoped agents + adversarial verify) ran 2026-07-03. The **24 non-controversial
fixes are DONE + merged** (`fd512f8`: dead code, per-frame perf, DRY — all byte-identical, see
Coordination Log). These **13 are confirmed real but change gameplay/checksums or are architectural**
— they need Bill's call, so they're parked here (severity in caps):

**Correctness bugs (in drafted-boon / raid paths):**
- ~~**HIGH — Mender `overflow` boon can SHRINK a shield**~~ — ✅ FIXED 2026-07-03 (`2c94233`): only grows + claims owner on real growth; `sim/mender_overflow_probe.gd` guards it. (No balance re-run needed — the boon simply stops destroying shields; boonless byte-identical.)
- ~~**MED — Bulwark `payExpose` boon is inert solo**~~ — ✅ FIXED 2026-07-03 (`4d3d9b6`): per-seat Exposed window + `outgoing_mult` +15%; `sim/bulwark_expose_probe.gd` guards it. Boonless byte-identical.
- ~~**MED — `fight_seed()` collides in Topology map mode**~~ — ✅ FIXED 2026-07-03 (`ac386bf`): folds `map_node` in map mode; `map==null` byte-identical; `sim/fight_seed_probe.gd` guards it.

**Netcode robustness (architectural):**
- ~~**MED — desync checksum covers only boss HP + tick**~~ — ✅ FIXED 2026-07-10 (`4779f59`, option b as recommended): `RaidNet.integrity()` ships `ih` beside `cs` every 30 ticks (seat HP/resources/absorb + `DetRng.state_hash()`); replica halts on mismatch; protocol v14. Engine checksum untouched — all sim baselines byte-identical. `sim/integrity_probe.gd` guards it.
- **MED — `seat.casting` holds a live Seat ref → RefCounted self-cycle** (`seat.gd`): a raid healer self-cast leaks the seat on Esc-mid-cast (only cleared on fight-over). Definitive fix: store `target_i` (index), mirroring `absorb_owner_i`/HoT `caster_i` — touches mender/bloom kits + HUD readers. (An interim `casting={}` teardown stopgap exists but the index fix is the right one.)

**Bigger DRY refactors (safe but larger churn — deliberate, not drive-by):**
- Sim harness: `_arg`/`_fmt`/`_write_csv` are md5-identical across 9 sims → a shared `sim/sim_util.gd`.
- HUD factories: `_place` (×6), `_title`/`_label`/`_gap`/`_panel` (×4-6) → shared UiKit helpers.

**Deeper coverage the audit flagged as NOT swept (future audits):** cross-platform float/`Dictionary`-iteration determinism (the real WASM-vs-native lockstep risk); `net_server` adversarial input hardening (malformed/oversized frames, claim races); a systematic boon×aspect correctness sweep (only 2 of ~60 effects were hand-checked — both were bugs); HUD/stage teardown tween/Node leak audit on Esc-mid-fight; config/save (`rift_net.cfg`, binds JSON) versioning + corruption handling.

**Acceptance for any of these:** determinism PASS; byte-identical where the change is meant to be neutral; a fresh baseline documented where it legitimately shifts checksums (boon/map changes); smokes green.

---

## CURRENT / OPEN IDEAS (parking lot — promote into a section when claimed)

- **MMO-feel levers (Bill's want, 2026-07-07 — the real goal behind the cut lockout/humans-only
  raid instinct):** make playing together the emotionally best way to play WITHOUT gating
  content. Candidates, all law-compatible: (a) **warband lending** — Commander-built raiders
  shareable between saves (your kid's tank, as he specced and named it, tanks your raid —
  async co-op through each other's builds); (b) **Bastion quest-board bounties posted for
  each other** ("beat my Trial time", seed-verified — rides the deterministic replay we
  already have); (c) **ghost/replay races** on the Depth ladder (whole runs replay from
  `(run_seed, picks, spends)`); (d) **co-op-only cosmetic standing** — titles/banners/transmog
  earned only in shared runs (Law 1's social track). W4's presence layer + world-event open
  lobbies remain the baseline. None claimed.

- **TEAM-COMP layer (Bill 2026-07-04, deliberately split from the commander merge — "another subject,
  focus the ai pick 1st"):** damage SCHOOLS (physical / void / poison / nature) + per-boss resist/immune/
  weak profiles so the party you assemble answers the encounter. Design sketch from the commander session:
  guarded mult in `CombatCore.damage_boss` (the SUNDER amp is the precedent slot; empty profile = 1.0 =
  byte-identical), school mapping via a `ClassKit.school_of(src)` no-op hook riding the existing meter `src`
  labels, profiles on `EncounterRes`, HUD RESISTED/WEAK pops + profile lines on the party screen / Seal
  tooltips. Tuning rule: Seals get soft multipliers (±15–30%); full IMMUNE only for supplemental schools
  (poison / thorns) and only on skirmish trash, so a class kit is never bricked mid-Seal. COMMANDER v1 is the
  lever that makes profiles a real decision (re-aspect your raiders per fight). Needs its own claim + the
  full byte-identical/retune gate (it IS an engine touch).
- Game title candidates: *UNPLUGGED*, *Ctrl+Alt+DEFEAT*, *KILLSWITCH*, *RIFT: Do Not Trust Its Outputs* (these read Realm-1-flavored now; a realm-neutral title may fit better).
- **Future realm seeds** (each = Seals ladder + map skin + joke register): *THE BUREAUCRACY* (paperwork hell — stamp-golems, queue mechanics, "please hold" telegraphs); *THE UNDERCROFT* (necropolis played straight — the contrast realm); *THE DEEP* (abyssal leviathans, pressure as attrition); *THE CLOCKWORK COURT* (fae mechanisms, rhythm-heavy strings); *THE KAIJU WEATHER STATION* (one enormous boss per floor).
- Rewind verb (deterministic-engine showpiece) — parked, see Classes.
- Positive run-affixes ("Mythical Boons") — fold into Run modifiers when built.
- ~~Second raid boss~~ — claimed: §RAID SEALS (branch `raid-seals`). Healer-aggro rules for co-op still open (R0 caveats list).
- Mender's own draft pool (currently continue-screen only) — subsumed by Draft parity above.

## COORDINATION LOG (claim before you start, tick when merged + plan updated)

- ☑ 2026-07-12 · main · **ADD PHASES SING + a boot-breaker caught (`63080a1` + `949d4e7`).**
  ① Bill: Gemini's add phase "says HOLD and just hits me until I die, no notes" (+ "same with
  mythos adds") — ALL THREE raid adds (BARD.EXE · SONNET · OPUS subagents) shipped melee dicts
  WITHOUT the "rhythm" key → the legacy unanswerable auto timer, empty channel, dead tank.
  Each add now carries an identity songbook (the Bard waltzes in 3/4 with a false note · the
  Sonnet rushes cheap pairs/triplets · the Opus lands deliberate talls). Proven by a forced
  add-phase probe (bard 5/5 · sonnet 4/4 · opus 4/4 bars committed/in tank obs) + **stream_probe
  LAW 7 (the Bard lesson): add melee without "rhythm" = FAIL — the class can't ship again.**
  ② ⚠ FOR THE ARTV2 SESSION's owed check-back: the `da314e9` assume-pass merge was RED — 
  scene_kit's untyped `const _DRIFT/_BOB` broke `:=` inference (the CLAUDE.md parse-cascade
  gotcha), world_shell failed to compile, and **main did not BOOT** (caught only by the
  Windows-install boot check; sims never load world_shell). Fixed with pure type annotations
  (`Array[float]`, `949d4e7`) — ARTV2 PROBE ALL OK (41 checks) · RAID UI SMOKE ALL OK · boot 0
  errors. Assume-pass merges on BOOT-PATH files need at least the one-frame boot check.
  Windows install updated + gemini tank autostart clean. *(this session)*
- ☐ 2026-07-12 · preview art / no runtime code · §GRAPHICS — **CLAIM: P3 CODEX I1 — THE
  ENVIRONMENT CONTRAST PAIR + C3 ASSET CONTRACT.** Use the approved SUNPRINT CEL direction and
  the Mistral data-center concept as the bright anchor: **THE STACK**, an airy retro-future server
  atrium. Pair it with a darker machine-space scene that remains colorful/readable and clearly
  belongs to the same world—not another generic fantasy dungeon. Define separable six-layer
  deliverables for SceneKit; generated previews remain outside runtime until Bill approves. After
  approval, Claude receives C3 only (asset folders/import defaults/repeatable scene tour). No
  overlap with the live `raid_content.gd` playtest edit. *(Codex graphics-v2 session)*

- ☑ 2026-07-12 · main · **THE GUARD — authored space around globals (`d03dbfa`; Bill: "it's
  every time a problem").** Quiet windows [impact−0.65, impact+0.45] (TuningConfig knobs,
  per-Seal melee overrides) around every answerable telegraph impact: committed bars inside
  SHATTER at cast start (the rear-up — a rule; selective, `stream_guard_shatter` names ids),
  both publishers slide beats past live windows (flurries degrade rather than cross),
  publishing never reads s.telegraph (windows = authored BossState data — continuity law
  intact). Probe law 6 + sanctioned-vanish + guard-quiet-not-a-halt. **Dense expert 100%
  win/2 deaths (35% this morning) — the whole press-feel arc closed: PRESS restore → ONE
  BAR → ONE CLAIM → THE GUARD. And ui_smoke_raid is ALL OK — the long-known pause+codex
  warden fail HEALED (it was dying to unanswerable stream pressure).** Closes the owed
  "per-Seal quiet windows" item as a general system. Windows install updated + boot-clean.
  TANK-PLAN §0 ruling 7. *(this session)*
- ☑ 2026-07-12 · worktree `../wow-artv2-c2` (branch `artv2-c2`) → **MERGED `da314e9`** ·
  §GRAPHICS — **GRAPHICS PACKET C2 — SCENE PROFILE CONTRACT + PLACEHOLDER PROFILES: ASSUMED
  PASS; FINAL MATRIX DEFERRED** (Bill 2026-07-12: "assume it passes, at worst we come
  back and fix it — update the plan and move on"). Built per GRAPHICS-PLAN §5·C2 / the §2.2
  six-layer law: data-driven `SceneKit` host (`game/art_v2/scene_kit.gd`) — profiles as pure
  data (backdrop · distant life · midground · combat floor · encounter dressing ·
  atmosphere+palette), `legacy`/""/unknown ⇒ the existing `StageBackdrop` UNCHANGED,
  `v2_interior_test` + `v2_exterior_test` = temporary colored/debug layers ONLY
  (watermarked). `ArtV2.make_scene()` re-routes through `SceneKit.make` (C1's naive .tscn
  lookup replaced per the C0 map; SCENE_DIR retired). Floor line at legacy h·0.80; zero
  `stage2d/*` edits; midground repeats from live size (2560×1080 grows sides); same
  `_stage` slot. `artv2_probe` +13 checks; NEW `sim/artv2_scene_tour.gd` (per
  profile×resolution sheets + the FEET-LINE RECORD — positions printed per shot, must match
  across profiles). **CHECK-BACK before merge:** probe result (run was in flight when the
  assume-pass call came) · tour matrix 1920/1280/2560 × legacy/interior/exterior + feet-line
  diff · `ui_smoke_raid` parity · `ab-gate raid_sim` low-seed. Bill explicitly overrode the wait;
  current `main` was merged into the clean C2 branch and the result fast-forwarded to main without
  touching the unrelated live `raid_content.gd` edit. Debt remains before release-default enable.
  *(Claude session)*

- ☑ 2026-07-12 · `main` (docs only) · §GRAPHICS — **V1 VISUAL VERDICT +
  REACTION-FIRST CONTRACT.** Bill selected the bright **SUNPRINT CEL** family and approved the
  UI-first hierarchy: the timing/answer channel dominates; abilities are secondary; press and
  grade feedback are immediate and unmistakable; actor motion is fast, cancelable punctuation
  that never delays combat truth. Update `GRAPHICS-PLAN.md`, MASTER §GRAPHICS, and BUILD-LEDGER
  only. No generated preview becomes a runtime asset in this slice; no overlap with Claude's
  active default-off C1 selector branch. Plans synchronized in the docs closure immediately after
  claim; no runtime asset or code changed. *(Codex graphics-v2 session)*

- ☑ 2026-07-12 · **MERGED `3126437`** (feat `916e9c2`) · §COMBAT PILLARS —
  **INTERRUPT-BY-ABILITY (Pillar #3 turns ON).** Bill: *"no one can interrupt — let's make
  our Eviscerate, and a combo tank attack interrupt."* The interrupt RESOLVER already exists
  (`CombatCore.stagger_boss` — used by the legacy `_kick` button + scripted Shockwave/Vindicate) and
  the WHOLE UI/feedback layer is built and waiting (`boss_cast_bar` "interrupt/uncontested" cue +
  "CLEAN KICK!/DENIED!" pops); the only blocker was `raid_hud.gd:3298 kickable_seat=false` + no press
  that honors it. **SIMPLE by Bill's steer (2026-07-12): press your ability ANY time during the cast
  to stop it — no tight window, no early-press whiff, no interrupt tax. DPS already juggle dodge +
  interrupt.** Three guarded pieces (byte-identical when no ability carries the flag ⇒ every
  non-carrier sim unchanged): (1) `ClassKit.ability_interrupts(id)` — **Twinfang→`eviscerate` ·
  Duelist→`dump`** (the two combo finishers Bill named), both add `carries_kick` to obs;
  (2) `combat_core._try_interrupt()` fired right after a kick-tagged ability commits in `perform` — a
  live INTERRUPTIBLE cast (single-resolve, not a dodge-string) routes to `stagger_boss(s, seat)` (new
  optional crediting seat → richer "interrupt" event + `kick_landed`; null arg = legacy "staggered",
  byte-identical); chains skip one verse, unchained casts clear. (3) flip that one `kickable_seat`
  line to read `carries_kick`. Alchemist dump = the 3rd kicker, follow-up; the AI isn't a *deliberate*
  kicker yet (raid_sim coincidental kicks ≈ 0 — AI kicker policy is the next slice). **Gates all
  green:** import ✅ · direct kick probe ✅ (Evis+dump kick myth_cot→myth_cot2, non-carrier Alchemist
  can't) · `ab-gate alchemist_sim` **BYTE-IDENTICAL PASS** (engine touch byte-neutral for
  non-carriers) · merged-main import clean + raid_sim runs. ⚠ **Pre-existing bug surfaced (NOT this
  change):** `ui_smoke_raid` fails at the `pause+codex round-trip` assertion (line 125) — reproduced
  identically on the pinned baseline `7064a01`, so it lives on `main` already (likely tank-v3/graphics
  era); flagged to Bill, unrelated to interrupts. **OWED (follow-ups):** AI *deliberate*-kicker policy
  · Alchemist dump = 3rd kicker · the boss-side S7 tight-window slice (`kick_window`) + verse-table
  kick diag stay parked · legacy Twinfang `_kick` button coexists (Bill may cut it). *(Claude session)*

- ☑ 2026-07-12 · `artv2-c1` → **MERGED to `main` (ff `3da278f`, slice `47197bd`)** ·
  §GRAPHICS — **GRAPHICS PACKET C1 COMPLETE — ART-V2 SELECTOR + FAIL-SAFE** (GRAPHICS-PLAN
  §5·C1, built exactly to the C0 map §10.2 shape). Three INDEPENDENT view-only toggles, all
  default OFF: static `ArtV2` holder (`game/art_v2/art_v2.gd`, no autoload) — `actors: bool` ·
  `scene: String` (profile id) · `dash: bool` — parsed from `--artv2=actors,scene:<id>,dash`
  at the top of `WorldShell._ready` (NOT drive_autostart: the parse must precede the HUD
  instance, whose `_ready` builds the backdrop). Guarded consumption, one seam each, THE
  FAIL-SAFE LAW at all three: `Actor2D.make()` head (V2 asset missing ⇒ null ⇒ fall through
  to user-art/puppets) · `raid_hud._ready` backdrop (`ArtV2.make_scene()`: "" / unknown
  profile ⇒ legacy `StageBackdrop`; `_stage` member loosened to `Control` for the C2 host,
  3 use sites) · `_build_combat` (v2dash guard around bar/castbar/dial/judge + band;
  `make_dash` returns null until C6 registers a host — even `--artv2=dash` builds the
  current dashboard; C6 owns null-guarding the render feed). No CombatState/spec/protocol/
  checksum contact. NEW `sim/artv2_probe.gd` (22 checks ALL OK — defaults OFF · grammar ·
  OFF-purity per factory id incl. the duelist→RiftmawRig2D fallthrough locked AS-IS for C4 ·
  flags-ON-no-assets ⇒ legacy) wired into verify-all PROBES. **Gates:** import clean ·
  `ui_smoke_raid` failure signature identical to main (only the known pause+codex fail) ·
  `ab-gate.sh raid_sim --seeds=20` **BYTE-IDENTICAL PASS** (low seeds per Bill's 07-12
  quicker-sims steer) · WSLg `raid_stage_tour` + `screenshot_duelist_raid` old-mode sheets
  eyeballed (legacy backdrop/puppets/dashboard, no drift) · live boot
  `--artv2=actors,scene:v2_interior_test,dash` = selector prints, profile warns + falls
  back, no script errors. Merged main pre-verify (docs-only delta — SUNPRINT CEL verdict;
  no code drift). verify-all deliberately not forced: globally PAUSED (Bill's pre-release
  switch) + docs-only merge kept every gate valid. Next packet: **C2**. *(Claude session)*

- ☑ 2026-07-12 · main · **ONE CLAIM — the overlap fix (Bill's playtest round 3).** Globals
  "don't register" traced in two layers: ① telegraph events were judged at IMPACT (open-window)
  while stream bars judge at the PRESS — an interim view-preview (`ffab265`) fixed the feel for
  the no-overlap case; ② Bill confirmed the press-STEALING overlap ("for sure") → FULL
  UNIFICATION: telegraph events (GLOBAL beats / my beats / strikeless BUSTERS) now compete in
  `_claim` under the same DEC-14 window/tie-break — nearest comet wins, judged at press on the
  one ladder, payoffs at press, stored mit applied at impact (`tg_claims`); the open-window
  model + its age knobs + the preview hack are RETIRED/deleted (−215 lines). TANK-PLAN §0
  amendment ruling 6. Proof: spike checksum BYTE-IDENTICAL (no overlaps = old behavior exactly) ·
  dense expert 35%→80% win, 13→5 deaths (the stolen presses back) · raid_sim clean, rations
  PASS · tour 5/5. Also this round: feints anchor their own READ dissolve (never the red ✗,
  `3763588`) + gate-neighborhood verdict anchors. Windows install updated + boot-clean.
  Remaining fairness lever: per-Seal quiet windows (S6, owed). *(this session)*
- ☑ 2026-07-12 · `devgen` → **MERGED to `main` (ff `97854ee`)** — **DEV · GENERATED SETUPS
  on the BOSS TEST screen** (Bill: "simulate different runs … give me an average build, not a
  perfect build, with a seed so I can retry one"). The SETUP toggle on the debug boss-test
  screen swaps the bare-kit jump for an AVERAGE build scaled to the chosen Seal's depth: new
  `game/dev_setups.gd` replays the descent's REAL economy in fast-forward — walks each floor's
  actual RunMap on a seeded route, one LIVE `Draft.roll_offers` 1-of-3 per fight won picked by
  a weighted average-player policy (rarity + synergy nudge, never optimal), milestones where
  the run lands them (creed@start · rig@draft-1 · module@Floor-1 · transform+rewire@Floor-2
  Twinfang · keystone@first elite · a curio at an affordable market); AI seats = Commander
  parity (boons+keystones, decorrelated seeds). Boss-test also gained a SPEC row (brim/draw
  etc.) and a module FOCUS anchor (e.g. ⭐Vigil — creed-compat filtered); the preview screen
  prints the build + a quick description + SEED with FIGHT / REROLL / USE-SEED (same seed =
  identical setup). `raid_hud.gd`: `_launch` head extracted to `_resolve_seat` (byte-identical)
  + `_launch_dev_gen` (boons ride the spec, `_inject_boons`/`_arm_gear` fold the rest). NEW
  probes: `dev_setup_probe` (determinism · depth-scaling · anchor · all-class · launch, ALL
  OK) + `screenshot_devgen` (both screens eyeballed). shell_probe ALL OK · ui_smoke_map ALL
  PASS · ui_smoke_raid = only the known pause+codex fail (identical on main). Dev tooling
  built same-day → no ledger/catalog touch. *(Claude session)*

- ☑ 2026-07-12 · main (docs only) · §GRAPHICS — **GRAPHICS PACKET C0 COMPLETE — the read-only
  recon; `GRAPHICS-PLAN.md §10 IMPLEMENTATION MAP` populated.** Seam map with exact anchors:
  ACTOR = `Actor2D.make()` (both call sites in `raid_stage_2d.gd`; `art/actors/` folder doesn't
  exist yet) · SCENE = the ONE `StageBackdrop` node at `raid_hud._ready:276` (WorldShell adds no
  backdrop of its own) · DASHBOARD = `_build_combat:2583` + `ClassBand.for_hud:2688` (tank's
  AnswerChannel = timing truth, dock-around-only). Candidate C1 selector shape = static `ArtV2`
  holder + `--artv2=` parsed in `WorldShell.drive_autostart` (§10.2). **`e4589a6` hunk audit:
  13/13 SALVAGE** (0 stale/reject — `raid_stage_2d`/`pose_rig_2d` barely drifted; all `raid_hud`
  anchors survive under tank-v3) with 2 transplant fixes owed: `_post` never nulled in `_clear`
  (H5) + the `finisher` wash isn't player-gated (H9); route = C7 cherry-pick, never a branch
  merge. **Findings for Bill:** ① tank-v3 is MERGED to main (§8's collision note was stale —
  corrected in §10); ② ⚠ LIVE WART — post-PURGE, `Actor2D.make` has no `duelist/alchemist/well`
  cases, so tank + caster + healer puppets all fall through to `RiftmawRig2D` (the BOSS rig) and
  drop their aspect; the voidcaller/mender rigs are unreachable dead code (C4 fixes the mapping);
  ③ an uncommitted editor rewrite of `project.godot` sits in the working tree right now — §8's
  never-stage warning is live, left untouched. NO code changed. *(Claude session)*

- ☑ 2026-07-12 · main (docs only) · §GRAPHICS — **GRAPHICS DIRECTION V2 DOC RESET COMPLETE —
  the AI-owned, modular-art reset (Bill); V1 STYLE BOARD is next.** Superseded the
  new-but-now-obsolete `ART-PLAN.md` v1
  before executing its painted-cutout slices; preserve its completed `tempo-art` Slice 1 as a
  reusable juice candidate and keep `godot/ART-PIPELINE.md` / `Actor2D` as the live fallback
  contract. New `GRAPHICS-PLAN.md` owns the full visual system: AI-generated + agent-prepared
  character art, native deformable hybrid rigs and selective frame swaps, authored dashboard UI,
  and **modular scene kits** that prove the same combat in a dark interior AND an outdoor/daylight
  scene. Work is approval-gated one slice at a time; existing stage/HUD remains playable and the
  default until each replacement is visually approved + verified. Implementation will use a fresh
  `art-v2` worktree, merge `main` frequently while Claude playtests there, and expose bounded
  non-image Claude handoff packets with files/contracts/gates. This claim is DOCS ONLY:
  ART-PLAN deprecation banner · GRAPHICS-PLAN new · MASTER §GRAPHICS + BUILD-LEDGER §G sync;
  no code or art assets touched. `GRAPHICS-PLAN.md` carries the one-gate-at-a-time order,
  C0–C8 Claude engineering packets, I0–I5 Codex image/visual packets, fallback laws, collision
  map, and mandatory interior+outdoor proof. **NEXT:** Codex I0 generates three V1 direction
  boards; Claude may run read-only Packet C0 in parallel. *(Codex graphics-v2 session)*

- ☑ 2026-07-12 · `tankline` → **MERGED to `main` (ff `b5aaa20`)** — **tank gate: drop the
  approach-side blue mullion** (Bill: "remove the 1st blue vertical line that shows where you
  can start clicking, it should be implied"). `answer_channel.gd` drew TWO steel-blue gate
  mullions — one at the graze OPEN (`gx - win_graze`, where scoring starts) + one at the CLOSE
  (the true late/stop edge). Kept only the CLOSE line (the hard stop is worth marking); the
  approach edge is now unmarked — the start is implied by the grading bands lighting up. Pure
  `_draw` view change (no state/engine). Verified: parse+import clean · WSLg before/after gate
  crop confirms the left blue line + gem gone, gold plumb + right stop-line intact. Deployed to
  `C:\Games\v3Tank` for playtest. No planned-scope/card change → no ledger/catalog touch. *(this session)*
- ☑ 2026-07-12 · `devboss` → **MERGED to `main` (ff `28a0775`)** — **DEV · BOSS TEST home-menu
  button** (Bill: "make a dev tester button main menu to select any of the raid bosses to test
  them quickly"). Debug-only button on the WorldShell home screen (`OS.is_debug_build()` gate,
  same idiom as the in-combat DEV ▶ WIN button) → a boss-test screen: pick a seat
  (Duelist/Twinfang/Alchemist/Well/Bloom) then a Seal (Vorathek/Mistral/Gemini/Mythos) and jump
  STRAIGHT into that single-boss fight, skipping class/aspect/raid/party ceremony. Drives the
  same `hud._launch(seat, "", boss_id)` the raid autostart uses, so the AI party fills and the
  fight starts as a normal Seal pull; Seal list pulled canonically from
  `RaidContent.run_encounters()` (new bosses auto-appear). Release builds never see the button;
  `world_shell.gd` only. Verified: import clean · shell_probe ALL OK · throwaway devboss_probe
  drove open→seat-toggle→press-each-Seal→lands-in-combat-on-right-enc ALL OK (probe then removed).
  No planned-scope/card change → no ledger/catalog touch. *(this session)*

- ☑ 2026-07-12 · `tank-v3` → **MERGED to `main` (ff `006c37d`)** — **THE WHOLE TANK-V3 LINE
  IS ON MAIN.** Bill: "merge this to main so we don't get too far off." The branch (S1–S5
  foundation + S6/S6b/S6c PRESS-restore + AAA + S7/S7b/S7c ONE-BAR + miss afterlife + peel +
  S8/S8b/S8c SONGBOOK + living-motion + feint fix) merged over the healer work with ONE
  conflict (the coordination log — unioned) and a clean `raid_hud.gd` auto-merge (tank's
  `_render_dial` vs the healer ticket flow live in different functions). **Integration gates
  on the merged tree:** stream_probe ALL OK · duelist_sim det PASS (checksums byte-identical
  to pre-merge S8c) · well_sim det PASS · keystone_probe ALL PASS · ui_smoke_map ALL PASS ·
  ui_smoke_raid = ONLY the known pause+codex warden-placeholder fail (dies with §A½). Windows
  install `C:\Games\v3Tank` already carries this code (== main now). Protocol **v18** rides.
  Owed (unchanged): per-Seal `stream_breathe`/buster/LATE authoring · Duelist deck re-land ·
  Bulwark/warden deletion (§A½, clears the smoke). *(this session)*
- ☑ 2026-07-12 · `heal-fixes` → **MERGED to `main`** (`2f2190e` fixes 1-3 · `1e66130`
  keystones) — **HEALER PLAYTEST PASS (Bill, 3 reports on the Well):** ① **THE FLUME** no
  longer drains Current to 0 (read as a random punish + mismatched its own text) — you keep
  max Current, the river re-arms and runs white again while held (well_kit/boons/config;
  CARD-CATALOG §Flume updated). ② **WELL DODGE READOUT** — the Well band built NO dodge
  indicator; gave it the same SPACE/DODGE rune the other unified kits carry, and fixed
  `render_guard` to normalize by the real unified cd (was the stale 2.4s def_cd — mis-read
  for Twinfang/Alchemist too). ③ **TICKET TURN-IN** — a turn-in was invisible for a healthy
  party (repair/mana no-op + a delayed one-shot toast); added a TICKET CLOSED / SPRINT RETRO
  stop panel at the node, and the TURN-IN map badge now only shows while you HOLD the ticket.
  ④ **KEYSTONES ELITE-GATED + capped 1/run** (Bill's call — he got The Flume on fight 1):
  keystones filtered out of the normal draft, granted only at ELITE nodes (1-of-2, per-seat
  chain), the reserved slot wired at last — **BUILD-LEDGER "keystone acquisition" row flipped
  🔨** (online offer still ⏳, protocol-gated like curses). Verify (paused bar → targeted):
  well_sim det PASS · draft_sim ALL PASS (synergy+pity hold) · keystone_probe ALL PASS ·
  ui_smoke_map + ui_smoke_raid + net_map_smoke ALL OK. *(this session)*

- ☑ 2026-07-12 · `tank-v3` (now MERGED to main `006c37d`) — **THE ONE-BAR VERDICTS — BUILT
  (S7 `9cb0180` · S7b `4a24897` · S7c `9815871` · S8 `f91e002` · S8b `63ff7c7` + TANK-PLAN
  §0 amendment `573ad88`→).** Bill's second playtest round, five rulings, all landed:
  **① ONE BAR** — dial (the circle) + shared judge HIDDEN for the tank; GLOBALS/targeted
  BUSTERS/my beats ride the channel as telegraph comets (synthetic negative ids, verbatim
  off the live telegraph); ALL casting on the BossCastBar under boss HP; telegraph verdicts
  anchor via `resolve_tg` (never mis-anchor a stream comet). **② THE MISS AFTERLIFE** —
  resolve slack 0.15→0.04 (~1 tick): nothing sits pressable at the line; unpressed = crimson
  ✗ husk that KEEPS FLOWING to the bar's end (`duel_bar_missed` event); gate draws only the
  true late-grace; press ghost rises VERTICALLY. **③ THE PEEL re-restored to pass 2** — every
  bar ships marked (hunt-chevron + victim name), tank answers all (comeback), damage to the
  hunted raider; probe invariant flipped. **④ THE SONGBOOK** — `_publish_phrases`: authored
  motif libraries per boss (weight/rest/steps{gap,kind,late}), one seeded draw per motif,
  grammar laws intact, legacy odds path preserved (spike+packs); songbooks authored for all
  4 Seals + the dense golem. **⑤ living-motion** — spawn pops, approach scaling, gate
  heartbeat. Gates: stream_probe ALL OK ×3 · duelist_sim det PASS (dense re-tuned to band) ·
  raid_sim 10-seed clean (rations PASS) · tour 5/5 (phrase-aware injection). **Windows
  install C:\Games\v3Tank updated (project+cache), boot + autostart checks clean — ready for
  Bill's playtest.** *(this session)*
- ☑ 2026-07-12 · `tank-v3` (now MERGED to main `006c37d`) — **THE PRESS RESTORE + AAA CHANNEL
  PASS — BUILT (`730a695`+`8194aa7`+`c93462c`+`573ad88`).**
  Root cause of Bill's "old slug" report FOUND: the v3 kit rewrite had regressed §THE PRESS
  to judged-at-impact (pass-2's instant symmetric claim + `stream_resolve_slack` + tick
  interpolation never carried — `cc4011f` took only guard+easy-aggro), so a press's verdict
  waited for the comet to reach the gate = perceived lag equals your earliness; raw press
  events rendered by NOTHING; comets stair-stepped at 30 Hz. **S6** ports pass-2 judging into
  the v3 kit (boss.stream_answers + resolve slack 0.15s; claim filtered victim==me per the v3
  peel; DEC-14/-15 kept; `duel_answer` gains signed `off_ms`+`id`; obs bars gain `answered` —
  activates the policy's existing skip; v18 note extended, no bump) · **S6b** the Twinfang
  echo (tick_frac interpolation · claim moment anchored at the comet's frozen last-drawn
  pixel: fading line + expanding circle + BULLSEYE ring, ±ms readout · verdict ease-in KILLED
  · every press echoes: press_tick gate-kick / dud crimson tick; the band's _front_id/_pending
  reconstruction hack DELETED — telegraph answers no longer mis-anchor on random comets) ·
  **S6c** the AAA pass (channel joins the UiKit glass family: gilded chrome/filigree ·
  SYMMETRIC banded gate = the RhythmBar target + aim plumb + gem mullions · shadow/glow/
  specular comets · Cinzel words · LATE shockwave · FLURRY plaque · AbilityRune.kick() so
  key/mouse presses animate the rail · gauge glass+gems). Gates per slice: duelist_sim det
  PASS (metrics move = the contract restored; good/sloppy fixture deaths match main's
  reference shape) · stream_probe ALL OK ×3 · ui_smoke_raid pre-existing pause+codex assert
  ONLY (A/B'd vs untouched c8d46cb) · screenshot tour 5/5 ×2. verify-all PAUSED globally
  (~/.rift-verify-paused, "building not gating") — respected, not forced. **NEXT: Bill's
  playtest = the feel gate** (`--autostart=raid:tank`). *(this session)*
- ☑ 2026-07-12 · `tank-v3` (worktree `../wow-tank-v3`) — **THE TANK-V3 REBUILD (attempt 3) — BUILT,
  all 5 slices + red-gate repair + union merge on the branch; final bar running.** Design of record = TANK-PLAN §0 THE CHANNEL CONTRACT
  v3 (FINAL BUILD SPEC): Design C two surfaces (channel = committed melee · judge/cast bar = raid
  globals+casts), full A/B unification REJECTED (DEC-1). Slices: **S1 `717b2a2`** law-suite probe +
  byte-free UI fixes (octagon projection + `_tempo_vis` deleted → constant pps; judge feed-or-
  deactivate unconditional = the frozen-ghost fix at source for ALL seats; NO protocol bump) · **S2
  `e99d2ae`** continuity — the STREAM barrier RETIRED, publishing unconditional to horizon (kills the
  #1 "second between generations" hitch), `stream_breathe` forward-compat knob, protocol **v17→v18** ·
  **S3 `bdd72a7`** cross-class restoration = THE MERGE-BACK GATE v2 skipped (`dodge_recovery` 0.8→0.35
  revert · BARRAGE un-collapse = PILLAR #2 ration · rhythm melee on Mistral+Gemini) · **S4 `dfa1d38`**
  vocabulary/legality matrix/LATE floor+cap/claim tie-break + landed-parry mit .95 restored (was
  silently clamped to .90) · **S5 (this commit)** net + final verification: `stream_probe` ALL OK incl.
  the forced-multi-step process-order probe (req 33 — real controller catch-up drain → single coherent
  comet slide, no jump); `server/preflight.sh` OK; net_smoke/net_map_smoke checksum-identical over
  loopback (v18); WSLg render confirmed (tank + Alchemist — no octagon, no frozen ghost, casts on the
  cast bar); BUILD_STAMP → TANK-V3 (v18). **`cc4011f` red-gate repair (verify round 1):** the
  `not is_cast` judge-feed guard REMOVED (the spec-named shared-widget regression — starved the
  judge mid-cast for blade/caster/healer) · DEC-8/pass-2 easy-aggro carried exactly ·
  `stream_dmg_mult` 0.85 (compensates the continuity fix's added stream exposure) · barrage-cd
  re-tune into PILLAR #2's 3–8 band. **UNION MERGE of main `9b15833`** (pass-2 `8d77cbe` +
  endless docs): branch wins the retired systems (barrier/octagon stay dead), pass-2 semantics
  verified carried by the gate round. **✅ `verify-all` SEEDS=300 (the merge-back bar) RAN
  2026-07-12 post-union: 39 ok / 2 FAIL, both understood + owned elsewhere** — map_advance_probe
  (pre-existing, broken on main too, descent thread owns it) · ui_smoke_raid pause+codex (the
  smoke's tank walk still drives the frozen Bulwark/warden placeholder, whose dead kit ends the
  fight early under the now-continuous stream — it passed on main only because the barrier used
  to DROP bars during telegraphs; the placeholder and its smoke line die with the §A½ warden
  deletion — do NOT weaken the smoke to pass it). Residual: expert-tier
  tank_death on Riftmaw/Gemini/Mythos (the AI tank policy answers stream-first and misses the
  CRUSH under the now-continuous stream) = S6 `stream_breathe` authoring + tuning, playtest-owned.
  ⚠ §7 items 1-3 are a DELIBERATE non-byte-identical re-baseline (the retirement WAS
  the regression) — re-pin checksums, don't chase the diff. **Bill's per-Seal playtest = the feel gate**
  (per-Seal texture/busters/LATE authoring = S6; deck re-land = later). *(this session)*

- ☑ 2026-07-11 · main (docs only) · **`ENDLESS-PLAN.md` NEW** / TEETH §ENDLESS / LEDGER §E —
  **ENDLESS MODE DESIGNED: THE BLIND DESCENT (Bill's fog-of-war pitch).** Bill: dungeon-crawler
  fog of war — see only adjacent rooms, find "the end", dead ends, turn around and go back.
  Design v1: the third door (raid=campaign · dungeon=push lap · **endless=which-way-and-how-
  greedy**) — small maze floors (~10–16 rooms, corridor→warren as Depth texture) under fog ·
  **honest info economy** (silhouette tells · VANTAGE rooms · CHARTS as loot · SCOUT ⏻ spend;
  Bill CUT the lying-signposts idea) · **free backtracking through cleared rooms** (Bill-liked;
  anti-tedium law: wrong turns cost decisions, never time) · **dead-ends-always-pay law** ·
  **the HUNTER as a per-floor printed term** (Bill: "some levels, not all-or-nothing") —
  QUIET/HUNTED read on the stair before you descend, exploration-fed clock, kill-it-to-quiet-
  the-floor · stairs/plunge exits, guardian every 3rd floor, runs start at rung 0, standing =
  deepest floor cleared (own page) · **⚠ NOT AI-themed (Bill)** — skin candidates WANDERING
  ESTATE / FIRST DIG / UNDERVAULT at §V-8. TEETH's don't-fork-Depth rule honored (rides
  `spec.depth`, zero new math). 🟡 at Bill's 8-verdict board §V; slices S0–S4 after DESCENT §I's
  map bang. No code touched. *(endless design session)*
- ☑ 2026-07-11 · `tank-v3` (worktree `../wow-tank-v3`) — **THE TANK-V3 REBUILD (attempt 3, Bill) —
  the original claim, kept for the record (the BUILT entry above supersedes).**
  Bill's tank-v2 playtest: upcoming notes NOT showing · whole notes flicker in/out · elements pop
  up all over (not just late) · sync weird · "fully buggy, not one thing" · other classes suspected
  broken by the merge. Scope check: AAA bar, tens of thousands of players — logically perfect and
  robust, no patch-on-patch. Opus agent workflow: behavior-contract recovery (the INTENT, not the
  v2 tech plan — learn what it got wrong) + current-code audit + builds-1/2 autopsy + class-
  regression hunt + symptom repro → root-cause synthesis → 3-architect design + judge synthesis →
  sequential build slices on the branch (quick gates only, per Bill's verify law) → verify-all
  final gate + class restore proof. *(this session)*
  **⚠ HAND-OFF NOTE from the tank-v2 session (2026-07-11, after this claim): PASS 2 landed on
  main at `8d77cbe` AFTER the claim above — audit THAT code, not `68b780a`.** Pass 2 maps onto
  the symptom list directly: *notes not showing / flickering in-out* = the peel-filter (obs hid
  bars whose victim ≠ tank; near the lock floor the victim FLAPPED per-bar → flicker) — GONE,
  every bar ships now (peeled = translucent + hunt-tick; answering them = the aggro comeback,
  Bill's rule) · *sync weird / imprecise* = press-grading was early-side-only + judged at impact
  → replaced with THE TWINFANG PRESS MODEL (instant symmetric claim, ±ms readout, 0.15s resolve
  slack, tick interpolation) · *other classes broken* = REAL v2 regression, fixed (the shared
  judge starved mid-cast by a `not is_cast` guard; it must feed on EVERY telegraph — pre-tank
  contract) · easy-aggro first cut in (slip .05/decay .02/floor .15/start .75). Remaining
  suspects pass 2 does NOT cover: *"elements pop up all over"* beyond LATE bars + peel-flicker —
  unreproduced here; check `AnswerChannel._seen`/flash bookkeeping + the barrier's thin-stream
  gaps on Seals. Gates green: stream_probe · duelist_sim det · ui_smoke_raid. If Bill's playtest
  of `8d77cbe` still fails, v3 proceeds — from the union, with the builds-1/2 autopsy including
  pass 2's root-cause map (this entry + the pass-2 log block below). The tank-v2 session STOPS
  touching this surface as of this note (the claim is yours).
- ☑ 2026-07-11 · `../wow-tank-v2` → **MERGED `5af4927` (ff)** · **THE TANK-V2 REWRITE — BUILT.**
  All slices landed: S1 engine+kit bang (`30008b6` — THE STREAM committed-timeline replaces
  rhythm_*; kit rewritten deckless on the v3 matrix, tick-native, BULLSEYE ladder; BARRAGE
  RETIREMENT + `dodge_recovery` 0.35→0.8) · S2+S3 (`answer_channel.gd` NEW — the game's one
  answer instrument; strike_judge/cast_dial RESTORED pre-tank; new band + STREAM TUNER (F9,
  dev) + verdict-slam carry + the loud AGGRO LOST peel moment) · S4 (`stream_probe` NEW =
  the law suite: immutability/barrier/grammar/obs-invariants/freshness ALL OK; fresh-every-
  pull seed fold; sim metrics on the v3 ladder) · protocol v16→17. **verify-all: 40 ok /
  1 fail — `map_advance_probe`, which is BROKEN ON MAIN TOO (seal_id Nil, descent-era
  staleness; ⚠ descent thread owns it)**; draft_sim + commander_probe re-pointed at the
  deckless world (duelist rows ride the Alchemist; REFORGE chain skips the deckless human).
  **NEXT: Bill's playtest = the feel gate** (numbers are knobs: `duel_*`, stream profile
  dicts, F9 tuner) → then S5 deck re-land per-verdict + S6 per-Seal texture/busters/LATE
  authoring. ⚠ Seal thread: stream density on Seals runs THIN under the barrier (six ability
  timers keep the earliest-fire close) — an S6/SealTune knob, the barrier is law. ⚠ WSLg
  screenshot pass owed (`screenshot_duelist_raid` re-scoped to the channel checklist).
  *(the tank-v2 rewrite — S1–S4 + swap)*
  **↳ PASS 2 (2026-07-11, Bill's live playtest) — MERGED `8d77cbe`.** Four reports, four
  fixes: **① "laggy/imprecise presses" → THE TWINFANG PRESS MODEL** (Bill: *"the twinfang
  is super good, do that"*): a press CLAIMS the nearest bar and is judged INSTANTLY,
  SYMMETRIC around gate-touch (|off|/claim on the blade's own fractions, ±ms readout on
  every stamp); bars resolve `stream_resolve_slack` (0.15s) after touch so hair-late
  presses connect; comets interpolate between 30 Hz ticks. The old press-opens-a-window,
  judged-at-impact, early-side-only model = the perceived lag. **② "not seeing all the
  notes" → THE PEEL REWORKED (Bill's rule):** the tank sees + answers EVERY bar; a peeled
  bar (translucent, hunt-ticked) damages its victim undodgeable, but the tank's clean
  answers still pay flow/counters — **answering peeled bars IS the aggro comeback**
  (supersedes the cdd008f stream-pause). **③ "aggro gone in 3 hits" → EASY AGGRO first
  cut:** slip .14→.05 · decay .05→.02 · lock floor .30→.15 · start .55→.75 (sloppy sim
  tank now HOLDS the boss; tune later). **④ "the blade froze — the bug is global" → a real
  tank-v2 regression:** the shared judge must be fed on EVERY live telegraph INCLUDING
  CASTS (its kick/cast windows live there — the pre-tank contract); the pass-1 `not
  is_cast` guard starved it mid-cast. Gates: stream_probe ALL OK (peeled-flag invariant) ·
  duelist_sim det PASS · ui_smoke_raid ALL OK. *(pass 2 — the playtest fixes)*
  **↳ the original claim (kept for the record):**
  (Bill: tank-w1 broke the game — *"plan the rewrite of the tank and the global dodge UI FROM
  THE BASE, no patching… i dont want tech debt"*). Requirements confirmed question-by-question →
  **TANK-PLAN §0 THE CHANNEL CONTRACT v3** (this commit) = design of record: committed attack
  timeline (engine publishes, UI draws — kills the pop/morph bug class) · ONE channel, NEW
  class-agnostic widget (`answer_channel.gd` — the game's one answer instrument, tank first) ·
  vocabulary v3 (no light bar · bullseye-dodge on heavy/buster · octagon double-duty · disguised
  purple feints, LATE-able · FLURRY = channel mode, no wind, dodge-only) · game-wide grading
  ladder GRAZE<GOOD<PERFECT<BULLSEYE (Twinfang coherence) · speed law (one shared px/s; LATE
  bars; whole-flow tempo shifts OK) · two writers (authored globals/busters + per-body texture
  profiles under grammar, pull-counter freshness) · pack field-holder writes + shatter handover ·
  peel = loud AGGRO LOST (keeps `cdd008f`). **Cross-class: BARRAGE/STRING BEATS RETIRED
  GAME-WIDE + non-tank `dodge_recovery` 0.35→~0.8 first cut** (DODGE-PLAN amended; BOSS-PLAN §3½
  superseded — ⚠ seal thread: hold string/texture authoring until tank-v2 lands). Slices: S0
  docs (this) → S1 engine+kit bang → S2 channel+band+tuner+reverts → S3 feedback layer → S4
  policy/probes → ONE swap merge (deckless; deck re-lands post-playtest). Old duelist/tank-w1
  implementation dies in the swap. Verify: fast probes per slice, full verify-all ONCE at the
  end (Bill's call). *(the tank-v2 rewrite — S0)*

- ☑ 2026-07-11 · `../wow-well-ui` → **MERGED `b9a43d9`** · **THE DRAW HUD DESYNC SWEEP** (Bill:
  *"the window moving creed doesnt move the window, and i couldnt figure out how to spend my
  banked heal… make a workflow to check the boon/creed etc and make sure these work"*). Ran a
  37-agent audit workflow (MAP→VERIFY→adversarial REFUTE→SYNTH) over the Draw spec's kit→observe→
  render→input chain — **21 confirmed defects, both reported bugs root-caused as kit↔UI desyncs,
  not mechanic bugs.** **BUG A (Eddy window):** the drifted clean-band centre was a grading-only
  local in `_release`, never exposed; the render band was set ONCE from raw config → the graded
  window drifted while the drawn one stayed pinned. Fixed (PLUMBING A): `_eddy_centre()` shared by
  grade + observe; per-cast `draw_lo/hi·still_lo/hi·cr_hi` in observe; `cast_channel` `zone_hi`
  right-edge bound (drift is left-only); `well_band` feeds them per frame — **byte-identical
  grading** (eddy build checksum unchanged vs parent). Same stroke fixes Narrows/Long-Draw/
  Deep-Still WIDTHS. **BUG B (banked heal):** the held cast rendered as a finished cast; added
  (PLUMBING B) a persistent 'BANKED — TAP/CLICK to RELEASE' plaque + gutter countdown + trembling
  needle pinned to the sliver. **Siblings:** SKIN film + deferred-wound on ally frames (Well-gated,
  view-only), KEY_E skin, current-haste label, Millrace pip, flume/frozen/glassriver/intercept/
  eddyline cues, + 2 guarded reducer fixes (Loosed absorb 12s→2s dead-config; eddyline SAVE emits
  its own event). **Scope: healer-path only — the global dodge bar / global-UI rework untouched**
  (concurrent session's lane, honored). Gates: parse · determinism PASS (well base/eddy/loaded +
  raid 4 Seals) · base+eddy byte-identical · `ui_smoke_raid` ALL OK. **⚠ `_draw` pixels need a
  WSLg screenshot pass — Bill's visual verdict on the new cues.** ledger §C row updated. *(the
  Draw HUD audit + fix)*

- ☑ 2026-07-10 · `../wow-tempo-d0` → **MERGED `4e46e73`** · **TEMPO D0 FOLLOW-UP BUILT** (Bill's
  board answers) — **On the Beat** back in the offer pool (kit code was already live) · **S3 THE
  4 DUOS** (Blood Coda W×F · Red Edge W×E · Grand Finale E×F · Reprise Rondo×W — kit hooks +
  `DUOS`/`theme_counts`/`armed_duos` folded into `Draft.offerable`: armed at ≥2 cards from EACH
  theme, Reprise also needs Rondo; Opus slot, two-tone frame render deferred) · **S6 THE SET
  PIECE** (the DECK-LAYOUT §5 signature-CD slot, first game-wide: a 4-strike phrase → build-scaled
  flourish [flow-scaled dmg + bleed pulse + combo refund + 2s Flow-lock]; new base ability on the
  Tempo/Fermata bar, `setpiece_enabled` A/B, policy arms it). Parse-clean + runtime smoke green
  (0 errors, all 8 determinism cells PASS incl. flourish). **ONLY kick carriers remain deferred**
  — gated on the interrupt-by-ability pillar (#3), not a Tempo verdict. *(commit `595ecd0`.)*

- ◐ 2026-07-10 · worktree `../wow-seals` (branch `seal-rework`) — **CLAIM: THE SEAL REWORK
  BUILD (`BOSS-BRIEF.md`) — S0 BUILT & GATE-CLEAN on the branch (`d8bc675`); S1+ blocked on
  tank-w1.** Bill's go ("implement these bosses like the brief says"). **S0 done:** `raid_sim.gd`
  instrumentation (beat-budget/seat · cast-source counts · TTK-vs-DESCENT-§4-contract with ±20%
  flag · verse/kick baseline · act/valley timeline), all pure reads → **byte-identical** (main
  vs S0 checksum diff clean 24 rows; determinism PASS ×4). Baseline recorded in §BOSSES (every
  Seal −47…−72% under contract). **⚠ NOT merged — held behind tank-w1:** that Wave-1 branch
  (still IN FLIGHT, at its S4) rewrites the SAME `raid_sim.gd` regions (`taunts→peels`, band
  loop, `_run_one` sig, return dict) + owns the `combat_core`/`boss_state` reducer S1's addenda
  need. Merging S0 now would hand tank-w1 a conflict on the file the brief flagged. **Order:
  tank-w1 merges → rebase `seal-rework`, reconcile `raid_sim.gd` → S1 (E1–E9 guarded addenda)
  → S2–S5 the four fights.** S2–S5 also need Bill's V1–V10 (recs = defaults) before authoring.
  *(boss-build session — S0)*
  **↳ pass 2 (2026-07-10, Bill: "tank build complete, verifying · v1–10 build with my recs"):**
  **① VERDICTS — all 11 DECIDED (recs)**, BOSS-PLAN §V flipped, gate ③ cleared. **② tank-w1
  RECON done → every engine block RESOLVED** (mapped to real APIs in BOSS-BRIEF §0a: flow =
  `seat.vars["flow"]`/`_flow_aggro`; peel = `_aggro_peel(s,base)` at `combat_core.gd:1237` = the
  path E5/E7 reuse; **THREAT_DROP already zeroes flow → S5 Compaction is pure data, zero engine**;
  V#9 valve = `flow_spike .20` already built; taunt fully deleted). **③ THE REAL REMAINING GATE
  = the UNION BASE:** tank-w1 is COMPLETE but forked from OLD main (merge-base `c6738ff`) and
  NOT merged — neither base alone has both the descent fight-ladder (new-main) AND the flow
  engine (tank-w1). S1 edits `combat_core` → needs the union. **Union forms when tank-w1 merges
  main → main** (the tank session's reconcile — NOT front-run in seal-rework; a trial merge here
  surfaced tank-w1↔new-main drift conflicts that are theirs to resolve). Verified: tank-w1's
  `raid_content` delta is party-naming only, so S2–S5 content is conflict-free once the union
  exists. **Turnkey after tank-w1 lands:** rebase seal-rework → re-apply S0 → S1–S5. *(pass 2 —
  recon + verdicts)*
  **↳ pass 3 (2026-07-10, Bill: "tank is on main, merge with main"):** tank-w1 LANDED in main
  (`62cc09e` — Duelist + FLOW=AGGRO + deck + Bulwark deletion). **Merged main → `seal-rework`
  (`cd421be`); the ONE conflict (`raid_sim.gd` `taunts→peels` vs S0) reconciled; S0 re-verified
  BYTE-IDENTICAL on the union (24 rows), det PASS ×4, import clean.** Union baseline captured →
  **the Duelist DIES to V/G/MY even at expert** (§BOSSES) = a Wave-1 verify signal + the rework
  now also rebalances Seal tank-damage for the Duelist. **S1 (engine addenda E1–E9, guarded/
  byte-identical) is now unblocked and building next** — balance-independent, so it proceeds
  ahead of the Duelist-tuning question. *(pass 3 — union merge)*
  **↳ pass 4 (2026-07-10) — S1 ENGINE ADDENDA BUILT & gate-clean on `seal-rework` (`43d70b0`).**
  The seven guarded primitives the fights build on, every default a no-op: **E1** gated ability
  sets (`AbilityRes.gate` {phase_from/until·stance·featured} + `_ability_eligible`/`_phase_index`
  + pick-loop skip) · **E2** stance cycler (`Effect.STANCE_SHIFT` + `EncounterRes.stance_count` +
  `BossState.stance`) · **E3** BREAK curtain (`Effect.BREAK` + `script_lines`, re-staggers) ·
  **E4** SealTune (`EncounterRes.tune` + `RaidContent._apply_tune` build scalars) · **E6**
  deny-race empower (`deny_denom/floor` + `deny_dmg` accrual + resolve clamp) · **E8** kick_window
  (field; honor rides the class interrupts flag) · **E9** pips (field + `Telegraph.pips_left`).
  Enum values appended (ordinals never shift). **Gates: raid_sim byte-identical vs main (32 rows,
  all 4 Seals) · determinism PASS ×4 · raid_probe ALL OK (+12 new E1/E2/E3/E4/E6 asserts) ·
  ui_smoke_raid ALL OK.** E5/E7 (mark relay / LISTENING) land at S5. **S0+S1 MERGED to main (`07a5e9b`) — byte-identical, raid_probe ALL OK on main.** NEXT: S2
  (Vorathek v2) — the first content re-baseline (recs all decided). ⚠ NOTE the Duelist-death
  finding: S2's Seal tank-damage tuning should track the Duelist's own survivability. *(pass 4 — S1 + merge)*

- ☑ 2026-07-10 · main (docs only) · **`BOSS-BRIEF.md` (NEW) — THE SEAL-REWORK BUILD BRIEF,
  hand-off ready (Bill: "make a plan to implement this… after will hand it off to Opus").**
  BOSS-PLAN made buildable: **S0** sim instrumentation (byte-identical, claimable NOW) → **S1**
  engine addenda E1–E9 (all guarded; E9 pips + E1 `featured` added to BOSS-PLAN §7 this pass) →
  **S2–S5** the four fights (first-cut numbers table: hp 56k/95k/85k/92k · per-Seal
  kick-window mults V×1.5→MY×0.85 · interim-vs-final miss costs) → **S6** sweep+record → **S7**
  kick re-tune (rides the first class `interrupts` flag). Gate status verified in-repo:
  **① descent map bang ✅ MERGED** (`a59ffa4`/`cf3f8d9` in `raid_content.gd` history;
  descent-s2/s3 don't own Seal data) · **② Wave-1 `wow-tank-w1` IN FLIGHT** (owns
  combat_core/raid_sim churn — S1+ waits on its merge; this build consumes flow/peels, never
  builds them; V#9 flow-spike knob flagged to DUELIST-BRIEF S0) · **③ V1–V10 recs = build
  defaults**, one-sentence go opens content. Ledger §F row → 🟡→🔒 + brief pointer; CLAUDE.md
  index. Builder claims worktree `wow-seals`/`seal-rework`. *(boss-rework session, pass 3)*

- ☑ 2026-07-10 · `meter-l3` → main (`9a6f6c0`→`7ee55b2`) · §SYSTEMS/§GRAPHICS · **METER L3
  SEGMENTS / RUN HISTORY — BUILT & MERGED (Bill: "continue to L3 now").** Recount's
  Current/Overall/per-pull dropdown, and it built the deferred run-recap accumulator in the same
  slice. **Accumulator:** `RunDirector.fight_log` — each fight snapshots meter/boon_meter/diag
  (+elapsed+encounter name) at `_on_end_moment` (once/fight, win/loss, headless too), auto-reset
  per descent via `fight_log_seed` keyed on `run_seed`; deep-copied plain data. **This unblocks
  the run-summary screen** (BUILD-LEDGER `:270` → 🟡, screen still owed). **Selector:** a footer
  chip cycles This Fight / Whole Run / ‹each past fight›; Whole Run merges snapshots (skips the
  live fight when frozen to avoid a double-count). Works across all 6 modes via a duck-typed
  `_Segment` (readers de-typed off `CombatState` — StatsPage's static calls still pass a real
  state; diag routed through `_diag_of`; segment build cached; NOW live-only). **Bugs caught &
  fixed pre-merge:** `fights` name collision (→ `fight_log`), Whole-Run double-count on the end
  screen, 3 Variant-inference parse errors from de-typing. Touches `run_director`/`raid_hud`/
  `meter_panel`; **project imports clean**, auto-merged clean on `raid_hud`. **⚠ built with the
  sim/screenshot bar paused (`2ee8325`) — a live playthrough is owed** (segment cycling + Whole
  Run totals). Ledger §G → 🔨 `7ee55b2`; METER-PLAN L3 ticked. **Meter is now feature-complete
  through L3** (6 modes + sparklines + run-history); remaining: run-summary screen · L4 window
  chrome · L5 teaching layer. *(meter session)*

- ☑ 2026-07-10 · `meter-spark` → main (`1924405`→`a26a3cd`) · §SYSTEMS/§GRAPHICS · **METER
  SPARKLINES — BUILT & MERGED (Bill: "continue"). L1 + all L2 view-only work now DONE.** A faint
  per-second trace behind each compact row in dmg/taken modes: reads `state.series` (cumulative
  col `base+i` → differentiated to per-second → normalized to the seat's own peak), drawn
  low-alpha under the text so it adds "shape of the fight" texture without crowding the columns
  (heal/shield/amp/disc carry no series → no sparkline; all indices guarded, `<3` samples → no-op).
  **The live meter is now 6 modes** (DAMAGE/HEALING/SHIELDING/TAKEN/⚡AMPLIFY/🎯DISCIPLINE) **+ row
  sparklines.** View-only / diag-family; imports clean. **What's left on L2 all needs a small
  engine field** (no longer pure view): per-seat interrupt counter · activity % · `src_label()`
  prettifier (low-value). Ledger §G → 🔨 `a26a3cd`; METER-PLAN L2 sparkline ticked. **⚠ live
  eyeball owed** — the byte gate + `screenshot_meter` are paused with the sim bar (`2ee8325`), and
  headless can't render custom `_draw`. **Next substantial level: L3 segments/run-history** (first
  slice that touches shared files `run_state`/`run_director` + wants a real verify pass).
  *(meter session)*

- ☑ 2026-07-10 · main (docs only) · BOSS-PLAN §1½ (NEW) + §V#11 + WORLD-PLAN §PILLARS #3 +
  CLAUDE.md pillar + ledger §A — **THE KICK CONTRACT (Bill's steer on the boss-rework recs;
  board grows 10→11 verdicts).** His calls folded in: **every class but healers carries ONE
  kick, bolted on the dump** (2/1/0 spread retired — 3 kickers/warband; Alchemist's kickless
  gap closes when the flag lands) · **warn early, window small** — the castbar is the warning,
  the kickable slice is absolute ~0.6 s at cast end (`kick_window` SealTune knob, per-Seal
  mult: kindergarten wide → exam tight) · **the press is free** (early press = normal dump, no
  penalty — the tax is having your dump armed) · **missing = the raid's costliest single
  mistake** (ladder: Mistral biggest-blast → Gemini permanent EMPOWER stacks → Mythos
  boss-HEAL) · counts modest (V one un-chained Chant · M one 2-chain · G one 3-chain · MY
  CoT+Hotfix). E8 engine addendum (kick-window slice + castbar lit-slice + verse sim table);
  note METER's parked per-seat kick counter (entry below) — E8's verse table is the sim-side
  half. **V#11 ✅ DECIDED (Bill, 2026-07-10): (b) YES — "add one to Vorathek"** — the teacher
  returns ONE gentle un-chained Devouring Chant as the floor-1 kick kindergarten (widest window,
  ~2 casts, miss = boss heals a chunk — the gentle rehearsal for Mythos's Hotfix; ramp reads
  single-kick→first-chain→chain+empower→exam). BOSS-PLAN §V#11/§1½/§3/§6 flipped. *(boss-rework
  session, pass 2 + V#11)*

- ☑ 2026-07-10 · `meter-l2` → main (`c502d36`→`88553af`) · §SYSTEMS/§GRAPHICS · **METER 🎯DISCIPLINE
  MODE — BUILT & MERGED (Bill: "continue").** The L2-tail follow-up to L1+AMPLIFY. A 6th
  header-cycle mode: a live "who's playing clean" scoreboard — one row per gradeable seat, ranked
  by **clean-answer %** (perfect/good/graze/read vs miss/baited/whiff), colored by grade S..D,
  bar ∝ clean%, with a dim fault tail (times hit · strays off the tank). Stat-block AI skipped
  (no timed inputs); <3 answers → "—". `_disc_clean` mirrors STATS PAGE v2's `_pct_defense` so the
  live read and the post-fight grade agree; compact-only (the full grade breakdown stays on the
  stats page). ⚠ interrupts aren't per-seat in state (HUD-side tally) → DISCIPLINE grades answers
  + strays, not kicks (a per-seat kick counter = small engine field, parked). View-only /
  diag-family; project imports clean (byte gate + `screenshot_meter` skipped — the sim/verify bar
  is paused, `2ee8325`). Ledger §G → 🔨 `88553af`; METER-PLAN L2 DISCIPLINE ticked. **Next
  L2-tail: per-row sparklines from `series`. Then L3 segments/run-history.** *(meter session)*

- ☑ 2026-07-10 · `meter` → main (`0859b2b`→`cce7c92`) · §SYSTEMS/§GRAPHICS · **METER L1 + ⚡AMPLIFY
  — BUILT & MERGED (Bill: "go ahead").** The live meter's first level-up. **L1:** killed the
  fragile class-accent switch → new `ClassKit.accent()` hook (built-in Color, no Palette import
  in the data layer, sibling to `recap_spec()`), backfilled on all 5 kits — **fixes the live bug
  where Alchemist + Well (the two default seats) rendered colorless**; compact rows got the
  Recount look (rank # w/ gilded #1 · share% column · player-row wash · brighter bar edge). **L2
  ⚡AMPLIFY:** new header-cycle mode reading `state.boon_meter` — "who enables the raid" (each
  seat's own boon lift + a synthetic RAID row for the raid-amp pool Sunder/Glint/Debilitate),
  drill a row → per-boon "≈ +X dmg/heal"; the live twin of STATS PAGE v2's BOON IMPACT.
  **View-only / diag-family:** `ab-gate raid_sim` **BYTE-IDENTICAL PASS** (both clean runs, before
  Bill paused the verify bar), project imports clean; visual `screenshot_meter` skipped per the
  sim-pause. Ledger §G row → 🔨 `cce7c92`; METER-PLAN L1+AMPLIFY marked built. **Deferred:**
  `src_label()` per-kit hook (`capitalize()` reads fine today) → L2 tail. **Next: L2 tail
  (DISCIPLINE from `seat.diag` · row sparklines) or L3 segments/run-history.** *(meter session)*

- ☑ 2026-07-10 · worktree `../wow-tank-w1` (branch `tank-w1`) · WAVE-1 BUILD · **✅ LANDED ON MAIN
  `62cc09e`** (FF; the Duelist is now the playable tank default — playtest-ready). **Merge resolution
  (6 files, principled — newer system wins per side):** `combat_core.gd` → tank-w1 FLOW=AGGRO
  (`taunt()` DELETED, no caller remained post-Bulwark) · `bulwark_kit.gd` → keep the delete ·
  `meter_panel.gd` → main's `kit.accent()` hook + added `DuelistKit.accent()→STEEL` · `raid_hud.gd`
  → combined (main's Draw `WellModules.offer_ids` + tank-w1 Duelist module branch) ·
  `commander_probe.gd` → combined (main per-seat wallets + tank-w1 rig-wire) · `draft_sim.gd` →
  main's rerolls-out (dropped tank-w1's dead `reroll_kept`/`lock` tests) · `verify-all.sh` → main's
  probe superset. **`net_protocol` resolved coherent at v16** (superset of v15 descent — no
  conflict materialized). **VERIFIED on main:** import clean · `ui_smoke_raid` ALL OK · `duelist_sim`
  determinism PASS · `commander_probe`/`draft_sim`/`meter_probe` ALL OK. **⚠ FOLLOW-UP (not a
  blocker):** the GEAR-2 "answer a Baleful Curse within 2s" deed lost its trigger — `curse_answered`
  was only bumped inside the deleted `taunt()`; re-home to the flow-rebuild path when the Duelist
  deck re-hosts the Bulwark GearFx cells. **UNBLOCKS:** `seal-rework` (rebase → re-apply S0 → S1–S5)
  + DECK-TAX (`wow-deck-tax`, combat_core) — the union base is now formed. *(tank-w1 landing session)*
- ☑ 2026-07-10 · worktree `../wow-tank-w1` (branch `tank-w1`) · WAVE-1 BUILD (landed `62cc09e`, above) · **BUILT + VERIFIED
  on the branch — `DUELIST-BRIEF.md` S0–S8 IN FULL + the Bulwark deletion; MERGE PENDING conflict
  resolution vs main's `tempo-d0`/`descent-s4`.** 6 commits: **S0** FLOW=AGGRO + taunt funeral
  (taunt DELETED whole, passive flow + seeded progressive peel, `bespoke_defense()` seam, THREAT_DROP→
  FLOW DUMP) · **S1** Duelist base kit (`data/duelist/*`, graded parry/dodge, height law, partial-mit
  .90, WIND, ◆/DUMP, flow feed) + wired as the **playable tank default** (registry/raid/net v16/HUD/
  world-shell/codex/draft) · **S2** DuelistPolicy 3 tiers · **S3** `duelist_sim` + raid_sim carry ·
  **S4** DuelistBand + DuelistGauge (FLOW orb/WIND/◆ pips) · **S5** deck (Veteran/Wager/Bellows/
  Dancer creeds · Crucible/Scales/Whetstone/Flow modules · 14-boon POOL + GAZE + Ease dial + Hold-
  the-Line · 3 keystones · rig) · **S6** ⏱ EN GARDE signature CD · **S7** transforms Prise-de-Fer/
  Remise/Flèche + doors + Floor-2 ceremony data + Dancer-excludes-parry law · **S8** per-Seal streams
  = existing Seal texture (left to BOSS-PLAN). **⚙ Bill GO'd building the deck defaults (07-10) + the
  Bulwark deletion (07-10):** Bulwark is GONE — the Duelist is the only tank; `gear_probe` retired
  (its GearFx deed cells are Bulwark-kit-hosted → re-home to the Duelist deck later; GEAR code stays
  live in twinfang_kit), `meter_probe`/`draft_sim`/`commander_probe`/`raid_boon_probe`/both UI smokes
  re-hosted/updated for the reworked-tank creed+rig ceremony. **⚙ `threat_enabled` KEPT** (repurposed
  as the aggro-subsystem enable; content sets it) so solo sims stay byte-identical. **VERIFIED:**
  import clean · determinism PASS everywhere (raid + duelist + deckless + all decked builds) ·
  `ab-gate twinfang_sim` **BYTE-IDENTICAL** · WSLg visual pass (full Duelist HUD renders) · GREEN:
  registry/meter/draft_sim/commander/raid_boon/ui_smoke_raid/ui_smoke_map/raid_sim. Numbers first-cut
  (playtest); the existing Seals over-damage the new tank = the documented re-baseline BOSS-PLAN
  retunes. **⚠ MERGE:** main moved (tempo-d0 reworked `combat_core.gd`; descent-s4 touched `draft`/
  `raid_content`/`net_protocol`) → the merge needs careful `combat_core.gd` (FLOW=AGGRO vs governor/
  transforms) + `net_protocol` VERSION conflict resolution before landing. *(tank-w1 build session)*

- ☑ 2026-07-10 · main (docs only) · **`WELL-DRAW-BRIEF.md` (NEW, root) — THE DRAW HEALER BUILD
  BRIEF** (Bill: *"make a plan to implement the draw healer, then ill hand it off to opus"*) +
  ledger §C pointers + MENDER banner + CLAUDE.md index. The two 🟡 Draw passes sliced: **S0
  SKIN** (base cast + the one guarded engine touch — a victim-seat defer pool, the absorb
  idiom, byte-identical unlit) → **S1 D6 deck data** (theme tags · 7 boons · 3 keystones as
  opus-rarity · MILLRACE demote · Skim pair parked) → **S2 ⭐THE VIGIL module** (the Patient-
  Hand machinery generalized + the tremble read; Draw-only module offer) → **S3 transforms**
  (Cupped Hand · Deep Draw · Braid + doors + rig WHENs — ⚠ WAITS on the `wow-tempo-d0` merge,
  reuses its Floor-2 ceremony/door-gating) → **S4 policy+sims** (the ONE deliberate
  re-baseline: skin casting · spike-hold releases · transform piloting · theme/build cells;
  re-pin ab-gates after) → S5 render polish (deferrable). Scope-gate honesty: all catalog rows
  stay 🟡 — the brief names each doc'd lean as the build default (winners Vigil·Rapids·Eddy ·
  Millrace demote · SKIN base-book Draw-graded/Brim-plain · trio as designed · 8-cap trim
  stays PARKED); **Bill starting the build session = GO on the defaults**, per-line veto cheap.
  Found + noted in the brief: the eddy drift is per-cast STATIC (`well_kit.gd:263` — Current
  Reading grades band-entry, NOT mid-cast movement) · the Deep-Draw-vs-hold overrun order rule
  (deep band first, the hold catches the miss) · Loosed-at-Last needs a per-seat last-hit-tick
  field (diag-family) · the default comp contains an AI Well·Brim since THE PURGE (gates lean
  on it). Statuses untouched (no decisions taken). Next: Bill starts the Opus build session on
  the brief. *(draw-brief session)*

- ☑ 2026-07-10 · `well-draw` → main (`ed358aa`) · DRAW HEALER BUILD · **`WELL-DRAW-BRIEF.md`
  S0+S1+S2+S4 BUILT & MERGED** (Bill: *"okay go for it build it"*). **S0 SKIN** — the missing-heal
  film: a guarded per-victim defer pool in `combat_core` (`_tick_skin` drains a share of each hit
  as late damage over ~3s; never absorbs/heals; graded Draw / plain Brim; 1 charge; `SPELL_CAP`
  8→9). **S1 D6 reshape** — 10 new Draw boons across VIGIL·RAPIDS·EDDY (whitewater · shootGap ·
  eddyline · **flume** · secondHand · rideTremble · **loosedAtLast** · currentReading · deepEddy ·
  **glassRiver**), Millrace DEMOTED (opus→sonnet, Flume crowned), Skim pair (looseGrip/shortPour)
  parked. **S2 ⭐Vigil module** — the Patient-Hand hold generalized (`_hold_armed()` = creed OR
  module), Draw-only offer (new `WellModules.offer_ids(aspect)` + aspect-gated `_fw_module_offer_ids`).
  **S4 policy+sims** — the AI now films the tank ahead of danger telegraphs + banks/releases a
  held heal on the spike; `well_sim --build=vigil|rapids|eddy` cells + skin metrics. **Gates:**
  determinism PASS (well base+loaded+3 builds · raid 4 Seals · twinfang) · **twinfang byte-identical
  to the pinned baseline** — proof the shared `combat_core` touch is guarded-neutral for other
  classes · well/raid re-baseline is the SANCTIONED default-comp shift (Well·Brim now casts skin) ·
  no crashes. **DEFERRED:** S3 transforms (Cupped Hand · Deep Draw · Braid + doors — 🟡, blocked on
  the `wow-tempo-d0` Floor-2 ceremony, still docs-only) · S5 render polish (Vigil tremble / skin
  film / flume-frozen chrome — states already exposed in `observe`) · balance @ real fightlen
  (Bill's lever, owed row). Catalog Draw rows + ledger §C flipped 🔨. ⚠ the full `ab-gate.sh
  well_sim/raid_sim` couldn't run (parallel A+B OOMs the 7 GB box; testing removed mid-build) —
  byte-neutrality proven instead via the twinfang-vs-baseline checksum match + guard-by-construction.
  *(the Draw build)*

- ☑ 2026-07-10 · main (docs only) · §SYSTEMS/§GRAPHICS · **METER-PLAN.md (NEW) — the live meter
  leveled up (Bill's direct ask: "make it nice like Recount, see more details, plan the next
  level up").** Audit found the meter (`meter_panel.gd`, `5a6e4ad`) is already a real Recount
  (4 modes · ranked bars · per-source drilldown · NOW · frozen recap), and STATS PAGE v2 left
  the accounting deep (`boon_meter`/`series`/`seat.diag` all captured but **unread by the live
  view**). Plan = a 5-level roadmap, nearly all **view-only / diag-family** (byte-free gate):
  **L1** de-stale + polish (⚠ live bug — Alchemist+Well, the two default seats, have NO accent;
  `PRETTY` labels stale → move accent/labels to `ClassKit` hooks) · **L2** new modes from
  existing data (⚡AMPLIFY = boon_meter "who enables the raid" · DISCIPLINE from diag · row
  sparklines) · **L3** segments/run-history (consumes the deferred run-recap accumulator,
  BUILD-LEDGER `:270`) · **L4** window chrome (drag/resize/2-windows/export/compare-band) ·
  **L5** teaching layer (live missed-ops nudge · grade-tint · boon-lift callouts · school_of
  hook). **Recommended first slice: L1 + AMPLIFY** (fixes the accent bug + the most on-brand
  feature, data already reconciled by `meter_probe [8]`). BUILD-LEDGER §G row added; NOT built,
  at Bill's verdict. *(meter-plan session)*

- ☑ 2026-07-10 · main (docs only) · **`DUELIST-BRIEF.md` (NEW, root) — THE WAVE-1 BUILD BRIEF**
  (Bill: *"make a plan to implement the new dodge tank class… when ready I'll start you with
  Opus to do the code"*) + ledger §B pointer/row updates + CLAUDE.md index. The whole ledger
  Wave 1 sliced S0–S8: **S0 FLOW=AGGRO + taunt funeral → S1 base kit + Bulwark deletion (ONE
  merge, §A½ rule) → S2 DuelistPolicy → S3 duelist_sim/carry → S4 HUD (ClassBand rail) →
  [gates] S5 deck data → S6 EN GARDE (first signature-CD chassis game-wide) → S7 transforms +
  Floor-2 ceremony → S8 per-Seal streams.** Scope-gate honesty: **S0–S4 are verdict-free**;
  S5–S7 block on **gate ① the §3 deck board** (or Bill's explicit "build the defaults") +
  **gate ② the §10.6 points**; transform ACQUISITION is already locked by the Tempo GO.
  Found + noted in the brief: the 30 Hz wall on the 60ms parry window (build grading
  tick-native) · the GEAR-2 taunt-deed re-home (`combat_core.gd:904`) · DuelistPolicy needs a
  NEW seed salt (byte-exact-history rule). Statuses untouched (no decisions taken — catalog
  stays 🟡). Next: Bill starts the build session on the brief. *(tank-brief session)*

- ☑ 2026-07-10 · `../wow-tempo-d0` → **MERGED to main `63d4308`** · **TEMPO D0 BUILT** —
  `TEMPO-D0-BRIEF.md` slices **S0 governor + S5 laws `e9e83ae` · S1 deck data (v4) `8906d84` ·
  S2 resonance `8389695` · S4 transforms `45f4d27`**. The one asymptotic speed wall
  (`beat_rate_cap`/`window_min`, per-source clamps deleted); the WOUND pot + KEEN meter + ghost
  Double Time v2; the v4 slate (WOUND·EDGE·FINISH themes, new creeds/modules/keystones/boons,
  trim applied); 3-of-a-theme resonance; the Cadenza/Rondo/Tremolo transforms + the Floor-2
  1-of-3 ceremony + 6 doors + the Return rig WHEN. All kit-local + guarded (transform/creed/module
  gated → boonless byte-identical; the checksum is boss-HP+tick only). Parse-clean (`godot --import`).
  Catalog rows → 🔨, ledger D0 row → 🔨. **DEFERRED (untouched): S3 duos · S6 Set Piece · kick
  carriers · On the Beat. OWED: balance/gate sims (Bill paused testing 07-10) · HUD render of the
  new gauges (view-only observe fields landed) · live-raid RaidNet spec-carry of creed/modules/rig/
  transform (the standing class debt — unblocks the Well Draw ceremony §above).** *(the D0 build)*

- ☑ 2026-07-10 · main (docs only) · TEMPO §17.12 GO record + `TEMPO-D0-BRIEF.md` §0 + catalog
  flips + ledger D0 row → ✅ — **THE D0 GO (Bill: "1 yes… yes tri[m] and yes transform trio").**
  All three gates OPEN: **v4 LOCKED (Wound · Edge · Finish** — Uptempo ✂️→EASE knob, Whetstone/
  Strop ✅) · **trim CONFIRMED** (park Momentum · Held Breath · Efficiency, **Encore kept** — the
  stated lean, cheap veto) · **transforms ✅** (Cadenza · Rondo · Tremolo + Floor-2 ceremony +
  doors). **DUOS approved-but-DEFERRED** ("save that for later" — system ✅, 4 cards stay 🟡).
  **Build order: S0 governor → S5 law reworks → S1 deck data → S2 resonance → S4 transforms**;
  deferred shelf: S3 duos · S6 Set Piece · kick carriers · On the Beat. The build claim is
  Bill's to start (his ask); catalog rows flip ✅→🔨+SHA per merged slice. *(ability-audit
  session, the GO)*

- ☑ 2026-07-10 · main (docs only) · TEMPO-PLAN §17.12 (NEW) + `TEMPO-D0-BRIEF.md` (NEW, root) +
  CARD-CATALOG flips + ledger D0 row + CLAUDE.md index + artifact D0 tab — **TEMPO ABILITY AUDIT
  PASS 3: Bill's artifact notes folded + THE BUILD BRIEF.** Verdicts: **GOVERNOR ✅ · RESONANCE ✅
  · THE DUO ✅** ("make this rich and nice" → 4-duo slate 🟡: Blood Coda W×F · The Red Edge W×E ·
  Grand Finale E×F · The Reprise Rondo×W; armed at ≥2 cards from EACH theme — mixing's jackpot vs
  resonance's depth) · Pickup cut confirmed · **NEW LAW — NO-SINGLE-NEXT-HIT** (from his
  Sforzando/Count-In notes: Tempo-pace riders must cover X seconds or X hits, never "the next
  strike"; next-DUMP + Fermata-hold exempt) → built-card sweep: `fencersLine` REWORK 🟡 (next 3
  strikes) · `killingEdge` fallback → 3-strike · Count-In parked text → 4-beat call · Grand
  Pause reworded ("full combo (5/5)" — his "so just full?" = yes). **⚒ `TEMPO-D0-BRIEF.md` = the
  implementation plan he asked for** ("let me know and ill start it"): S0 governor + S5 law
  reworks buildable NOW; S1 deck-data → S2 resonance → S3 duos gated on the v4 lock + trim; S4
  transforms on the trio verdict; S6 Set Piece deferrable. *(ability-audit session, pass 3)*

- ☑ 2026-07-10 · main (docs only) · §CLASSES — **THE ABILITY PASS ×2 — DONE, both 🟡 AT BILL'S
  BOARD.** Duelist (`TANK-PLAN §10`): button audit (4 of 6, +1 slot EMPTY; DUMP named the
  storyless press) · ⏱ **EN GARDE** designed (the owed "wall" CD — invite/halved-leaks/double-flow
  amplifier, never a taunt costume) · 3 transforms w/ doors (**PRISE DE FER** parry-seize ·
  **REMISE** prime/commit · **FLÈCHE** dump-loads-onto-perfect-answer) · top-3 ladders refit w/
  v1.1 adopted (Dancer excludes parry transforms from the offer). Draw (`MENDER-PLAN §13`):
  **SKIN** — the missing-heal base cast (graded film, DEFERS a share of each hit into a ~3s drip;
  never absorbs/heals — not Ward, not Bloom's HoT; Bill's playtest gap closed) · 3 cast
  transforms w/ doors (**CUPPED HAND** Flash-from-the-Current · **DEEP DRAW** Mend's second band ·
  **THE BRAID** Cascade as a graded string) · 8-cap trim parked per Bill (counted 10→11, rides
  the compliance-trims ledger row). Catalog rows 🟡 (2 tables) · ledger rows (2 new + CD row 💡→🟡
  + trims note) same commit. Both acquisition rules ride Bill's Tempo verdict ③.
  *(ability-pass session)*

- ☑ 2026-07-10 · `stats-page` → main (`4b58d0b`) — **STATS PAGE v2: BUILT & MERGED.** THE FULL
  REPORT behind THE RECKONING's "◆ FULL REPORT" button — per-seat tabs · OFFENSE/DEFENSE/DISCIPLINE
  letter grades · PERFORMANCE BREAKDOWN (judgment %s · crit rate · times-hit · interrupts · aggro
  strays) · DAMAGE MIX + TAKEN share bars ("89% autos") · BOON IMPACT (+ RAID AMPLIFIERS: Glint
  ≈+585 / Sunder ≈+68 raid dmg, live) · MISSED-OPPORTUNITY top-3 (plain language) · per-spec rows
  (`recap_spec`: Twinfang "82% sharp / openings / perfect strikes") · DAMAGE-OVER-TIME graph (boss
  HP% + per-seat DPS). Engine all diag-family, NEVER checksummed: `meter_boon`/`boon_meter`,
  amplifier credit folded once in `damage_boss`, `credit_boon_factors` + Twinfang inline credit,
  aggro/stray + uncontested-cast counters (raid-only), `series` 1 Hz sampler. **VERIFIED:** raid_sim
  + twinfang_sim **byte-identical** (serial A/B vs `3ec9a06`); `meter_probe` ALL OK (+[8] boon
  reconcile: amp credit == extra dmg exactly, determinism folds boon_meter/series); `ui_smoke_raid`
  ALL OK; `screenshot_stats` visual probe renders both tabs. Boon impact: Twinfang inline FULL ·
  Alchemist/Well via proc-src + amp paths (ramp/heal boons → SIM-PLAN S4 card-lift). Ledger §G row
  🔨 + deferred run-recap row 🔴. **STANDING RULE:** future kit reworks add their `credit_boon_factors`
  lines. *(stats session)* — original claim text follows:
  §SYSTEMS/§GRAPHICS — **CLAIM: STATS
  PAGE v2 — the full post-fight report (Bill's direct ask; per-fight only, run recap deferred).**
  Audit found ~80% already engine-truth (`state.meter` per-source, `seat.diag` grades, the shipped
  `RecapPanel`/`MeterPanel`). Building the genuinely-missing layer: (1) engine accounting — new
  `meter_boon` funnel + `s.boon_meter`, amplifier-boon credit folded ONCE in `damage_boss` at the
  vuln stack, `aggro_pulled` event+diag on threat-overtake retarget, `kick_open_missed` on an
  uncontested INTERRUPTIBLE cast, `s.series` 1 Hz sampler for the dmg-over-time graph (all
  diag-family, NEVER checksummed); (2) per-kit boon-credit one-liners + a `ClassKit.recap_spec()`
  hook, backfilled for the 3 ACTIVE kits (Twinfang/Alchemist/Well; frozen Bulwark/Bloomweaver
  skipped) — the credit line becomes a STANDING RULE every future kit rework carries; (3) a new
  `game/ui/stats_page.gd` FULL REPORT screen (% breakdowns · damage-mix share bars · dmg-over-time
  graph · BOON IMPACT · MISSED-OPPORTUNITY top-3 · category grades), reached by a button on the
  Reckoning + `_show_end`. BYTE-IDENTICAL bar: ab-gate raid/twinfang/alchemist/well_sim (all new
  writes are diag-family); `meter_probe` gains a boon-bucket reconcile [8]; new `screenshot_stats`
  visual probe. ⚠ COLLISION: `combat_core.gd` also claimed live by `../wow-rails` (tuning-sweep) —
  additive changes, merge main often, reconcile at merge. *(stats session)*

- ☑ 2026-07-10 · `tuning-sweep` → main (`784e365`) — **TUNINGCONFIG LITERALS SWEEP: BUILT &
  MERGED (REFIT P4's split-out follow-up; determinism law #5).** The last six engine hard-codes
  in `combat_core.gd` → `TuningConfig` @exports with the exact old values as defaults:
  `open_stagger_base/step/jitter` (the fight-opening ability spread — also DRY'd, create_state +
  pack entry share ONE `_stagger_abilities` helper) · `silence_recheck` 0.4 · `chain_splash`
  0.28 · `dmg_buff_cap` 0.55 · `curse_answer_window` 2.0. Encounter-data fallbacks (melee
  every/max) stay — data defaults, not engine balance. GATES: **ab-gate raid_sim + twinfang_sim
  BYTE-IDENTICAL PASS** (60 seeds, all four Seals) · merged-tree bar 36/38 green — the two
  "fails" were externally killed heavies (Bill cleared the box), zero failure strings in either
  log; both passed in full on the pre-merge tree. **REFIT P4 CLOSES** — the one remaining line
  item (twinfang per-spec kit split) is DEFERRED INTO the Twinfang rework itself (same
  restructure, zero merge-conflict with the class wave; noted on the P4 ledger row). *(rails
  session v2 — END OF THE RAILS QUEUE)*

- ☑ 2026-07-10 · main (docs only) — **CLAIM: THE SEAL REWORK PLAN (`BOSS-PLAN.md` NEW) — DONE,
  🟡 AT BILL'S 10-VERDICT BOARD (BOSS-PLAN §V).** Delivered: BOSS-PLAN.md (laws · taunt-removal
  aggro spec · SealTune tuning spine · density ramp · visual-grammar law · 15-steal catalog +
  parked/rejected lists · 4 fight scripts to contract · 7 engine addenda · 6-slice build order);
  ripples amended in the same commit (TANK-PLAN §1c ×3 + §8.0 budget · WORLD-PLAN §raid-identity ·
  SEAL-PILLAR-PLAN superseded banner · MASTER §BOSSES rewritten · ledger rows · CARD-CATALOG
  THE GAZE lane 💡×2 · CLAUDE.md index). Research: 7-agent workflow (engine inventory + constraint
  sheet + Hades II/StS/AtO/duel-genre steals). Build gates: after `wow-descent-map` merge +
  Wave-1 flow-aggro. *(boss-rework session)* — original claim text follows:
  Bill's
  go (2026-07-10): the 4-Seal boss redo begins — fill the DESCENT §4 timer contract (5/7/9/12 min)
  with STRUCTURE (phases · adds · dialogue breaks), never +HP; update the Seals to the post-overhaul
  systems (flow-aggro peels · one-dodge · interrupt-by-ability posture · PACK engine); **Bill's
  aggro decision: TAUNT BUTTON REMOVED — aggro all-passive, tank regains by flow** (amends TANK-PLAN
  §1c, ripples handled); a tuning spine so length/speed/density are knobs (no playtest yet);
  mechanic-density ramp (Seal I teaches 1–2 answers, ladder ramps); per-Seal identity plans + a
  steal-catalog from Hades II / StS2 / AtO (+ research/ reuse). Bill's addenda (mid-claim): tank
  content designs against **DUELIST/WARDEN** (Bulwark ignored — dies with the Duelist base merge);
  respect the **two-stream law** (invisible melee chip = the tank's own tempo · telegraphs = the
  raid-wide authored beats); every mechanic must be **coherent in the game's visual grammar**
  (bars/flurries/rigs — nothing unrepresentable). Docs: BOSS-PLAN.md (new) ·
  §BOSSES · TANK-PLAN §1c amendment · BUILD-LEDGER row+collisions · CARD-CATALOG (aggro-boon idea
  rows) · CLAUDE.md index. ⚠ build slices will touch `raid_content.gd` — `wow-descent-map` owns it
  live (fight ladder bang); build starts only after that merge. *(boss-rework session)*

- ☑ 2026-07-10 · worktree `../wow-tempo-art` (branch `tempo-art`, docs on main) · §GRAPHICS —
  **SUPERSEDED 2026-07-12 by `GRAPHICS-PLAN.md`; branch frozen as salvage-only. ORIGINAL CLAIM:
  TWINFANG ART PASS v1.** Foundation review locked with Bill: painted layers on the
  existing `PoseRig2D` skeleton (native, $0, agent-authorable; **Spine Pro = per-actor upgrade
  door** behind `Actor2D` — StS2 is literally Godot 4 + Spine, so the ceiling is same-engine);
  AtO-cel AI art generated now (THEME re-skin risk accepted). Slices: ① juice pass (screen_post
  wire + stage hit-stop + smears + lunge) ② painted skin rig (`tex` limbs + `TwinfangSkinRig2D`)
  ③ flipbook FX + strike/evis/coup polish. Spec block in §GRAPHICS; ledger row §G. Touches
  `raid_hud` **combat region only** (post-fx node — ⚠ `descent-map` claim owns the map region of
  the same file; merging main often) + `stage2d/*` + new `game/art/actors/twinfang/`. *(this
  session)*

- ☑ 2026-07-10 · worktree `../wow-deck-tax` (branch `deck-tax`) — **THE DECK TAX (offline) — the
  JAILBREAK run-length ability-poison: MERGED to main (`7e5397f`).** The slice-4 deferred bite,
  offline. A DECK deal poisons ONE ability slot run-length; it fizzles in combat until you pay the
  Market to DEPRECATE it — the one curse that never expires on its own (giving DEPRECATE its teeth).
  `class_kit.poisoned` id-set + a **one-line gate** in `combat_core` perform()'s ability branch
  (fizzle + `poisoned_fizzle` diag + an `ability_poisoned` view event; empty set = **byte-identical**,
  proven by ab-gate `twinfang_sim` PASS) · `run_director.poisoned` (persistent) ·
  `raid_hud._launch_map_fight` injects the piloted seat's kit poison (AI/sims/online carry none) ·
  a dynamic `_deck_deal` bets a named un-poisoned loadout slot · `_add_curse` sets the poison,
  `_purge_curse` (DEPRECATE prefers the DECK curse, Cooling vents oldest) clears curse+poison ·
  `_expire_curses` KEEPS run-length curses (they never tick) · `curse_probe` §G. **Merged the
  tank-w1 landing mid-flight** (Duelist added / Bulwark+gear_probe deleted — clean auto-merge across
  class_kit/combat_core/raid_hud; also dropped the dangling `gear_probe` the tank left in verify-all).
  **Deferred:** online DECK (spec-thread the poisoned set through make_spec/RaidNet.build + a
  protocol bump — rides the online curse system) · polish: an in-combat grey/flash on the poisoned
  slot (the `ability_poisoned` event is emitted for it; the map header pip ships now). Verify:
  import clean · `curse_probe` ALL OK · ab-gate `twinfang_sim` BYTE-IDENTICAL · `market_probe`/
  `commander_probe` ALL OK · `ui_smoke_map` ALL PASS. *(raid-rebuild session)*

- ☑ 2026-07-10 · worktree `../wow-descent-s4` (branch `descent-s4`) — **DESCENT SLICE 4 — THE
  JAILBREAK (printed curse deals): MERGED to main (`a22c1ec`), 2 commits.** Built via a 5-reader
  recon whose key find corrected my prior: **TIMING is buildable** — `make_config()` returns a
  FRESH TuningConfig per fight and every grade reads its windows live, so a `window_tighten` mark
  scaling `s.config.strike_*` is a real windows−10% tax with ZERO per-boss work. **4a the curse
  engine (byte-identical when dormant):** `RaidMarks` gains two guarded keys on the proven
  carry→mark channel — `seat_hp_cut` (HP tax; auto-repairs because a mark clears each fight) +
  `window_tighten` (TIMING tax); `RunDirector.curses` (cap 2) + `deprecate_uses` (NOT in cp_view —
  read directly like tokens, offline-only this slice); the `raid_hud` curse core (`_add_curse` w/
  CAP 2 + the HARD RULE *no run-long TIMING curse*, `_curse_pips`, `_apply_curse_marks` fold+tick
  at launch, ECONOMY hooks — mint-halve in `_mint_seats`, price surcharge in `_market_price`,
  `_apply_map_fx` routes curse/regenerate/purge keys, the **DEPRECATE** market slot [the slice-3
  deferred slot, escalating price] + the **Cooling purge** fork, `ms.curses` feed, descent-start
  reset); `map_event_panel._fx_hint` prints the bite + charge/regenerate goods; new `curse_probe`
  (in verify-all). **4b the node LIVE:** `JAILBREAK_LIVE=true`, KIND_JAILBREAK dispatch →
  `_show_jailbreak` — two deals rolled on a (map_seed,node) rng via the proven `_map_stop` panel,
  both halves printed, WALK AWAY free, cap-2 "cell full" (no free-good exploit); a 5-deal gentle
  pool (V#4); `raid_map_sim` KIND_JAILBREAK walker case (sanctioned re-baseline). **Merged main
  mid-build** (SEAL-REWORK S0 + tempo — raid_hud auto-merged clean). **Deferred:** DECK tax
  (run-length ability-poison — the `perform()` gate is one line but the offline+online spec-thread
  is the cost) · welded-downside DRAFT boons (② door) · event-curse legs (③) · online (safe no-op,
  **NO protocol bump**). **Verify:** import clean · `curse_probe` ALL OK (engine + node
  end-to-end: cap-2/HARD-RULE, ECONOMY+HP+TIMING bites, both exits, ticking, a deal grants
  good+bite) · `market_probe`/`commander_probe`/`draft_sim` ALL OK · `ui_smoke_map` ALL PASS ·
  `raid_map_sim` map-gen determinism PASS (the walker case is deterministic by construction). ⏳
  **Deferred to a nightly run** (OOM-prone under concurrent load): `raid_map_sim` run-trace +
  statistical re-baseline · full `verify-all` · `net_map_smoke`. **Next:** slice 5 (minigames:
  CAPTCHA/BENCHMARK + extraction schematics) + the DECK-tax follow-up. *(raid-rebuild session)*

- ☑ 2026-07-10 · worktree `../wow-descent-s3` (branch `descent-s3`) — **DESCENT SLICE 3 — THE
  PROMPT MARKET + PER-SEAT WALLETS: MERGED to main (`fd8b895`), 3 commits.** Built via a 6-reader
  recon (buildable-vs-deferred scope). **3a per-seat wallets (V#11):** `Draft.mint_diag(diag,cfg,
  cls)` mints each seat off its OWN `seat.diag` — `mint(state,cls)` delegates so it stays
  BYTE-IDENTICAL (draft_sim green); `raid_hud._mint_seats` credits all 4 wallets post-fight; the
  AI-draft shared-bank mirror is deleted → **AI raiders START EARNING** (before, `Draft.mint` read
  only the is_player mirror, so AI minted nothing); `commander_probe` re-pointed to per-seat
  independence. **3b rerolls-out (§11 #3):** `run.regenerate` charges are the ONLY reroll —
  `Draft.reroll` spends a charge (same draft_rng draw), `lock`/`reroll_kept`/`REROLL_COST`/`LOCK_
  COST` deleted, `draft_screen` shows "REGENERATE (n)" + drops LOCK, Hot Reload → +2 charges;
  `draft_sim` `_test_lock`→`_test_regenerate`. fight_seed never touches draft_rng → NO fight
  shift, only draft_sim's transcript re-baselines. **3c THE MARKET:** `RunMap.MARKET_LIVE=true`;
  new `MarketScreen` (THE SCRAPER); `_show_market` rolls a (map_seed,node)-seeded stock — CURIO ×2
  (unlocked pool, priced 6/8/10 by rarity) · REGENERATE (4⏣) · PATCH (5⏣), ~+30%/floor; per-seat
  BUY + **AUTO** (AI spend own wallets, banter); KIND_MARKET branch (mandatory, no-default=
  soft-lock); post-Seal recovery MARKET PHASE; Hashgrinder reframed (×2 income → market −1⏣);
  `raid_map_sim` KIND_MARKET case + `tokens@market` diag + a flat mint estimate (sanctioned
  re-baseline); new `market_probe` (in verify-all) drives the real HUD end-to-end. **Merged main
  twice mid-build** (tuning/meter/tempo-d0 — the tempo `run_state.transform` + `draft.offerable`
  doors auto-merged clean with my `regenerate`/`reroll`). **Deferred (dependency absent):** +1
  BACKUP (no wipe budget — printed SOON) · DEPRECATE (curse-purge=slice 4, boon-scrap=follow-up) ·
  online market/wallets (server has no purse — a safe no-op fallthrough, **NO protocol bump**).
  **Verify:** import clean · `market_probe`/`draft_sim`/`commander_probe`/`gear_probe` ALL OK ·
  `ui_smoke_map` ALL PASS · `raid_map_sim` determinism (seed1==seed1 + descent invariants) PASS on
  main. ⏳ **Deferred to a nightly run** (OOM-prone under concurrent load): the `draft_sim` +
  `raid_map_sim` STATISTICAL re-baselines (rerolls-out transcript + the live-market walk are the
  sanctioned shifts) · full `verify-all` · `net_map_smoke`. **Next:** slice 4 (THE JAILBREAK
  printed curse deals). *(raid-rebuild session)*

- ☑ 2026-07-10 · worktree `../wow-descent-s2` (branch `descent-s2`) — **DESCENT SLICE 2 — THE
  LEGIBILITY UI PASS: MERGED to main (`1f5e051`), 2 commits, ZERO file collisions with the
  tuning-sweep merge landing alongside.** Built via a 6-reader recon workflow (the one that
  disambiguated the THREE unrelated "integrity"s — see below). **2a display (byte-identical):**
  node doors print a one-line reward CONTRACT (on hover + tooltip; WILD stays sealed) + fight-tier
  ▮ pips (normal/elite/Seal, drawn as pip rects) · header restructured into the 3 meters
  (⏣ TOKENS · ⚡ LUCK · ⏻ CHARGE) + per-seat wound pips + a reserved curse-pip row + a one-shot
  first-⏻ teach + a currency legend, kind legend de-GATE'd, ⏣ moved off the peripherals line ·
  check/wager buttons print BOTH legs pre-commit ("on ✓ … · on ✗ nothing lost") via new
  `win_fx`/`lose_fx` descriptor fields folded with the wager stake (offline + online) · display
  renames (⚡"entropy"→"LUCK", "eligibility base"→"base odds", "feed ⚡ to bias"→"spend ⚡ LUCK…",
  fx-hint "integrity"→"party HP", THE ENTROPY→THE LUCK DAEMON) · §9.8 "REROLL THE FLOOR"
  flavor-lie reworded to what it does · orphan `luck_profile.gd.uid` deleted (§11 #14 tail).
  **2b THE RAID INTEGRITY KILL (§11 #2):** `map_check` integrity/desperation check-row deleted ·
  overtime "Bill it" wager stake integrity→tokens · rollback `catch` orphan `"integrity":"steady"`
  removed · the 5 tickets + SPRINT RETRO + Ticket Stub re-priced (drop dead heal/patch, KEEP
  repair/mana, pay ⏣) · `map_wager_probe` decoupled from content to a synthetic tokens wager.
  **Recon verdict that shaped it:** three things share the word — (A) `RaidNet.integrity()` net
  desync hash (frame "ih", untouched — `integrity_probe` stays green), (B) the campaign HP-frac
  carry (already retired-for-combat, §12 KEEP), (C) the currency (the kill). **NO PROTOCOL BUMP.**
  Tokens-primary re-price → raid_map_sim FIGHT checksums unchanged (repair/mana held; ⏣ is
  sim-carry-invisible), only the retired-integrity/fracs REPORT column shifts. Names BACKUPS/
  REGENERATE/DEPRECATE **reserved only** (mechanics = slices 3–5; the draft REROLL economy is
  untouched — that cut would shift `draft_sim`). **Verify:** 2a byte-identical proven (ab-gate
  `map_check_sim` + `map_check_online_probe`); light green (import · `map_wager_probe` ALL OK ·
  `ui_smoke_map` ALL PASS · `map_check_sim` ALL PASS · merged-tree parse + smoke). ⏳ **Heavy
  verify DEFERRED to a nightly run per Bill** (OOM-prone under concurrent box load): `raid_map_sim`
  2b baseline re-record · full `verify-all` · `net_map_smoke`. **Next:** slice 3 (PROMPT MARKET +
  per-seat wallets). *(raid-rebuild session)*

- ☑ 2026-07-10 · worktree `../wow-descent-map` (branch `descent-map`) — **DESCENT SLICE 1 — THE
  MAP BANG: MERGED to main (`ee18e05`), verify-all 40/40 GREEN ×2 (branch + merged tree).** The
  one deliberate `raid_map_sim` re-baseline, delivered: **4-floor FLOORS** (Vorathek→F1 Seal,
  Rings 3-2-1-0; rows 6/8/8/9 = 14/20/20/23 nodes) · **new node kinds** (ELITE live: REINFORCED
  trio + ⏣ bounty + curio-roll drop event, keystone slot reserved for the deck slices ·
  MARKET/JAILBREAK/MINIGAME flag-stubbed via `RunMap.effective_kind` to honest fallback kinds —
  map rng locked ONCE, interiors flip flags in slices 3–5 · WILD live, payload rolled at gen,
  tier printed) · **gen invariants proven in-sim** (pre-Seal valley band · elite placement laws ·
  market+elite reachable from every route — `_prove_descent` 40 maps/floor PASS) · **V#8 Prior
  DELETED end-to-end** (`luck_profile.gd` gone; profile/run_state/run_director/map_check/map_fx/
  UI/net/8 probes swept; descents open on baseline ⚡; prior event-fx → entropy) · **THE FIGHT
  LADDER** (per-floor packroll F1 55/35/10 → F4 15/45/40 · skirmish enrages 150/175→95/110 ·
  filler tier per FLOORS row; Forge body enrages untouched — zone-shared, balance-pass item) ·
  salvage `1:` row · protocol **v15**. Gates: solo `map_sim` + `raid_sim` **byte-identical**
  (ab-gate); post-merge sanity green; +fixed the pre-existing red `ui_smoke_map` (stats-v2 FULL
  REPORT button hung the walker — `b4d9ff3`). **Remaining slices:** 2 legibility UI (contracts/
  pips/3-meters/renames/integrity kill) · 3 Market+wallets · 4 Jailbreak · 5 minigame interiors ·
  6 QUEUE/tickets re-price · server pack pass · ceremony-time probe. *(raid-rebuild session)*

- ☑ 2026-07-10 · main (docs only) · TEMPO-PLAN §17.11 (NEW) + **DECK-LAYOUT §5 LAW CHANGE** +
  CARD-CATALOG flips + ledger rows + artifact D0 tab — **TEMPO ABILITY AUDIT PASS 2 (Bill's
  verdicts on §17.10) — DONE, 🟡 AT BILL'S BOARD.** His steers: pass-1 spells *"not great"*,
  +2 = button bloat → **ABILITY LAW tightened +2→+1 allowance, ceiling 6** (DECK-LAYOUT §5;
  ripple: Alchemist reshape trims to ONE slot — Wave-2 note added); freshness moves to his idea —
  **ABILITY TRANSFORMS** (drafted cards that REWRITE Evis/Coup, ≤1 transformed ability/run,
  Floor-2 1-of-3 lean, each a DOOR gating 2 sub-boons; Hades-hammer steal, Tempo pilots): 
  **CADENZA** (Coup at any Flow ≥2, scales with Flow spent) · **THE RONDO** (post-Coup 4-beat
  return phrase — the spell reborn, button deleted) · **TREMOLO** (Evis becomes a ≤3-press graded
  string). Tempo leaves its +1 slot EMPTY (Count-In parked 🔮; Sforzando/Pickup ✂️ → A5).
  **Crit-vs-speed answered (v4 branch proposal 🟡): WOUND · EDGE · FINISH** — speed is the
  CHASSIS, so SWIFT demotes to generics with NO ladder rungs (Uptempo → the EASE dial's
  beat-speed BITE face · Quickstep/Through-Line → STRIKE generics · Double Time v2 → class
  keystone) = NOT a hidden 4th branch; THE EDGE enters at 2 new cards (Whetstone entry creed —
  Bullseyes-can-crit IS the A7 opt-in · The Strop KEEN-gauge module; A7 boons + Hone stand).
  Governor stands regardless. 5 v2 verdict points on the artifact. *(ability-audit session,
  pass 2)*

- ☑ 2026-07-10 · main (docs only) · TEMPO-PLAN §17.10 (NEW) + CARD-CATALOG D0 addendum + ledger
  rows (D0 + pillar-#3) + the Slate-Machine artifact D0 tab — **TEMPO ABILITY AUDIT (Bill's D0
  pass) — DONE, 🟡 AT BILL'S VERDICT.** His four asks answered: **① the +2 button slots** — 4
  spell candidates (SFORZANDO accent-arm · THE RONDO post-Coup echo · THE COUNT-IN warband call ·
  THE PICKUP window-steal, SWIFT-gated), hold ≤2, every one carries a WHEN; + the no-button Coup
  fix: **Evis = standard interrupt carrier, Coup = premium kick** (pillar-#3 open Q now has a
  proposal). **② abilities are DOORS not islands** (lean) — each gates 2 boons into offers +
  adds 1 rig WHEN (the Hone/A7 offer-gating precedent generalized); Da Capo's park reverses into
  the Rondo door. **③ set bonuses: NO stat 2pc/4pc** (threshold trap; commitment already paid 3
  ways) — **RESONANCE** (3-of-theme auto-lights one tiny rotational perk, the Hades-2 Infusion
  steal) + optional cross-theme **DUO** (Blood Coda) as the counterweight. **④ the SWIFT speed
  wall is the ENGINE's** (30 Hz: Double Time v1's 0.08s rune = sub-tick Bullseye) — **SPEED
  GOVERNOR** law (one clamp pair, all sources asymptotic) + **DOUBLE TIME v2 = ghost notes**
  (optional half-beat pips, beat never passes the governor); swap menu kept warm (EDGE cheapest ·
  PUNISH pairs with Coup-as-kick · BAND = the Count-In, not a branch). 5 verdict points on the
  artifact D0 tab. *(ability-audit session)*

- ☑ 2026-07-10 · `class-bands` → main (`b4e8d26` bands · `ee58124` gauge base) — **CLASSBAND
  REGISTRY + SHARED GAUGE BASE: DONE (REFIT P4's last big rail).** THE BANDS: `game/ui/bands/` —
  ClassBand base (shared orb/rune-rail/guard shell + `for_hud` picker keyed off `_seat_cls_now`,
  the view twin of ClassRegistry) · TankBand · BladeBand (Tempo+Fermata incl. the coil
  hold-release) · BrewBand (ALEMBIC + brew holds) · HealerBand (click-cast + shared castbar) ·
  WellBand (DRAW grammars) · BloomBand. **raid_hud sheds ~630 lines** — ~25 per-class widget
  members → ONE `_band`; the 4-way match on build/render/keys/mouse/events → band routing;
  adding a class = one band file + one for_hud arm. **THE GAUGE BASE** (Bill's scope: "the
  obvious shared stuff, grow from there"): `game/ui/class_gauge.gd` — the VERDICT FLASH
  (flash()/verdict_alpha()/verdict_live(), four hand-rolled copies collapsed), the PULSE clock
  (per-widget rates kept), per-frame decay+redraw plumbing (`_tick` hook), the standard
  `on_event` entry; all 7 widgets retrofitted, draw STYLE untouched per widget — the art-era
  retheme lands once. **Also fixed en route:** both glint indicators (dead since `855ac2f` —
  stale `seat.vars` readers), the `show_result` rename mangle (75 masked script errors — the
  "ALL OK tail ≠ clean" lesson, now in memory), and the `rift_ui.cfg` ERROR-spam on every combat
  boot (has_section_key guard). ⚠ zero class-content change (Bill's mid-rework carve-out).
  GATES: verify-all **ALL GREEN (40 scripts)** post-fix · WSLg visual passes ×2 (bands 5/5,
  gauge-base spot-checks — brew banner drawn through the new flash path). **REFIT P4 now fully
  built except: TuningConfig literals sweep (split-out claim) · twinfang per-spec kit split.**
  *(rails session v2)*

- ☑ 2026-07-10 · main (docs only) · §REALMS/WORLD · `THEME-PLAN.md` (NEW) — **THE SETTING
  riff v0**: the world fiction born — **the Gilded Age → the Binding → the Quiet → the
  Return** (a new generation *chooses* the dive: gold-rush on the grandparents' locked
  estate, explicitly NOT post-apocalyptic; no rift, no invaders — every Seal a human-made
  WONDER, "humans being humans"; the AI realm = one wonder among wonders, joke contained +
  thematically home). Cohesion rule: **a region wears its Seal** (one cause for all zone
  variety; 6 seal seeds tabled). **TONE LAW**: heavy history / chipper present, registered
  cast, combat-never-the-joke generalized world-wide. **NAMING LAW**: system nouns = one
  global name forever, content nouns wear costumes, visual grammar constant → §REALMS
  global meta-layer REVERSED (haiku/sonnet/opus + tokens gag → Realm-1-local; leak audit
  triaged incl. ARMORY-v3 flag + Vorathek re-skin note). Ledger §D row added. **7 open
  dials at Bill (THEME §6):** origin · why-now · rarity names · module rename · title ·
  org · mystery-volume. *(theme session)*
- ☑ 2026-07-10 · main (docs only) · §SYSTEMS GEAR / `GEAR-CATALOG.md` §ARMORY-v3 (NEW) —
  **CURIO ARMORY v3 — the universal BIG SLATE: DONE, ~40 rows AT BILL'S NARROWING VERDICT
  (keep ~15–20).** Mined `research/` (Hades · StS · AtO · WoW · E33 · wildcards) into 10
  groups: FIGHT FORTUNE (Surge Protector · Turbo Button · Prompt Injection — the anti-heal
  slot) · WAR CHEST (Cold Wallet Balatro-interest · Buy Now Pay Later) · LOOT GAME (Dial-Up
  Modem slow-reveal · Foil Printer · Speedrun Timer thermometer · Combo Counter groove-chain) ·
  MAP DECK · CURSE-EATERS (Malware Miner / Antivirus Trial / Jailbroken Firmware — rides
  DESCENT §7) · TEAM PERIPHERALS (Rubber Duck · Pizza Fund · Golden GPU) · DEVIL DEALS (EULA
  Unread · CTRL+Z — the StS boss-relic tier) · THE CHASE WALL (Konami Code · Red Stapler
  anti-set · Big Red Button — brutal sev-III/BLOOD deeds per Hades Testaments) · THE TOYS
  (RGB Kit · Lo-Fi Stream · Mechanical Keyboard) · 2 new SET PAIRS. **NEW local law: THE FEEL
  BAR** — every row (Haiku included) names its visible/audible MOMENT, per Bill's "want to
  feel them even the lower weaker ones." All rows pass the v2 THREE HARD RULES; no G/H
  actives; 5 rows ⚠ flagged for rulings; rejected-by-rule list recorded so the dead stay
  dead. Ledger §D row + §3 verdict entry added. **NEXT:** Bill narrows → survivors get real
  deed homes (boss pages vs universal tables) → build joins the v2 pool work in
  `gear_catalog.gd`. *(curio-slate session)*

- ☑ 2026-07-10 · `kit-hoists` → main (`94b1147`) — **CLASSKIT HOISTS: BUILT & MERGED (REFIT P4,
  byte-identical DRY; the rails session's FINAL item — Bill's stop order).** `var boons`/`var
  modules` + `_b()`/`_m()`/`_tt()` hoisted to the `ClassKit` base; 21 duplicated blocks deleted
  across all 5 kits (−47 lines). NOT hoisted: `_has_payloads()` — bodies differ per class (it's
  content, not plumbing). GATES: **ab-gate twinfang_sim + well_sim BYTE-IDENTICAL PASS** ·
  **verify-all ALL GREEN (40 scripts)**. **RAILS SESSION CLOSED (Bill: "finish current task then
  stop") — P4 remainder for a future claim: ClassBand registry + shared Gauge base (the raid_hud
  refactor; needs a WSLg visual pass) · TuningConfig literals sweep (split out — judgment-heavy)
  · twinfang per-spec kit split. The night's rails: `b17ff52` (Profile/roster/run_seed/split-law)
  · `4779f59` (net integrity hash, protocol v14) · `855ac2f` (vulnerability stack, rebaseline) ·
  `fcee675` (class registry) · `94b1147` (kit hoists).** *(rails session — ENDED)*

- ☑ 2026-07-10 · `class-registry` → main (`fcee675`) — **CLASS REGISTRY: BUILT & MERGED (REFIT
  P4 — `class_id → factory`; the seam that gates net spec-carry of arbitrary builds).** NEW
  `data/class_registry.gd`: ONE lazy-init table (zero load-order risk in the class cache) per
  class — seat · display · aspects · seat factory · RunState starter · policy factory
  (byte-exact seed salts, incl. Bloomweaver's no-rng quirk — changing one is a lockstep event,
  says so on the table) · kit script name. Rewired: `RaidContent._healer/_blade/_caster_seat`
  dispatchers · `RaidNet.make_policy` (28-line ladder → 3 lines) · `raid_hud._make_seat_run` ·
  the world_shell healer toggle now CYCLES `classes_for_seat("healer")` — a third healer class
  appears in the Commander UI with zero UI work. The registry INDEXES content (Callables at the
  factories in their homes), never authors it. `RaidNet.cls_of` deliberately left byte-exact
  as-is (12 lines, feeds specs — not worth the wire-format risk). GATES: **ab-gate raid_sim
  BYTE-IDENTICAL PASS** (every Seal × every seat factory × every policy through the registry) ·
  NEW `sim/registry_probe.gd` (19 checks — salts locked via `DetRng.state_hash`) · **verify-all
  ALL GREEN (40 scripts)**. *(rails session — queue: ClassBand+Gauge base → ClassKit hoists)*

- ☑ 2026-07-10 · main (docs only) · TEMPO-PLAN §18 (NEW) + CARD-CATALOG Fermata section (NEW) +
  ledger flips — **DECK MACHINE row D8 (FINAL): THE FERMATA v6 — DONE. 🏁 BOTH MACHINES
  COMPLETE: 9 slates + 9 decks, all 🟡 at Bill's board; crons retired.** D8 itself: v5 pool →
  🔨 catalog (ladder-tagged Brinkman/Rested Blade/Window-Setter) + KIT A Afterimage (Doubled
  Dark/Deep Shadow/Procession/THE COMPANY OF KNIVES — anchored on built twinEcho+phantom) +
  KIT C Cold Hand (**Kept Books** — renamed from The Ledger, Duelist Red-Ledger family ·
  Patient Books · No Flourishes · THE RECKONING STROKE) at 🟡. Keystone cap-5 theme-weighted
  rule proposed the 4th time (accept once = the pattern). **The machine's full output:** every
  class/spec has a slate + a deck at verdict · CARD-CATALOG back-fills closed (Cask/Brew/Well/
  Fermata + new Warden/Bloom/Tempo/Duelist-kits sections) · 9-row cross-deck distinctness
  ledger · 8 research sweeps · ~40 tension points consolidated per-deck. NEXT = Bill's
  verdicts; the `/slate-loop` skill survives for re-runs. *(slate-machine session, deck tick
  04:34)*

- ☑ 2026-07-10 · main (docs only) · ALCHEMIST-PLAN §12 (NEW) + CARD-CATALOG Brew section (NEW)
  + ledger row — **DECK MACHINE row D7: THE BREW ASSEMBLY — DONE, one merged board.** Built
  pool → 🔨 catalog rows (the Brew's back-fill drift closed), ladder-tagged Slow Boil/Cannonade/
  Anchor. §8's 11 proposals cataloged 🟡 and SLOTTED (P3/P4/P5 = one keystone per incumbent
  ladder — the audit's zero-keystone gap closes cleanly). Kits formalized 🟡: G Tightrope
  (Wire-Walker/The Save/Practiced Wobble/THE PENDULUM) · P Prognosis (Diagnostician/Terminal
  Course/Called Shot/THE AUTOPSY REPORT) · S Sidearm (Venom-Tipped/Quick Draw + Silencer/
  FUSILLADE **⏸ pillar-parked**). **The keystone-pool math flagged:** 6 candidates vs the 2–3
  law — cap-5 theme-weighted proposed, Bill trims. **Cross-spec rename executed:** Cask kit-H
  Practiced Hands → **MUSCLE MEMORY** (Brew's built Practiced Hand owns the family); Tightrope
  theme-name/Twinfang-boon word-share noted for board readability. One verdict sitting now
  covers §8+§10+§12. 4 tension points (§12.3). *(slate-machine session, deck tick 04:19)*

- ☑ 2026-07-10 · main (docs only) · MENDER-PLAN §12 (NEW) + CARD-CATALOG Draw rows + ledger row
  — **DECK MACHINE row D6: THE DRAW RESHAPE — DONE, 🟡.** Winners = Vigil · Rapids · Eddy (§10
  ranking; the Skim parked, filed). **The headline: THE MILLRACE DEMOTION** — the built keystone
  (every 3rd cast free) is economy in a keystone slot and fails Bill's own locked bar; proposed
  boon-demote with **THE FLUME crowned** as the Rapids keystone (the §10.7 reconcile, resolved
  at his board — it touches a built card, so his verdict flips it). **⭐THE VIGIL module
  promoted** (the §1 transformer note made real — trembling held heals; the one real kit
  addition). New 🟡: Second Hand · **Ride the Tremble** (renamed — Warden owns White Knuckles) ·
  Whitewater · Shoot the Gap · Eddyline (pardon-check re-run: priced) · Current Reading (the
  Eddy→Rapids bridge) · Deep Eddy + keystones LOOSED AT LAST / THE FLUME / THE GLASS RIVER.
  Entry law from built creeds again (Patient Hand/Narrows/Eddy). Unfiled built boons
  (Loose Grip et al) = effect-filing at build, stated. Sibling gate held (zero landing/party
  cards). 4 tension points (§12.5). *(slate-machine session, deck tick 04:04)*

- ☑ 2026-07-10 · main (docs only) · MENDER-PLAN §11 (NEW) + CARD-CATALOG Well section (NEW —
  the shared+Brim back-fill, closing that ledger drift) + ledger row — **DECK MACHINE row D5:
  THE BRIM RESHAPE — DONE, 🟡.** Winners = Low Catch · Overflow · Glintsmith (§9 ranking; the
  Pulse's cards wait, filed). The sweep: BROKE none · FADED **Wide Brim → the EASE dial** ·
  DEAD none · OPENED = the three lanes, and every one ENTERS from a BUILT creed (Brink/Levee/
  Shallows — the reshape's luckiest fact). New at 🟡: Knife's Edge · **Cool Head** (renamed —
  Brew P8 owns "Steady Under Fire") · Runneth Over · Pressure Head · Whetstone Waters · The
  Primed Vein + keystones **THE UNDERTOW / THE FLOODGATE / THE GILDED HOUR** (pool = 4 with
  built High Tide, theme-weighted offers). Skeptic kills/catches: **Blind Pour killed before
  birth** (duplicate of the BUILT Blindfold) · Undertow-vs-Benediction rung distinction
  recorded · Brink Bell stays the one counted pardon. EASE knobs listed. 4 tension points
  (§11.5). *(slate-machine session, deck tick 03:49)*

- ☑ 2026-07-10 · main (docs only) · ALCHEMIST-PLAN §11 (NEW) + CARD-CATALOG Cask section (NEW,
  35 rows) + ledger row — **DECK MACHINE row D4: THE CASK DECK ASSEMBLY — DONE.** The locked §7
  slate (24 KEEP) is **hard-copied into the catalog at ✅** (approved-not-built; flips 🔨+SHA as
  slices 3–5 merge — the back-fill drift for this spec is CLOSED) with §9.1 ladder tags (Blend
  Line · Gauntlet · Tap List). The three §9 additive themes formalized as drop-in KITS at 🟡
  (T Twin Casks: Double Barrel/Clean Handoff/Rolling Boil/Bottling Line · H House Recipe:
  Signature/Practiced Hands/Never Change/Dynasty Pour · R Taproom: On the House/Private
  Reserve/**CLOSING TIME** — renamed from Last Call, Brew-boon collision caught by the
  distinctness check). Combined-pool gates: trios clean · Private-Reserve/Cellar integrates ·
  Never-Change×Single-Malt = the flagged monk build · **Solera×House-Recipe echo-ease tune
  flag** recorded for build. EASE knobs: band width · cook grace · peak width · strain
  softness. 4 tension points (§11.3). *(slate-machine session, deck tick 03:34)*

- ☑ 2026-07-10 · `vuln-stack` → main (`855ac2f`) — **GENERIC BOSS-VULNERABILITY STACK: BUILT &
  MERGED (REFIT P4; the "build FIRST" rail TEAM-COMP + Depth + Well-glint ride).** ⚠ THE
  DELIBERATE REBASELINE LANDED — ab-gate baselines pin per-SHA, so gates from here compare
  against ≥`855ac2f`; well/raid checksums shifted ON PURPOSE (glint semantics widened), and the
  neutrality claim was PROVEN, not assumed: **ab-gate twinfang_sim + alchemist_sim BYTE-IDENTICAL
  PASS** (empty stack = 1.0). Shipped: `boss_state.vulns` window list ({seat_i·mult·until·src},
  −1 = raid-wide) + `CombatCore.add_vuln/vuln_until/vuln_mult` — ONE fold point in `damage_boss`
  AND the stat-block ally contrib; same (seat,src) REFRESHES (never self-stacks), distinct
  sources multiply, lazy tick-driven prune (det-safe). Well GLINT migrated onto the stack —
  closes the co-op gap (a glinted FULL-fidelity/human blade now cuts deeper too, not just
  stat-block allies; keptLight extends via `vuln_until`; well_sim instrumentation follows). The
  dead boss-level `exposed_until_tick`/`expose_amt` RETIRED (only reader was the purged
  Voidcaller). NOT migrated by design: sunder/debilitate (decaying scalars at the same funnel) ·
  bulwark payExpose (dies with the tank wave) · Shining Hour (conditional state). **TEAM-COMP
  school amps + Depth affix windows now have their fold slot.** GATES: `sim/vuln_probe.gd` (12
  checks) · both ab-gates byte-identical · well_sim det PASS both aspects + loaded deck ·
  **verify-all ALL GREEN (39 scripts)**. *(rails session — queue: class registry →
  ClassBand+Gauge → hoists)*

- ☑ 2026-07-10 · main (docs only) · BLOOM-PLAN §4 (NEW) + CARD-CATALOG Bloomweaver section
  (NEW) + ledger row — **DECK MACHINE row D3: THE ORCHARD CLOCK DECK v0 — DONE, 🟡
  PROVISIONAL.** Core unpicked, so the deck is authored on **A (the slate's #1)** to make the
  core verdict CONCRETE — B/C/D pick = free re-run. 4 creeds (Long Summer EASE · Hothouse
  GREED · Mulchwork — wilts→MULCH tempo, rewritten from a pardon mid-pass · **THE WILD ROWS
  wild** — the garden plants itself) · 2 modules (**the Almanac** — the roster's FIRST
  forward-timeline gauge, HUD cost flagged · the Cider Press waste→Sap valve) · 11 boons ·
  3 rig WHENs (the Rescue = the clutch premium) · 2 keystones (FULL BLOOM chord · THE ORCHARD
  ETERNAL — skeptic fix: the golden arc ends on a WILT, never on hits taken) · ✦ Harvest Home ·
  **THE SEASON** CD · EASE knobs. Gates: 3 dream drafts · trio flag (three-POWER offer) ·
  distinctness rows (Twin-Casks stagger kinship · Full-Bloom vs Bottling-Line recorded).
  5 tension points (§4.8 — the core pick itself is #1). Meadow = sibling pass after the core
  locks. *(slate-machine session, deck tick 03:19)*

- ☑ 2026-07-10 · main (docs only) · TANK-PLAN §9 (NEW) + CARD-CATALOG D2 swap-kit rows + ledger
  flip — **DECK MACHINE row D2: THE DUELIST v2 — DONE, 🟡.** v1 is at Bill's LIVE board, so the
  pass deliberately does NOT re-author: **① the v1.1 RECONCILE** (Quick Wrists + Roll With It →
  the EASE dial per standing law · the FLOW module = 4th Floor-1 candidate, 3-of-4 offer
  proposed · Hold the Line re-keys onto FLOW · GUARD trio resolved to Warden §8 · Crucible
  peel-note · DUMP=carrier note) + **② three SWAP KITS pre-authored to card level** (M Matador:
  Cold Blood/Late Answer/Toro/LA ESTOCADA · S Scarlet: Red Ledger/Paid in Iron/Deep Cut/CRIMSON
  DIVIDEND · W Stormweave: Storm Footing/Eye of the Storm/Thread the Needle/Rolling Thunder/
  TEMPEST ANSWER) — **any 2–3-ladder verdict maps to a ready deck, no re-pass.** Skeptic catch:
  the Estocada/Reckoning-Stroke freeze-beat rhyme (two still-beat finishers roster-wide) —
  recorded, Bill's call. 5 tension points (§9.4). Distinctness row 3. *(slate-machine session,
  deck tick 03:04)*

- ☑ 2026-07-10 · main (docs only) · TANK-PLAN §8 (NEW) + CARD-CATALOG Warden section (NEW) +
  ledger flip — **DECK MACHINE row D1: THE WARDEN DECK v1 — DONE, 🟡 AT BILL'S VERDICT.**
  Winners = §6's recorded ranking top-3 (**Payload · Slam · Rampart**). From-scratch authoring:
  5 creeds (Sentinel EASE · Ballast/Drumhead/Deep Keel theme entries · **THE MONOLITH wild** —
  BLOCK deleted, one-button hold economy, the Dancer's mirror) · 3 modules (Coil · Aftershock ·
  the priced Bulwark Stance) · 12 boons (**the 🔮 guard trio re-homed to 🟡**: Return to Sender ·
  Cheap Iron · The Wall; new: Heavy Shipment/Special Delivery/Offensive Guard/Meet It Head-On/
  Drumfire/Second Wind/White Knuckles/The Push) · 3 keystones (Siege · Breakwater · Immovable —
  all engine-free) · **THE GATE** signature-CD (wind-scaled warband wall — the owed §1b slot) ·
  EASE knobs. Gates run with evidence (4 dream drafts · trios flagged the three-bread offer ·
  Feather-Step/Cheap-Iron collision → fold proposal · anti-patterns clean · AI thresholds).
  3 skeptics: 1 kill (Iron Reserves — bread flooding), Drumfire/Rally rhyme recorded, Siege/
  Avalanche re-verified. 5 tension points (§8.9 — Monolith ship? · the Gate · Feather-Step fold
  · Drumfire rhyme · numbers=playtest). Distinctness-ledger row 2. *(slate-machine session,
  deck tick 02:49)*

- ☑ 2026-07-10 · `net-integrity` → main (`4779f59`) — **NET-LAYER INTEGRITY HASH: BUILT & MERGED
  (audit 07-03 checksum-coverage finding, option b as recommended; REFIT §5 disposition).** The
  desync detector only saw boss HP + tick; seat HP/resources/absorb and `rng._state` drifted
  invisibly until they compounded into boss damage. Shipped: read-only `DetRng.state_hash()` +
  pure `RaidNet.integrity(state)` (tick · boss · per-seat scalars · rng state — scalars only, no
  Dictionary iteration) → the server ships `ih` beside `cs` on the same 30-tick cadence → the
  replica compares both and halts loudly on mismatch. **`NetProtocol.VERSION` 13→14** — ⚠ next
  deploy rebuilds server+clients together (`server/preflight.sh`, the versioned-protocol law).
  Engine checksum UNTOUCHED — every sim baseline byte-identical (that was the point of option b).
  NEW `sim/integrity_probe.gd` (replicas agree · hashing pure · seat drift caught · rng drift
  caught, checksum blind to both). GATES: **verify-all ALL GREEN (38 scripts)** incl. both net
  smokes checksum-identical through the new comparison. §CODE AUDIT bullet struck. *(rails
  session — P4 queue continues: vuln stack ⚠ rebaseline → class registry → ClassBand+Gauge →
  hoists)*

- ☑ 2026-07-10 · main (docs only) · TEMPO-PLAN §17 (NEW) + CARD-CATALOG D0 rows + ledger §C —
  **DECK MACHINE row D0: THE TEMPO DECK v3 — DONE, 🟡 AT BILL'S VERDICT.** Winners = **WOUND ·
  SWIFT · FINISH** (no ranking was recorded in the corrected §14, so the pass took Bill's own
  correction examples — "bleeds, fast attacks, slow big ones"; his ✅ picks swap winners → cheap
  re-run, EDGE/PUNISH/BAND cards stay filed). The REVISION: every built card filed (17.3); NEW =
  Uptempo + Open Veins creeds (entry law per theme) · Hemorrhage module (the wound-pot CASH
  decision) · Lacerate/Slow Bleed/Arterial Note/Quickstep/Grand Pause/Heavy Ink boons ·
  Through-Line AUTHORED (A1 drift closed) · THE CODA + EXSANGUINATE keystones (stagger rider
  dropped — engine-free) · the Deep Cash rig WHEN · **THE SET PIECE** signature-CD shape ·
  the EASE knob list. Coherence gates run WITH EVIDENCE in-doc (dream drafts ×4 · trio
  spot-checks found Da Capo's auto-skip · overlap audit · anti-pattern sweep · AI notes);
  3 skeptics (quota breach → trim table · Brink-vs-Heavy-Ink distinctness recorded · zone-clock
  checks). **7 tension points at Bill's board** (wild-creed gap · trims · Held Breath park ·
  keystone offer rule · the CD · On the Beat · winner swaps). Distinctness-ledger row 1 written.
  *(slate-machine session, deck tick 02:34)*

- ☑ 2026-07-10 · main (docs only) · TEMPO-PLAN §16 (NEW) + `research/fermata-sweep.md` (NEW) +
  ledger §C row — **SLATE MACHINE row 8 (FINAL): Twinfang·FERMATA challenger slate — DONE.
  PHASE 1 DRAINED (all 9 rows 🟡).** The v5 build is the truth (its cuts are law): **filing**
  (PITCH #0a/b/c — **THE BRINKMAN** lip-greed: Brink/Razor/Long-Ramp · **THE RESTED BLADE**
  rest economy: First Note/Rested/rest-bank Unseen Blade (Superhot-validated) · **THE
  WINDOW-SETTER** control: Stretto/Refrain/wideners/Eclipse; zero orphans) + **two additive
  themes** (v5 is tight — two honest beats three padded): **THE AFTERIMAGE** (echo build on
  coded Twin Echo + Phantom — result multiplication, never press multiplication; the
  procession) · **THE COLD HAND** (the Good-band CP economy + branded Evis cash — the Brinkman's
  designed polarity, the same ramp read opposite ways). 3 skeptic passes, **3 KILLS** (the
  Misdirection = Feint resurrection · the Unbroken Line = dodge-feeds-offense once removed ·
  the Snap Dancer = pays failing), ~5 fixes. Ranking: Cold Hand · Afterimage. The SLATE-loop
  cron is deleted (queue drained); **the DECK MACHINE (SLATE-PLAN §5–§6) gate opens on its next
  tick — D0 Tempo first.** *(slate-machine session, tick 02:27)*

- ☑ 2026-07-10 · main (docs only) · ALCHEMIST-PLAN §10 (NEW) + `research/brew-sweep.md` (NEW) +
  ledger §C row — **SLATE MACHINE row 7: Alchemist·BREW challenger slate — DONE.** The live deck
  + §8 stand untouched; the pass adds the ladder layer: **filing** (PITCH #0a/b/c — **THE SLOW
  BOIL** Purist sustain · **THE CANNONADE** ⭐Vessel bank-burst · **THE ANCHOR** one-poison
  precision; zero orphans, §8's 11 proposals slot INTO the ladders) + **three additive themes**:
  **THE TIGHTROPE** (plate-spinner's greed — deliberate near-empty catches on the see-saw, min()
  law untouched) · **THE SIDEARM** (Spitfire weave + deliberate-kick mastery — the roster's only
  interrupt theme; kick cards parked on the committed pillar-#3 flag, split from live cards) ·
  **THE PROGNOSIS** (the fight-arc clock — absorbs Killing Draught + Last Call; HP milestones
  base, phases = raid bonus; Called Shot commitment greed). 3 skeptic passes: 1 kill (**the
  Flash Boil** — venom-lean fights the min(V,R) core law), ~7 fixes. Ranking: Tightrope ·
  Prognosis · Sidearm. *(slate-machine session, tick 02:12)*

- ☑ 2026-07-10 · main (docs only) · MENDER-PLAN §10 (NEW) + §10.7 built-pool addendum +
  `research/draw-sweep.md` (NEW) + ledger §C row — **SLATE MACHINE row 6: Well·DRAW branch slate
  — DONE, four themes AT BILL'S VERDICT** (sibling law held: every theme on the release/hold
  surface, zero landing/party overlap with Brim §9). **THE RAPIDS** (the Current named as a
  ladder; ⚠ built Millrace vs pitched Flume — one capstone absorbs the other at the deck pass) ·
  **THE VIGIL** (held heals — Patient Hand entry + the transformer promoted; archery tremble
  telegraphs the gutter; GH extended-sustain "Second Hand") · **THE SKIM** (the undercook as a
  chosen tool — never forgiven the p^1.5 price, paid in WAKES; the anti-Current pole = the
  slate's pick-tension centerpiece vs Rapids) · **THE EDDY** (drift reads — osu press-and-follow;
  Glass River keystone). **§10.7 BUILT-POOL ADDENDUM:** the deck banner's 24 built boons + rig
  were missing from BOTH filing tables — all filed now; §9's 4th theme RENAMED Deep Well → **THE
  PULSE** (a built shared boon owns that name); built Levee re-filed to Overflow. 3 skeptic
  passes: 1 kill (the Whirlpool — Rekindle's job in a keystone costume), ~6 fixes. Ranking:
  Vigil · Rapids · Eddy · Skim. *(slate-machine session, tick 01:57)*

- ☑ 2026-07-10 · main (docs only) · MENDER-PLAN §9 (NEW) + `research/brim-sweep.md` (NEW) +
  ledger §C row — **SLATE MACHINE row 5: Well·BRIM branch slate — DONE, four themes AT BILL'S
  VERDICT** (filing table homes every verdicted creed/module/sketch, zero orphans). **THE LOW
  CATCH** (play-behind formalized — Brink 5★ entry, band-position catches so zone fights don't
  sleep) · **THE OVERFLOW ENGINE** (⭐Reservoir named — the Glint-or-bank per-cast fork stated
  as the identity; Payload distinctness recorded) · **THE GLINTSMITH** (TEAM — Glint-uptime as
  the idle-time job, the FFXIV green-DPS warning made law: damage only through clean healing;
  blindfold = greed pole, Ana-grenade → PRIME) · **THE DEEP WELL** (pulse-beat casts, dry-
  flirting, Levee rework → THE TIDE creed candidate). 3 skeptic passes: 1 kill (the Surgeon —
  operation-chains re-invent Draw's rhythm on Brim's bar), ~7 fixes. Ranking: Low Catch ·
  Overflow · Glintsmith · Deep Well. No CARD-CATALOG rows (deck reshape = Phase-2 row D5).
  *(slate-machine session, tick 01:42)*

- ☑ 2026-07-10 · main (docs only) · ALCHEMIST-PLAN §9 (NEW) + `research/cask-sweep.md` (NEW) +
  ledger §C row — **SLATE MACHINE row 4: Alchemist·CASK branch slate — DONE.** The §7 slate is
  Bill-LOCKED (24/6), so this pass is the missing DECK-LAYOUT layer, not a challenger: **the
  filing table** names the ladders the locked cards already form (**THE BLEND LINE** hold-or-cash
  · **THE GAUNTLET** one-cask strain-chain · **THE TAP LIST** banked moments — zero orphans,
  entry-creed mapping stated) + **three ADDITIVE themes** at verdict: **TWIN CASKS** (Overcooked
  pipeline — homes the parked Double Barrel as a module) · **THE HOUSE RECIPE** (Potion-Craft
  repetition mastery, echo skill-gated on clean peaks) · **THE TAPROOM** (TEAM — bottled peaks
  thrown to allies, applies on their clean moment; shared buff-channel debt). 3 skeptic passes:
  1 kill (**Storm Brewer** — parked until the F3 under-fire playtest), ~6 fixes. Ranking: House
  Recipe · Twin Casks · Taproom. No CARD-CATALOG rows (deck = Phase-2 row D4). *(slate-machine
  session, tick 01:27)*

- ☑ 2026-07-10 · main (docs only) · `BLOOM-PLAN.md` (NEW) + `research/bloom-sweep.md` (NEW) +
  ledger §C row — **SLATE MACHINE row 3: BLOOMWEAVER class slate — DONE, four core-minigame
  candidates AT BILL'S VERDICT** (the queue's one rewire-grade pass; do-not-merge lock honored;
  one-instrument law from Atomicrops applied to all four). **A · THE ORCHARD CLOCK** (ripeness
  arcs + phase management — Wildfrost timers, the RIPEN heir; specs Orchard/Meadow) · **B · THE
  TRELLIS** (seats-as-lanes, heals RACE incoming spikes + PvZ sap economy; specs Sower/Courier;
  HUD lift flagged) · **C · THE BRIAR** (planted arming wards + graded SNAP — the Thornveil
  heir; specs Briar/Balm) · **D · THE PRUNING** (auto-growing garden, graded CUTS redirect it —
  healing by subtraction; specs Topiary/Wildwood; rule-4 death-clause stated). 3 skeptic passes:
  1 kill (Pollinators = timers in a costume), ~9 fixes. Skeptic ranking A·B·C·D. 2 new buttons
  per core (narrow-kit budget). No CARD-CATALOG rows (deck = Phase-2 row D3 after Bill picks the
  core). *(slate-machine session, tick 01:12; tracking edits ride other sessions' commits —
  shared docs were dirty)*

- ☑ 2026-07-10 · main (docs only) · TANK-PLAN §7 (NEW) + `research/duelist-sweep.md` (NEW) +
  ledger §C row — **SLATE MACHINE row 2: Tank·DUELIST challenger slate — DONE, three challengers
  join the LIVE §3 verdict board** (v1's Headsman/Ironside/Ghost restated as PITCH #0a/b/c at the
  same bar; Bill still picks 2–3 ladders TOTAL). **THE MATADOR** (the read/bait economy —
  Punch-Out grammar; insight from reads + late answers; absorbs Read the Room) · **THE
  STORMWEAVE** (the unpaid weave→riposte instrument; scoped to weave events so the Ghost keeps
  generic footwork) · **THE SCARLET TRADE** (the blood ledger — assembles Blood Price/Overreach;
  floors everywhere, healer-duet pricing flagged). Fresh sweep: Sekiro streaks · SF6
  Drive/burnout (→ Ironside boon material) · Punch-Out bait puzzle · Nine Sols (its
  plant-and-detonate = the skeptics' kill: Mark/Wound/Payload triple-collision). 3 skeptic
  passes, 1 kill, ~8 fixes. No CARD-CATALOG rows (deck revision = Phase-2 row D2).
  *(slate-machine session, tick 00:57)*

- ☑ 2026-07-10 · main (docs only) · §TOOLING / `SIM-PLAN.md` (NEW) — **THE BALANCE LADDER
  (Bill: "do nothing now, but plan how we balance the most possible within reason — a day-long
  weekly desktop run + quick sims").** Born from a 3-agent audit of the real sim surface (the
  honest findings are §0 of the doc): expert = perfect TIMING on a fixed hand-authored rotation
  (latency never changes the ability script) · blade policy is CREED-BLIND (Alchemist is the
  only creed-aware policy) · active-module verbs unplayed (Deathmark's gauge never spent) ·
  raid_sim runs a BARE kit · only Alchemist has per-card ΔTTK · nothing samples drafted builds ·
  no per-seat attribution in the 4-seat win rate. The plan: **two speeds** (quick gate = today's
  bar; THE SOAK = weekly day-long pinned-worktree run → ranked DIGEST + week-over-week trend) ·
  **ladder S0→S5** — S1 CARD-VISIBILITY RULE ("a card doesn't exist to the sim until the policy
  can play it"; creed-aware branches + module verbs + a catalog coverage probe, shipped INSIDE
  each rework) · S2 creed matrix (cheap) · S3 card-delta harness generalized from
  `alchemist_sim._boon_ab()` · S4 **build sampler** (Monte Carlo through the REAL `draft.gd`
  pipeline + per-card LIFT + shared-tag pair-lift + >~15% dominance flag — absorbs TEMPO-PLAN's
  unbuilt EV-parity gate; the answer to "boon combos are too many" is sample-and-statistics,
  never enumeration) · S5 raid attribution (per-seat meters + sloppy-one-seat ABLATION matrix →
  carry index + seat-swap parity; lands with the tank/aggro rebaseline wave). §4 = the
  soft-threshold table of what "balanced" MEANS per surface (skill gradient / creed spread /
  card lift / build dominance / healer bite / carry index). Non-goals locked: no optimizer AIs,
  no auto-tuning, no hard balance gates (determinism stays the only PASS/FAIL). Calibration
  measured: ~1.6s/raid-fight single-core ⇒ ~400k fights/24h sharded = the soak envelope.
  NOTHING BUILT — every rung has a trigger tied to roster/deck stability (ledger §G row).
  *(sim-plan session)*

- ☑ 2026-07-10 · `p4-rails` → main (`b17ff52`) — **REFIT P4 — THE INFRA RAILS: BUILT & MERGED**
  (Bill's go-code: "turn the plan into code — the core stuff, no class/boon content; work around
  the others"). The non-class-facing P4 subset: (1) **SAVE UNIFICATION** — `game/profile.gd`, ONE
  versioned corruption-tolerant aggregate at `user://rift_profile.cfg` owning
  world/gear/prior/binds/roster/runs behind the existing store APIs (GearStore / LuckProfile /
  WellBinds / BloomweaverBinds / WorldSave are thin facades — zero call-site churn); one-time
  legacy-file import; headless disk-inert with a FIXED seed root; the one canonical serializer
  lives on Profile (WorldSave delegates). (2) **Commander roster persistence** — `_ensure_party`
  seeds from the Profile once per boot, party-screen CONFIRM commits; entries validate against
  the LIVE seat/class tables, proven in anger same-day: rosters saved before THE PURGE self-heal
  to the new defaults. (3) **Reproducible offline `run_seed`** — the descent mints ONE recorded
  seed off the profile stream (root/counter/last_seed); drop_rng, floor topology, per-fight seeds
  (folding floor/fight/NODE) and boon drafts derive closed-form — a whole run replays from one
  integer (replay/ghost-race hook); zone + Seal pulls recorded too; online untouched.
  (4) **Split-law guard** — `make_spec` ctx: a "zone" spec structurally refuses `seat_boons`,
  normalizes byte-identical to the bare spec. NEW `sim/profile_probe.gd` (20 checks) +
  `sim/splitlaw_probe.gd` (3) in verify-all. **Also fixed in the same merge: shell_probe /
  menu_probe were RED ON MAIN since the purge merge** (dead GATE idiom · mender healer flow) —
  re-pointed at the post-purge game (menu_probe walks the Well creed ceremony). GATES: full
  verify-all on the merged tree — every sim/probe/smoke + both net smokes green (the two probe
  fails in the run were these very fixes, verified green individually after). DEFERRED P4 items
  (now unblocked by the purge merge, this session's loop takes them one at a time): net-layer
  integrity hash (option b) → vuln stack (rebaseline) → class registry → ClassBand+Gauge base →
  ClassKit hoists/TuningConfig sweep. *(rails session)*

- ☑ 2026-07-10 · main (docs only) · TANK-PLAN §6 (NEW) + `research/warden-sweep.md` (NEW) +
  ledger §C row — **SLATE MACHINE row 1: Tank·WARDEN branch slate — DONE, five themes AT BILL'S
  VERDICT.** Fresh sweep (Lies of P guard-regain · Bloodborne rally · MonHun guard-counter ·
  For Honor superior block · Vermintide stamina economy) → **THE PAYLOAD** (stored damage,
  hurled back — seeds off 🔮 Return to Sender) · **THE SLAM** (guard-counter chains) · **THE
  RAMPART** (wind-pool endurance; prices the hold-all-wall module) · **THE BANNERMAN** (TEAM —
  aggro-uptime + clutch block-share; buff-channel debt flagged) · **THE THORNBACK** (graded-tap
  reflect; honesty-noted last). 3 skeptic passes: 1 kill (Wrecking Crew = Headsman repack), ~11
  fixes folded. Filing table homes the 🔮 guard trio + all 4 carries. Base kit untouched, no new
  buttons, no CARD-CATALOG rows (deck = Phase-2 row D1). *(slate-machine session, tick 00:42)*

- ☐ 2026-07-10 · main (docs only) + 2nd session cron — **CLAIM: SLATE MACHINE PHASE 2 — THE DECK
  MACHINE (Bill).** SLATE-PLAN §5–§6 NEW: when every Phase-1 slate has landed, a second 15-min
  loop (`4,19,34,49`) authors the **FULL DECK (design only, never code)** per target around its
  slate's **top-3-ranked branches** (Bill's ✅ picks override) — deck-creator skill + DECK-LAYOUT
  slots + coherence gates (dream-draft walkthroughs · offer-trio · overlap audits · anti-pattern
  sweep · AI-pilotability) + a cross-deck DISTINCTNESS LEDGER (§5) + 3 inline skeptics → deck §
  🟡 AT VERDICT + **CARD-CATALOG rows at 🟡**. Existing decks (Duelist v1 / Well / Brew / Fermata
  v5) are handled as REVISIONS, absorb-don't-duplicate. Ledger §C row added; `slate-loop` skill
  now re-arms BOTH crons. *(slate-machine session)*

- ☑ 2026-07-10 · main (docs only) · TEMPO-PLAN §14 REDONE + NEW §15 parking + SLATE-PLAN
  correction + BUILD-LEDGER row — **BRANCH = BUILD THEME, not a rewire (Bill's correction).**
  Bill clarified: a branch is a general CATEGORY inside the existing spec (bleeds / fast attacks /
  slow big ones — the tank-ladder precedent), a filing system so cards/creeds/mods synergize —
  the spec's minigame and identity stay. The 2026-07-09 six rewire-pitches were the wrong
  altitude → **re-homed to TEMPO §15 as SPEC/ASPECT IDEA PARKING 🔮** (Bill: cool as future spec
  ideas). **SLATE-PLAN.md fixed BEFORE the 00:42 hold lift** (761fbcc): theme anatomy for
  branch/challenger rows, rewire anatomy reserved for class slates (Bloomweaver), laws 2–3
  rewritten — so the cron loop doesn't repeat the mistake across 8 targets. **§14 redone as the
  corrected worked reference: six THEME candidates 🟡 AT VERDICT** — THE WOUND (bleed→cash) ·
  THE FINISH (combo weight, names the evis/coup lanes + Largo) · SWIFT (frequency/energy,
  doubleTime capstone) · THE EDGE (names the A7 crit package) · THE PUNISH (Opening-fed) ·
  THE BAND (TEAM texture, flagged thin) — with the existing-pool FILING TABLE (every built card →
  its theme / EASE-fold / generic; zero orphans) + inline skeptic checks. Poison excluded
  (Alchemist's lane). Bill picks 2–3 themes → deck pass. *(this session)*

- ☑ 2026-07-10 · main (docs only) — **THE RAID REBUILD plan (Bill) — DONE, 🟡 AT BILL'S VERDICT.**
  Bill's zoom-out brief ("the raid is all over the place — rebuild it from the ground up, keep
  the bosses for now" + mid-brief addendum: literal new minigame/puzzle node types + fold in the
  parked merchant/master-plan ideas) → NEW **`DESCENT-PLAN.md`** (the descent spec v1 + the
  12-question verdict board §V). Headlines: **4-floor promotion** (Vorathek → Floor 1's Seal;
  Rings count 3-2-1-0) · **time budget ~2h25 clean / ~3h lived** (floors 23/34/39/49 min, floor
  boundary = the blessed suspend) · **fight ladder** (deck-cycle law, 3-min trash cap, packs ON
  raid floors, enrage retighten; Seal budget contract 5/7/9/12 min for the later boss pass) ·
  **node slate** with printed one-line contracts + fight-tier pips (PROMPT MARKET 6-slot shop +
  post-Seal market phase · THE JAILBREAK printed curse deals · CAPTCHA/BENCHMARK/SERVER
  ROOM/PATCH BAY minigame nodes + 2 reserved · ▚WILD ~4%) · **reward legibility** (3 header
  meters ⏣⚡⏻; renames LUCK/STANDING/BACKUPS/REGENERATE/DEPRECATE; raid integrity KILLED;
  currency governance rule) · **quest verdict: one grammar, two ledgers** (THE QUEUE +
  ROUTE/DEED/ESCORT shapes; zone TICKETS v2 untouched world-side). Built by a 14-agent workflow
  (7 recon incl. MEASURED Seal timings via raid_sim → 3 architects time/economy/quest-first → 3
  adversarial judges → judged synthesis; run `wf_7a379a0b-44a`, journal in the session dir).
  Ledger: NEW §I rows + absorbed-row pointers (GEAR-3 Market, TEETH curse/CONTEST/rerolls-out,
  elite-node, stakes re-fiction). ⚠ Code lands AFTER `purge-oldgame` merges (GATE-cut overlap;
  recon confirmed gates still live on main). **First verdict in — V#11 ✅ (Bill, 07-10): shop
  purse = PER-SEAT EARNED WALLETS** (shared pot rejected as not-fun; your clean play mints YOUR
  ⏣ — the skill mint routes to the earning seat; the Draft-2.0 shared bank retires, UPSELL
  spends your own; AI seats: player-directed shopping or AUTO default). **ALL 12 VERDICTS IN
  (Bill, 07-10) → v1 LOCKED, ledger §I flipped 🔒:** V1–V6/V10/V12 at the recommendations ·
  V7 NO 2nd module · V8 STANDING/Prior DELETED entirely (no fold — "messes up an otherwise
  fresh run"; luck_profile/rift_prior.cfg/check-term die) · V9 WILD bumped ~10% (2/floor F2–4,
  out of EVENT quota). WORLD-PLAN amend banners placed (4-floor instances row + Seal band
  5/7/9/12). Build = post-purge, one map bang. *(raid-rebuild session)*

- ☑ 2026-07-10 · main (docs only) — **THE DUNGEON REBUILD plan (Bill) — DONE, 🟡 AT BILL'S
  VERDICT.** The watcher loop worked as claimed: woke the moment `DESCENT-PLAN.md` hit HEAD
  (`cddc390`; no stall, the resume protocol never fired), then ran the same zoom-out structure
  pass for the DUNGEON surface inline (time-first / economy-first / push-first lenses +
  skeptic checks; no workflow). **NEW `DUNGEON-PLAN.md`** — DESCENT's twin, inheriting its
  grammar wholesale (deltas only): ~29-min push lap / ~25 farm lap budget · `run_map` PRESET
  (7 rows/~17 nodes/1 Seal — rides §I's ONE re-baseline, no second bang) · THE DOOR CONTRACT
  (Version+Depth dials + affix preview, rendered-not-specced — the Depth thread stays owner) ·
  node-slate deltas + the 8-string SKIN TABLE (resolves the takeover-names-vs-earnest-world
  tension, V#2) · keystone-at-elite (AMENDs UNLOCK-2's "after the 1st boss" wording, V#3) ·
  subset table v1 (D1 Creed-only · D2 Module-not-Creed) · Dungeon 1 = **THE UNDERGRANARY** +
  **THE TALLYMAN** worked contract (node/boss authoring stays the W3 claim). **8 verdicts at
  §V.** Satellites in the same commit: BUILD-LEDGER **§J** (6 rows; zero new `draft.gd`-queue
  rows by design) · WORLD-PLAN §THE DUNGEON pointer · GAME-LOOPS L3 + gap-A sync · CLAUDE.md
  index line. *(dungeon-watcher session)*

- ☐ 2026-07-10 · main (docs only) + session cron — **CLAIM: THE SLATE MACHINE (Bill) — every
  class/spec gets the Tempo-§14 branch-slate treatment, one at a time, on a 15-min loop.** NEW
  **`SLATE-PLAN.md`** = the generalized pass (§1) + slate laws (§2) + **THE QUEUE** (§0: Warden →
  Duelist → Bloomweaver(class-level) → Cask → Brim → Draw → Brew → Fermata) + the loop protocol
  (§3); NEW `.claude/skills/slate-loop/` = the restart entry point (the cron is SESSION-ONLY —
  in a new session invoke `/slate-loop` to resume); BUILD-LEDGER §C row + CLAUDE.md index line.
  Each pass: fresh WebSearches → `research/<target>-sweep.md` → 4-lens synthesis → 4–6 pitches
  (incumbent deck = PITCH #0 where one exists) → 3 inline skeptics → slate lands **🟡 AT VERDICT**
  in the target's plan doc. "Done" = slate at verdict — the loop does NOT wait for Bill's picks;
  deck-creator passes are separate claims after each verdict. *(slate-machine session — the loop
  runs here)*

- ☑ 2026-07-10 · docs on main + worktree `../wow-purge` (branch `purge-oldgame`) — **THE
  OLD-GAME PURGE + audit follow-ups (Bill) — DONE, MERGED `0582294`.** Code: Voidcaller ·
  Mender · Reckoner + the 15 solo exam bosses + the GATE node kind DELETED (~40 files edited,
  3 class dirs + gate_content + policies/binds/gauges/probes removed); defaults flipped
  caster→Alchemist(brew) · healer→Well(brim) (healer keeps the Well⇄Bloomweaver toggle);
  Zone 1's THE THRESHOLD re-payloaded to a Forge elite; protocol **v13** (⚠ rebuild+redeploy
  server with clients); Twinfang Warden/Executioner + kept-class solo bosses survive as SIM
  FIXTURES only. **Full verify surface green** (35 harnesses: balance sims · probes · smokes ·
  both net smokes, zero desyncs). **Bands re-baselined @60 seeds** (deliberate): riftmaw
  100/100/0 · mistral 100/100/100 · gemini 100/100/28 · mythos 100/92/0 — good-tier IMPROVED
  on deep Seals (the Well), **⚠ riftmaw sloppy 77→0 = watch item** (entry Seal stone-walls
  the worst tier on the no-kicker comp — SEAL-PILLAR/healer-retune lever). Docs: purge
  decisions recorded (GAME SHAPE amendment etc., commit `35d270c`), audit drift/stale fixes,
  `archive/` born (5 docs), WORLD-PLAN §THE DUNGEON, ceremony-order in DECK-LAYOUT, ledger
  §A½ rows (Bulwark-dies-with-Duelist pinned). ⚠ WSLg visual pass OWED (class-select /
  party / lobby screens changed — headless can't render): Bill's next feel pass. *(this
  session)* **CLAIM was:** (1) docs: record the purge decisions (GAME SHAPE
  amendment · roster · casting-pool cut · BREADTH/gear consequences), fix the loop-audit drift +
  stale blocks, archive retired docs → `archive/`, WORLD-PLAN §DUNGEON consolidation; (2) code:
  DELETE Voidcaller + Mender + Reckoner + the 15 solo bosses + the GATE node kind wholesale;
  defaults flip caster→Alchemist(brew) · healer→Well(brim); Bulwark stays (dies with the Duelist
  base — ledger row); Bloomweaver stays frozen. Deliberate re-baseline (maps regen w/o gates,
  comp flips, NO-KICKER interim until pillar #3). ⚠ collides with live `cask-policy` +
  `tempo-pilot` worktrees — merging main often. *(this session)*

- ☑ 2026-07-11 · `peel-simplify` (worktree `../wow-peel-simplify`) — **LOST-AGGRO = UNDODGEABLE —
  MERGED `cdd008f`.** Bill: "if you get hit by a lost aggro attack you can't dodge it, and simplify
  it." A peeled rhythm bar was ALREADY undodgeable (only the tank's Duelist funnel answers the
  stream; DPS `modify_incoming` ignores it) — but the UI faked a dodge three ways: a dim "PEELED"
  comet on the tank's channel, a full dodge-DIAL prompt for the strayed DPS, and a banner that said
  "DODGE!". Now the stream carries ONLY the tank's own bars (`observe`: armed == the bar targets me);
  a peel just PAUSES the tank's stream till aggro drifts back, the raider eats the hit, and the
  banner reads "IT'S HUNTING YOU — CAN'T DODGE, RIDE IT OUT." DELETED: the peeled dial block, the
  "THE RHYTHM — PEELED"/mine-vs-not-mine judge branch, and the dead `rhythm_stray_windup` grace (a
  peel now lands at normal cadence — losing aggro costs you SOONER). Net −17 lines. This also erases
  the peel-nudge residual from `d7d8a2c`: lane probe 0 jumps / 0 flips / 0 nudges (riftmaw+mythos).
  GATES: gemini BYTE-IDENTICAL `4635155925447111502` (non-rhythm untouched) · riftmaw determinism
  PASS, re-baseline `2317005574163013085`→`7992045833249951212`, expert WR ~75% held · forge_sim ALL
  PASS · raid smoke ALL OK. STAMP → ONE BAR v1.6 · PEEL = NO DODGE. *(this session)*

- ☑ 2026-07-11 · `rhythm-fix` (worktree `../wow-rhythm-fix`) — **TANK-STREAM COMET GLITCH FIXED —
  MERGED `d7d8a2c`.** Bill: icons appear then vanish and pop in "in the middle on a line with a
  circle flashing around it," on ALL tank fights — a real bug, NOT clutter (he corrected an earlier
  mis-triage). ROOT (proven with a headless lane probe): the Judgment Channel projected a flat
  ~0.9s lead drawn as a LIGHT diamond, but the bar's size+windup were rolled at ARM → every HEAVY
  bar (35% odds) JUMPED ~98px backward AND morphed diamond→hexagon the instant it armed; aggro
  peels jumped 200-300px. `50349a6` lit heavy_odds/jig across the roster, so it went everywhere.
  FIX: pre-roll the next bar's SIZE at the START of its approach (rolled at resolve, so the 1-tick
  gap after a HEAVY bar still shows the shape a frame early) and project its TRUE size+windup — the
  comet now glides in seamless, which is exactly what the code's own comment already promised. One
  new BossState field (`rhythm_next_size`); the size rng draw just moves a few ticks earlier. PROOF:
  MINE-bar jumps 7→0, MINE shape-flips →0 (riftmaw + mythos); every residual nudge is a dim
  mine=false PEEL bar. GATES: determinism PASS · gemini (no stream) BYTE-IDENTICAL `4635155925447111502`
  (non-rhythm untouched by construction) · riftmaw deliberate re-baseline `8723130924775573198`→
  `2317005574163013085`, expert WR ~68-73% held · forge_sim ALL PASS · raid smoke ALL OK. STAMP →
  ONE BAR v1.5 · STREAM FIX. **Open follow-ups for Bill:** (a) pre-roll the VICTIM too → seamless
  peel bars (shifts when aggro is sampled — its own verdict); (b) his LATE-BAR idea: an intentional
  per-bar flag to skip the mouth-entry so some attacks pop late as a reaction test (the good version
  of what was glitching). *(this session)*

- ☑ 2026-07-11 · `tank-juice` (worktree `../wow-juice`) — **AAA TANK FEEDBACK — MERGED `2b006f2`.**
  Bill: full-on effects/clarity/feedback — the tank must KNOW missed-vs-perfect. BUILT:
  `verdict_slam.gd` (NEW) — center-screen verdict slams: PERFECT huge gold + 12-ray burst +
  rings + STREAK ×N · HIT crimson + edge-vignette pulse + shake · BAITED purple mock; judge
  emits a typed `verdict` signal (band wires slam + shake). Judge BIG mode (tank): taller
  track, comets ×1.35, wider footprint. DuelistGauge: ◆ banks punch-pop + halo; 'WINDED —
  breathe' dry-wind pulse. ⚠ gotcha RE-PROVEN + added to the pile: PRESET_FULL_RECT set in
  _ready (after add_child) = zero-rect silent no-draw — place-then-add always. Gates: gemini
  byte-identical · both smokes · WSLg 'PERFECT PARRY ×3' slam live over a CRUSH-octagon channel
  moment. STAMP → ONE BAR v1.4 · TANK JUICE. *(this session)*

- ☑ 2026-07-11 · `boss-castbar` (worktree `../wow-castbar`) — **THE BOSS CAST BAR (the
  declutter split) — MERGED `56f6cd1`.** Bill's taxonomy verdict: the dodge bar held too many
  different things — his mental model is small auto · big auto · global dodge · fake (+ kick),
  and the boss's SPELLS don't belong in footwork. BUILT: `boss_cast_bar.gd` (NEW, under the
  boss HP, every seat): heal=BURN IT DOWN · empower=IT GROWS · kickable verse (window band +
  'uncontested — no kicker' until interrupt-by-ability lands) · nova=BRACE; glyph medallion ·
  fill · countdown · kick/deny pops. Judgment Channel = FOOTWORK ONLY, and keeps streaming the
  rhythm WHILE the boss casts (no more channel hijack). Dial's wrong 'PARRY — interrupt!' cue
  deferred to the cast bar. Gates: gemini byte-identical · both smokes · WSLg Devouring-Chant-
  on-castbar + rhythm-under shot. STAMP → ONE BAR v1.3 · CASTBAR. *(this session — model note:
  session restarted on Fable for the UI pass.)*

- ☑ 2026-07-11 · `stream-texture` (worktree `../wow-texture`) — **SHAPES + HUMAN CADENCE +
  SEALS I & IV — MERGED `50349a6`.** Bill: bigs indistinguishable from smalls (all tiny gold
  diamonds) · pattern too metronomic · kill the purple veil · put the stream on the first big
  boss + the last. BUILT: judge SHAPE ALPHABET (small diamond / HEAVY hexagon / CRUSH spiked
  spinning octagon / hollow-purple feint; wakes+halos scale) · feint veil REMOVED · melee `jig`
  (re-arm jitter) + `heavy_odds` (TALL bars: windup ×1.35, dmg ×1.45, PARRY cue, policy parries)
  on all forge bodies + fixtures · **VORATHEK stream ON** (1.25/0.85/35% talls — §3 slow·tall·
  honest) · **MYTHOS stream ON** (0.5 windup/jig .40/20% — dense·all shapes). ⚠ wow-seals
  heads-up: raid_content riftmaw+mythos melee dicts touched (1 line each); Mistral/Gemini
  BYTE-IDENTICAL (gemini 4635155925447111502 = main). **Riftmaw DELIBERATE re-baseline
  8723130924775573198: seed-1 tank_death@50s → WIN@193s · expert 0→73.3% win · good-tier
  tank_death 57→9** (rest dps/enrage — seal-track debt). forge ALL PASS · duelist det PASS
  (new checksums 6543973726267971811/463140136036467795) · smoke OK. STAMP → ONE BAR v1.2.
  *(this session)*

- ☑ 2026-07-11 · `bar-grammar` (worktree `../wow-grammar`) — **THE GRAMMAR PASS — MERGED `ebc5122`.**
  Bill's fight-1 read: only smalls, no bigs/fakes; cues said DODGE for everything then randomly
  PARRY; comets spawn mid-channel. FIXES: (1) full alphabet EVERY body EVERY tier (swarm bluff
  un-gated + snap cd 11→9 · chanter +Censer Backhand/+Broken Cadence · brute +False Wind-Up;
  stalker already complete); (2) height-law WORDS — judge+dial `size_verbs` (smalls DODGE ·
  HEAVY+ PARRY) + duel_answer verdicts echo ev.kind (the button actually pressed); (3) judge
  `pps` per-instance (const→var), Duelist channel 420 px/s so short-lead bars enter at the mouth.
  STAMP → ONE BAR v1.1. Gates: forge_sim ALL PASS · riftmaw byte-identical · raid smoke OK · WSLg
  Chitin-Bluff veil live in fight-1 t1. *(this session)*

- ☑ 2026-07-11 · `one-bar` (worktree `../wow-onebar`) — **THE ONE BAR — MERGED `60c866b`.** Bill:
  lane works, but tank had TWO dodge bars — reuse the global one. RhythmLane DELETED; StrikeJudge
  gains the `rhythm` kind (feed_rhythm) — the stream and the globals take turns on the ONE Judgment
  Channel (re-seated bottom-center for the Duelist): smalls DODGE · bigs PARRY · feints hollow
  DON'T-PRESS · strings beat-comets; armed/projected comets glide seamlessly; duel_answer verdicts
  now stamp (also fixes Duelist classic swings never grading on the judge); eaten bars synth a MISS.
  + fixed the latent judge-starvation bug (feed never ran on gap frames). BUILD STAMP → 'ONE BAR v1'.
  Gates: all checksums unchanged · both smokes · WSLg armed/projection/string+verdict shots.
  BOSS-PLAN §3½ presentation para updated (v3). *(this session)*

- ☑ 2026-07-11 · `rhythm-lane` (worktree `../wow-lane`) — **THE RHYTHM LANE v1 — MERGED `ae0c0f0`.**
  Bill: "still no auto attacks, only globals, glitchy — audit the whole implementation." The e2e
  audit (real descent path, human seat) proved the ENGINE fires but the v1 PRESENTATION was the
  bug: the dial-borrowed bar was on screen ~30% in sub-second blips = a 1Hz strobe reading as
  "another global, glitching". REBUILD: dial = globals only; `RhythmLane` (bottom-center, permanent)
  = the stream — armed comet → impact gate, gaps show the projected NEXT swing, wind-ups dim but
  never remove, grade flashes + history gems + crimson eaten + grey PEELED. observe() gains
  tank-only `rhythm_lane` telemetry (gated on the melee rhythm key). + combat BUILD STAMP
  ("build 2026-07-11 · RHYTHM LANE v1") to settle stale-client questions forever. GATES: all 3
  checksums unchanged (view+observe only) · both smokes green · WSLg: lane in 5 consecutive
  frames + armed/gap/paused states. NEXT: Bill relaunches FRESH (stamp visible top-left =
  new build) → feel verdict on lane size/position/cadence. *(this session)*

- ☑ 2026-07-11 · `rhythm-coverage` (worktree `../wow-rhythm2`) — **THE RHYTHM: full walk-in
  coverage + pack fix — MERGED `a6ab9ae`.** Bill's re-test read "no changes" — root causes: (a) only
  the SWARM body carried the rhythm (fresh map rolls open on stalker/skirmish walk-ins = the old
  invisible chip = the lottery), (b) \_pack_advance never cleared rhythm_* (stale armed swing
  carried across members) nor honored rhythm_open_delay. FIX: stalker 0.6 / chanter 0.65 /
  brute 0.75 wind-ups + skirmish COPIES (sonnet/bard/opus 0.6; Seal add dicts untouched via
  duplicate) + pack-advance reset. Seals stay old-style (seal-rework owns them). GATES: forge_sim
  ALL PASS · raid_sim riftmaw byte-identical · both HUD smokes green. ⚠ stale-instance suspicion
  open: Bill's client may predate the merges — the tell is the rune chips (1/2/3/4 = new,
  SPC/F/1/2 = stale; a running Godot never hot-reloads). *(this session)*

- ☑ 2026-07-11 · `duelist-binds` (worktree `../wow-binds`) — **Duelist rebind (Bill) — MERGED `1a03d33`.**
  1 / SPACE / LEFT-CLICK = DODGE · 2 / RIGHT-CLICK = PARRY (F stays a legacy alias) · 3 = ⚡ DUMP ·
  4 = ⏱ EN GARDE. Band mouse grammar (hovered-BaseButton guard stops pause/rune double-fires);
  chips + hint + codex updated. View-only — engine untouched; ui_smoke_raid ALL OK; WSLg verified.
  ⚠ gotcha re-confirmed: `:=` off an untyped hud reference = Variant-inference parse error that
  cascades ("Failed to compile depended scripts") — type the var explicitly. *(this session)*

- ☑ 2026-07-10 · docs on main + worktree `../wow-rhythm` (branch `tank-rhythm`) — **DONE, MERGED `3096098`: THE
  TANK STREAM = THE RHYTHM (Bill's playtest verdict + design, `BOSS-PLAN §3½` NEW).** Bill
  playtested Duelist v1 in the descent fight 1 (forge swarm): ~4 invisible melee hits before the
  first telegraph (open_stagger 2.0s vs melee ~0.8s), dial empty ~70% of fight → "unplayable,
  totally bugged" (it wasn't a render bug — video-frame + framepace + headless analysis proved
  logic/render clean; the tank just has nothing to answer). FIX (Bill's design): upgrade the
  MELEE CHANNEL into THE RHYTHM — visible, dodgeable auto-attack bars on the aggro-holder,
  riding melee's keeps-ticking-through-telegraphs property (fills gaps, never overlaps, big
  beats stay on cadence); Duelist funnel is already source-agnostic so the press works today —
  it just lacked a wind-up to time. Chip = the partial-mit leak (no melee floor). Strays only
  on aggro-peel (victim-visible, longer wind-up, hidden from tank). Pilot = fight-1 swarm
  (+ its missing BIG parry bar + feint twin t≥2). Slices S1 engine (guarded, no-rhythm
  encounters byte-identical) · S2 swarm · S3 per-seat dial · S4 sims+feel. Ledger §F row added.
  **BUILT + MERGED `3096098`** — S1 engine (BossState rhythm_* · TuningConfig knobs · _tick_rhythm
  gap-fill channel · observe() victim-only · DuelistPolicy reads the bar · CastDial tg_rhythm +
  raid_hud dial feed) + S2 content (swarm rhythm 1.1s/22-30 + CARAPACE SNAP big parry bar +
  CHITIN BLUFF feint t≥2 + DuelistContent fixtures) + S4 gates. GATES: guard proven byte-identical
  pre-content (duelist dense/spike + raid riftmaw checksums = main) · forge_sim swarm 100/100/100 t1
  → 100/100/95 t3, TTK gradient 27.7→41.7s t1 · duelist_sim deliberate re-baseline (expert sharp%
  48→86 — the visible bar) · ui_smoke_raid ALL OK · ui_smoke_map ALL PASS · WSLg proof shots (bar
  live at fight-open, >> DODGE << in-zone, telegraph layering). Fixture 0%-win state = the known
  union baseline (SEAL REWORK owns that rebalance). NEXT: Bill feel pass on fight 1; then rhythm
  textures per Seal (§3 row) ride SEAL-REWORK S2+. *(this session)*

- ☑ 2026-07-09 · main (docs only) · NEW `GAME-LOOPS.md` + CLAUDE.md index line + 2 drift banners —
  **core game-loop AUDIT (Bill) — DONE.** Read all 23 plan docs; **`GAME-LOOPS.md`** is the
  deliverable: the game stated as 7 loops (beat→fight→node→run→world→account→warband) with status
  + doc-of-record pointers (§1/§2), audit findings (§3: 5 drift spots · 4 stale blocks · 6 gaps —
  headline: **the DUNGEON surface has no plan**; signature CD built nowhere; run loop = 6 doc
  homes), and the storage verdict (§4: **keep .md-in-git** — the fracture was a read-path problem,
  fixed by the index-doc pattern, not the medium; don't consolidate into bigger files). Zero live
  contradictions found — every conflict was a stale echo with the newer doc winning by written
  rule. Side fixes in the same commit: ⚠ stale banners on `ASCENSION-STEAL-PLAN.md` (rerolls-out +
  pre-world one-liner) and MASTER §MAPS' shipped "NEXT" list. Recommended follow-ups (Bill
  verdicts): freeze RAID-PLAN · author the DUNGEON spec before W3 · §ONLINE/§CLASSES stale-header
  fixes. No design changes, no card/ledger rows. *(this session)*

- ☑ 2026-07-09 · main (docs only) · TEMPO-PLAN §14 (NEW) + `research/` (NEW dir, 7 files) +
  BUILD-LEDGER §C — **Twinfang·Tempo deck rebuild, Phase A: DONE — six branch pitches AT BILL'S
  VERDICT.** Ground-up reshape onto DECK-LAYOUT, Tempo first (Fermata pass later), base ideas only.
  **(1) `research/` knowledge base built** (~2.1k lines, 6 Opus agents: WoW retail Midnight-era ·
  StS 1+2 · Hades 1+2 · Across the Obelisk · Expedition 33 · 12-game wildcards sweep — permanent,
  reusable for every future class/deck pass). **(2) 4-lens synthesis** (branch shapes · greed ·
  timing grammar · spectacle/party). **(3) SIX PITCHES in TEMPO-PLAN §14** — the Motif
  (wound-stack → graded resolve) · Redline (energy=fuel furnace + reclaim tap; absorbs Overdrive) ·
  Counterpoint (Opening answer-chains + Coup-as-interrupt) · the Conductor (support-rogue calls,
  TEAM) · the Soloist (rank grows accent beats on the lane) · Polyrhythm (ghost notes + two-ring
  keystone, one button). **3 Fable-skeptic adversarial pass: 0 kills, ~17 fixes folded** (entry-
  creed filing · no second button · Perfect-or-better kick · no hit-eating cards · aura→calls).
  Killed on purpose: Gambler (luck-as-greed) · Executioner (stock meta) · Hoarder (Fermata brush) ·
  Pendulum. Also reconciled two stale Fermata ledger rows (built `f5d5397`, was "design owed").
  No cards proposed, no code, CARD-CATALOG untouched. **NEXT: Bill picks 2–3 → full deck pass.**
  *(this session)*

- ☑ 2026-07-09 · main (docs only) · DECK-LAYOUT §5/§6 + deck-creator skill + BUILD-LEDGER §C —
  **THE ABILITY LAW: the button budget (Bill).** The signature CD existed but no rules governed
  ability/button count. Bill's frame: keep the game about **optimizing rotations** (not WoW's 50
  buttons), but movement-removal freed complexity budget for a few more spells — and mobile must
  work. Locked (both forks at my recommendation): **(1) count in TOUCH TARGETS** (dodge, CD,
  module buttons, drafted spells all count — mobile is the binding wall; the spike's play-proven
  layout = 5 targets, scales to 7 as 2-left/5-right). **(2) chassis free** = core 2–3 + dodge +
  CD (4–5 targets). **(3) allowance +2, HARD CEILING 7**, entering only via existing doors —
  drafted spells (earned in-run, fight-1 kit stays lean) + ≤1 module button (catalyst precedent);
  boons/creeds/rig never add buttons; interrupts ride existing buttons (pillar #3 pattern).
  **Exception: the Well (the broad-kit pilot) ceiling 8** — breadth is its fantasy and its casts
  share one grammar; trim its loaded 10 at reshape. **(4) every button carries a WHEN, not just a
  WHAT** — press-on-cooldown = a passive in a button costume (fold to passive/rig THEN); this is
  the real rotation-protector, the ceilings are the fence. Reconciles DECK-LAYOUT's stale "bar
  cap 5" (was quoting per-class `SPELL_CAP`: 5 Twinfang/Alch/Voidcaller, 8 Well — now derived
  from the ceiling). Compliance debt ledgered (BUILD-LEDGER §C new row): Brew fully-drafted = 9
  w/ CD, Well loaded = 10 — trims land at each class's reshape, no code now. §0 collision map
  unmoved (touches files already under the Phase-2 program row). *(this session)*

- ☑ 2026-07-09 · main (docs only) · DECK-LAYOUT §2/§4/§6 + CARD-CATALOG (Type field) + deck-creator
  skill — **CARD-TYPES DEMOTED: LENSES, NOT A LAW (Bill).** Bill questioned the 6 card-types
  ("to be strict removes a ton of freedom… these are some ideas to start off"). Verified first:
  **nothing mechanical reads the type** — no code path, no draft weighting; only an inert `ctype`
  label on the Well's boon dicts. The taxonomy had also already betrayed itself (EASE became a
  designed archetype — the dial; TEAM is the Support slot wearing a tag; RULE ≈ keystone). Fix:
  the law *"every card is tagged with exactly one type"* is **dropped**. The 6 words stay as the
  shared vocabulary doing the two jobs they were invented for, both authoring-time: **spread**
  (de-flood — no 14-POWER decks) + **coverage** (a checklist so no *kind* of good card gets
  forgotten), now applied **per DECK, not per card**. Cards take a **best-fit** tag (straddlers
  pick the dominant flavor; never contort a design to fit a box). Dial-lanes + ladders/sub-specs
  remain the axes that categorize with consequences. EASE-the-dial + TEAM-the-slot keep their own
  laws independent of the tags. No code; **no BUILD-LEDGER move** (relaxes an authoring rule — no
  planned-work rows or file-touch sets change). *(this session)*

- ☑ 2026-07-09 · main (docs only) · DECK-LAYOUT §1 (new RIG LAW block) + §6 — **THE RIG IS REQUIRED
  (Bill).** Law-stated what the slot table implied: **every class deck ships a WHEN→THEN Rig** — a
  reshape without one isn't done. Chassis identical on every class, WHENs/THENs class-authored
  (earned minigame moments, never passive rolls; THENs = modest role-shaped payoffs). Mechanics
  restated as law from `TEMPO-PLAN §5` (locked 2026-07-04): **ONE circuit/run** (wire after fight 1,
  one free Floor-2 re-wire, never grows), **greed-dial payout** (`base × mult`, mult ≈
  inverse-frequency × premium — rare WHENs pay a spike only if landed; built ref
  `twinfang_rig.gd`), power = **side boost** (~10% of own output). **Stacking stays CUT** (the old
  any-WHEN-fires-the-THEN-board model = "side-effect damage is killing the boss and I don't know
  why"); only small capped banking *inside* one THEN (Killing Edge cap 3; Overcharge takes max,
  never adds). No code change; no BUILD-LEDGER move (codifies existing scope — Duelist rig already
  🟡, Twinfang/Alch/Well rigs already 🔨). *(this session)*

- ☑ 2026-07-09 · main (docs only) · DECK-LAYOUT §1/§3/§4/§6 + CARD-CATALOG + deck-creator skill +
  ALCHEMIST-PLAN §2 + MASTER §1599 + BUILD-LEDGER §C — **MODULES = ADD-ONS, TRANSFORMER REQUIREMENT
  DROPPED + SUB-SPECS ARE THE DEPTH ENGINE (Bill).** Two linked steers: (1) a **module is a
  supplement/add-on** to the core minigame (a gauge layered on top, base fully playable without it) —
  NOT the mandated "fills → transformed state → crashes" transformer ("something about transforming I
  don't get" — Bill). The **"exactly one ⭐ transformer per class" law is removed**; transformers
  become one *optional* module flavor. Knock-on: the two **"class OWES a transformer" debts**
  (Alchemist post-Still-cut, both here + ALCH-PLAN) are **VOID** — no replacement owed; The Crucible
  (tank ⭐) drops to a plain module up for keep/simplify/cut at reshape. (2) **Sub-specializations
  (= the ladders/branches) are the depth engine** for "we need more boons/upgrades": deepen a class by
  adding/filling a branch (its own boons + module + keystone = meaningful cards), not by stacking flat
  boons — which the **EASE dial** already de-floods. Net: *more cards that matter, fewer that don't*.
  No code (Phase-2 reshape territory). *(this session)*
- ☑ 2026-07-09 · main (docs only) · CLAUDE.md + MASTER §HOW-TO-WORK — **LEDGER LAW added (process).**
  Gap found (Bill): the trigger to update `BUILD-LEDGER.md` lived only inside the ledger's own §4, so
  a session doing design work elsewhere didn't know it was on the hook (I missed it on the EASE-dial
  change until reminded). Fix: a prominent **⚙ LEDGER LAW** callout in CLAUDE.md (parallel to the
  CARD-TRACKING LAW) + woven into workflow step 4 + mirrored in MASTER §HOW-TO-WORK step 6. Rule: any
  planning change that creates/changes/removes planned-but-unbuilt work (or moves its file-touch set)
  updates the ledger in the **same commit**; 🔨+SHA on merge. Three-way split made explicit: cards →
  CARD-CATALOG · cross-file planned work + collisions → BUILD-LEDGER · decision history → this Coord
  Log. *(this session)*
- ☑ 2026-07-09 · main (docs only) · DECK-LAYOUT §4/§6 + deck-creator skill + CARD-CATALOG —
  **EASE → THE DIFFICULTY DIAL (Bill's idea).** EASE was going to get skipped (less "fun") and was
  flooding the pool (flat comfort cards are easy to author). Fix, locked with Bill (3 forks, all
  recommended): the EASE type is no longer a stack of flat comfort stats — it's **one rolled
  two-way dial** boon. On drop it **rolls 2–3 of the class's minigame knobs** (window / speed /
  grace); you **take one** and slide it **← COMFORT** (wider/slower, **damage-neutral**) or
  **BITE →** (tighter/faster, **+damage** that only pays if you can actually hit the harder version
  — a real whiff-gamble, GREED-adjacent). Lives **in the boon draft** (opportunity cost keeps free
  comfort honest); comfort still caps + tapers with power; the roll only sets *which* knobs are
  offered so the **direction is always chosen** (dodges the "luck wearing greed's clothes" trap).
  Wins for both audiences (learner turns it down, pusher turns it up), **de-floods** the pool (one
  archetype replaces the dozen flat comfort cards), a decision on every drop, and you can **flip a
  knob mid-run** as you master a fight. = Hades' Pact-of-Punishment routed through *our* timing
  dials. Landed: `DECK-LAYOUT.md §4` (full spec) + §6 law · `.claude/skills/deck-creator/SKILL.md`
  (authors dials, not flat comfort, going forward) · `CARD-CATALOG.md` (type-field note; flat-EASE
  boons Quick Wrists/Roll With It fold into the tank dial at reshape, forgiving *creed* The Veteran
  stays). No code (a Phase-2 reshape builds the per-class dial + its knob pool). *(this session)*
- ☑ 2026-07-09 · main (docs only) · WORLD §INSTANCES + BUILD-LEDGER §D + PROGRESSION §Tokens —
  **THE STAKES MODEL — how a wipe hurts + how hard bosses get (Bill: "bosses hard & complex like
  WoW, wipe→run-back→retry — but here you lose your 1-hour run after ONE wipe? earn a revive?
  does that cheapen the roguelike? maybe base mechanics lighter, save complexity for scaling up;
  StS-Ascension adds a boss mechanic each +1?").** Resolved along the locked RAID-vs-DUNGEON
  split: **retry cost = complexity budget**, so the two doors get two wipe rules. **RAID** = floor
  checkpoint + a finite **WIPE BUDGET** (start 3; res at the floor, cleared floors stay cleared;
  budget out → descent ends) = the WoW learn-and-retry loop kept roguelike-honest, and the answer
  to WORLD open-Q#6 (descent save/resume = the floor checkpoint). **DUNGEON** = lean (1 life;
  from-scratch is the point). **ATTEMPT TOKENS** = a Death-Defiance consumable (+1 attempt, any
  surface), **earned** at nodes / **bought** at Market — Bill's "earn/shop a revive" as a legible
  opportunity-cost resource, not a free undo (which alone would cheapen it; the locked "oaths bank
  win-or-lose" is the real anti-cheapen). **DIFFICULTY CONTRACT** revised: base = a mountain
  learned over *many* runs (NOT one session, NOT 20-mechanic memorization); the infinite
  "study-for-an-hour" push = the already-designed ladders (Versions authored-adds / Depth
  procedural / parked Run-modifiers = the StS-Heat stack). **Battle-rez already BUILT** (healer
  Rekindle — Well 6 charges / Mender 120 s, 40 % HP, R-key) — the *in-fight* layer, distinct from
  the run-loss budget; a boon/curio rez beyond the healer parked as an idea. Ledger rows added
  (§D: 🔒 budget + 🔒 tokens + 💡 boon-rez); numbers = playtest. No code touched. **NEXT:** build
  rides Wave-3/economy (needs descent-checkpoint plumbing + GEAR-3 Market); dungeon 1-life-vs-buy-in
  default is a feel call. *(design session)*

- ☑ 2026-07-09 · main (docs only) · NEW `BUILD-LEDGER.md` + CLAUDE.md index — **THE EXECUTION
  TRACKER (Bill: "~2 days of huge planning — quests/co-op minigames, curse cards, talent tree,
  new taunt, content layout, deck branches — track it all in one spot so executing code isn't
  crazy; are we branching off / stale-code scattered?").** Diagnosis confirmed: the COORDINATION
  LOG is a *chronological what-we-decided log*, the OVERALL PROGRESS table is high-level + partly
  stale, and CARD-CATALOG tracks *cards only* — nothing collected the **systems-level
  planned-but-unbuilt pile** into one forward-facing view. Built via a 5-scout parallel audit (3
  reading the plan docs, 1 reading MASTER-PLAN, 1 reading the **code** for stale/flagged
  surfaces). New `BUILD-LEDGER.md` = the one execution tracker: a **collision map** (which core
  files each planned change touches + the deliberate-rebaseline cluster + stale-code to retire),
  a **dependency spine** (rails-first → tank+aggro → class reshape → world/meta → depth/teeth →
  bosses → MMO shell), the **full slate** by workstream (~70 items, status-glyphed), and an
  **"awaiting Bill's verdict"** pull-list. Positioned as an INDEX (design stays in plan docs,
  card status in CARD-CATALOG, history here) — NOT a 4th source of truth. **Key findings:**
  FLOW=AGGRO + Duelist base kit land in the same files (must co-sequence); five class reworks
  share the same unbuilt substrate (rarity engine / elite-node type / HUD gauge base / spec-carry
  — build once); `combat_core.gd` + `raid_hud.gd` are the top hotspots; `bulwark_kit` sits at
  both migrations (moot — retire with the tank); solo-HUD/stage3d deletion held clean. **6 doc-drift
  fixes flagged** (GEAR-2-open line 670, roster "verified", dead §GRAPHICS line, Through-Line,
  Reservoir, Well-deck-"not-authored"). No code touched. **NEXT:** keep it updated as planning
  continues this week; back-fill/flip rows in the same commit as each decision. *(build-ledger session)*
- ☑ 2026-07-09 · main (docs only) · §CLASSES + §MODES / `TANK-PLAN §1c-1d` + WORLD-PLAN + CARD-CATALOG —
  **AGGRO = FLOW, UNIVERSAL — big combat-system change (Bill).** The tank's clean-answer streak (**FLOW**)
  IS the aggro/threat meter: play clean → hold the boss; slip → it peels to the warband. Replaces the old
  damage-threat "babysit" taunt. **Locks:** (1) FLOW is **base** (the aggro meter) — supersedes the same-day
  "flow = module"; the module becomes the damage-ramp *upgrade*. (2) **Universal — REVISES the "aggro =
  raid-only" lock `b2afbca`**: one rule in all content (overworld/dungeon/raid), only ambient numbers scale;
  raids keep identity via intensity. (3) **Progressive peel:** aggro is a % (the tank's flow); ≥30% = boss
  on tank, <30% = X% chance to peel (X rises as aggro falls), 0% = random. TAUNT = hard override
  (everyone-has-a-taunt). (4) **Reuses the built threat engine** — just rewire the tank's threat SOURCE
  damage→flow; non-tanks stay low passive threat. (5) **No tank = graceful chaos** (nobody drives aggro →
  random) — "3 DPS no tank" for free; don't bolt flow=aggro onto every class. (6) **Stream reconcile:** melee
  = the tank's skinny filler (aggro-holder only); targeted telegraphs = the tall "big hits" (= what a peeled
  squishy dodges); AoE strings = the flurries — the built melee/telegraph split (`raid_content.gd:8`), one
  seam = melee tempo. Determinism: peel roll uses seeded rng. **Consequences flagged (`§1d`):** non-tank
  peel-survivability, healer-follows-boss, AI-tank reliability, raid/dungeon identity, Hold-the-Line +
  Crucible overlap, Depth affix vocab, single-target-law clarify. **Flow-economy RULES locked** (skill-only;
  own bar; peel rides the victim's dodge bar + a warning + a determinism-safe grace-delay = react/taunt-back
  window; ≥30%/0% shape); **NUMBERS deferred to playtest for feel** (Bill — two-track). Base minigame now
  🟢 LOCKED. *(tank aggro session)*
- ☑ 2026-07-09 · main (docs only) · §CLASSES / `TANK-PLAN.md §1b` — **TANK BASE-MINIGAME PASS — the
  two specs sharpened (Bill).** Bill was "a bit lost on the difference between the 2 classes"; this pins
  it. **The specs now MATCH: 2 buttons each — a MAIN + a SECONDARY**, one rating rule (SECONDARY = small
  any / normal good+ / no tall / no hit-back; MAIN = any size + a **perfect hits back**). **Dodge tank** =
  DODGE (2nd, % mit small/normal) + PARRY (main) + **WEAVE** (a flurry = fast skinny bars, **dodge ALL or
  eat it all**, clean weave → free RIPOSTE); eats UNAVOIDABLES. **Shield tank** = BLOCK (2nd) + SHIELD
  (main — **HELD** across flurries; a **perfect shield hits back = SHIELD SLAM**, the parry-twin), **no
  dodge** (dropped); blocks everything (no unavoidables). **Leashed differently:** dodge tank = twitch
  recovery + **LOW HP, fast bar** + small fast-recharge pool (a "bubble", quick-healer build); shield tank
  = **big slow-recharge pool** (a "bar", his real leash) + **HIGH HP, bigger chunks**. **🛡 GUARD
  DROPPED** — both specs' **◆ → DUMP = pure damage**; defensive utility → the **~1-min defensive signature
  CD** (`DECK-LAYOUT §5`, a wall; owed). **Card fallout** (deferred, flagged in CARD-CATALOG): Return to
  Sender / Cheap Iron / The Wall → 🔮 re-home to Warden; SPEND lane now DUMP-only. **FLOW = a MODULE for
  now** (clean-streak → ramps DUMP; promote to base if loved). Branches/deck reshape come AFTER the
  minigame locks. *(tank base-minigame session)*
- ☑ 2026-07-09 · main (docs only) · `CARD-CATALOG.md` — **THE CARD SLATE + STATUS CONSOLIDATION
  (Bill: "how do we track boons/cards/creeds — want something solid + localized, a rule/skill").**
  Diagnosis: card design was scattered across 4 plan docs in 4 formats while the built truth lived
  separately in `data/<class>/*.gd`, with nothing linking them (drift showcase: "Duelist" = a
  proposed player kit in docs but a boss encounter in code). Bill's steer: generate-from-code is the
  right end-state but not yet (still planning, not everything's in code) → **for now a doc with
  STRICTER rules.** New `CARD-CATALOG.md` = the single source of truth for every card's design +
  status: one row per card, one format (mirrors the code dict fields for a later dump-from-code), a
  strict lifecycle (💡 idea → 🟡 at verdict → ✅ approved → 🔨 built+SHA → 🔮 parked / ✂️ cut) with
  the rule "flip status in the SAME commit as the decision," and a Cut Ledger (never resurrect).
  **Tank·Duelist fully populated as the worked reference**; other active classes are stubs pending
  back-fill on Bill's go. Pointers wired: CLAUDE.md index + new CARD-TRACKING LAW · deck-creator
  SKILL step 5 (authors into the catalog) · MASTER §CLASS FRAMEWORK. No code touched. **NEXT:**
  back-fill Twinfang/Alchemist/Well slates into the format (once Bill OKs it on the tank). *(card-catalog session)*
- ☑ 2026-07-09 · main (docs only) · §CLASS FRAMEWORK / `DECK-LAYOUT.md` — **THE DECK LAYOUT
  CONSOLIDATION (Bill: "merge all these ideas into a deck layout, then relook at classes").**
  New `DECK-LAYOUT.md` = the canonical class-deck anatomy, merging what was scattered across
  TEMPO-PLAN (meta-shape) · deck-creator SKILL (slots + 6 card-types) · MASTER (7 rules) ·
  TANK-PLAN (ladders) · TEETH-PLAN (depth-pass). Adds/formalizes: the **signature ~1-min CD**
  (one sanctioned baseline button/class — skill-amplifying, never button=damage) · the **3 axes**
  every card sits on (DIAL-LANE structural / LADDER thematic / CARD-TYPE descriptor) · **soft
  branches** (2 default, 3 when earned; attractors not cages; keystone-capped) · **EASE =
  player-authored difficulty** (floor-up/ceiling-down, capped) · the **spells reconcile** ("new
  buttons need a class-law reason" → the CD + broad-kit healer clear it; "spells lanes dead" stays
  anti-filler) · keystone count reconciled (pool 2–3 authored, acquire 1/run from elite). Pointers
  wired: CLAUDE.md index · deck-creator SKILL (spells line reconciled, defers to DECK-LAYOUT) ·
  MASTER §CLASS FRAMEWORK. No code touched. **NEXT (Phase 2):** reshape each class onto the layout,
  one at a time (deck-creator = the tool; tank + Well = templates). *(deck-layout session)*
- ☑ 2026-07-08 · main (docs only) · §TEETH / `TEETH-PLAN.md` — **THE "MORE DEPTH & MORE
  TEETH" PASS (design session with Bill).** Triaged Bill's depth dump against the locked laws
  (WORLD pillars · PROGRESSION #1/#4 · Framework-v2 rules): 7 ideas ride existing tech, rerolls
  LOCKED, PvP DROPPED. **🔒 Rerolls** — remove token-rerolls → a scarce EARNED charge (quests +
  the Market's already-specced "banked reroll charges"); **LOCK retires** with it, **UPSELL
  stays**; **Tokens re-home to the Market** (answers the on-record "5–6 pick-systems" density
  problem; the curios Hot Reload/Hashgrinder need reframing). **❌ PvP** — dropped (combat is
  telegraph-*answer*, no WARBAND analog). **✅ BUILD-NOW (rec'd, not vetoed):** the **CONTEST**
  skill-node (one telegraph, seats score → co-op / closest-wins loot / 1v1v1 *for the drop*;
  reuses the CAPTCHA event + 30 Hz lockstep — the first slice) · **spells/depth** = reweight the
  existing `type:"spell"` draft type (collection-vs-deck; pilot ONE class per Rule #2) · **loot**
  two modes (need/greed B-half revive with an AI banter-roll + the skill CONTEST) · **crafting**
  event-shaped (signature elite drops → extract-alive → oath-gated keystone UNLOCK — **partially
  reverses the "crafting CUT"**; counter-grind stays cut) · **curse cards** via the named
  "biting blessings". **🟡 endless** — a *door* on the existing **Depth** ladder; DESIGN-ONLY,
  folds into the parallel Depth thread (do NOT fork/re-spec Depth). No code touched; crafting
  reversal flagged at PROGRESSION-PLAN §Cut-list + MASTER §SYSTEMS E. **OPEN feel-verdicts:**
  pilot class · curse magnitudes · CONTEST scoring · endless framing. **NEXT:** build per
  §RECOMMENDED BUILD ORDER once Bill picks a slice. **+ REFINEMENTS folded later same
  day** (rarity-upgrade loot-roll · co-op puzzle · RESTED real-time XP-multiplier · the
  "borrow the grammar" next-level filter · retention framework → TEETH-PLAN §REFINEMENTS).
  *(teeth-pass session)*
- ☑ 2026-07-08 · `dodge-unify` → main (`de9cc10`) · §COMBAT / `DODGE-PLAN.md` — **UNIFY THE
  DODGE — the redundant F dodge is GONE (Bill's go, scoped). BUILT & MERGED.** The two input
  verbs (SPACE `defense` + F `dodge`) collapse into ONE spacebar dodge that answers BOTH a
  single DEFENSIBLE swing (instant negate) AND barrage-string beats, on one cd (**0.35s recovery
  on a connect / 1.3s whiff lockout** — flat model, single-swing negates included; "flat first,
  sim after"). **SCOPE (Bill, direct): Twinfang, Alchemist, Well (brim/draw) ONLY** — Bulwark
  (being replaced by the new tank), Voidcaller, Mender, Bloomweaver, Reckoner keep their
  two-verb split **BYTE-IDENTICAL** via an opt-in `ClassKit.unified_dodge()` hook (default
  false → the untouched `else` branches). **How:** new `CombatCore._unified_dodge()` fires every
  hook the two verbs did + owns one cd (`dodge_ready_tick`, mirrored to `defense_ready_tick` for
  the rune/policy gates); `_answer_strike` returns a connect-bool + takes `apply_cd` (default
  true = old split path). HUD: F dropped from a new `_twinfang_key` (split off the shared
  `_martial_key` so Voidcaller/tank keep F), `_fermata_key`, `_alchemist_key`, `_well_key`;
  hints reworded. Policies unchanged. **VERIFIED:** `verify-all` **37/37 GREEN** (det self-checks
  on twinfang/raid/alchemist/well/forge, all probes, `ui_smoke_raid`, net smokes) · twinfang_sim
  gradient holds (expert 100% → sloppy 76–98%, e.g. executioner-tempo) · **ab-gate well_sim
  BYTE-IDENTICAL** vs baseline (healer path untouched). Docs: DODGE-PLAN→BUILT/scoped, CLAUDE.md
  + WORLD-PLAN pillar 2. **OPEN:** the 3 non-scope classes convert to the one dodge at their own
  reworks (new tank first); the `_guard` rune cd-fraction bar scales off the old `def_cd` denom
  (cosmetic sliver, usable-flag correct); playtest-tune the flat negate cd. *(dodge-unify session)*
- ☑ 2026-07-08 · main (docs only) · §SYSTEMS E / `PROGRESSION-PLAN.md` §THE UNLOCK SYSTEM —
  **THE UNLOCK SYSTEM consolidated (design session with Bill, direct) — the five competing
  progression ideas in `UNLOCK-BRIEF.md` collapsed into ONE coherent system.** Through-line:
  *build-craft is persistent and slow (the tree); the run is fast and play-forward — heaviest
  in the raid, lightest on mobile.* Decisions locked: (1) **ONE tree, ONE meter** — every
  source (raid/dungeon/world/M+) feeds a single XP meter; points open per-class **tree nodes**
  (boons/keystones/modules/creeds/curios), bread-and-butter = levels only + **you choose the
  order** (retires the LEVELS fixed authored-wave rollout), deep/keystone nodes **also need an
  OATH KEPT** (leveling + oaths meet in the middle; oaths teach AND gate). Buys access/options
  **never power** (Law #1/#4 intact) → the brief's "all points → your choice" made law-legal.
  (2) **Density fix** — diagnosed StS/Hades run 1 primary in-run system + rare big-swing over
  many fights; we'd drifted to 5–6 systems, worst on the ~3–5-fight dungeon. Fix = the tree
  absorbs build-craft; **TWO surfaces, different density**: DUNGEON (<1h, mobile, variable,
  Creed + boon draft + **1 keystone after 1st boss** + no-choice drops + optional Market;
  Depth = its endgame) vs RAID (1.5–3h, +Module, **1 keystone after floor 1–2**, oaths at
  bosses, Market nodes). Keystones **1/run both surfaces** (partial layer, not every class).
  (3) **Dungeon variety** — each dungeon turns on a different SUBSET of systems (flavors; pick
  your mix; no run overloaded). (4) **Gear KEPT, reframed** — no-choice drops = the one real
  loot-moment (distinct by *agency*, zero configurator), Market = optional node; nothing
  folded (GEAR-1/2 stand). (5) **Suspend, don't pause** — no mid-combat pause (breaks flow);
  leave/resume between nodes even as a group; run locked to you till finish/quit; co-op
  quitter → AI backfill. (6) **Spine** — Zone 1 Gildfields (tutorial, rolls out every system)
  → Zone 2 (+dungeon) → Zone 3 (+dungeon) → Zone 4 = the raid; crest-gated, open borderlands.
  `PROGRESSION-PLAN.md` §THE UNLOCK SYSTEM rewritten (supersedes §LEVELS/HYBRID-WAVES);
  `UNLOCK-BRIEF.md` retired (tombstone → the new section). **One-page artifact** published.
  No code touched. **NEXT:** builds with the world track (W2/W3) — XP+tree on the world save,
  node-open UI, per-surface in-run stacks, dungeon-subset config, suspend/resume. *(unlock
  consolidation session)*
- ☐ 2026-07-07 · `refit-p3` (worktree ../wow-p3) · §CODE AUDIT / `REFIT-PLAN.md` §3 P3 —
  **P3 SHELL INVERSION (Bill's go) — P3.1a MERGED, rest in flight:** ✅ **P3.1a
  CampaignCore (merged to main):** the ONE campaign rulebook (`game/campaign_core.gd`) —
  net_server's ":501 mirror" `_ticket_srv` DELETED, HUD `_ticket_at` DELETED, writeback/
  cooling/cache/event-resolve shared; ab-gates BYTE-IDENTICAL, net+ui smokes green; 2 of
  main's 3 stale probes REVIVED (`map_advance_probe` drives ledger/recap/rig/module,
  `raid_boon_probe` recap; `fightlen_probe` still the open claim). ✅ **P3.1b RunDirector
  (merged):** `game/run_director.gd` owns the descent's 31 members + cp_view/cp_sync;
  raid_hud holds ONE `_d` (HUD + 11 probes rewritten); the server KEEPS its cp dict by
  design (natively the cp shape, serializable for the rejoin era). verify-all 33/34
  (only stale fightlen). ✅ **P3.2a WorldShell inversion (merged):** `world_shell.tscn`
  IS the boot scene — the shell raises raid_hud as its instance surface + owns all dev
  autostart idioms (`drive_autostart`); new `shell_probe` guards the chain (in
  verify-all); all smokes green. ✅ **P3.2b-1 (merged):** `UiKit.title_in`/`place`
  hoisted (121 sites) + **`fightlen_probe` FIXED — ALL THREE audit stale probes now
  revived, the open-claim item is CLOSED, verify-all runs 35/35.** ✅ **P3.2b-2 THE
  SCREENS MOVED UP (merged):** all 23 world-layer functions (home/select/party/atlas/
  bastion/zone/conquest) live on `world_shell.gd` — one contiguous cut, typed-`hud`
  access, two-surface `_ui` discipline, 4 routing stubs on the HUD (Esc/fight-end/zone
  route UP); menu/world/raid smokes + shell_probe re-hosted; **verify-all 35/35 ALL
  GREEN + real main_scene boot verified via the Godot MCP** (raid_hud 5,309 → ~4,700
  this phase). OWED: 7 screenshot_* WSLg scripts re-host at the next visual pass
  (left loud, logged in REFIT-PLAN). ✅ **P3.3 ONLINE SPLIT (merged) — PHASE 3
  COMPLETE:** connect form + lobby live on the shell (the presence door); the online
  DESCENT screens stay instance-side (they ARE the online run); net smokes
  checksum-clean through the shell-owned lobby. **THE SHELL INVERSION IS DONE** —
  world_shell owns boot + every world/lobby screen; raid_hud is the instance surface
  (~4,400 lines, from 5,309). Owed from the P3 ledger: 7 screenshot_* WSLg re-hosts ·
  state-ownership lift (`_d`/WorldSave/`_net` off the hud) — P4 companions. NEXT
  CLAIMS: REFIT-PLAN §3 P4 SCALE RAILS (class registry / ClassBand / vuln stack /
  Profile save / run_seed / Split-law guard / twinfang spec split) + §4 the MMO shell.
  *(refit P3 session — entry left uncommitted alongside the dungeon session's WIP claim)*

- ☐ 2026-07-07 · main (docs only) · §WORLD / `WORLD-PLAN.md` — **DUNGEON 1 (THE UNDERMILL)
  — design pass (Bill's brief: Westfall/Deadmines spin, NOT the AI theme; keystone elites;
  quest-system pass w/ adjustments; learner bosses; taunt already raid-only; proposes the
  Combo RIG going raid-only too).** Covers: theme spin options · run shape (1-floor Topology,
  keyed door) · KEYSTONE + keystone-elite/mutator grammar (Forge extension, forge_sim-
  certified) · TICKETS v2 W3 test slate + journal/board · learner boss roster recast from the
  casting pool. Design only, no code; verdicts → fold into WORLD-PLAN §DUNGEON 1 + Forge/W3
  scope. *(dungeon design session)*

- ☑ 2026-07-07 · `refit-p012` → main · §CODE AUDIT / `REFIT-PLAN.md` — **REFIT P0+P1+P2
  BUILT & MERGED (Bill's go).** P0: server `max_fps=60` + `MAX_PEERS`/`MAX_ROOMS`/msg-rate
  floor + net hygiene. P1 THE BIG DELETE: Esc→`_show_home` (dead-menu doorway severed),
  `ui_smoke_map` RE-HOSTED as the raid-descent walker (map→stops→ledger→arming→pulls→
  drops→draft chains→ELEVATED, ALL PASS = its new baseline), **50 files / net −6,854
  lines deleted** (solo HUDs+scenes, stage3d/, orphan sims, tank_policy+m0_content).
  P2: `sim/sim_util.gd` (7 sims migrated) + `scripts/verify-all.sh` (the bar, one
  command) + `scripts/ab-gate.sh` (byte-identical vs pinned worktree; hardened to refuse
  matching-garbage passes) + `server/preflight.sh`. **GATES:** 5 balance sims
  BYTE-IDENTICAL vs pre-branch baseline (identical seeds; raid CSV md5 `fc5351e2…` both
  sides) · net_smoke + net_map_smoke ALL OK · ui smokes raid/map/world PASS ·
  verify-all 30/34 green. **⚠ FOUND PRE-EXISTING RED (on pristine main, NOT this
  branch): `fightlen_probe` (expects zone hp 8500/enrage 150, gets 9600/190 — zone
  tuning moved under it, probably the ×2.5 bake/pack merge) + `raid_boon_probe`
  (after-win flow lands on `recap`, probe expects drop/draft — the recap insertion).
  Their expectations need a deliberate update — OPEN CLAIM.** REFIT-PLAN §3 P0–P2
  as-built; next up the plan: P3 extractions (RunDirector / WorldShell / online split).
  *(refit build session)*

- ☑ 2026-07-07 · `well-deck` → main · §CLASSES — **THE WELL — THE DECK BUILT (healer rework
  FINISHED).** The owed deck per `MENDER-PLAN.md` §2–5 + the ⚖ board verdicts is CODED + wired,
  ALL guarded (empty creed + no modules/boons/rig = byte-identical base, proven). Shipped: per-spec
  **CREEDS** (Brim: Brink/Foresight/Levee/Shallows · Draw: Patient Hand/Long Draw/Narrows/Eddy) ·
  3 auto-firing **MODULES** (⭐ Reservoir · Triage Protocol · Benediction) · **24 BOONS** (Shining
  Hour TEAM aura · Brink Bell · High Tide + Millrace keystones · Strong Pull · Kept Light · Meditate
  battery + Boiling Over clutch spells + the accepts, each `ctype`-tagged) · the per-spec WHEN/THEN
  **RIG**. Framework wiring: `_fw()`/`_fw_*` dispatch (per-spec creed & rig offers) + `_inject_boons`
  + build-panel/REFORGE + `Draft.catalog`/`SIG_KEY` + `RunState.start_well` all handle "well". ONE
  guarded engine touch (Shining Hour aura, mirrors the Glint read → byte-neutral). **Gates all green:**
  determinism PASS base AND fully-loaded deck (both specs) · **default comp byte-identical — 4-Seal
  checksums UNCHANGED (6880/8987/8338/4838)** · well plays+wins the whole Seal ladder (100% expert/
  good, sloppy = the intended gradient) · `well_sim --load` deck bands read (deck lifts survival +
  a real skill gradient) · ui_smoke_raid ALL OK + a new WELL-framework ceremony assertion · draft_sim
  ALL OK. New files `godot/data/well/well_{creeds,modules,boons,rig}.gd`. OWED follow-ups (not
  blockers): WellGauge module METERS (event flashes ship now) · AI use of the 2 drafted spells ·
  balance playtest (Bill) · name lock · online deck carry (shared Twinfang debt). *(healer deck session)*

- ☑ 2026-07-07 · `cask-spec` → main · §CLASSES / `ALCHEMIST-PLAN.md` §7.7 — **THE CASK — SLICE 1
  (verb base) BUILT & VERIFIED.** aspect `cask` guarded on the Alchemist kit (Fermata idiom:
  `_cask()` branches at the top of `upkeep`/`on_action`/`observe`; Brew evals untouched). Full
  §7.1 reducer in `alchemist_kit.gd` (walking band · graded pours Bull/Perfect/Good · MISS→dump ·
  Venom-heat/Rot-time + band walk · per-side STRAIN w/ swap-relief · SEAL→COOK→PEAK-tap sour
  curve · tap-earned PROOF · Rot tail), all numbers `cask_*` on `AlchemistConfig`. First-cut cask
  `AlchemistPolicy._act_cask` + `alchemist_sim` cask cells (`_cask_ab`/`_prove_cask`, `_run_one`
  threads aspect) + minimal HUD selection (`--autostart=raid:caster:cask`). **Gates ALL GREEN:**
  undrafted brew = `4344960863911121821` (byte-identical, 300 seeds) · raid default comp = main
  `8987010164597652967` (byte-identical A/B) · cask determinism PASS 300 seeds · `ui_smoke_raid`
  ALL OK. Verb-health: expert 100%/92%, clean seals + all-peak taps, dumps climb + collapse at
  sloppy (the stake works). **Next (slices 2–5):** the real 3-tier policy (halve cask aim-noise;
  the good tier over-collapses on a first cut), CASKWORKS HUD, card layers, balance. New house
  card-TYPE taxonomy in play (POWER/GREED/STRAT/EASE/RULE/TEAM). **⚠ Note:** the concurrent
  `brew-review` pass (§8 below) proposes back-porting Bullseye/graded pours to the BREW's vial —
  the Cask's graded-pour engine (`cask_grade_*`, Bull/Perfect/Good) is the reference to reuse.
- ☐ 2026-07-07 · main (docs only) · §CLASSES — **TANK REWORK — design pass, ROUND 5: "TWO KITS"
  (parry-vs-dodge · block-wall · combo dumps), tester v5 out.** Fresh-start rework of the tank seat's
  class (old Bulwark = frozen placeholder, NOT the base); no self-heal ever; damage never leads.
  **⚠ CUT HISTORY (don't rebuild): R2 THREE DOORS/lanes · R3 SHIELD CHARGE-&-PLANT WALL + circle-size
  + THE DUEL/balance/TOPPLE/guard-break + hard phase breaks · R4 the shared 3-verb kit (STRONG DODGE
  as a Duelist verb, ATTACK on the Warden, hold-blocks-EVERYTHING as base) — all superseded.**
  **🔒 THE LOCKED CORE — classic rhythm defense (E33 energy) on the HUD's own timing UI:** ONE stream
  of incoming hits drawn as **VERTICAL BARS, HEIGHT = power** (skinny lines; the ONLY fat bar is the
  Warden's HOLD attack — a hit with a **time dimension** you hold your block across, "inside the
  existing dodge, not a new thing"). **PARTIAL mitigation is the law** — even a perfect leaves a
  sliver (mit CAP): the tank is meant to bleed so the healer always has work. **🔒 THE HEALER DUET =
  the scoreboard (replaced the balance meter):** your HP bleeds and a sim healer refills it — bleed
  too little = healer idle, too much = you fall. **🔒 COMBO POINTS ◆** are the new build-and-spend
  resource. **⚡ THE TWO KITS ARE NOW DISTINCT (Bill's spec — this is the headline):**
  **• THE DUELIST (dense/twitch, def+off):** the whole game is **balancing PARRY vs DODGE** —
  **DODGE** (ONE dodge for soft AND hard hits, cheap, partial — but **🔒 you must PERFECT the big
  ones**: a GOOD dodge fully covers small hits and leaks hard on tall bars; only perfect covers a
  big hit — size matters with no second dodge button) vs **PARRY** (its own verb; **tiny window**; costs a big fatigue
  slug **whether it lands or not** so you CAN'T spam it — you pick your moments; land = gut the hit +
  counter + **bank a ◆**; miss = you swung, ate most of it, no ◆). Just one attack, no big/small.
  He faces **UNAVOIDABLE** hits he must eat. Spend ◆ on **⚡ DUMP (offense)** OR **🛡 GUARD (a few
  seconds of heavy damage-cut, defensive)** — your call. Skinny lines only. **⚠ SUPERSEDED 2026-07-09:
  GUARD DROPPED — ◆ → DUMP=damage only, defense moves to the ~1-min CD; + WEAVE added (see TANK-PLAN §1b).**
  **• THE WARDEN (heavy/endurance, def-only + off-cooldown):** **two defensive buttons, NO attack** —
  **BLOCK** (light tap, cheap; a **perfect block banks ◆**) + **BRACE** (heavy; and it's just the
  block **held** — hold it across the fat **HOLD bars** and **overlapping** pairs; drains fatigue
  fast). He can block **everything** (no unavoidables; **PIERCE** is a boss affix, ⚙ knob). Offense =
  **⚡ DUMP**, an **off-rhythm "blind" burst** fuelled by the ◆ from perfect blocks (modules vary the
  dump later). **The old hold-blocks-everything-for-free = a MODULE now**, not base (too strong).
  His stream is **slower + heavier** (sustained/overlap) to contrast the Duelist's density.
  **⚙ WINDOWS:** tight PARRY/perfect (~60ms), bigger GOOD (~230ms). **Kept:** consistent stream (no
  phases), FATIGUE leash, feints (hollow — READ if ignored, BAITED if answered), per-boss authored
  streams (encounter data, Warband Law), coherence rule. **⭐ TESTER v5 (same URL, touch buttons +
  keys):** https://claude.ai/code/artifact/174a77c3-54fe-4449-8a04-81abbcf421fe — DUELIST ⇄ WARDEN
  A/B, per-spec button rows (Dodge/Parry/⚡Dump/🛡Guard · Block/Brace/⚡Dump), combo pips, HP-vs-healer
  duet + boss HP, fatigue bar, feints/unavoidables/hold-bars/overlaps/pierce, ⚙ knobs (windows, mit
  tables, healer inflow, fatigue + combo costs, pierce affix). Source `tank-tester.html`, scratchpad.
  **Next:** Bill plays v5 → verdicts (parry-vs-dodge tension; is the tiny parry window + high cost
  right; combo off/def choice; Warden block-all + hold feel; healer duet; do the kits read on mobile)
  → class plan doc (TANK-PLAN) + deck pass (deck-creator skill; the hold-all wall + dump variations
  are early module candidates) + name pick (class + FATIGUE resource) → guarded build claim (Well
  idiom, byte-identical unless picked). *(tank design session)*
- ☐ 2026-07-08 · main (docs only) · §CLASSES — **TANK REWORK — DUELIST DECK v1 DESIGNED, AT BILL'S
  VERDICT** (deck-creator pass on the round-5 dodge-and-shield kit; Bill's brief: replay-driving
  cards, **DEEP stacked builds — not many strategies fighting**). **`TANK-PLAN.md` WRITTEN** (locked
  core + tester-v5 baseline knobs + the dials + the full slate hard-copied + build order). The slate:
  **4 creeds** (Veteran EASE learner / Wager GREED pole / Bellows rhythm — clean answers restore wind /
  **Dancer WILD — parry button GONE, perfect dodges ARE the parry**) · **3 modules, one ⭐** (⭐ Crucible
  — the BLEED fills it → WHITE STEEL → crash; Scales balance-pan anti-autopilot; Whetstone — banked ◆
  sharpen, unanswered hits dull) · **15 boons in 4 dial-lanes** (SWING/STEP/BANK/SPEND; 3 EASE, ≤1
  dressed pardon per lane; flagships: Return to Sender — guard stores + hurls back; All In full-bank
  dare; Overreach blood-parries feeding Crucible) · **rig 4 earnable WHENs** (Tall Land/Big Spend/
  Wall/Read → STRIKE·IRON·BREATH·PIP·BANNER) · **3 elite keystones** (AVALANCHE — dump = returning
  timed string, the gate reverses; BORROWED TIME — lands slow the stream; IMPOSSIBLE PARRY —
  unavoidables parryable at double cost) · ✦ Hold the Line TEAM support · 4 verified Warden carries.
  **Three named ladders** (HEADSMAN bank-and-burst / IRONSIDE guard-engine / GHOST footwork-chain) —
  every card feeds ≥1, zero ballast. **⭐ VERDICT BOARD (KEEP/TWEAK/CUT + names + export):**
  https://claude.ai/code/artifact/cf273dd1-4169-45e2-b990-47000941d417 — class + WIND name picks ride
  the board. **Dodge-unify reconciled 2026-07-08 (Bill):** design + deck UNCHANGED — the tank keeps its
  own dodge-and-shield minigame and **skips the universal dodge** every other seat runs (TANK-PLAN §1a);
  dodge tank = parry (reclaims the freed F) + dodge, shield tank = block/brace; "verb" jargon dropped.
  **Next:** Bill's export blob → fold → guarded build per TANK-PLAN §4. *(deck session)*

- ☑ 2026-07-07 · main (docs only) · §CODE AUDIT — **STRUCTURAL AUDIT v2 (post-pivot) — DONE,
  `REFIT-PLAN.md` WRITTEN.** 5-agent fan-out (engine/net/UI-HUD/world-meta/tooling) vs the
  new era (world preview = the real shell, hosted central server, raid = dev harness).
  Engine laws verified HOLDING; debt = the shell (raid_hud god file · net_server campaign
  mirror + no persistence/identity · ~6.5k dead solo lines behind raid_hud.gd:3757 · 8
  ad-hoc saves · gate folklore + ui_smoke_map booting a DEAD scene). Plan: P0–P4 phases +
  MMO target architecture + claim table (REFIT-PLAN §3–5) — **phases at Bill's verdict**.
  Doc-drift fixed with the audit: CLAUDE.md "only three"→five sims + plan-doc index,
  psim.sh help string. No code changes. *(audit session)*

- ☑ 2026-07-07 · `fermata-edge` → main (`f5d5397`) · §CLASSES — **FERMATA v5 EDGE BUILT — the
  Ramp & the Snap + the full v5 slate, per `FERMATA-V5-BRIEF.md`.** Bill verdicted v5 (all KEEP
  except feint + shadowstep cut) → built. **The verb:** fermata releases graded by DEPTH
  (`_ramp_grade`: GOOD 45% / PERFECT 37% / BULLSEYE 18% at the lip); crossing the lip auto-SNAPS
  (`_snap`: crash + lock + reroll, checked in upkeep + on a late release; no dead-note state);
  wideners add ENTRY runway only. **Slate:** Patient = THE LONG RAMP (extension past the lip +
  deep bonus + harsh snap); Fleeting snap-net; Shadow Dance = 3s NO-SNAP fever; CUT feint/
  shadowstep/patientEdge/firstPass; NEW Stretto/Refrain/Cold Cut/**The Brink** (nerve meter in
  `_deal`)/Composure/First Note; rig onedge→Razor, deepcoil→Rested; Unseen Blade banks Shades
  while RESTING, Eclipse chains NEAR. **Policy:** fractional depth-aim + latency jitter (fixed a
  narrow-window snap catastrophe). **HUD:** RhythmBar ramp bands + crimson LIP cliff + snap zone +
  SNAPPED flash (WSLg-verified). **GATES:** Tempo `4932869838389671587` / Venom
  `7876031242436484463` byte-identical to main · base+fat+mixed determinism PASS · input_check
  5/5 incl SNAP · raid `--blade=fermata` det PASS · ui_smoke_raid 0 errors · nerve gradient healthy
  (expert ~0 snaps/100%, sloppy 10+/50-70%). Owed (other layers): Brink/Shade/Mark/Dance HUD
  meters · shadow-dim · keystone elite acquisition · Veil warband application · online spec-carry.
  See [[tempo-second-spec-search]]. *(fermata v5 edge build session)*

- ☑ 2026-07-07 · main (docs only) · §CLASSES / `ALCHEMIST-PLAN.md` §8 — **THE BREW deck REVIEW
  pass (deck-creator audit vs the Cask) — ⭐ PROPOSAL BOARD OUT, AT BILL'S VERDICT**
  (`86ca7f68…`). The built slate STANDS; the pass found: ZERO keystones (playbook wants 2–3) ·
  greed-light (5 EASE vs 3 GREED, FUEL/VIAL lanes zero greed) · Fermentation auto-fires (the
  "passive wearing UI" anti-pattern) · the vial = the game's only ungraded pour verb. Produced:
  type tags on all 21 cards + H/S/O PAPER ladders (closes the Brew's verdict-3 ladder debt;
  engine stays the shared slice) + **11 proposals** — Bullseye pours (verb back-port) + Master's
  Draught rider · 3 keystone candidates (Red Line / Quicksilver / Seething Vial, keep ≥2) ·
  Fermentation hold-or-cash · Strike the Seam (settles F1 at deck level) · Steady Under Fire
  (F3-contingent probe) · Brimming (fuel greed) · optional 5th creed THE FEVER · close the
  "4th module owed" debt. Full spec in ALCHEMIST-PLAN §8; fold + build only after verdicts.
  *(brew-review session)*
- ☑ 2026-07-07 · main (docs only) · §CLASSES / `ALCHEMIST-PLAN.md` — **THE CASK — the Alchemist's
  2nd spec DESIGN LOCKED FOR BUILD (§7 written, the Opus handoff spec).** Designed live with Bill
  through 5 browser feel-tester iterations (artifact `72390dbd…`) + a plain-language card board
  (`374af4b3…`) verdicted 24 KEEP / 6 CUT. The verb: STACK 3–6 graded pours (Bullseye/Perfect/
  Good — Bill's order) into a cask on a walking band — Venom=heat/band-up, Rot=time+tail/band-down,
  same-side STRAIN (band shrinks ×0.82 + fills faster, swap relieves −2), last dose = FINISH,
  a MISS DUMPS the batch → seal → ~5s cook → PEAK tap (sour after). PROOF pips = the earned-power
  bar (tap-earned only). 3 creeds (Solera/Overproofer/Single Malt) · 3 modules (⭐ THE BLEND
  compounding master-blend transformer / Cellar bottling / Copper Still racking) · 12 boons +
  A-Round-for-the-House SUPPORT · 3 rig WHENs · Century Cask keystone (A8) · Spitfire-only spell
  carry (Decant/Reduction spec-hidden). CUT ledger + build slices 1–5 + gates in §7. **NEW HOUSE
  TAXONOMY (Bill): every card tags POWER/GREED/STRAT/EASE/RULE/TEAM** — reuse on all future
  boards. UNDER-FIRE feel (F3) flagged untested — first in-game playtest answers. Build claimable.
- ☑ 2026-07-07 · `well-aaa2` → main (`9eeaa41`) · §CLASSES / `MENDER-PLAN.md` — **THE WELL — AAA
  pass #2 MERGED (Bill: "better but far from AAA — basic line borders, squares, no different
  colors, banner covers the mana, bubbles childish").** Rendering-quality rebuild, pure view code:
  **UiKit gains `glow_tex()`/`glow()` (cached radial falloff, tinted per draw — bloom-like light
  in _draw without shaders) + `grad_rect`/`grad_rect_h` (per-vertex gradient fills)** — shared
  toolkit, additive. WellGauge = ONE reliquary console (glass slab + shadow + filigree + water
  crown glow + recessed POOL w/ drifting surface light); orbs = lit liquid spheres in metal
  sockets (layered depth, refraction rim-light, specular, one drifting light-mote — cartoon
  bubble rings gone); Current = chevron stream; target bar = hero bar (gradient fill, glowing
  leading edge, finials). CastChannel seated on a glass pill, gradient fill + glowing edge;
  DRAW channel wears Palette.WATER (spec color identity). Verdict banner rises ABOVE the channel
  — never covers charges or the live window. **Verified:** ui_smoke_raid ALL OK · WSLg shots both
  specs, zero draw errors. *(healer-rework session)*

- ☑ 2026-07-07 · `raid-forge` → main (`781c4dc`) · §MAPS / §THE WORLD / `WORLD-PLAN.md`
  §FORGE — **THE DESCENT REFIT (Bill: "update the raid — packs, phases; more nodes, bigger paths;
  quests/stories as-is with more filler in between").** Forge PALETTES["takeover"] (Realm-1 skins:
  CRAWLER SWARM / UNSUPERVISED LEARNER / SCRUM-CANTOR / LEGACY MONOLITH); RunMap gained a `rows`
  param (default 6 = every existing map byte-identical; raid floors run 8 → **20 nodes/floor**);
  floor_fights interleaves takeover forge fillers between the authored story minibosses (tier ramps
  per ring t1→t3); packroll **v2** swaps full-HP bard/sonnet fillers → forge lightweights at the
  ring's tier + weights 30/45/25 (**closes the forge-built wart** — a rolled trio lands mid-fight-
  sized, not Seal-sized); +1 cooling/+1 cache keep the breather econ proportional; net_server floor
  parity; map_screen scales to any seal row. Entry/Seal/events/tickets/gate quotas untouched
  (stories as-is). **Gates:** packroll_probe v2 · map/pack/fight-seed/menu probes · both UI smokes ·
  net_map_smoke (no desyncs) · raid_map_sim structural PASS on the 20-node floors (losses land on
  Seals, never strays) · forge_sim spot ALL PASS · **frozen-main A/B twinfang(120)+raid(60)
  BYTE-IDENTICAL** (additive/defaulted throughout). Windows play-copy synced. Owed next: per-body
  stage rigs (art); zone-2 palettes.
- ☑ 2026-07-07 · `well-aaa-ui` → main (`f356bad`) · §CLASSES / `MENDER-PLAN.md` — **THE WELL — AAA
  UI sweep (Bill's feel pass #3: "casting bar bigger/clearer/fancier — especially the DRAW click
  part; the well is just blocks → animated blue bubble things; spice up the health bar").** Pure
  view code, zero combat touches. CastChannel now SCALES with control height (classic healers'
  60-tall placement = pixel-identical; the Well places it 660×116) + the release window rebuilt:
  steel CLEAN zone w/ shimmer + entry brackets, gold Still-Point sliver crowned by a gem,
  RELEASE WINDOW caption, playhead needle (white → gold inside the window), in-zone RELEASE flare.
  WellGauge rewritten: charges = glass WATER ORBS (wavy waterline, rising bubbles, gilded rims,
  eased fill/drain, newest-orb glow, DRY pulse) · Current pips w/ travelling light · TARGET BAR =
  jeweled glass health bar (HP numerals, damage trail, ghost landing + hairline, POUR gate/gem/
  plaque, glint aura) · verdict banner centre-stage on a chip. Palette + WATER/WATER_DEEP.
  **Verified:** ui_smoke_raid ALL OK · WSLg shots both specs clean (wave polygon degenerate-vertex
  fix). *(healer-rework session)*

- ☑ 2026-07-07 · main (docs only) · §MODES & ENDGAME / `WORLD-PLAN.md` §INSTANCES /
  `PROGRESSION-PLAN.md` §Laws — **RAID vs DUNGEON identity split (Bill, design session).**
  Bill's WoW-classic instinct (raid daily lockout + humans-only raids + aggro-only-in-raids +
  M+ dungeons) triaged against the laws. **LOCKED:** ~~aggro/threat = raid-only grammar~~ **⚠
  REVISED 2026-07-09 → aggro is now UNIVERSAL** (the tank rework makes aggro = FLOW, a skill
  readout not a rotation — fun enough to live everywhere; one rule in all content, only ambient
  numbers scale; raids keep identity via intensity. `TANK-PLAN §1c`, WORLD-PLAN §INSTANCES);
  **dungeons =
  the M+ push surface** (the 07-04 Depth ladder gets the dungeon door as its primary home —
  30–45 min = the push cadence, Forge tiers + mutators = affixes; raids keep the dial as the
  long-form flex). **CUT (recorded so we don't re-derive):** humans-only raids (breaks the
  Warband Law; with no player base it kills the flagship content — Bill: "my head is too far
  in wow classic land") and the daily lockout (PROGRESSION law 4 re-affirmed in place; RAID
  RITES + descent length carry the "big deal" weight, no clock). The instinct's REAL goal —
  "make people play together" — recorded as **MMO-feel levers** in the parking lot
  (warband lending / bounty board / ghost races / co-op standing). No code. *(design session)*

- ☑ 2026-07-07 · `mender-rework` → main (merge, base build) · §CLASSES / `MENDER-PLAN.md` — **THE
  WELL — reworked direct-cast healer, BASE BUILT & MERGED.** The healer rework (MENDER-PLAN, Bill's
  tester+board verdicts) ships as a guarded class **`well`** on the healer seat (Alchemist idiom —
  byte-identical unless picked; old Mender untouched as the default). **Built:** CHARGES economy
  (12, pulse +1/2s, no mana) · pure-cast book (flash/mend/cascade/wellspring/dispel/rekindle —
  Ward/Renew/Meditate cut; Rekindle no-CD long-cast) · **BRIM** (aspect `brim`, dev-label TARGET)
  grades the LANDING (pour/spill/plain + landing preview) · **DRAW** (aspect `draw`, SPEED) grades
  the RELEASE (clean/still/undercook/overrun) + **THE CURRENT** (cast-haste streak, breaks on
  undercook/DRY, ebbs) · **THE GLINT** (personal — healed ally +40% dmg 4s via one guarded engine
  touch in `_apply_group_damage`, byte-neutral) · the **WellGauge** HUD (charge vessel · Current
  pips · release band + Still-Point sliver · verdict rail) · per-ally ✦ Glint frame chip · `WellPolicy`
  (both specs, 3 tiers) · `well_sim` (+psim.sh) · `raid_sim --healer=well` · RaidNet carry. **Gates:**
  determinism PASS both specs · DEFAULT comp byte-identical to main across all 4 Seals
  (6880/8987/8338/4838, verified pre+post) · well plays+WINS all 4 Seals · `ui_smoke_raid` ALL OK
  (brim+draw combos added) · WSLg shots verified (both instruments + Glint chip render). Play:
  `--autostart=raid:healer:brim|draw`. **Bands:** draw gradient clean (maw 25/21/15 · rot 45/36/16
  · glint 83/33/18); brim survival-strong (win-gradient thin — policy depth owed). **NEXT (the deck,
  a follow-up build claim):** creeds (Brink/Foresight/Levee/Shallows · Patient-Hand/Long-Draw/
  Narrows/Eddy) · modules (⭐Reservoir/Benediction/Plumb-Line · ⭐Siphon/Double-Draw/Triage) · the
  accepted boon slate + rig WHENs + High-Tide/Millrace keystones · sharpen the BRIM win-gradient ·
  balance playtest · class NAME lock · online creed/module/rig carry (shared Twinfang debt). See
  `MENDER-PLAN.md` ⚖ block. *(healer-rework session)*
- ☑ 2026-07-07 · `forge` → main (`d3722f5`) · §THE WORLD W2 / `WORLD-PLAN.md` §FORGE — **THE
  FORGE v1 BUILT (Bill: "lets go for the forge"; THE CHASE parked same day — "pressure to do
  one thing or another is meh").** `data/world/forge.gd`: seeded encounter assembler — 4 BODIES
  on the baked baseline (SWARM 4.6k pack-filler · STALKER 7.2k feints · CHANTER 6.8k kickable
  verses · BRUTE 9.6k parry exams), TIER knobs t1→t3 (cast ×1.0/.85/.72, cd ×1.0/.9/.8, +string
  beats, dmg creep ≤15% — never stat inflation), 1–2 moves seeded per fight from per-body verb
  palettes (parry swing / dodge string w/ seeded feint beat / kickable chant / nova), zone
  PALETTES (Gildfields: CHAFF-SWARM · HEDGE STALKER · GRAIN-CANTOR · HUSKMAN REAPER + seeded
  epithets) + NAMED souls. **THE ID IS THE RECIPE:** `forge:<zone>:<body>:<tier>:<seed>[:named]`
  regenerated by an additive `encounter_by_id` arm — specs stay strings; packs/lockstep/replays
  carry Forge fights free. **Zone 1 content pass:** every Gildfields stand-in swapped to
  authored forge ids (TONE CRACK CLOSED — no more BARD.EXE in the fields); Long Furrows = a
  chaff PAIR (authoring rule: a swarm is never alone); THE PALE TILLER = t2 brute wearing its
  authored soul (the named-miniboss rule); capstone stays VORATHEK; raid Topology fillers stay
  Realm-1 bodies (correct inside the door). **Gates:** `sim/forge_sim.gd` certification (psim-
  sharded; determinism per id, ZERO expert-unwinnable, band floors, 15s degeneracy floor) —
  864-row sweep **ALL PASS** (TTKs ramp swarm≈19s→brute-t3≈62s, every cell 100% expert) ·
  frozen-main A/B twinfang(120)+raid(60) **BYTE-IDENTICAL** · world/raid smokes + world/pack/
  packroll/menu probes green · play copy synced. **NEXT:** packroll fillers → forge swarm
  bodies (kills the full-HP-filler wart); zone-2+ palettes; stage rigs per body (art pass);
  tier-3 borderland pockets when LEVELS lands. *(world-structure session)*

- ☑ 2026-07-07 · `packroll` → main (`89918db`) · §THE WORLD / §MAPS — **PACK QUOTAS v1: the
  Topology now ROLLS packs** (the "generator" half of Bill's pack ask; zones stay authored per
  the shape-assignment rule). Offline descents: MID skirmish nodes roll 50% solo / 35% duo /
  15% trio, seeded from (map seed, node id) — deterministic per descent; entry + Seal never
  roll; light fillers (bard/sonnet) walk in first and the node's own body CAPTAINS (dies last —
  oaths + drop ceremony stay anchored to the kill that matters); OVERCLOCK/curse marks land on
  member 1 only (known v1 wart). Online descents unchanged (server-side pass later). Gate:
  `sim/packroll_probe.gd` (never-roll slots · determinism · 50/38/12 measured @400 · captain
  rule · built chain) ALL OK · raid smoke green · play copy synced. **NEXT feel knob:** duo/trio
  weights + filler pool per ring; Forge SWARM bodies replace the full-HP fillers (a trio runs
  Seal-sized at the baked ×2.5). *(world-structure session)*

- ☑ 2026-07-07 · `baselen` → main (`7d740fe`) · §BOSSES / `WORLD-PLAN.md` §FIGHT LENGTH —
  **THE ×2.5 LENGTH IS NOW THE GAME (Bill: "i dont like the long fight and normal branch,
  merge this into the main").** All 4 Seals + 3 skirmishes: HP + enrage ×2.5 baked into
  `raid_content.gd` (riftmaw 38750/225s · mistral 33750/237.5 · gemini 41250/270 · mythos
  47500/355 · bard 8500/150 · sonnet 9000/150 · opus 10500/175); adds untouched (matches what
  Bill felt under the scalar); gate exams (class-content 1v1s) stay authored-short by choice.
  The LONG FIGHTS bat is DELETED — one launcher; `--fightlen` survives as a dev knob relative
  to the new baseline. **Gates:** twinfang_sim 120 **BYTE-IDENTICAL** vs fresh frozen main ·
  raid determinism PASS · full battery green (pack/fightlen/world probes, world/raid/map/menu
  smokes, net_smoke). **New raid bands @60:** riftmaw 100/97/77 · mistral 100/100/100 ·
  gemini 100/87/10 · mythos 100/83/0 — skill spread widens (the design goal); the healer
  regen/mana retune is the standing good-tier lever (the raid-healer inert-mana finding
  closes through it). Windows play copy synced. *(world-structure session)*

- ☑ 2026-07-07 · `worldreset` → main (`9aeda85`) · §THE WORLD — **dev world-reset button**
  (Bill: "i already beat that one, i cant redo it"). Atlas bottom-right "⟲ reset world (dev)",
  armed double-press (first press turns ⚠ SURE?), `WorldSave.wipe()` writes a fresh save over
  disk; world smoke proves reset → 0 conquered + flags forgotten. *(world-structure session)*

- ☑ 2026-07-07 · `pack` → main (`f912a4f`) · §THE WORLD / ENGINE / `WORLD-PLAN.md` §FIGHT
  LENGTH — **PACK v1 BUILT (Bill: "make a good plan for the pack generator, then execute"):
  sequential encounters in ONE battle, heat carries.** Engine (guarded — every classic fight
  byte-identical): `CombatState.pack/pack_i` (empty = single), `BossState.entered_tick` (0
  default), `_pack_advance` on member death (in-place BossState reset — no stale refs;
  telegraph cleared; fresh threat = re-establish the pull; seeded ability stagger),
  **walk-in grace** `pack_walkin_ticks` (TuningConfig, 75 = 2.5s — no enemy actions, players
  may open: the diegetic valley), **per-member enrage** (entry-relative clock). Spec: pack ids
  ride `(seed, spec)` (make_spec/make_state/build; size<2 normalizes away; online untouched,
  no protocol bump). HUD: `pack_next` name-card ("NAME · 2/3"), plate/dial rebind free (they
  read s.encounter live); `--fightlen` scales waiting members + their enrage. Content: THE
  GRANARY STEPS = bard→sonnet→opus (smalls→captain), THE HOLLOW WARREN = bard→sonnet→bard
  (gauntlet); node `pack:[]` payload. **Gates:** `sim/pack_probe.gd` ALL OK (size-1 pack ==
  plain pull checksum-identical · 3-member win via policies 44.5s · walk-in silence · entry-
  relative enrage · determinism) · frozen-main A/B psim twinfang(120) + raid(60) merged CSVs
  **BYTE-IDENTICAL** · net_smoke checksums clean · world/raid/map smokes + menu/world/fightlen
  probes green (world smoke now drives the Granary pack). **NEXT:** Bill feel-test (packs ×
  fightlen — the total pool runs Seal-sized: author fewer members OR wait for Forge SWARM
  bodies); then THE CHASE shape; Topology pack quotas (dungeon floors); Seal pillar pass.
  *(world-structure session)*

- ☑ 2026-07-06 · main (docs only) · §CLASSES — **HEALER REWORK FIRST PASS — design board AT VERDICT**
  (artifact https://claude.ai/code/artifact/68b0c28c-cc3a-4655-b9d5-fdc67e929e24). Bill's ask: heal-low +
  overheal read as boons not specs; weigh merging Mender+Bloomweaver into one 2-spec class. Findings:
  the code confirms the diagnosis (Tidecaller/Brinkwarden = one casting verb, one inverted Litany
  condition — `mender_kit.gd:167`); **recommendation = DO NOT merge** (Split-law F10: cast-triage vs
  seed-gardening are different games; decks are per-spec so the merge saves nothing; the seat toggle
  already offers both). Proposed: Tidecaller/Brinkwarden DEMOTE → Foresight/Brink CREEDS; Reservoir→
  ⭐ module · Nerve→module · Litany/Benediction→module (all re-homed coded machinery); NEW verb = **THE
  WELL** (visible pulse-refill mana vessel, instrument) + **THE BRIM** (heals graded by where the
  target's HP LANDS — perfect pour); second spec = **VIGIL** (hold a finished cast, release on the
  spike — Fermata's press/release mirror); damage-healer = a 3rd healer-seat class, future. Build plan:
  verdicts → MENDER-PLAN.md → HTML brim tester → guarded in-game base (`raid:healer:…`, byte-identical
  unless picked) → deck/instrument/sim at `--fightlen` bands. **BRIM FEEL-TESTER BUILT & LIVE** (same
  day, Bill: "make a browser basic tester"): party under scripted Rendmaw-style pressure (melee/
  buster/nova/hex) + the 4-spell book + Meditate, the Well w/ pulse refills + dry state, brim-band
  landing grades (PERFECT POUR refund / SPILL / plain) w/ landing preview + grade rail + efficiency
  ledger, **BRIM ⇄ DRAW A/B toggle** + ⚙ knobs (band/refund/pulse/damage/draw-band) —
  https://claude.ai/code/artifact/80b2169b-3f38-488e-a31c-d9b49a718b25 (source:
  session scratchpad `brim-tester.html`). **⚡ 2026-07-07 — VERB PAIR LOCKED off the tester** (Bill:
  "i like both alot, the draw one is very nice … can we do both specs with those?"): **BOTH tester
  modes promote to the spec pair — SPEC 1 BRIM (grade the landing, on the ally's bar) · SPEC 2 DRAW
  (grade the release, on your cast bar)** — same book/Well/GCD, attention inverts (read the party vs
  read your hands; the Tempo/Fermata symmetry). VIGIL (the hold) folds into Draw build territory
  (Patient-Hand creed / transformer candidate). Class doc created: **`MENDER-PLAN.md`** (creeds =
  demoted aspects per-spec · modules = 3 re-homed machines w/ ⭐ Reservoir · tester knob baseline ·
  build order, Alchemist idiom, old Mender stays frozen default). **⭐ VERDICT BOARD OUT (same day,
  Bill: "give me an artifact with all the ideas for both, 1 tab each, 1–5 stars + comments"):**
  https://claude.ai/code/artifact/958cdbe8-7c92-48cb-bf95-eae69b3994c1 — the full idea slate as
  rateable cards (BRIM 25 · DRAW 25 · CLASS 9: base rules · 4 creeds · 3 modules · 10 boons · 4 rig
  WHENs · keystone per spec + shared Well/Shining-Hour/Boiling-Over/kick/Dry-Ward/names), stars +
  comments persist in-browser, EXPORT copies a paste-back summary. **⚡ 2026-07-07 — BILL'S FULL
  EXPORT LANDED (66/66 rated) + FOLDED → `MENDER-PLAN.md` ⚖ block is the record.** Headlines:
  ~~THE CRIT MODEL~~ **→ ✧ THE GLINT (crit TORN OUT same day — Bill: "kills the planning for the
  brim; not mana not healing, already using it for the cascade"):** a perfect (Brim pour · Draw
  Still Point) = **the HEALED ALLY +~40% damage ~4s** (PERSONAL — Bill: "just for the person we
  are healing, not everyone"; who you bless joins the triage game) — precision pays OUTWARD
  through kill speed, never the Well; clean rhythm pays INWARD (the Current);
  refunds/crits/bigger-heals all dead ·
  **BOOK REWORK** (all heals casted+direct: Ward/Renew CUT, Meditate → boon, Rekindle no-CD
  long-cast) · resource = **CHARGES** · spec dev-labels **TARGET/SPEED** · healer = **0 kicks** ·
  preview BASE + blindfold boon · Brimful on big-CD buttons only · creed reworks owed (Quick
  Pull→THE NARROWS all-or-nothing · Dead Reckoning→THE EDDY drifting band, both Bill-specced) ·
  ⭐ Reservoir rework owed (3★ + Ward cut guts it) · cuts: Deep Refund/Runoff/Steady Arm/Edge of
  the Lip/edge+held WHENs/Slow Water(parked). Tester **v6 = the verdicted build** (charges
  default, 3-spell book, Glint live + boss HP/kill-clock/best-time so the reward is FELT).
  **NEXT: Bill feels v6 (Glint = my rec; runner-up THE GILD on file) → the build claim**
  (guarded base `raid:healer:brim|draw`, byte-identical unless picked). *(healer-rework session)*
- ☑ 2026-07-06 · main (docs only) · §BOSSES / `WORLD-PLAN.md` §FIGHT LENGTH — **THE PACING
  GRAMMAR locked (Bill: fights much too short, "rarely get a combo off").** Current truth: Seals
  enrage 90–142s, skirmishes 60–70s — the Framework-v2 kits out-arc the fights. Locked: length
  from STRUCTURE, never sponges/screens — two laws (**NO FLAT SPONGES**: every added minute
  arrives with a structure beat · **DEMAND ROTATION**: long fights rotate the loaded skill;
  dodge ration budgets per SEGMENT) + six shapes to mix (Bill: "mix all those"): **PACK**
  (1–4 sequential enemies, one battle, HEAT CARRIES across members — a per-class pack-carry rule
  joins each rework's spec) · **VERSE/CHORUS** (default long boss) · **REPRIEVE** phase-pause
  with a job (+THE DENY: kickable boss recovery — pillar-3 showcase) · **THE CHASE** (multi-
  arena running battle) · **INTERLUDE WAVES** (proven) · **SIDE-DUEL/AURA-ADD** (Manastorm
  steal). Bands: zone skirmish 60–90s · pack/elite 2–4m · capstone 4–6m · dungeon Seal 5–8m ·
  raid Seal 8–12m ("10-min boss" = raid tier) · world boss 5–10m; the zone spine stays
  skirmish-weight (attunement budget holds). Healer mana/regen rebalances WITH the bands — the
  logged inert-healer finding is largely a fight-length symptom. Lands with W2 Forge (SHAPE
  axis) + the boss PILLAR PASS. **VERDICT PASS (Bill, same day):** PACK kept (primary) · CHASE
  kept · WAVES kept-lukewarm · verse/chorus CUT (illegible) · REPRIEVE+DENY CUT (a pause with
  jobs is MORE stress; no flow-preserving hard-stop exists → new law: **NO HARD STOPS, valleys
  are diegetic** — walk-ins/withdrawals/transits, the clock never freezes) · side-duel/aura-add
  CUT ("very anti fun"). **`--fightlen=N` dev feel-scalar BUILT & MERGED (`c0ccffd`,
  branch `fightlen`):** all five offline launch paths scale boss HP+enrage post-build
  (RaidMarks idiom, INF-guarded, flag absent = untouched); `sim/fightlen_probe.gd` proves ×1
  byte-equal + ×2.5 exact (riftmaw 15500/90s → 38750/225s; bard 3400/60s → 8500/150s);
  raid/world smokes + menu probe green. Bill feel-tests with `--fightlen=2.5` next.
  *(world-structure session)*

- ☑ 2026-07-06 · main (docs only) · §SYSTEMS / `PROGRESSION-PLAN.md` §LEVELS + `WORLD-PLAN.md` —
  **LEVELS: the paced unlock rollout (design session with Bill, direct).** Bill's ask: WoW-shaped
  slow roll — level up for boons, zone milestones introduce Modules/Creeds, high-level areas tease
  the future, oaths give XP, "once max level you've unlocked it all"; goal = spread the skill curve.
  **Verdict: legal under Law #1** (levels = options/access, never stats; XP = non-spendable event
  meter, not a meta-currency; StS front-load note AMENDED — stretched, not deleted). **Locked model
  = HYBRID WAVES:** milestones unlock SYSTEMS account-wide (Zone 1 crest → Modules · first dungeon →
  Creeds · Zone 2 → rig · first Seal → 2nd curio slot); event-XP levels (quests/oaths/firsts/
  conquest/instance clears — NO kill-grind, the world can't farm anyway) pace each class's boon pool
  in authored waves of ~2–3; Ledger/gear/curios untouched; endgame stays Depth/Versions. **Zone
  gating (Bill's catch: options-not-power means difficulty alone can't wall the skilled): CREST-
  GATED SPINE + OPEN BORDERLANDS** — Zone N+1 needs Zone N's crest (access-lane, a moment not a
  number); 1–2 over-tier borderland pockets per zone stay open as the Duskwood tease (Forge TIER
  wall, standing pay only). Skill-spread = two dials: buttons grow with account age, demands grow
  with content tier; no scaling system needed (a low-level friend plays a simpler kit in the same
  fight). DESIGN LOCKED, not built — builds with W2/W3 (XP ledger on the world save, wave tables,
  crest gates, borderland nodes). *(world-structure session)*

- ☑ 2026-07-07 · `escort-ticket` → main (`44c727e`) · §THE WORLD W2 — **ESCORT/VOLATILE
  TICKET — thinnest flagged slice BUILT + deepened + MERGED (Bill: "keep building"/"keep going"/"merge
  ① to main"; §MEWGENICS STEALS ①).** Reconciled with the concurrent PACK system on merge (burden
  applies to the on-field encounter = pack lead / single fight); post-merge world_probe + ui_smoke_world
  green, raid_sim byte-identical to main (a83e7cbd). *Deepened `eaf628e`:* sustained two-wave burden + pre-pull warning (pressure↔vial) +
  cleared-door turn-in soft-lock fix — still byte-identical + green. Carry a
  payload PICKUP→TURN-IN; while carrying, fight/elite nodes get an enemy-side BURDEN add (the boss
  withdraws to face it) — a burden not a buff (OVERWORLD POWER + mutator-on-enemy laws hold),
  PERSISTENT via the world save's per-zone flags. **NEW `data/world/escort.gd`** = pure logic
  (WorldSave + node → transitions + burden id, like WorldContent) so it's headless-testable and
  the HUD is a thin caller behind `ESCORT_PREVIEW`. Burden = `RaidContent.apply_burden` appends a
  fixed AddRes to a FRESH encounter via the existing add-wave engine (**CombatCore untouched**);
  rides `RaidNet.build`'s `carry` as pure data → **absent = byte-identical**. Gildfields route:
  WARDEN'S REST(4) → GRANARY STEPS(5) burdened → UNDERMILL GATE(19). **Verified:** `world_probe`
  ALL OK (state machine + gate + persistence + deterministic burden that provably changes the
  fight) · `ui_smoke_world` ALL PASS (HUD drive + escort-inert-on-rush guard) · `raid_sim`
  **byte-identical** to main baseline (`raid_results.csv` same md5, 2401 rows). **Owed before
  merge:** richer burdens (kickable cast / hazard beat) · lane-law turn-in reward (a pool row, not
  today's standing flag+toast) · route→authored node fields · cleared-door turn-in edge. **Awaiting
  Bill's feel pass** (`--autostart=zone`, or run from the `wow-escort-ticket` worktree). *(escort slice session)*

- ☑ 2026-07-06 · `alch-cards` → main · §CLASSES / `ALCHEMIST-PLAN.md` — **THE ALCHEMIST CARD SLATE,
  CODED (all six slices).** Bill: "go ahead and code it" (the locked pre-build slate). On top of the
  base minigame: **4 Creeds · 3 Modules (incl. the ⭐ Reaction-Vessel) · the 6×6 Combo Rig · 18 Boons ·
  3 Spells**, each landed guarded + sim-A/B'd + policy-taught per layer. (a) Framework generalized —
  `_fw()` provider + `_fw_creed/module/rig*` dispatch replaced the Twinfang-only `_blade_tempo_human()`
  gate everywhere (creed pick / module pick / rig wire / `_inject_boons` / build panel / rig-fire pop);
  the Alchemist caster swears a Creed. (b) Modules w/ a compact ALEMBIC gauge + catalyst key 4. (c) Rig
  off the brew's own beats (fuel raw-fractional). (d/e) Boons incl. **Debilitator** — the SUPPORT debt,
  a raid-wide `boss.debilitate` debuff via a **sunder-precedent engine touch** (BossState/TuningConfig/
  CombatCore, guarded byte-neutral). (f) Spells keys 5/6/7. **Creed-aware offers** (verdict 6):
  `hide_creeds` tag + `Draft._ok()` check + module/rig-board filters — draft offers 21 cards, Purist
  hides the 4 rupture cards (21→17). **GATES:** undrafted brew BYTE-IDENTICAL (Crucible seed1
  `4344960863911121821`); raid DEFAULT comp byte-identical to pure main (`4978452801628609439`, freeze-
  snapshot A/B — the Debilitate touch is byte-neutral); creed/module/rig/boon determinism ALL PASS;
  **net_smoke ALL OK** (lockstep) · gear/commander/raid/draft probes PASS · ui_smoke_raid + ui_smoke_world
  PASS · WSLg ALEMBIC render OK. Card BALANCE = Bill's playtest dial (each distinct+sane, skill moves
  outcomes; Chain Rupture −12.6s/Catalyst −9.0s are the standouts; HotPour/Emulsion/Practiced Hand/
  Reduction are human-skill/comfort cards the safe AI doesn't chase). **Owed:** 2nd spec · class puppet ·
  ONLINE spec-carry of creed/module/rig (offline map+gate carry them via `_inject_boons`; RaidNet spec
  doesn't — a shared Twinfang follow-up) · Commander AI-caster toggle · name/art. *(alch-cards session)*

- ☑ 2026-07-06 · main (docs only) · §THE WORLD / `WORLD-PLAN.md` — **MEWGENICS RESEARCH → 3 STEALS
  FOLDED (Bill: "fold ideas, 123").** Deep-research pass on Mewgenics' overworld/quest loop
  (verify stage cut per Bill — Opus + trusted sources; 19 sources, reviews + wiki.gg). Finding:
  its skeleton already matches ours (node maps · pickup→turn-in quests · attrition · persistent
  linear unlocks), so only three parts were worth taking, each adapted to our laws and targeting
  **W2** (Forge + TICKETS v2): **① ESCORT/VOLATILE tickets** (new grammar verb — carried payload
  applies an enemy-side mutator to fights en route; a BURDEN not a buff → OVERWORLD POWER +
  mutator-on-enemy laws hold; turns TICKETS into a mechanic; GILDFIELDS grain-vial fit) · **② THE
  QUEST BOARD** (BASTION station = optional-ticket faucet, their Invention-Quest split; lane-law
  rewards only) · **③ the legible RISK FORK** (sharpen "cave vs rush" into a signposted
  reconverging easy/hard beat; reward axis swapped to pool/standing, never Mewgenics' level-ups).
  **NOT stolen:** roster retirement/churn (breeding engine Bill cut; fights fixed-warband) · mana
  combat (wrong genre) · route predictability (ZONE REMEMBERS already beats it). **Parked (run
  layer, not zones):** their post-boss "bank now or push deeper" push-your-luck. WORLD-PLAN gained
  §MEWGENICS STEALS + an ESCORT entry in the quest grammar + a QUEST BOARD station. *(mewgenics
  research session)*

- ☑ 2026-07-06 · `tempo-real` → main (`67f5efc`) · §TEMPO — **THE WHOLE TEMPO PLAN, CODED.** Bill:
  "code everything, make it real." All kit-local + deterministic across 6 files (boons/config/creeds/
  modules/kit + sim). Cuts (Opportunist·Held Note·spells·Killer's Eye; Edge→Largo creed·Deathmark cut;
  Opening=class base) · base-kit fixes (F8/F11/F15/F17/F19/F26) · crit rework A7 (Heartseeker always-crit
  + HONE standing Edge meter + Serrated + Assassin's Note, no base crits) · Largo creed · Through-Line ·
  Understudy · Overdrive module (FEVER, verified firing @expert) · Battle Hymn signal. VERIFY:
  twinfang_sim ALL determinism PASS; crit build 90→100%/41.6→29.1s; Overdrive fevers/run 1.00;
  ui_smoke_raid ALL OK; raid_sim --blade=tempo 4 Seals det PASS. TEMPO-PLAN Appendix A banner added.
  **Owed follow-ups (other layers):** HUD gauges (raid_hud render), Battle Hymn party-aura (raid buff
  channel), A8 keystone/elite acquisition (Topology elite node). *(tempo-real session)*

- ☑ 2026-07-06 · main (docs only) · §CLASSES / `ALCHEMIST-PLAN.md` — **ALCHEMIST PRE-BUILD
  RUN-THROUGH (Bill, direct): the card slate is LOCKED for build.** Four Bill calls:
  **⭐ transformer = THE REACTION-VESSEL** (reaction banks instead of dealing; Rupture dumps the
  vessel — sustain/burst inverted; Twin-Still and Catalyst-forge rejected) · **rig slate locked**
  (settles F13/I3: Sweet Pour/Hot Pour/Emulsion/Ripe/Boil/Perfect Wave → Splash/Backwash/Quicken/
  Residue/Fume/Overfill; Purist board hides the Rupture WHENs) · **fixed rarities this slice**
  (the per-offer H/S/O roll is DESIGNED-NOT-BUILT for Tempo too — shared engine slice later) ·
  **F22 settled: Spitfire = designated interrupt carrier when pillar 3 lands** (no engine work now).
  Four holes found in the accepted cards + fixed in the plan: **Last Call reframed** (no cleanse
  mechanic exists and phases don't wipe the brew → phase-transition auto-cash, no wipe added) ·
  **Chain Rupture was stale** (base already keeps 35% → card is now +30pp, ≈0.65) · **creed-aware
  offers get a mechanism** (`hide_creeds` tag + `Draft._ok()` check, byte-identical untagged) **and
  extend to modules** (Purist never sees Fermentation/Reaction-Vessel) · HUD framework plumbing
  noted Twinfang-hardcoded (generalization = slice a). Build order = ALCHEMIST-PLAN §6.3 slices
  a–f; next session codes it. **→ CODED in `alch-cards` (entry above).** *(alchemist run-through session)*

- ☑ 2026-07-06 · `world-w1` → main (`b9c26aa`) · §THE WORLD W1 — **THE ATLAS + ZONE 1 + THE
  BASTION BUILT (Bill: "go ahead and build this... 1st zone is big impressions"), flagged
  preview** (`WORLD_PREVIEW` home button + `--autostart=world[:seat[:aspect]]` / `zone`;
  front-door flip stays W3). **ZONE 1 = THE GILDFIELDS** (working name; was "Mirefen" — Bill
  asked for Westfall inspiration): authored 20-node conquest map, dying-harvest arc that
  funnels into the UNDERMILL dungeon door (the Westfall steal: the zone's mystery IS the
  dungeon's setup); spine 9 inside the attunement budget; cave chain (Pale Tiller miniboss) ↔
  marsh smugglers' path (the door RUSHABLE without the capstone, BFS-proven); THE SLUICE =
  the ZONE REMEMBERS teaser (permanent flag floods the Drowned Acre fight into a cache);
  personal gate; waystation → Atlas flight web. New: `game/world_save.gd` (versioned
  `user://rift_world.cfg`, canonical sorted-key JSON, headless disk-inert) ·
  `data/world/world_content.gd` (earnest world fiction — tone law holds; W1 fights are
  canonical stand-ins bard/sonnet/opus/riftmaw, the W2 Forge recasts them) ·
  `ui/atlas_screen.gd` + `ui/zone_screen.gd` (fog/frontier/silhouette render, worn-road
  curves, warband token) · Bastion hub v1 (Commander party setup re-doored as THE WARBAND
  CAMP via `_party_ctx`). Zone pulls are BARE KIT through the shared RaidNet factory, no
  overrides — isolated, full HP, conquest is the only writeback. **Gates:** `world_probe`
  (structure / conquest semantics / variants / save round-trip / fight determinism) ALL OK ·
  `ui_smoke_world` full-loop ALL PASS (bare-kit asserted on every pull) · psim twinfang(120)
  + raid(60) per-seed CSVs **byte-identical** vs frozen main · ui_smoke_raid/map +
  menu/commander/gear probes green · WSLg 6-shot tour eyeballed + sent to Bill. **Notes:**
  main_menu now routes `gate`/`world`/`zone` autostarts to the raid scene (was raid-only);
  the `raid_frames/col_std` ConfigFile noise in headless smokes is PRE-EXISTING (27 hits on
  frozen main). **NEXT:** Bill plays it (`--autostart=world`), feel verdicts → W2 (the
  Encounter Forge + the TICKETS v2 content pass); door-exit polish (descent end → Atlas,
  not home). *(world-structure session)*

- ☑ 2026-07-06 · main (docs only) · §THE WORLD / `WORLD-PLAN.md` — **GAME STRUCTURE + ZONE QUESTS
  design session (Bill, direct).** Bill's structure question ("one session used to be a zone; now
  nodes launch instances — keep the mid-run deck economy or start fresh?") → **THE SPLIT locked:**
  run economy stays instance-only VERBATIM (the run still exists behind doors — a dungeon IS the
  old session compressed); zones get the new persistent **TICKETS v2** grammar (route / deed /
  door tickets in Zone 1, event tickets at W4; lane-law rewards only; "quests edit the collection,
  runs edit the deck"). **ELITE = Forge body + enemy-side MUTATOR** (Bill's module idea; optional
  1-of-2 choose-your-poison). One-time spice pick = **THE ZONE REMEMBERS** (permanent zone flags
  rewire later nodes; Zone Heat passed over → later-zone candidate). Bill's replay question
  answered with the **GUEST-WORLD rule** (a zone session plays the least-progressed member's
  world; pending choices write back only to saves that still had them; guests re-fighting the
  host's uncleared nodes IS the replay). Node formula: spine 8–12 capped by the attunement
  budget, breadth scales — Zone 1 ~20 nodes (was 14). **RAID RITES parked** (Bill: hard
  mandatory every-entry raid nodes — "that's later"). WORLD-PLAN gained §ZONE QUESTS & DYNAMICS;
  Zone-1 content line + PARKED updated. No code. *(world-structure session)*

- ☑ 2026-07-06 · `tempo-strike-lane` → main (`c1071bd`) · §TEMPO — **STRIKE lane bread: Press the
  Advantage + Cold Open.** Two non-crit STRIKE boons filling the gap the crit exodus (A7) left.
  Press the Advantage: basic Strikes inside the Opening +30% (new `_in_opening` test). Cold Open:
  Strikes at Flow ≤2 +25% (low-Flow mirror of Tightrope). Both guarded in `_deal` on kind
  perfect/strike + `_b()` — byte-identical when undrafted. Verified: twinfang_sim determinism ALL
  PASS + boonless CSV byte-identical; strike A/B 90.0%/43.8s→95.0%/41.7s; ui_smoke_raid ALL OK;
  raid_sim --blade=tempo 4 Seals det PASS. TEMPO-PLAN Appendix A1/A6 marked built. *(strike-lane session)*

- ☑ 2026-07-06 · `alchemist-core` → main · §CLASSES / `ALCHEMIST-PLAN.md` — **THE BREW BASE
  MINIGAME BUILT (Bill's direct order — playtest before boons).** Bill: "can't go farther without
  knowing live things — just do the base mini game, UI/bars, then the rest after; UI is the main
  focus, very nice and full and flashy." Shipped: `data/alchemist/` kit (artifact timing verbatim,
  all constants tunable + `dmg_scale` 0.55 raid dial, zero rng, state in `seat.vars`) · caster seat
  goes POLYMORPHIC (voidcaller default | alchemist) through raid_content/raid_net/raid_sim/HUD
  ceremony/party/lobby · **THE ALEMBIC** (game/ui/brew_gauge.gd — hold-zone reservoirs, breathing
  sweet-band vial w/ verdict stamps + droplet pour arcs, tap-to-Rupture chamber w/ acid bloom +
  RIPE halo, balance see-saw, shimmering potency strip, pour-history gems, scale-punch banners;
  the game's first hold-release verb: HOLD 1/2 → release pours, 3/R ruptures) · AlchemistPolicy
  (3 tiers: release-aim + rupture-peak noise) · `alchemist_sim` in `psim.sh` · gate exam THE
  SANDBOX (kickless class can't play the Prompter) · codex entry · Draft null-guards (boonless
  class skips REFORGE) · `screenshot_alchemist_raid` visual probe. **Gates:** default comp
  BYTE-IDENTICAL vs main (twinfang_sim 150 seeds + raid_sim 4 Seals × 100 seeds, per-seed CSV
  checksums) · alch determinism PASS (solo + raid) · ui_smoke_raid (+brew coverage) / ui_smoke_map /
  net_smoke / raid+commander+draft+gear+menu probes / raid_map_sim / fight_seed_probe ALL OK ·
  WSLg shots verified. **Bands:** solo crucible 100/99.7/50 · leech 96/78/0.7 (300 seeds); raid
  alch-comp riftmaw 100/100/68 · mistral 100/100/100 · gemini 100/99/47 · mythos 100/94/21 —
  expert parity with the voidcaller comp, sloppy pays for the missing kicker (F22 stays open).
  **Next:** Bill plays it (`--autostart=raid:caster:brew`), feel verdicts → creeds/modules/boons
  slices per ALCHEMIST-PLAN §6.3. **Feel-pass 1 (Bill, same day, merged `aa7e809`):** the twin
  poison bars now sit SHOULDER-TO-SHOULDER as one comparator block ("the bars should be next to
  each other so you can see them and balance them well") — beam directly beneath the pair, vial
  far left, chamber right w/ its own POTENCY footer. **Feel-pass 2 — SATURATION CUT (Bill, same
  day):** first flagged live (⚗ SAT toggle + sim A/B, merged `ed50476`), Bill's verdict "better
  off" → mechanic removed entirely (config/kit/gauge/policy/sim/codex). The HARD cap (12) is the
  only ceiling; full pours always land; `min(V,R)×balance` skill untouched. ⚠ Knock-on: the two
  cards built ON saturation are cut too — the **Reckless Brewer** creed and the **⭐ Still** module —
  so ~~the class OWES a new ⭐ transformer~~ **[OWE VOID 2026-07-09 — transformer requirement dropped,
  modules are add-ons; no replacement owed. See Coord Log.]** (ALCHEMIST-PLAN §3 lists candidates). Bands basically
  unchanged (sat barely bound); det PASS; default comp still byte-identical (alchemist not in it).
  *(alchemist-core session)*

- 📋 2026-07-07 · main (docs only) · §CLASSES — **FERMATA v5 VERDICTS IN + BUILD BRIEF READY —
  the EDGE build is CLAIMABLE.** Bill's pass on deck v5: everything KEEP except `feint` CUT
  ("no time or reason to veto") and `shadowstep` CUT ("one block card only" — Vanish is the one
  defense card; dodge-breaks-the-draw now bites unsoftened). Slate LOCKED (7 laws · 4 creeds ·
  2 modules · 13 boons · 3 rig WHENs · 3 keystones + carries). **`FERMATA-V5-BRIEF.md` written
  at repo root** — the self-contained execution brief for the implementing agent: the ramp/snap
  verb spec, per-card code status (coded ✓ / rework / new / verify — `firstBlood` is listed but
  likely unimplemented), file-by-file code map, sliced work order with the two byte-identical
  checksum gates (Tempo `4932869838389671587` · Venom `7876031242436484463`), verification
  matrix, gotchas. Next: an Opus agent claims the brief and builds in worktree `fermata-edge`.
  *(fermata v5 verdict session)*

- 📋 2026-07-07 · main (docs+skill) · §CLASSES / §TOOLING — **FERMATA EDGE VERB LOCKED + DECK v5 +
  THE DECK-CREATOR SKILL.** Bill's edge-bullseye idea A/B'd in the tester → verdict "edge is way
  better, this feels great": the verb is now **THE RAMP & THE SNAP** (damage ramps entry→lip,
  bullseye against the cliff, crossing it auto-SNAPS; wideners add entry runway only). **Code
  OWED** — the kit still grades centre; recode verb + v5 slate together after Bill's verdicts.
  Deck v5 shipped (artifact 3c01d3ed): Deep Edge + On-the-Edge WHEN cut (absorbed/obsoleted by
  the verb), Patient Knife = THE LONG RAMP, Shadow Dance = 3s NO-SNAP fever, NEW Cold Cut / The
  Brink / The Razor, four named archetypes, offer-trio audit clean. **NEW SKILL**
  `.claude/skills/deck-creator/SKILL.md` (per Bill: "make a deck creator skill") — the reusable
  slate playbook for every class: the pick-tension law, the fun hierarchy (greed > payoff >
  control > pacing > bread > insurance — never raw), the anti-pattern list from Bill's real cut
  history, quotas (one WILD creed · one ⭐transformer · elite-only spectacle keystones), coherence
  rules + the BROKE/FADED/DEAD/OPENED sweep, and the design→verdict→build process. Full spec =
  TEMPO-PLAN §13. *(fermata edge-lock session)*

- 📋 2026-07-07 · main (docs only) · §CLASSES — **FERMATA v4 DECK RE-AUDIT (design, at Bill's
  verdict).** After the HUD wiring + ROAMING WINDOW + THE DRAW passes landed, Bill flagged the
  structural cost: "you can no longer choose how long to charge the coil — rerun your ideas,
  better explanations, tags." Every card re-read under the Draw: hold-length greed had become
  roll-luck (Patient Knife → **OVERTIME tail** creed · Patient Edge → **DEEP EDGE** aim greed ·
  Unseen Blade → **Shades bank while RESTING**), sharpen-speed cards faded (Feint → **THE
  REROLL** — the direct "if it's close I can't pick" answer · First Pass was degenerate → **FIRST
  NOTE** rested-opener · Quiet Fuse reframed), rig Deep Coil dead → **THE RESTED DRAW**, plus 3
  NEW cards on the dials the Draw opened: **Composure** (no Flow decay after a Perfect+ release)
  · **Refrain** (a Bull holds the window in place) · **Stretto** (windows roll nearer). Verdict
  artifact rebuilt with WHAT/WHY/FEELS + greed/ease/speed/control tags + status chips (7 reworked
  · 3 new · rest STANDS with re-check notes): 3c01d3ed… Full spec = TEMPO-PLAN §13 V4 block.
  **Code holds the coded stopgaps until the verdicts land, then the reworks get recoded.**
  *(fermata v4 design session)*

- ☑ 2026-07-07 · `fermata` → main · §CLASSES — **FERMATA BUILT — Twinfang's second spec is real,
  deterministic, byte-identical when unpicked.** Bill: "yeah go ahead and build this fully." The
  hold-release aspect: Strike COILS (`coil`/`release` via `on_action`; release < the sharpen floor
  UNRAVELS — no strike, ~0.35s stagger, no Flow loss; the AI presses early + releases on the
  centre-aim, same latency gradient as Tempo split across two inputs). Shares Tempo's Flow/combo/
  Coup/Opening/crit via a new `_tempo_family()` gate. **Coded:** 4 creeds (Patient Knife / Fleeting
  Shade / Long Night / Tutti) · 2 modules (⭐Shadow Dance duration-gated bullet-time · The Mark
  brand→Evis cash) · 11 boons (COIL/VEIL/RELEASE + On the Beat on the Tempo side) · 3 keystones
  (Unseen Blade / Eclipse / Phantom) · 3 rig WHENs · fermata sim probe + `--blade=fermata` in
  raid_sim + the lobby entry (Twinfang = Tempo + Fermata; venom → AI-only legacy since poison is
  the Alchemist). **VERIFIED:** twinfang_sim base+fat fermata determinism PASS; @expert base =
  25.7 bullseyes/run (coil lands dead-centre = Tempo's ~22), @good smears to Perfect (identical
  gradient), 0 unravels from the clean AI; **Tempo `4932869838389671587` + Venom
  `7876031242436484463` checksums MATCH main byte-for-byte**; raid_sim `--blade=fermata` Mistral
  det PASS + 100% win/skill (distinct checksum + TTK from venom); ui_smoke_raid OK (only the
  pre-existing raid_frames/col_std errors). **SIM SIMPLIFICATIONS (flagged for the HUD pass):**
  Tutti's coiled-kick + Phantom's two-blade crossing + Veil-over-warband's ally application are
  feel/wiring the instant-dump sim can't express — modelled as grade-mult / flat twin / published
  flag respectively. **OWED (other layers):** HUD gauges (charge ring off-marker per Bill, shadow
  dim, Shade/Mark/Dance meters) · elite acquisition for the 3 keystones · online spec-carry. See
  [[tempo-second-spec-search]]. *(fermata build session)*

- 📋 2026-07-06 · main (docs only) · §CLASSES — **FERMATA: Twinfang's second spec — VERB LOCKED with
  Bill via feel-testers, full deck DESIGNED (TEMPO-PLAN §13 rewritten as the hard-copy ledger; NOT
  built).** The §13 hunt ran four candidates: MOTIF (aim-cuts→wounds→SEVER) rejected "no strategy,
  too similar to the warrior" · OSTINATO (engrave-runes engine-builder) rejected "novel but strategies
  aren't jumping out" · a rubber-band/pot/spring tri-tester rejected "too far from just the tempo
  variation — but I liked the hold" → **LOCKED: Tempo with a HOLD instead of a TAP** (strike on
  RELEASE; min-coil 0.35s kills the click-cheat; one-way sweep; charge ring + SHNK sharpen cue; base
  has NO hold-length bonus). Fantasy = WoW Subtlety steal (coil INTO shadow, strike from the dark),
  name FERMATA (the held musical note). Tester iterated live with Bill (slower sweep, min-coil,
  one-way, charge-ring visual, ⚙ tweak sliders): `scratchpad/fermata-tester.html` → artifact
  e920ea01… + local copy `~/fermata-tester.html` (claude.ai was down). Deck = 3 creeds (Patient
  Knife / Fleeting Shade / Long Night) · 2 modules (⭐SHADOW DANCE bullet-time transformer · THE MARK
  brand-and-cash) · 12 boons in 4 lanes keyed off the coil STATE (COIL/VEIL/RELEASE/AMBUSH, incl.
  Bill's auto-dodge as Vanish + support Veil Over the Warband) · 3 rig WHENs · 1 elite keystone
  (Unseen Blade). **NEXT:** Bill's deck verdict pass (interactive triage page shipped alongside) →
  build per §13.7 order (engine note: `perform()` needs a press/release action pair). *(fermata
  design session)*

- ☑ 2026-07-06 · main (docs only) · §CLASS FRAMEWORK v2 — **correction: the `tempo-boons` card slate
  was never blocked.** It merged to main 2026-07-05 (`fe4d109`/`8c845ca`; rig `d1515e7`; build-out
  `2277d15`) and is on origin — the ⚠ "UNCOMMITTED on Bill's other computer" note in the split entry
  below was a false alarm from a stale 07-05 doc line. TEMPO-PLAN warnings corrected (`e3ff865`);
  **card-level verdicts (F23/F27 etc.) are actionable on main now.** *(original tempo-boons session)*

- ☑ 2026-07-06 · `venom-split` → main · §CLASS FRAMEWORK v2/§CLASSES — **THE SPLIT (docs only):
  spec-audit verdicts triaged + Venom promoted to its own class.** Bill verdicted the full 36-item
  Twinfang spec audit (0 reject · 12 tweak · 24 accept; board artifact `168429ee…` — full finding
  bodies recovered from it). **Headline F10: the Brew leaves Twinfang** → `VENOM-PLAN.md` renamed
  **`ALCHEMIST-PLAN.md`** (working name THE ALCHEMIST — name/art filler until build; DPS seat; the
  in-code poison-wheel Venom stays the frozen placeholder aspect). Twinfang owes a **rhythm-variant
  second spec** (new TEMPO-PLAN §13, design owed). All verdicts folded: TEMPO-PLAN gains the ⚖
  audit block (Opening→baseline verb F1 · modules un-parked + ⭐Overdrive F6/I1 · Battle Hymn
  support F14/I2 · mobile-proof high-Flow F8/F11 · crit + Swan Song opens →§10) and supersede
  notes on the 2026-07-05 module-shelving; ALCHEMIST-PLAN gains its verdict block (F4 wave
  accepted · creed-aware offers law · I4/I5/I6/I9 boons in · F2 active-patience + F3 auto-evasion
  + rig vocab = 🟡 talk-with-Bill). CLAUDE.md index/roster updated. Zero code/sim files touched
  (`git diff --stat` = 4 .md). ⚠ Card-slate verdicts (F23/F27) blocked on `../wow-tempo-boons` —
  UNCOMMITTED on Bill's other computer, no remote branch; commit/push it there before card work.
  *(split session)*

- 📋 2026-07-06 · main (docs only) · §CLASS FRAMEWORK v2 — **CLASS DESIGN RULES locked with Bill.**
  Bill's asks: (a) asymmetric classes as a THEME — "not every class will have x abilities and x
  creeds… don't be afraid to make classes very unique"; (b) durable rules so class-making sessions
  remember them; (c) role-flex weighed — Bill's own realization mid-design: the "nobody wants to
  tank" motivation is VOID because AI raiders + Commander already solve it, so role CONVERSION via
  boons is rejected (pollution / comp-conditional sims) while off-role utility survives as capped
  spice ("may SAVE a fight, never RUN one" — the interrupt-carrier 2/1/0 idiom generalized);
  (d) mechanics density = GEOGRAPHY (zone rotation-showcase → dungeon → raid full-exam; kits must
  be fun BARE). Recorded as the 7-rule **⚖ CLASS DESIGN RULES** block in §CLASS FRAMEWORK v2
  (uniform interfaces/asymmetric content · one complexity budget · AI-pilotable-or-no-ship ·
  skill-moves-outcomes · hard roles/soft utility · fun-bare/geography · comp-variants parked).
  *(class-rules design session)*

- 📋 2026-07-06 · main (docs only) · §BOSSES — **`SEAL-PILLAR-PLAN.md` written (execution brief,
  NOT built — Bill is handing it to another agent).** Expands the §BOSSES SEAL PILLAR PASS block
  into a self-contained brief: current beat-source map with static estimates (Vorathek `volley`
  aoe×3@cd13 ≈ 9–12 beats/seat = the main offender · Mistral under budget · Gemini borderline via
  `bard_sonnet` · Mythos ~10–17 via `fanout`+`sonnet_tools`, ULTRATHINK exempt), **Phase A
  sim-side-only instrumentation** (per-seat budget table from existing `seat.diag` grades +
  telegraph-transition cast counts — zero engine files, gated byte-identical), **Phase B knobs**
  (cd-first levers, aoe→rand_target conversions, reverse-M7.2 compensation via melee/nova never
  more beats), band targets (curve preserved, Mythos sloppy ≤50), full verify gate + wrap-up
  protocol. The claiming agent should read THAT doc first. *(seal-pillar planning session)*

- ☑ 2026-07-06 · `fresh-slate` → main · CLAUDE.md/§CLASSES/§BOSSES/§TOOLING — **FRESH SLATE:
  CLAUDE.md rewritten lean + `HISTORY.md` + old sims DELETED + SEAL PILLAR PASS planned.** (Bill:
  "keep this fresh… remove old boss sims as well… only tempo and the 4 bosses simmed, so it doesn't
  waste time simming bad stuff.") (1) **CLAUDE.md** → stable laws + run-book only: era summary
  (one-HUD law · roster rework · Voidcaller cut · boss-redo era), the WORLD-PLAN combat pillars,
  ACTIVE VERIFICATION surface, distilled gotchas, plan-doc index; the frozen milestone history +
  PoC source notes moved WHOLE to **`HISTORY.md`**. (2) **Deleted** (git history is the attic):
  `bulwark_sim` · `mender_sim` · `voidcaller_sim` · `bloomweaver_sim` · `reckoner_sim` ·
  `sim_runner` (M0 relic) · dead-HUD smokes (`ui_smoke`, `ui_smoke_mender/twinfang/voidcaller/
  bloomweaver`) · frozen-kit probes (`bulwark_expose_probe`, `mender_overflow_probe`). **Kept:**
  `twinfang_sim` (Tempo pilot) + `raid_sim` (4 Seals) + ALL system probes (draft/gear/commander/
  map*/net*/raid*/menu/meter/fight_seed) + `ui_smoke_raid`/`ui_smoke_map` + `map_sim` (solo-map
  fossil kept as the shared-RunMap byte-identity instrument) + **all `sim/policies/`** (the raid's
  AI seats need them) + visual probes. `psim.sh` supported list → `twinfang_sim|raid_sim`; stale
  "class sims" acceptance lines amended in §CLASSES/§BOSSES/§HOW-TO-WORK. (3) **SEAL PILLAR PASS
  v1 planned** (§BOSSES, claimable): instrument per-seat beat budgets in `raid_sim` FIRST → retune
  the 4 Seals toward the dodge-ration pillar (~3–8 non-tank beats; ULTRATHINK stays whole; reverse-
  M7.2 warning: removing beats softens — retune cadence back), kick chains untouched until
  interrupt-by-ability lands, deliberate band re-baseline. **Verified post-deletion:** fresh
  `--import` + `twinfang_sim` + `raid_sim` + `ui_smoke_raid` green in the worktree. *(fresh-slate session)*

- 📋 2026-07-06 · main (docs only) · §THE WORLD — **THE WORLD pivot: design LOCKED with Bill, `WORLD-PLAN.md` written (NOT built).**
  Bill's pitch: a WoW-like persistent world (Westfall-style zones, fog, first-visit fight-through with
  branching routes, world-boss events anyone nearby can join, repeatable dungeon at the zone edge,
  flight paths, hometown) wrapping the roguelike instances — "the world is kinda the menu." Worked
  through with Bill and locked: **one game reaffirmed** (the solo/MMO two-game split weighed again,
  DECLINED — AI warband + Commander IS the solo mode) · **zones = persistent conquest** (no drafts;
  the permanence/variance line = world/instance) · **overworld power = bare kit + persistent unlocks**
  · **WARBAND LAW** (every fight tuned for exactly 4 seats; AI backfill ⇒ NO 1-to-x enemy-scaling
  system) · **mid-fight join PARKED** (v1 events = open lobby pre-pull; seat-claim + replay-catchup
  sketch preserved in the plan) · **COMBAT PILLARS**: single-target law · dodge RATIONED (universal
  dodge stays, ~3–8 authored beats/fight for non-tanks) · **interrupt-by-ability** (Bill's design —
  no kick button/class; flagged existing abilities [ideally dumps = the interrupt tax] kick inside a
  TIGHT window; accidental-vs-deliberate kick rates become sim diagnostics; distribution across
  classes = comp texture; Voidcaller cut from the roster plan, stays as frozen caster placeholder).
  New tool specced: the **ENCOUNTER FORGE** (seeded skirmish generator + `forge_sim` certification —
  the determinism dividend: batch-verified procedural difficulty). Phases **W0–W5** (W1 = Atlas +
  Zone 1 offline, claimable; W3 = front-door flip to PLAY→ATLAS; W4 = presence + world events).
  MASTER-PLAN updated (Overall Progress row · §THE WORLD section · GAME SHAPE front-door amendment).
  **NEXT:** W0 companion = CLAUDE.md fresh-slate cleanup (history → HISTORY.md) — separate claim;
  then W1. *(world design session)*

- ☑ 2026-07-05 · `curio-content` → main (`77ebc85`, ff) · §SYSTEMS GEAR — **CURIO CONTENT PASS v1 — the equip refocus, MERGED.** Curios = UNIVERSAL cross-spec fortune/run-shapers, always-on rule-changes ONLY (never touch a verb, no one-shots, no per-floor budgets — the lane rule Bill locked). **CUT the 10 verb-welded/class offenders** from `gear_catalog.gd` ITEMS+TABLES (verify_stamp · powder_vial · spark_plug · salt_vial · grace_period · sticky_note · debt_collector · encore_bell · echo_chamber · overflow_sluice); their gear-gated kit code is dead-but-harmless (never rolls → never fires). **SHIPPED 3 working universal curios**, all wired this slice: **Expansion Bus** (boon draft 1-of-4 not 1-of-3 — `Draft.roll_offers(run, extra)`, default 0 = byte-identical rng), **Hashgrinder Rig** (all Token income ×2 — routed through the `_gain_tokens` chokepoint + mint), **Hot Reload** (rerolls are FREE — `Draft.reroll(_kept)(…, free)` + `DraftScreen.free_reroll`, human-seat gated). New TABLES unlock them off UNIVERSAL deeds (curses/zero_deaths/no_dips). **Panopticon (map reveal) dropped** — the raid map already draws every node, no fog to lift; parked until a fog system exists. **Verified:** draft_sim ALL OK (rng stream unchanged), ui_smoke_raid ALL OK, gear_probe green (its 3 opus-roll tests — which leaned on the removed echo_chamber(opus) fixture — reframed onto pure `rarity_weights`/pity math + a live clamp assertion; the interim pool has NO opus curio yet, noted for restore; retired the stale twinfang Flow+grace sub-test, red at baseline from the Tempo rework). **NEXT (the "build the rest later" bucket):** opus-tier curios; the rest of GEAR-CATALOG's ~18 v2 pool (Root Access needs Module-pick UI · Bootleg 3rd slot needs variable slots · set-bonuses need a set system · map-routing curios need §MAPS work); the MARKET economy (buy curios from the unlocked pool + banked reroll charges, primary path per CURIO ECONOMY v2). *(curio content session)*
- 📋 2026-07-04 · main (docs only) · §MODES & ENDGAME + §SYSTEMS E.5 — **ENDGAME = infinite raid DEPTH + oath-dedication curation (design captured with Bill, NOT built).** Bill's pitch: "make the endgame cool — raid scales infinitely like Mythic+, keep your gear between runs so you can be a little broken, and higher tiers drop better." Worked through it: (1) two-thirds already designed — **Versions** (per-boss authored mechanic-adds) + **raid DEPTH** (unbounded scalar) = the RANK track's "Mythic+"; "richer drops at higher tier" is already the drop spec. Added the design refinement: **scaling = cheap numeric spine (HP/dmg/enrage) + affix TIERS at Depth breakpoints**, and because combat is *timing* the affixes COMPRESS WINDOWS / add beats (reusing the strings/feints/interrupt/add engine), so gear never papers over a window you can't hit. (2) **"Keep your gear / be a little broken" = a persistent-power treadmill → weighed and DECLINED with Bill, Law #1 reaffirmed** (breaks the co-op scaling contract; makes sims gear-conditional). Reconciled: **Depth scales CURATION CAPACITY, not hitting power**; the broken-build fantasy stays run-scoped + re-earned. (3) **Drop-curation lever = OATH DEDICATION only** (Bill's call — no attune/fine-tune toggle, no meta-currency): swear an oath on **yourself or a teammate**; KEPT bends that seat's drop roll (rarity/consistency, not the item). **Locked knobs:** swearer keeps Tokens / gifts the luck; beneficiary swear-time locked; Realm-1 skin = cross-team SLA. Buildable as a small GEAR-2 extension (`beneficiary_seat_i`, byte-identical when self). No code touched. **NEXT:** Bill is running core concepts with another agent in parallel; this stays design-only until claimed. *(endgame design session)*

- 📋 2026-07-04 · main (docs only) · §CLASSES — **`TEMPO-PLAN.md` written (design phase, NOT built).** Deep
  redesign of Twinfang·Tempo into a risk/reward "greed dial" + a class-FRAMEWORK meant to generalize (Tempo is
  the pilot). LOCKED with Bill: **Creeds** (miss-penalty temperament — Flourish/Drumline/Held Breath [Bloodwaltz
  cut]; draft 1-of-3 random @ run start from a per-class unlocked pool; event-node swap for a wound/Token
  penalty) · **Modules** (Hades-weapon UI addons, each adds a HUD gauge — Opening[built]/Edge/Deathmark/
  Metronome/Hemorrhage; pick **1** at END of Floor 1, NOT 2, NOT at start) · **triggers OFF the auto-attack**
  (remove the innate "every Perfect Strike" proc → payloads fire only on earned moments, bigger per proc) ·
  **combo-gen fix** (Perfect +1 not +2, drop Tier-2 combo → a wind-up you spend) · **WHEN/THEN/ALWAYS** rename +
  a visual "combo board" for legibility · **rarity = build-definingness** (Model A, numbers scale to trigger
  frequency, Monotonic-Pool-safe) · **per-class levels = unlock count, overall = sum** (the PROGRESSION-PLAN
  Rank track made visible; reconciled, no new grind currency). Full spec in `TEMPO-PLAN.md`; see [[tempo-redesign]]
  memory. FUTURE (parked): titles · cosmetic transmog · social lobbies. **NEXT:** lock the open content picks
  (§10) → build the RISK CORE + 2 Creeds + combo-fix first (§11). Bill is fine-tuning the trigger/effect menu.
  *(tempo-design session)*

- ☑ 2026-07-04 · `reckoner-online` · §CLASSES/§ONLINE/§MAPS — **THE RECKONER — ONLINE + personal GATE — DONE, MERGED to main.** Finishes the Reckoner's full integration (offline class + FORGE UI already merged). (1) **Online:** the blade seat is now a lobby CLASS toggle (Twinfang ⇄ Reckoner), mirroring the healer's — `net_server._class` accepts a blade class msg, `_valid_aspects` returns colossus/berserker when `cls == reckoner`, and `raid_hud`'s lobby shows the ◈ TWINFANG/RECKONER button. NetProtocol **v11→v12** (KILL SWITCH also took v11 concurrently; merged to v12). The netcode spec already threads per-seat `cls` generically (Commander/bloom-raid plumbing), so RaidNet `build`→ReckonerKit + `make_policy`→ReckonerPolicy (AI takeover) ride the wire unchanged. (2) **Personal GATE:** `GateContent.make_state`'s blade branch forks on `cls == reckoner` → the Reckoner's own solo boss (the **Sentinel**) recast to the FIREWALL identity (mirrors the Mender/Bloomweaver gate split); the stage puppet stays the placeholder rig. Works offline (map GATE node) and online. **Verified:** `net_smoke` ALL OK with a HUMAN reckoner blade + bloomweaver healer online — both replicas build ReckonerKit/BloomweaverKit and agree on IDENTICAL checksums, AI takeover clean; `ui_smoke_raid` ALL OK (new `gate exam blade/RECKONER` = ReckonerKit vs Sentinel/FIREWALL, healer gate kept last so the juice test holds); **byte-identical default comp** (all changes guarded by `cls == reckoner` / `seat == blade`; offline sims unaffected). ⚠ **Protocol v12: rebuild + redeploy the server with clients** (v11 rejected at handshake). **NEXT (unclaimed):** the deferred cosmetics (reckoner stage2d puppet, rune icons, audio); a commander-selectable reckoner AI blade; the 5 upgrade branches. See [[reckoner-warrior-proposal]].

- ☑ 2026-07-04 · `killswitch` · §MAPS + §BOSSES — **THE KILL SWITCH P1 (node-variety + retire integrity) —
  MERGED (Bill: boring one-click nodes; integrity doesn't work — a healer tops HP off; a shared 'big
  charge-up move' you feed/empty in events; non-dominated choices; bad-luck variety).** Retired INTEGRITY
  (fights boot full-HP minus wounds; wounds the sole HP stake; Cooling stops laundering). ⏻ CHARGE — a
  party-shared 0-100 meter carrying the descent, fed by nodes, cashed at a Seal via the OVERCLOCK arming
  dial (SURGE/SHIELD, linear) — offline AND online (protocol v11, server-authoritative). `core/raid_marks.gd`
  the shared fight-mark applier. 5 new non-dominated charge events (mercy_terminal fixes Bill's +2-vs-+1).
  ⚠ **KEPT MANA** — the concurrent resource-tax pass (cf29902) made it bite, so retiring it was reversed.
  Gates: solo map_sim byte-identical · map_charge_probe/map_mark_probe ALL PASS · net_smoke/net_map_smoke
  (arming fires, zero desyncs) · raid_sim + bulwark determinism unchanged · WSLg arming dial clean. Design:
  the `kill-switch` artifact. **P2 MERGED:** 6 parked events re-priced (heal→charge/hurt→wound) → 14-event pool; party_out_mult DMG-amp + enrage_offset STALL (two default-safe CombatState fields, bulwark checksum unchanged) + STALL arming option + throughput_altar. **OPEN:** ⚠ charge-economy TUNING (walker sloppy 40→96% — feed/payoff too generous, needs a probe) · two-way Forge/sacrifice-gear (needs a gear-picker) · P3 (live PULL THE PLUG + finale retune).

- ☑ 2026-07-04 · `topo-bloom-raid` · §CLASSES/§GRAPHICS — **SEEDFALL wired into THE game HUD + balanced as a RAID seat — MERGED (`0a3a70e`, merge `dfbc72f`).** (Bill: "why is this on solo? everything should be on the raid only — swap to raid mode … adapt to the updated healer UI.") Corrects the earlier Seedfall pass, which had wired the DEAD solo `bloomweaver_hud` (ONE-HUD-LAW slip). Kit/config/boons/policy/binds/gauge were already shared + correct; this brings the *input + display* onto `raid_hud`'s Bloomweaver band + the raid-frame MEGA-upgrade chips.
  - **raid_hud band:** KEY_4 = BLOOM (cash a bed) · KEY_5 = Thornlash (was 4 = lash); `_cast_on_bloom` gates Bloom on a bed-present + over-cap on Verdance; the Verdance gauge reads TOTAL PARTY SEEDS + Flourish tiers (ripen fields dropped); Wildgrove class blurb reworded to stacking. **raid_frame:** the seed bed renders as a growth chip with a **×N stack-depth badge** + a **gold COOK glow** at full ramp (reuses the frame's `ripe` gold path). Bloom rune auto-appears (loadout `order()` includes it); right-click Bloom chord ships via BloomweaverBinds. View-only — no engine/kit change; diff = raid_hud + raid_frame only → all sims byte-identical.
  - **RAID balance (Bill: raid-only; `raid_sim --healer=bloomweaver`, 100 seeds, det PASS both aspects):** expert **100 on all four bosses**; good 100/100/94/**59**, sloppy (wild) 63/100/54/**5** · (thorn) 99/100/58/**8**. Riftmaw/Mistral comfortable, Gemini a mid-check, **Mythos the brutal finale** (good ~59, sloppy ~5-8, almost all `healer_death`). PRE-EXISTING + flavor-consistent — the old one-seed kit was already `mythos wild 100/60/14`; Seedfall held the good tier (60→59), sloppy dropped (the ramp punishes thrash-replanting, by design). NOT globally buffed (would trivialize the other 3 fights + solo).
  - **Gate:** ui_smoke_raid ALL OK on fully-merged main (Seedfall + reckoner + openings + commander) · raid determinism PASS (4 bosses) · net_smoke ALL OK · view-only diff → 6 solo sims + raid byte-identical. Solo `bloomweaver_sim` is now a LEGACY kit harness (the raid seat is the balance source of truth).
  - **NEXT (unclaimed):** the **Mythos-finale proactive-healer gap** (good 59 / sloppy 5) is the standing balance follow-up — needs Bill's steer (deeper Bloomweaver self-triage AI over the long finale, or a proactive-healer-friendly finale tweak; do NOT fix with a shared-content nerf that also hits the Mender). Also: the dead solo `bloomweaver_hud` still carries vestigial Seedfall edits (harmless — leave for the dead-HUD cleanup sweep) · Constrict boon branch · AI over-cap probe.
- ☑ 2026-07-04 · `reckoner` · §CLASSES — **THE RECKONER (Warrior, 6th playable class) — DONE, MERGED to main.** The blade/melee-DPS seat is now a CLASS CHOICE (Twinfang ⇄ Reckoner), mirroring the `bloom-raid` `cls`-threading (default `twinfang` → byte-identical). Verb **COMMIT**: an auto-advancing swing shaped by TWO tick-stamped presses — WIND (weight: Quick/Even/Heavy/Over) × STRIKE (apex power: Finesse / True ±1t / Overload) — degrade-never-whiff; abilities **Overswing** (wind-end haymaker) / **Ultraswing** (inserted bonus beat) / **Onslaught** (VENT 3-wind+3-strike phrase); resources Rage / Momentum / Poise-Break→STAGGER; **Clash** (apex onto a boss impact tick). Aspects **Colossus** (punishing/stagger) / **Berserker** (forgiving; Momentum snowball + hyperarmor). Ported from a tuned browser greybox (True band ±1t).
  - **Engine/class (ZERO CombatCore change — snaps onto ClassKit hooks + seat.vars; only view-only `wind_commit` event added):** `data/reckoner/{config,kit,boons,content}.gd` + `sim/policies/reckoner_policy.gd` + `sim/reckoner_sim.gd` + `sim/raid_reckoner_probe.gd`; cls-wiring in `raid_net` (cls_of/make_policy/default_aspect) + `raid_content` (_reckoner/_blade_seat/make_state) + `run_state.start_reckoner` + `psim.sh`.
  - **HUD (the one game HUD):** `_blade_cls` plumbing (mirrors `_healer_cls`) — 6th class card, aspect ceremony, `_build_band_reckoner`/`_render_band_reckoner`, `_reckoner_key` (SPACE = phase-aware wind/strike swing · F dodge · 1-4 abilities). **"THE FORGE" instrument** (`game/ui/reckoner_gauge.gd`, from a UI-spec workflow): a big linear WIND bellows bar (zones + EVEN money-core + fixed aim gate + sweeping hammer-notch) above a radial contracting ANVIL ring (constant close onto an emerald TRUE hub + NOW), Momentum pips + Poise meter, scale-punched verdict banner + paired grade-history gems; event-driven verdict/juice (`on_event` + `_reckoner_juice`: TRUE!/OVERSWING!/CLASH!/STAGGER!/ULTRA!/ONSLAUGHT! + free grade-colored damage floats).
  - **Verified:** reckoner_sim determinism PASS (both aspects); bands **Colossus 100/95/82 · 100/85/55**, **Berserker 100/100/92 · 100/100/75** (the timing gate drives it, avg Momentum 7→1); raid_reckoner_probe ALL OK (Reckoner blade WINS riftmaw/mistral/mythos, metered, spec routes cls→kit+ReckonerPolicy); **byte-identical default comp** (raid_sim + twinfang_sim checksums identical). Merged `main` (Commander / THE OPENING / Seedfall) cleanly — `_make_run` folded into Commander's `_make_seat_run` (+ reckoner case), `_sync_blade_cls` kept alongside the party fns.
  - **NEXT (unclaimed):** reckoner stage2d PUPPET (reuses twinfang rig), rune ICON art, AUDIO cues, online net_server lobby toggle + personal GATE fork (gate_content), class_codex entry; make reckoner a COMMANDER-selectable AI blade class (party toggle); the 5 UPGRADE BRANCHES (Buffer Overflow / Batch / Overclock / Force Quit / Race Condition). Debug: `--autostart=reckoner:colossus|berserker`. Sim: `scripts/psim.sh reckoner_sim 300`. See [[reckoner-warrior-proposal]].


- ☑ 2026-07-04 · `openings-poc` · §CLASSES/§GRAPHICS — **THE OPENING — a new offense-side timing verb — MERGED to main (fast-forward).**
  (Bill: "our verbs are too centered around the tank/dodging stuff… meh for dps and heals, lets try new verbs
  more general and fun" → picked ① THE OPENING → "a vulnerable hit timing bar, hit your evis and venoms right
  when/around/after they hit" → "much prettier and fancy" + "add it to the raid mode, always on raid, for all
  twinfang raid fights".) Inverts the telegraph from DANGER→OPPORTUNITY: a boss swing OVEREXTENDS it, opening a
  vulnerability window around the impact tick; the blade's DUMPS (Eviscerate/Coup/Rupture/Flurry) landed in the
  sweet spot (just after impact) hit ×1.90 at the peak, tapering to ×1.05 at the edges, nothing outside. The
  offense-side inverse of dodge/riposte — you don't answer the swing, you punish the recovery. **Kit-local, ZERO
  engine change:** `twinfang_config` open_* tuning + master `open_enabled`; `twinfang_kit` `_stamp_opening`
  (upkeep watches `s.telegraph`, schedules the window in `seat.vars`, deterministic) + graded `_opening_bonus`
  in `_deal` + `_opening_note` aspect kicker (Tempo +Flow / Venom +poison on a PEAK) + `observe()` open_*/open_on;
  `twinfang_policy` dump PATIENCE (bank a ready dump for the window, skill-scaled aim via the per-policy DetRng;
  classic path when open_on=false → byte-identical). **Live in the raid** (`raid_content`/`gate_content`
  open_enabled on — the boss's swings at the tank open the blade's window) with the OpeningBar wired into
  `raid_hud`'s blade band (the one HUD). **Fancy `opening_bar.gd`** — Gilded Reliquary: gold frame + filigree,
  engraved plaque, a molten crimson→ember WOUND that breathes, a sweet-spot that IGNITES, a sweeping plumb needle
  with a motion trail + boundary gems, and a spark-burst PUNISH. Rewards Tempo (timing aspect) strongly, Venom
  (forgiving DoT) lightly — sharpens the aspect contrast. **Verified:** twinfang open=off byte-identical to main
  (720 rows); other 4 class sims byte-identical (determinism PASS, matching checksums); raid determinism PASS
  (4 Seals); **Gemini A/B 150 seeds — openings SPED kills (expert 70.1→61.6s) and NUDGED sloppy UP 60.7→65.3**
  (faster kill = less healer exposure) → balance-neutral-to-positive, no retune; ui_smoke_raid + ui_smoke_twinfang
  PASS; WSLg render clean (blade leads the damage meter). **Merge hygiene:** checkpointed Bill's finished-but-
  uncommitted working-tree UI polish first (`d254441` — rhythm-bar bounded-green fix + gauge_gallery + class_codex
  Bloomweaver page + raid_hud `_seat_cls_now`), so the branch built on the latest (raid_hud 3-way auto-merged).
  Debug: `godot --path godot game/twinfang_main.tscn -- --autostart=tempo:executioner` (solo) or PLAY→blade→Seal
  (raid). Probe: `sim/screenshot_opening.gd`. See [[openings-verb]]. **NEXT (parked):** window-cadence tune if the
  raid wants more openings; roll the verb out to Voidcaller (punish casts) + the wider roster; other parked verbs
  (Overclock/Vent, Charge&Release for healers).

- ☑ 2026-07-04 · `commander` · §SYSTEMS/§CLASSES — **COMMANDER v1 — you build the WHOLE party — MERGED to main.**
  (Bill, direct: "when you play single player with the AI, you pick their upgrades and their setups as well —
  it's just the auto rotation during the fight that the AI does." The team-comp resist layer was split off
  mid-session per Bill's steer — "another subject, focus the ai pick 1st"; see the parking lot.) The solo raid
  is now a commander game, ZERO engine files touched (everything rides the netcode spec plumbing that already
  carried per-seat aspects/cls/boons):
  - **PARTY SETUP screen** ("ASSEMBLE YOUR RAID", `raid_hud._show_party_setup`) between the realm card and the
    descent: each AI seat = ASPECT ⇄ toggle + the healer seat's class toggle (Mender ⇄ Bloomweaver), aspect
    blurb per row, your seat pinned gold. `_party {seat -> {cls, aspect}}` persists across descents in-session;
    defaults = the verified comp. `_party_seat_cfg()` emits the full 4-seat spec cfg — at defaults it is
    IDENTICAL to what `make_spec` fills for missing keys, so untouched = byte-identical by construction
    (probe-proven). Commanded aspects also ride single-Seal `_launch` pulls.
  - **You draft the AI raiders' boons:** `_ai_runs {seat -> RunState}` (draft streams decorrelated off the
    human's `run_seed`); the post-fight REFORGE now CHAINS one DraftScreen per seat — yours first, then each
    AI ally ("REFORGE — THE TWINFANG · AI ALLY / you command the build — the AI only drives the rotation") —
    all spending the ONE shared ⏣ bank (mirrored into the AI run per screen, remainder banked back; rerolls/
    locks/upsells work there too). All seats' boons ride the spec via `make_spec(..., seat_boons)` →
    `RaidNet.build` folds each into its kit; boon procs are kit-side so AI policies need zero changes.
    Online untouched (`_ai_runs` stays empty online; commander-online = a lobby-UI follow-up).
  - **Gate PASS:** NEW `sim/commander_probe.gd` 14 checks ALL OK (default-cfg spec byte-identity · commanded
    aspects/classes/boons land in the right kits · commanded fight deterministic over 600 ticks · draft chain
    = you + 3 AI, one boon each, shared bank intact) · **all six sims byte-identical** vs the frozen-main
    baseline (100 seeds via psim, logs AND per-seed CSVs: raid + 5 classes) · menu_probe / raid_boon_probe /
    map_advance_probe extended + green · ui_smoke_raid gained a commander section (party toggles, commanded
    descent, 4-draft chain) + net_smoke + ui_smoke_map ALL OK · NEW `sim/screenshot_commander.gd` WSLg probe
    (party default/commanded + AI draft screen) eyeballed clean at 1080p.
  - **NEXT (unclaimed):** ONLINE commander (host configures the AI seats in the lobby — the spec already
    carries it) · draft-pacing lever if 4 drafts/fight drags in playtest (AI drafts only at Seal/gate kills,
    or an AUTO-pick button per ally) · AI builds surfaced on the map (armor doll / build panel are human-only
    today) · `Draft.mint` could count the AI seats' fight performance into the shared bank. *(commander session)*
- ☑ 2026-07-04 · `topo-bloom-seedfall` · §CLASSES — **BLOOMWEAVER REWORK "SEEDFALL": stacking + ramping seeds — MERGED to main (`b6e0346`, merge `8b3f5a5`).** (Bill: "the 'maturing' [ripen] thing is only meh… be able to STACK seeds… the HoT scales, resets when you stack — stack fast then let it cook.") Replaces the disliked RIPEN/harvest-window with a STACKING, RAMPING garden. Design via 24-agent workflow → artifact https://claude.ai/code/artifact/ecf1462b-6471-4d15-846c-21df88179414 ; Bill picked all 4 recommended forks (core-only scope / dedicated Bloom key + double-tap alias / full ramp reset / Constrict as a future boon branch). See [[bloomweaver-seedfall-rework]].
  - **Mechanic (ZERO CombatCore change — rides `seat.hots` [already a stacking Array] + `kit.upkeep` running the tick BEFORE `_apply_seat_effects`):** Growth STACKS a seed onto an ally's BED (soft cap 3 / grove 4, hard cap 5). One SHARED ramp per bed: a fresh/reset bed ticks at `ramp_floor` (0.35 / grove 0.40) and climbs to full over `ramp_time` 4.5s; ANY new seed RESETS it (`ramp_reset_frac` 0 = full reset, exposed as a sim knob). upkeep rewrites each bed's `tick = seed_base(8.5)·ramp·stacks` every frame → the engine fires the ramped value that same tick. Stack FAST, then hands-off to COOK.
  - **Cash-out:** dedicated **BLOOM** rune (key 4; Thornlash → 5) cashes fires-left × ramped tick × `bloom_eff` 0.9 (Clean Harvest boon → lossless ×1.15 for 15 Verdance). Growth on a HARD-capped bed ALIASES to Bloom (the double-tap gesture Bill kept). Lifesurge mass-blooms. Overgrowth/Sap Rot refresh WITHOUT resetting the ramp (topping a cooked field doesn't knock it down).
  - **Overcap / shields / Verdance:** 4th–5th seed spends 15 Verdance (refused if short — never silently drains). **Barkskin** sized by seeds under it (+15%/seed grove, +24% thornveil, cap +120%); **Perfect Ward COOKS the bed** to full ramp atop its Sap/Verdance refund. Verdance still = the efficiency gauge (earned only from effective heals + absorbs; overheal/wilt earn 0 → greedy over-stacking self-punishes, which makes uncapped stacking safe).
  - **Aspects:** Wildgrove FLOURISH relit on TOTAL PARTY SEEDS (Σ stacks ≥6 → +25%, ≥10 → +40%; ripen deleted), soft cap 4, floor 0.40, Wildbloom COOKS the whole garden. Thornveil = seeds-as-armor (reflect scales with streak × seeds, Briarheart seed-fattened, snap-streak kept). **Constrict support branch DEFERRED** (ships as a boon branch when Bill wants it — a `ConstrictAllyKit` reading the coil via the `dps_factor` sentinel, zero-engine solo).
  - **Boons reworked (all `_b()`-gated):** +Ironbark Roots (shield/seed) · Bountiful Bed (soft cap +1) · Clean Harvest (lossless Bloom for Verdance) · Thornbomb (Bloom rakes boss ×seeds); Deep Roots/Quickbloom/Quickening/Evergreen retuned to seeds; slot-verb Garden system kept.
  - **GATE PASS:** other 5 classes **BYTE-IDENTICAL** (bulwark/mender/twinfang/voidcaller checksums matched frozen-main baseline exactly) · determinism PASS (both aspects + all 4 raid bosses) · **net_smoke ALL OK** (replica agreement + AI takeover) · ui_smoke_bloomweaver green. Diff = bloomweaver-only + its VerdanceGauge (kept vestigial `flourish_ripe`/`ripe_garden` fields so raid_hud's setters don't error). Bands (300 seeds, merged tree @ `sap_regen` 9): teachers 100 flat; Hollowking **wildgrove 93/77/59 · thornveil 91/83/83** — steeper skill gradient than the old 99/94/76 (the "stack fast" discipline bites the sloppy tier); Thornveil the forgiving aspect.
  - **Concurrent-merge reconciliation:** the `resource-tax` pass (`cf29902`) landed on main mid-work and had cut Bloomweaver `sap_regen` 12→9 ("planting is a Sap budget"). The merge combined cleanly (my config rewrite kept that line byte-identical to base, so git applied their 9.0 on top of my new seed fields); **9.0 is HONORED** (it sharpens Seedfall's stack-fast Sap budget — thematically aligned), `seed_base` 8.5 held, and the bands above were RE-CONFIRMED on the merged tree (`git diff e3a56e5 HEAD` = bloomweaver + gauge + plan ONLY → other 5 classes provably byte-identical to current main).
  - **NEXT:** ☑ raid-seat Bloomweaver `raid_hud` wiring — DONE in `topo-bloom-raid` (see the entry above). Remaining: the AI rarely over-caps (human-facing tool; a probe could exercise it) · **Constrict** boon branch when wanted · bespoke raid stage rig · a human WSLg pixel-glance of the new seed ×N chips / cook glow / gauge · the Mythos-finale proactive-healer gap (see `topo-bloom-raid`).
- ☑ 2026-07-03 · `topology-checks` · §MAPS — **THE INFERENCE CHECK — deep events + build-read dice +
  ⚡Entropy/📁Prior luck meta — MERGED to main (Bill: "the map is a joke, just +integrity jokes; we
  need deep decisions, side stuff like better luck next time, more than yes/no, an AtO-style dice
  system adapted to us").** Phases P0 (unified MapFx applier, byte-identical) → P1 (MapCheck pure
  resolver + 3 enriched raid events + breakdown panel, offline) → P2 (⚡ nudge stepper) + P4 (📁 Prior
  persistence) → **P5 ONLINE PARITY + SEAT-PICKER** → **P3 MULTI-STAGE BRANCHES + cross-node FLAGS +
  14 events (protocol v8 — server traverses stages)**. Design dossier = the `inference-check` artifact;
  5 forks locked (solo shallow · ENTROPY · soft fails · party-picks-seat · post-fail mulligan). Gates:
  NEW `map_check_sim`/`map_event_probe`/`map_check_online_probe`(+seat-picker)/`map_branch_probe`(+online
  glue) ALL PASS; solo `map_sim` byte-identical; `raid_map_sim` re-baselined (pool 14, walker resolves
  checks, curve intact); `net_smoke`(v8)/`net_map_smoke`(2 online checks, zero desyncs)/ui smokes green;
  WSLg `screenshot_event`+`screenshot_seatpick`+`screenshot_branch` clean. ⚠ **v8: rebuild+redeploy the
  server with clients.** **OPEN follow-ups (unclaimed):** P2-rest (mulligan/cushion/wager) · online Prior
  (client transmits its tier) · P6 fight-altering marks. See §MAPS · THE INFERENCE CHECK.

- ☑ 2026-07-03 · `healer-frames` · §GRAPHICS — **RAID-FRAME MEGA UPGRADE — MERGED to main
  (`353626d`) (Bill: bigger/awesome healer frames; shield bigger + clearly visible without
  burying the dodge reads, or movable; HoT countdown timers; real icons; sleek).** `RaidFrame` v2
  (view-only) with SIZE VARIANTS — classic 164×92 stays byte-for-layout for the frozen solo HUDs;
  the game HUD uses **raid 240×102** (martial seats) and **XL 312×120 triage cards** (healer's
  4-seat raid; the 5-frame gate sandbox auto-falls back to compact so the column clears the mana
  orb). What's new on the card: (1) **SHIELD CREST** — a gilded heater shield in a dedicated
  right gutter showing the absorb VALUE + a ward-expiry countdown ring (+seconds on XL); blooms
  when a ward lands, ring-shockwaves when it eats a hit, crimson-pulses near expiry, ghost socket
  when empty — plus a woven-gold absorb EXTENSION appended past the HP fill (overshield chevrons
  when it clips). (2) **Incoming damage** is now a hazard-striped slice right-anchored on
  fill+shield (the true eat order — shield first), so shields never bury the dodge read; lethal =
  pulsing bar edge + "!" wedge. (3) **HoT icon chips** (real RuneIcons: renew/flash/mend/
  laststand/growth) with countdown sweeps + seconds (XL), ripe-Growth gold halo kept. (4) Debuff
  wax seal gains a countdown ring + timer. (5) Role spine, live %, hp/max, gilded YOU name.
  (6) **The raid panel is MOVABLE**: drag the ≡ header (clamped on-screen, persisted per-layout
  to `user://rift_ui.cfg`), double-click resets. HUD feed: absorb/ward/HoT/debuff remains off
  live seats (`HOT_META` icon+duration table). **Gate PASS:** ui_smoke_raid (extended with a
  drag/persist/reset assert) + mender/bloomweaver/map/net smokes ALL OK (net: zero desyncs);
  NEW `sim/screenshot_healer_frames.gd` WSLg probe (force-stages wards/HoTs/DoT/bloodied so
  every element is in frame) eyeballed at 1080p ×3 seats. Zero engine files touched. **NEXT
  (unclaimed):** frame hover tooltip naming each HoT/ward with exact numbers; dispel CLICK
  directly on the debuff seal; per-boss debuff icons. *(healer-frames session)*

- ☑ 2026-07-03 · `armory-ui` · §GRAPHICS GEAR — **ARMOR SET pro GUI — MERGED to main (`7b78912`)
  (Bill: "modal, hover with stats, see current gear while choosing").** (1) **Rich hover cards**
  on every doll socket via `_make_custom_tooltip` — slot header + every piece's effect line
  (rarity-colored); trinkets show effect/flavor/charges/scrap; hover ring lift; and UiKit's theme
  gained a gilded **TooltipPanel/TooltipLabel** chip, upgrading EVERY tooltip in the game.
  (2) **YOUR SET modal** (`game/ui/armor_modal.gd`): click any doll socket (map + REFORGE
  screens) → dim + GlassPanel — the doll (hovers live inside), scrollable per-slot piece
  breakdown w/ effect lines, equipped trinket RelicCards (`◆ EQUIPPED · ×N ◆` ribbon) or EMPTY
  SOCKET wells, ⏣ tokens + class crest; Esc/click-outside/✕ close — `raid_hud._input` routes Esc
  while it lives (mirrors `_pause`; never falls through to quit-to-menu). (3) **Drop-ceremony
  comparison**: the offered curio (`◆ NEW ◆`) stands beside your equipped trinket cards / FREE
  SOCKET wells, top-aligned — REPLACE decisions made with current gear in view. `RelicCard`
  gained `ribbon_text` (static display ribbon). Verified: ui_smoke_raid extended (modal
  open/Esc-close, comparison cards present) + all 7 smokes green; `screenshot_armory` gained
  drop_compare/set_modal steps, GUI-eyeballed (fixed a charges-vs-ribbon collision + caption
  stagger this way). View-only — no engine/sim surface. *(armory session)*

- ☑ 2026-07-03 · `armory` · §SYSTEMS GEAR — **Drop cadence + signature strength + ARMOR SET doll —
  MERGED to main (Bill's direction: "loot only for big kills; make the first signature strong;
  rebrand boons as armor — gear up your run").** Playtest verdict fixed: drops-every-fight + weak
  items = no WoW moment. (1) **Drops are EVENTS** — roll only at Seal kills, gate exams, and any
  kill whose SIGNATURE is still locked (first-kill shower intact); repeat skirmish kills pay
  ring-scaled salvage ⏣ (1/2/3) via toast (`raid_hud._after_drop(event)`, `Gear.first_locked`).
  (2) **Weights retuned richer** (50/35/15 · 38/40/22 · 25/40/35 by ring — ~4-6 rolls/descent).
  (3) **Signature strength pass** — all 9 live signatures redesigned STRONG, combat six promoted
  to printed Sonnet: Tooth (denied heal resets defense+dodge +20), Bell (+30 & 10s double-regen
  hum via `GearFx.bell_live`), Stamp (+4 links/+8 Momentum + Guard reset), Powder (3 stacks/+2
  Flow), Spark (first 2 answered kicks refund whole cd), Salt (heal 60 + mana refund), Swan
  (200/25), Stub (+10% +1⏣). (4) **ARMOR SET (presentation-only)** — `data/armor_slots.gd` maps
  all ~120 boons → WEAPON/HELM/CUIRASS/GAUNTLETS/GREAVES (healer WEAPON = heal output; explicit
  id map + tag fallback — note: the `slot` boon key was TAKEN by verb-mods, armor uses its own
  table); `game/ui/armor_doll.gd` YOUR SET paper doll (count badges + best-rarity rings + hover
  piece lists + 2 curio TRINKET sockets) on the descent map, beside the REFORGE draft (shared
  DraftScreen gains a "⚒ SLOT" forge chip per card + REFORGED toast), build panel grouped by
  slot, drop ceremony framed "a TRINKET for your set". Draft economy UNTOUCHED (Hades stacking,
  no caps). **Gate PASS:** gear_probe 57 checks ALL OK · frozen-snapshot A/B — all 5 gearless
  sims byte-identical (100 seeds; only the CSV-path echo differs) · all 7 UI smokes green ·
  `sim/screenshot_armory.gd` GUI tour (map doll / forge chips / trinket drop) eyeballed clean ·
  post-merge-with-main (tune.sh) probe+smoke+raid_sim re-run green. **Docs:** PROGRESSION-PLAN
  (drops-are-EVENTS + signature philosophy + THE ARMOR SET section), GEAR-CATALOG (weights table
  + strong rows). **Deferred (Bill's B-halves, revisit after feel-testing):** capped slots w/
  replacement (kills Hades stacking), Need/Greed shared rolls vs the AI raid at Seal kills (needs
  AI seats wearing gear + raid_sim gate). *(armory session)*

- ☑ 2026-07-03 · `ledger-desc` · §GRAPHICS/GEAR — **Show item EFFECT on the Ledger page — MERGED (`e9e76ef`).** The
  Ledger (`raid_hud._offer_oath_then`) shows each row's item name + rarity + unlock condition but NOT
  the item's `desc` (what it does) — "make it clear what I'll get". Add the effect line (rarity-colored,
  wrapped) per row so the player sees the reward's actual effect. Data already exists (`GearCatalog`
  item `desc`). View-only, one function. ⚠ `raid_hud.gd` shared w/ `gear2` (owns this screen) +
  `bloom-raid` — merge main before merge-back. Gate: ui_smoke_raid green + a Ledger screenshot. *(raid-finish session)*

- ☑ 2026-07-03 · `raid-tuning` · §BOSSES + §CLASSES — **RAID healing rebalance — FIRST PASS MERGED to main
  (`4a9f33e`), all raid-gated (solo sims byte-identical, verified).** The raid healer was idle 93–98% w/
  mana never a factor (proved by the `ed6ca6e` logs on main). Fixed: (1) **tank self-heal cut** — Fortify's
  flat 130 → ~68 when `threat_enabled` (`bulwark_config.raid_self_heal_mult 0.52`; DR still carries, so it's
  a mitigation button and the HEALER tops the tank); (2) **raid mana regen** dialed via the raid Mender seat's
  `regen_mult` var (0.5, no MenderConfig change → solo byte-identical); (3) **Vorathek ramp** (the TEACHING
  Seal, kept GENTLE): melee 30-42→34-44 (the only un-freezable pressure = the healer's core job), Cataclysm
  30→42 unavoidable baseline, Riftrot 3 targets, Void Volley a gentle dodge-check; (4) **battle rez 'Rekindle'**
  (Mender: 6s channel / 340 mana / 120s cd, revives a fallen ally at 40%; raid HUD rune + **R** key, hover the
  fallen frame; loss model untouched — a single dead dps was always survivable). Engine-clean; `raid_sim` now
  also prints `rez` + a fixed `hlIdle` (excludes mid-cast).
  **Result (150 seeds):** healer GCD-idle **93%→8-54%** (finally engaged). Skill bands: Vorathek 100/100/**47**
  (teacher gradient ✓) · Gemini 100/100/**69** ✓ · Mythos 100/97/**20** (finale, rez fires ~0.07/run) ✓ ·
  **Mistral 100/100/100** (still a pushover — melee bumped so the healer works, but it has no lethal dodge-check;
  needs its own gradient pass). Mana floor DIPS more up the ladder (Vorathek ~85% → Gemini/Mythos ~79-84%) — the
  ramp works. Determinism PASS (riftmaw/mistral/gemini); solo bulwark+mender PASS bands-match; ui_smoke_raid +
  ui_smoke_mender green.
  **NEXT (unclaimed, wants Bill's playtest feel):** (a) the "painful ramp" — crank the LATER Seals' dodge-checks
  so a missed dodge really bites (Mistral needs a real dodge gradient; Gemini/Mythos punish harder); (b) MANA AS
  A HARD WALL is still open — regen barely moves the floor because the Mender's kit is very efficient (cheap
  HoTs/wards + Meditate's 280 battery); a true OOM wall needs trimming those efficiency tools (a Mender design
  call) or much more sustained damage. (c) rez feel: it rarely fires in AI sims (AI dies in cascades, not
  isolation) — it's mostly a human/co-op save; watch it in co-op.
- ☑ 2026-07-04 · `resource-tax` · §BOSSES + §CLASSES — **RESOURCE-TAX pass (SECOND healing/resource pass) —
  MERGED to main (`cf29902`).** Closes open item (b) above (mana-as-a-wall) + Bill's playtest steer: "mana is
  still infinite, fights are short, too much resource regen — hurt mana a lot to overshoot the middle, similar
  with other resources, and battles should be longer." Unlike the first pass (raid-gated `regen_mult`), this
  trims the Mender's **efficiency tools at the config level** (so it bites everywhere the Mender plays):
  `mana_regen 8→4.5` · **Meditate 280→160, cd 45→55** (the flagged battery) · core heal costs ×~1.5
  (flash 22→33 / mend 16→24 / renew 18→27 / ward 20→30 / cascade 40→58 / well 30→46 / surge 22 / laststand 28 /
  revive 340→380). Other resources (softer — "keep execution the focus"): **Twinfang energy 20→18** (gentle;
  14 broke Tempo's accelerando — good-tier missed enrage, so backed off), **Bloomweaver sap 12→9**; Voidcaller
  Focus (build-and-spend) + Bulwark rage (combat-gen) left as the already-gated exemplars. **Longer fights** —
  raid Seals HP +~17% / enrage +~20% (riftmaw 13500→15500/90 · mistral 13500/95 · gemini 16500/108 · mythos
  19000/142).
  **Result (raid_sim 200 seeds):** healer mana floor now DIPS to **exp 46-57% / good 0-48% / sloppy OOM-wall**
  (was never <42%, idle 9-54%) — you finally watch the bar; fights **+20-25% longer**. Bands: expert 100 all
  Seals · good 96-100 · sloppy riftmaw 80 / mistral 100 / gemini 60 / mythos 22. Determinism PASS ×4 Seals;
  threat gate load-bearing (OFF 0.45 dps deaths vs ON 0.00); solo Mender bands intact (choir ~79/83, rendmaw/
  rotweaver ~100); Twinfang warden-tempo 100/100/0 & exec-tempo 100/88/0 & venom healthy; Bloomweaver bands
  intact; Bulwark/Voidcaller untouched (localized change verified); ui_smoke_raid ALL OK.
  **NEXT (wants Bill's playtest feel — the "middle" dial):** this landing keeps EXPERTS comfortable (floor ~half)
  and punishes good/sloppy — if mana should bite experts too (true overshoot), cut `mana_regen` further (4.5→~3)
  and/or costs up; if too harsh, ease regen back up. Still open from pass 1: (a) Mistral has no lethal dodge-check
  (100/100/100); (c) rez feel in co-op. See [[raid-healer-under-pressured]].
- ☑ 2026-07-03 · `online-boons` · §MAPS MAP-3b / §SYSTEMS — **Online co-op boons — MERGED to main
  (`24dd28a`)**, worktree removed. The Draft 2.0 boon draft now works in online co-op: each human
  seat drafts its OWN boons after each won fight, and the picks ride the fight SPEC per seat
  (`RaidNet.make_spec` `seat_boons`; `build` applies each seat's `boons`) so every replica builds the
  identical fight — lockstep-safe. Server tracks per-seat boon sets + a post-fight DRAFT phase
  (`draft`→`pick`, proceeds once all seats picked; disconnect drops the owed pick); map broadcast
  carries the descent `seed` so clients seed their run. Client rolls its own offers → `DraftScreen`
  → `send_pick` → waits; build panel un-gated for online. Protocol **v3→v4**. Gate PASS:
  `net_map_smoke` extended (2 clients draft 6 boons, boons rode a spec, ring advanced, **zero
  desync**); `net_smoke` ALL OK on v4; offline byte-identical (empty `seat_boons`); ui_smoke_raid +
  raid_boon_probe + bulwark determinism green. ⚠ **protocol v4 — rebuild+redeploy server with
  clients.** **This closes the offline/online boon gap — boons + gear now work both ways.** *(raid-finish session)*

- ☑ 2026-07-03 · `pause-codex` · §GRAPHICS/UX — **In-game PAUSE menu + DEV CLASS CODEX — MERGED to main
  (`33d44ba`).** A PAUSE button (top-right of combat) + **P / Esc-in-combat** open an overlay on the ONE
  game HUD: OFFLINE it FREEZES the fight (`CombatController.paused`, guarded — ONLINE lockstep never
  freezes, the guide just opens over the running fight); it renders a **Class Codex** for the seat you're
  driving — core-loop, each BAR (fills/spends/goal), each MOVE (+ what it encourages), the GOAL ROTATION
  for your Aspect, and **THE BRANCHES** (both Aspects + boon/gear sub-builds, current one highlighted +
  drafted-boon count in the header). New files: `data/class_codex.gd` (authored for the 4 raid classes
  from live kits/configs/boons + HUD tips — a TEACHING doc; code wins on drift), `game/ui/pause_overlay.gd`,
  `sim/screenshot_pause.gd` (WSLg probe). Engine: **+1 guarded field on `CombatController`** (the DRIVER,
  not `CombatCore` — sims never touch it, so class checksums are unaffected by construction). raid_hud:
  combat-screen only (`_input` Esc/P→pause · `_build_combat` button · `_clear` drops the freeze · SEAT_CLASS
  + `_owned_boon_labels`). **Verified:** ui_smoke_raid green (opens+freezes+resumes the codex for all 8
  seat×aspect combos, asserted) · menu_probe green · bulwark determinism PASS · WSLg shots eyeballed
  (tank/blade/caster/healer render clean + scannable). Merged main (menu-refresh) before merge-back —
  clean auto-merge (menu vs combat regions). ⚠ **`build-panel`** (open claim) plans an always-visible
  readout at the SAME top-right combat corner as this PAUSE button — coexist/relocate when it lands
  (complementary: glance panel vs full pause guide). NEXT: extend the codex to Bloomweaver if it ever
  becomes a seat; per-branch "you own this" highlighting off `_run.boons`. *(pause-codex session)*
- ☑ 2026-07-03 · `build-panel` · §GRAPHICS — **Verb/boon summary on the game HUD — MERGED to main
  (`fbfc74b`)**, worktree removed. An always-visible **TOP-LEFT** panel during offline descent fights:
  "◆ YOUR GUARD/RHYTHM/KICK/TRIAGE" + the assembled verb rules (per-class `*_boons` verb summary) +
  the drafted boons (title, rarity-colored). Tracks `_taken_boons` dicts in `_show_boon_draft` (reset
  per descent). Placed top-left (not top-right — the DPS meter owns that; caught via screenshot).
  Reconciled with `pause-codex` (kept both; its `_pause_quit` now returns to `_show_home`, not the
  retired `main.tscn`). Gate PASS: screenshot-eyeballed (renders clean, no collision); menu/boon
  probes + ui_smoke_raid green; bulwark determinism unchanged. **View-only, zero engine.** NEW WSLg
  probes `sim/screenshot_menu.gd` + `sim/screenshot_build.gd` (render works here — no longer
  layout-blind). NEXT: online boons (build panel + draft ride the spec). *(raid-finish session)*

- ☑ 2026-07-03 · `menu-refresh` · §GAME SHAPE — **Menu refresh + boot into the game HUD — MERGED to
  main (`d27a84f`)**, worktree removed. The game boots straight into the game HUD (`raid_main.tscn`);
  `main_menu` + the dev BossSelect front door are retired. Flow: **HOME** (PLAY / PLAY ONLINE / QUIT)
  → **CLASS** (4 seats) → **SUB-CLASS** (Aspect) → **RAID** (Realm 1 card) → the descent. All
  fight-end/Esc/leave returns → `_show_home` (`_show_select` is now a thin wrapper). Reuses AspectCard
  for class + raid cards; boss-select stays `--autostart` dev only. Gate PASS: NEW `sim/menu_probe.gd`
  (HOME→class→aspect→raid→live descent→HOME); ui_smoke_raid green; bulwark determinism unchanged;
  boon/gear/floor probes green. **Menus+docs scope** (no file rename). **Pending:** a live WSLg glance
  at the card/button layout (headless proves it builds, not the pixels). **NEXT:** the verb/boon
  summary on the game HUD (deferred from the boon work); optional later — rename `raid_hud`→`game_hud`. *(raid-finish session)*
- ☑ 2026-07-03 · `raid-boons` · §MAPS/§SYSTEMS — **Boon draft in the RAID campaign — MERGED to main
  (`0338a37`)**, worktree removed. Draft 2.0 (1-of-3 / rarities / build-your-verb) now runs in the
  raid descent OFFLINE: the human seat gets a `_run` (RunState via the class starter), a **REFORGE**
  `DraftScreen` fires after each won fight (chained AFTER the gear drop), `Draft.take` folds the pick
  into `_run.boons`, `_inject_boons` rides it into the human kit at every map/gate-fight build
  (`_show_boon_draft` mints Tokens too). AI raiders stay boon-less; boons persist across the descent.
  Gate PASS: NEW `sim/raid_boon_probe.gd` (1-of-3 offered, taken boon injects into the kit, reaches
  REFORGE after the drop); `map_advance_probe` all 4 seats gear→draft→DESCEND→floor 1; ui_smoke_raid
  green; bulwark determinism unchanged. Merged `twinfang-accel` cleanly. **NEXT:** ONLINE boons (the
  human's `run_seed`/picks ride the fight spec so replicas build identically — netcode follow-up);
  a verb/boon summary on the raid combat HUD (solo shows one; raid doesn't yet); gate-fight post-draft. *(raid-finish session)*
- ☑ 2026-07-03 · `gear2` · §SYSTEMS GEAR-2 — **Sworn OATHS + Ledger offer + purses — MERGED to main
  (`8d18685`)**, worktree removed. The oath loop is LIVE on the raid campaign: swear ONE oath on
  the boss's **Ledger offer screen** (page rows w/ lock gems + SWEAR / RE-SWEAR / FIGHT UNSWORN)
  → in-fight ⚖ tracker banner (turns crimson + "OATH BROKEN" pop the moment a monotone deed dies)
  → resolves at the kill: **OATH KEPT = the row unlocks INTO the same kill's drop pool** + a
  stakes-scaled purse (`Oaths.purse`: Tokens + pity ticks / sonnet floor / opus guarantee,
  `stakes = 3 − ring`); Realm-1 verdicts = SLA MET / SLA BREACHED. `game/oaths.gd` detector
  engine reads `seat.diag`/`seat.vars` ONLY (new unconditional diag: curse_dropped/answered
  [engine THREAT_DROP+taunt], chain_break, kick_whiff [kit mistake-counters — gear saves don't
  hide deeds], bloodied_dip [`_damage` crossing]; + `BossState.last_curse_tick`). `Gear.roll` is
  now the real **rarity-first draw** (ring weights 70/25/5 → 55/35/10 → 40/38/22, +5pp opus per
  pity tick, purse bends, nearest-tier clamp). SEVEN new curios w/ oath rows: **GRACE PERIOD**
  (one streak-break forgiven — 5 class meanings) · STICKY NOTE · SCRATCHPAD (regen ×3 in ≥6s
  winds) · DEBT COLLECTOR · ENCORE BELL · **ECHO CHAMBER** (opus) · OVERFLOW SLUICE — every raid
  class's gate page has a deed to chase. **Tokens unified**: scrap + purses feed raid-boons'
  REFORGE purse (`_run.tokens` — one ⏣ currency). **Gate PASS:** fresh frozen-main A/B — all 6
  sims CSVs byte-identical unsworn/gearless · map sims identical · `gear_probe` 51 checks ALL OK
  (detectors, purse table, floor/pity/ring rolls, all 7 items + controls, geared determinism) ·
  raid smoke drives swear→break→KEPT→purse→re-swear live · all 8 smokes + net_smoke green ·
  raid-boons' probes green (their `raid_boon_probe` needed one press-through for the new Ledger
  screen — the composed chain is win → verdict → drop card → REFORGE draft → DESCEND) · Ledger/
  verdict screens eyeballed (`screenshot_drop`). **NEXT (unclaimed):** GEAR-3 (MARKET stock +
  extraction schematics — tokens now have a real faucet); combat-actives socket (G/H) for MUTE
  BUTTON-family items; version-gated rows await the Trial Ladder; fold gear+oaths into the
  ONLINE campaign spec. *(gear-design session)*
- ☑ 2026-07-03 · `bloom-raid` · §CLASSES/§ONLINE — **Second healer in THE RIFT: Bloomweaver gets a raid seat —
  MERGED to main.** (Bill: "add the second healer... the last relic that didn't make it from the switch...
  separate shields from heals".) The last solo class never wired into the raid is now the 5th playable class.
  - **Class threading:** the healer SEAT is a class CHOICE (Mender ⇄ Bloomweaver), carried as a per-seat `cls`
    through `RaidNet` spec/build/make_policy/seat_to_ai + `default_aspect`/`cls_of` and `RaidContent._bloomweaver()`
    / `_healer_seat()`. Default `mender` → **every existing fight byte-identical** (all six solo sims + raid
    determinism checksum unchanged). `GateContent` is class-aware (a Bloomweaver's personal GATE = its Ashmaul exam).
  - **HUD (the one game HUD):** 5th class card THE BLOOMWEAVER → full band via `_healer_cls` fork —
    Sap orb + VerdanceGauge (Blooming Medallion) + benediction CastChannel + Growth/ward rune rail +
    BloomweaverBinds; input 1-4/Q/E/7 + chords + bloom double-tap + F/SPACE dodge; frames show Growth ripeness +
    ghost the BLOOM cash-out; 9 new event arms; verb = GARDEN; boon summary/pools. WSLg-verified (class-select,
    combat band, meter split all render clean).
  - **Meter split (Bill's ask) — SHIELDS ≠ HEALS:** engine `CombatCore.meter_shield` bucket routes ward absorbs
    to a new SHIELDING DONE / SPS column, out of HEALING DONE / HPS (real HP restored). `s.meter` only (never
    checksummed) → six solo sims byte-identical, `meter_probe` ALL OK. A ward-heavy healer no longer inflates HPS.
  - **AI:** the Bloomweaver policy now self-triages in raids (`observe` includes its own frame when
    `threat_enabled`) so it survives healer-piercing beats. Bands (100 seeds): riftmaw wild 100/100/98, thorn
    100/100/100; mythos wild 100/60/14 (the finale bites a proactive healer harder than Mender's reactive heals —
    flavor-consistent; deeper mythos AI tuning is a noted follow-up).
  - **Online (protocol v5, co-exists with v4 boons):** lobby healer CLASS toggle (Mender ⇄ Bloomweaver) +
    class-aware valid aspects; `net_smoke` runs a **Bloomweaver online healer** — both replicas build a
    BloomweaverKit at identical checksums + a mid-fight disconnect → BloomweaverPolicy AI takeover → clean win.
  - **Stage:** the 2D raid stage renders a MenderRig2D for the Bloomweaver seat (graceful), now tinted by its
    aspects (verdance green / thorn amber); a bespoke Bloomweaver rig is a later art follow-up.
  - **Gate:** all six solo sims byte-identical A/B, raid determinism PASS (default + bloom), all 7 UI smokes +
    meter_probe + raid_bloom_probe + net_smoke green.
  - **Reconciled with the healing-rebalance first pass (`raid-tuning`, 405fce8):** the harder raid (melee/nova/DoT
    ramp) engages the Bloomweaver too — its **Sap floor dips to ~46-55%** (a tighter resource constraint than the
    Mender's ~88% mana), 100% win on Vorathek, deterministic. High overheal (~48%) is the proactive-HoT signature
    (plant ahead → some ticks top an already-full ally — exactly why Verdance is earned only on EFFECTIVE healing).
    Battle-rez (Rekindle) stays **Mender-only by design** — Bloomweaver PREVENTS deaths (wards/HoTs ahead) rather
    than recovering from them. All 6 solo sims re-verified byte-identical post-reconcile.
  - **Follow-ups:** bespoke Bloomweaver stage rig; mythos AI finale tuning; a raid Sap-lever + overheal trim if
    Bill wants Bloomweaver's economy tuned like the Mender's (deferred — raid-healer rebalance pending Bill's
    steer, see [[raid-healer-under-pressured]]); optional Bloomweaver battle-rez; unpark its GEAR-CATALOG rows
    (ORCHARD BELL / CROWN OF BRIARS) now that it has a seat. *(bloom-raid session)*
- ☑ 2026-07-03 · `gear1` · §SYSTEMS GEAR-1 — **GEAR-1 raid-campaign loot PoC — MERGED to main
  (`866592f`)**, worktree removed. The Curio game is LIVE on the raid campaign: `data/gear/`
  (GearCatalog: 9 signature items — Riftmaw Tooth / LE CHAT's Bell / Swan Song / Ticket Stub /
  Cooling Paste + the 4 class-marked gate items; GearFx: the gear-gated kit proc layer) ·
  `game/gear.gd` (signature-first roll, class filter, own DetRng — combat rng untouched) ·
  `game/gear_store.gd` (`user://rift_gear.cfg` unlock store; HUD-flow only, headless stays
  disk-inert) · raid_hud: drop CEREMONY ("PERIPHERAL ACQUIRED" tarot card, EQUIP / REPLACE /
  SCRAP→⏣, dupes auto-scrap, `_map_tokens` bank for the future MARKET), curios armed on the
  human seat each pull (Seal/skirmish/GATE), PERIPHERALS map strip + Cooling Paste USE button,
  Ticket Stub rides `_ticket_at`, "curio" proc pops. Engine: ONE new no-op ClassKit hook
  (`on_boss_heal_denied`, dispatched from `stagger_boss`) + `Seat.gear/gear_vars`; kit sites
  all gear-gated. **Gate PASS:** frozen-snapshot A/B — all 6 sims logs+CSVs **byte-identical**
  gearless (120/100/60 seeds, psim) · map_sim + raid_map_sim identical · `sim/gear_probe.gd`
  22 checks ALL OK (roll rules, every item + gearless controls, geared-fight determinism +
  divergence) · all 8 smokes green (raid smoke drives the full drop loop) · net_smoke OK ·
  ceremony/map shots eyeballed (`sim/screenshot_drop.gd`). Noun locked: **CURIO** global /
  **PERIPHERAL** Realm-1. **NEXT (unclaimed):** GEAR-2 (oaths + Ledger UI + purses, per
  `GEAR-CATALOG.md`); fold `gear` into the ONLINE campaign spec (rides like tickets — v1 is
  offline-only); Bloomweaver rows stay parked until it gets a raid seat. *(gear-design session)*
- ☑ 2026-07-03 · `online-map` · §MAPS MAP-3b / §ONLINE — **Online co-op map traversal — MERGED to
  main (`127ab2c`)**, plan updated (§MAPS MAP-3b + Overall Progress netcode row), worktree removed.
  Server owns the campaign + broadcasts it, leader routes, fights `carry` state (protocol **v3**).
  New `sim/net_map_smoke.gd` proves a full 2-client descent (routes → carried-state fights [0.83–0.96
  opening] → MISTRAL Seal → ring advance to Ring 2, or clean wipe→campaign-end, **zero desyncs**);
  `net_smoke` ALL OK on v3; offline byte-identical (map_sim/raid_map_sim/bulwark determinism);
  ui_smoke_raid green. Merged main (self-heal-meter/gear-catalog docs) cleanly. ⚠ **protocol v3 —
  rebuild+redeploy the server with clients.** NEXT: live WSLg 2-window playtest; online GATE spectate;
  event-choice UX; party-vote routing. *(raid-finish session)*
- ☑ 2026-07-03 · main (docs only) · §SYSTEMS/PROGRESSION — **Gear catalog + boss-deed naming + difficulty scaling (Bill, direct) — DONE.** (1) **Feats/quests → OATHS** (sworn / OATH KEPT / OATH BROKEN; arm-with-cost = **Blood Oaths**; Realm-1 skin = SLA, Blood Oath = PIP) — PROGRESSION-PLAN amended, incl. one-oath-per-seat-per-fight (open Q resolved). (2) **Oath↔difficulty scaling:** severity I–III printed per row (= row rarity) + **re-swear purses** scaling with `stakes = (3−ring)+(version−1)` (Tokens + drop-roll bends; table in PROGRESSION-PLAN — unlock once, replayable fortune forever). (3) **`GEAR-CATALOG.md` NEW** — ~35 items across 11 Ledger pages (4 Seals · 3 skirmishes · 4 class-marked GATE pages), every combat item names its hook/tags/combo vs the class-fun kits (grounded via code extraction): Opus build-arounds = **KEYSTONE OF THE BROKEN WALL** (Sunder-max resets the raid's defensive verbs), **SECOND OPINION** (PERFECT/READ beat payoffs ×2), **FIFTH PSALM** (Benediction fires triage payloads party-wide), **ROULETTE FANG** (wheel-revolution micro-sip), **ECHO CHAMBER**, **THE CONCLUSION** (execute-window payload ×2), ORCHARD BELL / CROWN OF BRIARS (parked until a Bloomweaver seat is live); **THE UNPLUGGING** set pair (the power-cable gag as the 2-slot meme build); Haiku rows all single visible proc moments; ring/version drop-weight table; GEAR-1..4 rollout mapping + `gear_probe` acceptance bar. **NEXT:** Bill blesses the gear noun (CURIO / Realm-1 PERIPHERAL proposed) → GEAR-1 claimable against the catalog. *(gear-design session)*
- ☑ 2026-07-03 · `self-heal-meter` · §SYSTEMS — **Meter follow-up (Bill, direct): SELF-heals now count — MERGED to main (`c616fe7`).** The HEALING column answers "how much do I keep myself alive vs the healer": kit `_heal` helpers meter their EFFECTIVE slice (overheal beside it, HP behavior unchanged — same clamp) credited to the seat itself, srcs named after the cards — Bulwark `lifesteal`(Bloodthirst)/`fortify`/Vengeful Guard/Landslide/Warding Light · Voidcaller Kick Recovery(int_heal)/Reprieve/Umbral Mending · Twinfang Red Harvest. Raid HEALING ranking shows it live (probe shot: Mender 524 · 19.8 HPS vs tank Fortify 130 · 4.9). Gate: bulwark/twinfang/voidcaller (120 seeds) + raid (60) logs AND CSVs **byte-identical** vs main; `meter_probe` +2 self-heal checks (voidcaller fight row exists; Bloodthirst lifesteal == exactly 48) ALL OK ×2 (pre + post the raid-richness main sync); 4 smokes green; `screenshot_meter` gained a HEALING-mode raid step. *(meter session)*
- ☑ 2026-07-03 · `raid-richness` · §MAPS MAP-2 — **Raid map RICH & FUN — MERGED to main (`d2e51ea`)**,
  plan updated (§MAPS MAP-2 has the record), worktree removed. TICKETS quests (pickup→turn-in,
  wound-economy rewards + sprint-retro bonus, closeable-by-construction, `_prove_tickets` PASS),
  per-ring identity (`MapContent.realm_title/sub`), +5 events (solo pool frozen at 6 for byte-identity,
  raid uses `raid_event_ids()` = 11). Game-layer only, zero engine; all guarded off = byte-identical
  solo map + combat. Gate PASS: raid_map_sim all floors (tickets/shard/gate/structure/determinism) +
  solo map_sim byte-identical + ui smokes + bulwark/raid determinism. **STILL OPEN in MAP-2:** ELITE
  nodes, MARKET (needs GEAR loot), secret rooms, art pass. *(raid-finish session)*
- ☑ 2026-07-03 · `realm1-floors` · §MAPS MAP-3c — **Finish Realm 1's raid — MERGED to main (`fafaf1a`)**,
  plan updated (§MAPS MAP-3c has the full record), worktree removed. GEMINI (Ring 2) + CLAUDE MYTHOS
  (Ring 0, credential-shard gated) are now playable floor Seals in a 3-floor RING descent;
  `RaidContent.FLOORS[]` + `floor_fights(ring)` + `raid_hud._build_floor`/`_advance_floor`/
  `_show_floor_cleared`/`_show_campaign_cleared`; `RunMap` shard gate (completability BFS-proven).
  Reconciled with the concurrently-merged `gate-nodes` (one personal GATE exam per floor —
  `_build_floor` passes `{KIND_GATE:1}`+`shard_req`) and `dps-meter` (engine byte-identical, checksums
  matched). Bands 100/100/97.5 · 100/100/92.5 · 100/100/47.5. Gate PASS: all sims determinism +
  raid_sim/bulwark_sim byte-identical + all smokes green. **Online nav (3b) is the open follow-up.** *(raid-finish session)*
- ☑ 2026-07-03 · `gate-nodes` · §MAPS/§GAME SHAPE — **Tier-1 PERSONAL GATE nodes — MERGED to main**, plan updated (§MAPS GATE entry has the full record), worktree removed. Zero engine files; `run_map.gd` gained the guarded `extra_quota` param (empty = byte-identical, proven: map_sim 300 seeds + raid_sim 60 identical vs frozen branch-point baseline); raid smoke drives the full gate flow (intro → exam → win writeback / loss = force-reboot wound, run continues); merged main in pre-merge-back (bulwark class-fun ④ landed mid-work — post-merge probes re-PASS). ⚠ realm1-floors session: the GATE kind is yours to reuse per floor (`{RunMap.KIND_GATE: 1}` in the floor's generate call); gate exam difficulty is currently Ring-3 teaching tier for all floors — deeper rings may want harder exam picks (a `GateContent.EXAMS` ring dimension). *(progression design session)*
- ☑ 2026-07-03 · main · §GAME SHAPE — **RAID-ONLY locked with Bill (docs only)**: one game (raid campaign + PROVING GROUNDS practice card, unlock-inert); solo campaign/maps/HUD-polish retired-frozen; 15 solo bosses → personal-content pipeline (Tier-1 GATE nodes claimable / Tier-2 owned adds / Tier-3 split phase); **raid-first law**. PROGRESSION-PLAN Breadth/GEAR-1 retargeted; RAID-PLAN product shape amended. *(progression design session)*
- ☑ 2026-07-03 · main · §SYSTEMS — **`PROGRESSION-PLAN.md` written (docs only, design locked with Bill)**: persistent meta-game = boss loot tables + armed feats + extraction schematics + World/Pools/Rank/Breadth tracks + standing; Monotonic Pool Law; material economy CUT (supersede notes added to RAID-PLAN). No code touched. GEAR-1 (Bulwark PoC) is claimable. *(progression design session)*
- ☑ 2026-07-03 · `dps-meter` · §SYSTEMS/§GRAPHICS — **DPS/HPS meter (Recount-style), Bill's direct ask — MERGED to main (`5a6e4ad`).** Engine: `state.meter` per-seat per-source accounting (diag-family, NEVER checksummed) written at the funnels — `damage_boss`/`heal_unit` gained optional `src` (rides `boss_hit` events as `kind`+`crit`, so ALL classes now feed the raid damage-number source palette — closes raid-dmg-juice's follow-up), `_apply_group_damage` per-seat, HoT ticks credit their `src` stamp, absorbs credit the ward owner as healing, `_damage` tracks taken-by-source; kits label every damage/heal site (Twinfang's direct-deal path calls `CombatCore.meter_dmg` itself). UI: `game/ui/meter_panel.gd` right-rail window in ALL SIX HUDs — ranked combatant bars (class-accent, live DPS/HPS + rolling NOW), click a raider → per-spell breakdown (total · share% · n · avg · max · crits / overheal%), header click cycles DAMAGE/HEALING/TAKEN, **M cycles ranking → spells → hidden** (session-sticky), healers default to HEALING; end screens get a frozen clickable recap beside THE RECKONING. Works online untouched (reads lockstep state only; net_smoke ALL OK). **Gate:** frozen-snapshot A/B — all 5 class sims + raid Riftmaw(150)+Mythos(60) logs AND per-seed CSVs **byte-identical**; `sim/meter_probe.gd` (Σ meter == boss HP delta + self-heals exactly, kit-direct path covered, healer/HoT/raid attribution, meter determinism) ALL OK; mid-work main merges reconciled (Litany ② / Ripen-vs-Snap ③ / Redline-avalanche ④ — src labels re-applied onto the reworked sites, mender+bloomweaver+bulwark+raid re-proven byte-identical vs main post-merge); 6 UI smokes + net_smoke green; WSLg shots eyeballed (raid compact/detail/end + solo Twinfang detail — Tempo reads 59% Perfect Strikes, the aspect identity is legible in the data). **Caveats/next:** kit-side self-heals (`_heal` helpers: bulwark lifesteal, voidcaller siphon) are not metered (survivability, not healer output — thread `CombatCore.meter_heal` through them if wanted); all ward absorbs lump under one "Wards" row per owner; `sim/screenshot_meter.gd` is the visual probe. *(meter session)*
- ☑ 2026-07-02 · `raid-dmg-juice` · §GRAPHICS — MERGED to main (`eb79f5a`), synced to the Windows play copy. Damage-number juice now lives in the RAID HUD (where the user actually plays). Shared `game/ui/damage_numbers.gd` (`DamageNumbers.spawn` — one source of truth for the STYLE table + rendering; solo Twinfang refactored onto it, ~85 inline lines deleted). Twinfang kit stamps `seat` on its boss_hit + poison events (damage_boss already had it) so the raid attributes hits; `raid_hud` → YOUR hits full treatment (source colour, big, longer, punch, crit outline+spark-ring+shake), an ALLY's hit small/dim ambient (own-vs-ally via `ev.seat == _ctrl.player()`; generic own-hits tint by seat class accent). Gates: twinfang_sim + raid_sim **byte-identical** vs main (Riftmaw seed-1 cs 1472825847869132157 unchanged), both UI smokes, raid dmg-path probe, WSLg raid screenshot. **Note:** only Twinfang tags a damage `kind`, so in the raid the blade seat gets the rich source palette; other seats (tank/caster/healer) get bigger accent-tinted numbers + crit-capable but no per-ability colour until their kits tag sources too — an easy follow-up. *(this session)*

- ☑ 2026-07-02 · main · Online/R2+R2.5 — DONE, retroactive claim: lockstep netcode (`godot/net/`), deploy kit (`server/`), Windows engine, browser WASM + tunnels. See CLAUDE.md R2/R2.5 entries. *(online session — same session as draft2 below)*
- ☑ 2026-07-02 · main · Infra — git init, baseline commit, MASTER-PLAN.md created, CLAUDE.md wired to it. *(infra session)*
- ☑ 2026-07-02 · main · §MAPS — design locked + written (docs only); Raid Floor 1 depends on `raid-seals` merge. *(planning session)*
- ☑ 2026-07-02 · `map1` · §MAPS MAP-1 — MERGED to main (`fd62f7b`), all sims/smokes green, plan updated, worktree removed. Realm-1 "The Stack" skin incl. Bill's GPU/data-center/water/jobs flavor (6 events). ⚠ draft2 session: bulwark_hud.gd changed (draft header/`_on_card_taken`/`_on_end` map-mode branches) — merge main in as planned. *(map session)*
- ☑ 2026-07-02 · `raid-seals` · §RAID SEALS + Bosses + Engine — MERGED to main (`ac1aa25`), full gate + 300-seed bands + probes + smokes green, plan updated, worktree removed. Net touches were additive (`enc` in spec, lobby `boss` msg, **protocol v2 — rebuild the server with the clients**); no conflict with map1/draft2 (tuning_config untouched). *(raid-seals session)*
- ☑ 2026-07-02 · `raid-map` · §MAPS MAP-3a — MERGED to main (`5d4ff47`), post-merge sanity green, plan updated, worktree removed. Ring 3 raid floor offline: skirmishes from Seal AddRes packs, raid map mode in raid_hud (integrity+mana carry, CORRUPTED SECTOR wounds — the attrition that actually bites, probe 98%→44%), raid_map_sim. Stayed off draft2's surface as claimed. *(raid-seals session)*
- ☑ 2026-07-02 · `judgment-ui` · §GRAPHICS — **Telegraph timing UI overhaul — MERGED to main (`2689262`)**: StrikeJudge "Judgment Channel" in all 6 HUDs (impact-gate hairline, graded bands @constant px/s, beat comets, verdict stamps, history gem rail), dial impact hairline + classic perfect sliver, string double-pop fix, player instruments moved to player column. View-only, zero engine files; all smokes green ×2, screenshots eyeballed, plan updated, worktree removed. *(judgment-ui session)*
- ☑ 2026-07-02 · `ability-runes` · §GRAPHICS — **Ability button UI overhaul — MERGED to main (`63b886d`)**: `ability_rune.gd` rebuilt as a chamfered gilded RUNE-SOCKET (the orb-shader "coin" that stretched into ovals is gone). Obsidian slot + two-tone bevel, glyph grown 33→40px and kept readable on cooldown, square radial cd veil + burn-down edge, become-ready GLEAM sweep, ready under-glow, hover ignite + press dip, out-of-resource crimson want-line, keybind tab notched into the top-right chamfer, name engraved UNDER the socket (face stays clean). Public API unchanged → zero HUD edits, all six rails (+ guard/challenge runes) upgraded at once. View-only; all 7 smokes green, rails eyeballed via screenshot probe. *(judgment-ui session)*
- ☑ 2026-07-02 · `orbs` · §GRAPHICS — **Resource orb overhaul — MERGED to main (`b75dc84`)**: `ui_orb_liquid.gdshader` (one pass: depth-shaded liquid, two-wave surface + hot meniscus, rising bubbles, damage-CHIP ghost that drains after a hit, gain FLASH, low-HP BOIL, glass volume/crescent/gold-rim/speculars in the ui_orb light grammar; GL-Compat safe) + `liquid_orb.gd` rewrite (keeps claw mount/numeral/caption plaque; eased fill, chip/flash timers, HEALTH numeral bleeds crimson when low). API unchanged → every HUD orb upgraded free (HP/rage/energy/focus/mana/sap, all six HUDs). View-only, zero engine files; 6 smokes green, both hues eyeballed (full crimson + part-full amber). *(judgment-ui session)*
- ☑ 2026-07-02 · `ui-ceremony` · §GRAPHICS — **Ceremony pass — MERGED to main (`3c63915`)**: `transition_veil.gd` (obsidian fade + gold hairline breath on every `_clear()` — screens settle in, never snap; one-line hook, all 6 HUDs), `boss_intro.gd` (self-freeing Cinzel-Decorative boss name-card + sigil ghost + sweeping gold rules at every fight start incl. raid Seals; non-blocking, burns off in 2.4s), DraftScreen deal-in stagger (rerolls re-deal), class-menu emblem entrance stagger. View-only, zero engine files; 7 smokes green, intro card + cd-veil eyeballed via probe. UI-OVERHAUL "screen transitions + boss intro card" line: DONE. Still open there: spellbook/binds art pass, boss-glyph small-size review. *(judgment-ui session)*
- ☑ 2026-07-02 · `recap` · §GRAPHICS — **End-screen recap stats — MERGED to main (`16fcc19`)**: `recap_panel.gd` "THE RECKONING" on every win/defeat screen, all 6 HUDs — fight duration, epithet (UNTOUCHED/FLAWLESS/CLEAN/SCRAPPY/BLOODY), judgment bar + counts (`seat.diag` engine truth, classic parries folded in) in the Judgment Channel's grade colours, DEALT/TAKEN counting tiles (`RecapPanel.track` one-liner in each event drain, tallies reset per fight), conditional footnotes (boss-reclaimed HP, kicks/clean/DENIED, rhythm %, reads, whiffs), staggered reveal. Guarded for smoke-built end screens (null state). View-only, zero engine files; 7 smokes green; probe-verified end screen (Devourer clear: FLAWLESS, 12-perfect bar, 4084/398, reclaim footnote). *(judgment-ui session)*
- ☑ 2026-07-02 · `grimoire` · §GRAPHICS — **Spellbook art pass — MERGED to main (`8c0a446`)**: `grimoire.gd` two-page reliquary tome (dim veil, gilded spine, opening entrance; ABILITIES page = rune-socket glyph rows + keybind chips + stat lines + wrapped ABILITY_TIPS incl. the defensive verb; BOONS page = rarity-gemmed Draft 2.0 entries + type tags, scrollable, "the pages wait" empty state) replaces the plain-text `_toggle_book` panels in bulwark/twinfang/voidcaller (same S toggle; veil-click closes). View-only; 7 smokes green, tome eyeballed via probe (4-boon warden book). **Note:** `_run.boons` is a Dictionary (id→true) post-Draft-2.0 — resolved via each class's pools. Follow-ups: healer tome (mender/bloomweaver have boons but no book button), raid tome. ⚠ gotcha: a half-broken `.godot` import cache in a fresh worktree parse-fails ui_kit's font preloads and CASCADES weirdly (`wing_flourish nonexistent`) — `rm -rf godot/.godot` + re-import fixes it. *(judgment-ui session)*
- ☑ 2026-07-02 · `juice2` · §GRAPHICS — **Combat juice II — MERGED to main (`54d06a1`)**: `kill_moment.gd` fight-end beat (win: SLAIN in Cinzel-Decorative over expanding gold shock rings + ember burst · loss: YOU FALL into a closing crimson vignette; ~1.3s via `_on_end_moment` wrapper in all 6 HUDs, headless runs skip it so smokes/sims are untouched); **BossBar enrage clock** — the game's deadliest timer was invisible: pulsing "◆ ENRAGE · Ns" from T-12s (urgency-scaled pulse), burning "— ENRAGED —" frame after, INF-guarded for enrage-less fights + gold phase-break flash; `_float_num` damage text with WEIGHT (magnitude-scaled Cinzel numerals 17→30px, x-drift, expo rise, late fade) in bulwark/twinfang/voidcaller/raid. View-only, zero engine files; 7 smokes green; SLAIN moment probe-verified (Devourer kill). *(judgment-ui session)*
- ☑ 2026-07-02 · `draft2` · §SYSTEMS — MERGED to main (`c05d2e8`): Draft 2.0 (Phase A) + Token economy (Phase C), all five classes. Gates: draft_sim ALL OK · 5 class sims + raid **byte-identical** vs frozen baselines at every step (raid's post-merge diff = raid-seals' own new sim content; Riftmaw seed-1 checksum matched exactly) · smokes + map_sim green post-merge (map salvage drafts now ride DraftScreen w/ custom headline; mint runs in map mode) · WSLg draft screens verified. Plan updated (§SYSTEMS, Overall Progress). Phase B (slot-verbs + lock-a-slot spend) is the open follow-up. *(draft2 session)*
- ☑ 2026-07-02 · `slot-verbs` · §SYSTEMS Phase B — MERGED to main (`7860efa`): build-your-Guard PoC (cross-product TRIGGER×PAYLOAD×PROPERTY pieces, opus Twin Guard) + LOCK·1⏣ hold-through-reroll. Gates: 6 sims **byte-identical** boonless vs fresh baselines · `_prove_guard_mods` 74.2%→92.5% + determinism PASS · draft_sim ALL OK (5-class LOCK matrix) · 5 smokes · WSLg shots (locked draft / Grimoire YOUR GUARD / live charge pips). Merge grafted YOUR GUARD into the new Grimoire tome's guard entry. Plan updated; port-to-other-verbs is the open §SYSTEMS follow-up. *(draft2 session)*
- ☑ 2026-07-02 · `twinfang-dmg-juice` · §GRAPHICS — MERGED to main (`c76355e`). Twinfang damage numbers now read by SOURCE: `twinfang_kit._deal` tags every `boss_hit` with a `kind` (view-only, twinfang_sim **byte-identical** vs main ×2 — before & after merging slot-verbs-port in); `twinfang_hud._dmg_num`/`DMG_STYLE` colours autos gold, Eviscerate/Flurry ember, Coup mint, Rupture green — all bigger + longer (1.15–1.85s) with a scale-punch, and CRITS slam bold (Cinzel 900) + outline + hard punch + spark-ring (`_crit_burst`) + flash/shake. Rotating spawn LANES (odd staggered down) so combo bursts fan out instead of piling up. Merged cleanly under slot-verbs-port (different regions in both shared files). Verified: byte-identical sim, UI smoke, 12-path crit probe, WSLg screenshots (realistic + burst both legible). **Pattern is portable** — the other 4 classes could tag their damage sources the same way if wanted. *(this session)*
- ☑ 2026-07-02 · `slot-verbs-port` · §SYSTEMS Phase B port — MERGED to main: build-your-verb for the OTHER FOUR classes (RHYTHM/KICK/TRIAGE/GARDEN engines, 32 pieces, 4 opus transforms incl. Twin Step/Twin Void charges + Benediction + Deep Garden). Gates: 6 sims **byte-identical** boonless vs fresh baselines · 4 probes PASS (rhythm 54.2→92.5, kick 80.8→100, triage 71.7→90.8, garden 78.3→84.2, all det) · draft_sim ALL OK · 5 smokes ×3 · WSLg (YOUR RHYTHM tooltip in-frame + Twin Step/Void pips). Merged juice2's `_on_end_moment` cleanly. §SYSTEMS Phase B now fully closed — slot-verbs live on ALL FIVE verbs. *(draft2 session)*
- ☑ 2026-07-03 · `audit-cleanup` · §TOOLING/Audit — **Code audit + non-controversial cleanup — MERGED to main (`fd512f8`)**, synced to Windows. Fan-out audit (11 scoped agents → adversarial verify → synth): 60 findings, 24 verified auto-safe APPLIED, 13 confirmed-but-need-a-decision PARKED (see §CODE AUDIT). Applied = dead code (AspectRes/UpgradeRes/ui_orb.gdshader + ~10 dead helpers/consts), per-frame perf (core `_apply_inputs` empty-queue skip; phase_ats/progress/enrage-colour set-once; pose_rig glow-guard + default-alloc hoist), DRY (`_float_num`→DamageNumbers, `_phase_num`→BossBar.phase_index, draft build_tags hoist), raid `_barrage` feint. Net −179 lines. Gates: 6 solo sims + raid Riftmaw/Gemini checksums **byte-identical**, draft_sim OK, 7 UI smokes green, WSLg renders clean. *(this session)*
- ☑ 2026-07-03 · `mender-overflow-fix` · §CODE AUDIT — MERGED to main (`2c94233`), synced to Windows. Fixed the HIGH bug: Overflow now only GROWS a ward and claims ownership on real growth (was collapsing a larger Surge/Ward down to hp_max*0.5 + stealing owner every overheal). mender_sim boonless BYTE-IDENTICAL; new `sim/mender_overflow_probe.gd` regression guard (fails on old code); mender smoke green. *(this session)*
- ☑ 2026-07-03 · `bulwark-payexpose-fix` · §CODE AUDIT — MERGED to main (`4d3d9b6`). Sunder Guard now opens a PER-SEAT Exposed window and `outgoing_mult` applies +15% (was writing boss-level fields only the Voidcaller reads → 0% solo, and a co-op leak). bulwark_sim + raid Riftmaw checksum BYTE-IDENTICAL; new `sim/bulwark_expose_probe.gd` guards it (1.15 in-window, fails on old code); smoke green. *(this session)*
- ☑ 2026-07-03 · `twinfang-metronomes` (class-fun ①) · §CLASSES — **MERGED to main (`fa3bd36`).** Twinfang Two-Metronomes: **Tempo = ACCELERANDO** (Flow=BPM — the Perfect window slides earlier + tightens as Flow climbs; `*_lo` config anchors + `_perfect_lo/hi_sec` kit helpers = one source of truth for `_strike`+`observe`; the RhythmBar compresses for free since the HUD already feeds `obs.perfect_lo/hi`). **Venom = POISON WHEEL** (one lit lane V→F→C — a Strike feeds it & ADVANCES [ride → Synergy comes naturally], Envenom FIXATES to over-stack; **Flow removed from Venom entirely** → kills the old half-scales-with-Flow mud, `flow 0` confirmed in smoke). **Coup CONSUMES Flow** (seed 2; ride-vs-spend, AI cashes at execute <50%). Gauge shows the wheel's on-deck lane (pulsing ring+chevron+NEXT); tooltips/dodge-hint per aspect. Retune was **config-only** (no boss HP/enrage change): wheel apply 3/2, `venom_decay_every` 3→4s. **Bands (300 seeds):** Tempo 100/100/**0** (Warden) · 100/95/**0** (Executioner) — execution-heavy enrage-check intact; Venom 100/100/**98** (Warden) · 98/92/**64** (Executioner) — forgiving, `avg_flow 0.00`. Gates: determinism PASS (cross-seed probe moved to Venom — a flawless expert Tempo clear is legitimately seed-independent: boss never heals, no hit lands); **only 6 twinfang files changed → every other class byte-identical by construction**; `ui_smoke_twinfang` PASS; post-merge Bulwark+Mender determinism PASS. **DEFERRED** (input-surface / lower-priority): half-Rupture sip/slam + Flow-milestone slot procs. *(class-fun session)*
- ☑ 2026-07-03 · `mender-litany` (class-fun ②) · §CLASSES — **MERGED to main (`99c9cca`).** Mender Litany: **LITANY** = one 0-5 pip combo meter, filled by IN-CONDITION heals, **INVERTED per aspect** so the two builds can't be piloted the same way — Tidecaller lights a pip by topping AHEAD (heal leaves target ≥ `foresight_line` 0.60), Brinkwarden by catching BEHIND (heal catches target ≤ `blood_thresh` 0.40). Payloads scale ×(1+0.15·pips); the **5th pip cashes a party Benediction bloom** + resets (now CORE; repurposed `mdPropBenediction` → +50% + cleanse). Reuses the old `_triage_proc` engine (→ `_litany_beat`/`_triage_payloads`); unifies the 0.40/0.50 low line onto `blood_thresh`. **Signature fixes:** Last Stand = rolling Nerve-scaled HoT + DR that KEEPS allies bloodied (spends 60% Nerve) so Nerve income + the bloodied-damage buff survive the save (fixes the self-sabotage); Surge FLYWHEEL = a Tidecaller shield re-banks 35% of what it absorbs into the Reservoir (`on_absorb`, capped). **UI:** `LitanyPips` widget + RaidFrame **aspect READ overlay** (teal tide-line vs crimson brink-band, `read_mode`-gated so Bloomweaver/raid frames unchanged) + litany/benediction flashes + tooltips. **Bands (200 seeds):** Rendmaw/Rotweaver ~99-100; **Choir tide 73/65/65 · brink 83/78/78** — vs M7.2's near-tie 81/71/71 · 82/78/77, the rework SHARPENS the demanding-Tidecaller / forgiving-Brinkwarden contrast (better aspect divergence). Gates: determinism PASS; only mender files + the gated shared `raid_frame.gd` → other class SIMS byte-identical by construction; ui_smoke_mender + bloomweaver + raid PASS. **DEFERRED:** bloodpact re-cut (fiddly with stat-block allies). *(class-fun session)*
- ☑ 2026-07-03 · `bloomweaver-ripensnap` (class-fun ③) · §CLASSES — **MERGED to main (`b626706`).** Two DISTINCT aspect axes (zero shared gauge): **WILDGROVE = RIPEN** — a Growth matures (store `dur` on the hot; ripeness = 1−left/dur); harvest inside the ripe window [`ripe_lo` 0.45, `ripe_hi` 0.88] blooms ×(1+`ripe_bonus` 0.6) = harvest-timing skill; Flourish lights on the garden (floor) and UPGRADES to `flourish_bonus_ripe` 0.42 when the field is RIPE (tending pays, no crater for a healer just keeping growths up). **THORNVEIL = SNAP-STREAK** — each Perfect Ward is a SNAP that ramps reflect `thorns_frac` 0.45 → `thorns_max` 0.90 over a 0–5 `thorn_charge`; Perfect burst + Briarheart wards scale with charge; a WILTED ward BREAKS the streak = a fighting-game combo meter on a healer. **BRIDGE:** Wildbloom refunds Sap/ally healed, Briarheart Sap/ward placed. **UI:** VerdanceGauge → thorn-charge pips + reflect% / ripe-garden gold pips + ripe-Flourish line; RaidFrame gold "ripe" HoT gem (gated `ripe`); "SNAP ×N" center pops. **Bands (200 seeds):** Ashmaul ~99, Swarmheart 100 (design), Hollowking grove 98/93.5/**79** · thorn 97/91.5/**85** — within ~2pp of M7.2 intent, sharper aggressive-thorn / sustain-grove split. Gates: determinism PASS; only bloomweaver files + bloomweaver-only `verdance_gauge` + gated shared `raid_frame` → other class SIMS byte-identical; bloomweaver+mender+raid smokes PASS. Used **`scripts/psim.sh`** (~7×) for all bands. *(class-fun session)*
- ☑ 2026-07-03 · `bulwark-chainredline` (class-fun ④) · §CLASSES — **MERGED to main (`74ce85e`).** Bulwark GUARD CHAIN vs REDLINE (the tank's two specs finally different SHAPES, not the same dump-a-counter button): **WARDEN = GUARD CHAIN** — Counter is a STREAK you protect: every won read (parry / PERFECT beat / held feint) links it; EATING a heavy/crush you should've parried DROPS it to HALF; each link passively boosts ALL outgoing (`chain_dmg_per` 0.06 — Riposte-as-passive); Vindicate cashes the whole chain; `counter_max` 5→6. **JUGGERNAUT = REDLINE** — at cap you hit OVERDRIVE (dodging no longer dumps Momentum — the redline reward, and the fix for "my own dodge kills my snowball"); Avalanche is a PARTIAL vent (`avalanche_vent` 6, keep riding) not a self-destruct dump. **Surgical** — reuses `counter`/`momentum` vars so every Warden/Jugg boon + slot-verb piece keeps working. **UI:** SpecGauge Warden = chain link-line + "+X% DMG" + "CHAIN BROKEN" flash; Jugg = overheat band + OVERDRIVE halo/label; chain_break center-pop; tooltips/blurbs. **Bands (200 seeds):** Warden gradient intact + faster (Devourer loose 74→78, Duelist good 94→99, loose still 69); Jugg 100% everywhere (its known out-races property) with the new ride-and-vent loop. Gates: determinism PASS (bulwark + all 4 raid Seals); only bulwark data/view + shared view `spec_gauge` → other class SIMS byte-identical; ui_smoke + raid smoke PASS; **raid bands preserved** (tank uses BulwarkKit so it changed too — Riftmaw 100/100/95, Mythos 100/97/47, ~intent). **DEFERRED: SUNDER** (a boss-side team-visible break meter — an engine change collapsing Riposte+Exposed; deserves its own guarded/retuned pass) + live Guard-rune strip + flat-filler retirement. Used `psim.sh` throughout. *(class-fun session)*
- ☑ 2026-07-03 · `class-fun-reworks` · §CLASSES — **ALL FOUR LEADS DONE & MERGED** (memory `class-fun-deepdive`; artifact brief). Per-class Aspect-identity reworks that make each class's two builds feel like different characters: **① Twinfang Two-Metronomes (`fa3bd36`)** · **② Mender Litany (`99c9cca`)** · **③ Bloomweaver Ripen-vs-Snap (`b626706`)** · **④ Bulwark Chain-vs-Redline (`74ce85e`)**. Each: own branch, determinism PASS, bands retuned to intent, other-class sims byte-identical, smokes green. NEXT: Bill playtests; tune from feel. *(class-fun session)*
- ☑ 2026-07-03 · `bulwark-sunder` (class-fun deferred) · §CLASSES — **MERGED to main (`efcd089`).** **Bulwark SUNDER** — the tank's boss-side, team-visible BREAK METER. Engine (guarded by `boss.sunder>0` → every non-Bulwark fight byte-identical, VERIFIED: twinfang seed-1 checksum bit-identical to main): `BossState.sunder` + `TuningConfig.sunder_k` 0.06/`sunder_decay` 1.1/`sunder_max` 5; `damage_boss` amps ALL damage ×(1+sunder·k) while cracked (co-op "break the wall"); `update()` bleeds it. Fed ONLY by won reads (skill-gated → preserves the gradient): Warden = spiky parry/read/beat chunks; Juggernaut = a slow FLOOR while riding high Momentum — same meter, two fill curves. UI: fracture pips on the boss bar (hidden at 0), boss flinches on a crack, WALL BROKEN pop. Bands preserved (expert a touch faster = skill reward, loose unchanged). Determinism PASS (bulwark+raid), smokes green. *(class-fun session)*
- ☑ 2026-07-03 · `class-fun-bolts` (class-fun deferred) · §CLASSES — **MERGED to main (`be4e329`).** **Twinfang 'Lingering Venom'** boon: Rupture becomes a SIP (0.62× detonation, keeps HALF the cocktail + Synergy) vs the default SLAM — the sip/slam decision as a draft choice. **Mender Blood Pact re-cut**: bloodied allies feed the healer 50% MORE Nerve instead of a flat +0.35 ally-damage stat (rewards the gamble via YOUR resource; base Brinkwarden bloodied-damage unchanged). Both boon-gated → boonless checksums BIT-IDENTICAL to main; determinism PASS; smokes green. **STILL DEFERRED (genuine low-value follow-ups):** live "YOUR GUARD" proc-rune strip (slot-verb combo stays tooltip-only in combat) · flat-filler boon retirement (cleanup — risky boon churn) · Twinfang Flow-milestone procs (marginal; only drafted-payload builds; retune risk). *(class-fun session)*
- ☑ 2026-07-03 · `fight-seed-map-fix` · §CODE AUDIT — MERGED to main (`ac386bf`), synced to Windows. `fight_seed()` folds `map_node` in map mode so same-index nodes stop replaying the identical fight; `map==null` byte-identical (draft_sim + map_sim + class sims verified). `sim/fight_seed_probe.gd` guards it. *(this session)*
- ☑ 2026-07-03 · `sim-parallel` · §TOOLING — MERGED to main (`f9d30d3`). `scripts/psim.sh <sim> [seeds] [jobs]` shards a class sim's seeds across cores (byte-identical `--seed0` offset; probes gated to shard 0) → **~4.5× per sim** (bloomweaver 147s→33s @100/8-shard). Merged CSV row-identical to a single run; default runs byte-identical (bulwark/voidcaller/twinfang verified). Raid sim not wired (different CSV schema). *(this session)*
- ☑ 2026-07-03 · `raid-sim-parallel` · §TOOLING — MERGED to main (`fed49cf`). raid_sim now shards under `psim.sh` too (**~4.9×**: 119.7s→24.6s @30 seeds/8 shards, 4 Seals×3 tiers). Byte-identical `--seed0`; merge is header-driven (groups before `seed`, won/ttk by name → both schemas); extra args forwarded (`psim.sh raid_sim 300 8 --boss=mythos`). *(this session)*
