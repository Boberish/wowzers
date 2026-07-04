## All Bloomweaver (Healer #2) tuning constants + the spellbook. A Resource so the
## sim can sweep it. Identity: NO mana, NO direct heals — everything is planted
## ahead (SEEDS + wards). Spec resource (Verdance) builds only from EFFECTIVE proactive
## healing (ramped seed ticks into real damage + wards that absorb).
##
## SEEDFALL rework: Growth STACKS seeds onto an ally's bed (soft cap 3 / grove 4,
## over-cap to 5 by spending Verdance). Each bed carries ONE shared ramp — a fresh or
## freshly-stacked bed ticks at a fraction of full and climbs over ramp_time; applying
## ANY new seed RESETS that ramp. Stack FAST, then let it cook. Bloom cashes the bed.
class_name BloomweaverConfig
extends Resource

@export var gcd: float = 1.0
@export var sap_max: float = 100.0
@export var sap_regen: float = 9.0         ## per second (× regen_mult × dt) — energy-style.
                                           ## RESOURCE-TAX pass: cut from 12. Growth 15 / Bark 25 /
                                           ## Overgrowth 40 now can't be chained forever — planting
                                           ## the field is a Sap budget, not a free reflex.

# --- Verdance (spec gauge, both aspects). Earned, never regenerated. ---
@export var verdance_max: float = 100.0
@export var verd_per_heal: float = 0.10    ## Verdance per point of EFFECTIVE healing
@export var verd_per_absorb: float = 0.15  ## Verdance per point a ward actually absorbs
@export var verd_min_spend: float = 20.0   ## signature won't fire below this

# --- The SEED BED: a stacking, ramping HoT (gid "growth", one dict/ally, `stacks`) ---
@export var seed_base: float = 8.5         ## heal per tick, PER STACK, at FULL ramp (≈ old Growth HPS)
@export var seed_every: float = 1.0        ## tick interval, seconds (smoother/legible ramp)
@export var seed_dur: float = 9.0          ## bed lifetime, seconds (Deep Roots → 12s)
@export var ramp_floor: float = 0.35       ## a fresh/reset bed ticks at this fraction of full
@export var ramp_grove_floor: float = 0.40 ## Wildgrove seeds pay off sooner
@export var ramp_time: float = 4.5         ## seconds from floor → full after the last seed
@export var ramp_reset_frac: float = 0.0   ## a new seed rewinds ramp progress to this frac (0 = FULL reset). Sim knob.
@export var soft_cap: int = 3              ## free stacks
@export var grove_soft_cap: int = 4
@export var hard_cap: int = 5              ## overcap ceiling
@export var overcap_verd: float = 15.0     ## Verdance spent per seed past the soft cap

# --- Bloom (the cash-out) + Lifesurge ---
@export var bloom_eff: float = 0.9         ## Bloom cashes remaining fires × ramped tick × this (lossy → decide)
@export var bloom_sap: float = 5.0
@export var clean_harvest_verd: float = 15.0  ## Clean Harvest boon: spend this to bloom losslessly
@export var clean_harvest_mult: float = 1.15
@export var lifesurge_eff: float = 1.25    ## Lifesurge mass-bloom multiplier

# --- Barkskin / Perfect Ward (ward sized by the seeds cooking under it) ---
@export var bark_base: float = 45.0        ## absorb at 0 seeds (seeds now inflate it)
@export var shield_per_seed: float = 0.15  ## Wildgrove/shared: +absorb per seed under the ward
@export var thorn_shield_per_seed: float = 0.24  ## Thornveil: seeds literally build the wall
@export var seed_shield_cap: float = 1.2   ## seed bonus caps at +120%
@export var bark_dur: float = 6.0
@export var perfect_sap: float = 15.0      ## Sap refunded when a ward is FULLY consumed
@export var perfect_verd: float = 10.0     ## bonus Verdance on a Perfect Ward
@export var strike_perfect_sap: float = 12.0  ## M7: a PERFECT dodge refunds Sap (Verdance stays healing-earned)

# --- Wildgrove (garden aspect) — FLOURISH now lights on TOTAL PARTY SEEDS (ripen deleted). ---
@export var flourish_seeds_lo: int = 6     ## total party seeds (Σ stacks) to light Flourish
@export var flourish_seeds_hi: int = 10    ## …and the LUSH field (upgraded bonus)
@export var flourish_bonus: float = 0.25   ## all your healing +25% while Flourish is lit
@export var flourish_bonus_hi: float = 0.40  ## …and MORE on a lush field
@export var wildbloom_heal: float = 1.0    ## Wildbloom heals each seeded ally Verdance × this × depth
@export var wildbloom_sap: float = 5.0     ## Sap back per seeded ally Wildbloom heals

# --- Thornveil (ward aspect) — SNAP-STREAK kept; reflect also scales with seeds. ---
@export var thorns_frac: float = 0.45      ## reflect at 0 charge (base)
@export var thorns_max: float = 0.90       ## reflect ceiling (streak + seeds clamp here)
@export var thorn_charge_max: int = 5      ## snaps to full streak
@export var thorn_per_seed: float = 0.08   ## reflect multiplier per seed under the ward
@export var perfect_burst: float = 26.0    ## bonus boss damage on a Perfect Ward (scales w/ charge)
@export var thornbomb_per_seed: float = 8.0  ## Thornbomb boon: a Bloom rakes the boss for stacks × this
@export var briar_conv: float = 0.8        ## Briarheart ward per ally = Verdance × this
@export var briar_dur: float = 8.0
@export var briar_sap: float = 4.0         ## Sap back per ward Briarheart plants

## The spellbook. No mana — costs are Sap; the signature spends Verdance.
## Growth STACKS; Bloom (its own rune, key 4) detonates a bed. Thornlash moved to 5.
@export var spells: Dictionary = {
	"growth":    {"name": "Growth",     "key": "1", "sap": 15.0, "cast": 0.0, "cd": 0.0,  "target": true},
	"bark":      {"name": "Barkskin",   "key": "2", "sap": 25.0, "cast": 0.0, "cd": 8.0,  "target": true},
	"overgrowth":{"name": "Overgrowth", "key": "3", "sap": 40.0, "cast": 2.0, "cd": 12.0, "target": false},
	"bloom":     {"name": "Bloom",      "key": "4", "sap": 5.0,  "cast": 0.0, "cd": 0.0,  "target": true},
	"lash":      {"name": "Thornlash",  "key": "5", "sap": 10.0, "cast": 0.0, "cd": 0.0,  "target": false, "dmg": 18.0},
	"saprot":    {"name": "Sap Rot",    "key": "q", "sap": 20.0, "cast": 0.0, "cd": 8.0,  "target": true,  "offgcd": true, "dispel": true},
	"lifesurge": {"name": "Lifesurge",  "key": "e", "sap": 0.0,  "cast": 0.0, "cd": 30.0, "target": false, "offgcd": true},
	"wildbloom": {"name": "Wildbloom",  "key": "7", "sap": 0.0,  "cast": 0.0, "cd": 0.0,  "target": false, "spec": "wildgrove"},
	"briarheart":{"name": "Briarheart", "key": "7", "sap": 0.0,  "cast": 0.0, "cd": 0.0,  "target": false, "spec": "thornveil"},
}

## Ability bar order (the signature is appended per aspect).
func order(aspect: String) -> Array:
	return ["growth", "bark", "overgrowth", "bloom", "lash", "saprot", "lifesurge",
		("wildbloom" if aspect == "wildgrove" else "briarheart")]

# Phase B slot-verb GARDEN mods (build-your-Garden; entries with `slot` in BloomweaverBoons).
# Innate proc = every cashed BLOOM (Lifesurge mass-blooms count individually).
@export var mod_thorn: float = 18.0          ## bwPayThorn dmg per proc
@export var mod_sap: float = 8.0             ## bwPaySap per proc
@export var mod_mend: float = 15.0           ## bwPayMend heal (proc target / lowest ally)
@export var mod_trig_sap: float = 8.0        ## built-in Sap on a drafted trigger fire
@export var mod_ramp_quick: float = 1.1      ## bwPropQuick: seeds cook this many seconds faster
@export var mod_garden_need: int = 3         ## bwPropDeepGarden: payloads ×2 at this many beds
