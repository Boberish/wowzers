## TwinfangKit — the Melee DPS class behaviour, ported from poc/twinfang.html. Energy
## + a rhythm-gated Strike + combo points + Flow (a damage multiplier you keep alive by
## chaining Perfects) + both Aspects (Tempo Flow-tiers/Coup, Venomancer typed-poison/
## Rupture). `boons` (drafted upgrade/relic ids) modify behaviour throughout.
##
## Faithful & deterministic: all class state lives in `seat.vars` (ticks are truth,
## the only randomness is the shared seeded `s.rng` for Contagion). No GCD — the rhythm
## paces your Strikes; other abilities gate on energy + their own cooldown.
class_name TwinfangKit
extends ClassKit

var aspect: String = "tempo"           ## "tempo" | "venomancer" | "fermata"
var cfg: TwinfangConfig
var creed_id: String = "drumline"      ## TEMPO rework: the run's risk temperament (Tempo only)
var rig: Dictionary = {}               ## TEMPO §5: the run's ONE Combo rig — {"when": id, "then": id}
var transform: String = ""             ## D0 S4: the run's ONE ability transform (cadenza/rondo/tremolo); "" = none

# TEMPO REWORK · GRADED WINDOW (§2c): one landing zone, four tiers by centredness.
enum { G_MISS = 0, G_GOOD = 1, G_PERFECT = 2, G_BULL = 3 }

func accent() -> Color:
	return Color("57c7e0")   # Palette.FLOW — the rhythm cyan

func _init(_aspect: String, _cfg: TwinfangConfig) -> void:
	aspect = _aspect
	cfg = _cfg

## FERMATA (§13): the hold-release aspect. It IS Tempo's kit (Flow / combo / Coup / Opening /
## crit) — only the Strike changes (press→sharpen→release), so everything Flow-shaped is shared
## via `_tempo_family()`. `aspect == "tempo"` stays exact (adding `or fermata` never changes a
## tempo eval); fermata is a brand-new path, so no existing checksum can move.
func _tempo_family() -> bool:
	return aspect == "tempo" or aspect == "fermata"

func _fermata() -> bool:
	return aspect == "fermata"

## TUTTI creed (fermata): every button coils; sharp dumps take the window grade multiplier.
func _tutti() -> bool:
	return aspect == "fermata" and bool(_creed().get("tutti", false))

## SHADOW DANCE is live: the bullet-time window (coils sharpen instantly, releases grade up).
func _dance_active(s: CombatState, seat: Seat) -> bool:
	return _m("shadowdance") and bool(seat.vars.get("dance_armed", false)) \
		and s.tick < int(seat.vars.get("dance_until", 0))

## The live minimum coil (seconds) before the blade sharpens — Fleeting Shade shortens the
## floor, Quiet Fuse trims it, a Dance makes it instant.
func _coil_min(seat: Seat) -> float:
	if bool(seat.vars.get("coil_instant", false)):
		return 0.0
	var m := float(_creed().get("coil_min", cfg.coil_min_sec))
	if _b("quietFuse"):
		m -= cfg.quiet_fuse_cut
	return maxf(0.0, m)

## FERMATA · THE LIP (seconds from press): the far edge a release must not cross — past it the
## note SNAPS. Base = the window's `hi`; PATIENT KNIFE extends the ramp past it for a deeper max.
func _fermata_lip_sec(seat: Seat) -> float:
	var w := _edge_window(seat)
	var ext: float = (float(w[1]) - float(w[0])) * cfg.patient_ramp_ext if bool(_creed().get("patient", false)) else 0.0
	return float(w[1]) + ext

## FERMATA · THE ROAMING WINDOW roll — where the NEXT green lands. Patient waits far; Stretto
## biases near. Drawn from s.rng (fermata-only stream → tempo/venom checksums untouched).
func _roll_window_shift(s: CombatState, seat: Seat) -> float:
	var smin := cfg.patient_shift_min if bool(_creed().get("patient", false)) else cfg.fermata_shift_min
	var roll := lerpf(smin, cfg.fermata_shift_max, s.rng.next_float())
	if _b("stretto"):                                    # STRETTO: pull the roll toward the near edge
		roll = lerpf(roll, cfg.fermata_shift_min, cfg.stretto_bias)
	return roll

## FERMATA · THE SNAP — the sweep crossed the lip (or a release landed past it). The note breaks:
## no strike, Flow crashes (Fleeting bleeds 2 instead), a stagger (Patient's is harsher), the Brink
## zeroes, First Blood arms, and the window re-rolls. There is no dead-note state to hold.
func _snap(s: CombatState, seat: Seat) -> void:
	seat.vars["coiling"] = false
	seat.vars["sharp"] = false
	seat.vars["veil_warband_active"] = false
	seat.vars["coil_instant"] = false
	var stagger := cfg.snap_lock
	if String(_creed().get("snap", "crash")) == "flow_loss":
		seat.vars["flow"] = maxi(0, _flow(seat) - int(_creed().get("snap_amt", cfg.fleeting_snap_amt)))
	else:
		seat.vars["flow"] = 0                            # a crash
		if bool(_creed().get("patient", false)):
			stagger = cfg.patient_snap_stagger
	seat.vars["flow_decay_acc"] = 0
	seat.vars["overdrive"] = 0
	seat.vars["tl_stacks"] = 0
	seat.vars["brink"] = 0                               # THE BRINK: a snap zeroes the nerve meter
	if _b("firstBlood"):                                 # FIRST BLOOD: arm the comeback release
		seat.vars["first_blood_ready"] = true
	seat.vars["strike_lock_until"] = s.tick + _tt(s, stagger)
	seat.vars["window_shift"] = _roll_window_shift(s, seat)
	CombatCore._bump_diag(s, seat, "snap")
	CombatCore.emit_event(s, {"t": "snap", "player": seat.is_player})

# --- CREEDS (Tempo rework, TEMPO-PLAN §3): a slip's cost + Flow's reward value ---
func _creed() -> Dictionary:
	return TwinfangCreeds.get_creed(creed_id)

## D0 S4 · the run's ability TRANSFORM (tempo-family only; "" = the vanilla ability path).
func _transform() -> String:
	return transform if _tempo_family() else ""

## D0 S3 · true if a crit SOURCE is held (Whetstone creed / Heartseeker / Hone) — the Edge branch.
func _has_crit_source() -> bool:
	return _b("hone") or _b("heartseeker") or bool(_creed().get("whetstone", false))

func _creed_flow_value() -> float:
	if not _tempo_family():
		return 1.0
	return float(_creed().get("flow_value", 1.0))

## LARGO creed (Tempo) / THE LONG NIGHT (Fermata): the slow-and-sharp temperament — slower
## beats, tighter window, harder Perfects. Both set `largo: true`, so they share the machinery.
func _largo() -> bool:
	return _tempo_family() and bool(_creed().get("largo", false))

## OVERDRIVE (module): a FEVER is live — every Strike auto-lands all-green and free.
func _fever(s: CombatState, seat: Seat) -> bool:
	return _m("overdrive") and s.tick < int(seat.vars.get("fever_until", 0))

## A SLIP — a missed Perfect Strike or an eaten swing — paid in your groove/window per Creed.
func _creed_slip(s: CombatState, seat: Seat, force_shatter := false) -> void:
	if not _tempo_family() or _flow(seat) <= 0:
		return
	var before := _flow(seat)
	var c := _creed()
	match ("shatter" if force_shatter else String(c.get("slip", "flow_loss"))):
		"shatter":
			seat.vars["flow"] = 0
		"freeze":
			pass                                   # Flow untouched — the window pays instead
		_:
			seat.vars["flow"] = maxi(0, _flow(seat) - int(c.get("slip_amt", 2)))
	seat.vars["flow_decay_acc"] = 0
	var lost := before - _flow(seat)
	# F17: Held Breath's freeze loses no Flow, but it still counts as a CRASH EVENT so the
	# crash-keyed cards (Shatterfall / Staccato) aren't dead under it — pay off the frozen tempo.
	var crash_from := before if String(c.get("slip", "")) == "freeze" else lost
	seat.vars["overdrive"] = 0                      # DOUBLE TIME: the ride ends the instant you slip
	if _b("hone"):                                  # A7 (Whetted Edge): a slip DULLS the Edge meter
		seat.vars["edge"] = maxi(0, int(seat.vars.get("edge", 0)) - cfg.edge_slip_dull)
	seat.vars["tl_stacks"] = 0                       # THROUGH-LINE: any slip breaks the line
	if _b("quickstep"):
		seat.vars["quickstep"] = 0                    # QUICKSTEP: a slip resets the governed ride
	if _b("heavyInk"):
		seat.vars["heavy_ink"] = maxi(0, int(seat.vars.get("heavy_ink", 0)) - 1)   # HEAVY INK: one drips per missed beat
	# SHATTERFALL (boon): a crash from 4+ Flow detonates the shattered tempo as damage —
	# a PAYOFF fired AFTER the slap, never instead of it (the rebuild loss still stands).
	if _b("shatterfall") and before >= 4 and crash_from > 0:
		_deal(s, seat, float(crash_from) * cfg.shatterfall_per, true, false, "shatter")
	# STACCATO FURY (boon): a real crash arms a free, harder next Eviscerate.
	if _b("staccato") and before >= cfg.staccato_flow_min and crash_from > 0:
		seat.vars["staccato_ready"] = true
	var lock := float(c.get("lock_sec", 0.0))
	if lock > 0.0:
		seat.vars["window_lock_until"] = s.tick + _tt(s, lock)
		seat.vars["window_locked"] = true
	CombatCore._bump_diag(s, seat, "slip")
	CombatCore.emit_event(s, {"t": "creed_slip", "player": seat.is_player, "creed": creed_id})

# --------------------------------------------------------------------------
# Flow / combo / resource helpers
# --------------------------------------------------------------------------

func _flow(seat: Seat) -> int:
	return int(seat.vars.get("flow", 0))

func max_flow() -> int:
	if _fermata() and int(_creed().get("flow_cap", 0)) > 0:   # FLEETING SHADE: a lower Flow ceiling (its cost)
		return int(_creed()["flow_cap"]) + (2 if _b("flowCap") else 0)
	return cfg.flow_max + (2 if _b("flowCap") else 0)

func _flow_mult(seat: Seat) -> float:
	return 1.0 + float(_flow(seat)) * cfg.flow_per * _creed_flow_value()   # CREED: glass pays more per point

## Tempo transforms the kit in tiers as Flow climbs: 1 = double-hit Perfects,
## 2 = +combo & energy refund, 3 = Coup de Grâce ready (max Flow).
func flow_tier(seat: Seat) -> int:
	var f := _flow(seat)
	var t1 := 2 if _b("encore") else 3
	if f >= max_flow():
		return 3
	if f >= 5:
		return 2
	if f >= t1:
		return 1
	return 0

func _gain_flow(seat: Seat) -> void:
	seat.vars["flow"] = clampi(_flow(seat) + 1, 0, max_flow())
	seat.vars["flow_decay_acc"] = 0

func _gain_cp(seat: Seat, n: int) -> void:
	var nw := int(seat.vars.get("cp", 0)) + n
	# OVERKILL (boon): combo built PAST the cap banks into the next Eviscerate (max cap).
	if _b("overkill") and n > 0 and nw > cfg.cp_max:
		seat.vars["overkill_bank"] = mini(
			int(seat.vars.get("overkill_bank", 0)) + (nw - cfg.cp_max), cfg.overkill_cap)
	seat.vars["cp"] = clampi(nw, 0, cfg.cp_max)

func _gain_energy(seat: Seat, x: float) -> void:
	seat.resource = clampf(seat.resource + x, 0.0, cfg.energy_max)

# --------------------------------------------------------------------------
# D0 S1 · THE WOUND POT — short bleeds on the boss frame, inscribed on Bullseye
# (Open Veins creed) / Perfect (Lacerate boon), ticked in upkeep, press-cashed by
# Eviscerate when Hemorrhage is held. seat.vars["wounds"] is an Array of {end, per,
# acc} kept in FIXED INSERTION ORDER (determinism). Guarded: only the wound
# creed/boons/module reach these, so every other build is byte-identical.
# --------------------------------------------------------------------------

## Inscribe a bleed of `per_base` per-tick damage, shaped by the wound boons + module.
func _inscribe_wound(s: CombatState, seat: Seat, per_base: float) -> void:
	var per := per_base
	var dur := cfg.open_veins_dur
	if _b("slowBleed"):
		per *= cfg.slow_bleed_mult
		dur += cfg.slow_bleed_dur
	if _b("arterialNote"):
		per *= cfg.arterial_mult
		dur -= cfg.arterial_shorten
	if _m("hemorrhage"):
		dur += cfg.hemorrhage_ext
	dur = clampf(dur, cfg.wound_tick_every, cfg.wound_dur_cap)
	var ws: Array = seat.vars.get("wounds", [])
	ws.append({"end": s.tick + _tt(s, dur), "per": per, "acc": 0})
	seat.vars["wounds"] = ws
	CombatCore.emit_event(s, {"t": "wound_inscribe", "player": seat.is_player})

## Tick every live bleed once per upkeep; drop the expired (order preserved). Resonance (S2)
## leaves one extra tick on an expiring bleed. Also drains the Exsanguinate erupt bank.
func _tick_wounds(s: CombatState, seat: Seat) -> void:
	var ws: Array = seat.vars.get("wounds", [])
	if not ws.is_empty():
		var tick_ticks := _tt(s, cfg.wound_tick_every)
		var kept: Array = []
		for w in ws:
			var acc := int(w["acc"]) + 1
			if acc >= tick_ticks:
				acc = 0
				_deal(s, seat, float(w["per"]), false, false, "bleed")
			w["acc"] = acc
			if s.tick < int(w["end"]):
				kept.append(w)
			elif bool(seat.vars.get("res_wound", false)):
				_deal(s, seat, float(w["per"]), false, false, "bleed")   # RESONANCE (S2): one after-tick
		seat.vars["wounds"] = kept
	# EXSANGUINATE (keystone): the erupted burst pays out across exsang_beats ticks.
	if int(seat.vars.get("exsang_left", 0)) > 0:
		var eacc := int(seat.vars.get("exsang_acc", 0)) + 1
		if eacc >= _tt(s, cfg.wound_tick_every):
			eacc = 0
			_deal(s, seat, float(seat.vars.get("exsang_per", 0.0)), false, false, "bleed")
			seat.vars["exsang_left"] = int(seat.vars["exsang_left"]) - 1
		seat.vars["exsang_acc"] = eacc

## Eviscerate CASHES the pot (Hemorrhage): consume every live bleed, pay its remaining value +
## 10%/bleed. 5+ bleeds ERUPT (Exsanguinate, spread over 3 beats); 4+ fire The Deep Cash WHEN.
func _cash_wounds(s: CombatState, seat: Seat) -> void:
	if not _m("hemorrhage"):
		return
	var ws: Array = seat.vars.get("wounds", [])
	if ws.is_empty():
		return
	var n := ws.size()
	var tick_ticks := _tt(s, cfg.wound_tick_every)
	var total := 0.0
	for w in ws:
		var remaining := maxi(1, (int(w["end"]) - s.tick) / maxi(1, tick_ticks))
		total += float(w["per"]) * float(remaining)
	total *= (1.0 + cfg.hemorrhage_cash_per * float(n))
	if bool(seat.vars.get("bcoda_armed", false)):        # BLOOD CODA duo: the cash pays the duo bonus too
		total *= cfg.blood_coda_mult
		seat.vars["bcoda_armed"] = false
	seat.vars["wounds"] = []
	if _b("exsanguinate") and n >= cfg.exsang_min_bleeds:
		seat.vars["exsang_left"] = cfg.exsang_beats                       # ERUPT across the next 3 beats
		seat.vars["exsang_per"] = total / float(maxi(1, cfg.exsang_beats))
		seat.vars["exsang_acc"] = 0
		CombatCore.emit_event(s, {"t": "exsanguinate", "player": seat.is_player, "n": n})
	else:
		_deal(s, seat, total, false, false, "bleed")                      # instant cash
	if n >= cfg.deepcash_min_bleeds:
		_rig_fire(s, seat, "deepcash")                                    # THE DEEP CASH rig WHEN
	CombatCore.emit_event(s, {"t": "wound_cash", "n": n, "player": seat.is_player})

## D0 S2 · RESONANCE — count drafted cards per theme (creed + modules + boons); at res_threshold
## of ONE theme, light that theme's single rotational perk (Wound after-tick · Edge no-tighten ·
## Finish phrase-mark). Computed ONCE per fight (the deck is fixed). Adds no damage at 0 themes.
func _compute_resonance(seat: Seat) -> void:
	var count := {"wound": 0, "edge": 0, "finish": 0}
	var ct := String(_creed().get("theme", ""))
	if count.has(ct):
		count[ct] = int(count[ct]) + 1
	for mid in modules:
		if not bool(modules[mid]):
			continue
		var mt := String(TwinfangModules.get_module(String(mid)).get("theme", ""))
		if count.has(mt):
			count[mt] = int(count[mt]) + 1
	for card in TwinfangBoons.spec_pool(aspect):
		if _b(String(card.get("id", ""))):
			var bt := String(card.get("theme", ""))
			if count.has(bt):
				count[bt] = int(count[bt]) + 1
	seat.vars["res_wound"] = int(count["wound"]) >= cfg.res_threshold
	seat.vars["res_edge"] = int(count["edge"]) >= cfg.res_threshold
	seat.vars["res_finish"] = int(count["finish"]) >= cfg.res_threshold
	seat.vars["res_counts"] = count

# --- Tempo ACCELERANDO: the live rhythm window as a function of current Flow. Flow 0 =
#     the base anchors; max Flow = the *_lo anchors; lerp between (Flow = BPM). Venom pins
#     Flow at 0, so it always sees the base window (a steady beat, no accelerando). ONE
#     source of truth for _strike AND observe() so the RhythmBar/policy read exactly what
#     the kit judges a press against.
func _tempo_t(seat: Seat) -> float:
	# GEAR-2: Encore Bell — after a finisher the window holds at the wide Flow-0
	# anchors for 3 strikes (encore_left is only ever written by the gear branch).
	if int(seat.vars.get("encore_left", 0)) > 0:
		return 0.0
	# CREED (Held Breath): a slip locks the tight window to base for a beat (upkeep clears it).
	if bool(seat.vars.get("window_locked", false)):
		return 0.0
	return clampf(float(_flow(seat)) / float(max_flow()), 0.0, 1.0)
func _swing_min_sec(seat: Seat) -> float:
	var base := lerpf(cfg.swing_min, cfg.swing_min_lo, _tempo_t(seat)) * (cfg.largo_beat_mult if _largo() else 1.0)
	# THE SPEED GOVERNOR (D0 S0): extra speed brings the earliest strike sooner, clamped to the
	# wall (base ÷ beat_rate_cap). Boonless push == 0 → speedup 1 → byte-identical.
	var sp := _gov_speedup(seat)
	if sp > 1.0:
		base = maxf(base / sp, cfg.swing_min / cfg.beat_rate_cap)
	return base

## THE SPEED GOVERNOR (D0 S0/S1, TEMPO-PLAN §17.10 D) — the summed EXTRA speed push beyond the
## accelerando. v4: Double Time is now ghost-notes (NOT a speed source); QUICKSTEP is the wall's
## source — each Perfect stack contributes its rate−1 slice. Boonless returns 0 → byte-identical.
func _speed_push(seat: Seat) -> float:
	if not _tempo_family():
		return 0.0
	return float(int(seat.vars.get("quickstep", 0))) * cfg.quickstep_speed

## The governed speedup multiplier (1.0 = no extra speed). rate = 1 + (cap−1)·(1 − exp(−k·push)):
## sources fold ASYMPTOTICALLY so stacks approach beat_rate_cap but every card keeps a visible delta.
func _gov_speedup(seat: Seat) -> float:
	var push := _speed_push(seat)
	if push <= 0.0:
		return 1.0
	return 1.0 + (cfg.beat_rate_cap - 1.0) * (1.0 - exp(-cfg.gov_k * push))
func _perfect_lo_sec(seat: Seat) -> float:
	return _edge_window(seat)[0]
func _perfect_hi_sec(seat: Seat) -> float:
	return _edge_window(seat)[1]
## The live Perfect window [lo, hi] in seconds. MODULE (The Edge): narrows the window around
## its centre for a bigger Perfect payoff — "narrow for damage." Base window otherwise.
func _edge_window(seat: Seat) -> Array:
	var t := _tempo_t(seat)
	var lo := lerpf(cfg.perfect_start, cfg.perfect_start_lo, t)
	var hi := lerpf(cfg.perfect_end, cfg.perfect_end_lo, t)
	# RUBATO (boon): the whole window sits earlier — same skill, a faster song.
	if _b("rubato"):
		lo = maxf(cfg.swing_min, lo - cfg.rubato_shift)
		hi = maxf(lo + 0.06, hi - cfg.rubato_shift)
	# WIDE TEMPO (boon) + FENCER'S LINE (boon, the strike after a Bullseye) widen the green.
	var pad := 0.0
	if _b("wideTempo"):
		pad += cfg.wide_pad
	# FENCER'S LINE (D0 S5 · NO-SINGLE-NEXT-HIT LAW): a Bullseye widens the next 3 strikes (was the
	# single next window — imperceptible at tap pace). fencer_left counts the strikes still owed.
	if _b("fencersLine") and int(seat.vars.get("fencer_left", 0)) > 0:
		pad += cfg.fencer_pad
	# EDGE RESONANCE (D0 S2): the window doesn't tighten on the beat after a crit — the hold flag is
	# set on a crit and consumed by the next strike's grade read (no `s` here — a plain flag).
	if bool(seat.vars.get("res_edge", false)) and bool(seat.vars.get("res_edge_hold", false)):
		pad += cfg.res_edge_pad
	# FIRST NOTE (Fermata boon): a draw begun after a 1.5s rest gets extra ENTRY runway.
	if _fermata() and _b("firstNote") and bool(seat.vars.get("first_note_ready", false)):
		pad += cfg.first_note_pad
	if pad > 0.0:
		# F19: wideners TAPER with Flow — full help at walking pace, nothing at max Flow.
		var taper := (1.0 - t) if cfg.widener_taper else 1.0
		var w := (hi - lo) * pad * taper
		# THE WIDENER LAW (EDGE): for Fermata a widener adds ENTRY runway only — the lip (hi,
		# the cliff, the payoff) never moves; only the safe entry side opens up.
		if _fermata():
			lo -= w
		else:
			lo -= w; hi += w
	# THE EDGE (module): narrows around the centre for a bigger Perfect payoff.
	if aspect == "tempo" and _m("edge"):
		var mid := (lo + hi) * 0.5
		var half := (hi - lo) * 0.5 * cfg.edge_window_mult
		lo = mid - half
		hi = mid + half
	# THE SPEED GOVERNOR (D0 S0/S1): Quickstep (and any future beat-speed source) routes through
	# the ONE asymptotic wall — the window slides EARLIER (arrival speeds) AND tightens by the
	# governed speedup, floored at window_min so the Bullseye band stays readable. The per-source
	# doubletime_min_frac clamp is retired. push == 0 (boonless) → the block is skipped → identical.
	var sp := _gov_speedup(seat)
	if sp > 1.0:
		lo /= sp
		hi /= sp
		var mid2 := (lo + hi) * 0.5
		var half2 := maxf(cfg.window_min * 0.5, (hi - lo) * 0.5)
		lo = mid2 - half2
		hi = mid2 + half2
	# LARGO creed: the beat runs slower (window sits later) and TIGHTER (fewer, sharper Perfects).
	if _largo():
		lo *= cfg.largo_beat_mult
		hi *= cfg.largo_beat_mult
		var midL := (lo + hi) * 0.5
		var halfL := (hi - lo) * 0.5 * cfg.largo_window_mult
		lo = midL - halfL
		hi = midL + halfL
	# FERMATA · THE ROAMING WINDOW: relocate the green by this beat's shift (rolled on each
	# resolve in _strike). Applied LAST so the width and every boon/creed effect above are
	# preserved — only the CENTRE moves. Clamped reachable: the mouth can't sit before a fresh
	# coil could sharpen (+ a read margin), and the far edge stays on the fixed fermata ruler.
	# NEAR WINDOWS ARE EARNED (pacing pass): at low Flow the window keeps extra distance (the
	# slack), fading to nothing at max Flow — the twitchy short draws only exist in a hot streak.
	if _fermata():
		var fmid := (lo + hi) * 0.5
		var fhalf := (hi - lo) * 0.5
		var floor_sec := _coil_min(seat) + fhalf + 0.10 \
			+ cfg.fermata_near_slack * (1.0 - _tempo_t(seat))
		fmid = clampf(fmid * float(seat.vars.get("window_shift", 1.0)),
			floor_sec, cfg.fermata_ruler_sec - fhalf - 0.06)
		lo = fmid - fhalf
		hi = fmid + fhalf
	return [lo, hi]

# --- Venomancer POISON WHEEL: the lit lane (0=V, 1=F, 2=C) — the lane the NEXT Strike
#     feeds. A Strike stacks it then ADVANCES the wheel (riding V→F→C tops all three →
#     Toxic Synergy); Envenom stacks it WITHOUT advancing (fixate = over-stack a lane).
const WHEEL_KEYS := ["V", "F", "C"]
func _wheel(seat: Seat) -> int:
	return int(seat.vars.get("wheel", 0))
func _wheel_strike(s: CombatState, seat: Seat, perfect: bool) -> void:
	var lane := _wheel(seat)
	_apply_venom(seat, WHEEL_KEYS[lane], cfg.wheel_perfect_apply if perfect else cfg.wheel_strike_apply)
	if perfect and _b("contagion"):
		# Contagion: a Perfect also seeds a random OTHER lane — easier to keep all three live.
		var other := (lane + 1 + (1 if s.rng.next_float() < 0.5 else 0)) % 3
		_apply_venom(seat, WHEEL_KEYS[other], 1)
	seat.vars["wheel"] = (lane + 1) % 3

## The single outgoing-damage path: Flow multiplier, Execute relic, crit, then land.
## Poison ticks bypass this (they scale with neither Flow nor Execute — see _upkeep).
## `kind` tags the SOURCE for the view layer only (auto Strike vs a finisher/signature),
## so the HUD can colour non-auto-attacks distinctly — it never touches the checksum.
## COMBO RIG (§5) — a WHEN moment fired: if the run's wired WHEN matches, apply the wired THEN
## at its computed magnitude (a modest side-boost). Deterministic; a view-only pop shows it work.
func _rig_fire(s: CombatState, seat: Seat, when_id: String) -> void:
	if not _tempo_family() or rig.is_empty() or String(rig.get("when", "")) != when_id:
		return
	var then_id := String(rig.get("then", ""))
	var mag := TwinfangRig.magnitude(when_id, then_id)
	if mag <= 0:
		return
	match TwinfangRig.then_kind(then_id):
		"damage":
			_deal(s, seat, float(mag), false, false, "echo")     # flat — the board's number is honest
		"energy":
			_gain_energy(seat, float(mag))
		"crit":
			# KILLING EDGE (D0 S5 · A3 rework + NO-SINGLE-NEXT-HIT LAW): with the Edge meter up it
			# sharpens it by the greed-scaled magnitude; with no Edge meter its fallback is a
			# guaranteed crit across the NEXT 3 strikes (was a single flat charge — imperceptible).
			if _b("hone"):
				seat.vars["edge"] = mini(int(seat.vars.get("edge", 0)) + mag, cfg.edge_max)
			else:
				seat.vars["rig_crit"] = maxi(int(seat.vars.get("rig_crit", 0)), 3)
		"bleed":
			seat.vars["bleed_left"] = mag
			seat.vars["bleed_per"] = maxi(1, int(round(float(mag) / 4.0)))
			seat.vars["bleed_acc"] = 0
		"empower":
			seat.vars["rig_empower"] = maxi(int(seat.vars.get("rig_empower", 0)), mag)   # next dump +mag%
		"expose":
			seat.vars["rig_expose_amt"] = mag
			seat.vars["rig_expose_until"] = s.tick + _tt(s, 2.0)
	CombatCore._bump_diag(s, seat, "rig_fire")
	CombatCore.emit_event(s, {"t": "rig_fire", "player": seat.is_player,
		"when": when_id, "then": then_id, "mag": mag})

func _deal(s: CombatState, seat: Seat, raw: float, flow_scaled: bool, crit: bool,
		kind := "strike") -> float:
	var d := raw
	# STATS PAGE v2 — [boon_id, factor] for each inline multiplier that fired, credited to
	# the per-boon impact bucket once the hit lands (d unchanged — pure side-accounting).
	var bf: Array = []
	if flow_scaled:
		d *= _flow_mult(seat)
		if _b("tightrope") and _flow(seat) >= max_flow():     # TIGHTROPE: +dmg riding max Flow
			var f_tr := 1.0 + cfg.tightrope_mult
			d *= f_tr
			bf.append([&"tightrope", f_tr])
		var od := int(seat.vars.get("overdrive", 0))          # DOUBLE TIME: overdrive damage
		if od > 0:
			var f_od := 1.0 + float(od) * cfg.doubletime_dmg
			d *= f_od
			bf.append([&"overdrive", f_od])
	# THE BRINK (Fermata boon): a nerve-streak meter multiplies ALL your outgoing damage -
	# the fermata Through-Line, keyed to how deep you keep riding (a snap zeroes it in _snap).
	if _fermata() and _b("theBrink"):
		var f_br := 1.0 + cfg.brink_per * float(seat.vars.get("brink", 0))
		d *= f_br
		bf.append([&"theBrink", f_br])
	# COMBO RIG (§5) — Expose: the boss takes +% from ALL your damage for a beat.
	if int(seat.vars.get("rig_expose_until", 0)) >= s.tick:
		var f_ex := 1.0 + float(seat.vars.get("rig_expose_amt", 0)) / 100.0
		d *= f_ex
		bf.append([&"rig_expose", f_ex])
	# COMBO RIG (§5) — Overcharge: your NEXT dump hits harder (consumed by the first dump).
	if _is_dump(kind):
		var emp := int(seat.vars.get("rig_empower", 0))
		if emp > 0:
			var f_emp := 1.0 + float(emp) / 100.0
			d *= f_emp
			bf.append([&"rig_empower", f_emp])
			seat.vars["rig_empower"] = 0
	# FINISH IT (boon): the execute now lives on the SPENDER — Eviscerate only, below 35%.
	if _b("execute") and kind == "finisher" and s.boss.hp_max > 0.0 and s.boss.hp / s.boss.hp_max < 0.35:
		var f_exe := 1.0 + cfg.execute_mult
		d *= f_exe
		bf.append([&"execute", f_exe])
	if crit:
		d *= 2.0
		if _b("serrated"):                                    # SERRATED FATE: crits deal more
			var f_se := 1.0 + cfg.serrated_bonus
			d *= f_se
			bf.append([&"serrated", f_se])
		if _b("assassinsNote") and _in_opening(s, seat):      # ASSASSIN'S NOTE: crits in the Opening bite harder
			var f_an := 1.0 + cfg.assassin_open_mult
			d *= f_an
			bf.append([&"assassinsNote", f_an])
		if _m("strop"):                                       # THE STROP: this crit spends the whole KEEN meter
			var keen := int(seat.vars.get("keen", 0))
			if keen > 0:
				var f_keen := 1.0 + cfg.keen_per * float(keen)
				d *= f_keen
				bf.append([&"strop", f_keen])
				seat.vars["keen"] = 0
		if _tempo_family() and _b("redEdge"):             # THE RED EDGE duo: a crit pulses every live bleed
			for w in (seat.vars.get("wounds", []) as Array):
				_deal(s, seat, float(w["per"]), false, false, "bleed")
	# THE OPENING: a dump landed in the boss's vulnerability window hits harder (graded
	# by how centred on the sweet spot). Strikes/perfects are NOT dumps — they keep their
	# own rhythm. All hits of a multi-hit dump (Flurry) share the same window.
	if _is_dump(kind):
		var ob := _opening_bonus(s, seat)
		if ob > 0.0:
			d *= (1.0 + ob)
			bf.append([&"opening", 1.0 + ob])
		# TUTTI creed (Fermata) / ON THE BEAT (Tempo boon): a dump reads the live rhythm window —
		# a sharp/centred dump takes the grade multiplier, an off-window one is a shade weaker.
		var db := _dump_beat_bonus(s, seat)
		if db != 0.0:
			d *= (1.0 + db)
			if db > 0.0:
				bf.append([&"onTheBeat", 1.0 + db])
	# STRIKE-lane boons on the basic tap (not dumps): Press the Advantage rewards a Strike landed
	# inside the Opening; Cold Open rewards a Strike while Flow is low (a post-crash rebuild bet).
	if kind == "perfect" or kind == "strike":
		if _b("pressAdvantage") and _in_opening(s, seat):
			var f_pa := 1.0 + cfg.press_advantage_mult
			d *= f_pa
			bf.append([&"pressAdvantage", f_pa])
		if _b("coldOpen") and _flow(seat) <= cfg.cold_open_flow_max:
			var f_co := 1.0 + cfg.cold_open_mult
			d *= f_co
			bf.append([&"coldOpen", f_co])
		if _b("throughline"):                                 # THROUGH-LINE: consecutive Perfects escalate the tap
			var f_tl := 1.0 + cfg.throughline_per * float(seat.vars.get("tl_stacks", 0))
			d *= f_tl
			bf.append([&"throughline", f_tl])
	d = roundf(d)
	s.boss.hp = maxf(0.0, s.boss.hp - d)
	if d > 0.0:
		CombatCore.meter_dmg(s, seat, StringName(kind), d, crit)
		if not bf.is_empty():                                 # STATS PAGE v2 — per-boon impact
			CombatCore.credit_boon_factors(s, seat, d, bf)
		# `seat` lets the RAID HUD tell your hits from an ally's (damage_boss already
		# carries seat); solo ignores it. View-only — never checksummed.
		CombatCore.emit_event(s, {"t": "boss_hit", "amt": int(d), "crit": crit, "kind": kind, "seat": seat})
	return d

func _poison_boss(s: CombatState, seat: Seat, dmg: float) -> void:
	var d := roundf(dmg)
	if d <= 0.0:
		return
	s.boss.hp = maxf(0.0, s.boss.hp - d)
	CombatCore.meter_dmg(s, seat, &"poison", d)
	CombatCore.emit_event(s, {"t": "poison", "amt": int(d), "seat": seat})

# --------------------------------------------------------------------------
# THE OPENING — the offense-side timing verb. A telegraphed boss swing overextends
# it: the kit watches s.telegraph, stamps a vulnerability window around the impact
# tick into seat.vars (deterministic, no engine change), and your DUMPS punish it.
# --------------------------------------------------------------------------

const DUMP_KINDS := ["finisher", "coup", "rupture", "flurry"]

func _is_dump(kind: String) -> bool:
	return kind in DUMP_KINDS

## TUTTI (Fermata creed) / ON THE BEAT (Tempo boon): a dump that lands where a Strike would be
## graded takes the window's grade multiplier. Reads `since` against the live green — Bullseye/
## Perfect/Good pay, off-window is neutral (On the Beat) or a small penalty (Tutti — you paid a
## coil to fire it). Deterministic; the coil-delay/kick-tax of Tutti is a HUD-layer feel.
func _dump_beat_bonus(s: CombatState, seat: Seat) -> float:
	var tutti := _tutti()
	if not tutti and not _b("onTheBeat"):
		return 0.0
	# Fermata (Tutti) reads the PRESS-relative clock — a dump fired mid-coil where the release
	# would grade is "on the beat"; idle dumps are simply off-window. Tempo keeps strike-relative.
	var since: int
	if _fermata():
		since = (s.tick - int(seat.vars.get("coil_press_tick", s.tick))) \
			if bool(seat.vars.get("coiling", false)) else -1
	else:
		since = s.tick - int(seat.vars.get("last_strike_tick", -100000))
	var lo := _tt(s, _perfect_lo_sec(seat))
	var hi := _tt(s, _perfect_hi_sec(seat))
	# Fermata (Tutti) reads the DEPTH ramp — a dump fired deep in the ride takes the depth grade.
	var grade := _ramp_grade(since, lo, hi) if _fermata() else _strike_grade(since, lo, hi)
	var g := 0.0
	match grade:
		G_BULL: g = 0.8
		G_PERFECT: g = 0.6
		G_GOOD: g = 0.0
		_: g = (-(1.0 - cfg.tutti_off_mult)) if tutti else 0.0   # off-window: Tutti bites, On the Beat is neutral
	return g * (1.0 if tutti else cfg.on_the_beat_frac)

## Called every upkeep tick: when a DEFENSIBLE single-swing telegraph appears, schedule
## its opening. Deferred while a previous window is still live so a fresh swing can't
## clobber an opening you're mid-punish on (boss cooldowns give the deferral room).
func _stamp_opening(s: CombatState, seat: Seat) -> void:
	if not cfg.open_enabled or s.telegraph == null:
		return
	var ab := s.telegraph.ability
	if ab.response != AbilityRes.Response.DEFENSIBLE or not ab.strikes.is_empty():
		return
	if int(seat.vars.get("open_tg", -999999)) == s.telegraph.start_tick:
		return
	if s.tick <= int(seat.vars.get("open_to", -1)):
		return
	var impact := s.telegraph.start_tick + s.telegraph.dur_ticks
	seat.vars["open_tg"] = s.telegraph.start_tick
	seat.vars["open_from"] = impact - _tt(s, cfg.open_pre_sec)
	seat.vars["open_to"] = impact + _tt(s, cfg.open_post_sec)
	seat.vars["open_peak"] = impact + _tt(s, cfg.open_peak_sec)
	seat.vars["open_size"] = int(ab.size)

## True while the boss's Opening vulnerability window is live at s.tick (kit-local, deterministic).
func _in_opening(s: CombatState, seat: Seat) -> bool:
	if not cfg.open_enabled:
		return false
	var to := int(seat.vars.get("open_to", -1))
	return to >= 0 and s.tick >= int(seat.vars.get("open_from", 0)) and s.tick <= to

## The graded damage bonus for a dump landing at s.tick: full open_bonus inside the core
## (sweet spot), tapering to open_min_bonus at the window edges, 0.0 outside the window.
func _opening_bonus(s: CombatState, seat: Seat) -> float:
	if not cfg.open_enabled:
		return 0.0
	var to := int(seat.vars.get("open_to", -1))
	if to < 0:
		return 0.0
	var frm := int(seat.vars.get("open_from", 0))
	if s.tick < frm or s.tick > to:
		return 0.0
	var peak := int(seat.vars.get("open_peak", frm))
	var core := _tt(s, cfg.open_core_sec)
	var dist: int = absi(s.tick - peak)
	if dist <= core:
		return cfg.open_bonus
	var half := (peak - frm) if s.tick <= peak else (to - peak)
	var span := maxf(1.0, float(half - core))
	var f := clampf((float(dist) - float(core)) / span, 0.0, 1.0)
	return lerpf(cfg.open_bonus, cfg.open_min_bonus, f)

## Fired once per dump (after it lands): diagnostics + the aspect kicker on a PEAK read
## (Tempo bank Flow, Venom stack the lit lane) + a view-only pop. The DAMAGE bonus itself
## already applied inside _deal — this is the feedback and the read-reward.
func _opening_note(s: CombatState, seat: Seat, kind: String) -> void:
	if not cfg.open_enabled:
		return
	var b := _opening_bonus(s, seat)
	if b <= 0.0:
		CombatCore._bump_diag(s, seat, "open_whiff")   # a dump with no opening to punish
		return
	var peak := b >= cfg.open_bonus - 0.0001
	CombatCore._bump_diag(s, seat, "open_peak" if peak else "open_hit")
	if peak:
		if _tempo_family():
			for _i in cfg.open_flow:
				_gain_flow(seat)
		elif aspect == "venomancer":
			_apply_venom(seat, WHEEL_KEYS[_wheel(seat)], cfg.open_venom)
		_rig_fire(s, seat, "punish")       # COMBO RIG (§5): a dump PUNISHED the Opening
	CombatCore.emit_event(s, {"t": "opening", "grade": ("peak" if peak else "hit"),
		"player": seat.is_player, "kind": kind})

## Called once when a DUMP lands (Evis/Coup/Rupture/Flurry) — the Opening read-reward plus
## any equipped Module payoff (Deathmark detonation). Central "a dump landed" hook.
func _dump_landed(s: CombatState, seat: Seat, kind: String) -> void:
	_opening_note(s, seat, kind)
	_deathmark_detonate(s, seat)

## MODULE (The Deathmark): a dump cashes every stamped Mark for a burst, then clears them.
func _deathmark_detonate(s: CombatState, seat: Seat) -> void:
	if not _m("deathmark"):
		return
	var m := int(seat.vars.get("marks", 0))
	if m <= 0:
		return
	seat.vars["marks"] = 0
	_deal(s, seat, float(m) * cfg.mark_dmg, true, false, "detonate")
	CombatCore._bump_diag(s, seat, "detonate")
	CombatCore.emit_event(s, {"t": "detonate", "player": seat.is_player, "marks": m})

# --------------------------------------------------------------------------
# Venom (Venomancer): three poison types on the boss, kept in seat.vars.
# --------------------------------------------------------------------------

static func new_venom() -> Dictionary:
	return {"V": 0, "F": 0, "C": 0, "fes_ticks": 0, "syn_ramp": 1.0,
		"syn_active": false, "tick_acc": 0, "decay_acc": 0}

func _venom(seat: Seat) -> Dictionary:
	var v: Dictionary = seat.vars.get("venom", {})
	if v.is_empty():
		v = new_venom()
		seat.vars["venom"] = v
	return v

func _apply_venom(seat: Seat, type: String, n: int) -> void:
	var v := _venom(seat)
	v[type] = clampi(int(v[type]) + n, 0, cfg.ven_cap)

func _venom_total(seat: Seat) -> int:
	if aspect != "venomancer":
		return 0
	var v: Dictionary = seat.vars.get("venom", {})
	if v.is_empty():
		return 0
	return int(v["V"]) + int(v["F"]) + int(v["C"])

# --------------------------------------------------------------------------
# Per-tick upkeep: energy regen, Flow decay, and the Venomancer poison engine.
# --------------------------------------------------------------------------

func upkeep(s: CombatState, seat: Seat) -> void:
	# GEAR-1: LE CHAT's Bell — +30 starting energy, exactly once (gear-gated no-op).
	var bell := GearFx.bell_grant(seat)
	if bell > 0.0:
		_gain_energy(seat, bell)
	_gain_energy(seat, cfg.energy_regen * s.dt)
	# COMBO RIG (§5) — Bloodletter: a kit-side bleed ticks 1/s until spent.
	var bl := int(seat.vars.get("bleed_left", 0))
	if bl > 0:
		var bacc := int(seat.vars.get("bleed_acc", 0)) + 1
		if bacc >= _tt(s, 1.0):
			bacc = 0
			var per := mini(int(seat.vars.get("bleed_per", 1)), bl)
			_deal(s, seat, float(per), false, false, "bleed")
			seat.vars["bleed_left"] = bl - per
		seat.vars["bleed_acc"] = bacc
	# D0 S1 · THE WOUND POT: tick the boss-frame bleeds + drain any Exsanguinate erupt (no-op
	# with an empty pot → byte-identical for every non-Wound build).
	if _tempo_family():
		if not bool(seat.vars.get("res_computed", false)):
			_compute_resonance(seat)                      # D0 S2 · RESONANCE: light the theme perks once
			seat.vars["res_computed"] = true
		_tick_wounds(s, seat)
	# ARMORY (strong bell): the warm start hums — regen doubles for the first 10s.
	if GearFx.bell_live(s, seat):
		_gain_energy(seat, cfg.energy_regen * s.dt)
	# GEAR-2: Scratchpad — regen trebles while a long wind-up thinks.
	if GearFx.scratchpad_live(s, seat):
		_gain_energy(seat, cfg.energy_regen * s.dt * 2.0)
		if GearFx.flag_once(seat, &"scratchpad_pop"):
			GearFx.pop(s, seat, &"scratchpad")
	# Twin Step: the spent spare dodge charge returns after mod_step_recharge seconds.
	if _b("tfPropTwinStep") and int(seat.vars.get("dodge_spare", 1)) < 1 \
			and s.tick >= int(seat.vars.get("dodge_recharge_tick", 0)):
		seat.vars["dodge_spare"] = 1

	# CREED (Held Breath): the window lock expires here; Flow is frozen while it's active.
	if bool(seat.vars.get("window_locked", false)) and s.tick >= int(seat.vars.get("window_lock_until", 0)):
		seat.vars["window_locked"] = false

	# OVERDRIVE (module): when the FEVER ends, the ride crashes Flow down to a seed and rebuilds.
	if bool(seat.vars.get("fever_armed", false)) and s.tick >= int(seat.vars.get("fever_until", 0)):
		seat.vars["fever_armed"] = false
		seat.vars["flow"] = mini(_flow(seat), cfg.overdrive_seed)
		seat.vars["flow_decay_acc"] = 0
		CombatCore.emit_event(s, {"t": "overdrive_crash", "player": seat.is_player})
	# UNDERSTUDY (boon): a spent groove-save recharges over time, up to the cap.
	if _tempo_family() and _b("understudy"):
		var usc := int(seat.vars.get("us_charges", cfg.understudy_charges))
		if usc < cfg.understudy_charges and s.tick >= int(seat.vars.get("us_recharge_tick", 0)):
			seat.vars["us_charges"] = usc + 1
			if usc + 1 < cfg.understudy_charges:
				seat.vars["us_recharge_tick"] = s.tick + _tt(s, cfg.understudy_recharge)
	# BATTLE HYMN (support): publish the raid-haste tier while you hold high Flow (the raid reads it).
	if aspect == "tempo" and _b("battleHymn"):
		seat.vars["battle_hymn_tier"] = _flow(seat) if _flow(seat) >= cfg.battle_hymn_flow_min else 0

	# FERMATA (§13): the coil engine — charge while holding, sharpen, feed the build-territory dials.
	if _fermata():
		_fermata_upkeep(s, seat)

	# Flow decays toward 0 between Perfects. Frozen while a Held-Breath window lock is active,
	# and HELD NOTE (boon) pauses it while the boss winds up a swing (read the telegraph in peace).
	var held := _b("heldNote") and s.telegraph != null
	if _flow(seat) > 0 and not bool(seat.vars.get("window_locked", false)) and not held \
			and s.tick >= int(seat.vars.get("sp_flowlock_until", 0)):   # SET PIECE flourish holds the tempo
		var acc := int(seat.vars.get("flow_decay_acc", 0)) + 1
		var every := _tt(s, cfg.flow_decay_every * (1.5 if _b("virtuoso") else 1.0))
		if acc >= every:
			acc -= every
			seat.vars["flow"] = _flow(seat) - 1
		seat.vars["flow_decay_acc"] = acc

	if aspect == "venomancer":
		_tick_venom(s, seat)

	# THE OPENING: schedule a vulnerability window when the boss commits a swing.
	_stamp_opening(s, seat)

func _tick_venom(s: CombatState, seat: Seat) -> void:
	var v := _venom(seat)

	# Stacks bleed off slowly — the cocktail won't sit at cap, you must maintain it.
	v["decay_acc"] = int(v["decay_acc"]) + 1
	var decay_every := _tt(s, cfg.venom_decay_every)
	while int(v["decay_acc"]) >= decay_every:
		v["decay_acc"] = int(v["decay_acc"]) - decay_every
		if int(v["V"]) > 0: v["V"] = int(v["V"]) - 1
		if int(v["F"]) > 0: v["F"] = int(v["F"]) - 1
		if int(v["C"]) > 0: v["C"] = int(v["C"]) - 1

	if int(v["F"]) > 0:
		v["fes_ticks"] = int(v["fes_ticks"]) + 1
	else:
		v["fes_ticks"] = 0

	var three: bool = int(v["V"]) > 0 and int(v["F"]) > 0 and int(v["C"]) > 0
	if three:
		v["syn_active"] = true
		var rate := cfg.syn_rate * (1.6 if _b("catalyst") else 1.0)
		v["syn_ramp"] = minf(cfg.syn_cap, float(v["syn_ramp"]) + rate * s.dt)
	else:
		v["syn_active"] = false
		v["syn_ramp"] = 1.0

	v["tick_acc"] = int(v["tick_acc"]) + 1
	var tick_every := _tt(s, cfg.venom_tick_every)
	while int(v["tick_acc"]) >= tick_every:
		v["tick_acc"] = int(v["tick_acc"]) - tick_every
		var pot := 1.3 if _b("potent") else 1.0
		var fes_sec := float(v["fes_ticks"]) * s.dt
		var dmg := float(v["V"]) * 1.8 * pot \
			+ float(v["F"]) * 1.5 * pot * (1.0 + (0.20 if _b("fastRot") else 0.12) * fes_sec) \
			+ float(v["C"]) * 1.1 * pot
		if three:
			dmg += float(int(v["V"]) + int(v["F"]) + int(v["C"])) * 0.5 * float(v["syn_ramp"]) * pot
		_poison_boss(s, seat, dmg)

# --------------------------------------------------------------------------
# FERMATA — the coil engine (per-tick): charge → sharpen → feed the build dials.
# --------------------------------------------------------------------------

func _fermata_upkeep(s: CombatState, seat: Seat) -> void:
	# SHADOW DANCE (module): the bullet-time window ends → crash Flow to a seed and rebuild.
	if bool(seat.vars.get("dance_armed", false)) and s.tick >= int(seat.vars.get("dance_until", 0)):
		seat.vars["dance_armed"] = false
		seat.vars["flow"] = mini(_flow(seat), cfg.shadowdance_seed)
		seat.vars["flow_decay_acc"] = 0
		CombatCore.emit_event(s, {"t": "dance_end", "player": seat.is_player})

	if not bool(seat.vars.get("coiling", false)):
		seat.vars["veil_warband_active"] = false
		# THE UNSEEN BLADE (keystone): bank a Shade per interval while RESTING — the rest-vs-chain
		# dial (idle bleeds Flow but gathers Shades for one giant next release).
		if _b("unseenBlade"):
			var sacc := int(seat.vars.get("shade_acc", 0)) + 1
			if sacc >= _tt(s, cfg.unseen_shade_every):
				sacc = 0
				seat.vars["shades"] = mini(int(seat.vars.get("shades", 0)) + 1, cfg.unseen_shade_cap)
			seat.vars["shade_acc"] = sacc
		return

	var press := int(seat.vars.get("coil_press_tick", s.tick))
	var coil_ticks := s.tick - press
	var min_ticks := _tt(s, _coil_min(seat))

	# THE SNAP: while coiling, the sweep crossing the lip breaks the note (no snap during a Dance).
	if not _dance_active(s, seat) and float(coil_ticks) > float(_tt(s, _fermata_lip_sec(seat))):
		_snap(s, seat)
		return

	# the SHNK: the tick the blade crosses sharp — emit once.
	if coil_ticks >= min_ticks and not bool(seat.vars.get("sharp", false)):
		seat.vars["sharp"] = true
		CombatCore.emit_event(s, {"t": "coil_sharp", "player": seat.is_player})

	# RESTLESS DARK (boon): energy regens faster inside the shadow.
	if _b("restlessDark"):
		_gain_energy(seat, cfg.energy_regen * s.dt * cfg.restless_dark_regen)

	# VEIL OVER THE WARBAND (support): publish the shelter while drawing (raid applies it — owed).
	seat.vars["veil_warband_active"] = _b("veilWarband")

# --------------------------------------------------------------------------
# Incoming damage: Debilitate (Crippling softens the boss) + Flow reset on a swing.
# --------------------------------------------------------------------------

func modify_incoming(_s: CombatState, seat: Seat, dmg: float, _source: StringName, _size: int) -> float:
	if aspect == "venomancer" and _b("debilitate"):
		var v: Dictionary = seat.vars.get("venom", {})
		var c := int(v.get("C", 0)) if not v.is_empty() else 0
		if c > 0:
			return dmg * (1.0 - minf(0.30, float(c) * 0.04))
	# VANISH (Fermata boon): the first boss hit taken during a coil is softened in the shadow.
	if _fermata() and _b("vanish") and bool(seat.vars.get("coiling", false)) \
			and not bool(seat.vars.get("veil_used", false)):
		seat.vars["veil_used"] = true
		return dmg * (1.0 - cfg.vanish_reduce)
	return dmg

## Eating a swing wipes your Flow — the core tension. Swings carry a Size; the
## unavoidable Hex pulse and enrage do not, so only swings reset Flow (faithful).
func on_damage_taken(s: CombatState, seat: Seat, _dmg: float, _source: StringName, size: int) -> void:
	GearFx.damage_taken(s, seat)   # GEAR-1: death procs (Swan Song) — gear-gated no-op
	if size != AbilityRes.Size.NONE and _flow(seat) > 0:
		if GearFx.once(seat, &"grace_period"):
			GearFx.pop(s, seat, &"grace_period")   # GEAR-2: the song survives one landed swing
		elif _tempo_family() and _b("understudy") and int(seat.vars.get("us_charges", cfg.understudy_charges)) > 0:
			# UNDERSTUDY (boon): spend a groove-save — the swing lands, but your Flow survives it.
			seat.vars["us_charges"] = int(seat.vars.get("us_charges", cfg.understudy_charges)) - 1
			seat.vars["us_recharge_tick"] = s.tick + _tt(s, cfg.understudy_recharge)
			CombatCore.emit_event(s, {"t": "understudy_save", "player": seat.is_player})
		else:
			var before := _flow(seat)
			_creed_slip(s, seat)                   # REWORK: eating a swing is a SLIP (the Creed pays it)
			if _flow(seat) < before:
				CombatCore.emit_event(s, {"t": "flow_lost", "player": seat.is_player})

# --- GEAR-1: a boss self-heal was DENIED somewhere — Riftmaw Tooth pays energy ---
func on_boss_heal_denied(s: CombatState, seat: Seat) -> void:
	var g := GearFx.tooth_grant(s, seat)
	if g > 0.0:
		_gain_energy(seat, g)

## M7 string beats join the rhythm: a PERFECT dodge plays like a Perfect Strike
## (+1 Flow); a GOOD one pays a little energy; holding a feint keeps the song
## going. A LANDED beat wipes Flow through on_damage_taken above (beats carry a
## Size) — dodging protects the solo, exactly like dodging a swing does.
func on_strike_result(s: CombatState, seat: Seat, _ability: AbilityRes,
		_strike: StrikeRes, grade: int) -> void:
	match grade:
		StrikeRes.Grade.PERFECT:
			if _tempo_family():
				_gain_flow(seat)                   # a perfect dodge keeps the accelerando alive
			else:
				_gain_energy(seat, cfg.strike_good_energy)   # Venom has no Flow — footwork pays energy
			if _b("dancersgrace"):
				seat.vars["next_perfect"] = true   # Opus: a perfect dodge primes the blades
			if _b("tfTrigBeat"):
				_tf_trigger(s, seat, "beat")       # Phase B: PERFECT beat = proc moment
		StrikeRes.Grade.GOOD:
			_gain_energy(seat, cfg.strike_good_energy)
		StrikeRes.Grade.READ:
			_gain_energy(seat, cfg.strike_read_energy)
		_:
			pass

# --------------------------------------------------------------------------
# Dodge: a clean negate (no reflect). Riposte relic feeds combo on a dodge.
# --------------------------------------------------------------------------

func defense_active() -> float:
	return cfg.dodge_active

func defense_cd() -> float:
	return cfg.dodge_cd

## THE ONE DODGE: Twinfang (Tempo/Fermata/Venom) folds its swing-negate and its
## barrage beat-dodge onto the single SPACE press (DODGE-PLAN.md 2026-07-08).
func unified_dodge() -> bool:
	return true

## Twin Step (Phase B): the engine just charged the dodge cooldown — a spare charge
## eats it, so a second step is available back-to-back; upkeep restores the spare.
## Under the unified dodge the live gate is dodge_ready_tick (kept in lockstep with
## defense_ready_tick), so refund BOTH.
func on_defense_press(s: CombatState, seat: Seat) -> void:
	if _b("tfPropTwinStep") and int(seat.vars.get("dodge_spare", 1)) > 0:
		seat.vars["dodge_spare"] = int(seat.vars.get("dodge_spare", 1)) - 1
		seat.dodge_ready_tick = s.tick
		seat.defense_ready_tick = s.tick
		seat.vars["dodge_recharge_tick"] = s.tick + _tt(s, cfg.mod_step_recharge)

func on_negate(s: CombatState, seat: Seat, _ability: AbilityRes) -> void:
	if _b("dodgeCp"):
		_gain_cp(seat, 2)
	if _b("tfTrigEvade"):
		_tf_trigger(s, seat, "evade")      # Phase B: a clean dodge = proc moment

## FERMATA base law: a DODGE INPUT mid-coil breaks the coil (you lose the charge, no stagger).
## SHADOWSTEP keeps it at half progress; VANISH's top rung keeps it fully sharp. Softeners only —
## the base always breaks, so coiling on top of a dodge beat is greedy.
func on_dodge_press(s: CombatState, seat: Seat) -> void:
	if not _fermata() or not bool(seat.vars.get("coiling", false)):
		return
	if _b("vanish") and cfg.vanish_keep_sharp:
		return                                                     # VANISH (opus): the draw survives, still sharp
	seat.vars["coiling"] = false
	seat.vars["sharp"] = false
	CombatCore.emit_event(s, {"t": "coil_break", "player": seat.is_player})

# --------------------------------------------------------------------------
# Abilities
# --------------------------------------------------------------------------

func on_action(s: CombatState, seat: Seat, id: StringName, _target: Seat = null) -> bool:
	match String(id):
		"strike":      return _strike(s, seat)
		"coil":        return _coil_press(s, seat)    # FERMATA: begin the hold
		"release":     return _coil_release(s, seat)  # FERMATA: resolve the strike on release
		"eviscerate":  return _eviscerate(s, seat)
		"kick":        return _kick(s, seat)
		"envenom":     return _envenom(s, seat)
		"flurry":      return _flurry(s, seat)
		"gracenote":   return _grace_note(s, seat)
		"coda":        return _coda(s, seat)
		"setpiece":    return _setpiece(s, seat)   # D0 S6 · the signature CD
		"coupdegrace": return _coup(s, seat)
		"rupture":     return _rupture(s, seat)
	return false

## GRADED WINDOW (§2c): given `since` and the live green [lo,hi], return the grade. The
## dead centre is a Bullseye, the core is Perfect, the flanks are Good, outside is a Miss.
func _strike_grade(since: int, lo: int, hi: int) -> int:
	if since < lo or since > hi:
		return G_MISS
	var center := (float(lo) + float(hi)) * 0.5
	var halfw := maxf(1.0, (float(hi) - float(lo)) * 0.5)
	var p := absf(float(since) - center) / halfw   # 0 at centre … 1 at the edge
	if p <= cfg.grade_bull_frac:
		return G_BULL
	if p <= cfg.grade_perfect_frac:
		return G_PERFECT
	return G_GOOD

## FERMATA · THE RAMP grade (EDGE verb): graded by DEPTH into the window, not centredness.
## Entry is a weak-but-safe GOOD; the ramp climbs to a BULLSEYE at the far lip, right against the
## SNAP cliff (crossing the lip is caught separately). depth d = (since − lo) / (hi − lo); d > 1
## is the Patient Knife extension (still BULLSEYE, with a deep bonus in _coil_release_bonus).
func _ramp_grade(since: int, lo: int, hi: int) -> int:
	if since < lo:
		return G_MISS
	var d := (float(since) - float(lo)) / maxf(1.0, float(hi - lo))
	if d < cfg.fermata_good_frac:
		return G_GOOD
	if d < cfg.fermata_good_frac + cfg.fermata_perfect_frac:
		return G_PERFECT
	return G_BULL

## Consolidated crit roll. fifthCrit counts only true Perfects (is_perfect); Heartseeker
## fires on a Bullseye; Opportunist rolls a chance on ANY Strike during a boss wind-up.
## CRIT (A7 — the Whetted Edge): base Tempo has NO crits. Two opt-in sources:
## Heartseeker (Bullseyes always crit) and HONE's standing EDGE meter (every hit rolls
## crit ~per-point). Nothing is consumed — Edge is maintained by clean rhythm, dulled by slips.
func _roll_crit(s: CombatState, seat: Seat, bullseye: bool, _is_perfect: bool) -> bool:
	var crit := false
	if bullseye and bool(_creed().get("whetstone", false)):   # WHETSTONE creed (v4 EDGE entry): Bullseyes can crit from run start
		if s.rng.next_float() < cfg.whetstone_crit:
			crit = true
	if bullseye and _b("heartseeker"):             # HEARTSEEKER: the standalone entry — Bullseyes always crit
		crit = true
	if _b("hone"):                                 # HONE (keystone): the standing Edge meter grants crit chance
		var edge := int(seat.vars.get("edge", 0))
		if edge > 0 and s.rng.next_float() < float(edge) * cfg.hone_crit_per_pt:
			crit = true
	if int(seat.vars.get("rig_crit", 0)) > 0:      # COMBO RIG (§5) — Killing Edge charge
		seat.vars["rig_crit"] = int(seat.vars["rig_crit"]) - 1
		crit = true
	if crit and bool(seat.vars.get("res_edge", false)):   # EDGE RESONANCE: hold the next window wider
		seat.vars["res_edge_hold"] = true
	return crit

## FERMATA — press to coil into shadow. Records the press tick; the strike resolves on RELEASE.
## A press while already coiling (or during an unravel stagger) is a no-op — one coil at a time.
func _coil_press(s: CombatState, seat: Seat) -> bool:
	if not _fermata():
		return false
	if bool(seat.vars.get("coiling", false)):
		return false
	if s.tick < int(seat.vars.get("strike_lock_until", 0)):
		return false                                   # still staggered from an unravel
	seat.vars["coiling"] = true
	seat.vars["sharp"] = bool(seat.vars.get("coil_instant", false)) or _dance_active(s, seat)
	seat.vars["coil_press_tick"] = s.tick
	seat.vars["veil_used"] = false
	# THE REST: a draw begun after a 1.5s rest arms First Note (entry runway) and the Rested Draw WHEN.
	var rested := (s.tick - int(seat.vars.get("last_strike_tick", -100000))) >= _tt(s, 1.5)
	seat.vars["first_note_ready"] = _b("firstNote") and rested
	if rested:
		_rig_fire(s, seat, "rested")
	CombatCore.emit_event(s, {"t": "coil_press", "player": seat.is_player})
	return true

## FERMATA — release the coil. Held < the sharpen floor ⇒ the shadow UNRAVELS (no strike, a
## short stagger, NO Flow loss). Sharp ⇒ resolve exactly like a Strike, graded on `since`, with
## the coil-duration build dials layered on. `coil_instant` (Eclipse/Dance) skips the floor.
func _coil_release(s: CombatState, seat: Seat) -> bool:
	if not _fermata() or not bool(seat.vars.get("coiling", false)):
		return false
	seat.vars["coiling"] = false
	seat.vars["veil_warband_active"] = false
	var coil_ticks := s.tick - int(seat.vars.get("coil_press_tick", s.tick))
	var dance := _dance_active(s, seat)
	var instant := bool(seat.vars.get("coil_instant", false)) or dance
	seat.vars["coil_instant"] = false
	if not instant and coil_ticks < _tt(s, _coil_min(seat)):
		# UNRAVEL — the click-cheat killer: released before the SHNK, no strike, no Flow loss.
		seat.vars["sharp"] = false
		if not (_b("quietFuse") and cfg.quiet_fuse_no_stagger):
			seat.vars["strike_lock_until"] = s.tick + _tt(s, cfg.coil_unravel_stagger)
		# PATIENT KNIFE: an unravel is a FULL crash (its greed cuts both ways).
		if bool(_creed().get("unravel_slip", false)):
			_creed_slip(s, seat, true)
		if _b("firstBlood"):                            # FIRST BLOOD: a fumble arms the comeback release
			seat.vars["first_blood_ready"] = true
		_rig_fire(s, seat, "unravel")
		CombatCore._bump_diag(s, seat, "unravel")
		CombatCore.emit_event(s, {"t": "unravel", "player": seat.is_player})
		return true
	# THE SNAP: released PAST the lip — rode the ramp too deep, the note breaks (no snap in the Dance).
	if not dance and float(coil_ticks) > float(_tt(s, _fermata_lip_sec(seat))):
		_snap(s, seat)
		return true
	seat.vars["sharp"] = false
	return _strike(s, seat, true, coil_ticks)

## The rhythm. Strike too early (< swing_min) and it's ignored (no cost). Inside the green
## window it's graded Bullseye/Perfect/Good (§2c); outside = a Miss (base hit + Creed slip).
## FERMATA · THE DRAW (pacing pass): a release is graded on the PRESS-relative clock —
## `coil_ticks` IS the sweep position. The needle only runs while you hold, so idle time is
## genuinely calm and dumps/kicks get cast between draws. Tempo's strike-relative clock is
## untouched (`from_release` is fermata-only).
func _strike(s: CombatState, seat: Seat, from_release := false, coil_ticks := 0) -> bool:
	var a: Dictionary = cfg.abilities["strike"]
	var last := int(seat.vars.get("last_strike_tick", -100000))
	var since := coil_ticks if from_release else (s.tick - last)
	var fever := _fever(s, seat)                       # OVERDRIVE FEVER bypasses the rhythm gate (auto-chain)
	if not fever and not from_release and since < _tt(s, _swing_min_sec(seat)):
		return false                                   # too early — the press is dropped
	# DOUBLE TIME: the overdrive ride only lives at max Flow — the moment you dip, it's gone.
	if _flow(seat) < max_flow():
		seat.vars["overdrive"] = 0
	var cost := float(a["energy"])
	if fever:
		cost = 0.0                                     # OVERDRIVE FEVER: free strikes
	elif aspect == "tempo" and _b("syncopation") and _flow(seat) >= max_flow():
		cost = 0.0
	if aspect == "venomancer" and int(seat.vars.get("encore_left", 0)) > 0:
		cost = maxf(0.0, cost - 6.0)                   # GEAR-2: Encore Bell (Venom side)
	if seat.resource < cost:
		return false                                   # out of energy
	# ACCELERANDO + GRADED WINDOW (§2c): the live green [lo,hi] rides Flow (Venom pins Flow 0).
	var lo := _tt(s, _perfect_lo_sec(seat))
	var hi := _tt(s, _perfect_hi_sec(seat))
	var grade := _ramp_grade(since, lo, hi) if from_release else _strike_grade(since, lo, hi)
	if fever:
		grade = G_BULL                                 # OVERDRIVE FEVER: every strike lands dead-centre
	if bool(seat.vars.get("coda_ready", false)):
		seat.vars["coda_ready"] = false                # CODA (spell): the primed beat is all-green
		grade = maxi(grade, G_PERFECT)
	if from_release and _dance_active(s, seat):
		grade = maxi(grade, G_PERFECT)                 # SHADOW DANCE: bullet-time — releases grade up to Perfect
	if from_release and _b("firstBlood") and bool(seat.vars.get("first_blood_ready", false)):
		grade = maxi(grade, G_PERFECT)                 # FIRST BLOOD: the comeback release lands clean
		seat.vars["first_blood_ready"] = false
	# F26: base Syncopation is COST-ONLY now — the Good→Perfect grade-up moves to a future Opus rune.
	var perfect := grade >= G_PERFECT
	var bullseye := grade == G_BULL
	# EDGE RESONANCE (D0 S2): the after-crit widened window has now been read for grading — consume
	# the hold (a fresh crit below re-sets it for the next beat).
	if bool(seat.vars.get("res_edge_hold", false)):
		seat.vars["res_edge_hold"] = false
	seat.resource -= cost
	if int(seat.vars.get("encore_left", 0)) > 0:       # the encore spends a beat per Strike
		seat.vars["encore_left"] = int(seat.vars["encore_left"]) - 1
	seat.vars["last_strike_tick"] = s.tick

	var base := float(a["dmg"])
	var cp := int(a["cp"])
	# FERMATA: the ride-depth build dials (Patient deep-lip / Unseen Blade Shades / Killing Whisper)
	# multiply the release BEFORE grading branches; Shades + First Note consume here.
	if from_release:
		base *= (1.0 + _coil_release_bonus(s, seat, coil_ticks, bullseye))
		if _b("unseenBlade"):
			seat.vars["shades"] = 0
		seat.vars["first_note_ready"] = false
	if perfect:
		CombatCore._bump_diag(s, seat, "perfect_strike")   # class-signature skill signal (token mint)
		CombatCore._bump_diag(s, seat, "s_bull" if bullseye else "s_perfect")
		var gm := (cfg.bull_mult if bullseye else 1.6)     # dead centre bites harder than the core
		base = roundf(base * gm * (cfg.edge_perfect_mult if _m("edge") else 1.0) * (cfg.largo_hit_mult if _largo() else 1.0))   # Edge / LARGO: bigger Perfects
		var crit := _roll_crit(s, seat, bullseye, true)
		_deal(s, seat, base, true, crit, "perfect")
		CombatCore.emit_event(s, {"t": "perfect", "player": seat.is_player})
		if _tempo_family():
			_gain_energy(seat, cfg.strike_bull_refund if bullseye else cfg.strike_perfect_refund)   # F11: BASE energy refund
			var was_max := _flow(seat) >= max_flow()
			_gain_flow(seat)                                                  # Flow = BPM (Tempo only)
			if _b("hone"):                                                    # A7: hone the Edge meter with clean rhythm
				seat.vars["edge"] = mini(int(seat.vars.get("edge", 0)) + (cfg.edge_bull_gain if bullseye else cfg.edge_perfect_gain), cfg.edge_max)
			if _b("throughline"):                                             # THROUGH-LINE: extend the run
				seat.vars["tl_stacks"] = mini(int(seat.vars.get("tl_stacks", 0)) + 1, cfg.throughline_cap)
			# D0 S1 · THE WOUND (Open Veins on Bullseye · Lacerate half on Perfect), QUICKSTEP push, KEEN whet.
			if bool(_creed().get("open_veins", false)) and bullseye:
				_inscribe_wound(s, seat, cfg.open_veins_tick)
			if _b("lacerate"):
				_inscribe_wound(s, seat, cfg.open_veins_tick * cfg.lacerate_frac)
			if _b("quickstep"):
				seat.vars["quickstep"] = mini(int(seat.vars.get("quickstep", 0)) + 1, cfg.quickstep_cap)
			if _m("strop"):
				seat.vars["keen"] = mini(int(seat.vars.get("keen", 0)) + 1, cfg.keen_cap)
			# RONDO transform: during the RETURN, each Perfect+ re-strikes a slice of the stored Coup.
			if _transform() == "rondo" and s.tick <= int(seat.vars.get("rondo_until", -1)):
				var rfrac := (cfg.rondo_restrike_bull if bullseye else cfg.rondo_restrike) + (cfg.second_theme_bonus if _b("secondTheme") else 0.0)
				var rhit := float(seat.vars.get("rondo_hit", 0.0)) * rfrac
				if rhit > 0.0:
					var rpaid := _deal(s, seat, roundf(rhit), false, false, "rondo")
					var rtot := float(seat.vars.get("rondo_paid", 0.0)) + rpaid
					seat.vars["rondo_paid"] = rtot
					if rtot >= float(seat.vars.get("rondo_hit", 0.0)) * 0.5 and not bool(seat.vars.get("rondo_when_fired", false)):
						seat.vars["rondo_when_fired"] = true
						_rig_fire(s, seat, "returnWhen")
					if _b("reprise"):                            # THE REPRISE duo: the Return re-opens a bleed
						_inscribe_wound(s, seat, cfg.open_veins_tick)
			if _m("overdrive") and was_max and not fever:                     # OVERDRIVE: max-Flow Perfects fill the meter
				var od2 := int(seat.vars.get("od_meter", 0)) + 1
				if od2 >= cfg.overdrive_fill:
					seat.vars["fever_until"] = s.tick + _tt(s, cfg.overdrive_fever_sec)   # FEVER!
					seat.vars["fever_armed"] = true
					CombatCore._bump_diag(s, seat, "fever")
					od2 = 0
				seat.vars["od_meter"] = od2
			# COMBO RIG (§5) WHEN moments — Peak (just hit max), Riff (every 3rd Perfect), Bullseye
			if not was_max and _flow(seat) >= max_flow():
				_rig_fire(s, seat, "peak")
			var rr := int(seat.vars.get("rig_riff", 0)) + 1
			if rr >= 3:
				rr = 0
				_rig_fire(s, seat, "riff")
			seat.vars["rig_riff"] = rr
			if bullseye:
				_rig_fire(s, seat, "bullseye")
			if _b("doubleTime") and was_max:                                    # DOUBLE TIME v2: fill the GHOST window
				var ghm := int(seat.vars.get("ghost_meter", 0)) + 1
				if ghm >= cfg.ghost_fill:
					seat.vars["ghost_until"] = s.tick + _tt(s, cfg.ghost_window_sec)
					ghm = 0
					CombatCore._bump_diag(s, seat, "ghost_open")
				seat.vars["ghost_meter"] = ghm
			if _m("deathmark"):                                              # MODULE (Deathmark): stamp the boss
				seat.vars["marks"] = mini(int(seat.vars.get("marks", 0)) + 1, cfg.mark_cap)
			if _fermata():
				_fermata_perfect(s, seat, bullseye, was_max, fever)
				if _b("theBrink"):                                          # THE BRINK: nerve-streak +1 on a deep release
					seat.vars["brink"] = mini(int(seat.vars.get("brink", 0)) + 1, cfg.brink_cap)
				if _b("composure"):                                         # COMPOSURE: rest without bleeding the streak
					seat.vars["composure_until"] = s.tick + _tt(s, cfg.composure_sec)
			var t := flow_tier(seat)
			if t >= 1:
				_deal(s, seat, roundf(float(a["dmg"]) * 0.6), true, false, "perfect")   # Tier 1: extra hit
			if t >= 2:
				_gain_energy(seat, 6.0)                                       # Tier 2: energy refund (combo bonus removed)
			# DOUBLE TIME v2 (ghost notes): inside the window every Perfect+ lands a free ghost half-strike.
			if _b("doubleTime") and s.tick < int(seat.vars.get("ghost_until", 0)):
				_deal(s, seat, roundf(float(a["dmg"]) * cfg.ghost_frac), true, false, "ghost")
		else:
			_wheel_strike(s, seat, true)                                     # ride the wheel (Perfect)
	elif grade == G_GOOD:
		CombatCore._bump_diag(s, seat, "s_good")
		if _tempo_family():
			seat.vars["flow_decay_acc"] = 0                                  # F8: a GOOD MAINTAINS — it holds the groove (pauses decay)
		_deal(s, seat, roundf(base * cfg.good_mult), true, _roll_crit(s, seat, false, false), "strike")
		if aspect == "venomancer":
			_wheel_strike(s, seat, false)
		if from_release and _b("coldCut"):                              # COLD CUT: the shallow-safe release pays combo
			_gain_cp(seat, cfg.cold_cut_cp)
			if cfg.cold_cut_refund > 0.0:
				_gain_energy(seat, cfg.cold_cut_refund)
		# a GOOD treads water — it lands, but no Flow gained and NO slip (the safety tier)
	else:
		CombatCore._bump_diag(s, seat, "s_miss")
		_deal(s, seat, base, true, _roll_crit(s, seat, false, false), "strike")
		if aspect == "venomancer":
			_wheel_strike(s, seat, false)                                    # ride the wheel (normal)
		else:
			_creed_slip(s, seat)                                             # REWORK: a missed beat is a SLIP (Creed pays it)
			if _fermata() and _b("firstBlood"):                              # FIRST BLOOD: a miss arms the comeback
				seat.vars["first_blood_ready"] = true
	# FENCER'S LINE (D0 S5): a Bullseye re-arms the widener for the next 3 strikes; every other
	# strike spends one of them (the DURATION rider the NO-SINGLE-NEXT-HIT law demands).
	if _b("fencersLine"):
		if bullseye:
			seat.vars["fencer_left"] = 3
		elif int(seat.vars.get("fencer_left", 0)) > 0:
			seat.vars["fencer_left"] = int(seat.vars["fencer_left"]) - 1
	# FERMATA · THE ROAMING WINDOW: every resolve rolls where the NEXT green lands. Drawn from
	# s.rng so lockstep replicas agree; only the fermata aspect reaches this line, so the
	# tempo/venom rng streams are untouched (their checksums stay byte-identical).
	# PATIENT KNIFE raises the roll's floor — the window never lands near; the knife waits.
	if _fermata():
		if bullseye and _b("refrain"):
			seat.vars["refrain_repeat"] = true               # REFRAIN: a Bullseye HOLDS the window — keep the shift,
		else:                                              # so the next draw replays the same note (the repeat pays more)
			seat.vars["window_shift"] = _roll_window_shift(s, seat)
	# D0 S6 · THE SET PIECE: tally the marked phrase; a clean all-Perfect+ phrase cashes the flourish.
	if _tempo_family() and bool(seat.vars.get("sp_armed", false)):
		if perfect:
			seat.vars["sp_hits"] = int(seat.vars.get("sp_hits", 0)) + 1
		seat.vars["sp_left"] = int(seat.vars.get("sp_left", 0)) - 1
		if int(seat.vars["sp_left"]) <= 0:
			seat.vars["sp_armed"] = false
			if int(seat.vars.get("sp_hits", 0)) >= cfg.setpiece_phrase:
				_setpiece_cash(s, seat)
	_gain_cp(seat, cp + (cfg.bull_bonus_cp if bullseye else 0))   # F15: a Bullseye grants extra combo (superset of Perfect)
	if _b("strikeEnergy") and perfect:
		_gain_energy(seat, cfg.efficiency_refund)                 # Efficiency: stacks ON TOP of the base refund
	# FERMATA release after-effects (Twin Echo · Eclipse re-coil · Phantom twin · the on-edge rig).
	if from_release:
		_fermata_after_release(s, seat, grade, bullseye, perfect, base, coil_ticks)
	# Tell the view HOW this strike landed so the rhythm bar can flash a clear verdict.
	var result := (("bullseye" if bullseye else "perfect") if perfect
		else ("good" if grade == G_GOOD else ("early" if since < lo else "late")))
	CombatCore.emit_event(s, {"t": "strike", "player": seat.is_player, "result": result})
	return true

# --------------------------------------------------------------------------
# FERMATA — the release-side helpers (bonuses, module fills, keystone effects).
# --------------------------------------------------------------------------

## The release damage fraction: with the press-relative clock, the draw's LENGTH is decided by
## where the window landed — so Patient Knife (creed) + Patient Edge (boon) pay the FAR-WINDOW
## fraction (0 at the pivot → 1 across the span): long stalks hit harder, quick near draws don't.
## Unseen Blade cashes its time-banked Shade battery (far draws bank more — same instinct);
## Killing Whisper pays a Bullseye. Additive; base kit returns 0.0 — the true small variation.
func _coil_release_bonus(s: CombatState, seat: Seat, coil_ticks: int, bullseye: bool) -> float:
	var b := 0.0
	# PATIENT KNIFE (THE LONG RAMP): a release in the extension PAST the lip pays up to deep_mult,
	# scaling with how far into that extension you dared ride.
	if bool(_creed().get("patient", false)):
		var w := _edge_window(seat)
		var hi_t := _tt(s, w[1])
		var ext_t := (float(_tt(s, w[1])) - float(_tt(s, w[0]))) * cfg.patient_ramp_ext
		if coil_ticks > hi_t and ext_t > 0.0:
			b += cfg.patient_deep_mult * clampf(float(coil_ticks - hi_t) / ext_t, 0.0, 1.0)
	if _b("unseenBlade"):                                       # THE UNSEEN BLADE: the rest-banked Shade battery
		b += cfg.unseen_shade_per * float(seat.vars.get("shades", 0))
	if bullseye and _b("killingWhisper"):                       # KILLING WHISPER: Bullseye releases bite
		b += cfg.killing_whisper_mult
	if _b("refrain") and bool(seat.vars.get("refrain_repeat", false)):  # REFRAIN: the held-window repeat pays more
		seat.vars["refrain_repeat"] = false
		b += cfg.refrain_bonus
	return b

## A sharp Perfect/Bull release feeds the module gauges: SHADOW DANCE fills toward the DANCE
## (bullet-time), THE MARK brands the boss on a Bullseye for Eviscerate to cash.
func _fermata_perfect(s: CombatState, seat: Seat, bullseye: bool, was_max: bool, fever: bool) -> void:
	if _m("shadowdance") and _flow(seat) >= cfg.shadowdance_flow_min and not bool(seat.vars.get("dance_armed", false)):
		var dm := int(seat.vars.get("dance_meter", 0)) + 1
		if dm >= cfg.shadowdance_fill:
			seat.vars["dance_until"] = s.tick + _tt(s, cfg.shadowdance_sec)
			seat.vars["dance_armed"] = true               # the DANCE is live (duration-gated by _dance_active)
			CombatCore._bump_diag(s, seat, "dance")
			CombatCore.emit_event(s, {"t": "dance_start", "player": seat.is_player})
			dm = 0
		seat.vars["dance_meter"] = dm
	if _m("mark") and bullseye:
		seat.vars["mark_tier"] = mini(int(seat.vars.get("mark_tier", 0)) + 1, cfg.mark_tier_cap)

## Fired after a release resolves: Twin Echo (max-Flow echo), Phantom (Bullseye twin strike),
## Eclipse (a Bullseye instantly re-coils you, already sharp), and the coil rig WHENs.
func _fermata_after_release(s: CombatState, seat: Seat, grade: int, bullseye: bool,
		_perfect: bool, base: float, coil_ticks: int) -> void:
	if grade >= G_PERFECT and _b("twinEcho") and _flow(seat) >= max_flow():
		_deal(s, seat, roundf(base * cfg.twin_echo_mult), true, false, "strike")
	if bullseye and _b("phantom"):                            # PHANTOM (keystone): the crossing twin strike
		_deal(s, seat, roundf(base * cfg.phantom_twin_mult), true, false, "strike")
	if bullseye and _b("eclipse"):                            # ECLIPSE (keystone): re-coil already sharp,
		seat.vars["coil_instant"] = true                      # and the chained window lands NEAR (else the dance dies)
		seat.vars["window_shift"] = cfg.fermata_shift_min
		CombatCore.emit_event(s, {"t": "eclipse", "player": seat.is_player})
	# THE RAZOR (rig WHEN): a release in the last sliver before the lip — a hair from the snap.
	if float(coil_ticks) >= float(_tt(s, _fermata_lip_sec(seat)) - _tt(s, cfg.razor_sec)):
		_rig_fire(s, seat, "razor")

func _eviscerate(s: CombatState, seat: Seat) -> bool:
	if _transform() == "tremolo":
		return _tremolo_press(s, seat)          # TREMOLO: Eviscerate becomes a graded 3-press string
	var a: Dictionary = cfg.abilities["eviscerate"]
	var cp := int(seat.vars.get("cp", 0))
	# STACCATO FURY (boon): a crash-armed Eviscerate is FREE and hits harder.
	var free := _b("staccato") and bool(seat.vars.get("staccato_ready", false))
	var cost := 0.0 if free else float(a["energy"])
	if cp < 1 or seat.resource < cost:
		return false
	seat.resource -= cost
	var per := float(a["per_cp"]) + (8.0 if _b("eviPlus") else 0.0)
	var dmg := per * float(cp)
	if _b("overkill"):                                 # OVERKILL: banked over-cap points add on
		dmg += float(seat.vars.get("overkill_bank", 0)) * cfg.overkill_per
		seat.vars["overkill_bank"] = 0
	if free:
		dmg *= (1.0 + cfg.staccato_mult)
		seat.vars["staccato_ready"] = false
	# THE MARK (Fermata module): Eviscerate consumes the boss's brand for +per-tier, then clears it.
	if _m("mark"):
		var mt := int(seat.vars.get("mark_tier", 0))
		if mt > 0:
			dmg *= (1.0 + cfg.mark_open_bonus * float(mt))
			seat.vars["mark_tier"] = 0
			CombatCore.emit_event(s, {"t": "mark_cash", "player": seat.is_player, "tier": mt})
	# D0 S1 · GRAND PAUSE (a full 5/5 combo) + HEAVY INK (over-3 combo held in rhythm) amplify it.
	if _b("grandPause") and cp >= cfg.cp_max:
		dmg *= (1.0 + cfg.grand_pause_mult)
	if _b("heavyInk"):
		dmg *= (1.0 + cfg.heavy_ink_per * float(seat.vars.get("heavy_ink", 0)))
		seat.vars["heavy_ink"] = 0
	# D0 S3 · DUOS — Blood Coda (Wound×Finish): a full-combo Evis cashing 4+ bleeds pays both ×mult;
	# Grand Finale (Edge×Finish): a full-combo finisher with a crit build hot is a guaranteed crit.
	var fin_crit := false
	if _b("bloodCoda") and cp >= cfg.cp_max and _m("hemorrhage") \
			and (seat.vars.get("wounds", []) as Array).size() >= cfg.deepcash_min_bleeds:
		dmg *= cfg.blood_coda_mult
		seat.vars["bcoda_armed"] = true              # the wound cash below pays the duo bonus too
	if _b("grandFinale") and cp >= cfg.cp_max and _has_crit_source():
		fin_crit = true
		dmg *= (1.0 + cfg.grand_finale_bonus)
	_deal(s, seat, dmg, true, fin_crit, "finisher")
	seat.vars["cp"] = 0
	if cp >= cfg.cp_max:
		_rig_fire(s, seat, "finale")       # COMBO RIG (§5): a full 5-combo Eviscerate
	_cash_wounds(s, seat)                 # THE WOUND: Hemorrhage cashes the pot (+ Deep Cash / Exsanguinate)
	if _b("theCoda") and cp >= cfg.cp_max and _in_opening(s, seat):   # THE CODA (keystone): a free echoed finisher
		_deal(s, seat, dmg, true, false, "finisher")
		CombatCore.emit_event(s, {"t": "coda_echo", "player": seat.is_player})
	if bool(seat.vars.get("res_finish", false)) and cp >= cfg.cp_max:   # FINISH RESONANCE: the phrase-mark read cue (view)
		CombatCore.emit_event(s, {"t": "phrase_mark", "player": seat.is_player})
	_dump_landed(s, seat, "finisher")     # THE OPENING: read-reward if it hit the window
	CombatCore.emit_event(s, {"t": "finisher", "id": "eviscerate", "cp": cp})
	return true

## D0 S4 · TREMOLO transform — Eviscerate is a STRING: up to tremolo_max_presses, each spending
## cp_per combo, each graded on its own beat. All Perfect+ -> the final hit +tremolo_final_bonus.
## The string is ONE finisher for boon math (Grand Pause / Heavy Ink snapshot the FIRST press).
## Ends on the 3rd press, an empty hand (< cp_per combo), or a phrase timeout.
func _tremolo_press(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["eviscerate"]
	var cp := int(seat.vars.get("cp", 0))
	if cp < cfg.tremolo_cp_per:
		return false                                # empty hand — nothing to press
	var live := int(seat.vars.get("trem_presses", 0)) > 0 \
		and int(seat.vars.get("trem_presses", 0)) < cfg.tremolo_max_presses \
		and s.tick <= int(seat.vars.get("trem_until", -1))
	var first := not live
	if first:
		seat.vars["trem_presses"] = 0
		seat.vars["trem_all_perf"] = true
		seat.vars["trem_all_bull"] = true
	var cost := float(a["energy"]) if first else 0.0
	if seat.resource < cost:
		return false
	seat.resource -= cost
	# grade this press on the beat (Rolled Chord pads the ENTRY side — the widener law)
	var since := s.tick - int(seat.vars.get("last_strike_tick", -100000))
	var lo := _tt(s, _perfect_lo_sec(seat))
	var hi := _tt(s, _perfect_hi_sec(seat))
	if _b("rolledChord"):
		lo -= int(round(float(hi - lo) * cfg.rolled_chord_pad))
	var grade := _strike_grade(since, lo, hi)
	if grade < G_PERFECT:
		seat.vars["trem_all_perf"] = false
	if grade < G_BULL:
		seat.vars["trem_all_bull"] = false
	var per := float(a["per_cp"]) + (8.0 if _b("eviPlus") else 0.0)
	var base := per * float(cfg.tremolo_cp_per)
	var gmul := 0.6
	if grade == G_BULL:
		gmul = cfg.bull_mult
	elif grade == G_PERFECT:
		gmul = 1.6
	elif grade == G_GOOD:
		gmul = cfg.good_mult
	base *= gmul
	# the FIRST press snapshots the finisher boon math (Grand Pause / Heavy Ink) for the whole string
	if first:
		var fm := 1.0
		if _b("grandPause") and cp >= cfg.cp_max:
			fm *= (1.0 + cfg.grand_pause_mult)
		if _b("heavyInk"):
			fm *= (1.0 + cfg.heavy_ink_per * float(seat.vars.get("heavy_ink", 0)))
			seat.vars["heavy_ink"] = 0
		seat.vars["trem_first_mult"] = fm
	base *= float(seat.vars.get("trem_first_mult", 1.0))
	_gain_cp(seat, -cfg.tremolo_cp_per)             # spend the combo
	seat.vars["trem_presses"] = int(seat.vars.get("trem_presses", 0)) + 1
	seat.vars["trem_until"] = s.tick + _tt(s, cfg.tremolo_phrase_sec)
	seat.vars["last_strike_tick"] = s.tick          # each press sets the next press's beat
	var is_final := int(seat.vars["trem_presses"]) >= cfg.tremolo_max_presses
	if is_final and bool(seat.vars.get("trem_all_perf", true)):
		base *= (1.0 + cfg.tremolo_final_bonus)      # all Perfect+ -> the final hit pays more
		if _b("triplet") and bool(seat.vars.get("trem_all_bull", true)):
			base *= (1.0 + cfg.triplet_bonus)        # TRIPLET door: an all-Bullseye string
	_deal(s, seat, roundf(base), true, false, "finisher")
	_dump_landed(s, seat, "finisher")               # THE OPENING: the press punishes the window
	CombatCore.emit_event(s, {"t": "tremolo", "press": int(seat.vars["trem_presses"]),
		"final": is_final, "player": seat.is_player})
	return true

func _kick(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["kick"]
	if s.tick < int(seat.cooldowns.get("kick", 0)) or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	seat.cooldowns["kick"] = s.tick + _tt(s, maxf(0.5, float(a["cd"]) - (cfg.rude_cd_cut if _b("rudeKick") else 0.0)))   # RUDE INTERRUPTION
	if s.telegraph != null and s.telegraph.ability.response == AbilityRes.Response.INTERRUPTIBLE:
		CombatCore.stagger_boss(s)                      # cancels the cast; emits "staggered"/DENIED
	else:
		CombatCore.emit_event(s, {"t": "kick_whiff", "player": seat.is_player})
	# GEAR-1 (ARMORY strong): Powder Vial — the boot carries the toxin
	# (Venom: 3 stacks on the lit lane; Tempo: +2 Flow).
	if GearFx.has(seat, &"powder_vial"):
		if aspect == "venomancer":
			_apply_venom(seat, WHEEL_KEYS[_wheel(seat)], 3)
		else:
			_gain_flow(seat)
			_gain_flow(seat)
		GearFx.pop(s, seat, &"powder_vial")
	return true

func _envenom(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["envenom"]
	var cp := int(seat.vars.get("cp", 0))
	if cp < 1 or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	# FIXATE: over-stack the lit lane WITHOUT advancing the wheel (the "double-down" tool).
	_apply_venom(seat, WHEEL_KEYS[_wheel(seat)], cp)
	seat.vars["cp"] = 0
	if _b("tfTrigSpender") and cp >= cfg.cp_max:
		_tf_trigger(s, seat, "spender")    # Phase B: a full-point finisher = proc moment
	CombatCore.emit_event(s, {"t": "finisher", "id": "envenom", "cp": cp})
	return true

func _flurry(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["flurry"]
	if seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	for _i in int(a["hits"]):
		_deal(s, seat, float(a["dmg"]), true, false, "flurry")
	_gain_cp(seat, int(a["cp"]))
	_dump_landed(s, seat, "flurry")       # THE OPENING (all three hits shared the window)
	return true

## GRACE NOTE (spell): an ornamental off-beat jab. It does NOT set last_strike_tick — your
## rhythm clock is untouched — and grants no combo: pure filler damage woven between beats,
## for when your energy margin allows (shines with Syncopation's free Strikes at max Flow).
func _grace_note(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["gracenote"]
	if s.tick < int(seat.cooldowns.get("gracenote", 0)) or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	seat.cooldowns["gracenote"] = s.tick + _tt(s, float(a["cd"]))
	_deal(s, seat, float(a["dmg"]), true, false, "gracenote")
	CombatCore.emit_event(s, {"t": "gracenote", "player": seat.is_player})
	return true

## CODA (spell): prime the next Strike to land ALL-GREEN — one guaranteed Perfect. The
## get-back-on-the-horse button, and legal counterplay to a Held-Breath window lock.
func _coda(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["coda"]
	if s.tick < int(seat.cooldowns.get("coda", 0)) or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	seat.cooldowns["coda"] = s.tick + _tt(s, float(a["cd"]))
	seat.vars["coda_ready"] = true
	CombatCore.emit_event(s, {"t": "coda", "player": seat.is_player})
	return true

## D0 S6 · THE SET PIECE (signature CD) — press to MARK the next setpiece_phrase strikes as a phrase;
## the tally lives in _strike, and a clean all-Perfect+ phrase cashes _setpiece_cash.
func _setpiece(s: CombatState, seat: Seat) -> bool:
	if not _tempo_family() or not cfg.setpiece_enabled:
		return false
	var a: Dictionary = cfg.abilities["setpiece"]
	if s.tick < int(seat.cooldowns.get("setpiece", 0)) or bool(seat.vars.get("sp_armed", false)):
		return false
	seat.cooldowns["setpiece"] = s.tick + _tt(s, float(a["cd"]))
	seat.vars["sp_armed"] = true
	seat.vars["sp_left"] = cfg.setpiece_phrase
	seat.vars["sp_hits"] = 0
	CombatCore.emit_event(s, {"t": "setpiece_arm", "player": seat.is_player})
	return true

## The flourish: build-scaled — flow-scaled damage + a pulse on every live bleed (Wound) + a combo
## refund (Finish) + a Flow-lock (hold the tempo through the payoff). Auto-fits whatever the build is.
func _setpiece_cash(s: CombatState, seat: Seat) -> void:
	_deal(s, seat, cfg.setpiece_flourish, true, false, "finisher")
	for w in (seat.vars.get("wounds", []) as Array):
		_deal(s, seat, float(w["per"]), false, false, "bleed")
	_gain_cp(seat, cfg.setpiece_refund_cp)
	seat.vars["sp_flowlock_until"] = s.tick + _tt(s, cfg.setpiece_flowlock_sec)
	CombatCore._bump_diag(s, seat, "setpiece_cash")
	CombatCore.emit_event(s, {"t": "setpiece_cash", "player": seat.is_player})

func _coup(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["coupdegrace"]
	if s.tick < int(seat.cooldowns.get("coupdegrace", 0)):
		return false
	if _flow(seat) < (cfg.cadenza_min_flow if _transform() == "cadenza" else max_flow()) or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	seat.cooldowns["coupdegrace"] = s.tick + _tt(s, float(a["cd"]))
	var flow_spent := _flow(seat)
	# Damage rides the Flow you spend (via _deal's flow_mult) — then Coup CONSUMES it.
	var coup_raw := float(a["dmg"]) * (1.4 if _b("crescendo") else 1.0)
	if _transform() == "cadenza":                       # CADENZA: damage scales with the Flow spent (full = today's)
		coup_raw *= float(flow_spent) / float(max_flow())
		if _b("bravura") and flow_spent >= max_flow() and _in_opening(s, seat):
			coup_raw *= (1.0 + cfg.bravura_bonus)        # BRAVURA door
	var coup_dmg := _deal(s, seat, coup_raw, true, false, "coup")
	if _transform() == "rondo":                         # RONDO: arm the RETURN — the crash valley becomes act two
		seat.vars["rondo_hit"] = coup_dmg
		seat.vars["rondo_until"] = s.tick + _tt(s, cfg.rondo_beats * cfg.perfect_end)
		seat.vars["rondo_paid"] = 0.0
	var seed := cfg.coup_flow_seed + (cfg.da_capo_seed if _b("daCapo") else 0)   # DA CAPO (Rondo door): a higher seed
	if _transform() == "cadenza" and _b("dalSegno") and flow_spent >= cfg.dal_segno_flow:
		seed += cfg.dal_segno_seed                       # DAL SEGNO door: a deep Cadenza seeds +1
	seat.vars["flow"] = clampi(seed, 0, max_flow())
	seat.vars["flow_decay_acc"] = 0
	_gain_cp(seat, 3)                                    # refeeds combo → chain into Eviscerate
	_dump_landed(s, seat, "coup")                       # THE OPENING (fires after the Flow reset)
	_rig_fire(s, seat, "coup")                          # COMBO RIG (§5): empower rides the NEXT dump
	CombatCore.emit_event(s, {"t": "coup", "player": seat.is_player})
	if GearFx.has(seat, &"encore_bell"):                 # GEAR-2: the bell rings after the finisher
		seat.vars["encore_left"] = 3
		GearFx.pop(s, seat, &"encore_bell")
	return true

func _rupture(s: CombatState, seat: Seat) -> bool:
	var a: Dictionary = cfg.abilities["rupture"]
	if s.tick < int(seat.cooldowns.get("rupture", 0)):
		return false
	var total := _venom_total(seat)
	if total < 1 or seat.resource < float(a["energy"]):
		return false
	seat.resource -= float(a["energy"])
	seat.cooldowns["rupture"] = s.tick + _tt(s, float(a["cd"]))
	if GearFx.has(seat, &"encore_bell"):                 # GEAR-2: the bell rings after the finisher
		seat.vars["encore_left"] = 3
		GearFx.pop(s, seat, &"encore_bell")
	var per := float(a["per"]) * (1.4 if _b("rupturing") else 1.0)
	var v := _venom(seat)
	# Lingering Venom (boon): a SIP — a smaller detonation that keeps HALF the cocktail +
	# Synergy warm, so the engine never craters (sustain). Default = SLAM (full, zeroes it).
	var sip := _b("lingerVenom")
	_deal(s, seat, float(total) * per * float(v["syn_ramp"]) * (0.62 if sip else 1.0), true, false, "rupture")
	if sip:
		v["V"] = int(v["V"]) / 2; v["F"] = int(v["F"]) / 2; v["C"] = int(v["C"]) / 2
		v["fes_ticks"] = 0                                 # keep stacks + syn_ramp/syn_active warm
	else:
		v["V"] = 0; v["F"] = 0; v["C"] = 0
		v["fes_ticks"] = 0; v["syn_ramp"] = 1.0; v["syn_active"] = false
	_dump_landed(s, seat, "rupture")      # THE OPENING: detonate in the window for the spike
	CombatCore.emit_event(s, {"t": "rupture", "total": total, "sip": sip})
	return true

# ---------------------------------------------------------------- slot-verb Rhythm mods
# Phase B (build-your-Rhythm): the innate proc moment is every PERFECT Strike; TRIGGER
# pieces add moments, PAYLOAD pieces fire on every proc, PROPERTY pieces reshape the
# verb. NO LOCKOUTS. All _b()-gated — boonless sims stay byte-identical.

func _has_payloads() -> bool:
	return _b("tfPayLash") or _b("tfPayEnergy") or _b("tfPayLeech")

## A drafted trigger fired: built-in energy sip + one proc moment.
func _tf_trigger(s: CombatState, seat: Seat, source: String) -> void:
	_gain_energy(seat, cfg.mod_trig_energy)
	_rhythm_proc(s, seat, source)

## One proc moment: fire every drafted payload once (payLash is flat — not Flow-scaled).
func _rhythm_proc(s: CombatState, seat: Seat, source: String) -> void:
	if not _has_payloads():
		return
	seat.vars["verb_procs"] = int(seat.vars.get("verb_procs", 0)) + 1   # probe diagnostic
	if _b("tfPayLash"):
		_deal(s, seat, cfg.mod_lash, false, false)
	if _b("tfPayEnergy"):
		_gain_energy(seat, cfg.mod_energy)
	if _b("tfPayLeech"):
		# meter the effective slice as self-healing (HP behavior unchanged)
		var leech_eff := maxf(0.0, minf(seat.hp_max - seat.hp, cfg.mod_leech))
		seat.hp = clampf(seat.hp + cfg.mod_leech, 0.0, seat.hp_max)
		CombatCore.meter_heal(s, seat, &"red_harvest", leech_eff, cfg.mod_leech - leech_eff)
	CombatCore.emit_event(s, {"t": "verb_proc", "player": seat.is_player, "src": source})

# --------------------------------------------------------------------------
# Observation (policy + HUD). All view/AI fields — never part of the checksum.
# --------------------------------------------------------------------------

func observe(s: CombatState, seat: Seat) -> Dictionary:
	var last := int(seat.vars.get("last_strike_tick", -100000))
	var v: Dictionary = seat.vars.get("venom", {})
	# FERMATA · THE DRAW: the bar's clock is PRESS-relative — the needle only runs while
	# coiling (parked at 0 when idle), and the "too early" region is the un-sharp coil floor
	# (a release there unravels). Tempo/venom keep the strike-relative clock + swing_min.
	var since_obs := s.tick - last
	var early_obs := _tt(s, _swing_min_sec(seat))
	if _fermata():
		since_obs = (s.tick - int(seat.vars.get("coil_press_tick", s.tick))) \
			if bool(seat.vars.get("coiling", false)) else 0
		early_obs = _tt(s, _coil_min(seat))
	var out := {
		"tick": s.tick,
		"aspect": aspect,
		"energy": seat.resource,
		"energy_max": cfg.energy_max,
		"cp": int(seat.vars.get("cp", 0)),
		"cp_max": cfg.cp_max,
		"flow": _flow(seat),
		"flow_max": max_flow(),
		"flow_mult": _flow_mult(seat),
		"tier": flow_tier(seat),
		"since_strike": since_obs,
		# ACCELERANDO: the window the kit will judge THIS press against — flow-adjusted, so
		# the RhythmBar visibly compresses and the policy re-aims as Flow climbs (Venom = base).
		"swing_min_ticks": early_obs,
		"perfect_lo": _tt(s, _perfect_lo_sec(seat)),
		"perfect_hi": _tt(s, _perfect_hi_sec(seat)),
		# FIXED ruler so the RhythmBar shows the accelerando (tempo) / the roaming window
		# (fermata — wide enough for the whole roam band + a late reach, and it never rescales).
		"rhythm_scale": _tt(s, cfg.fermata_ruler_sec if _fermata() else (cfg.perfect_end + 0.15)),
		# GRADED WINDOW (§2c): the sub-band fractions (of the half-window from centre) so the
		# RhythmBar can draw Bullseye-core / Perfect / Good-flank zones, not one flat green band.
		"grade_bull_frac": cfg.grade_bull_frac,
		"grade_perfect_frac": cfg.grade_perfect_frac,
		"strike_cost": float(cfg.abilities["strike"]["energy"]),
		"boss_frac": (s.boss.hp / s.boss.hp_max) if s.boss.hp_max > 0.0 else 0.0,
		"def_zone": cfg.dodge_zone,
		"def_cd": cfg.dodge_cd,
		"kick_ready": s.tick >= int(seat.cooldowns.get("kick", 0)),
		"coup_ready": _tempo_family() and _flow(seat) >= (cfg.cadenza_min_flow if _transform() == "cadenza" else max_flow()) \
			and s.tick >= int(seat.cooldowns.get("coupdegrace", 0)),
		"setpiece_ready": _tempo_family() and cfg.setpiece_enabled \
			and s.tick >= int(seat.cooldowns.get("setpiece", 0)) and not bool(seat.vars.get("sp_armed", false)),
		"setpiece_armed": bool(seat.vars.get("sp_armed", false)),
		"setpiece_left": int(seat.vars.get("sp_left", 0)),
		"rupture_ready": aspect == "venomancer" and _venom_total(seat) >= 1 \
			and s.tick >= int(seat.cooldowns.get("rupture", 0)),
		"wheel": _wheel(seat),   # Venom poison wheel: 0=V 1=F 2=C, the lit (on-deck) lane
		"venom": {"V": int(v.get("V", 0)), "F": int(v.get("F", 0)), "C": int(v.get("C", 0)),
			"syn_ramp": float(v.get("syn_ramp", 1.0)), "syn_active": bool(v.get("syn_active", false))},
		"venom_total": _venom_total(seat),
	}
	# THE OPENING — the vulnerability window (absolute ticks; -1 once it has expired /
	# none scheduled). The policy times its dumps to open_peak; the HUD draws the bar.
	out["open_on"] = cfg.open_enabled   # off → the policy uses the classic dump logic
	var o_to := int(seat.vars.get("open_to", -1))
	if cfg.open_enabled and o_to >= s.tick:
		var o_from := int(seat.vars.get("open_from", 0))
		out["open_from"] = o_from
		out["open_peak"] = int(seat.vars.get("open_peak", o_from))
		out["open_to"] = o_to
		out["open_core_ticks"] = _tt(s, cfg.open_core_sec)
		out["open_size"] = int(seat.vars.get("open_size", 0))
		out["open_active"] = s.tick >= o_from
		out["open_bonus_now"] = _opening_bonus(s, seat)   # HUD: live grade of a dump RIGHT NOW
	else:
		out["open_from"] = -1
		out["open_peak"] = -1
		out["open_to"] = -1
		out["open_active"] = false
		out["open_bonus_now"] = 0.0

	# CREED + MODULES (Tempo rework) — for the HUD combo board / verdict pops / policy
	out["creed"] = creed_id
	if _transform() != "":                                       # D0 S4 · TRANSFORM state (view + policy)
		out["transform"] = _transform()
		out["rondo_active"] = _transform() == "rondo" and s.tick <= int(seat.vars.get("rondo_until", -1))
		out["trem_presses"] = int(seat.vars.get("trem_presses", 0))
	if seat.vars.has("res_counts"):                              # D0 S2 · RESONANCE (view: the build-panel chip)
		out["resonance"] = seat.vars.get("res_counts", {})
		out["res_wound"] = bool(seat.vars.get("res_wound", false))
		out["res_edge"] = bool(seat.vars.get("res_edge", false))
		out["res_finish"] = bool(seat.vars.get("res_finish", false))
	out["creed_name"] = String(_creed().get("name", ""))
	out["flow_value"] = _creed_flow_value()
	out["window_locked"] = bool(seat.vars.get("window_locked", false))
	out["modules"] = modules.keys()
	out["edge"] = _m("edge")                                     # MODULE gauges for the HUD
	# D0 S1 · v4 gauges (view-only; HUD render deferred): the WOUND pot, the KEEN meter, the ghost window.
	if _tempo_family():
		var ws: Array = seat.vars.get("wounds", [])
		if not ws.is_empty() or _m("hemorrhage"):
			var wt := 0.0
			for w in ws:
				wt += float(w.get("per", 0))
			out["wound_count"] = ws.size()
			out["wound_total"] = wt
		if _m("strop"):
			out["keen"] = int(seat.vars.get("keen", 0))
			out["keen_max"] = cfg.keen_cap
		if _b("doubleTime"):
			out["ghost_active"] = s.tick < int(seat.vars.get("ghost_until", 0))
		if _b("quickstep"):
			out["quickstep"] = int(seat.vars.get("quickstep", 0))
	if _m("deathmark"):
		out["marks"] = int(seat.vars.get("marks", 0))
		out["marks_max"] = cfg.mark_cap

	if _b("tfPropTwinStep"):   # Twin Step charge pips (Phase B)
		out["guard_charges"] = int(seat.vars.get("dodge_spare", 1)) \
			+ (1 if s.tick >= seat.defense_ready_tick else 0)
		out["guard_charges_max"] = 2

	# FERMATA (§13) — the coil state for the HUD (charge ring / shadow dim) AND the policy
	# (when to press vs hold vs release). All view/AI — never checksummed.
	if _fermata():
		out["fermata"] = true
		var coiling := bool(seat.vars.get("coiling", false))
		out["coiling"] = coiling
		out["coil_sharp"] = bool(seat.vars.get("sharp", false))
		out["coil_min_ticks"] = _tt(s, _coil_min(seat))
		out["coil_ticks"] = (s.tick - int(seat.vars.get("coil_press_tick", s.tick))) if coiling else 0
		out["strike_locked"] = s.tick < int(seat.vars.get("strike_lock_until", 0))
		# THE RAMP & THE SNAP (EDGE) — depth bands + the lip (the cliff) so the bar draws the ramp.
		out["fermata_ramp"] = true
		out["ramp_good_frac"] = cfg.fermata_good_frac
		out["ramp_perfect_frac"] = cfg.fermata_perfect_frac
		out["lip_ticks"] = _tt(s, _fermata_lip_sec(seat))
		out["dance_no_snap"] = _dance_active(s, seat)
		if _b("theBrink"):
			out["brink"] = int(seat.vars.get("brink", 0))
			out["brink_max"] = cfg.brink_cap
		if _b("unseenBlade"):
			out["shades"] = int(seat.vars.get("shades", 0))
			out["shades_max"] = cfg.unseen_shade_cap
		if _m("mark"):
			out["mark_tier"] = int(seat.vars.get("mark_tier", 0))
			out["mark_tier_max"] = cfg.mark_tier_cap
		if _m("shadowdance"):
			out["dance_meter"] = int(seat.vars.get("dance_meter", 0))
			out["dance_fill"] = cfg.shadowdance_fill
			out["dance_active"] = bool(seat.vars.get("dance_armed", false))
	return out

## STATS PAGE v2 — Twinfang's spec rows for the FULL REPORT: how sharp the tempo ran and
## how the Openings were used. Read-only from seat.diag; empty rows self-skip.
func recap_spec(_s: CombatState, seat: Seat) -> Array:
	var d: Dictionary = seat.diag
	var rows: Array = []
	var sharp := int(d.get("s_bull", 0)) + int(d.get("s_perfect", 0))
	var s_all := sharp + int(d.get("s_good", 0)) + int(d.get("s_miss", 0))
	if s_all > 0:
		rows.append({"label": "Strike windows", "value": "%d%% sharp" % int(round(100.0 * float(sharp) / float(s_all))),
			"hint": "%d bull/perfect · %d good · %d missed" % [sharp, int(d.get("s_good", 0)), int(d.get("s_miss", 0))]})
	var oh := int(d.get("open_hit", 0))
	var ow := int(d.get("open_whiff", 0))
	if oh + ow > 0:
		rows.append({"label": "Openings", "value": "%d landed" % oh, "hint": "%d dumped off-window" % ow})
	if int(d.get("perfect_strike", 0)) > 0:
		rows.append({"label": "Perfect strikes", "value": str(int(d.get("perfect_strike", 0))), "hint": ""})
	if int(d.get("snap", 0)) > 0:
		rows.append({"label": "Snaps", "value": str(int(d.get("snap", 0))), "hint": "nerve streaks lost at the lip"})
	return rows
