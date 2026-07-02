## RunState — the roguelite meta that persists across fights in a single run: the
## chosen Aspect, the current loadout (which abilities are on your bar), the acquired
## boons (upgrade/relic ids), and how far through the encounter list you are.
## Game-layer state (not part of the pure combat engine).
class_name RunState
extends RefCounted

var char_class: String = "bulwark"   ## "bulwark" | "mender" | "twinfang"
var aspect: String = "warden"
var loadout: Array = []           ## ability ids in key order (1..N)
var boons: Dictionary = {}        ## acquired upgrade/relic id -> true
var enc_index: int = 0
var encounters: Array = []        ## Array[EncounterRes]

static func start(aspect: String) -> RunState:
	var r := RunState.new()
	r.char_class = "bulwark"
	r.aspect = aspect
	r.loadout = ["cleave", "rampage", "fortify", ("vindicate" if aspect == "warden" else "avalanche")]
	r.boons = {}
	r.enc_index = 0
	r.encounters = BulwarkContent.run_encounters()
	return r

static func start_mender(aspect: String) -> RunState:
	var r := RunState.new()
	r.char_class = "mender"
	r.aspect = aspect
	r.loadout = MenderConfig.new().order(aspect)
	r.boons = {}
	r.enc_index = 0
	r.encounters = MenderContent.run_encounters()
	return r

static func start_bloomweaver(aspect: String) -> RunState:
	var r := RunState.new()
	r.char_class = "bloomweaver"
	r.aspect = aspect
	r.loadout = BloomweaverConfig.new().order(aspect)
	r.boons = {}
	r.enc_index = 0
	r.encounters = BloomweaverContent.run_encounters()
	return r

static func start_twinfang(aspect: String) -> RunState:
	var r := RunState.new()
	r.char_class = "twinfang"
	r.aspect = aspect
	r.loadout = TwinfangConfig.new().loadout(aspect)
	r.boons = {}
	r.enc_index = 0
	r.encounters = TwinfangContent.run_encounters()
	return r

static func start_voidcaller(aspect: String) -> RunState:
	var r := RunState.new()
	r.char_class = "voidcaller"
	r.aspect = aspect
	r.loadout = VoidcallerConfig.new().loadout(aspect)
	r.boons = {}
	r.enc_index = 0
	r.encounters = VoidcallerContent.run_encounters()
	return r

func current_encounter() -> EncounterRes:
	return encounters[enc_index]

func is_last() -> bool:
	return enc_index >= encounters.size() - 1

func total() -> int:
	return encounters.size()
