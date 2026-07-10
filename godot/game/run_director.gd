## RunDirector — the offline descent's STATE, held apart from the combat HUD
## (REFIT-PLAN P3.1b). Everything a raid campaign carries between fights lives here:
## the Topology floor, the party's persistent integrity/wounds/mana, TICKETS, the
## Inference-Check meta (⚡/📁/flags), THE KILL SWITCH, GEAR-1 curios + the ⏣ purse,
## the boon runs (yours + the commanded AI raiders'), and GEAR-2 oaths. The HUD
## (today) and the WorldShell (P3.2) hold ONE of these and render it; CampaignCore
## is the rulebook that steps it. RefCounted + Node-free: headless-safe by
## construction. The ONLINE campaign is the server's cp dict — natively the same
## cp-view shape, shared rules via CampaignCore; a serializable dict is what the
## persistence/rejoin era wants server-side, so it stays a dict there by design.
class_name RunDirector
extends RefCounted

# ---- Topology raid floor (MAP-3a): the run map + what carries across its fights
var map: RunMap = null
var node: int = -1                 ## current map node (-1 = the entry rim)
var inv: Dictionary = {}           ## api_key / credential shards
var fracs: Array = [1.0, 1.0, 1.0, 1.0]   ## per-seat persistent integrity
var wounds: Array = [0.0, 0.0, 0.0, 0.0]  ## CORRUPTED SECTORS: max-HP cut a heal can't fix
var mana: float = 1.0              ## the healer's mana ALSO carries — the raid's fuel gauge
var fights: Array = []             ## Array[EncounterRes], indexed by node "fight"
var floor_i: int = 0               ## which RaidContent.FLOORS entry (the RING descent, MAP-3c)
var tickets: Dictionary = {}       ## MAP-2: OPEN ticket ids (id -> title) carried this floor
var ticket_total := 0              ## tickets placed on this floor (for the sprint-retro bonus)
var closed := 0                    ## tickets closed this floor
var toast := ""                    ## a one-shot ticket pop, shown on the next map screen

# ---- The Inference Check meta (Topology deep events): ⚡ within-run luck +
# cross-node ripple flags. Inert (0/{}) until an event carries the matching fx.
# (V#8: the across-run 📁 Prior died — nothing follows you into a fresh run.)
var entropy: int = 0
var flags: Dictionary = {}
var marks: Dictionary = {}         ## a pending fight-altering mark (KILL SWITCH cash-out / curse)
var charge: int = 0                ## ⏻ THE KILL SWITCH — a party-shared 0..100 meter
# ---- THE JAILBREAK (§7): active curses (cap 2). Each = {kind, label, fights, mag}: kind ∈
# economy_mint | economy_price | hp | timing; fights>0 = bounded (ticks down at its bite site).
# NOT in cp_view — read directly on _d like tokens (offline-only this slice; online = no-op).
var curses: Array = []
var deprecate_uses: int = 0        ## DEPRECATE price escalates each use (§6)
var poisoned: Dictionary = {}      ## DECK TAX (§7): ability ids poisoned run-length (offline);
                                   ## injected into the human seat's kit at each fight build
var check_fails: int = 0           ## consecutive check fails → comeback pity

# ---- GEAR-1 (Curios): run-scoped loot; only Ledger UNLOCKS persist (GearStore)
var gear: Array = []               ## equipped curio ids (≤ Gear.SLOTS)
var gear_charges: Dictionary = {}  ## active-item charges left this run
var tokens := 0                    ## ⏣ fallback bank when no run exists (see raid_hud._gain_tokens)
var gear_unlocks: Dictionary = {}  ## boss_id -> unlocked item ids (Ledger rows)
var drop_rng: DetRng = null        ## the drop stream — NEVER the combat rng

# ---- Draft 2.0 + COMMANDER: the human's boon run, and the AI raiders you command
var run_seed: int = -1             ## the descent's ONE minted seed (REFIT P4): drops/floors/fights/drafts derive closed-form — a run replays from this integer
var run: RunState = null           ## the human's boon run (null = no descent live)
var fight_log: Array = []          ## METER L3 — per-fight meter snapshots (MeterPanel.snapshot) for the meter's run-history segments; auto-reset per descent via fight_log_seed
var fight_log_seed: int = -2       ## the run_seed the `fight_log` was gathered under (-2 sentinel); a change clears the log = new descent
var taken_boons: Array = []        ## drafted boon dicts (for the build panel: title/rarity)
var party: Dictionary = {}         ## AI seats only: seat_key -> {cls, aspect} (persists across descents)
var ai_runs: Dictionary = {}       ## AI seats only: seat_key -> RunState (their boon runs)

# ---- GEAR-2 (Sworn Oaths): one oath per fight, sworn at the boss node
var sworn: Dictionary = {}         ## the CURRENT fight's sworn oath row (+ "boss")
var oath_result: Dictionary = {}   ## resolved at fight end, consumed by the drop flow
var oath_broken := false           ## live tracker latch (view-only)
var drop_pity := 0                 ## opus dry-streak counter (purses add ticks)

## The cp VIEW dict CampaignCore/MapFx step: arrays/dicts mutate in place, scalars
## are synced back by cp_sync. (Same shape the server's online campaign dict has
## natively — the rulebook can't tell the sides apart, by design.)
func cp_view() -> Dictionary:
	return {"fracs": fracs, "wounds": wounds, "mana": mana,
		"entropy": entropy, "inv": inv, "flags": flags,
		"marks": marks, "charge": charge,
		"tickets": tickets, "closed": closed, "total": ticket_total,
		"toast": toast}

func cp_sync(cp: Dictionary) -> void:
	mana = float(cp["mana"])
	entropy = int(cp["entropy"])
	charge = int(cp["charge"])
	closed = int(cp["closed"])
	toast = String(cp["toast"])
