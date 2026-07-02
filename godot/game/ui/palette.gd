## Arcane Obsidian palette. One place for the whole game's colour language:
## near-black grounds, ember-gold accents, crimson danger, cool steel for Warden,
## warm ember for Juggernaut.
class_name Palette
extends RefCounted

static var BG0 := Color("07070c")          # deepest ground
static var BG1 := Color("12121b")          # panel/well
static var PANEL := Color("181824")
static var EDGE := Color("2c2436")

# Gilded Arcane Glass — glass fill gradient stops (top-lit) + frosted grain tint.
static var FILL_TOP := Color("1c1a28")     # glass fill top edge
static var FILL_BOT := Color("0d0c15")     # glass fill bottom edge
static var WELL_TOP := Color("10101a")     # recessed well variant top

static var GOLD := Color("e6b463")
static var GOLD_BRIGHT := Color("ffdc93")
static var GOLD_DIM := Color("6f5330")

static var CRIMSON := Color("d0413a")
static var CRIMSON_DEEP := Color("4e1917")

static var BLOOD := Color("9a2b28")         # HP orb
static var RAGE := Color("d97a2e")          # Rage orb
static var STEEL := Color("8fb8e0")         # Warden / Counter
static var MOMENTUM := Color("e0862f")      # Juggernaut

static var TEXT := Color("dacfb6")
static var TEXT_DIM := Color("867f6d")

static var LIGHT := Color("d8c47f")         # light swing
static var HEAVY := Color("df8f3c")         # heavy swing
static var CRUSH := Color("d0413a")         # crush swing

static var WIN := Color("83c98d")
static var LOSE := Color("d3625b")

# Voidcaller (caster DPS) accents
static var VOID := Color("8a5bd6")          # Focus / caster (violet-blue)
static var EXPOSE := Color("e0b23a")        # boss Exposed (amber)

# Twinfang (melee DPS) accents
static var ENERGY := Color("e8c84a")        # energy orb (yellow)
static var FLOW := Color("57c7e0")          # Flow — the rhythm multiplier (cyan)
static var POISON := Color("7fd44a")        # Venomancer poison / DoT (green)
static var CP := Color("e8933d")            # combo points (ember)
static var PERFECT := Color("7fe0a0")       # a Perfect Strike (mint)
static var KICK := Color("b48ee8")          # interrupt / Kick (violet)

# Bloomweaver (healer #2) accents
static var SAP := Color("a8d060")           # Sap orb (spring green)
static var VERDANCE := Color("5fd6a3")      # Verdance gauge (living jade)
static var THORN := Color("c98a5a")         # Thornveil / thorn damage (bark amber)

# draft card tints by boon type
static var SPELL := Color("6fb2c9")
static var UPGRADE := Color("d0a94f")
static var RELIC := Color("b072c9")

# Draft 2.0 rarity tiers (Haiku / Sonnet / Opus — offer frequency, never a power cap)
static var HAIKU := Color("8fa3ad")        # quiet steel — the everyday tier
static var SONNET := Color("e6b463")       # gilded — the strong tier
static var OPUS := Color("d98fff")         # radiant violet — the chase tier

static func rarity_color(r: String) -> Color:
	match r:
		"opus":
			return OPUS
		"sonnet":
			return SONNET
		_:
			return HAIKU

static func size_color(size: int) -> Color:
	match size:
		AbilityRes.Size.CRUSH:
			return CRUSH
		AbilityRes.Size.HEAVY:
			return HEAVY
		_:
			return LIGHT

static func type_color(t: String) -> Color:
	match t:
		"spell":
			return SPELL
		"relic":
			return RELIC
		_:
			return UPGRADE
