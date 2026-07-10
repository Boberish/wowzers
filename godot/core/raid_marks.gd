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
const SEAT_HP_CUT_CAP := 0.35     ## JAILBREAK HP TAX: a corrupted-sector cut per seat, capped
const WINDOW_TIGHTEN_CAP := 0.30  ## JAILBREAK TIMING TAX: answer-window shrink, capped
const SURGE_FREEZE_TICKS := 90    ## a full SURGE dump → this many ticks (3s) of frozen boss timers
const SHIELD_ABSORB_MAX := 220.0  ## a full SHIELD PRIME dump → this much absorb on every seat
const STALL_MAX_SEC := 16.0       ## a full STALL dump → this many seconds of enrage delay

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
		"stall":
			return {"enrage_offset": float(n) / 100.0 * STALL_MAX_SEC}
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
	# DMG-AMP — the raid hits HARDER all fight (bites the DPS/enrage race + self-heal bosses).
	var amp := float(mark.get("party_out_mult", 0.0))
	if amp > 1.0:
		s.party_out_mult = maxf(s.party_out_mult, amp)
	# STALL (+s, blessing) / enrage-sooner (−s, curse) — shifts the enrage timer.
	var eoff := float(mark.get("enrage_offset", 0.0))
	if eoff != 0.0:
		s.enrage_offset += eoff
	# JAILBREAK HP TAX (§7) — a temporary corrupted sector: cut every seat's max HP for this
	# fight. Because a mark auto-clears each fight, this IS the "auto-repairs after" promise —
	# next fight rebuilds hp_max clean. Mirrors the wounds arithmetic (raid_hud/raid_net).
	var shc := clampf(float(mark.get("seat_hp_cut", 0.0)), 0.0, SEAT_HP_CUT_CAP)
	if shc > 0.0:
		for u in s.seats:
			u.hp_max = maxf(1.0, roundf(u.hp_max * (1.0 - shc)))
			u.hp = minf(u.hp, u.hp_max)
	# JAILBREAK TIMING TAX (§7) — answer windows shrink for this fight only. s.config is a
	# FRESH TuningConfig per fight and every grade reads the windows live off it, so scaling
	# strike_* here tightens PERFECT/GOOD/GRAZE for every seat + every boss with no per-boss
	# work, and can't leak into another fight. Auto-clears with the mark ("−10% next fight").
	var wt := clampf(float(mark.get("window_tighten", 0.0)), 0.0, WINDOW_TIGHTEN_CAP)
	if wt > 0.0:
		s.config.strike_perfect *= (1.0 - wt)
		s.config.strike_good *= (1.0 - wt)
		s.config.strike_graze *= (1.0 - wt)
