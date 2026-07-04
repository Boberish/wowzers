## All Twinfang (Melee DPS) tuning constants + the ability table, lifted verbatim
## from poc/twinfang.html. A Resource so balance sims can sweep it.
##
## The verb is "drive the rhythm": Strike is gated by a per-strike timing window
## (wait for the green), not a GCD. Perfect Strikes build Flow, and Flow multiplies
## ALL your damage — chaining Perfects is the skill ceiling. Getting hit by a swing
## wipes Flow, so dodging protects your damage as much as your health.
class_name TwinfangConfig
extends Resource

@export var hp_max: float = 310.0
@export var energy_max: float = 100.0
@export var energy_regen: float = 18.0      ## per second — RESOURCE-TAX pass: cut from 20 (gently).
                                            ## Strike costs 12 and the rhythm gates you to ~one per
                                            ## 0.6-0.95s, so at 20/s energy never emptied. At 17 a
                                            ## finisher-heavy stretch (Evisc 25 / Coup 30) taxes the
                                            ## bar — but NOT so hard it breaks Tempo's accelerando DPS
                                            ## engine (14 did: good-tier missed the enrage race).

@export var cp_max: int = 5                 ## combo points
@export var flow_max: int = 6
@export var flow_per: float = 0.08          ## +8% damage per Flow point
@export var flow_decay_every: float = 2.4   ## seconds without a Perfect → lose 1 Flow

# --- M7 strike strings: dodge-beat payoffs (PERFECT grants +1 Flow — no knob) ---
@export var strike_good_energy: float = 6.0
@export var strike_read_energy: float = 10.0

# --- the rhythm: seconds since your last Strike. These are the Flow-0 anchors.
@export var swing_min: float = 0.42         ## earliest you may Strike (before = ignored, no cost)
@export var perfect_start: float = 0.60     ## [perfect_start, perfect_end] = the green window (Perfect)
@export var perfect_end: float = 0.95

# --- Tempo ACCELERANDO: Flow IS tempo. As Flow climbs the whole cycle shifts EARLIER and
#     the green window tightens (Flow = BPM) — DPS rises from faster cadence AND from
#     flow_per's bigger hits. These are the MAX-Flow anchors; the kit lerps between the
#     Flow-0 values above and these by (flow / max_flow). Venom keeps Flow pinned at 0, so
#     its window is ALWAYS the base — a steady beat, no accelerando. Window width goes
#     0.35s → 0.22s (tighter but fair); a Flow crash drops you back to walking pace.
@export var swing_min_lo: float = 0.27
@export var perfect_start_lo: float = 0.40
@export var perfect_end_lo: float = 0.60
@export var coup_flow_seed: int = 2         ## Flow left after Coup CONSUMES it (ride vs spend) —
                                            ## a seed so the spike doesn't crater you to walking pace

# --- Venomancer POISON WHEEL: one lit lane (V→F→C). A Strike feeds the lit lane and
#     ADVANCES the wheel (riding tops all three → Toxic Synergy comes naturally); Envenom
#     FIXATES it (over-stacks the lit lane, no advance). Flow never touches Venom.
@export var wheel_perfect_apply: int = 3    ## a Perfect Strike stacks the lit poison this much
@export var wheel_strike_apply: int = 2     ## a non-Perfect Strike stacks the lit poison this much

# --- dodge (the defensive verb) ---
@export var dodge_active: float = 0.55      ## how long a dodge stays "active"
@export var dodge_zone: float = 0.42        ## the visible answer window (last stretch of the swing)
@export var dodge_cd: float = 2.4

# --- THE OPENING (offense-side verb) — a boss swing OVEREXTENDS it: around each
#     telegraphed swing's impact a VULNERABILITY window opens on the BOSS, and your
#     DUMPS (Eviscerate / Coup / Rupture / Flurry) landed in it hit harder. It's the
#     inverse of the dodge bar — you don't answer the swing, you PUNISH the recovery.
#     Graded: the core (sweet spot, just AFTER impact) pays full open_bonus, tapering to
#     open_min_bonus at the window edges, nothing outside. Basic Strikes keep their own
#     self-rhythm groove untouched — the Opening times your BURST, not your beat, so
#     Twinfang now has two timing layers. Kit-local + deterministic (no engine change).
@export var open_enabled: bool = true       ## master switch (sims A/B it off = classic Twinfang)
@export var open_pre_sec: float = 0.18      ## window opens this long BEFORE impact
@export var open_post_sec: float = 0.42     ## ...and stays open this long AFTER ("when/around/after they hit")
@export var open_peak_sec: float = 0.10     ## sweet-spot centre, this long AFTER impact
@export var open_core_sec: float = 0.10     ## +/- this around the peak = full bonus
@export var open_bonus: float = 0.90        ## peak dump damage bonus (x1.90) — a real spike
@export var open_min_bonus: float = 0.05    ## edge-of-window dump bonus (x1.05) — a tight peak is the skill
@export var open_flow: int = 1              ## Tempo: +Flow on a PEAK dump (reading the boss pays BPM)
@export var open_venom: int = 2             ## Venom: +poison to the lit lane on a PEAK dump

# --- Venomancer poison model ---
@export var ven_cap: int = 8                ## per-type poison cap (V/F/C)
@export var syn_cap: float = 1.8            ## Toxic Synergy ramp cap
@export var syn_rate: float = 0.14          ## Synergy growth per second while all three live
@export var venom_decay_every: float = 4.0  ## every this long, each poison type bleeds 1 stack
@export var venom_tick_every: float = 1.0   ## poison damage cadence

## The ability book. `effect` is inferred from the fields/id in TwinfangKit.
## strike is the rhythm builder; eviscerate/envenom are finishers (spend all combo);
## coupdegrace/rupture are the per-Aspect signatures; flurry is a draftable spell.
@export var abilities: Dictionary = {
	"strike":      {"name": "Strike",        "key": "1", "energy": 12.0, "dmg": 19.0, "cp": 1},
	"eviscerate":  {"name": "Eviscerate",    "key": "2", "energy": 25.0, "finisher": true, "per_cp": 23.0},
	"kick":        {"name": "Kick",          "key": "3", "energy": 10.0, "cd": 7.0, "interrupt": true},
	"envenom":     {"name": "Envenom",       "key": "4", "energy": 25.0, "finisher": true, "poison": true},
	"flurry":      {"name": "Flurry",        "key": "5", "energy": 28.0, "dmg": 13.0, "cp": 2, "hits": 3},
	"coupdegrace": {"name": "Coup de Grâce", "key": "4", "energy": 30.0, "cd": 5.0, "spec": "tempo", "dmg": 120.0},
	"rupture":     {"name": "Rupture",       "key": "4", "energy": 22.0, "cd": 3.5, "spec": "venomancer", "per": 9.0},
}

## The four-slot bar for an Aspect (signature appended last). Draft spells fill 5+.
func loadout(aspect: String) -> Array:
	if aspect == "tempo":
		return ["strike", "eviscerate", "kick", "coupdegrace"]
	return ["strike", "envenom", "kick", "rupture"]

# Phase B slot-verb RHYTHM mods (build-your-Rhythm; entries with `slot` in TwinfangBoons).
# Innate proc = every PERFECT Strike — perfects are frequent, so payloads are small.
@export var mod_lash: float = 6.0            ## tfPayLash dmg per proc
@export var mod_energy: float = 3.0          ## tfPayEnergy per proc
@export var mod_leech: float = 5.0           ## tfPayLeech heal per proc
@export var mod_trig_energy: float = 6.0     ## built-in energy on a drafted trigger fire
@export var mod_window_pad: float = 0.20     ## tfPropWindow: widen the Perfect window per side
@export var mod_step_recharge: float = 6.0   ## tfPropTwinStep spare-dodge recharge, seconds
