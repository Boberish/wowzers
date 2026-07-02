## The kit attached to the Mender's AI allies (tank + 3 DPS). Its only job is the
## per-seat group-damage override: under a Brinkwarden healer, bloodied allies deal
## MORE damage (the "living on the edge speeds the kill" hook). Non-brinkwarden or
## non-bloodied allies fall back to the engine's default curve.
class_name MenderAllyKit
extends ClassKit

var aspect: String = "tidecaller"
var cfg: MenderConfig
var bloodpact: bool = false          ## draft boon (adds +0.35 to bloodied factor)

func _init(_aspect: String, _cfg: MenderConfig, _bloodpact: bool = false) -> void:
	aspect = _aspect
	cfg = _cfg
	bloodpact = _bloodpact

func dps_factor(_s: CombatState, _seat: Seat, frac: float) -> float:
	if aspect == "brinkwarden" and frac <= cfg.blood_thresh:
		var pact := 0.35 if bloodpact else 0.0
		return 0.9 + (cfg.blood_thresh - frac) * 1.5 + pact   # 0.9 at 40% → 1.5 at 0%
	return -1.0   # use the engine default (0.3 + 0.7*frac)
