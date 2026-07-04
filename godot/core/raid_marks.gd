## RaidMarks — the ONE place a fight-altering MARK is applied to a freshly-built fight.
## Called by BOTH RaidNet.build (online + offline map fights, via the carry) AND
## raid_hud._apply_next_fight_mark — one applier, so the two can never hand-copy-diverge
## (the same reason MapFx exists). A mark is the THE KILL SWITCH cash-out (OVERCLOCK PRIME)
## and the devil's-bargain fight-curse, carried on the proven carry→spec→build path.
##
## EVERY branch is a BUILD-TIME state write on an EXISTING field, guarded by its key, so a
## fight with NO mark is byte-identical to before (the P6/mark byte-identity guarantee).
class_name RaidMarks
extends RefCounted

const HP_CUT_CAP := 0.35          ## a full 100⏻ dump caps here (linear below)
const DMG_BUFF_CAP := 0.55        ## the boss self-empower cap (mirrors combat_core)
const SURGE_FREEZE_TICKS := 90    ## a full SURGE dump → this many ticks (3s) of frozen boss timers
const SHIELD_ABSORB_MAX := 220.0  ## a full SHIELD PRIME dump → this much absorb on every seat

## The OVERCLOCK PRIME cash-out: turn a ⏻ spend into a fight-mark. SHARED by the arming
## panel (preview) AND the authoritative server (so a client can't forge the effect).
static func overclock(kind: String, spend: int) -> Dictionary:
	var n := clampi(spend, 0, 100)
	match kind:
		"surge":
			return {"boss_hp_cut": float(n) / 100.0 * HP_CUT_CAP,
				"boot_freeze": int(round(float(n) / 100.0 * SURGE_FREEZE_TICKS))}
		"shield":
			return {"party_absorb": float(n) / 100.0 * SHIELD_ABSORB_MAX}
	return {}

static func apply(s: CombatState, mark: Dictionary) -> void:
	if mark.is_empty() or s.boss == null:
		return
	# SURGE — the boss BOOTS WOUNDED (bites the enrage/DPS race + self-heal bosses).
	var cut := clampf(float(mark.get("boss_hp_cut", 0.0)), 0.0, HP_CUT_CAP)
	if cut > 0.0:
		s.boss.hp = maxf(1.0, roundf(s.boss.hp * (1.0 - cut)))
	# BOOT-FREEZE — the boss's ability + melee timers start DELAYED: a free, uncontested
	# opening for burst + threat setup. Reuses the timer ints seeded at make_state.
	var freeze := int(mark.get("boot_freeze", 0))
	if freeze > 0:
		s.boss.melee_timer += freeze
		for id in s.boss.ability_timer:
			s.boss.ability_timer[id] = int(s.boss.ability_timer[id]) + freeze
	# OVERCLOCK CURSE — the boss hits HARDER for the fight (the devil's-bargain rider that
	# bites the healer). dmg_buff scales outgoing only when > 0 (default 0.0 → byte-neutral).
	var dbuff := float(mark.get("boss_dmg_buff", 0.0))
	if dbuff > 0.0:
		s.boss.dmg_buff = maxf(s.boss.dmg_buff, minf(dbuff, DMG_BUFF_CAP))
	# SHIELD PRIME — a party ABSORB WALL (anti-spike; bites one-shot bosses only). absorb is
	# drained before HP, default 0.0 → byte-neutral when absent.
	var absorb := float(mark.get("party_absorb", 0.0))
	if absorb > 0.0:
		for u in s.seats:
			u.absorb = maxf(u.absorb, absorb)
