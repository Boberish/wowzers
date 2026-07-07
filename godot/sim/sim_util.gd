## SimUtil — the shared sim/probe harness helpers (REFIT-PLAN P2; closes the parked
## MASTER-PLAN §CODE AUDIT sim-DRY item — the per-sim copies had already started to
## drift, which is exactly why this exists). A new probe should need ~this and a
## seed loop, nothing more:
##
##   extends SceneTree
##   func _initialize() -> void:
##       var seeds := SimUtil.arg_int("seeds", 200)
##       for sd in range(1, seeds + 1):
##           ...  # build state from (seed, spec), step CombatCore, collect a row
##       print("MY PROBE: %s" % ("ALL PASS" if fails == 0 else "FAIL"))
##       quit(0 if fails == 0 else 1)     # exit code IS the gate (verify-all.sh)
##
## Keep CSV schemas per-sim (they legitimately differ); keep every checksum printed
## as a STRING (63-bit ints don't survive JSON floats — same law as the netcode).
class_name SimUtil
extends RefCounted

## --key=value from the args after "--" (e.g. --seeds=300). Same contract every
## sim has carried since M0; the one copy now lives here.
static func arg(key: String, def: String) -> String:
	var prefix := "--%s=" % key
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return def

static func arg_int(key: String, def: int) -> int:
	return int(arg(key, str(def)))

static func arg_float(key: String, def: float) -> float:
	return float(arg(key, str(def)))

## "cause=n, cause=n" loss/cause tallies for the band footers ("-" when clean).
static func fmt_causes(causes: Dictionary) -> String:
	if causes.is_empty():
		return "-"
	var parts: Array = []
	for k in causes:
		parts.append("%s=%d" % [k, causes[k]])
	return ", ".join(parts)
