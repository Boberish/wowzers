## ClassGauge — the shared base under the class combat instruments (REFIT P4, the
## gauge half of the ClassBand rail; Bill 2026-07-10: "make the base of obvious
## shared stuff and we can go on from that base").
##
## What every hand-drawn gauge/bar had re-rolled separately — ONE home now:
##   · THE VERDICT FLASH — one (text/key, color, timer, hold) banner slot with a
##     fade: flash() arms it, verdict_alpha() reads the fade, verdict_live() gates
##     the draw. Widgets with bespoke verdict layouts (rhythm/opening) use the
##     verdict string as a KEY and draw their own form; text-banner widgets
##     (well/brew) draw the string straight.
##   · THE PULSE — one breathing phase for glow/wobble effects; each widget keeps
##     its own rate (pulse_rate), the base keeps the clock.
##   · per-frame plumbing — _process decays the timers and queue_redraw()s;
##     subclasses put their own eases/pops in _tick(delta) instead of _process.
##   · on_event() — the standard entry the ClassBands feed engine events through.
##
## Draw STYLE stays per-widget (procedural _draw until the art era) — this base is
## the seam a retheme lands on ONCE. Grow shared draw helpers here as they earn it.
class_name ClassGauge
extends Control

const VERDICT_HOLD := 0.85

var verdict: String = ""           ## the live verdict key/text ("" or expired = none)
var verdict_color: Color = Color.WHITE
var pulse: float = 0.0             ## the shared breathing phase
var pulse_rate: float = 3.2        ## per-widget feel — set in _init/_ready

var _verdict_t: float = 0.0
var _verdict_hold: float = VERDICT_HOLD

## Arm the verdict flash (a key like "perfect"/"peak", or a full banner line).
func flash(text: String, col: Color = Color.WHITE, hold: float = VERDICT_HOLD) -> void:
	verdict = text
	verdict_color = col
	_verdict_hold = maxf(0.05, hold)
	_verdict_t = _verdict_hold

func verdict_live() -> bool:
	return _verdict_t > 0.0

## 1 → 0 over the hold — the standard fade every verdict draw multiplies in.
func verdict_alpha() -> float:
	return clampf(_verdict_t / _verdict_hold, 0.0, 1.0)

## The standard event entry (ClassBand.on_event feeds the active gauge through
## this) — widgets match on ev["t"] and flash()/stash what they care about.
func on_event(_ev: Dictionary) -> void:
	pass

func _process(delta: float) -> void:
	pulse += delta * pulse_rate
	if _verdict_t > 0.0:
		_verdict_t = maxf(0.0, _verdict_t - delta)
	_tick(delta)
	queue_redraw()

## Subclass per-frame state (eases, pops, trails) — override THIS, not _process.
func _tick(_delta: float) -> void:
	pass
