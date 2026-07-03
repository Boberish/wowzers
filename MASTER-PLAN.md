# MASTER PLAN — Project Rift

**This is the coordination hub.** Current status, open work, claims, and ideas all live HERE.
`CLAUDE.md` keeps the stable rules (engine law, how to run things, past milestone history); this file is the *living state*. When Bill says "work on X", X is a section of this file.

---

## HOW TO WORK (process rules — every agent, every task)

1. **Read this file first.** Find your section, check the Coordination Log for conflicts.
2. **Claim your work**: add a line to the Coordination Log (`date · branch · section · what`) *before* starting.
3. **Always work in a git worktree** — never directly on `main`:
   `git worktree add ../wow-<task> -b <task>` → work there → commit early and often.
4. **Sync often**: merge `main` into your branch regularly (at least before merging back) so parallel work never drifts far apart. **⚡ If your worktree predates 2026-07-03, `git merge main` NOW** — it brings **`scripts/psim.sh`** (runs any of the 5 class sims + `raid_sim` sharded across cores, **~5×** faster: `scripts/psim.sh <sim> [seeds] [jobs] [-- --boss=…]`). Prefer it over a single-threaded `godot --headless … --script res://sim/<sim>.gd -- --seeds=N`. It sims **your** worktree's code (self-locating root), so you still need to be synced. A missing/old `psim.sh` fails safe (no wrong results); output is byte-identical to a single run.
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
| Netcode (R2/R2.5: lockstep WS server, Docker/tunnel deploy kit, Windows + browser clients) | ✅ DONE & verified (cross-OS identical checksums; see CLAUDE.md R2/R2.5). **+ MAP-3b: online co-op map traversal (protocol v3, `127ab2c`)** — server owns the campaign, leader routes, fights carry state |
| **Realms (raids = themed realms; Realm 1 "The Takeover" = AI irony)** | 🟢 Realm 1 PLAYABLE end-to-end: 3-floor RING descent (MISTRAL→GEMINI→MYTHOS) w/ GATE exams + shard gate (MAP-3c `fafaf1a`). Online nav (3b) + Realm 2 open |
| **Raid Seals II–IV (online boss ladder: Mistral/Gemini/Claude-Mythos)** | ✅ DONE, merged `ac1aa25` (adds/chains/rand-beats engine + 3 bosses + lobby Seal pick, protocol v2 — see §RAID SEALS) |
| **Draft 2.0 + Tokens + slot-verbs (Phases A+B+C)** | ✅ COMPLETE 2026-07-02 — build-your-verb live on ALL FIVE classes (Guard/Rhythm/Kick/Triage/Garden), LOCK/REROLL/UPSELL economy, 5 opus charge/transform capstones (see §SYSTEMS). Next §SYSTEMS frontier: Trial Ladder (D) |
| **Trial Ladder ("Versions")** | 🔴 NEW — planned (now also the RANK track + version-gated loot rows, see `PROGRESSION-PLAN.md`) |
| **Persistent progression (loot tables / OATHS / Ledger / standing)** | 🟡 **GEAR-1 MERGED 2026-07-03** (`866592f` — Curio drops/equip/scrap/unlock store live on the raid campaign, byte-identical gearless). Design: `PROGRESSION-PLAN.md` + `GEAR-CATALOG.md`. GEAR-2 (oaths/Ledger UI) claimable |
| **Maps ("The Topology" — AtO-style node runs)** | 🟡 MAP-1 MERGED (solo PoC on Bulwark, Realm-1 skin) — MAP-2/3 open |
| **GAME SHAPE — RAID-ONLY** | 🔒 LOCKED 2026-07-03 (see §GAME SHAPE) — one game; solo campaign retired to a PRACTICE card; raid-first law |

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

**Killed:** solo campaign surface · solo maps ×5 (cancelled unspent) · new solo bosses ·
solo-only features · the solo draft-run mode (drafts live in the Topology, where they already run).
**Frozen:** the five solo class HUDs (no further polish; personal gates run through `raid_hud`'s
existing per-seat class bands). **Kept:** all 15 boss content files (the casting pool, §REALMS
table) · the six class sims (regression spine — infra, not product) · boss-select as practice/debug.
**Front door (the ONLY player flow — reaffirmed with Bill 2026-07-03):** ONE **PLAY** button
(Play *is* the raid — it's the only mode) → **pick your CLASS** (which seat you take) → **pick your
SUB-CLASS** (Aspect) → **pick the RAID** (one for now: Realm 1 · The Takeover) → play. No mode
select, no "solo vs co-op" fork (AI fills empty seats; PLAY ONLINE is a lobby toggle *inside* the
raid, not a separate mode). The old `main_menu` / per-class `*_main.tscn` solo entries + the
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
- **MAP-2 (depth) — 🟢 PARTLY DONE (tickets + ring identity + events, `d2e51ea`); ELITE/MARKET/secret-rooms/art still open.** All map depth lands on the RAID floors (the Bulwark solo map stays a practice fossil). **DONE (raid-richness):** **TICKETS** — pickup→turn-in quests (`RunMap` `n_tickets`/`tickets[]` + `ticket_open`/`ticket_close` payloads, all guarded off = byte-identical solo map) resolved in `raid_hud._ticket_at` with rewards in the wound-attrition economy (repair-sector / integrity / refuel / patch, reused `_apply_map_fx`) + a **SPRINT-RETRO** bonus for closing every ticket on a floor; placed same-lane-forward so closeable by construction (`raid_map_sim._prove_tickets`: placement-det + closeable 40/40·80/80·80/80 PASS). Per-floor counts in `RaidContent.FLOORS` (R3:1/R2:2/R0:2). **Ring identity** — `MapContent.realm_title/sub(ring)` (user space → middleware → root), ring-aware `MapScreen` header + open-ticket list + toast + ticket node badges. **Expanded events** — +5 (helpdesk / model graveyard / prompt injection / rollback daemon / overtime daemon); the SOLO pool is FROZEN at the original 6 via `event_ids()` (pool size shifts rng draws → byte-identity), raid floors pull `raid_event_ids()` (all 11). Verified: raid_map_sim all floors PASS; solo map_sim byte-identical (5.90 nodes/20 keys/6 backdoor); ui smokes green; combat untouched. **STILL OPEN:** secret rooms, **ELITE** nodes, **MARKET** (needs GEAR loot to stock), 10+ events, map art pass, route-agnostic objectives.
- **GATE nodes (Tier 1 personal exams, §GAME SHAPE) — ✅ DONE, merged 2026-07-03.**
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
- **Acceptance (all phases):** map-gen determinism; solo sims + raid checksums byte-identical with maps off; smokes green.

## CLASSES

**Now:** 5 classes done & verified (2 tanks-of-verbs pattern: mitigate/keep-alive/rhythm/interrupt/anticipate). Aspect pairs everywhere. Raid seats for all 4 roles.
**Game-shape note (2026-07-03):** the per-class solo gauntlets are PRACTICE surfaces now (§GAME SHAPE) — class work targets the raid seats first; kit changes still gate on the class sims as always.
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

**Now:** 15 solo bosses + Vorathek raid + Seals II–IV, all with M7.2 strings, tuned skill bands.
**Game-shape note (2026-07-03):** the 15 solo bosses are the **personal-content casting pool** — promote on demand as Tier-1 GATE duels / Tier-2 owned adds / Tier-3 split-phase exams (§GAME SHAPE + the §REALMS identity table). No new solo-only bosses.
**Next up:**
- ~~Theme reskin of solo bosses~~ — DE-SCOPED 2026-07-02 (solo stays rift-fantasy; the AI identities moved to the Realm 1 casting pool, see §REALMS).
- **Aura-add mechanic** (from Manastorm): a mid-fight elite that BUFFS the boss until killed — creates a real add-vs-boss decision AND attacks the R3 "one telegraph source" interrupt problem. Needs engine work (second cast source) — design against `RAID-PLAN.md` R3.
- **OPUS phase design** (Helpful/Harmless/Honest) — the raid finale deserves authored phases, not just the curse.
**Open ideas:** boss "patch notes" as Trial-Ladder flavor; a Stable-Diffusion illusion miniboss (all feints, low HP).
**Acceptance:** boss sims determinism PASS, bands within intent, byte-identical for untouched bosses.

## SYSTEMS — Draft 2.0, slot-verbs, token economy (design doc: `ASCENSION-STEAL-PLAN.md`)

**Phases (sequenced, each mergeable alone):**
- **A. Draft 2.0 — ✅ DONE (merged 2026-07-02, branch `draft2`), ALL FIVE CLASSES at once** (draft parity already existed — the old "Bulwark-only" note was stale). ONE shared roll in `game/draft.gd` (per-class `*_boons.gd` are now data catalogs + `apply()` + `aspect_tags()`): offer slot 0 = **synergy slot** (guaranteed tag-match vs loadout ∪ owned boons ∪ aspect vocab), rarity **Haiku .70 / Sonnet .25 / Opus .05** as *frequency only* (no caps, no lockouts) with opus pity (+5pp/dry draft, hard-forced by draft 6 — proven worst drought = 5), **deterministic**: RunState carries `run_seed` + a draft-only `DetRng`; per-fight combat seeds are closed-form `fight_seed()` (spends can't shift combat) — whole runs now replay from `(run_seed, picks, spends)`, the Trial-Ladder leaderboard prerequisite. **6 new Opus transforms** (`retaliation`, `dancersgrace`, `nullbrand`, `voidfeast`, `sanctifiedward`, `evergreencycle`) + reclassified opus (`vindInterrupt`, `riposteChain`, `syncopation`, `contagion`, `secondwind`, `verdantsurge`), all `_b()`-gated. UI: `game/ui/draft_screen.gd` (shared screen: token plaque, UPSELL under each card, REROLL plate, ✦ RESONANT mark), RelicCard rarity frames (opus breathing ring), Palette HAIKU/SONNET/OPUS. Works inside the Topology map (salvage drafts pass a custom headline; mint runs in map mode).
- **B. Slot-verbs — ✅ DONE, ALL FIVE VERBS (Bulwark PoC merged `7860efa`, port to the other four merged 2026-07-02 branch `slot-verbs-port`).** The port (same cross-product/no-lockouts pattern, ~8 pieces/class, kit-side proc engines, all `_b()`-gated): **Twinfang build-your-RHYTHM** (innate proc = PERFECT Strike; Ghost Step/Killing Tempo/Beat Dancer · Razor Echo/Quickblood/Red Harvest · Wide Tempo + opus **Twin Step** 2nd dodge charge) · **Voidcaller build-your-KICK** (innate = landed interrupt; Resonant Break/Starve the Choir/Void Step · Null Lash/Mind Siphon/Umbral Mending · Perfect Pitch + opus **Twin Void** 2nd kick charge) · **Mender build-your-TRIAGE** (innate = clutch heal on a sub-50% ally; Cleansing Rite/Aegis Echo/Graceful Step · Lightward/Deep Well/Lingering Grace · Swift Litany + opus **Benediction** every-5th-proc party bathe) · **Bloomweaver build-your-GARDEN** (innate = cashed Bloom; Barkward Echo/Seedsower/Rootstep · Bramble Burst/Sapwell/Petalfall · Quickening + opus **Deep Garden** payloads ×2 at 3+ Growths). `verb_summary()` renders the assembled verb in each class's verb tooltip (+ Grimoire tomes); Twin Step/Void pips ride the dodge/kick rune-sockets. **Port probes (`_prove_verb_mods`, 120 paired seeds @sloppy): rhythm 54.2→92.5 · kick 80.8→100 · triage 71.7→90.8 · garden 78.3→84.2, all deterministic.** Port gates: 6 sims byte-identical boonless · draft_sim ALL OK · 5 smokes · WSLg (tooltip + pips). ⚠ Port lesson (memory'd): `RunState` couples every class's content into every sim's compile graph — never edit ANY kit while ANY sim runs. The Bulwark PoC details: Build-your-Guard as **cross-product pieces, NO LOCKOUTS** (Bill-locked): **TRIGGER** cards add proc moments (`trigRead` feint READ · `trigThird` every 3rd guard · `trigBeat` PERFECT beat · `trigRiposte` landed Riposte, Warden pool; each carries a +4-rage built-in), **PAYLOAD** cards fire on EVERY proc moment — innate proc = any clean negate — (`payReflect` 35 · `payHeal` 30 · `payRage` 8 · `payExpose` 1.2s/+15% · `payCounter` Warden · `payMomentum` Jugg), **PROPERTY** cards reshape the verb (`propSwift` cd ×0.8 · `propWide` window ×1.3 · **opus `propCharge` "Twin Guard"** 2nd charge via post-press `defense_ready_tick` rewrite + `upkeep` recharge — riposteChain precedent). Kit-side proc engine (`BulwarkKit._guard_proc`/`_trigger_fire`), all `_b()`-gated; knobs = `BulwarkConfig.mod_*`; catalog entries carry `slot:`, guard-adjacent classics labeled `slot:"property"`. **LOCK · 1⏣ = hold-through-reroll** (Bill-locked): `Draft.lock` + `Draft.reroll_kept(run, offers, locked)` redraws only unlocked slots (locked ids excluded from redraw; empty locks ≡ classic reroll stream). UI within existing surfaces: slot captions on RelicCard ("OPUS · GUARD PROPERTY"), ◆ HELD banner + LOCK/RELEASE buttons on DraftScreen, YOUR GUARD assembled rules in the guard tooltip + the Grimoire tome's guard entry, Twin Guard charge pips on the rune-socket. **Proof (`_prove_guard_mods`, Duelist@loose, 120 paired seeds): boonless 74.2% → modded 92.5% win-rate, TTK 57.9s → 38.5s, 7.7 procs/run, modded determinism PASS** — two runs of the same class now build tangibly different verbs. Gates: 6 sims byte-identical boonless vs frozen baselines · draft_sim ALL OK (incl. 5-class LOCK matrix) · 5 smokes · WSLg shots. **Scoping rule for the port (still locked):** pools stay per-class; mods express through UI the class already has; cross-aspect bleed = rare spice only.
- **C. Token economy — ✅ DONE (merged with A)**: kits bump class-signature skill signals into `seat.diag`/`state.diag` (`negate` / `perfect_strike` / `clean_kick` / `dispel` / `perfect_ward` — diag is never checksummed, so byte-identical sims held); `Draft.mint(state, class)` at fight end = footwork (PERFECT+READ per `mint_per_grades` 3) + signature (per `mint_per_signature` 4) + flawless bonus (no miss/bait/whiff), cap 3/fight (knobs on TuningConfig). Spends: REROLL 1⏣ / UPSELL 2⏣ ("lock a slot" waits for B). Refused spends consume no rng (test-proven).
- **D. Feeds the Trial Ladder** (below).
- **E. Persistent progression — design LOCKED 2026-07-03, decisions of record in `PROGRESSION-PLAN.md`.** The meta-game: in-run boss loot (2 slots, rarity-first pity rolls reusing Draft 2.0 machinery, scrap→Tokens, MARKET buys) + permanent unlocks by *event* only — first-kill signature rows, **sworn OATHS** (renamed from "armed feats/quests" 2026-07-03 — swear the deed on the boss's Ledger page → keep it → the row joins your drop pool forever; severity I–III + stakes-scaled re-swear purses; Realm-1 skin = SLA, Blood Oaths = PIP), Trial-version rows, carried-out map schematics. **Realm-1 item/oath content lives in `GEAR-CATALOG.md`** (per-boss pages synergized with the class-fun reworks). Four persistent tracks (World/Pools/Rank/Breadth), **Monotonic Pool Law** (an unlock may never make a run worse — rarity-first rolls + synergy weighting + auto-scrap token floor), lane rule (boons = verb/agency · gear = fortune/new-buttons). **CUT (superseded):** RAID-PLAN's material economy (essences/Embers/Sigils/Riftcores/crafting), use-based mastery, pre-run loadouts, daily/weekly content. Phases GEAR-1…4 in the doc; **GEAR-1 MERGED 2026-07-03 (`866592f`, see Coordination Log)** — GEAR-2 (oaths + Ledger UI + purses) is the open follow-up. Gear noun locked: **CURIO** / Realm-1 **PERIPHERAL**.
**Acceptance (met + how to re-run):** `sim/draft_sim.gd` (determinism transcripts incl. spends, synergy guarantee, pity bound, spend legality, mint table + seeded-fight integration) ALL OK · all 5 class sims + raid sim **byte-identical stdout+CSV** vs pre-change baselines (diag-only kit touches; 300 seeds) · 5 UI smokes green · WSLg visual probe `sim/screenshot_draft.gd` (5 draft screens + end screen, pity-forced opus) rendered clean.

## MODES & ENDGAME

- **Trial Ladder ("Versions")** — NEW: replay any boss at v1/v2/v3…; each version ADDS MECHANICS (extra string beats, feints, phases — never just +HP%), better rewards, fake patch notes. Deterministic engine ⇒ seed-verified leaderboards nearly free. Design vs `TuningConfig` + strings content.
- **Run modifiers** (Hades-Heat/Hardcore-Trials style): opt-in stacking difficulty for exclusive rewards — after Trial Ladder proves the scaling hooks.
- **Open ideas:** endless "Manastorm" mode; ~~meta-progression (account tokens → cosmetic/QoL)~~ — superseded by `PROGRESSION-PLAN.md` (standing/crests + pool growth, no account currencies); ~~daily seed challenge~~ — CUT from core per `PROGRESSION-PLAN.md` (no timed content; deterministic-seed leaderboards stay a free opt-in someday).

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

**Now:** headless sims per class, UI smokes, screenshot tours, this repo is now GIT (baseline 2026-07-02). Worktree workflow live (see HOW TO WORK). **`scripts/psim.sh <sim> [seeds] [jobs] [-- extra args]`** shards any of the 5 class sims + raid_sim across cores (~4.5–5×; e.g. `psim.sh raid_sim 300 8 --boss=mythos`).
**Next up:** CI-ish script that runs all sims + smokes in one command (the merge-back gate, `tools/verify-all.sh`); decide CSV output home (`godot/out/` is gitignored).
**Open ideas:** auto-post sim bands into this file; seed-verified replay files for leaderboards.

## CODE AUDIT — open findings that NEED A DECISION (2026-07-03)

A fan-out audit (11 scoped agents + adversarial verify) ran 2026-07-03. The **24 non-controversial
fixes are DONE + merged** (`fd512f8`: dead code, per-frame perf, DRY — all byte-identical, see
Coordination Log). These **13 are confirmed real but change gameplay/checksums or are architectural**
— they need Bill's call, so they're parked here (severity in caps):

**Correctness bugs (in drafted-boon / raid paths):**
- ~~**HIGH — Mender `overflow` boon can SHRINK a shield**~~ — ✅ FIXED 2026-07-03 (`2c94233`): only grows + claims owner on real growth; `sim/mender_overflow_probe.gd` guards it. (No balance re-run needed — the boon simply stops destroying shields; boonless byte-identical.)
- ~~**MED — Bulwark `payExpose` boon is inert solo**~~ — ✅ FIXED 2026-07-03 (`4d3d9b6`): per-seat Exposed window + `outgoing_mult` +15%; `sim/bulwark_expose_probe.gd` guards it. Boonless byte-identical.
- ~~**MED — `fight_seed()` collides in Topology map mode**~~ — ✅ FIXED 2026-07-03 (`ac386bf`): folds `map_node` in map mode; `map==null` byte-identical; `sim/fight_seed_probe.gd` guards it.

**Netcode robustness (architectural):**
- **MED — desync checksum covers only boss HP + tick** (`combat_core.gd` :68): excludes seat HP/resources/absorb, threat, and `rng._state` — the lockstep detector can't see non-boss drift until it reaches boss HP. Two paths: (a) fold seat state + `rng.state_hash()` into `state.checksum` (strongest, but **rebaselines every sim checksum** — a coordinated change), or (b) a **net-layer-only** integrity hash on the existing 30-tick cadence (additive, keeps all sim baselines byte-identical). *Recommend (b).*
- **MED — `seat.casting` holds a live Seat ref → RefCounted self-cycle** (`seat.gd`): a raid healer self-cast leaks the seat on Esc-mid-cast (only cleared on fight-over). Definitive fix: store `target_i` (index), mirroring `absorb_owner_i`/HoT `caster_i` — touches mender/bloom kits + HUD readers. (An interim `casting={}` teardown stopgap exists but the index fix is the right one.)

**Bigger DRY refactors (safe but larger churn — deliberate, not drive-by):**
- Sim harness: `_arg`/`_fmt`/`_write_csv` are md5-identical across 9 sims → a shared `sim/sim_util.gd`.
- HUD factories: `_place` (×6), `_title`/`_label`/`_gap`/`_panel` (×4-6) → shared UiKit helpers.

**Deeper coverage the audit flagged as NOT swept (future audits):** cross-platform float/`Dictionary`-iteration determinism (the real WASM-vs-native lockstep risk); `net_server` adversarial input hardening (malformed/oversized frames, claim races); a systematic boon×aspect correctness sweep (only 2 of ~60 effects were hand-checked — both were bugs); HUD/stage teardown tween/Node leak audit on Esc-mid-fight; config/save (`rift_net.cfg`, binds JSON) versioning + corruption handling.

**Acceptance for any of these:** determinism PASS; byte-identical where the change is meant to be neutral; a fresh baseline documented where it legitimately shifts checksums (boon/map changes); smokes green.

---

## CURRENT / OPEN IDEAS (parking lot — promote into a section when claimed)

- Game title candidates: *UNPLUGGED*, *Ctrl+Alt+DEFEAT*, *KILLSWITCH*, *RIFT: Do Not Trust Its Outputs* (these read Realm-1-flavored now; a realm-neutral title may fit better).
- **Future realm seeds** (each = Seals ladder + map skin + joke register): *THE BUREAUCRACY* (paperwork hell — stamp-golems, queue mechanics, "please hold" telegraphs); *THE UNDERCROFT* (necropolis played straight — the contrast realm); *THE DEEP* (abyssal leviathans, pressure as attrition); *THE CLOCKWORK COURT* (fae mechanisms, rhythm-heavy strings); *THE KAIJU WEATHER STATION* (one enormous boss per floor).
- Rewind verb (deterministic-engine showpiece) — parked, see Classes.
- Positive run-affixes ("Mythical Boons") — fold into Run modifiers when built.
- ~~Second raid boss~~ — claimed: §RAID SEALS (branch `raid-seals`). Healer-aggro rules for co-op still open (R0 caveats list).
- Mender's own draft pool (currently continue-screen only) — subsumed by Draft parity above.

## COORDINATION LOG (claim before you start, tick when merged + plan updated)

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
- ☐ 2026-07-03 · `gear2` · §SYSTEMS GEAR-2 — **Sworn OATHS + Ledger offer + purses (Bill: "continue" after GEAR-1).**
  Per PROGRESSION-PLAN + GEAR-CATALOG: swear ONE oath at the boss node (Ledger-lite offer screen)
  → in-fight tracker banner + live BROKEN pop → resolve at the kill → **permanent row unlock joins
  the same kill's drop pool** + stakes-scaled purse (Tokens + pity ticks / rarity floors,
  `stakes = 3 − ring` until versions exist). Detector engine over `seat.diag`/`seat.vars` ONLY
  (new unconditional diag bumps: curse_dropped/answered, chain_break, kick_whiff, bloodied_dip —
  never checksummed). `Gear.roll` grows the real rarity-first draw (ring weights 70/25/5 →
  40/38/22 + run pity). SEVEN new items implemented w/ oath rows: GRACE PERIOD · STICKY NOTE ·
  SCRATCHPAD · DEBT COLLECTOR · ENCORE BELL · ECHO CHAMBER · OVERFLOW SLUICE (one per raid class
  page + universals; combat-actives like MUTE BUTTON stay deferred — no G/H socket yet).
  Gate: frozen A/B byte-identical gearless/unsworn on all sims + gear_probe extension + smokes.
  ⚠ engine touches: THREAT_DROP/taunt diag + `_damage` dip diag + `BossState.last_curse_tick` —
  all diag-family/write-only. *(gear-design session)*
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
