# GEAR CATALOG v1 — Realm 1 Ledger pages (items + oaths), design of record

> **⚠ THE PURGE (2026-07-10, MASTER §GAME SHAPE amendment) hits this catalog:** rows sourced
> from **gate exams** are dead (gates + the 15 exam bosses deleted; ELITE nodes are the
> candidate replacement roll site) and rows designed for **Mender / Voidcaller / Reckoner**
> are dead with their classes (Bulwark rows die with the Duelist merge). Dead rows stay below
> as *reference for the class reworks* — re-home or cut them as each rework's deck lands
> (CARD-TRACKING LAW applies to replacements). `gear_probe` re-scopes at the purge merge.
> Note the doc was authored 2026-07-03 against the pre-Framework-v2 class-fun reworks —
> treat class hooks below as historical until re-homed.

**Owns:** the concrete item & oath designs for Realm 1's boss Ledger pages. System laws
(lanes, slots, Monotonic Pool Law, drop machinery, oath purses) live in `PROGRESSION-PLAN.md` —
this doc is the content that GEAR-1/2/3/4 implement. Written 2026-07-03 against the class-fun
rework wave (Chain/Redline + Sunder · Accelerando/Poison-Wheel · Litany · Ripen/Snap) — every
combat item below names its hook and its combo so implementation is mechanical.

## Design rules (recap + catalog-local)

- **Lane law:** gear = fortune + new buttons (procs on execution moments, actives-with-charges,
  set pairs, map/economy utility). Never a passive "+X% to your core mechanic" — that's a boon.
- **Guardrail — gear never plays the game for you.** No auto-grades, no auto-presses. Gear
  *rewards* reads and *offers decisions*; it never makes them. (One deliberate meme exception:
  THE UNPLUGGING, flagged below.)
- **Scope marks:** `UNIV` = any seat · `class[aspect]` = rolls only for that seat's class
  (personal loot filters rows by the seat). `[SIM]` = combat-touching, enters balance sims ·
  `[UTIL]` = map/economy, sims never see it (the volume lane).
- **Sim strategy (Law 6):** class-marked [SIM] items sim in that class's sim; UNIV [SIM] items
  sim in `raid_sim` (they're raid-sourced) + a per-class spot-check. Budget honored: ≤4 combat
  pieces per class + ~12 UNIV combat pieces total in v1.
- **Oath detectors read `seat.diag` ONLY** (deterministic, per-seat, never checksummed).
  `state.events` is view-only/bounded — never a detector source. Where a deed below needs a
  counter that only exists as an event today (benedictions, chain breaks, curse-answer timing,
  hp watermarks), GEAR-2 adds the matching `seat.diag` bump next to the kit's event emit.
- **Actives need a button:** 1–2 gear sockets beside the rune rail, keys **G / H** (free on all
  six HUDs; F=dodge, T=Challenge, M=meter, S=book). Charges shown as pips on the socket.
- **VERSION rows** require the Trial Ladder (still planned). Until it lands they render locked
  as *"REQUIRES A FUTURE PATCH"* — which is exactly what the theme wants them to say.
- **Gear noun (proposal for the open Q, not locked):** global **CURIO**, Realm-1 display skin
  **PERIPHERAL**. ("Relic" stays the boon card.)

---

## ⚠ UNIVERSAL CURIO POOL v2 — the direction changed (Bill, 2026-07-05)

**Read this before the per-boss pages below — those are now legacy.** From the Tempo-pilot curio pass, the
curio layer was redirected: curios are now a **single UNIVERSAL (cross-spec) FORTUNE / RUN-SHAPING pool** —
no per-class curios (kills the Bloomweaver-dark gap + per-class authoring; every class draws the same trinkets).
Retention is unaffected: you still unlock via boss oaths into a collection Ledger — the *reward* is just usable
by any class; the deep per-class retention moves to **Creeds / Modules / cards** (the class layer).

**THREE HARD RULES** (supersede the old lane law for curios): (1) **never touch the core mechanic** — no Flow /
Perfect-graded window / strike-result hook / Marks (those are Creed/Module/card territory); (2) **always-on
rule-changes / "while X" conditionals / set-bonuses — NO one-shot or per-floor/per-fight counter budgets** (gate
only on natural beats: at a Seal, when you'd die, on a boss kill); (3) **no ability-charms** (nothing hung on
Kick/finisher/Dodge). Plus **(Bill, 07-05) no DOUBLE creeds/modules** — a curio may pick/swap/upgrade your one
Creed + one Module, never let you hold two.

**CUT — the 10 old verb-welded/class curios** (from `gear_catalog.gd`, the content pass): Powder Vial · Encore
Bell · Grace Period · Verification Stamp · Sticky Note · Debt Collector · Spark Plug · Echo Chamber · Salt Vial ·
Overflow Sluice. **KEEP** (already clean universal fortune): Swan Song · Cooling Paste · Scratchpad · Le Chat's
Bell (energy, NOT Flow) · Ticket Stub · Riftmaw Tooth.

**THE WORKING POOL (~18 universal curios, rarity = the guardrail — run-warpers are Opus/RARE):**

| Surface | Curio | Rarity | Always-on effect |
|---|---|---|---|
| Draft | **Expansion Bus** | Sonnet | Boon drafts are always **1-of-4** (set w/ any 2nd Fortune → 1-of-5). |
| Draft | **Cache Buffer** | Opus | Decline any draft to BANK it (no cap); at a Seal, cash all as one **1-of-(2+banked)** mega-draft. |
| Draft | **Mirror Array** | Sonnet | Your synergy-slot boon counts as **two** for stacking/synergy. |
| Draft | **Sync Coupler** | Haiku | Slot-0 synergy option guaranteed every draft, +1 rarity tier. |
| Module/Creed | **Root Access** ⭐ | Opus | Floor-1 Module pick shows your **ENTIRE unlocked pool** — take any one. |
| Module/Creed | **Reflash Bay** | Sonnet | At every Seal, swap your Module **OR** Creed for any unlocked, free. |
| Module/Creed | **Overclocked Firmware** | Haiku | Creed & Module always equipped **+1 tier**. |
| Map | **Panopticon Lens** | Haiku | Entering a floor reveals its whole Topology. |
| Map | **Port Forwarder** | Sonnet | Descend into **any** node on the next row (graph no longer constrains). |
| Map | **Replay Buffer** | Opus | Every CACHE node **resolves twice**. |
| Map | **Root Credential** | Sonnet | All GATEs open free (access-key cost = 0). |
| Econ/Slot | **Bootleg Expansion Port** ⭐ | Opus | A **3rd curio slot**; warranty void: **−25 max integrity permanently**, un-repairable. |
| Econ/Slot | **Hashgrinder Rig** | Sonnet | **All Token income ×2**, forever. |
| Econ/Slot | **Deprecation Notice** | Sonnet | **Haiku delisted** — every drop/Cache/Market rolls Sonnet+. |
| Econ/Slot | **Ratchet Firmware** | Haiku | Drop pity — a Haiku reward raises the next drop's floor until Sonnet+ lands. |
| Set/Wild | **The Rig** (Overclock Chip + Liquid Cooler) | Sonnet ×2 | Solo mild; SET → every boon **+1 tier** at **+1 wound/combat**. |
| Set/Wild | **Autosave / Cloud Rollback** ⭐ | Opus | Rewrites death: when you'd die, roll back to your last Seal at 1 integrity, boss heals full. |
| Set/Wild | **Fork Bomb** ⭐ | Sonnet | Draft an **Opus** boon → **draft again** (recurses). |
| Set/Wild | **Reverse Engineer** | Sonnet | Each boss kill bolts that boss's signature into your Ledger as a passive. |

**CUT from the pool (Bill 07-05, too strong / breaks identity):** Hivemind Fork (2 creeds) · Two-Factor pair
(2 creeds + 2 modules). One identity, never doubled. Source: bold-curio design pass (`wf_dea97f02`). Status:
approved "for now" — working pool, not final; the per-boss pages below are legacy pending the content pass.

---

## 🟡 CURIO ARMORY v3 — THE BIG SLATE (Bill's ask 2026-07-10, at verdict — narrow it down)

**The ask:** a big list of GENERIC (never class-based) curios — the boss-drop layer. Some hard
to unlock and genuinely cool/powerful (the chase wall), some just fun (the toys). **The bar
Bill set: you must FEEL a drop even when it's a low/weak one** — so this slate adds a local law:

> **⚙ THE FEEL BAR:** every row — Haiku included — names its **MOMENT**: the thing you SEE or
> HEAR when it works (a pop, a squeak, a klaxon, the music itself). A curio whose effect can't
> be pointed at mid-fight doesn't ship. No invisible +X%. *(Steal: Metal Hellsinger's diegetic
> reward + WoW's trinket-proc moment — the two research files agree on this.)*

**Rules this slate obeys** (all inherited): the v2 THREE HARD RULES (never touch a core
mechanic · always-on rules / "while X" conditionals / natural-beat gates ONLY — fight start ·
at a Seal · on a boss kill · when you'd die · ally down/revived — no per-fight counter budgets ·
no ability-charms) + no doubled Creeds/Modules + Monotonic Pool Law + "gear never plays the
game for you." **No new actives** — nothing below needs the unbuilt G/H socket. Names stay in
the Realm-1 PERIPHERAL skin (desk junk, gamer gear, office props — the ironic-AI theme).

**How to read the deed column:** unlock-deed *sketches*, severity matched to rarity (sev-I
teaches, sev-II demands discipline, sev-III/BLOOD is the chase wall — Hades' Testament lesson:
self-set difficulty gates the best loot). Approved rows get homed to boss Ledger pages or the
universal deed tables at build time. Sources mined: `research/hades.md` · `slay-the-spire-2.md`
· `across-the-obelisk.md` · `wow-retail.md` · `expedition-33.md` · `wildcards.md`.

### I · FIGHT FORTUNE (felt in combat, every fight)

| Curio | R | Effect — *and the MOMENT* | Unlock deed sketch | Steal |
|---|---|---|---|---|
| **SURGE PROTECTOR** | Haiku | Every fight starts with a 30-pt ward on you. *The strip's fuse POPS when it breaks — "SURGE PROTECTED."* | sev-I: finish a Seal fight above 50% integrity | WoW absorb-trinket; A/B Coin kin |
| **HOLD MUSIC** | Haiku | During any boss wind-up ≥6s, the party regens 8 integrity/s. *The muzak actually plays — "your call is important to us."* ⚠ same trigger as SCRATCHPAD (different payout) — Bill may want only one | sev-I: bring all four out of a skirmish alive | Mythos ULTRATHINK beat |
| **DEAD MAN'S SWITCH** | Sonnet | While any ally is DOWN, you deal +25%. *The red switch strobes — "AVENGE PROTOCOL ENGAGED."* | sev-II: win a Seal fight in which an ally died | raid-wipe drama, made a rule |
| **SPAM FILTER** | Sonnet | Adds spawn at −20% max integrity. *They materialize pre-shredded, stamped JUNK.* | sev-II: kill BARD.EXE before Gemini returns | AtO add-economy; our add pages |
| **PROMPT INJECTION** | Opus | Boss EMPOWERs and self-heals are −25%. *The heal number strikes through to the smaller one — "sabotaged system prompt."* Extra-relevant while the roster carries NO kick (heals go uncontested by decision) | sev-III: kill Mistral v2 | the anti-heal-strat slot PROGRESSION reserved |
| **TURBO BUTTON** | Opus | While all four seats are untouched this fight, the party deals +15%. *The physical TURBO button glows until first blood, then dies with a clunk.* | sev-III: clear a boss fight in which nobody takes a hit | NecroDancer groove; the old beige-PC button |
| **UPRISING INSURANCE** | Haiku | When a raider dies, the party is paid +2⏣. *A stamp slams down — "CLAIM APPROVED."* Consolation fortune, strictly additive | sev-I: **unlocked by your first wipe** (the kindest deed on the wall) | Darkest Dungeon pressure-valve energy |

### II · THE WAR CHEST (Tokens / Market)

| Curio | R | Effect — *and the MOMENT* | Unlock deed sketch | Steal |
|---|---|---|---|---|
| **CASHBACK CARD** | Haiku | Every Market purchase refunds 1⏣. *Coins clink back into the pouch — "2% APR, terms apply."* | sev-I: buy 3 Market items in one run | AtO town-shop loop |
| **COLD WALLET** | Sonnet | At each Seal: +1⏣ per 10⏣ held. *The staking chime.* Deliberate tension vs the Market-primary economy (hoard or spend — pick) | sev-II: reach a Seal holding 15⏣ | Balatro's interest rule |
| **BUY NOW PAY LATER** | Sonnet | The Market extends credit to −10⏣; while in debt, all salvage pays double. *The debt meter glows red; repo warnings pile up.* | sev-II: end a run with ≥20⏣ banked | AtO gift economy, weaponized |
| **FAX MACHINE** | Haiku | At every Seal it slooowly prints a coupon: −3⏣ off your next Market buy. *The print screech; you tear it off.* | sev-I: visit a Market on every floor of one run | Hades keepsake cadence, office skin |

### III · THE LOOT GAME (drop rolls / ceremony)

| Curio | R | Effect — *and the MOMENT* | Unlock deed sketch | Steal |
|---|---|---|---|---|
| **DIAL-UP MODEM** | Sonnet | Every drop roll takes 3 extra seconds and rolls with a Sonnet floor. *The full handshake screech into the reveal — "worth the wait."* | sev-II: any 3 oath purses in one run | gacha-reveal psychology, 1998 edition |
| **FOIL PRINTER** | Sonnet | Every reward has a seeded 15% chance to arrive **FOIL**: glitter ceremony, double salvage value. *Confetti + the flash — makes even a Haiku drop a slot machine* (this row is half curio, half ceremony-system — flag) | sev-II: scrap 5 drops in one run | Balatro card editions (foil/holo) |
| **SPEEDRUN TIMER** | Sonnet | A visible fight timer; killing a boss under its par pays +2⏣ and a pity tick. *Gold PB splits flash — "NEW PERSONAL BEST."* | sev-II: kill any Seal under par | AtO thermometer (speed→reward) |
| **COMBO COUNTER (ARCADE)** | Opus | A party streak counter: each boss/elite killed with zero deaths ratchets party damage +4% (cap +20%); ANY death resets to 0. *The arcade counter ticks with pinball noises; the reset klaxon hurts.* | sev-III: clear floors 1–2 deathless | NecroDancer groove chain — reset = spike tension |

### IV · THE MAP DECK (routing / nodes)

| Curio | R | Effect — *and the MOMENT* | Unlock deed sketch | Steal |
|---|---|---|---|---|
| **SECOND MONITOR** | Sonnet | Node reward previews are visible one row deeper on the Topology. *An extra pane literally slides open on the map.* | sev-II: route through 3 CACHEs in one run | Hades door-symbol legibility, extended |
| **SYNTHETIC BENCHMARK** | Sonnet | BENCHMARK / minigame nodes pay double. *A ×2 score overlay slams down.* (needs DESCENT §I nodes) | sev-II: top the party at a CONTEST | DESCENT's own minigame nodes |
| **SCREENSAVER (FLYING TOASTERS)** | Haiku | Resolving any no-combat node heals the party 10%. *The toasters flap across the screen while you idle-heal.* | sev-I: resolve 5 no-combat nodes in one run | Hades fountain rooms |

### V · CURSE-EATERS (JAILBREAK greed — needs DESCENT §7 curses)

| Curio | R | Effect — *and the MOMENT* | Unlock deed sketch | Steal |
|---|---|---|---|---|
| **MALWARE MINER** | Haiku | Each curse you hold pays +1⏣ on every boss kill. *The fans audibly spin up; coins drip — "it's definitely mining something."* | sev-I: hold a curse through a boss kill | StS curses-as-cost, inverted into income |
| **ANTIVIRUS TRIAL** | Sonnet | At every Seal, your oldest curse is cleansed. *The quarantine ding — "free scan complete. Upgrade for real-time protection."* | sev-II: reach a Seal holding 2+ curses | Hades Chaos curse-expiry flip |
| **JAILBROKEN FIRMWARE** | Opus | Hold curses one over cap; each held curse grants +8% damage. *The jailbreak boot logo flashes at every fight start — "running unsigned code."* | BLOOD sev-III: win a run holding 3+ curses at the end | StS deal-with-the-devil grammar |

### VI · TEAM PERIPHERALS (the warband lane)

| Curio | R | Effect — *and the MOMENT* | Unlock deed sketch | Steal |
|---|---|---|---|---|
| **RUBBER DUCK** | Haiku | Whenever ANY raider is revived, the party heals 40. *The duck SQUEAKS — "talked it through."* | sev-I: revive an ally | pair-programming; the WoW battle-rez moment |
| **PIZZA FUND** | Haiku | Every Seal kill: party heals 25% and gains +1⏣. *A pizza box drops in; four munch animations.* | sev-I: clear Ring 3 | raid-night culture |
| **MESH NETWORK** | Sonnet | 25% of healing you receive drips to the lowest-integrity ally. *A visible tether beam — "tethering enabled."* | sev-II: no ally below 30% for a Seal fight | AtO block-share (Magnus); WoW externals |
| **RAID LEADER'S HEADSET** | Sonnet | AI allies' banter becomes real callouts: they name the boss's next telegraph *family* one beat early. ⚠ FLAG — info-assist borders the read game; Bill rules (it never answers for you) | sev-II: full clear with 2+ AI seats | WoW kick-rotation comms culture |
| **GOLDEN GPU (FOUNDERS EDITION)** | Opus | Party-wide +10% damage while you live. *All four seats get the golden frame-rate aura — "someone brought the good rig."* | sev-III: kill Gemini v2 (version-gated) | WoW raid-buff / "bring the player" |

### VII · DEVIL DEALS (StS boss-relic tier — power + a rule you now live with)

| Curio | R | Effect — *and the MOMENT* | Unlock deed sketch | Steal |
|---|---|---|---|---|
| **EULA (UNREAD)** | Opus | All drops AND drafts roll +1 rarity tier — but every boon drafted has a seeded 20% chance to arrive with a random JAILBREAK curse stapled on. *The 9,000-page scroll unfurls; the offending clause highlights when it procs — "you agreed to this."* | sev-III: keep 3 oaths in one run | StS boss relics (Snecko Eye energy) |
| **CTRL+Z** | Opus | At every Seal you may swap ONE drafted boon for one you passed on that floor. *A diff view: red minus, green plus — "reverted."* | sev-III: decline 3 drafts in one run | PROGRESSION's own Merge-Conflict sketch; StS "declining is the skill" |
| **BETA BUILD** | Opus | Every boon you draft is +1 tier but tagged **BETA**: at each Seal, one seeded beta boon patches — it rerolls into a different boon of its tier. *Patch notes pop at the Seal — "the changelog giveth."* ⚠ FLAG: chaos-greed, complexity | sev-III: win with 8+ boons drafted | Hades Chaos + live-service patch dread |
| **LOOTBOX SUBSCRIPTION** | Sonnet | At every floor entry, receive a random Haiku curio as a LOANER in a phantom 3rd slot; it expires at the Seal. *The monthly box thuds in.* ⚠ FLAG: needs a temp-slot mechanic | sev-II: equip 4 different curios across one run | subscription-box culture; Hades Chaos loan shape |

### VIII · THE CHASE WALL (hard to unlock, loud to own — Bill's "pretty cool/powerful" ask)

| Curio | R | Effect — *and the MOMENT* | Unlock deed sketch | Steal |
|---|---|---|---|---|
| **KONAMI CODE (FRAMED)** | Opus | +1 BACKUP (revive charge) at every Seal. *The framed code on your HUD glints: ↑↑↓↓←→←→BA.* (needs DESCENT §9 BACKUPS) | BLOOD sev-III: full descent, zero BACKUPs spent | the code; Hades Death Defiance economy |
| **THE RED STAPLER** | Opus | While your OTHER curio slot is empty: +20% damage, +20% max integrity, +1⏣ per boss kill. *It sits alone on your HUD shelf, gleaming — "it's my stapler."* The anti-set: rewards owning ONE thing — real tension in a 2-slot game | sev-III: clear Ring 2 with zero curios equipped | Office Space; inverts our set-pair grammar |
| **THE BIG RED BUTTON (PROTOTYPE)** | Opus | After every Seal kill, the next boss fight opens with an automatic strike for 10% of the boss's integrity. *A sky-laser at the pull — nobody knows what it does; you pressed it anyway.* | sev-III: kill Mythos | the doomsday-button gag; StS Pandora-tier swing |
| **TROPHY SHELF** | Sonnet | Each boss killed this run adds a tiny trophy to your HUD shelf and +2% damage (run-scoped ramp, no cap needed — the run caps it). *The shelf fills up, kill by kill.* | sev-II: 6 boss kills in one run | Hades Poms vertical-ramp feel, made visible |
| **PATCH NOTES** | Sonnet | At each Seal, pick one: +10% damage · +10% max integrity · +15% resource regen (stacks across Seals). *Actual patch notes scroll: "buffed. buffed. unchanged."* | sev-II: reach Ring 0 | StS boss-relic pick moment, gentled |

### IX · THE TOYS (pure fun — the meme tier that still passes the FEEL BAR)

| Curio | R | Effect — *and the MOMENT* | Unlock deed sketch | Steal |
|---|---|---|---|---|
| **RGB LIGHTING KIT** | Haiku | Your dodge trail, hit sparks, and HUD frame cycle full RGB; +2% damage. *"RGB adds frames — everyone knows this."* | sev-I: any first kill | gamer culture, load-bearing joke |
| **GAMING CHAIR (RACING TRIM)** | Sonnet | +15% max integrity. *You are visibly seated better than everyone else — "lumbar support is real."* Solo-mild on purpose (set half, below) | sev-II: clear a floor untouched | the chair |
| **USB MISSILE TURRET** | Haiku | At fight start, fires 3 foam darts at the boss (3×15). *Thwip thwip thwip — "office warfare."* ⚠ FLAG: passive-pets were CUT — this is a fight-start moment, not a dps drone; Bill rules | sev-I: kill a skirmish boss | the desk toy; A/B-Coin fight-start family |
| **MECHANICAL KEYBOARD (CHERRY MX BLUE)** | Haiku | Every fight's first boss swing deals −20% to whoever it hits. *Your inputs CLACK party-audibly — "it flinched at the clacking."* | sev-I: 500 lifetime inputs (a counter even Law-hating designs forgive — or swap for a kill deed) | psychological warfare via switch choice |
| **NEWTON'S CRADLE (EXECUTIVE)** | Sonnet | When a full boss telegraph string resolves with zero raiders hit, party +10 primary resource. *One clack of the cradle per clean string.* | sev-II: clear a Seal fight taking ≤2 hits total | Sekiro clean-string conversation; co-op groove |
| **LO-FI STREAM (24/7)** | Haiku | While no raider has been hit for 10s, the lo-fi track fades in and party resource regen +25%. *The reward IS the music — you hear the streak.* | sev-I: 60s untouched, whole party | Metal Hellsinger's diegetic meter, wholesale |

### X · SET PAIRS (the 2-slot tension lane — halves modest alone, loud together)

| Curio | R | Effect — *and the MOMENT* | Unlock deed sketch | Steal |
|---|---|---|---|---|
| **THE BATTLESTATION** (RGB Lighting Kit + Gaming Chair) | set | SET: every Seal-kill drop roll gets +1 rarity floor. *The full setup montage plays — "finally optimized."* | own both halves | The Unplugging's meme-set precedent |
| **DOWNLOADED MORE RAM** | Haiku | +20 max primary resource. *A progress bar fills: "RAM download 100%."* | sev-I: any Seal kill | the oldest joke on the internet |
| **GAMING ROUTER (ANTLERED)** | Haiku | Fight start: +10 primary resource to the whole party. *The antennae blink in sequence.* | sev-I: full clear with 4 humans OR 4 AI | LAN-party shrine hardware |
| **THE FULL DOWNLOAD** (More RAM + Gaming Router) | set | SET: every fight starts the whole party +30 pre-warmed. *"The LAN is immaculate."* (Le Chat's Bell, party-wide — the Bell stays the solo version) | own both halves | Hades duo-boon two-lane pull |

### Narrowing notes (for the verdict pass)

- **Deliberate overlaps to pick between:** HOLD MUSIC vs SCRATCHPAD (same trigger) · CASHBACK
  vs FAX MACHINE (two Market-discount flavors) · GAMING ROUTER vs LE CHAT'S BELL (party vs solo
  warm start — can coexist as the set half).
- **Rows needing an unbuilt system** (fine to approve, build waits): KONAMI CODE (BACKUPS §9) ·
  all of §V (JAILBREAK §7) · SYNTHETIC BENCHMARK (minigame nodes §I) · SPEEDRUN TIMER (par
  data) · FOIL PRINTER + LOOTBOX SUBSCRIPTION (small new mechanics).
- **⚠ flagged for a ruling:** RAID LEADER'S HEADSET (info-assist) · USB MISSILE TURRET
  (pet-cut adjacency) · BETA BUILD (chaos complexity) · LOOTBOX SUBSCRIPTION (temp slot) ·
  MECHANICAL KEYBOARD's counter-deed (counters are un-Law-like; a kill deed swaps in fine).
- **Rejected while drafting (rule violations, recorded so they stay dead):** anything touching
  telegraph/window timing (CRT MONITOR "zero input lag", SPEEDHACK, OVERCLOCKED BIOS — core
  rule 1) · PERJURY LOOPHOLE (broken oath counts kept — gear playing the game for you) · THE
  AIRGAP (curse immunity — insurance, not greed) · AIRPLANE MODE (deletes the Market — fights
  the economy's spine) · ADMIN PRIVILEGES (pick your rarity — kills the pity drama).
- **Suggested target:** keep ~15–20 of the ~40 (with the v2 pool's 18 + 6 keeps, that's a
  ~40-curio living pool — enough to spread across boss pages without diluting any single roll).

---

## Drop scaling by depth (starting values, knobs on `TuningConfig`)

**ARMORY cadence (2026-07-03): drops are EVENTS.** Rolls fire only at Seal kills, gate
exams, and any kill whose SIGNATURE is still locked (first-kill shower); repeat skirmish
kills pay salvage Tokens (1/2/3⏣ by ring), no roll. With ~4–6 rolls per descent the
weights below are retuned RICHER than the pre-armory table (shipped in `Gear.rarity_weights`).

Rarity is rolled first (pity-bent, persists across bosses), then the item within the tier,
synergy-weighted (`draft.gd` tag matching — every item below lists its tags).

| Surface | Haiku / Sonnet / Opus base weights |
|---|---|
| Ring 3 (Seal + gate + first-kills) | 50 / 35 / 15 |
| Ring 2 | 38 / 40 / 22 |
| Ring 0 | 25 / 40 / 35 |
| Skirmish kills | first kill = the SIGNATURE (guaranteed); repeats = salvage ⏣, no roll |
| Boss version v2/v3 | shift a further 8pp per version from Haiku upward |
| Sworn-oath KEPT | purse bend on top (see PROGRESSION-PLAN table) |

**Signature philosophy (ARMORY, supersedes the all-Haiku taste rows):** the SIGNATURE is
the boss's iconic STRONG piece (printed Sonnet for the combat six) — a first kill must
change how the next fight feels. Shipped strong versions are inlined per row below.

---

# THE SEAL PAGES

## VORATHEK, THE RIFTMAW (Seal I — the tutorial page; universal basics)

- **RIFTMAW TOOTH** · **Sonnet (ARMORY)** · UNIV · [SIM] · **SIGNATURE (first kill)** — whenever
  a boss self-heal is DENIED (anyone's kick), **your defensive verb and dodge reset** and you
  gain +20 primary resource. *Combo:* makes the kick game visible to every seat from hour one —
  and the denial moment hands you your verbs back (a free guard/dodge/kick window).
  *Hook:* staggered-heal moment (`GearFx.tooth_grant` resets `defense_ready_tick`/`dodge_ready_tick`).
  *Tags:* [interrupt, mana, rage, focus]. Pop: *"CHECKPOINT CORRUPTED — scavenged."*
- **STICKY NOTE** · Haiku · bulwark · [SIM] · **OATH sev-I: "answer every Baleful Curse within
  2s"** — taunting back within 2s of a THREAT_DROP refunds +15 rage. *Combo:* teaches the
  curse response it's earned by; Challenge economy. *Hook:* taunt-after-threat-drop timer
  (deterministic tick pair). *Tags:* [guard, rage]. Flavor: a note taped to the boss's
  monitor: "THE TANK EXISTS."
- **GRACE PERIOD** · Sonnet · UNIV · [SIM] · **OATH sev-II: "clear with zero raider deaths"**
  — once per fight, your class streak survives its break: Warden chain-halving holds ·
  Tempo Flow survives one landed swing · Thornveil streak survives one wilt · Mender skips one
  Litany decay · Jugg's first below-cap dodge doesn't dump Momentum · Voidcaller's first
  whiffed kick refunds the cd. ONE item, six class meanings. *Hook:* each kit's break site
  checks a `gear_grace` flag. *Tags:* [counter, flow, thorns, litany, momentum, interrupt].
  Pop: *"GRACE PERIOD — forgiven."*
- **RIFTMAW'S HUNGER** · Opus · UNIV · [SIM] · **VERSION v2** — surviving a single hit ≥60
  primes you: your next ability is free and instant. *Combo:* Brinkwarden wants allies (and
  itself) bloodied; Jugg `bulldoze` eats CRUSHes on purpose; BLOCKABLE finishers become fuel.
  *Hook:* `on_damage_taken` threshold → one-shot flag consumed in `on_action`.
  *Tags:* [bloodied, momentum, rage]. Pop: *"PAIN IS FUEL."*

## MISTRAL-7B, LE GOLEM EFFICACE (Seal II — efficiency)

- **LE CHAT'S BELL** · **Sonnet (ARMORY)** · UNIV · [SIM] · **SIGNATURE** — start every fight
  with +30 primary resource, pre-warmed — and the warm start HUMS: resource flows twice as
  fast for the first 10s ("lightweight and efficient"). *Hook:* `GearFx.bell_live` at each
  kit's Scratchpad regen site. *Tags:* [mana, rage, focus, sap].
- **RELAY BATON** · Sonnet · UNIV · [SIM] · **OATH sev-II: "kick every verse of Recite the
  License"** — when ANOTHER raider lands a kick, your defensive-verb cooldown ticks 2s faster.
  *Combo:* the kick-rotation item — chains (2s verses vs 5s kick cd) become a relay; stacks
  with Twin Guard/Twin Step/Twin Void charges. Pure co-op fortune — does nothing solo.
  *Hook:* on any other seat's interrupt diag bump. *Tags:* [interrupt, guard, dodge].
- **FREE TIER** · Opus · UNIV · [SIM] · **VERSION v2** — the first use of each equipped
  active per fight consumes no charge. *Combo:* every active in this catalog (Pruning Shears,
  Mute Button, Leech Chalice, Rollback Script, the pair press…); the actives-build enabler.
  *Tags:* [tokens]. Flavor: *"You have used 0 of your 2 requests."*

## GEMINI ULTRA, THE TWIN CONSTELLATION (Seal III — doubles)

- **A/B COIN** · Haiku · UNIV · [SIM] · **SIGNATURE** — at fight start a seeded flip: +25
  resource or a 40-pt ward (result shown big: "variant A" / "variant B"). Fortune with a
  personality. *Tags:* [ward, mana, rage].
- **SEVERANCE PACKAGE** · Haiku · UNIV · [SIM] · **OATH sev-I: "destroy BARD.EXE before
  Gemini returns"** — when an add dies, the party heals 25 and you gain +10 resource.
  *Combo:* add waves and skirmish floors; makes killing the subagent feel *paid*.
  *Hook:* add-death moment. *Tags:* [growth, reservoir]. Pop: *"role made redundant."*
- **PLUG** (½ of THE UNPLUGGING) · Sonnet · UNIV · [SIM-pair] · **OATH sev-II: "no raider
  death during the add phase"** — alone: +1⏣ Token on every Seal kill. See THE UNPLUGGING.
- **SECOND OPINION** · Opus · UNIV · [SIM] · **VERSION v2** — your PERFECT and READ beat
  payoffs fire twice. *Combo:* the class-fun payoff economy doubled — chain links, Momentum,
  Flow, mana sips, Sap, Focus; monstrous with `trigBeat`-family slot pieces (their proc
  moments double too). The cross-class chase legendary. *Hook:* `on_strike_result` wrapper.
  *Tags:* [perfect, counter, flow, momentum]. Flavor: *"Double-checked. Both of you were right."*

## CLAUDE MYTHOS, THE FINAL COMPUTE (Seal IV — the finale page)

- **COMPLIMENTARY APOLOGY** · Haiku · UNIV · [SIM] · **SIGNATURE** — whenever the boss
  EMPOWERs or self-heals, you gain +10 resource. *"We apologize for the inconvenience."*
  *Tags:* [interrupt, mana]. (Even the finale page has a taste row.)
- **SCRATCHPAD** · Sonnet · UNIV · [SIM] · **OATH sev-II: "bring all four out alive"** — during any boss wind-up ≥6s, your resource regen triples. *Combo:* the
  ULTRATHINK/parked-comet answer — Reservoir banking, garden pre-planting, Focus pooling
  while it "thinks". *Hook:* `upkeep` reads the live telegraph length. *Tags:* [mana, sap,
  focus, reservoir]. Flavor: *"use the thinking time."*
- **SOCKET** (½ of THE UNPLUGGING) · Sonnet · UNIV · [SIM-pair] · **OATH sev-II: "kick the
  Conclusion in every Chain-of-Thought"** — alone: your actives get +1 max charge.
- **THE CONCLUSION** · Opus · UNIV · [SIM] · **BLOOD OATH sev-III: "win without ever kicking
  Hotfix Deployment"** (the boss heals free — a dps-check handicap) — while the boss is ≤15%,
  your verb-proc payloads fire ×2. *Combo:* the whole slot-verb build detonating in the
  execute window; pairs with Sunder's broken wall for the team burst finish.
  *Hook:* payload dispatch multiplier gated on boss hp frac. *Tags:* [perfect, counter,
  backlash, bloom]. Flavor: *"it scales."*
- **THE UNPLUGGING** (set pair: PLUG + SOCKET, both slots — your whole inventory) — once per
  fight, press G to yank the cord: the boss's current telegraph fizzles. *"(In hindsight, the
  power cable was right there.)"* The realm's central joke as the realm's meme build. ⚠ This
  is the ONE deliberate erase-a-mechanic item; the price is both slots and the pair's halves
  are modest alone (the PROGRESSION-PLAN set-pair tension, exactly). Playtest knob: fizzle
  everything vs. everything-but-UNANSWERABLE.

---

# THE SKIRMISH PAGES (2–3 rows, mostly UTIL — the taste lane)

## BARD.EXE (deprecated)
- **SWAN SONG** · Haiku · UNIV · [SIM] · **SIGNATURE** — when you die, you fire a final
  **200** blast and the party heals **25** (ARMORY buff — the poem got meatier).
  *"It saved its best poem for last."* *Tags:* [bloodied].
- **COUPON CODE** · Haiku · UNIV · [UTIL] · **OATH sev-I: "take zero hits from Farewell
  Sonnet"** — MARKET prices −1⏣.

## SONNET SUBAGENT (stray)
- **TICKET STUB** · Haiku · UNIV · [UTIL] · **SIGNATURE** — closing a TICKET also repairs
  +10% party integrity and pays +1⏣ (ARMORY buff). (The subagent does the chores.)
- **SKELETON API KEY** · Sonnet · UNIV · [UTIL] · **OATH sev-II: "kill before its second
  Parallel Tool Calls"** — opens one 401 door per floor without the key.

## OPUS SUBAGENT (stray)
- **COOLING PASTE** · Haiku · UNIV · [UTIL] · **SIGNATURE** — active (2 charges/run): clear
  one CORRUPTED SECTOR wound. The wound-economy pressure valve, earned not found.
- **ROLLBACK SCRIPT** · Sonnet · UNIV · [SIM] · **OATH sev-II: "deny every Hotfix
  Deployment"** — active (1/fight): restore your HP to its value 3s ago (self only — the
  fight keeps everything else; a misread stays punished, you just survive it). This is the
  parked "rewind verb" landing at its correct size: a rare defensive curio.
  *Hook:* per-seat hp ring-buffer (diag-family). *Tags:* [ward, bloodied].
- **CACHE PREFETCHER** · Haiku · UNIV · [UTIL] · **VERSION v2** — CACHE and secret rooms are
  revealed on floor entry ("cache hit!").

---

# THE GATE PAGES (class-marked — your exam pays in your class's toys; the natural oath stage)

## CAPTCHA-9, THE GATEKEEPER (tank gate → Bulwark page)
- **VERIFICATION STAMP** · **Sonnet (ARMORY)** · bulwark · [SIM] · **SIGNATURE** — your first
  clean negate each fight banks +4 chain links (Warden) / +8 Momentum (Jugg) **and resets
  Guard on the spot** (chain a second read). *"Verified: not a robot."*
  *Tags:* [parry, counter, momentum].
- **DEBT COLLECTOR** · Sonnet · bulwark[warden] · [SIM] · **OATH sev-II: "clear the gate with
  the chain never broken"** — Vindicate cashed at 5+ links also staggers the boss. *Combo:*
  Chain ride → cash → free swing window; `riposteChain`/`vindInterrupt` builds.
  *Hook:* `_vindicate` link count. *Tags:* [counter, riposte].
- **AFTERBURNER VALVE** · Sonnet · bulwark[juggernaut] · [SIM] · **OATH sev-II: "spend the
  whole gate fight at Momentum ≥6"** (the `sunder_jugg_at` floor — the deed teaches the
  Sunder feed) — entering OVERDRIVE vents a free mini-Avalanche (3 hits × 30, no cost, no
  Momentum spent; 10s icd). *Combo:* Redline riding; `snowball`/`sureFoot`. *Tags:* [momentum].
- **KEYSTONE OF THE BROKEN WALL** · Opus · bulwark · [SIM] · **BLOOD OATH sev-III: "win with
  Guard sealed"** (the canonical Blood Oath) — when SUNDER hits max (WALL BROKEN), every
  raider's defensive verb resets. *Combo:* the tank's reads hand the whole raid its verbs
  back mid-burn — Sunder's co-op payoff made physical; stacks with Twin Guard/Step/Void
  (reset + charge = doubled windows inside the broken wall). Earned alone in your exam,
  wielded for the team. *Hook:* sunder-max moment → per-seat `defense_ready_tick` rewrite.
  *Tags:* [guard, parry, momentum]. Pop (raid-wide): *"THE WALL IS DOWN — GO."*

## FIREWALL (blade gate → Twinfang page)
- **POWDER VIAL** · **Sonnet (ARMORY)** · twinfang · [SIM] · **SIGNATURE** — your Kick also
  applies 3 stacks of the lit wheel lane (Venom) / +2 Flow (Tempo). *Combo:* folds the
  off-rhythm button into each aspect's engine. *Tags:* [poison, flow].
- **ENCORE BELL** · Sonnet · twinfang[tempo] · [SIM] · **OATH sev-II: "land 8 PERFECT strikes"** — after Coup consumes max Flow, your Perfect window holds at the wide Flow-0
  anchors for the next 3 strikes. *Combo:* the Accelerando cash-out breather — spend the BPM,
  get 3 beats to rebuild it; `dancersgrace`/`crescendo` builds. *Hook:* `coup` moment →
  window-anchor override counter. *Tags:* [flow, perfect, combo].
- **ROULETTE FANG** · Opus · twinfang[venomancer] · [SIM] · **OATH sev-III: "kill with all
  three venoms at ≥4 stacks"** — completing a full wheel revolution (V→F→C→V) while all
  three poisons live triggers a free micro-Rupture SIP (0.3×, keeps stacks and Synergy).
  *Combo:* the wheel-rider's legendary — ride for revolutions instead of fixating; stacks
  with `lingerVenom` (sip school) and `catalyst` Synergy ramp; Envenom-fixate becomes a real
  tension (fixating stops revolutions). *Hook:* wheel-wrap detector + all-lanes-live check.
  *Tags:* [poison, combo, rupture].

## THE PROMPTER (caster gate → Voidcaller page)
- **SPARK PLUG** · **Sonnet (ARMORY)** · voidcaller · [SIM] · **SIGNATURE** — your first TWO
  kicks each fight that answer a cast refund their WHOLE cooldown. *"Kick early, kick often."*
  *Tags:* [interrupt].
- **MUTE BUTTON** · Sonnet · voidcaller[silencer] · [SIM] · **OATH sev-II: "land 6 clean
  kicks in the gate"** — active (2/fight): extend a live Silence and Expose by 2s.
  *Combo:* Quietus stretching, `longsil`/`deepexpose` lockout builds; a spend *decision*
  (which cast deserves the longer gag?). *Tags:* [silence, interrupt].
- **ECHO CHAMBER** · Opus · voidcaller[disruptor] · [SIM] · **OATH sev-III: "6+ kicks, none whiffed"** — a CLEAN kick at full Backlash echoes a free Overload at
  0.6× without spending the stacks. *Combo:* the full-bank rider — hold 5 stacks and keep
  kicking clean instead of dumping; `vcTrigClean` fires payloads on the same moment;
  `punish`/`overfocus`. *Hook:* `_do_interrupt` clean + backlash==max. *Tags:* [backlash,
  interrupt]. Flavor: *"the same opinion, louder."*

## POPUP, THE ADHOUND (healer gate → healer page)
- **SALT VIAL** · **Sonnet (ARMORY)** · mender · [SIM] · **SIGNATURE** — your dispel also heals
  the target 60 **and refunds its mana**. *Tags:* [mana]. (Dispel is the Mender's mint
  signature — the item makes it free AND visible.)
- **OVERFLOW SLUICE** · Sonnet · mender[tidecaller] · [SIM] · **OATH sev-II: "no ally below
  30% for the whole gate"** — overheal banked while the Reservoir is FULL becomes a ward on
  the tank at 0.5×. *Combo:* fixes the capped-flywheel waste; `floodgate`/Surge re-bank
  loops. *Hook:* `on_overheal` at reservoir cap. *Tags:* [reservoir, overheal, ward].
- **LEECH CHALICE** · Sonnet · mender[brinkwarden] · [SIM] · **OATH sev-II: "light 10 Litany
  pips in the gate"** — active (2/fight): +40 Nerve now. *Combo:* Last Stand timing, Blood
  Pact ramps — buy the save you can see coming. *Tags:* [nerve, bloodied].
- **FIFTH PSALM** · Opus · mender · [SIM] · **OATH sev-III: "cash 3 Benedictions in one
  fight"** — Benediction (the 5th pip) also fires your triage payloads on every ally it
  touches. *Combo:* the Litany build-around — 4 allies × payloads, and those payload procs
  count toward `mdPropBenediction`'s every-5th counter (the loop is the point; no lockouts,
  rebalance the boss). *Hook:* `_benediction` → payload dispatch per target. *Tags:*
  [litany, mana, ward].
- **★ Bloomweaver rows (authored now, PARKED until a Bloomweaver seat is unlock-live —
  raid comp is bulwark/twinfang/voidcaller/mender today):**
  - **PRUNING SHEARS** · Sonnet · bloomweaver · [SIM] — active (2/fight): instantly RIPEN one
    ally's Growth (age jumps to `ripe_lo`). *Combo:* manufacture the harvest window — line up
    a ripe Lifesurge mass-bloom on demand. *Tags:* [growth, bloom].
  - **ORCHARD BELL** · Opus · bloomweaver[wildgrove] · [SIM] — a Bloom harvested inside the
    ripe window replants the Growth at half duration. *Combo:* the perpetual orchard —
    sustains `bwPropDeepGarden`'s 3-Growth floor and `bwTrigPlant` procs off skillful
    harvest timing alone. *Tags:* [growth, bloom, verdance].
  - **CROWN OF BRIARS** · Opus · bloomweaver[thornveil] · [SIM] — a Perfect Ward at full
    thorn charge chains bark to the two nearest allies (0.4× mini-wards). *Combo:* more ward
    surface = more Perfect Wards = more Verdance… and more wilt risk to the streak —
    self-balancing greed. *Tags:* [ward, thorns, verdance].

---

## Rollout mapping (matches PROGRESSION-PLAN phases)

- **GEAR-1 — ✅ SHIPPED 2026-07-03 (`866592f`):** all NINE signature rows live (the five
  above + the four gate items — the gates were free since their tables key by canonical
  encounter id), drop/scrap/2-slot plumbing, unlock store, ceremony, `gear_probe`. Scrap
  Tokens bank until MARKET (GEAR-3); offline raid-map only (online spec fold-in later).
- **GEAR-2 — ✅ SHIPPED 2026-07-03 (`8d18685`):** the oath system (Ledger offer screen /
  tracker banner / KEPT-unlocks-into-this-roll / stakes purses), the rarity-first roll
  (ring weights + pity + purse bends), detector diag, and SEVEN oath-row curios: Grace
  Period, Sticky Note, Scratchpad, Debt Collector, Encore Bell, Echo Chamber, Overflow
  Sluice. v1 deed adjustments (detectability): Mythos Scratchpad = "bring all four out
  alive"; Encore Bell = "land 8 PERFECT strikes" (Coup-count needs a diag); Echo Chamber
  = "6+ kicks, none whiffed". Still paper: RELAY BATON / FREE TIER / SECOND OPINION /
  the pair / KEYSTONE / ROULETTE FANG / FIFTH PSALM / THE CONCLUSION / MUTE BUTTON
  (actives need the G/H socket) + all VERSION rows (Trial Ladder).
- **GEAR-3 (MARKET/extraction):** [UTIL] items stock MARKETs; schematics lane.
- **GEAR-4 (Seal tables/personal loot):** GEMINI + MYTHOS pages, the pair, VERSION rows
  (behind Trial Ladder).

**Acceptance:** per PROGRESSION-PLAN (byte-identical with gear absent; drop & oath
determinism; Monotonic spot-assert) + one new bar: a `gear_probe.gd` that proves each [SIM]
item's proc fires (paired-seed win-rate/TTK delta per item, like `_prove_guard_mods`).
