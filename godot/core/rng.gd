## Deterministic seeded PRNG (mulberry32). This is the ONLY source of randomness
## allowed inside the combat engine. Same seed -> identical stream, every run, on
## every machine -> reproducible netcode AND replayable balance sims.
##
## Cosmetic randomness (floating combat text, etc.) must use a SEPARATE rng on the
## client so it can never desync the authoritative stream.
class_name DetRng
extends RefCounted

var _state: int

func _init(seed: int) -> void:
	_state = seed & 0xFFFFFFFF

## 32-bit multiply keeping only the low 32 bits, computed without relying on
## 64-bit overflow behaviour (al*b and ah*b each stay < 2^48, well within int64).
static func _imul32(a: int, b: int) -> int:
	a &= 0xFFFFFFFF
	b &= 0xFFFFFFFF
	var al := a & 0xFFFF
	var ah := (a >> 16) & 0xFFFF
	var low := (al * b) & 0xFFFFFFFF
	var mid := ((ah * b) & 0xFFFF) << 16
	return (low + mid) & 0xFFFFFFFF

## Next raw 32-bit unsigned value.
func next_u32() -> int:
	_state = (_state + 0x6D2B79F5) & 0xFFFFFFFF
	var t := _state
	t = _imul32(t ^ (t >> 15), t | 1)
	t = ((t + _imul32(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF) ^ t
	t = t & 0xFFFFFFFF
	t = t ^ (t >> 14)
	return t & 0xFFFFFFFF

## Uniform float in [0, 1).
func next_float() -> float:
	return float(next_u32()) / 4294967296.0

## Uniform float in [a, b).
func next_range(a: float, b: float) -> float:
	return a + next_float() * (b - a)
