# ENDLESS-PLAN — THE BLIND DESCENT (fog-of-war endless mode, design v1)

> **What this owns.** The endless mode's structure: the maze floor (a fog-of-war,
> dead-ends-and-backtracking crawler), the information economy, the hunter, the exit/descent
> contract, and the door that hangs it off the Atlas. Born from Bill's 2026-07-11 pitch:
> *"fog of war as you go, dungeon crawler — you see the first nodes around you, find the end,
> dead ends, turn around and go back."*
>
> **Doc relations.** Obeys TEETH-PLAN §ENDLESS (endless = a door on the **Depth** ladder —
> this doc NEVER touches Depth math; `spec.depth`, window-compression affixes, and the
> no-stat-inflation law are owned by MASTER §MODES & ENDGAME and inherited wholesale).
> Inherits DESCENT-PLAN's node grammar (printed contracts, meters, node glyphs) and
> DUNGEON-PLAN's door-ceremony vocabulary. Hangs off WORLD-PLAN §INSTANCES as a new Atlas
> node. THEME-PLAN's naming law applies: every mechanic below gets ONE world-neutral system
> noun; the mode's proper name + the hunter's name are content costumes (§7).
> **⚠ NOT AI-THEMED** (Bill, 2026-07-11) — no Realm-1 register anywhere in this mode.
>
> **Status: 🟡 design v1 at Bill's verdict board (§V).** Direction pre-approved in
> conversation ("pretty much everything seems good"); the board locks the dials. NOT built.

---

## 0. IDENTITY — the third door

| Door | Shape | The question it asks |
|---|---|---|
| RAID | 1.5–3h, 4 floors, authored descent | *can you execute the campaign?* |
| DUNGEON | ~29-min lap, map printed, Depth free-pick | *how deep can you push one clean lap?* |
| **ENDLESS** | **floors until you wipe, map HIDDEN** | ***which way — and how greedy?*** |

The raid and dungeon print their whole map and ask you to route. Endless **hides the map
and makes finding the route the game.** Each floor is a small maze under fog: you see the
room you're in and silhouettes of rooms adjacent to anywhere you've been. Somewhere is a
STAIR down. Find it — past dead ends, locked doors, and pockets of loot — take it, Depth
ratchets, the fog closes in, repeat until the warband wipes. Build snowballs across floors
(drafts continue, run-scoped per Law #1); death is the only way out; your standing records
the deepest floor you **cleared**.

**The one anti-tedium law (everything in §2–§4 serves it):** *"which way do I go" must
always be a read or a bet — never a coin-flip — and a wrong turn must cost a decision you
made, never time the game wasted.* Free backtracking (§3) + dead-ends-always-pay (§4) +
honest tells (§2) are the three legs.

---

## 1. THE FLOOR — a maze, not a lattice

**This is the one sanctioned fork of the map generator's *shape*.** `run_map.gd` is a
forward row-lattice (rows × lanes, edges only forward — completable by construction).
An endless floor is a **seeded connected graph**: rooms with positions, undirected edges,
dead-end pockets, a few loops. New generator mode (same file or `maze_map.gd` sibling),
but the **node schema, contracts, and idioms carry wholesale**:

- Node dict stays `{id, kind, name, fight, event, key, next: [ids], locked_next: [ids]}`
  with `pos` replacing `row/lane`; edges stored both directions. `effective_kind`,
  `fingerprint`, `to_dict/from_dict`, WILD's pre-rolled-payload-revealed-on-entry idiom —
  all reused unchanged, so map screen / save / net / sims inherit.
- **Guarantees by construction** (probe-enforced, like the lattice's): entry→exit path
  always exists · every dead-end terminus holds a payoff (§4 law) · locked edges only gate
  OPTIONAL rooms · one-way edges (§3) never sit on the only exit path.
- **Floor size: ~10–16 rooms**, of which a beeline needs ~4–6. Target **~5–8 min/floor** —
  the "one more floor" cadence is the mode's heartbeat. Fights are forge-skirmish tier;
  no full Seal per floor (guardian cadence: §6).
- **Density is Depth texture, not a fixed pick** (answers the open question from the
  pitch session): shallow floors are CORRIDORS (mostly linear, a stub or two — teach the
  verbs, fast laps); deeper floors become WARRENS (branchy, loopy, real navigation).
  One `maze_branchiness` knob on the generator, driven by floor number.

**Room slate — DESCENT's table, endless deltas only** (same rule as DUNGEON §5):

| Room | In endless? | Delta |
|---|---|---|
| ⚔ FIGHT | ✓ (the bread) | forge tiers ramp with Depth; tier pips are the silhouette tell |
| 💀 ELITE | ✓ | dead-end guardians + the hunter (§5) |
| 🛒 MARKET | ✓ quota ~1 per 3 floors | a found room, not a phase; same 6-slot stock |
| ❄ COOLING | ✓ | attrition valve — endless is long |
| ⭐ EVENT | ✓ thin | reuse pool |
| 👁 VANTAGE | **NEW — endless-only kind** | clear it → reveals a swath (§2) |
| 📦 CACHE | ✓ (the dead-end payoff) | secret-room jackpot grammar, printed roll |
| ▚ WILD | ✓ ~1/floor deep | at tight fog a WILD is nearly free spice |
| 🔑 lock+key | ✓ | backdoor grammar verbatim: visible vault door, key down a different wing |

---

## 2. THE FOG — an information economy (no lying signposts)

**The base read:** entered rooms show their full printed contract. Rooms adjacent to
anywhere you've been show as **silhouettes leaking exactly ONE fact** — a small global
glyph vocabulary (naming law #3: same glyphs at every Depth, every skin):

- **tier pips** (fight strength) · **glint** (cache/loot) · **red pulse** (elite) ·
  **door-wind** (this room touches a STAIR — the honest hot/cold, see below).

The lying-signposts idea is CUT (Bill: "how do you know when it's lying"). Replaced by
**three faucets of honest information you EARN** — info always comes from somewhere you
can see, fight for, or pay for:

1. **VANTAGE rooms.** An authored room kind visible in silhouette (its own glyph). Clear
   its fight/event → the map reveals everything within 2 edges (deep floors: its whole
   wing). High ground as strategy: routing *toward the vantage first* is the smart
   opening, and the generator places it off the beeline so it's a detour bet.
2. **CHARTS as loot.** Cache rooms and elite drops can roll a **floor chart** — reveals a
   chunk of the floor including any STAIR in it. Information IS a loot rarity. A dead end
   that pays a chart converts your wrong turn into the rest of the floor.
3. **SCOUT — the spend.** From any cleared room, spend ⏻ CHARGE to fully reveal one
   adjacent silhouette (contract + its onward edges). Rationed omniscience; un-parks the
   **Panopticon curio** as the scout-economy curio (cost break / extra range).

**Hot/cold, local and honest:** the **door-wind glyph** — any silhouette adjacent to a
STAIR carries it. No compass, no floor-wide pointer: you learn to hunt the wind. (Alt on
the board: a distance-only counter — §V-2.)

**Fog scales with Depth — information is the difficulty axis** (this composes with the
Depth thread's window-compression instead of competing with it): shallow floors leak
silhouettes 2 rings out and every tell; deep floors 1 ring, and tells get scarcer
(tier pips last to go). The darkness *is* the deep game.

---

## 3. MOVEMENT — free backtracking, priced commitment

- **Cleared territory is free.** Click any cleared room, you're there — the world rule
  ("travel through conquered territory is free node-hopping") applied verbatim. A dead
  end NEVER charges a walk-back tax; its only cost is the fights you chose on the way in.
  (Bill-approved 2026-07-11 — this is load-bearing for the anti-tedium law.)
- **One-way drops (thin ration, printed).** A few edges are marked one-way **before you
  take them** — a chute deeper into a wing you can't climb back through; the return trip
  must find another way. Commitment as a *choice*, honest contract, never on the only
  exit path. Ration ~0–2/floor, ramping with Depth (§V-6: in v1 or later).
- **Lock + key** — the visible vault door + the key down another wing. The classic
  detour bet, grammar reused unchanged.

---

## 4. DEAD ENDS PAY — the pocket economy

**The law: every dead-end terminus holds something** — cache · shrine (boon draft) ·
chart · key · market · vantage. Generator-enforced; an empty dead end is a bug
(probe-asserted). A wrong turn is a *gamble that resolved*, not wasted time.

**The greed dial this creates is the mode's core loop:** the STAIR is usually findable
off ~40% of the floor; the other 60% is pockets. Beeline = fast, safe, poor. Full-clear
= rich, slow — and *slow* has teeth on hunted floors (§5) and deep fog. The three lines
every floor asks: **rush it · milk it · pick your pockets and know when to leave.**

---

## 5. THE HUNTER — a per-floor term, not the mode's identity

Bill's steer: *some* floors have it — not all-or-nothing. So the hunter is one of the
floor's **printed terms** (§6), read on the STAIR door before you descend. Some floors
are QUIET. Some are HUNTED. You always chose to enter a hunted floor.

**Hunted-floor rules (v1, deterministic):**
- The hunter spawns at a printed room after a grace of **G first-entries** (you see where
  it wakes). From then on it advances **one room along the graph toward you per NEW room
  you enter**. Revisits and free-hops don't feed it — **it taxes exploration exactly**,
  which is the greed axis, which is the point. No wall clock anywhere (determinism law);
  pathing on its own seeded `DetRng` stream.
- **Always visible once awake** (its icon moves on your map). This is a routing game —
  a hidden hunter is a cheap death, a visible one is a chess piece you route around.
- **Contact = the hunter fight**, an elite with a *cornered* opener (it arrives
  mid-string — you eat its momentum). But it cuts both ways: **you can turn and hunt
  it** — kill it and the floor goes QUIET + it drops its cache (bounty). Three legitimate
  lines on a hunted floor: rush the stair · explore under the tax · turn and fight.
- v1 = ONE hunter family, world-neutral system noun **the HUNTER**; its proper name is
  the skin's (§7). Later: hunter variants as deep-floor terms (a pack, a warden that
  guards the stair instead of chasing, …) — parked, not specced.

---

## 6. THE DESCENT — exits, terms, and the door

- **The STAIR is the exit.** Taking it = floor cleared, Depth ratchets, next floor deals.
  **Every stair prints the next floor's terms before you commit** (door-contract idiom,
  DUNGEON §2): QUIET/HUNTED · size band · a reward skew. The descent is a chain of read
  bets, never a gotcha.
- **Two stair archetypes (v1):** most floors deal 1–2 **STAIRS** (+1 Depth, plain) and
  sometimes a **PLUNGE** (+2 Depth — skips a floor: richer draft on arrival, but you land
  mid-warren with the deeper floor's fog). Authored-affix stairs (Versions vocabulary)
  are the later spice, after the Trial Ladder lands.
- **Guardian cadence:** every 3rd floor the stair is **guarded** — a mini-Seal from the
  casting pool at current Depth squats on it. The ante that keeps "one more floor" from
  being free, and the mode's rhythm marker (big payout on the kill).
- **Runs start at the bottom rung, every run.** No Depth free-pick at this door — the
  climb IS the mode (TEETH: "chaining floors at ratcheting Depth until a wipe, build
  snowballing within the run"). Farm-laps-at-a-comfy-Depth is the DUNGEON door's job;
  the two doors stay different bets. (§V-4.)
- **No cash-out, no retreat.** Death is the only exit; suspend-don't-pause covers real
  life; a full wipe ends the run. Per-fight seat deaths follow raid rules. Meta XP banks
  regardless (unlock system: XP from all sources), so a deep wipe never stings the
  account — only the run.
- **Standing: its own page.** "Deepest floor CLEARED" (clear ≥ took the stair), seed-
  verified like all Depth standings — but a **separate leaderboard from the dungeon's
  per-dungeon best-Depth** (a marathon from rung 0 and a single lap at Depth N measure
  different things; sharing one number would corrupt both). Same `spec.depth` scalar
  under the hood — zero new math.
- **The door lives on the Atlas** as its own landmark node (TEETH's framing), unlocked
  with/after the first dungeon door. Door ceremony = DUNGEON's (creed pick, board), minus
  the dials it doesn't have.

---

## 7. THE SKIN — candidates (⚠ NOT AI — Bill, 2026-07-11)

Per THEME-PLAN: the fiction question is *"what human wonder makes an underground that
never ends?"* System nouns above stay global; these name the door, the halls, the hunter.

1. **THE WANDERING ESTATE** — a wonder: *a home that builds itself*, one notch too far —
   a house that never stopped adding rooms. Explains everything for free: endless floors,
   dead ends, one-way servant-chutes, the re-deal between runs (*the house rearranges*),
   VANTAGE = the grand landings, CHARTS = the architect's loose pages, and the hunter is
   **THE HOUSEKEEPER** (utterly polite; you are not on the guest list). Chipper-creepy —
   dead center of the tone law.
2. **THE FIRST DIG** — the original excavation the Binding generation cut, re-opened. The
   gold-rush register distilled: fog = uncharted galleries, CHARTS = the old surveyors'
   fragments, SCOUT = the sounding lantern, hunter = *what the diggers woke*. Leans on
   the Return premise hardest; most "dungeon-crawler classic."
3. **THE UNDERVAULT** — the Binding's own confiscated-goods warehouse: everything taken
   from every wonder, shelved in halls beyond counting. Hunter = **THE CUSTODIAN**, still
   doing its rounds. Loot fiction is perfect (the shelves ARE the caches); riskiest for
   variety (one aesthetic).

Plus the free meta-hook whichever wins: **the cartographer's book** — revealed floor
fragments persist as a collection page (pure standing/cosmetic lane, Law-#1 clean).

---

## 8. CO-OP + DETERMINISM (mostly free)

- Seeded maze + pre-rolled fog contents (WILD idiom: payloads rolled at generation,
  *revealed* on entry) → lockstep, checksums, and shareable/raceable seeds work unchanged.
  Reveal state + hunter position live with the walker (campaign/run state), the map stays
  immutable — mirrors cleared-node tracking.
- **One shared fog for 4 seats** — the party maps together; routing stays the human
  leader's job exactly as on lattice maps today (AI seats follow, commander policy
  untouched).
- Seed-verified deepest-floor leaderboard rides the standing write; ghost-races stay the
  parked lever they already are.

---

## §V — THE VERDICT BOARD (Bill)

| # | Question | Options | Rec |
|---|---|---|---|
| 1 | Maze density | (a) fixed corridor-ish · (b) fixed warren · **(c) Depth texture: corridor→warren** | **(c)** — density becomes part of the climb |
| 2 | Hot/cold | **(a) door-wind glyph (local, adjacent-to-stair)** · (b) distance counter · (c) none — charts/vantage only | **(a)** — learnable, honest, no GPS |
| 3 | Hunter clock | **(a) advances per NEW room you enter** · (b) per room-clear · (c) real-tick timer | **(a)** — taxes exploration exactly; (c) violates determinism spirit |
| 4 | Run start | **(a) always rung 0 — the climb is the mode** · (b) free-pick like the dungeon door | **(a)** — keeps the two doors different bets |
| 5 | Guardian cadence | **(a) every 3rd stair guarded** · (b) every stair · (c) none | **(a)** — rhythm without a toll booth |
| 6 | One-way drops | (a) in v1 · **(b) later ration, after fog+backtrack feel proves** | **(b)** — smallest v1 that plays |
| 7 | Hunter visibility | **(a) always visible once awake** · (b) only when adjacent | **(a)** — chess piece, not jump-scare |
| 8 | The skin | (a) WANDERING ESTATE · (b) FIRST DIG · (c) UNDERVAULT | **(a)** — explains the mode's every mechanic diegetically; (b) close second |

---

## §B — BUILD SLICES (after DESCENT §I's map-layer bang settles; flagged `ENDLESS_PREVIEW`)

| Slice | What | Gate |
|---|---|---|
| **S0** | Maze generator mode (schema-compatible) + fog/reveal state + map-screen fog render · `--autostart=endless` | new `endless_map_probe` (connectivity · dead-ends-pay · stair-reach · determinism × seeds); flag off ⇒ byte-identical |
| **S1** | Descent chain (RunDirector/CampaignCore): stair→next floor, Depth ratchet, terms print, wipe→standing write | probe + ui_smoke walk |
| **S2** | Info economy: silhouette tells · VANTAGE · CHARTS · SCOUT spend (+Panopticon hook) | probe asserts each faucet |
| **S3** | The HUNTER (per-floor terms, seeded pathing, cornered fight, bounty) | det PASS; quiet floors byte-identical to S2 |
| **S4** | Atlas door + skin strings + cartographer collection page | ui_smoke_world |

**Collision notes (BUILD-LEDGER §E row + §0):** map layer (`run_map.gd`/sibling ·
`map_content.gd` · `campaign_core.gd` · `map_screen.gd`) — ⚠ same hotspot as DESCENT §I,
land AFTER it; `run_director.gd` (floor chaining); Atlas/world save (door node, standing
page). No `combat_core` touch. No Depth-math touch, ever (owned upstream).
