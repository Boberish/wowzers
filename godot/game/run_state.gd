## RunState — the roguelite meta that persists across fights in a single run: the
## chosen Aspect, the current loadout (which abilities are on your bar), the acquired
## boons (upgrade/relic ids), how far through the encounter list you are, and the
## Draft 2.0 economy (run seed, draft rng, Tokens, opus pity).
## Game-layer state (not part of the pure combat engine).
class_name RunState
extends RefCounted

var char_class: String = "bulwark"   ## "bulwark" | "twinfang" | "bloomweaver" | "alchemist" | "well"  (post-purge 2026-07-10)
var aspect: String = "warden"
var loadout: Array = []           ## ability ids in key order (1..N)
var boons: Dictionary = {}        ## acquired upgrade/relic id -> true
# --- TEMPO REWORK framework (plumbing; blade/Tempo only for now — other classes leave these empty) ---
var creed: String = ""            ## run-start risk temperament (TwinfangCreeds id); "" = default
var modules: Dictionary = {}      ## equipped UI Modules id -> true (picked at Floor-1 elevation)
var rig: Dictionary = {}          ## the ONE Combo rig (TEMPO §5): {"when": id, "then": id}; wired at draft 1
var transform: String = ""        ## D0 S4: the ONE ability transform (cadenza/rondo/tremolo); picked at Floor 2; "" = none
var enc_index: int = 0
var encounters: Array = []        ## Array[EncounterRes]

# --- Draft 2.0 (see game/draft.gd) ---
var run_seed: int = 0             ## seeds fights (closed-form) and the draft stream
var draft_rng: DetRng = null      ## draft/economy stream — never state.rng, never the global RNG
var tokens: int = 0               ## skill-minted draft currency ("spend them responsibly")
var regenerate: int = 0           ## banked REGENERATE charges — the ONLY reroll (rerolls-out §11#3):
                                  ## earned/bought/Hot-Reload-granted, spent to redraw a draft row
var pity_opus: int = 0            ## drafts since an opus was OFFERED while one was offerable

# ---- Topology map mode (MASTER-PLAN §MAPS; map == null ⇒ classic linear run, untouched)
var map: RunMap = null            ## the generated node map for this run
var map_node: int = -1            ## current node id (-1 = not entered yet)
var inventory: Dictionary = {}    ## map pickups ({"api_key": true, ...})
var hp_frac: float = 1.0          ## persistent integrity across map nodes (fights start here)

# ---- The Inference Check meta (Topology deep events; all inert on a linear run) ----
var entropy: int = 0              ## ⚡ within-run luck pool spent to bias a roll
var flags: Dictionary = {}        ## cross-node ripple marks ({"covered_shift": true, …})
var check_fails: int = 0          ## consecutive failed checks → comeback pity (resets on a pass)

static func start(aspect: String, seed_v: int = -1) -> RunState:
	var r := _base("bulwark", aspect, seed_v)
	r.loadout = ["cleave", "rampage", "fortify", ("vindicate" if aspect == "warden" else "avalanche")]
	r.encounters = BulwarkContent.run_encounters()
	return r

static func start_bloomweaver(aspect: String, seed_v: int = -1) -> RunState:
	var r := _base("bloomweaver", aspect, seed_v)
	r.loadout = BloomweaverConfig.new().order(aspect)
	r.encounters = BloomweaverContent.run_encounters()
	return r

static func start_twinfang(aspect: String, seed_v: int = -1) -> RunState:
	var r := _base("twinfang", aspect, seed_v)
	r.loadout = TwinfangConfig.new().loadout(aspect)
	r.encounters = TwinfangContent.run_encounters()
	return r

static func start_alchemist(aspect: String, seed_v: int = -1) -> RunState:
	var r := _base("alchemist", aspect, seed_v)
	r.loadout = AlchemistConfig.new().loadout(aspect)
	r.encounters = AlchemistContent.run_encounters()
	return r

static func start_well(aspect: String, seed_v: int = -1) -> RunState:
	var r := _base("well", aspect, seed_v)
	r.loadout = WellConfig.new().loadout(aspect)
	r.encounters = WellContent.encounters()
	return r

## Shared init. seed_v < 0 -> wall-clock seed (normal play); tests pass explicit seeds
## for fully replayable runs. The draft stream is decorrelated from fight seeds.
static func _base(cls: String, aspect: String, seed_v: int) -> RunState:
	var r := RunState.new()
	r.char_class = cls
	r.aspect = aspect
	r.boons = {}
	r.enc_index = 0
	r.run_seed = seed_v if seed_v >= 0 else int(Time.get_ticks_usec() & 0x7FFFFFFF)
	r.draft_rng = DetRng.new((r.run_seed ^ 0x9E3779B9) & 0xFFFFFFFF)
	return r

## Per-fight combat seed — CLOSED-FORM off (run_seed, enc_index), never a draft_rng
## draw, so spending Tokens in a draft can never shift the next fight's combat.
func fight_seed() -> int:
	var s := (run_seed * 1000003 + enc_index * 7919 + 1) & 0x7FFFFFFF
	# Topology map mode reuses enc_index across nodes (the ramp maps several combat
	# nodes onto the same fight index), so fold the unique node id in — otherwise two
	# same-index nodes seed state.rng identically and the fight plays back verbatim.
	# Guarded: a linear run (map == null — every class sim + draft_sim) is untouched.
	if map != null:
		s = (s * 1000003 + (map_node + 1) * 6763) & 0x7FFFFFFF
	return s

func current_encounter() -> EncounterRes:
	return encounters[enc_index]

func is_last() -> bool:
	return enc_index >= encounters.size() - 1

func total() -> int:
	return encounters.size()
