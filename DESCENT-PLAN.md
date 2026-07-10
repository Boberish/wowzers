# DESCENT-PLAN — THE RAID REBUILD (the descent spec v1)

**Status: 🔨 SLICES 1–4 BUILT & MERGED (`ee18e05` · `1f5e051` · `fd8b895` · `a22c1ec`, 2026-07-10)
— the map bang, the legibility pass, the PROMPT MARKET + per-seat wallets, and THE JAILBREAK
curse deals are live.** All 12
verdicts in (V1–V6/V10/V12 at the recommendations · **V7 NO second module** · **V8
STANDING/Prior DELETED entirely** — shipped, 14 files · **V9 WILD ~10%** — shipped · V11
per-seat wallets — lands with slice 3). The 4-floor descent GENERATES AND PLAYS: Vorathek
seals Floor 1, elites are live (REINFORCED trios, bounty + curio roll; keystone slot reserved),
wilds roll sealed payloads, market/jailbreak/minigame nodes exist with honest stub interiors —
slices 3–5 flip `RunMap.*_LIVE` flags without regenerating any map. Fight ladder + skirmish
enrage retighten shipped; verify-all 40/40 ×2; solo maps + raid combat byte-identical.
**SLICE 2 (`1f5e051`) — THE LEGIBILITY PASS:** node doors print a one-line reward CONTRACT (on
hover + tooltip) + fight-tier ▮ pips (normal/elite/Seal); the header carries the 3 meters
(⏣ TOKENS · ⚡ LUCK · ⏻ CHARGE) + wound pips + a reserved curse-pip row + a first-⏻ teach + a
currency legend, and the kind legend is de-GATE'd; check/wager buttons print BOTH legs pre-commit
("on ✓ … · on ✗ nothing lost"); the stats-jargon renames land (Entropy→LUCK display-only, ids
frozen; THE LUCK DAEMON); the "REROLL THE FLOOR" flavor-lie is fixed; and **THE RAID INTEGRITY
KILL** ships — the `map_check` integrity check-row is gone, the overtime wager + 5 tickets +
SPRINT RETRO + Ticket Stub re-price off the dead integrity number onto live ⏣ (fight checksums
unchanged; only the retired-integrity report column moves). 2a proven byte-identical
(ab-gate map_check_sim + online-probe); light verify green (import · map_wager_probe · ui_smoke_map
· map_check_sim). ⏳ **Deferred to a nightly run** (OOM-prone under concurrent box load):
raid_map_sim baseline re-record for 2b · full verify-all · net_map_smoke.
**SLICE 3 (`fd8b895`) — THE PROMPT MARKET + PER-SEAT WALLETS:** V#11 per-seat wallets ship
(`Draft.mint_diag` mints each seat from its OWN combat diag → **AI raiders start earning**; the
shared bank retires); **rerolls-out** (§11 #3 — the 1⏣ REROLL + LOCK die, a banked REGENERATE
charge redraws; Hot Reload → +2 charges); and **THE MARKET node goes live** (`RunMap.MARKET_LIVE`)
as THE SCRAPER's shop — a printed-price stock (CURIO ×2 from your unlocked pool · REGENERATE ·
PATCH), a 4-seat wallet strip, per-seat BUY, and **AUTO** (AI raiders spend their own ⏣ with
banter); plus the post-Seal **MARKET PHASE** (recovery-only), the Hashgrinder reframe (→ market
−1⏣), and a `tokens@market` sim diagnostic. **Deferred (dependency absent):** +1 BACKUP (no wipe
budget yet — printed SOON) · DEPRECATE (curse-purge = slice 4; boon-scrap = a follow-up) · online
market/wallets (server has no purse — a safe no-op, NO protocol bump). Verify: import clean ·
`market_probe`/`draft_sim`/`commander_probe`/`gear_probe` ALL OK · `ui_smoke_map` ALL PASS ·
`raid_map_sim` determinism (seed1==seed1 + descent invariants) PASS. ⏳ **Deferred to a nightly
run:** the `draft_sim` + `raid_map_sim` statistical re-baselines (rerolls-out + the live-market
walk are sanctioned shifts) · full `verify-all` · `net_map_smoke`.
**SLICE 4 (`a22c1ec`) — THE JAILBREAK (printed curse deals):** `RunMap.JAILBREAK_LIVE` on; the
node offers **two deals, both halves printed** (a strong good + a curse bite in a different
currency), WALK AWAY free, and refuses at cap 2. The **curse system** ships: active curses (cap 2,
header pips, bounded-duration, ticking), enforced by `_add_curse` (with the HARD RULE — no
run-length TIMING curse). Bites (V#4 gentle): **ECONOMY** (mint halved / market +⏣), **HP** (a
temporary corrupted sector, auto-repairs — via a `seat_hp_cut` fight-mark), **TIMING** (windows
−10% — via a `window_tighten` mark that scales the fresh-per-fight `s.config` answer windows, no
per-boss work). Two **redundant exits**: the Market **DEPRECATE** slot (escalating price — the
slice-3 deferred slot, now live) + a **Cooling purge fork**. All ride the proven `RaidMarks`
channel, byte-identical when no curse. **Deferred:** DECK tax (run-length ability-poison — needs a
`perform()` gate + spec-threading offline+online) · welded-downside draft boons (② door) ·
event-curse legs (③) · online (safe no-op, NO protocol bump). Verify: import clean · `curse_probe`
ALL OK (engine + node end-to-end) · `market_probe`/`commander_probe`/`draft_sim` ALL OK ·
`ui_smoke_map` ALL PASS · `raid_map_sim` map-gen determinism PASS. ⏳ **Deferred to a nightly
run:** the `raid_map_sim` run-trace + statistical re-baseline (JAILBREAK_LIVE walk = a sanctioned
shift) · full `verify-all` · `net_map_smoke`.
**Next: slice 5 (minigames: CAPTCHA / BENCHMARK + extraction schematics) → slice 6 (QUEUE) +
the DECK-tax follow-up** — ledger §I is the tracker. The zoom-out rebuild of the raid run structure
Bill asked for ("the raid is all over the place — rebuild it from the ground up; keep the bosses
for now"). Produced by a 14-agent workflow: 7 recon readers (as-built map code · quest-confusion
audit · measured sim timings · zone TICKETS v2 · reward economy · genre references · parked
MASTER-PLAN ideas) → 3 architects (time-first / economy-first / quest-first) → 3 adversarial
judges (legibility / coherence+arithmetic / fun-per-hour) → one judged synthesis. Judges ranked
economy-first's legibility spine + time-first's fatigue skeleton on top; both are merged here,
with quest-first's QUEUE + ticket grammar grafted in.

**How to read it:** §V is the verdict board — the twelve calls that are genuinely Bill's.
Everything else is the spec those verdicts activate. Every element in §5–§10 carries a status
tag: **BUILT-KEEP** (built, unchanged) · **BUILT-RESKIN** (built, new face/words) · **NEW**
(build it) · **CUT** (dies). Law amendments are flagged **AMEND:** — nothing locked is broken
silently. Bosses are untouched (recast later); §4 writes the *contract* the boss pass fills.

**Doc relations:** obeys WORLD-PLAN (pillars · stakes · instances) with two flagged AMENDs;
DECK-LAYOUT §1 run-flow kept verbatim; TEETH-PLAN's CONTEST/curse/rerolls-out land *here*
(TEETH keeps the rationale); GEAR-3's Market lands *here*; execution rows in BUILD-LEDGER §I.
GAME-LOOPS L2/L3 stanzas update when verdicts land.

---

## §V · THE VERDICT BOARD — ✅ all twelve decided (Bill, 2026-07-10)

**The record:** V1 (a) four floors · V2 (a) ~2h25 · V3 (a) elective elites · V4 (c) mixed curse
menu, lean gentle · V5 (a) best-of-N · V6 approve all names (STANDING moot — V8 deletes the
concept) · **V7 (b) NO second module** · **V8 DELETE STANDING/Prior entirely** — stronger than
option (b): no fold into starting LUCK either, "it messes up an otherwise fresh run"; every run
starts at baseline · V9 (a) **amended to ~10% WILD** · V10 (b) SEV-1 parked v1.1 · V11 (b)
per-seat earned wallets · V12 (a) ship structure at ~2h. Original questions kept below for the
record.

1. **THE FOUR-FLOOR PROMOTION**
   *Question:* Make Vorathek the boss of a short new first floor, so every floor ends in a boss
   and the Rings count down 3-2-1-0 (Gemini moves to Ring 1)?
   *Options:* (a) Yes — 4 floors, 4 checkpoints, same 4 bosses. (b) No — keep 3 floors, Vorathek
   stays the warm-up fight.
   *Recommendation:* **(a).** All three designers landed here independently. You get a gentle
   first sitting (~23 min ending on a boss kill), a 4th checkpoint for the wipe budget, and the
   Ring fiction finally counts down without a gap — for zero new bosses. It does amend the
   WORLD-PLAN line that said "3-Ring Takeover unchanged," which is why it's your call.

2. **THE LENGTH DIAL**
   *Question:* Is ~2 h 25 clean / ~3 h lived the right size for a full raid?
   *Options:* (a) As specced. (b) Shorter (~2 h — trim one normal fight per floor). (c) Longer
   (push toward 3 h clean — +1 fight per floor).
   *Recommendation:* **(a).** It matches your 3-hour StS2 appetite once real play (wipes,
   shopping, thinking) is counted, and floors of 23/34/39/49 minutes give you clean stopping
   points with the kid. The dial is easy to turn later — it's a quota number.

3. **ELITES: TEMPTATION OR GUARANTEE?**
   *Question:* Elites are optional — route to one or skip it. Skipping every elite forfeits your
   keystone for the run. Keep that, or force one elite onto every route?
   *Options:* (a) Optional, with the pay printed on the door and the map guaranteeing one is
   always reachable. (b) Mandatory — one full row of three elites; picking your lane picks your
   poison.
   *Recommendation:* **(a).** The do-I-dare-fight-the-elite squeeze is the best route decision in
   this whole genre, and printing "KEYSTONE" on the door means nobody misses it by accident —
   they miss it by choice, which is the game. Option (b) is elegant and guarantees the grant, but
   it deletes the squeeze. (One judge voted each way; the fun judge felt strongest.)

4. **CURSE BITE SIZE** *(the standing TEETH verdict)*
   *Question:* How hard may a Jailbreak deal bite before it stops being fun for you two?
   *Options:* (a) Gentle start — "next 2 fights: +1 surprise beat" / "mint halved next 2 fights".
   (b) Spicy — "windows −10% next 3 fights" / "one ability poisoned until you pay the Market to
   remove it". (c) Mixed menu of both, priced accordingly.
   *Recommendation:* **(c), leaning gentle for launch.** Every bite is printed, bounded or
   purchasable-away, and capped at 2 active — so you can tune upward in playtest without anyone
   getting ambushed. Hard rule already in the plan: no run-long timing curse, ever.

5. **BENCHMARK SCORING RULE**
   *Question:* When all 4 seats play the shared skill-game, how is the winner scored?
   *Options:* (a) Best-of-N beats (highest total grade wins). (b) Closest-without-going-over
   (price-is-right). (c) Sudden death (first miss drops out).
   *Recommendation:* **(a) best-of-N.** It's the plainest to read on screen ("you scored 14,
   SONNET-BOT scored 12"), works identically for the co-op mode, and never eliminates the kid on
   beat one. The others are spicier variants you can add as later event flavors.

6. **THE NAMES BUNDLE** *(approve/veto each — one word each is fine)*
   *Question:* The fiction renames: **LUCK** (was Entropy) · **STANDING** (was Prior) ·
   **BACKUPS** (wipe attempts — "RESTORING FROM BACKUP…") · **REGENERATE** (banked draft
   rerolls) · **DEPRECATE** (pay to remove a curse/boon) · **THE JAILBREAK** (the curse den) ·
   **THE SCRAPER** (the merchant — "scraped off the open web, possibly stolen").
   *Options:* approve all / veto individually (alternates on file: LE CHAT or POPUP the Adhound
   for the merchant; UNSIGNED PATCH for the curse den).
   *Recommendation:* **Approve all.** Every one explains itself in the fiction instead of needing
   a tooltip — BACKUPS especially makes the wipe budget self-teaching.

7. **SECOND MODULE SLOT — ✅ DECIDED (Bill, 2026-07-10): (b) NO.** One module per run; boons
   carry the late game. The recommendation (a Floor-3 second pick) is rejected; the WORLD-PLAN
   long-raid sanction stays unused. Floor 4 deck depth comes from boons + the keystone.

8. **STANDING — ✅ DECIDED (Bill, 2026-07-10): DELETE ENTIRELY.** Stronger than option (b):
   no fold into starting LUCK either — any cross-run carry "messes up an otherwise fresh run."
   Every run starts at baseline. What dies: `luck_profile.gd` + `user://rift_prior.cfg`
   persistence, the Prior term in the check breakdown, the run-start "+2⚡" carry, the
   end-of-run bank toast, and the parked online-Prior follow-up. What stays: mercy choices in
   events may still pay IN-RUN goods/flags; the in-run comeback pity keeps (it resets with the
   run, so fresh stays fresh).

9. **WILD NODES — ✅ DECIDED (Bill, 2026-07-10): (a) amended to ~10%** ("for spicy"). Quota
   becomes 2 WILD per floor on floors 2–4 (0 on the teaching floor) ≈ 10% of a floor's mids.
   The slots come out of the EVENT quota, not COMBAT — wilds often resolve as surprise
   events/deals anyway, and the fight budget (§3) holds unchanged. Fight tier stays printed
   even on WILD.

10. **SEV-1 ESCALATION** *(the cross-floor ticket)*
    *Question:* Build the once-per-run ticket that's picked up on Floor 2, escalates each Ring,
    and turns in at Mythos's door — now, or later?
    *Options:* (a) In v1. (b) Park for v1.1 after the base QUEUE proves itself.
    *Recommendation:* **(b).** Two judges loved it, but it's the one quest piece with real new
    plumbing (cross-map state), and the QUEUE + three ticket shapes already give floor-to-floor
    thread. Prove the base, then add the long arc.

11. **THE SHOP PURSE IN CO-OP — ✅ DECIDED (Bill, 2026-07-10): PER-SEAT EARNED WALLETS.**
    Shared-pot rejected ("we all share the same money — not fun"). The rule: **you keep what
    your own play mints** — the skill mint already pays more ⏣ for clean play; it now pays into
    YOUR wallet instead of a party pot. **AI seats:** the player directs their market buys
    (flip through their wallets and shop for them) **or hits AUTO** — AI spends its own wallet
    with banter; AUTO is the default for players who don't care. Consequence (one pooling rule
    for one currency): the Draft-2.0 shared token bank flips to per-seat everywhere — UPSELL
    spends YOUR wallet too. This edits the §12 KEEP line for Draft 2.0 accordingly.
    **As-built finding (2026-07-10, code recon):** today there is ONE `run.tokens` pot
    (`run_state.gd:23`) and `Draft.mint()` reads `state.diag` — the HUMAN player's mirror — so
    AI seats currently earn nothing at all. Per-seat wallets therefore also mean **AI seats
    start earning for their own play**. Cheap to build: per-seat grade counts already exist
    (`seat.diag`, `combat_core.gd:629` — what the Reckoning and raid sims read); the mint just
    re-routes its deposit from the run pot to the earning seat's wallet.

12. **INTERIM ACCEPTANCE**
    *Question:* Ship this structure now at ~2 h (bosses still at today's 2–3 minute lengths,
    under-filling their 5/7/9/12 budgets), letting the later boss pass grow it?
    *Options:* (a) Yes — structure first, bosses fill the contract. (b) Hold the map until at
    least one Seal is stretched.
    *Recommendation:* **(a).** The map, shop, curses, and legibility fixes are all independently
    valuable at any boss length, and the Seal budgets are written down as the contract the boss
    redo must fill — with structure beats, never +HP.

---

## 0 · THE RAID IN ONE PARAGRAPH

The raid becomes a **four-floor descent** down the privilege Rings — **Ring 3 → 2 → 1 → 0** —
with a Seal boss ending every floor: **Vorathek → Mistral → Gemini → Mythos** (Vorathek is
promoted from "first fight" to Floor 1's boss; same fight, better job). A clean full clear is
**~2 hours 25 minutes** at good play, **~2¾–3 hours lived** (wipes, shopping, thinking) — played
in one Saturday or split across floors, because the floor boundary is a checkpoint you can walk
away at. You fight **~21 fights** on a steep length ladder: 1–3 minute normal fights that grow
with your deck, one 4–6 minute elite per floor *if you dare route to it*, and four bosses at
5/7/9/12 minutes. Between fights, the map finally says what everything is: **three meters on the
header (⏣ TOKENS · ⚡ LUCK · ⏻ CHARGE)**, every node **prints what it pays and how hard its fight
is before you click it**, every dice-check shows both what winning pays and what losing costs,
and every ticket prints its reward at pickup. The **PROMPT MARKET** finally exists to spend
Tokens at; **THE JAILBREAK** sells power with a printed, bounded, escapable downside; and three
small skill-game nodes (CAPTCHA, BENCHMARK, and a co-op drill) reuse the combat engine as
minigames. Everything Bill likes stays connected — key→backdoor, tickets→lanes, shards→the last
Seal, charge→the Kill Switch — it just stops being secret.

---

## 1 · TIME BUDGET

**Decision order honored: total length first.** Target: **~145 min deathless at good tier ≈
2 h 25** (expert ~2 h 05); lived pace with 1–2 boss re-pulls and human thinking ≈ **2¾–3 h** —
the top of WORLD-PLAN's 1.5–3 h raid band, matching Bill's 3-hour StS2 appetite (which the genre
research reads correctly as appetite for *decision density*, not 3 hours of spike execution).

**The budget by floor (the arithmetic that must close):**

| Floor | Fights on route | Combat min | Valley nodes (min) | Post-fight ceremony | Arming + oath | Market phase / finale | Routing | **Floor total** | Combat share |
|---|---|---|---|---|---|---|---|---|---|
| 1 · RING 3 | 4.3 | 9.2 | 1.7 nodes (2.5) | 4.3 | 2.0 | 3.0 | 1.8 | **~23 min** | 40% |
| 2 · RING 2 | 5.2 | 16.6 | 2.8 nodes (4.9) | 5.2 | 2.0 | 3.0 | 2.4 | **~34 min** | 49% |
| 3 · RING 1 | 5.2 | 21.2 | 2.8 nodes (4.9) | 5.2 | 2.0 | 3.0 | 2.4 | **~39 min** | 55% |
| 4 · RING 0 | 5.8 | 28.5 | 3.2 nodes (5.6) | 5.8 | 2.0 | 4.0 (META) | 2.7 | **~49 min** | 58% |
| **RUN** | **~21** | **~76** | **~18** | **~21** | **8** | **13** | **~9** | **~145 min** | **52%** |

*(Ceremony ≈ 1 min/fight: the Reckoning recap + your draft + 3 AI drafts. Market phases are the
zero-execution exhale after Seals 1–3; after Mythos it's the META/carry-out ceremony, not a
shop — a shop after the run ends sells nothing.)*

**The fatigue laws (stated so the table and the law agree):**
- Run-wide scheduled combat ≤ ~52% of the clock. Floor 1 is the on-ramp (~40%). Only the finale
  floor exceeds 55% (~58%) — because Mythos is 12 of its 49 minutes, and that's the point.
- Every fight of 3+ minutes carries **≥25% of its length as in-fight valleys** (pack walk-ins,
  phase turns, vent beats — diegetic, never a pause). Sustained-spike share of the run lands ≈
  **44%**, at the top of the genre's sustainable band.
- **No stacked spikes:** generation never places two 3-min+ fights on adjacent route nodes
  without a valley option; a non-fight band is guaranteed in the rows before every Seal.

**Session model:** SUSPEND anywhere on the map (suspend-don't-pause, locked). The **blessed stop
is the floor boundary** — Seal dead, oath banked, market phase done, checkpoint written.
Sittings: lunch = 1 floor (23–49 min) · evening = 2 floors (~57–88 min) · the Saturday = the
descent. **Stakes model kept verbatim:** floor checkpoints, wipe budget starts at 3, cleared
floors stay cleared, a wipe re-pulls only the boss (now a real 5–12 min cost, which finally
gives attempt tokens teeth), last attempt spent = descent over, finale pays META never a drop.

**Interim honesty:** until the boss pillar pass fills the §4 Seal budgets, bosses under-fill by
~22 min and the run ships at **~2 h**. The map and economy don't change when bosses grow — the
Seal budget is the contract the boss pass fills.

---

## 2 · MAP STRUCTURE

**KEEP the generator wholesale** (`run_map.gd`): 3-lane layered DAG, same-lane completability
spine, 45% lane crossings, quota-bag shuffle on its own rng stream, one locked 401 backdoor edge
+ key per floor, deterministic node-entry order. Only its **inputs** change (floor count, rows,
quotas) — one deliberate, one-time `raid_map_sim` re-baseline.

| Floor | Ring | Seal | Rows | Nodes | Walked route |
|---|---|---|---|---|---|
| 1 | RING 3 — THE PERIMETER | VORATHEK | 6 | 14 | 6 (entry + 4 mids + Seal) |
| 2 | RING 2 | MISTRAL-7B | 8 | 20 | 8 (entry + 6 mids + Seal) |
| 3 | RING 1 | GEMINI ULTRA | 8 | 20 | 8 |
| 4 | RING 0 — ROOT | CLAUDE-MYTHOS | 9 | 23 | 9 (entry + 7 mids + Seal) |
| | | | | **77 generated** | **31 walked (~40%)** |

**AMEND:** WORLD-PLAN's instances row says "Realm 1 = the existing 3-Ring Takeover, unchanged."
All three architects independently promoted Vorathek to Seal of a short first floor. Reasons:
the fight-length ladder needs a genuine on-ramp floor; the stakes model wants a 4th checkpoint;
the Ring fiction finally counts down cleanly 3-2-1-0 (Gemini moves to Ring 1 — no invented
"Ring 4", no skipped number); costs zero new bosses. Needs Bill's blessing (Verdict #1).

**Route-choice feel — three levers:**
1. **Pay printed on the door** (the Hades rule): every node shows its kind, its one-line reward
   contract, and its **attention price** — fight-tier pips (▮ normal · ▮▮ elite · ▮▮▮ Seal).
   Entering blind is too expensive when a node costs minutes of rhythm execution.
2. **Lanes are commitments:** the MARKET sits mid-floor in one lane, ELITEs in others, THE
   JAILBREAK somewhere greedy, and a ROUTE ticket pins you to its lane (KEEP the
   forfeit-on-lane-change rule — it's a real decision). Generation guarantees the MARKET and ≥1
   ELITE reachable from every early-row position (the same cheap reachability check the shard
   gate already uses), ≥1 COOLING mid-floor, and the valley band before the Seal.
3. **One legible risk fork per floor** (floors 2–4): a row authored so the lanes visibly
   diverge — easy lane (short fight, quick reconverge) vs hard lane (the elite + the fattest
   cache) — stakes signposted **before** commit.

**The backdoor gets a room:** KEEP the locked 401 edge + key; the skip path now passes through
the **SERVER ROOM** (§8) so the key pays twice — a row skipped *and* a jackpot room with a
printed risk.

**Grant ladder on the 4-floor spine (DECK-LAYOUT §1 kept, mapped):** Creed at run start → rig
wire after fight 1 (at the **PATCH BAY**, §8) → **Module at end of Floor 1** → **keystone 1-of-2
at your first ELITE** (floors 2+) → free re-wire at end of Floor 2 → oaths at every Seal →
Mythos pays META. *(V#7 ✅: NO second module — one per run, boons carry the late game.)*
`_advance_floor`'s baked grant indices move accordingly.

**Seeding fix (NEW):** the map seed derives from the descent's run seed, not the wall clock —
replay-stable floors, checkpoint restore across app restarts, co-op shared maps.

---

## 3 · THE FIGHT BUDGET

**Decision order: total (§1) → bosses (§4) → this remainder.** ~21 fights per descent:
**~14–15 normals (incl. 4 entry fights) · 3 elites (one per floor 2–4, routed to by choice) ·
4 Seals.** That's the Hades pyramid — many short fights, a spine of mids, four monsters — and
~21 won fights = ~21 boon drafts, which a many-unlocks game wants.

**The fight-length ladder (Bill's scaling ask, made a formula):**
- **Deck-cycle law:** a fight lasts long enough to cycle your current deck ~2–3 times. Floor-1
  deck (creed + rig) cycles in ~30 s → ~75 s fights; floor-4 deck (module(s) + keystone + ~15
  boons) needs ~3 minutes.
- **THE TRASH CAP (hard authored rule):** nothing except elites and Seals ever exceeds
  **3 minutes**. Length growth beyond that lives only in the authored spikes — max 2 spikes per
  floor, never adjacent.
- **NO FLAT SPONGES (law, kept):** every added minute arrives as structure. The **PACK engine**
  (built: heat-carry chains, ~2.5 s walk-in valleys) is the lengthener — raid floors finally
  turn packs ON. Normals grow by becoming duos/trios of Forge bodies with the authored encounter
  as captain (mechanism already coded; weights re-tuned by floor: F1 mostly solos → F4 mostly
  trios).
- **Enrage gets honest:** trash enrages retighten from today's 4–5× TTK safety nets to
  **~1.5–1.7×** so the clock is a real wall.

| | F1 RING 3 | F2 RING 2 | F3 RING 1 | F4 RING 0 |
|---|---|---|---|---|
| Deck entering | creed + rig | + module, ~5 boons | + keystone + re-wire, ~10 boons | + ~15 boons |
| Normal fight (good) | 1–1.5 min (avg 1.25) | 1.5–2 (avg 1.75) | 2–2.5 (avg 2.25) | 2.5–3 (avg 2.75) |
| Elite | — | ~4 min | ~5 min | ~6 min |
| Seal | 5 min | 7 min | 9 min | 12 min |
| Fights on route | 1 + 2.3 + Seal = 4.3 | 1 + 2.2 + elite + Seal = 5.2 | 5.2 | 1 + 2.8 + elite + Seal = 5.8 |
| **Combat math** | 3.3×1.25 + 5 = **9.2** | 3.2×1.75 + 4 + 7 = **16.6** | 3.2×2.25 + 5 + 9 = **21.2** | 3.8×2.75 + 6 + 12 = **28.5** |

**Total: 75.5 ≈ 76 combat minutes** — the numbers §1 uses. (Elite counts assume the player
routes to one per floor because its pay is printed on the door; by blind chance it's ~0.7/floor —
the budget uses the deliberate number and playtest confirms. This is Verdict #3.)

**Intensity valleys:** saw-tooth by construction — the quota guarantees ~2–3 non-fight nodes per
walked floor; the pre-Seal valley band, the no-stacked-spikes rule, and the
elite-not-adjacent-to-Seal placement rule are generation constraints, not hopes.
**Draft-saturation valve (NEW, small):** if the boon slate runs dry late, drafts convert to
UPSELL/⏣ offers instead of dead picks. Freshness across 3 hours comes from **rotating the
puzzle, not the speed**: pack composition, elite mutators, and (later) per-Ring telegraph
vocabularies — never tightening windows as you tire.

---

## 4 · BOSS TIMERS

Boss budget = **33 min = ~43% of combat, ~23% of the clock.** Bosses keep their kits for now;
these targets are the contract the later boss pass fills — **with structure beats (add cycles,
pack joins, phase acts), never +HP** (the one lever every reference game says not to pull).

| Seal | Floor | Target (good) | Enrage (~30% headroom) | Share of boss budget | Today (measured) | The gap = structure owed |
|---|---|---|---|---|---|---|
| VORATHEK the Riftmaw | 1 | **5 min** | ~6.5 min | 15% | 2.7 min | ~2 min — one walk-in pack + one add wave; the teaching Seal |
| MISTRAL-7B | 2 | **7 min** | ~9 min | 21% | 2.0 min | ~5 min — largest relative gap (currently the *shortest* Seal) |
| GEMINI ULTRA | 3 | **9 min** | ~11.5 min | 27% | 2.9 min | ~6 min — two add cycles; densest interrupt traffic |
| CLAUDE-MYTHOS | 4 | **12 min** | ~15 min | 36% | 3.3 min | ~9 min — the three-act finale (the parked Helpful/Harmless/Honest phases); Kill-Switch P3 "PULL THE PLUG" is the natural in-fight cash-in when built |

**AMEND:** WORLD-PLAN's "raid Seal 8–12 min" band was written for a 3-Seal raid. With four Seals
and fight-length-scales-with-deck, early Seals sit deliberately below band and only Gemini/Mythos
enter it. The ramp is the feature (Verdict #2 confirms the dial). Do NOT bridge the interim gap
with `--fightlen` — stretching the same loop is fatigue, not content.

---

## 5 · THE NODE SLATE

Every node prints: **kind + one-line contract + attention pips (▮)** before entry.

| Node | Status | The one-line contract |
|---|---|---|
| ⚔ **COMBAT** | BUILT-KEEP (packs NEW-wiring) | "A pack fight (▮, size printed: SKIRMISH/PATROL/PACK). Pays: a boon pick + skill-minted ⏣ (+ salvage ⏣ if a repeat)." |
| ☠ **ELITE** | NEW | "A mutator fight (▮▮), the poison printed — spicy ones offer 1-of-2 before the pull. Pays: your KEYSTONE (first of the run) + a curio roll + fat ⏣." |
| 👑 **SEAL** | BUILT-KEEP | "The floor boss (▮▮▮). Pays: oath verdict + drop event + checkpoint + the market phase. Mythos pays META, never a drop." |
| 🛒 **PROMPT MARKET** | NEW (this IS GEAR-3) | "Spend ⏣. Stock and prices printed below." (§6) |
| ⛓ **THE JAILBREAK** | NEW | "Two deals, both halves printed. Walking away is free." (§7) |
| ? **EVENT** | BUILT-KEEP | "A story choice with printed odds AND printed stakes on both legs." (The built inference-check engine; 'events thin' = a content pass later — structure reserves 2–3 slots/floor.) |
| ❄ **COOLING STATION** | BUILT-KEEP + NEW fork | "Pick ONE: repair a corrupted sector / purge a curse / +15⏻." (The campfire law: every breather carries a fork.) |
| 📦 **CACHE** | BUILT-KEEP | "Free loot: +25⏻ + ⏣ (later: a schematic that banks only if you reach the Seal alive)." |
| 🤖 **CAPTCHA GATE** | NEW (light) | "One telegraph: prove you are human. Perfect pays ⚡/⏻ (rarely a spare ACCESS KEY); a miss just pays nothing." (§8) |
| 🏁 **BENCHMARK** | NEW | "Party skill game on one shared telegraph stream. Prize printed on the door." (§8) |
| 🚪 **SERVER ROOM** | NEW | "Hidden behind the 401 backdoor. A jackpot roll — with a printed INTRUSION DETECTED risk %." (§8) |
| 🔧 **PATCH BAY** | NEW (light re-host) | "Wire your rig." (The existing rig-wire + Floor-2 re-wire ceremonies get a place; §8.) |
| ▚ **WILD** | NEW (~10%, V#9 ✅) | The one rationed mystery — and even it prints its fight tier. |
| **GATE** (solo exams) | **CUT** | Ratifies THE PURGE in the map layer: `KIND_GATE`, the quota, `GATE_ENC`, the sim's one-gate assert all go. ELITE inherits the drop-roll site. |
| Resource-gathering node | **CUT (never existed — settled)** | Keys, shards, tickets, and ⏻ already ARE the gathering game. A gather node would be a contract with no decision in it. |

**Mid-row quotas (the bag):**

| Kind | F1 (12 mids) | F2/F3 (18) | F4 (21) |
|---|---|---|---|
| COMBAT | 7 | 7 | 9 |
| ELITE | 0 | 2 | 2 |
| EVENT | 2 | 2 | 2 |
| COOLING | 1 | 1 | 2 |
| CACHE | 0 | 1 | 1 |
| MARKET | 1 | 1 | 1 |
| JAILBREAK | 0 | 1 | 1 |
| BENCHMARK / CAPTCHA | 1 (CAPTCHA — the teacher) | 1 (BENCHMARK) | 1 (rotate) |
| WILD | 0 | 2 | 2 |

*(V#9 ✅: WILD at ~10% — the extra slot comes out of EVENT, not COMBAT, so the §3 fight budget
holds; wilds often resolve as surprise events/deals anyway.)*

---

## 6 · THE SHOP — THE PROMPT MARKET (NEW; GEAR-3 made flesh)

**Fiction:** staffed by **THE SCRAPER** — "everything's scraped off the open web; 20% off and
possibly stolen." Tagline stays: *"TOKENS — spend them responsibly."* (Merchant face =
Verdict #6.)

**Two surfaces, one stock philosophy:**
- **The MARKET node** — exactly **1 per floor** (resolves the recorded ≤1/act vs ≥1/floor
  conflict in Curio-Economy-v2's favor), mid-floor, guaranteed reachable, always skippable. This
  is where the scarcity tension lives.
- **The MARKET PHASE** — after Seals 1–3, the AtO town beat: all four seats shop simultaneously,
  AI seats auto-spend with banter, zero execution. THE macro exhale and the blessed suspend
  point. The phase stocks only **recovery and ceremony goods** (repairs, refuel, DEPRECATE,
  restock of nothing rare) so the routed node keeps its teeth. After Mythos: no shop — the META
  ceremony.

**Fixed 6-slot node stock (StS2-legible, prices printed, ~+30%/floor):**

| Slot | Item | Start price |
|---|---|---|
| 1–2 | **CURIO ×2** from YOUR unlocked pool (rotating — the reliable curio path; drops stay the jackpot) | 6–10⏣ |
| 3 | **REGENERATE charge** (banked draft reroll — the only purchasable reroll; rerolls-out law) | 4⏣ |
| 4 | **+1 BACKUP** (an attempt on the wipe budget; floors 2+, cap 1/market) | 10⏣ |
| 5 | **PATCH** (repair one corrupted sector) / mana refuel | 5⏣ |
| 6 | **DEPRECATE** — pay to have LESS: purge a curse or scrap a drafted boon (half back in ⏣). Price escalates each use. | 5⏣ |

**The purse (V#11 ✅ decided):** **per-seat earned wallets** — each seat's skill mint pays into
its OWN wallet (clean play = more ⏣, personally). At the market the player shops for the AI
seats from their wallets, or hits **AUTO** (default) and they spend their own with banter. One
pooling rule everywhere: draft UPSELL spends your wallet too (the Draft-2.0 shared bank
retires). **AI seats earn too** — today only the human's grades mint (`Draft.mint` reads the
player mirror); per-seat mint reads each seat's own `seat.diag`, so a clean AI raider shops
like one.

**The scarcity audit (re-run at 21 fights, per the judges):** faucets mint ~15–23⏣/floor (skill
mint ~3⏣ × ~5 fights + salvage + oath purse + scrap) vs ~35–40⏣ of stock → **you afford ~2 of 6
slots** — now per seat, so a sloppy seat window-shops while a clean seat splurges. Real triage,
no vendor trash. Add a `tokens@market` diagnostic to `raid_map_sim` beside
the charge one. UPSELL at drafts BUILT-KEEP; per-draft REROLL/LOCK **CUT** (§11). Curio reframes
at build time: Hashgrinder Rig → "market prices −1⏣ (floor 1⏣)"; Hot Reload → "grants 2
REGENERATE charges."

---

## 7 · CURSES — THE JAILBREAK (NEW)

**Three doors, all opt-in:** ① the JAILBREAK node (1/floor, floors 2–4) offers **two deals, both
halves printed on the button**; ② rare **welded-downside boons** in ordinary drafts, marked ⚠
(the shipped greed-toggle lineage: Hone / blindfold / Overreach — BUILT-KEEP as vocabulary,
expanded); ③ event outcomes whose printed downside leg is a curse.

**A deal = a strong good + a printed bite, priced in a DIFFERENT currency than the reward pays**
(the rule every reference game agrees on). Goods run ~30–50% over market value: an Opus-lean
boon, a curio, +40⏻, +1 BACKUP, fat ⏣.

**The bite vocabulary (small, bounded, always printed):**
- **TIMING TAX** — "next 2 fights: +1 un-telegraphed beat" / "windows −10% next fight."
  **Bounded to N fights, always.**
- **ECONOMY TAX** — "skill mint halved next 2 fights" / "market prices +2⏣ this floor."
- **HP TAX** — "enter the next fight with a temporary corrupted sector (auto-repairs after)."
- **DECK TAX** — one ability slot poisoned **until you DEPRECATE it at the Market** (the one
  run-length curse — legal because it has a printed exit and a price).

**HARD RULE (fixes the one judge-flagged legibility hole): no run-long timing curse ever
exists.** A run-long bite must hit a non-timing currency AND have a printed DEPRECATE exit.
Active curses: **cap 2, always visible as header pips.** Exits are deliberately redundant —
Market DEPRECATE *and* the Cooling purge fork — because a cold player needs two ways out. Why
say yes: best per-⏣ value in the raid *if* you can eat the bite — a skill-read, which is the
whole game; the pain is scheduled where YOU route it. Bite magnitudes = Verdict #4.

---

## 8 · MINIGAME & PUZZLE NODES (first-class slots — structure now, content later)

| Node | What the player does | Pays | Build weight | Status |
|---|---|---|---|---|
| 🤖 **CAPTCHA GATE** | One-to-few CombatCore telegraphs fired as a node — "prove you are human: dodge this" — graded PERFECT/GOOD/MISS | ⚡/⏻ by grade; a perfect can pay a spare ACCESS KEY; a miss never blocks passage | **LIGHT** — the MAP-1 captcha event is the shipped precedent; generalize to a node kind | NEW |
| 🏁 **BENCHMARK** | The CONTEST primitive: one shared telegraph stream, all 4 seats answer, `strike_judge` grades, lockstep makes scoring cheat-proof. *"Highest score gets the compute."* CO-OP mode (floors 1–2): party clears a shared bar → party bonus (REGENERATE charge / rarity bump / +⏻) — flubbing pays nothing, never punishes. CONTEST mode (floors 3–4): closest-to-perfect claims a curio roll; AI seats roll and banter | party bonus or a contested drop | **LIGHT-MEDIUM** — TEETH's own build #1; all tech exists. Scoring rule = Verdict #5 | NEW |
| 🚪 **SERVER ROOM** | The secret room on the backdoor path: enter with the ACCESS KEY (or pass a CAPTCHA at the door). Inside: a jackpot — an extraction schematic (usable now, banks permanently only if you reach the Seal alive) or an Opus-lean roll — with a **printed INTRUSION DETECTED %** (a short pack fight if it fires) | jackpot roll; the named-but-never-built ambush, finally built, as a legible gamble | **MEDIUM** | NEW |
| 🔧 **PATCH BAY** | The rig-wire (after fight 1) and free Floor-2 re-wire ceremonies get a diegetic place — a server-room screen where you physically wire WHEN→THEN. Same grants, same timing, RIG LAW intact | (a ceremony home, not a reward node) — reserves the surface where a real wiring puzzle grows later | **LIGHT** — UI framing over a built system | NEW (re-host) |
| 🧩 **FIREWALL DRILL** *(reserved slot)* | Co-op coordination puzzle: a 4-part pattern where each seat owns a lane (synced parries, split soaks, a communal telegraph). Clear together → party bonus; flub = missed opportunity only | party bonus | **MEDIUM** — needs the "what is a puzzle without movement" feel-verdict first; do not author before it | NEW (reserved) |
| 👁 **THE HALLUCINATOR** *(reserved slot)* | An all-feints, low-HP illusion miniboss — a pure don't-press-reads minigame wearing an elite/event skin. Forge-authored fresh (the purge left only the identity) | elite-tier reward | **MEDIUM** — reserved, author later | NEW (reserved) |

**Minigame contract:** they pay bonus-tier goods only (⚡/⏻/⏣, REGENERATE charges, rarity bumps,
contested curios) — never modules or keystones — so skipping them is always legal. One telegraph
stream, exactly 4 seats, everything rides `(seed,spec)`: pillar-clean by construction.

---

## 9 · THE REWARD SYSTEM

### Resource verdicts — every symbol answered

| Resource | Verdict | New face |
|---|---|---|
| ⏣ Tokens | **BUILT-KEEP → per-seat (V#11 ✅)** | "⏣ TOKENS — YOUR clean play mints them; spend at the PROMPT MARKET & drafts." Wallet per seat; the shared party pot retires. |
| ⚡ Entropy | **BUILT-RESKIN → ⚡ LUCK** | Same math (nudge +8%/pip max 3, mulligan 2⚡ max 3). The stats-nerd name dies. |
| 📁 Prior | **CUT — deleted entirely (V#8 ✅)** | Cross-run karma "messes up an otherwise fresh run." `luck_profile.gd` + `rift_prior.cfg` + the check-row + the carry + the toast all die; no fold into starting LUCK. In-run comeback pity keeps (resets with the run). |
| ⏻ Charge | **BUILT-KEEP** | Legend line + one-shot first-gain tooltip: "⏻ feeds THE KILL SWITCH — cash it at this floor's Seal." Faucet curve retuned (the walker's sloppy-96% generosity is a known flag). |
| Wounds | **BUILT-KEEP + readout** | Header pips: "▓ CORRUPTED SECTOR −20% max HP" per seat. The run's only HP stake, finally visible between fights. |
| Integrity (raid) | **CUT — finish the kill** | Re-price the 5 tickets (dead heal/patch payloads) + the overtime_daemon wager (stakes a retired number — the warning is a bluff) into live goods. Drop the integrity row from raid check breakdowns. |
| 🔑 API key | **BUILT-RESKIN → ACCESS KEY / CREDENTIAL REQUEST** | Same code; the pickup surfaces on THE QUEUE as a visible lead ("fetch credentials at [node] — opens the 401 route"). Best-taught loop in the game; now also opens the SERVER ROOM. |
| Credential shards | **BUILT-RESKIN → ROOT ACCESS** | The Ring-0 gate presented as the floor's mandatory spine quest: a 0/3 progress bar + pickup toasts (today they tick silently). Mechanics unchanged. |
| 📋 Tickets | **BUILT-KEEP + re-price + print** | §10. |
| Marks / flags | **BUILT-KEEP** | "A mark on your file" stays deliberately murky — one sanctioned mystery. |
| Attempt tokens | **NEW → BACKUPS** | The wipe budget IS your backups (start 3). A wipe = "RESTORING FROM BACKUP…". "+1 BACKUP" is the Market/ticket item. Stakes model verbatim, fiction-named. |
| Reroll charges | **NEW → REGENERATE charges** | Banked, scarce, earned (tickets/BENCHMARK) or bought. The draft button says "REGENERATE (1)". Rerolls-out honored. |
| drop_pity / check_fails | **BUILT-KEEP, invisible** | Pity only ever helps; it may stay hidden. |

**Governance rule (standing):** *no new in-run currency ever ships without retiring one.* The
header carries exactly **three meters (⏣ ⚡ ⏻)** + wound/curse pips + situational keys/tickets.
Pocket items (BACKUPS, REGENERATE, keys, schematics) live in a pocket row, not as meters.

### Source → reward (the whole table a player ever needs)

| Source | ALWAYS pays | Sometimes | Status |
|---|---|---|---|
| Won fight | boon pick (1-of-3) + minted ⏣ | ticket/deed progress; salvage ⏣ on repeats | BUILT-KEEP |
| ELITE | keystone 1-of-2 (first of run) + curio roll + fat ⏣ | schematic | NEW (the post-purge drop-roll site — settled) |
| SEAL | checkpoint + oath cash-out + drop event + market phase | first-kill signature (banks on a WIN only — kept) + the locked need/greed BONUS roll with AI banter when its build claim lands | BUILT-KEEP (+NEW locked stack) |
| MYTHOS (finale) | **META payout** (XP/unlock progress + a carry-out) — never an in-run drop | — | NEW (locked design) |
| MARKET | what the price tags say | — | NEW |
| JAILBREAK | the printed deal | — | NEW |
| EVENT | the printed choice fx | flags that ripple to later nodes | BUILT-KEEP |
| COOLING | your pick: repair / purge / +15⏻ | — | BUILT-KEEP + NEW fork |
| CACHE | +25⏻ + ⏣ | schematic | BUILT-KEEP |
| BENCHMARK / CAPTCHA / SERVER ROOM | the printed prize | — | NEW |
| Ticket turn-in | the reward printed at pickup **OR +1 BACKUP** (the fork, every time) | SPRINT RETRO on closing all | BUILT-KEEP + NEW fork |
| Oath kept | ⏣ purse + roll bend + a Ledger row (banks win or lose) | — | BUILT-KEEP |

### The legibility contract — what the UI must state, where

1. **On every node, before entry:** kind + one-line contract + fight-tier pips. Mystery = WILD
   only (~4%), and even WILD prints its fight tier.
2. **On every check/wager button:** the % AND both legs — "72% — on ✓: +2⏣ · on ✗: 1 corrupted
   sector" (the `_fx_hint` formatter exists; render it on all legs, not just free choices). This
   also teaches that fails are soft, free.
3. **One legend line** under the node legend: "⏣ TOKENS — spend at the Market · ⚡ LUCK — bend
   the dice · ⏻ CHARGE — cash at the Seal."
4. **Plain words in the breakdown:** "eligibility base" → "base odds"; "INTERRUPT ×2 +24" → "2
   of your boons fit +24" — and **boon cards print their tags at draft**, so the audit trail
   becomes auditable.
5. **One verdict frame, pass or fail:** "ROLLED 43 vs 76%."
6. **Tickets print their reward** at pickup, in the header list, and at the turn-in fork.
7. **Wound pips + curse pips on the header; shard pickups toast; first-⏻ tooltip fires once.**
8. **No flavor lies:** the entropy daemon's "REROLL THE FLOOR" button says what it actually
   does, or the choice dies.

---

## 10 · QUESTS — the tickets verdict + the in-raid design

**VERDICT: one grammar, two ledgers — merge the shapes, keep the surfaces.** All three
architects and all three judges converged; treat as settled. One shape taxonomy, one authoring
format, one UI vocabulary across raid and zones — but the **run ledger** (raid: tickets die with
the run, pay run economy) and the **world ledger** (zones: persist, pay access/pool/standing)
never mix. The locked Split holds by construction: *reward lane is a property of the surface,
not the shape.* Persistence, DOOR shapes, ZONE REMEMBERS, and guest-world binding never enter
the raid; the one sanctioned bridge stays one-way — zone DOOR tickets may **read** seed-verified
raid results and pay the collection lane world-side (Bill's beloved interconnection, extended
across surfaces without breaking the law).

**In-raid quest design:**

| Piece | Design | Status |
|---|---|---|
| **THE QUEUE** | A floor-start ticket board: Floor 1 offers 1 (to teach), floors 2–4 offer 2–3; pick up what you like. Every ticket prints its reward on the board and in the header. The single best legibility surface any draft produced. | NEW (UI over built ticket state) |
| **ROUTE tickets** | Today's pickup → same-lane turn-in, forfeit on lane change (the routing tension is the point), ≤1/lane placement math kept. | BUILT-KEEP (re-priced) |
| **DEED tickets** | Performance objectives on the built oath-detector tech (`seat.diag`): "TICKET-88: zero missed interrupts across 2 fights → pays a REGENERATE charge." Quests that read your play, not your feet. | NEW (cheap) |
| **ESCORT tickets** | The zone slice ported run-scoped: carry a VOLATILE payload N nodes; intervening fights gain ONE enemy-side mutator (a burden, never a buff, riding `(seed,spec)`); turn-in pays fat (+1 BACKUP or a curio). The push-your-luck ticket the Mewgenics steal explicitly parked FOR the raid. | NEW (port; engine proven behind `ESCORT_PREVIEW`) |
| **The turn-in fork** | EVERY ticket close offers: the printed reward **OR +1 BACKUP.** Tickets are the earned attempt faucet, exactly as the stakes model specifies — one consistent UI moment. | NEW |
| **SPRINT RETRO** | Close every ticket on a floor → the set bonus (repair + refuel). | BUILT-KEEP |
| **SEV-1 ESCALATION** | One cross-floor ticket per run, picked up on Floor 2, escalating each Ring, turning in at Mythos's door for a fat payout — the long-arc thread. | NEW — **parked for v1.1** pending Verdict #10 (medium build weight) |
| Ticket rewards | Re-priced into LIVE goods only: repair / refuel / ⏣ / ⏻ / REGENERATE / +1 BACKUP. No dead integrity payouts (§11). Helpdesk fiction stays — jokes live inside realm doors. | BUILT-RESKIN |

Zone TICKETS v2 proceeds overworld-side untouched (W2); the shared grammar doc simply names both
ledgers.

---

## 11 · THE CUT LIST

1. **GATE nodes + solo exams** — `KIND_GATE`, quota, `GATE_ENC`, the sim's one-gate assert.
   Ratifies THE PURGE in the map layer; ELITE inherits the drop-roll duty. **CUT**
2. **Integrity in the raid, completely** — the 5 tickets' dead heal/patch payloads, the
   overtime_daemon's bluff wager stake, the integrity check-row. The missed half of Kill-Switch
   P2, finished. **CUT**
3. **The 1⏣ draft REROLL + LOCK** — replaced by banked REGENERATE charges (rerolls-out, locked);
   UPSELL stays. **CUT**
4. **The 3-floor shape / Vorathek as a mere entry fight** — promoted per §2. **CUT**
5. **The mid-raid BANK & LEAVE fork** — superseded by stakes-model checkpoints; leaving is just
   suspending now. **CUT**
6. **Wall-clock map seeding** — descent maps derive from the run seed. **CUT**
7. **Jargon display names** — "Prior," "Entropy," "eligibility base," "feed ⚡ to bias," the
   split verdict framing. **CUT**
8. **The entropy daemon's fake "REROLL THE FLOOR" text** — flavor that lies about fx. **CUT**
9. **Trash enrages at 4–5× TTK** — retightened to ~1.5–1.7×. **CUT**
10. **Mystery-by-default** — every node/check/ticket prints its contract; opacity is rationed to
    WILD (~4%) + marks/flags. **CUT**
11. **Resource-gathering as a node concept** — formally dead (§5). **CUT**
12. **The six frozen legacy solo events** — stay out of the raid pool permanently. **CUT**
13. **Run-long timing curses** — never exist (§7 hard rule). **CUT (pre-emptive)**
14. **📁 Prior / STANDING — the whole cross-run karma concept (V#8 ✅)** — `luck_profile.gd`,
    `user://rift_prior.cfg`, the check-breakdown row, the run-start carry, the bank toast, the
    parked online-Prior follow-up. Fresh runs stay fresh. **CUT**
15. **The second-module long-raid clause (V#7 ✅)** — declined for the raid; one module per
    run stands. **CUT (declined)**
16. The standing dead list stays dead: no PvP, no crafting/materials, no dailies/lockouts/FOMO,
    no account meta-currencies, no persistent power sold anywhere, no 1-to-x scaling, no cheap
    reroll creeping back.

---

## 12 · WHAT SURVIVES UNCHANGED (explicit KEEP — nobody rebuilds these)

- **The map generator core** (`run_map.gd`): 3-lane layered DAG, same-lane spine, 45% crossings,
  quota-bag + rng-stream idiom, backdoor + key mechanics, node-dict serialization contract, BFS
  completability. Only inputs change.
- **MapFx.apply** as the ONE fx applier; **CampaignCore** as the ONE campaign rulebook; the
  canonical `enter_node` order (visited→shard→ticket→key).
- **The INFERENCE CHECK engine** whole: the % math (base + tags + aspect + role + in-run pity +
  ⚡ nudges, clamp 5–95 — *the cross-run Prior term drops, V#8 ✅*), the pure hashed die,
  branches, cross-node flags, wagers, mulligans, the co-op seat-picker. Presentation changes
  only, plus the one term removal.
- **THE KILL SWITCH**: charge faucets (cooling/cache/skirmish/events), the arming panel (already
  the best-explained piece in the game), SURGE/SHIELD/STALL via `RaidMarks`. Numbers retuned,
  mechanics untouched.
- **The post-fight ceremony order verbatim** (DECK-LAYOUT §1): writeback → oath verdict →
  RECKONING → loot beat (drops-are-events; salvage on repeats) → boon draft (rig-wire first,
  mint, you then AI seats) → continue. Pre-Seal: arming → oath → launch.
- **Run-flow grants**: creed at start · rig wire after fight 1 · module end of Floor 1 ·
  keystone 1-of-2 at first elite · free re-wire end of Floor 2 · oaths at Seals — mapped to 4
  floors, unchanged in kind.
- **THE STAKES MODEL verbatim**: floor checkpoints, wipe budget 3, cleared-stays-cleared, finale
  pays META, oaths bank win-or-lose, suspend-don't-pause.
- **Draft 2.0**: 1-of-3, rarity-as-frequency + pity, synergy tags, UPSELL, skill mint
  (`Draft.mint`), AI-seat drafts in seat order. *(One amendment rides V#11 ✅: the shared token
  bank becomes per-seat wallets — the mint math and everything else keeps.)*
- **The drop ceremony**: two-step rarity-first roll, pity, EQUIP/REPLACE/SCRAP, first-kill
  signature banks on a WIN only, oath purses (Sev × stakes).
- **The PACK engine** (heat-carry, walk-in valleys) and the Forge (id-is-recipe bodies/tiers) —
  this plan just points them at raid floors.
- **Ticket placement math** (≤1/lane, pickup early, turn-in late same-lane) and SPRINT RETRO.
- **All COMBAT PILLARS and the engine**: single telegraph stream, dodge ration,
  interrupt-by-ability, warband law (exactly 4 seats), overworld power rule, `CombatCore` the
  pure deterministic reducer — nothing here touches any of them.
- **The Realm-1 fiction**: helpdesk tickets, 401/200, corrupted sectors, the Kill Switch,
  privilege Rings, "spend them responsibly." The jokes that land all stay; only the stats-jargon
  dies.

---

## 13 · LANDING NOTES (for whoever builds this — conflicts · rows · risks)

**Conflicts with in-flight work:**
- **THE PURGE** (worktree `../wow-purge`, 🔨): this plan's GATE cut overlaps the purge's gate
  deletion — **land after the purge merges.** The plan formally settles the purge's open
  hand-wave: ELITE nodes are the replacement drop-roll site. (Recon confirmed GATE nodes still
  live on main as of this writing.)
- **`draft.gd` claim queue** (BUILD-LEDGER §0 hotspot): REGENERATE charges, ⚠ welded-downside
  boons, elite curio rolls, Market stock + the already-queued rarity tier-roll engine / loot
  two-modes / EASE dial all land on the one roll pipeline — serialize claims, keep `draft_sim`
  green. **V#11 ✅ adds:** the shared token bank → per-seat wallets — `run.tokens`
  (`run_state.gd:23`) becomes per-seat; `Draft.mint` switches its input from `state.diag` (the
  human-only mirror — why AI seats earn nothing today) to each seat's `seat.diag`
  (`combat_core.gd:629`, already tracked) and deposits to the earning seat; UPSELL spends the
  seat's own wallet; AI market spend = player-directed or AUTO. Online: wallets ride the
  campaign broadcast like tokens do today.
- The Depth/endless parallel thread owns Depth — this plan deliberately does not touch it.
- The ESCORT port depends on the unmerged zone slice (branch `escort-ticket`,
  `ESCORT_PREVIEW`) which still owes its lane-law reward — the raid port inherits that debt.
- Other live worktrees (`cask-policy`, `tempo-pilot`, the SLATE MACHINE) don't collide with the
  map layer but share `raid_hud.gd` — coordinate HUD-touching claims.

**Build risks / must-flag:**
- **ONE deliberate `raid_map_sim` re-baseline**: rows/quotas/floor-count/event-pool changes
  shift every map's rng. Do it as one bang. The same commit must: update the hand-mirrored
  ticket walker alongside `CampaignCore.ticket_at` (known divergence trap), retire the one-gate
  assert, add the new invariants (elite+market reachability BFS · pre-Seal valley band ·
  no-stacked-spikes · keystone-at-first-elite), and add a per-fight ttk column (recon pain
  point).
- `FLOORS` ring-as-behavior-key sites (~5): salvage table needs a `1:` entry; filler-tier
  `clampi` is already correct for rings 3/2/1/0; oath stakes, `floor_fights` (+1 list),
  `_advance_floor` grant indices all move.
- Node-dict serialization contract: new kinds touch `to_dict`/`from_dict`/fingerprint/
  server-broadcast together, once.
- **V#8 in code:** `map_check.gd` drops the Prior term (a small odds shift on every check —
  fold it into the one re-baseline bang, not a separate reset); delete `luck_profile.gd` +
  the `rift_prior.cfg` read/write + the P4 "online Prior" follow-up wherever it's parked.
- The fight budget assumes players route to 1 elective elite per floor (by chance ~0.7) — if
  playtest shows skipping, the budget loses ~4–6 combat min and Verdict #3 gets revisited.
- Ceremony time (~34 min of the 145 budget) is the one unmeasured band — no probe times
  menus/drafts; consider a ceremony-time probe before trusting the total to ±10 min.
- Charge economy retune owed (walker sloppy hits 96% — too generous); 4 floors add faucets;
  retune at the re-baseline.
- StS2 numbers behind the genre pyramid are Early Access — re-verify before load-bearing tuning.
- Sloppy tier remains a wall (0% deep Seals) — this plan widens skill spread further at
  Gemini/Mythos budgets; the healer-regen good-tier lever is the sanctioned kindness knob, not
  fight shortening.
- Judge-flagged fixes already folded into this spec: no post-Mythos market phase (META ceremony
  instead) · duty-cycle law restated so law and table agree · no run-long timing curses · Ring
  numbering 3/2/1/0 · shop scarcity re-audited at ~21 fights · fight-tier pips replace a
  separate attention-unit glyph.
- Plain-language check done: all new names are fiction words; no designer jargon reaches the
  screen. CREDENTIAL REQUEST is a display reframe of the key pickup, not a new ticket object.

**Change log:**
- 2026-07-10 — v1 authored from the raid-rebuild workflow (Bill's zoom-out brief + mid-brief
  minigame addendum); 🟡 at Bill's verdict.
- 2026-07-10 — all 12 verdicts in (V7 no 2nd module · V8 Prior deleted · V9 WILD ~10% · V11
  per-seat wallets); v1 LOCKED; WORLD-PLAN amend banners placed.
- 2026-07-10 — **SLICE 1 (the map bang) BUILT & MERGED `ee18e05`**: 4 floors · new kinds +
  stub layer (`RunMap.effective_kind`, `*_LIVE` flags) · gen invariants proven
  (`raid_map_sim._prove_descent`) · V#8 Prior deletion shipped · fight ladder + skirmish
  enrages · protocol v15 · ONE deliberate re-baseline, solo maps + raid combat byte-identical.
  Interim notes: elite keystone = reserved slot (per-class deck slices) · online elite fights
  its captain solo until the server pack pass · Forge body enrages untouched (zone-shared).
- 2026-07-10 — **SLICE 2 (the legibility pass) BUILT & MERGED `1f5e051`**, two commits:
  **2a display (byte-identical)** — `KIND_CONTRACT` one-liners + fight-tier pip rects on the
  node doors (contract on hover + tooltip; WILD stays sealed) · header restructured into the 3
  meters (⏣⚡⏻) + wound pips + reserved curse row + first-⏻ teach + currency legend + de-GATE'd
  kind legend (⏣ moved off gear_line) · both-legs check hints via new `win_fx`/`lose_fx`
  descriptor fields folded with the wager stake (offline + online) · display renames
  (⚡"entropy"→"LUCK", "eligibility base"→"base odds", "feed ⚡ to bias"→"spend ⚡ LUCK…",
  fx-hint "integrity"→"party HP", THE ENTROPY→THE LUCK DAEMON) · §9.8 "REROLL THE FLOOR"
  flavor-lie reworded · orphan `luck_profile.gd.uid` deleted. **2b the integrity kill** —
  `map_check` check-row deleted · overtime wager stake integrity→tokens · rollback `catch`
  orphan key removed · 5 tickets + SPRINT RETRO + Ticket Stub re-priced (drop dead heal/patch,
  keep repair/mana, pay ⏣) · `map_wager_probe` decoupled to a synthetic tokens wager. Tokens-
  primary re-price keeps raid_map_sim FIGHT checksums identical (repair/mana unchanged; ⏣ is
  sim-carry-invisible) — only the retired-integrity/fracs REPORT column shifts (intended). NO
  protocol bump (the net `integrity()` desync hash is a different thing, untouched; `integrity_
  probe` stays green). Names BACKUPS/REGENERATE/DEPRECATE reserved only (mechanics = slices 3-5;
  draft REROLL economy untouched). ⏳ heavy verify (raid_map_sim re-baseline · verify-all ·
  net_map_smoke) deferred to a nightly run per Bill (OOM-prone under concurrent box load).
- 2026-07-10 — **SLICE 3 (PROMPT MARKET + per-seat wallets) BUILT & MERGED `fd8b895`**, three
  commits behind a 6-reader recon (which disambiguated buildable-vs-deferred + the online scope).
  **3a per-seat wallets (V#11):** `Draft.mint_diag(diag,cfg,cls)` mints each seat from its OWN
  `seat.diag` (the human's mint unchanged — `mint` delegates → byte-identical); `raid_hud._mint_
  seats` credits all 4 wallets post-fight; the AI-draft shared-bank mirror is deleted (AI drafts
  spend their own ⏣); `commander_probe` re-pointed to per-seat independence. **AI seats START
  EARNING** (before, `Draft.mint` read only the is_player mirror). **3b rerolls-out (§11 #3):**
  `run.regenerate` charges are the only reroll — `Draft.reroll` spends a charge (same draft_rng
  draw), `lock`/`reroll_kept`/`REROLL_COST`/`LOCK_COST` deleted, `draft_screen` shows "REGENERATE
  (n)" + drops LOCK, Hot Reload → +2 charges on equip; `draft_sim` `_test_lock`→`_test_regenerate`.
  fight_seed never touches draft_rng → NO fight shift, only draft_sim's transcript re-baselines.
  **3c THE MARKET:** `RunMap.MARKET_LIVE=true`; new `MarketScreen` (THE SCRAPER's shop); `_show_
  market` rolls stock on a (map_seed,node) rng — CURIO ×2 (unlocked pool, rarity-priced 6/8/10) ·
  REGENERATE (4⏣) · PATCH (5⏣), ~+30%/floor; per-seat BUY + AUTO (AI spend own wallets, banter);
  KIND_MARKET branch (mandatory, no-default=soft-lock); post-Seal recovery MARKET PHASE; Hash-
  grinder reframed (×2 income → market −1⏣); `raid_map_sim` KIND_MARKET case + `tokens@market`
  diag + flat mint estimate (sanctioned re-baseline); new `market_probe` (in verify-all) drives
  the real HUD end-to-end. **Deferred:** +1 BACKUP (no wipe budget — printed SOON) · DEPRECATE
  (curse=slice 4, boon-scrap=follow-up) · online market (safe no-op, NO protocol bump). ⏳ nightly:
  the draft_sim/raid_map_sim statistical re-baselines · full verify-all · net_map_smoke.
- 2026-07-10 — **SLICE 4 (THE JAILBREAK curse deals) BUILT & MERGED `a22c1ec`**, two commits
  behind a 5-reader recon (which confirmed TIMING is buildable — `s.config` is fresh per fight so
  a `window_tighten` mark is a real windows−10% tax with no per-boss work). **4a the curse engine
  (byte-identical when dormant):** `RaidMarks` gains two guarded mark keys — `seat_hp_cut` (HP tax,
  auto-repairs since a mark clears each fight) + `window_tighten` (TIMING tax, scales the fresh
  `s.config.strike_*` windows read live at grade time); `RunDirector.curses` (cap 2) +
  `deprecate_uses`; `raid_hud` curse core (`_add_curse` w/ cap-2 + the HARD RULE, `_curse_pips`,
  `_apply_curse_marks` fold+tick, ECONOMY hooks in `_mint_seats`/`_market_price`, `_apply_map_fx`
  curse/regenerate/purge keys, the DEPRECATE market slot + Cooling purge fork); `_fx_hint` prints
  the bite; `curse_probe` (verify-all). **4b the node LIVE:** `JAILBREAK_LIVE=true`, KIND_JAILBREAK
  dispatch → `_show_jailbreak` (two deals rolled on a (map_seed,node) rng via `_map_stop`, both
  halves printed, WALK AWAY free, cap-2 "cell full"); 5-deal gentle pool (V#4); `raid_map_sim`
  KIND_JAILBREAK walker case (sanctioned re-baseline). **Deferred:** DECK tax (run-length
  ability-poison — the `perform()` gate is one line but the spec-threading offline+online is the
  cost) · welded-downside boons · event-curse legs · online (no-op, NO protocol bump). ⏳ nightly:
  raid_map_sim run-trace + statistical re-baseline · full verify-all · net_map_smoke.
