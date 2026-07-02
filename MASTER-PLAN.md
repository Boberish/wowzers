# MASTER PLAN — Project Rift

**This is the coordination hub.** Current status, open work, claims, and ideas all live HERE.
`CLAUDE.md` keeps the stable rules (engine law, how to run things, past milestone history); this file is the *living state*. When Bill says "work on X", X is a section of this file.

---

## HOW TO WORK (process rules — every agent, every task)

1. **Read this file first.** Find your section, check the Coordination Log for conflicts.
2. **Claim your work**: add a line to the Coordination Log (`date · branch · section · what`) *before* starting.
3. **Always work in a git worktree** — never directly on `main`:
   `git worktree add ../wow-<task> -b <task>` → work there → commit early and often.
4. **Sync often**: merge `main` into your branch regularly (at least before merging back) so parallel work never drifts far apart.
5. **Verify before merging back**: run the acceptance bar for your section (listed per-section below; default = the class sims + UI smokes you touched, determinism PASS, and byte-identical checksums for any engine change).
6. **Merge to `main`, then UPDATE THIS FILE** — status, what changed, what's next, tick the Coordination Log entry. A task isn't done until the master plan says so.
7. Engine law is unchanged and non-negotiable: `CombatCore` stays a pure, deterministic, Node-free reducer (see CLAUDE.md).
8. Cleanup: `git worktree remove ../wow-<task>` when merged.

---

## OVERALL PROGRESS

| Area | State |
|---|---|
| Combat engine (pure reducer, strings, threat) | ✅ Solid, regression-gated |
| Classes (Bulwark, Mender, Twinfang, Voidcaller, Bloomweaver) | ✅ All playable + verified |
| Bosses (15 solo + Vorathek raid) | ✅ Done, tuned bands |
| Run loop + draft (all 5 classes) | ✅ Draft 2.0 everywhere — synergy slot, Haiku/Sonnet/Opus + pity, Tokens (merged 2026-07-02, see §SYSTEMS) |
| UI (Gilded Reliquary overhaul) | ✅ Done |
| 3D stage | 🟡 Bulwark vertical slice only |
| Co-op raid (R0/R1: any seat, any aspect, AI raiders) | ✅ Playable |
| Netcode (R2/R2.5: lockstep WS server, Docker/tunnel deploy kit, Windows + browser clients) | ✅ DONE & verified (cross-OS identical checksums; see CLAUDE.md R2/R2.5) |
| **Realms (raids = themed realms; Realm 1 "The Takeover" = AI irony)** | 🟠 Realm 1 in flight via `raid-seals`; solo reskin DE-SCOPED |
| **Raid Seals II–IV (online boss ladder: Mistral/Gemini/Claude-Mythos)** | ✅ DONE, merged `ac1aa25` (adds/chains/rand-beats engine + 3 bosses + lobby Seal pick, protocol v2 — see §RAID SEALS) |
| **Draft 2.0 + Tokens + slot-verbs (Phases A+B+C)** | ✅ ALL MERGED 2026-07-02 — build-your-Guard PoC live on Bulwark; porting slot-verbs to the other 4 verbs is the open follow-up (see §SYSTEMS) |
| **Trial Ladder ("Versions")** | 🔴 NEW — planned |
| **Maps ("The Topology" — AtO-style node runs)** | 🟡 MAP-1 MERGED (solo PoC on Bulwark, Realm-1 skin) — MAP-2/3 open |

---

## REALMS & THEMES — every raid is a themed realm

**The frame (Bill, 2026-07-02):** the game has MANY raids over time, and **each raid is its own themed REALM** — the Rift tears into somewhere new each time. Solo classes/bosses KEEP the core dark-fantasy Rift identity (the solo reskin is DE-SCOPED — see salvage note below). A realm = a boss ladder (Seals) + a Topology map skin + a joke register + a supporting cast. Realm bibles live here.

**Global meta-layer (realm-independent, keep — it's the subtle wink):** draft currency = **TOKENS** ("spend them responsibly"), rarity tiers = **Haiku / Sonnet / Opus**. Everything else AI-flavored is Realm 1 scoped.

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
- **MAP-2 (depth):** tickets, secret rooms, ELITE, MARKET (token stub), 10+ events, art pass.
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
  **3b (online nav — leader picks the node in the lobby, fracs+wounds ride the spec) is NEXT,
  unclaimed**; the map dict is wire-serializable by design. Later floors: Ring 2 → GEMINI
  ULTRA, Ring 1→0 → CLAUDE MYTHOS behind "root access requires every credential shard" —
  those floors should lean hard on wounds (their fights actually kill raiders).
- **Acceptance (all phases):** map-gen determinism; solo sims + raid checksums byte-identical with maps off; smokes green.

## CLASSES

**Now:** 5 classes done & verified (2 tanks-of-verbs pattern: mitigate/keep-alive/rhythm/interrupt/anticipate). Aspect pairs everywhere. Raid seats for all 4 roles.
**Next up (any agent can claim):**
- **Draft parity**: Mender/Twinfang/Voidcaller/Bloomweaver have boon POOLS but only Bulwark has the full between-fight draft in its run loop. Port the draft loop to all classes (prereq for Draft 2.0 everywhere).
- **Theme banter pass per class** (ally callouts, tooltip jokes) — after Theme Bible lands.
**Open ideas** (from Ascension research, parked until a 6th/7th class is wanted):
- Self-brink DPS: gauge climbs = more damage, cap = self-destruct (Cultist Insanity / Stormbringer Static archetype). Verb: *ride the redline*. Strong fit.
- Over-defend punishment tank layer (Mountain King self-stun) — could bolt onto Bulwark as a boon/mod instead.
- Imposed-rhythm caster (Runemaster attunement auto-cycle) — kit rotates on a clock you don't control.
- ~~Rewind/Chronomancer verb~~ — PARKED (unintuitive in a reaction game; revisit as a rare relic at most).
**Acceptance:** class sims determinism PASS + bands sane; UI smoke green.

## BOSSES & ENCOUNTERS

**Now:** 15 solo bosses + Vorathek raid, all with M7.2 strings, tuned skill bands.
**Next up:**
- ~~Theme reskin of solo bosses~~ — DE-SCOPED 2026-07-02 (solo stays rift-fantasy; the AI identities moved to the Realm 1 casting pool, see §REALMS).
- **Aura-add mechanic** (from Manastorm): a mid-fight elite that BUFFS the boss until killed — creates a real add-vs-boss decision AND attacks the R3 "one telegraph source" interrupt problem. Needs engine work (second cast source) — design against `RAID-PLAN.md` R3.
- **OPUS phase design** (Helpful/Harmless/Honest) — the raid finale deserves authored phases, not just the curse.
**Open ideas:** boss "patch notes" as Trial-Ladder flavor; a Stable-Diffusion illusion miniboss (all feints, low HP).
**Acceptance:** boss sims determinism PASS, bands within intent, byte-identical for untouched bosses.

## SYSTEMS — Draft 2.0, slot-verbs, token economy (design doc: `ASCENSION-STEAL-PLAN.md`)

**Phases (sequenced, each mergeable alone):**
- **A. Draft 2.0 — ✅ DONE (merged 2026-07-02, branch `draft2`), ALL FIVE CLASSES at once** (draft parity already existed — the old "Bulwark-only" note was stale). ONE shared roll in `game/draft.gd` (per-class `*_boons.gd` are now data catalogs + `apply()` + `aspect_tags()`): offer slot 0 = **synergy slot** (guaranteed tag-match vs loadout ∪ owned boons ∪ aspect vocab), rarity **Haiku .70 / Sonnet .25 / Opus .05** as *frequency only* (no caps, no lockouts) with opus pity (+5pp/dry draft, hard-forced by draft 6 — proven worst drought = 5), **deterministic**: RunState carries `run_seed` + a draft-only `DetRng`; per-fight combat seeds are closed-form `fight_seed()` (spends can't shift combat) — whole runs now replay from `(run_seed, picks, spends)`, the Trial-Ladder leaderboard prerequisite. **6 new Opus transforms** (`retaliation`, `dancersgrace`, `nullbrand`, `voidfeast`, `sanctifiedward`, `evergreencycle`) + reclassified opus (`vindInterrupt`, `riposteChain`, `syncopation`, `contagion`, `secondwind`, `verdantsurge`), all `_b()`-gated. UI: `game/ui/draft_screen.gd` (shared screen: token plaque, UPSELL under each card, REROLL plate, ✦ RESONANT mark), RelicCard rarity frames (opus breathing ring), Palette HAIKU/SONNET/OPUS. Works inside the Topology map (salvage drafts pass a custom headline; mint runs in map mode).
- **B. Slot-verbs PoC — ✅ DONE on Bulwark (merged 2026-07-02, branch `slot-verbs`); PORT TO THE OTHER FOUR VERBS = the open follow-up.** Build-your-Guard as **cross-product pieces, NO LOCKOUTS** (Bill-locked): **TRIGGER** cards add proc moments (`trigRead` feint READ · `trigThird` every 3rd guard · `trigBeat` PERFECT beat · `trigRiposte` landed Riposte, Warden pool; each carries a +4-rage built-in), **PAYLOAD** cards fire on EVERY proc moment — innate proc = any clean negate — (`payReflect` 35 · `payHeal` 30 · `payRage` 8 · `payExpose` 1.2s/+15% · `payCounter` Warden · `payMomentum` Jugg), **PROPERTY** cards reshape the verb (`propSwift` cd ×0.8 · `propWide` window ×1.3 · **opus `propCharge` "Twin Guard"** 2nd charge via post-press `defense_ready_tick` rewrite + `upkeep` recharge — riposteChain precedent). Kit-side proc engine (`BulwarkKit._guard_proc`/`_trigger_fire`), all `_b()`-gated; knobs = `BulwarkConfig.mod_*`; catalog entries carry `slot:`, guard-adjacent classics labeled `slot:"property"`. **LOCK · 1⏣ = hold-through-reroll** (Bill-locked): `Draft.lock` + `Draft.reroll_kept(run, offers, locked)` redraws only unlocked slots (locked ids excluded from redraw; empty locks ≡ classic reroll stream). UI within existing surfaces: slot captions on RelicCard ("OPUS · GUARD PROPERTY"), ◆ HELD banner + LOCK/RELEASE buttons on DraftScreen, YOUR GUARD assembled rules in the guard tooltip + the Grimoire tome's guard entry, Twin Guard charge pips on the rune-socket. **Proof (`_prove_guard_mods`, Duelist@loose, 120 paired seeds): boonless 74.2% → modded 92.5% win-rate, TTK 57.9s → 38.5s, 7.7 procs/run, modded determinism PASS** — two runs of the same class now build tangibly different verbs. Gates: 6 sims byte-identical boonless vs frozen baselines · draft_sim ALL OK (incl. 5-class LOCK matrix) · 5 smokes · WSLg shots. **Scoping rule for the port (still locked):** pools stay per-class; mods express through UI the class already has; cross-aspect bleed = rare spice only.
- **C. Token economy — ✅ DONE (merged with A)**: kits bump class-signature skill signals into `seat.diag`/`state.diag` (`negate` / `perfect_strike` / `clean_kick` / `dispel` / `perfect_ward` — diag is never checksummed, so byte-identical sims held); `Draft.mint(state, class)` at fight end = footwork (PERFECT+READ per `mint_per_grades` 3) + signature (per `mint_per_signature` 4) + flawless bonus (no miss/bait/whiff), cap 3/fight (knobs on TuningConfig). Spends: REROLL 1⏣ / UPSELL 2⏣ ("lock a slot" waits for B). Refused spends consume no rng (test-proven).
- **D. Feeds the Trial Ladder** (below).
**Acceptance (met + how to re-run):** `sim/draft_sim.gd` (determinism transcripts incl. spends, synergy guarantee, pity bound, spend legality, mint table + seeded-fight integration) ALL OK · all 5 class sims + raid sim **byte-identical stdout+CSV** vs pre-change baselines (diag-only kit touches; 300 seeds) · 5 UI smokes green · WSLg visual probe `sim/screenshot_draft.gd` (5 draft screens + end screen, pity-forced opus) rendered clean.

## MODES & ENDGAME

- **Trial Ladder ("Versions")** — NEW: replay any boss at v1/v2/v3…; each version ADDS MECHANICS (extra string beats, feints, phases — never just +HP%), better rewards, fake patch notes. Deterministic engine ⇒ seed-verified leaderboards nearly free. Design vs `TuningConfig` + strings content.
- **Run modifiers** (Hades-Heat/Hardcore-Trials style): opt-in stacking difficulty for exclusive rewards — after Trial Ladder proves the scaling hooks.
- **Open ideas:** endless "Manastorm" mode; meta-progression (account tokens → cosmetic/QoL, losses still bank progress); daily seed challenge (same seed for everyone, leaderboard).

## GRAPHICS / PRESENTATION

**Now:** Gilded Reliquary 2D UI done; 3D stage = Bulwark slice (PoseRig procedural rigs, dais, VFX, reticle dial).
- **Telegraph timing UI overhaul ("the Judgment Channel") — DONE, merged 2026-07-02.** Bill's brief: the circle-sweep timing UI read too vague — needed a narrow "aim here" mark, graded feedback around it, verdict satisfaction, and quick-succession clarity, at paid-game quality. Shipped `game/ui/strike_judge.gd` (**StrikeJudge**): a linear precision instrument under every dial that fuses the ENEMY CAST BAR with a fixed gilded **IMPACT GATE** — hairline aim mark, stained-glass graded bands (mint PERFECT / gold GOOD or true parry window / steel GRAZE / violet clean-kick), incoming swings & string beats as comet-gems approaching at **constant px/sec (PPS 250)** so timing muscle-memory transfers across attacks and HUDs, per-press **verdict stamps** (ghost needle + burst + gold rays at your exact press spot), a **grade-history gem rail** (last 8 judgments — the quick-succession answer), feint DON'T-PRESS hatch veil, dodge-lockout LOCKED veil, heal/empower channel fill, parked-comet countdown for long winds (ULTRATHINK-ready). Compact mode (name inside the channel) for the healer HUDs. Classic parries get a cosmetic proximity grade ("PERFECT PARRY!" ≤0.14s) — negation stays binary engine-truth. Dial kept as boss presence; gained a 12-o'clock impact hairline + classic perfect sliver. Wired into ALL SIX HUDs; twinfang/raid rhythm bar and raid/voidcaller player cast bar moved to the player's column (your instrument under you, theirs under the boss). **Fixed a pre-existing feedback bug:** string dodges pop twice ("PARRY!"+"PERFECT!" overlapping garbage) — echo negates (no `seat` key) no longer pop. View-only, ZERO engine files touched. Verified: all 6 UI smokes + map smoke green ×2, bulwark sim determinism PASS, screenshot probes (strings/3D/2D/raid/full tour) eyeballed at 1080p — layouts clean in every HUD. **Next (unclaimed):** classic-parry perfect could earn a real payoff (engine change, needs byte-identical gate + retune); judge could render add-wave/chain-verse counters for Seals II–IV.
**Next up:**
- Wire the other 4 HUDs to CombatStage3D (~15 lines each, pattern documented in CLAUDE.md) + a rig per class.
- **Robot re-rig**: per-boss silhouettes as ROBOTS/COMPUTERS (theme!) — replaces the `variant()` stopgap and is easier than organic sculpts. CAPTCHA-9 = a turnstile with an eye; GEMINI = two identical chassis; OPUS = a server-cathedral.
- Blender/GLTF pipeline later (art replaces rig subclasses; `act()`/`windup()` contracts stay).
**Open ideas:** screen transitions; binds/spellbook art pass; theme the Gilded Reliquary gold → circuit-board copper/emerald-terminal accents (light touch, don't redo).
**Acceptance:** `sim/stage3d_tour.gd` / `screenshot_tour.gd` render clean (WSLg), determinism ×3 untouched.

## ONLINE (R2+)

**IN FLIGHT — another session owns this** (`godot/net/` client/server/protocol, `server/` Docker+tunnel, `dist/web` export). Per `RAID-PLAN.md`: server-authoritative WebSocket, headless Godot server, browser WASM client.
**Do not touch without checking the Coordination Log.** When it lands: netcode session should update this section + Overall Progress.
**Queued behind it:** R3 raid content/economy (needs aura-add / parallel cast sources — see Bosses).

## TOOLING & INFRA

**Now:** headless sims per class, UI smokes, screenshot tours, this repo is now GIT (baseline 2026-07-02). Worktree workflow live (see HOW TO WORK).
**Next up:** CI-ish script that runs all sims + smokes in one command (the merge-back gate, `tools/verify-all.sh`); decide CSV output home (`godot/out/` is gitignored).
**Open ideas:** auto-post sim bands into this file; seed-verified replay files for leaderboards.

---

## CURRENT / OPEN IDEAS (parking lot — promote into a section when claimed)

- Game title candidates: *UNPLUGGED*, *Ctrl+Alt+DEFEAT*, *KILLSWITCH*, *RIFT: Do Not Trust Its Outputs* (these read Realm-1-flavored now; a realm-neutral title may fit better).
- **Future realm seeds** (each = Seals ladder + map skin + joke register): *THE BUREAUCRACY* (paperwork hell — stamp-golems, queue mechanics, "please hold" telegraphs); *THE UNDERCROFT* (necropolis played straight — the contrast realm); *THE DEEP* (abyssal leviathans, pressure as attrition); *THE CLOCKWORK COURT* (fae mechanisms, rhythm-heavy strings); *THE KAIJU WEATHER STATION* (one enormous boss per floor).
- Rewind verb (deterministic-engine showpiece) — parked, see Classes.
- Positive run-affixes ("Mythical Boons") — fold into Run modifiers when built.
- ~~Second raid boss~~ — claimed: §RAID SEALS (branch `raid-seals`). Healer-aggro rules for co-op still open (R0 caveats list).
- Mender's own draft pool (currently continue-screen only) — subsumed by Draft parity above.

## COORDINATION LOG (claim before you start, tick when merged + plan updated)

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
- ☑ 2026-07-02 · `draft2` · §SYSTEMS — MERGED to main (`c05d2e8`): Draft 2.0 (Phase A) + Token economy (Phase C), all five classes. Gates: draft_sim ALL OK · 5 class sims + raid **byte-identical** vs frozen baselines at every step (raid's post-merge diff = raid-seals' own new sim content; Riftmaw seed-1 checksum matched exactly) · smokes + map_sim green post-merge (map salvage drafts now ride DraftScreen w/ custom headline; mint runs in map mode) · WSLg draft screens verified. Plan updated (§SYSTEMS, Overall Progress). Phase B (slot-verbs + lock-a-slot spend) is the open follow-up. *(draft2 session)*
- ☑ 2026-07-02 · `slot-verbs` · §SYSTEMS Phase B — MERGED to main (`7860efa`): build-your-Guard PoC (cross-product TRIGGER×PAYLOAD×PROPERTY pieces, opus Twin Guard) + LOCK·1⏣ hold-through-reroll. Gates: 6 sims **byte-identical** boonless vs fresh baselines · `_prove_guard_mods` 74.2%→92.5% + determinism PASS · draft_sim ALL OK (5-class LOCK matrix) · 5 smokes · WSLg shots (locked draft / Grimoire YOUR GUARD / live charge pips). Merge grafted YOUR GUARD into the new Grimoire tome's guard entry. Plan updated; port-to-other-verbs is the open §SYSTEMS follow-up. *(draft2 session)*
