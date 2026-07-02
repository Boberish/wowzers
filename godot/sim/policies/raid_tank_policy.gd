## RaidTankPolicy — BulwarkPolicy plus the raid tank's one extra job: HOLD AGGRO.
## When the boss is on someone else (a Baleful Curse threat-drop, or a pull gone
## wrong) and Challenge is up, taunt it back before anything else. Everything else
## is the solo tank brain unchanged.
class_name RaidTankPolicy
extends BulwarkPolicy

## Probe knob: the raid sim disables the taunt to PROVE threat is load-bearing
## (dps should start dying to stolen aggro when the tank can't answer the Curse).
var use_challenge: bool = true

func act(obs: Dictionary) -> Dictionary:
	if use_challenge and not bool(obs.get("aggro_me", true)) \
			and bool(obs.get("challenge_ready", false)):
		return {"type": "ability", "id": "challenge"}
	return super.act(obs)
