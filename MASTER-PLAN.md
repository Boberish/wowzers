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
| Run loop + draft (Bulwark full; others "continue"-only) | 🟡 Bulwark-only draft |
| UI (Gilded Reliquary overhaul) | ✅ Done |
| 3D stage | 🟡 Bulwark vertical slice only |
| Co-op raid (R0/R1: any seat, any aspect, AI raiders) | ✅ Playable |
| Netcode (R2) | 🟠 IN FLIGHT (another session: `godot/net/`, `server/`, web export in `dist/`) |
| **Realms (raids = themed realms; Realm 1 "The Takeover" = AI irony)** | 🟠 Realm 1 in flight via `raid-seals`; solo reskin DE-SCOPED |
| **Raid Seals II–IV (online boss ladder: Mistral/Gemini/Claude-Mythos)** | 🟠 IN FLIGHT (this session, branch `raid-seals` — see §RAID SEALS) |
| **Draft 2.0 / slot-verbs / token economy** | 🔴 NEW — planned (see Systems; design: `ASCENSION-STEAL-PLAN.md`) |
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

## RAID SEALS — the online boss ladder (first AI-Killer content) — IN FLIGHT (branch `raid-seals`)

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

**Engine additions (ALL guarded — solo content must stay byte-identical; frozen-baseline gate
running per the concurrent-sessions rule):**
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

**Acceptance bar:** six solo sims byte-identical vs frozen baseline; Vorathek raid checksums
unchanged per seed; `raid_sim` determinism PASS on all four Seals + sane skill bands
(Mistral ≥ Gemini ≥ Mythos win rates); `ui_smoke_raid` + `net_smoke` green.

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
- **MAP-3 (RAID FLOOR 1 — "RING 3: THE SHALLOW STACK", after `raid-seals` + net merge):**
  entry Seal = **VORATHEK** (tutorial fight at the gate) → 3 lanes × ~4 rows → **MISTRAL-7B** (Seal II) as the floor boss. Raid node kinds: SKIRMISH (a trash-pack fight = an **add wave without a boss** — direct reuse of `AddRes`), EVENT, COOLING, CACHE. One 401 backdoor (🔑 API Key on the long lane) that skips a row. *Later floors:* Ring 2 → GEMINI ULTRA, Ring 1→0 → CLAUDE MYTHOS behind "root access requires every credential shard."
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
- **A. Draft 2.0** (GREENLIT): synergy picks (1 of 3 offers must tag-match your build) + transform boons (top rarity = verb transforms, not +%) + rarity/pity (Haiku/Sonnet/Opus, rarity = frequency not caps). Bulwark first, then port with draft parity.
- **B. Slot-verbs PoC**: Guard = `[Trigger]+[Property]+[Payload]` mods; rewrite Bulwark's 17 boons as typed mods. **NO LOCKOUTS** — combos stack, rebalance the boss instead. **Scoping rule (locked):** pools stay per-class; mods must express through UI the class already has (new-UI mods get budgeted explicitly or cut). Cross-ASPECT flavor bleed allowed as rare spice only where the class UI already supports it (e.g. Tempo drafting a venom payload — Twinfang UI already renders poison).
- **C. Token economy**: skilled play mints TOKENS mid-run (from `state.diag`: perfect-parry streaks, no-avoidable-damage clears) → spend in draft (reroll / lock a slot / upsell rarity). Deterministic, per-seat.
- **D. Feeds the Trial Ladder** (below).
**Acceptance:** run-loop UI smokes; draft determinism when seeded; kit checksums byte-identical when boons absent.

## MODES & ENDGAME

- **Trial Ladder ("Versions")** — NEW: replay any boss at v1/v2/v3…; each version ADDS MECHANICS (extra string beats, feints, phases — never just +HP%), better rewards, fake patch notes. Deterministic engine ⇒ seed-verified leaderboards nearly free. Design vs `TuningConfig` + strings content.
- **Run modifiers** (Hades-Heat/Hardcore-Trials style): opt-in stacking difficulty for exclusive rewards — after Trial Ladder proves the scaling hooks.
- **Open ideas:** endless "Manastorm" mode; meta-progression (account tokens → cosmetic/QoL, losses still bank progress); daily seed challenge (same seed for everyone, leaderboard).

## GRAPHICS / PRESENTATION

**Now:** Gilded Reliquary 2D UI done; 3D stage = Bulwark slice (PoseRig procedural rigs, dais, VFX, reticle dial).
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
- ☐ 2026-07-02 · `raid-seals` · §RAID SEALS + Bosses + Engine — add waves (`AddRes`), cast chains, random personal beats (all guarded); three AI-themed raid bosses (MISTRAL-7B / GEMINI ULTRA / CLAUDE MYTHOS); lobby Seal pick. ⚠ small additive touches to `godot/net/` (spec `enc` field, lobby `boss` msg, protocol v2) — Online session please coordinate at merge. *(raid-seals session)*
- ☐ 2026-07-02 · `draft2` · §SYSTEMS — Draft 2.0 (Phase A: synergy tags, Haiku/Sonnet/Opus rarity + pity, transform boons, deterministic run-seeded drafts) + Token economy (Phase C: diag-minted Tokens, REROLL/UPSELL). Files: new `game/draft.gd`/`game/ui/draft_screen.gd`/`sim/draft_sim.gd`; `run_state.gd`, all 5 `*_boons.gd` + `*_kit.gd` (guarded one-liners) + `*_hud.gd` (draft/end screens, `_begin_fight` seed), `relic_card.gd`, `palette.gd`, `tuning_config.gd` (4 mint knobs). ⚠ shared-risk w/ `map1` (bulwark HUD) + `raid-seals` (tuning_config) — merging main in before merge-back. Slot-verbs (Phase B) NOT in scope. *(draft2 session)*
