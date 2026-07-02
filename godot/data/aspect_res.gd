## A class Aspect (1 of 2 chosen at run start): grants a signature ability and
## biases the between-fights draft. Schema locked now; fleshed out in M1 (Bulwark
## = Warden / Juggernaut). Constants live in `constants` so sims can sweep them.
class_name AspectRes
extends Resource

@export var name: String = ""
@export var signature_ability: StringName = &""
@export var constants: Dictionary = {}
@export var draft_bias: Array[StringName] = []
