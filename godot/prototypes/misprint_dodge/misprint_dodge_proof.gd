## MisprintDodgeProof — the one guarded selector for the 2026-07-15 Misprint
## Masquerade animation test. It is deliberately separate from ArtV2: this is
## an unapproved prototype, enabled only by the isolated test scene/tour.
class_name MisprintDodgeProof
extends RefCounted

static var enabled := false
## Presentation-only A/B switch for the deliberately overcooked motion pass.
## It is false everywhere except the isolated wrapper/tour.
static var pushed_motion := false
## Live knobs owned by the isolated wrapper. They never enter combat state.
static var motion_ease_s := 0.12
static var trail_count := 4
static var trail_spread := 1.0
static var trail_opacity := 1.0
static var blur_px := 6.0
