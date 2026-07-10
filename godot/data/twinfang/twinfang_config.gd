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

# --- TEMPO REWORK · MODULE tuning (illustrative — tuned after the systems land) ---
@export var edge_window_mult: float = 0.7   ## The Edge: Perfect window width ×this (tighter = riskier)
@export var edge_perfect_mult: float = 1.25 ## The Edge: a Perfect Strike deals ×this (the reward)
@export var mark_cap: int = 5               ## The Deathmark: max marks stamped on the boss
@export var mark_dmg: float = 16.0          ## The Deathmark: burst per mark when a dump detonates them

# --- TEMPO REWORK · GRADED WINDOW (§2c, Option B) — the Perfect window is subdivided.
#     Within the live [lo,hi] green, position is normalized 0(centre)…1(edge). The dead
#     centre is BULLSEYE (elite read), the core is PERFECT, the flanks are GOOD (it lands,
#     partial damage, NO Flow, no slip — treading water), outside = a MISS (base + slip).
@export var grade_bull_frac: float = 0.18   ## |p|<=this = Bullseye (centre 18% of the window)
@export var grade_perfect_frac: float = 0.55 ## |p|<=this = Perfect (centre core); beyond → Good
@export var bull_mult: float = 1.8          ## Bullseye Strike damage (vs Perfect's 1.6) — dead centre bites
@export var good_mult: float = 1.0          ## Good Strike damage — it LANDS at base, no Flow, no slip;
                                            ## its value is preserving Flow (not crashing), NOT bonus dmg,
                                            ## so treading water can't limp a sloppy blade past a DPS check

# --- TEMPO REWORK · new card tuning (Slice 1; illustrative — sim/feel-tune) ---
@export var serrated_bonus: float = 0.40    ## Serrated Fate: crits deal +this
@export var opportunist_crit: float = 0.25  ## Opportunist: crit chance on a Strike during a boss wind-up
@export var tightrope_mult: float = 0.15    ## Tightrope: +this damage while at max Flow
@export var shatterfall_per: float = 25.0   ## Shatterfall: damage per Flow point lost in a 4+ crash
@export var overkill_per: float = 6.0       ## Overkill: banked over-cap combo adds this to next Eviscerate
@export var overkill_cap: int = 3           ## Overkill: max banked over-cap points
@export var staccato_mult: float = 0.5      ## Staccato Fury: post-crash Eviscerate deals +this (and is free)
@export var staccato_flow_min: int = 3      ## …only arms when the crash was from >= this Flow
@export var execute_mult: float = 0.35      ## Finish It: Eviscerate +this below 35% boss HP
@export var rubato_shift: float = 0.05      ## Rubato: the window sits this many seconds earlier
@export var wide_pad: float = 0.15          ## Wide Tempo: widen the window this fraction each side
@export var fencer_pad: float = 0.25        ## Fencer's Line: the strike AFTER a Bullseye is this much wider
@export var da_capo_seed: int = 1           ## Da Capo: Coup's Flow seed +this
@export var rude_cd_cut: float = 2.0        ## Rude Interruption: Kick cooldown −this seconds
# --- FULL BUILD (2026-07-06): base-kit fixes + the crit build + Largo + Overdrive + support ---
@export var strike_perfect_refund: float = 4.0 ## F11: BASE energy a Perfect refunds (clean play self-fuels)
@export var strike_bull_refund: float = 6.0    ## F11/F15: a Bullseye refunds more (superset of Perfect)
@export var efficiency_refund: float = 6.0      ## Efficiency boon: energy ON TOP of the base refund
@export var bull_bonus_cp: int = 1              ## F15: a Bullseye grants this many EXTRA combo points
@export var widener_taper: bool = true          ## F19: window wideners fade as Flow climbs (help low, not high)
# crit build (A7 — the Whetted Edge): no base crits; Hone unlocks the standing Edge meter
@export var edge_max: int = 10                  ## Edge meter ceiling
@export var edge_perfect_gain: int = 1          ## Perfect hones +this
@export var edge_bull_gain: int = 2             ## Bullseye hones +this
@export var edge_slip_dull: int = 3             ## a slip dulls Edge by this
@export var hone_crit_per_pt: float = 0.045     ## crit chance per Edge point while Hone is up
@export var assassin_open_mult: float = 0.50    ## Assassin\u2019s Note: crits in the Opening deal +this
@export var throughline_per: float = 0.02       ## Through-Line: +dmg per consecutive Perfect
@export var throughline_cap: int = 5            ## Through-Line: stack cap
# Largo creed — slow & sharp
@export var largo_beat_mult: float = 1.35       ## beats land this much farther apart
@export var largo_window_mult: float = 0.7      ## the green runs this much tighter
@export var largo_hit_mult: float = 1.25        ## Perfects/Bullseyes hit this much harder
# Understudy (guard) + Overdrive (transformer) + Battle Hymn (support)
@export var understudy_charges: int = 1         ## groove-saves per fight
@export var understudy_recharge: float = 25.0   ## seconds to recharge a save
@export var overdrive_fill: int = 6             ## max-Flow Perfects to fill the Overdrive meter
@export var overdrive_fever_sec: float = 3.0    ## FEVER duration
@export var overdrive_seed: int = 2             ## Flow left after a FEVER crash
@export var battle_hymn_flow_min: int = 4       ## the raid aura is live at/above this Flow
@export var press_advantage_mult: float = 0.30  ## Press the Advantage: a basic Strike inside the Opening deals +this
@export var cold_open_mult: float = 0.25        ## Cold Open: a basic Strike while Flow <= cold_open_flow_max deals +this
@export var cold_open_flow_max: int = 2         ## Cold Open: the low-Flow ceiling it pays under
# --- FERMATA (§13): the hold-release aspect — Strike COILS (press→sharpen→release). Every
#     knob here is fermata-only (aspect-gated in TwinfangKit); tempo/venom never read them, so
#     the existing checksums are untouched. Ladders in TEMPO-PLAN §13; base = the Haiku rung. ---
@export var coil_min_sec: float = 0.35          ## min hold before the blade SHARPENS; release early = UNRAVEL
@export var coil_unravel_stagger: float = 0.35  ## strike-lock after an unravel (no strike, NO Flow loss)
# THE ROAMING WINDOW — Fermata's core read (from the feel-tester): the green RELOCATES after
# every release, so there is no autopilot rhythm — you track where the next window landed and
# ride the sweep to it. The shift multiplies the accelerando'd window CENTRE (width untouched),
# clamped reachable: the mouth never sits before a fresh coil could sharpen, and the far edge
# stays on the fixed fermata ruler. Rolled from s.rng per resolve (fermata-only draw).
@export var fermata_shift_min: float = 0.75     ## nearest the window may land (× base centre)
@export var fermata_shift_max: float = 1.85     ## farthest the window may land (× base centre)
@export var fermata_ruler_sec: float = 1.80     ## the FIXED HUD ruler — roam space + a late reach
# THE DRAW (pacing pass, Bill 2026-07-07): the sweep starts on the PRESS, not on the last strike
# — idle has NO clock (Flow decay is the only pacing nudge), so dumps/kicks get cast in calm.
# Near windows are EARNED: at low Flow the window keeps its distance (the slack), fading to 0 at
# max Flow — the twitchy short draws only exist inside a hot streak.
@export var fermata_near_slack: float = 0.30    ## extra window keep-away at Flow 0 (→ 0 at max Flow)
# THE RAMP & THE SNAP (EDGE verb, Bill 2026-07-07 "edge is way better"): inside the window damage
# RAMPS entry→lip by depth (GOOD 45% · PERFECT 37% · BULLSEYE last 18%, hard against the cliff).
# Crossing the lip auto-SNAPS the note (miss + Flow crash, no dead-note state). Wideners add ENTRY
# runway only — the lip never moves. Depth d = (since − lo) / (hi − lo); bands split at good/perfect.
@export var fermata_good_frac: float = 0.45     ## GOOD covers [0, this) of the depth ramp
@export var fermata_perfect_frac: float = 0.37  ## PERFECT covers [good, good+this); BULLSEYE = the rest to the lip
@export var snap_lock: float = 0.40             ## strike-lock after a SNAP (rode past the lip)
@export var razor_sec: float = 0.05             ## The Razor (rig WHEN): a release this close before the lip
# creeds
@export var patient_ramp_ext: float = 0.40      ## Patient Knife: the ramp continues this fraction PAST the lip…
@export var patient_deep_mult: float = 0.20     ## …paying up to +this at the extension's end (a deeper lip)
@export var patient_snap_stagger: float = 0.5   ## Patient Knife: a SNAP staggers this long (harsher cliff)
@export var patient_shift_min: float = 1.30     ## Patient Knife: the window never lands near — the knife waits
@export var fleeting_min_sec: float = 0.20      ## Fleeting Shade: shorter min coil
@export var fleeting_flow_cap: int = 4          ## Fleeting Shade: Flow ceiling (the cost)
@export var fleeting_slip_amt: int = 2          ## Fleeting Shade: a Miss loses this (not a crash)
@export var fleeting_snap_amt: int = 2          ## Fleeting Shade: a SNAP bleeds this Flow instead of crashing
@export var tutti_off_mult: float = 0.85        ## Tutti: an off-window (un-sharp) dump lands at this fraction
# modules
@export var shadowdance_fill: int = 6           ## sharp Perf/Bull at Flow>=min to fill Shadow Dance
@export var shadowdance_sec: float = 3.0        ## THE DANCE duration (release bullet-time)
@export var shadowdance_flow_min: int = 4       ## the meter fills only at/above this Flow
@export var shadowdance_seed: int = 2           ## Flow left after the Dance crashes
@export var mark_open_bonus: float = 0.12       ## The Mark: Eviscerate +this per brand tier
@export var mark_tier_cap: int = 3              ## The Mark: max brand tier
# boons — THE ROLL (control over where the window lands)
@export var stretto_bias: float = 0.15          ## Stretto: windows roll this fraction toward the near edge
@export var refrain_bonus: float = 0.0          ## Refrain (S/O rune): the held-window repeat hits +this
# boons — THE RIDE / RELEASE
@export var cold_cut_cp: int = 1                ## Cold Cut: a GOOD-band (shallow-safe) release grants +this combo
@export var cold_cut_refund: float = 0.0        ## Cold Cut (S/O rune): the shallow release also refunds this energy
@export var brink_per: float = 0.03             ## The Brink: +this damage per nerve stack (all outgoing)
@export var brink_cap: int = 5                  ## The Brink: nerve-meter ceiling
@export var killing_whisper_mult: float = 0.15  ## Killing Whisper: Bullseye releases +this
@export var restless_dark_regen: float = 0.30   ## Restless Dark: +this fraction of energy regen while drawing
@export var quiet_fuse_cut: float = 0.08        ## Quiet Fuse: min coil reduced by this
# boons — THE DRAW (defense)
@export var vanish_reduce: float = 0.50         ## Vanish: the first boss hit per draw takes -this
@export var vanish_keep_sharp: bool = false     ## Vanish (Opus rung): the eaten hit doesn't break the draw
@export var veil_warband_reduce: float = 0.04   ## Veil Over the Warband: allies take -this while you're drawing
# boons — THE REST
@export var composure_sec: float = 2.0          ## Composure: Flow decay paused this long after a Perfect+ release
@export var first_note_pad: float = 0.20        ## First Note: after a 1.5s rest, the draw's ENTRY runway +this
# boons — FLOW & COMEBACK
@export var twin_echo_mult: float = 0.30        ## Twin Echo: a max-Flow release echoes a strike at this
@export var quiet_fuse_no_stagger: bool = false ## Quiet Fuse (Opus rung): unravel loses its stagger
# keystones (A8 — elite drops)
@export var unseen_shade_per: float = 0.06      ## Unseen Blade: +dmg per Shade on the next release
@export var unseen_shade_cap: int = 5           ## Unseen Blade: shade ceiling
@export var unseen_shade_every: float = 0.7     ## Unseen Blade: bank a Shade per this long RESTING (idle)
@export var phantom_twin_mult: float = 1.0      ## Phantom: a Bullseye release fires a twin strike at this
# On the Beat (a TEMPO-side card — dumps in the strike window gain the grade mult)
@export var on_the_beat_frac: float = 0.60      ## fraction of the live window grade bonus a dump gains
# DOUBLE TIME (signature): at max Flow, each further Perfect adds an "overdrive" stack.
@export var doubletime_dmg: float = 0.04    ## +this damage per overdrive stack (flow-scaled hits)
@export var doubletime_tighten: float = 0.06 ## per-stack SPEED PUSH weight (folds into the governor)
@export var doubletime_min_frac: float = 0.35 ## DEPRECATED (D0 S0): the per-source clamp is retired —
                                            ## the ONE window_min wall replaces it. Field kept so the
                                            ## Resource's saved data loads; no longer read by the kit.
@export var doubletime_cap: int = 12        ## overdrive stack ceiling (push backstop)

# --- THE SPEED GOVERNOR (D0 S0, TEMPO-PLAN §17.10 D · §17.11) — ONE wall every EXTRA speed
#     source folds into asymptotically, so stacks approach the ceiling but each card keeps a
#     visible delta and the engine's 30 Hz Bullseye band stays readable. The accelerando itself
#     is NOT folded here (its _lo anchors already ARE its asymptote, and folding it would move
#     the boonless numbers): the governor is the wall for the multiplicative speed ON TOP of the
#     accelerando (Double Time · Quickstep · later the EASE beat-speed BITE). Per-source clamps
#     (doubletime_min_frac) are deleted — one wall. Numbers are sim knobs.
@export var beat_rate_cap: float = 1.6      ## the governed beat may run at most this × the accelerando cadence
@export var window_min: float = 0.15        ## a governed window never narrows below this WIDTH (sec) —
                                            ## ≈4-5 ticks @30 Hz, keeps the 18% Bullseye band ≥ ~1 tick + read
@export var gov_k: float = 0.9              ## asymptote curvature: rate = 1 + (cap-1)·(1 − exp(−k·push))

# --- D0 S1 · QUICKSTEP (generic STRIKE boon) — each Perfect adds a SPEED PUSH (governor-clamped:
#     the wall keeps it readable) and self-bites (tighter window). Stacks reset on a slip. ---
@export var quickstep_speed: float = 0.08   ## each Perfect adds this push (routes through _speed_push)
@export var quickstep_cap: int = 8          ## push stack ceiling

# --- D0 S1 · DOUBLE TIME v2 (ghost notes) — v1 beat-doubling CUT at the governor wall. Sustained
#     max-Flow clean play opens an ~8s window where each Perfect+ ALSO lands a free GHOST half-
#     strike (no Flow risk, no window tighten, no push): twice the NOTES, never a faster beat. ---
@export var ghost_fill: int = 6             ## max-Flow Perfects to open the ghost window
@export var ghost_window_sec: float = 8.0   ## the ghost window stays open this long
@export var ghost_frac: float = 0.5         ## a ghost half-strike lands at this fraction of a Perfect

# --- D0 S1 · THE WOUND POT (v4 WOUND branch, TEMPO-PLAN §17) — short bleeds inscribed on the boss
#     frame, ticked in upkeep (fixed iteration order = determinism), press-cashed by Eviscerate
#     when Hemorrhage is held. Durations in SECONDS; a "beat" in the fiction ≈ wound_tick_every. ---
@export var wound_tick_every: float = 0.8   ## a live bleed ticks this often (≈ one beat)
@export var open_veins_dur: float = 1.6     ## OPEN VEINS creed: a Bullseye bleed lasts this (≈2 beats)
@export var open_veins_tick: float = 4.0    ## OPEN VEINS: damage per bleed tick (modest)
@export var lacerate_frac: float = 0.5      ## LACERATE boon: a Perfect inscribes a bleed at this fraction
@export var slow_bleed_dur: float = 0.8     ## SLOW BLEED boon: +this duration (sec) …
@export var slow_bleed_mult: float = 1.10   ## … and ticks +10%
@export var wound_dur_cap: float = 4.0      ## SLOW BLEED cap: a bleed never lasts beyond this (~5 beats)
@export var arterial_mult: float = 1.30     ## ARTERIAL NOTE boon: bleeds tick this much harder …
@export var arterial_shorten: float = 0.8   ## … but expire this much sooner (sec)
@export var hemorrhage_ext: float = 0.8     ## HEMORRHAGE module: every bleed ticks +this longer
@export var hemorrhage_cash_per: float = 0.10 ## HEMORRHAGE: Evis cash pays +this per bleed consumed
@export var deepcash_min_bleeds: int = 4    ## THE DEEP CASH (rig WHEN): consume this many bleeds in one Evis
@export var exsang_min_bleeds: int = 5      ## EXSANGUINATE keystone: min live bleeds to erupt
@export var exsang_beats: int = 3           ## EXSANGUINATE: the erupted burst spans this many ticks

# --- D0 S1 · THE EDGE branch (v4) — Whetstone creed (opt-in crit from run start) + The Strop
#     module (the KEEN meter: clean strikes whet the blade, the next crit spends it all). ---
@export var whetstone_crit: float = 0.12    ## WHETSTONE creed: a Bullseye crits at this chance from run start
@export var keen_cap: int = 5               ## THE STROP module: KEEN gauge ceiling
@export var keen_per: float = 0.08          ## THE STROP: the next crit consumes all KEEN for +this per stack

# --- D0 S1 · FINISH-lane boons ---
@export var heavy_ink_per: float = 0.10     ## HEAVY INK: each combo point above the floor adds +this to the next finisher
@export var heavy_ink_floor: int = 3        ## HEAVY INK: combo above this counts
@export var grand_pause_mult: float = 0.25  ## GRAND PAUSE: a full-combo (5/5) Eviscerate hits +this

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
	# TEMPO REWORK · draftable spells (new buttons; fill bar slots 5+)
	"gracenote":   {"name": "Grace Note",    "key": "6", "energy": 18.0, "dmg": 14.0, "cd": 2.0},
	"coda":        {"name": "Coda",          "key": "7", "energy": 25.0, "cd": 10.0},
}

## The four-slot bar for an Aspect (signature appended last). Draft spells fill 5+.
func loadout(aspect: String) -> Array:
	if aspect == "tempo" or aspect == "fermata":   # Fermata IS Tempo's kit — the strike just COILS
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
