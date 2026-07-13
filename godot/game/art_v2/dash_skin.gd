## DashSkin — C6B: the painted-dashboard asset registry (GRAPHICS-PLAN §2.3.1 / P5).
## Resolves every I3-B runtime piece ONCE at construction (SCENES.md §3½ renderer
## law — a texture first loaded inside a draw callback uploads as a permanent flat-
## white RID under WSLg d3d12-GL; never load() in _draw). `make()` returns null if
## ANY core piece is missing → the host stays on its C6A graybox and the widgets
## keep their legacy chrome (the fail-safe law: missing V2 assets never break the
## HUD). Pure view: textures + geometry helpers, zero gameplay/state contact.
##
## Opening rectangles (the code-data windows inside each painted shell) are baked
## from `dash/manifest.json` — the deterministic crop tool's provenance record
## (artv2_dash_prep.gd). Text, values, fills, cooldowns, timing geometry, casts,
## warnings and the 30% Flow lock stay code-drawn on top (I3-B README law).
class_name DashSkin
extends RefCounted

const DIR := "res://game/art_v2/dash/"
const PIECES := ["frame_answer", "shell_boss", "shell_resource", "party_row",
	"slot_ability", "socket_combo", "socket_debuff", "utility_tab",
	"icon_diamond", "icon_hexagon", "icon_octagon", "icon_brace",
	"icon_feint_diamond", "icon_feint_hexagon", "icon_feint_octagon"]

## Interior openings as [x0, y0, x1, y1] fractions of each piece (manifest.json).
const OPEN_ANSWER := [0.032, 0.144, 0.968, 0.862]
const OPEN_BOSS := [0.133, 0.285, 0.945, 0.696]
const OPEN_RESOURCE := [0.04, 0.224, 0.962, 0.811]
const OPEN_SLOT := [0.153, 0.115, 0.859, 0.818]
const OPEN_COMBO := [0.183, 0.125, 0.824, 0.892]
const OPEN_UTIL := [0.105, 0.401, 0.435, 0.802]
## party_row openings: portrait ring · HP · resource · cast · 3 status sockets
const ROW_PORTRAIT := [0.044, 0.17, 0.169, 0.727]
const ROW_HP := [0.208, 0.261, 0.949, 0.489]
const ROW_RESOURCE := [0.208, 0.602, 0.655, 0.739]
const ROW_CAST := [0.205, 0.852, 0.66, 0.898]
const ROW_SOCKETS := [[0.728, 0.614, 0.78, 0.841], [0.808, 0.614, 0.86, 0.841],
	[0.889, 0.614, 0.941, 0.841]]
## 3-slice caps (fractions of texture width) — the regions that must NOT stretch:
## answer-frame corner assemblies · resource-shell end caps · the party row's
## portrait ring (left) and socket block (right).
const CAPS_ANSWER := [0.09, 0.09]
const CAPS_RESOURCE := [0.085, 0.085]
const CAPS_ROW := [0.19, 0.30]

var t: Dictionary = {}     ## piece name -> Texture2D (resolved at construction)

## Build the registry, or null when any piece is absent (⇒ graybox fallback).
static func make() -> DashSkin:
	var s := DashSkin.new()
	for p in PIECES:
		var path: String = DIR + String(p) + ".png"
		if not ResourceLoader.exists(path):
			return null
		var tex: Texture2D = load(path)
		if tex == null:
			return null
		s.t[p] = tex
	return s

## THE ANSWER-ICON LAW (§2.3.1 SHAPE LAW): ◇ dodge-or-parry · ⬡ dodge-only ·
## ⯃ parry-only · ⊘ BRACE. PURPLE = feint and rides its own painted variants for
## the three PRESSABLE shapes only — a BRACE can never be purple (there is no such
## asset by design; the request is answered with the normal barred disc).
func icon(kind: String, purple: bool) -> Texture2D:
	var shape := "diamond"
	match kind:
		"heavy", "buster":
			shape = "octagon"
		"global", "flurry":
			shape = "hexagon"
		"eat":
			return t["icon_brace"]      # never purple, by law
	if purple:
		return t["icon_feint_" + shape]
	return t["icon_" + shape]

## Horizontal 3-slice draw: end caps render at UNIFORM scale (dest_h / tex_h so
## rings/medallions/ornament keep their aspect at any bar height); only the middle
## band stretches. StyleBoxTexture margins render 1:1 and squash thin bars, hence
## this helper.
func hshell(ci: CanvasItem, piece: String, rect: Rect2, caps: Array, mod := Color.WHITE) -> void:
	var tex: Texture2D = t.get(piece)
	if tex == null:
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var s := rect.size.y / th
	var lw := tw * float(caps[0]) * s
	var rw := tw * float(caps[1]) * s
	if lw + rw > rect.size.x:            # too narrow to slice — uniform squeeze
		ci.draw_texture_rect(tex, rect, false, mod)
		return
	ci.draw_texture_rect_region(tex, Rect2(rect.position, Vector2(lw, rect.size.y)),
		Rect2(0, 0, tw * float(caps[0]), th), mod)
	ci.draw_texture_rect_region(tex,
		Rect2(rect.position + Vector2(lw, 0), Vector2(rect.size.x - lw - rw, rect.size.y)),
		Rect2(tw * float(caps[0]), 0, tw * (1.0 - float(caps[0]) - float(caps[1])), th), mod)
	ci.draw_texture_rect_region(tex,
		Rect2(Vector2(rect.end.x - rw, rect.position.y), Vector2(rw, rect.size.y)),
		Rect2(tw * (1.0 - float(caps[1])), 0, tw * float(caps[1]), th), mod)

## Map a texture x-fraction through the 3-slice above into dest pixels — so the
## painted openings still line up when the middle band stretches.
static func slice_x(rect: Rect2, caps: Array, fx: float, tex_w: float, tex_h: float) -> float:
	var s := rect.size.y / tex_h
	var lw := tex_w * float(caps[0]) * s
	var rw := tex_w * float(caps[1]) * s
	if lw + rw > rect.size.x:            # uniform-squeeze path mirrors hshell
		return rect.position.x + rect.size.x * fx
	if fx <= float(caps[0]):
		return rect.position.x + tex_w * fx * s
	if fx >= 1.0 - float(caps[1]):
		return rect.end.x - tex_w * (1.0 - fx) * s
	var mid0 := float(caps[0])
	var mid1 := 1.0 - float(caps[1])
	return rect.position.x + lw + (rect.size.x - lw - rw) * (fx - mid0) / (mid1 - mid0)

## The dest rect of an opening inside a 3-sliced shell (y maps uniformly).
func sliced_opening(piece: String, rect: Rect2, caps: Array, open: Array) -> Rect2:
	var tex: Texture2D = t[piece]
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var x0 := DashSkin.slice_x(rect, caps, float(open[0]), tw, th)
	var x1 := DashSkin.slice_x(rect, caps, float(open[2]), tw, th)
	var y0 := rect.position.y + rect.size.y * float(open[1])
	var y1 := rect.position.y + rect.size.y * float(open[3])
	return Rect2(x0, y0, x1 - x0, y1 - y0)

## The dest rect of an opening inside a UNIFORMLY drawn piece.
static func uniform_opening(rect: Rect2, open: Array) -> Rect2:
	return Rect2(rect.position.x + rect.size.x * float(open[0]),
		rect.position.y + rect.size.y * float(open[1]),
		rect.size.x * (float(open[2]) - float(open[0])),
		rect.size.y * (float(open[3]) - float(open[1])))

## Uniform-scale dest rect for a piece fitted to a height, anchored at a position.
func fit_h(piece: String, pos: Vector2, h: float) -> Rect2:
	var tex: Texture2D = t[piece]
	return Rect2(pos, Vector2(h * float(tex.get_width()) / float(tex.get_height()), h))
