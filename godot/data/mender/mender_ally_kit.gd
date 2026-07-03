## The kit attached to the Mender's AI allies (tank + 3 DPS). Its only job is the
## per-seat group-damage override: under a Brinkwarden healer, bloodied allies deal
## MORE damage (the "living on the edge speeds the kill" hook). Non-brinkwarden or
## non-bloodied allies fall back to the engine's default curve.
class_name MenderAllyKit
extends ClassKit

var aspect: String = "tidecaller"
var cfg: MenderConfig
var bloodpact: bool = false          ## (unused for damage now — Blood Pact feeds the healer's Nerve
                                     ## instead; the healer kit reads the boon in upkeep)

func _init(_aspect: String, _cfg: MenderConfig, _bloodpact: bool = false) -> void:
	aspect = _aspect
	cfg = _cfg
	bloodpact = _bloodpact

func dps_factor(_s: CombatState, _seat: Seat, frac: float) -> float:
	if aspect == "brinkwarden" and frac <= cfg.blood_thresh:
		return 0.9 + (cfg.blood_thresh - frac) * 1.5   # bloodied allies hit harder = the ASPECT (0.9→1.5)
	return -1.0   # use the engine default (0.3 + 0.7*frac)
