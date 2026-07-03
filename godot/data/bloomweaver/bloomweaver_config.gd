## All Bloomweaver (Healer #2) tuning constants + the spellbook. A Resource so the
## sim can sweep it. Identity: NO mana, NO direct heals — everything is planted
## ahead (HoTs + wards), and the spec resource (Verdance) builds only from
## EFFECTIVE proactive healing: HoT ticks into real damage and wards that absorb.
class_name BloomweaverConfig
extends Resource

@export var gcd: float = 1.0
@export var sap_max: float = 100.0
@export var sap_regen: float = 12.0        ## per second (× regen_mult × dt) — energy-style

# --- Verdance (spec gauge, both aspects). Earned, never regenerated. ---
@export var verdance_max: float = 100.0
@export var verd_per_heal: float = 0.10    ## Verdance per point of EFFECTIVE healing
@export var verd_per_absorb: float = 0.15  ## Verdance per point a ward actually absorbs
@export var verd_min_spend: float = 20.0   ## signature won't fire below this

# --- Growth / Bloom (the double-tap) ---
@export var growth_tick: float = 12.0      ## heal per HoT interval
@export var growth_every: float = 1.5      ## HoT interval, seconds
@export var growth_dur: float = 9.0        ## HoT duration, seconds (6 ticks)
@export var bloom_eff: float = 0.9         ## Bloom cashes remaining ticks × this (lossy → decide!)
@export var lifesurge_eff: float = 1.25    ## Lifesurge mass-bloom multiplier

# --- Barkskin / Perfect Ward ---
@export var bark_shield: float = 55.0
@export var bark_dur: float = 6.0
@export var perfect_sap: float = 15.0      ## Sap refunded when a ward is FULLY consumed
@export var perfect_verd: float = 10.0     ## bonus Verdance on a Perfect Ward
@export var strike_perfect_sap: float = 12.0  ## M7: a PERFECT dodge refunds Sap (Verdance stays healing-earned)

# --- Wildgrove (garden aspect) — RIPEN: a Growth matures over its life; harvest it in
#     the ripe window for a bloom bonus, and Flourish now lights on RIPE growths (not just
#     alive), so the grove's game is TENDING the field to peak and timing the harvest. ---
@export var flourish_need: int = 3         ## allies with a Growth to light Flourish (presence = the floor)
@export var flourish_bonus: float = 0.25   ## all your HoT ticks +25% while Flourish is lit
@export var flourish_bonus_ripe: float = 0.42  ## …and MORE when the field is RIPE (tending pays off)
@export var wildbloom_heal: float = 1.0    ## Wildbloom heals each Growth'd ally Verdance × this
@export var ripe_lo: float = 0.45          ## matured fraction where the ripe window opens
@export var ripe_hi: float = 0.88          ## …and closes (past = overripe, no bonus)
@export var ripe_bonus: float = 0.6        ## a bloom harvested IN the ripe window ×(1 + this)
@export var wildbloom_sap: float = 5.0     ## Bridge: Sap back per Growth'd ally Wildbloom heals

# --- Thornveil (ward aspect) — SNAP-STREAK: consecutive Perfect Wards ("snaps") ramp the
#     thorn reflect; a ward that WILTS (expires unconsumed) breaks the streak. ---
@export var thorns_frac: float = 0.45      ## reflect at 0 charge (base)
@export var thorns_max: float = 0.90       ## reflect at full charge (the streak ceiling)
@export var thorn_charge_max: int = 5      ## snaps to full streak
@export var perfect_burst: float = 26.0    ## bonus boss damage on a Perfect Ward (scales w/ charge)
@export var briar_conv: float = 0.8        ## Briarheart ward per ally = Verdance × this
@export var briar_dur: float = 8.0
@export var briar_sap: float = 4.0         ## Bridge: Sap back per ward Briarheart plants

## The spellbook. No mana — costs are Sap; the signature spends Verdance.
@export var spells: Dictionary = {
	"growth":    {"name": "Growth",     "key": "1", "sap": 15.0, "cast": 0.0, "cd": 0.0,  "target": true},
	"bark":      {"name": "Barkskin",   "key": "2", "sap": 25.0, "cast": 0.0, "cd": 8.0,  "target": true},
	"overgrowth":{"name": "Overgrowth", "key": "3", "sap": 40.0, "cast": 2.0, "cd": 12.0, "target": false},
	"lash":      {"name": "Thornlash",  "key": "4", "sap": 10.0, "cast": 0.0, "cd": 0.0,  "target": false, "dmg": 18.0},
	"saprot":    {"name": "Sap Rot",    "key": "q", "sap": 20.0, "cast": 0.0, "cd": 8.0,  "target": true,  "offgcd": true, "dispel": true},
	"lifesurge": {"name": "Lifesurge",  "key": "e", "sap": 0.0,  "cast": 0.0, "cd": 30.0, "target": false, "offgcd": true},
	"wildbloom": {"name": "Wildbloom",  "key": "7", "sap": 0.0,  "cast": 0.0, "cd": 0.0,  "target": false, "spec": "wildgrove"},
	"briarheart":{"name": "Briarheart", "key": "7", "sap": 0.0,  "cast": 0.0, "cd": 0.0,  "target": false, "spec": "thornveil"},
}

## Ability bar order (the signature is appended per aspect).
func order(aspect: String) -> Array:
	return ["growth", "bark", "overgrowth", "lash", "saprot", "lifesurge",
		("wildbloom" if aspect == "wildgrove" else "briarheart")]

# Phase B slot-verb GARDEN mods (build-your-Garden; entries with `slot` in BloomweaverBoons).
# Innate proc = every cashed BLOOM (Lifesurge mass-blooms count individually).
@export var mod_thorn: float = 18.0          ## bwPayThorn dmg per proc
@export var mod_sap: float = 8.0             ## bwPaySap per proc
@export var mod_mend: float = 15.0           ## bwPayMend heal (proc target / lowest ally)
@export var mod_trig_sap: float = 8.0        ## built-in Sap on a drafted trigger fire
@export var mod_tick_mult: float = 0.88      ## bwPropQuick Growth tick-interval multiplier
@export var mod_garden_need: int = 3         ## bwPropDeepGarden: payloads ×2 at this many Growths
