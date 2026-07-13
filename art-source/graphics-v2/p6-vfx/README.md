# P6 Signature VFX · I4 Production Sources

Bill authorized the full-budget VFX pass on 2026-07-13 with one rich GL Compatibility/WebGL2-safe
look—no deliberately cheap browser edition. These are project-bound AI-authored flipbook sources
for Claude's C7 preparation/runtime binding. They stay outside `res://` until C7 cuts, registers,
imports, pools, and verifies them.

## Delivered families

| Effect | Alpha source | Frames / layout | Gameplay read |
|---|---|---:|---|
| Parry | `alpha/parry-alpha-v1.png` | 8 · 4×2 | contact spark → shield/counter crescent → sunburst → fast recoil |
| Dodge | `alpha/dodge-alpha-v1.png` | 8 · 4×2 | directional teal wind S-curve; never reads as a block/impact |
| Combo Dump | `alpha/dump-alpha-v1.png` | 8 · 4×2 | five stored sparks collapse → spiral → premium offensive wave |
| En Garde activation | `alpha/engarde-activate-alpha-v1.png` | 8 · 4×2 | floor ellipse + open guard brackets → crest → compact hold |
| En Garde hold | `alpha/engarde-hold-alpha-v1.png` | 4 · 4×1 | quiet low-rate active-stance loop; open center |
| Light impact | `alpha/impact-light-alpha-v1.png` | 6 · 3×2 | tiny, immediate contact; must stay below parry visual weight |
| Heavy impact | `alpha/impact-heavy-alpha-v1.png` | 8 · 4×2 | directional star/arc break with chunky fragments |
| Crush impact | `alpha/impact-crush-alpha-v1.png` | 8 · 4×2 | vertical buster commit → ground shock fan → rapid debris clear |

Matching untouched generation outputs live under `chroma/`. Alpha PNGs were produced with the
installed Codex imagegen `remove_chroma_key.py` helper using border-key sampling, soft matte,
threshold `12..220`, and despill. All eight alpha outputs were visually inspected after conversion.
The rejected heavy sheet with white cell-divider lines was not committed; the corrected no-grid
source is `impact-heavy-*-v1.png`.

## Sheet cuts

Every source is `1672×941`. Use `source-layout.json` for the deterministic first cut. The odd
height is intentional source reality: two-row sheets use `y=0..470` and `y=470..941`. Do not ask
Godot to infer equal `vframes=2` directly from the unprepared sheet. C7 should cut cells, preserve
their full registration canvas, then alpha-trim only if it also records the offset/pivot metadata.

The drawn contact/body/ground anchor must be registered in the C7 visual prep tour; do not simply
center every trimmed alpha box. Parry/Light/Heavy share a contact-point vocabulary. Dodge/Dump
share a release origin with directional travel. En Garde uses the invisible fighter's body center
plus floor ellipse. Crush uses the lower-middle ground contact.

## Runtime intent (C7)

- Presentation never gates combat. New committed actions replace/scrub stale recovery immediately.
- Suggested total visual durations: Light `~110 ms`; Dodge/Parry `~190–220 ms`; Heavy `~190 ms`;
  Crush/Dump `~230–260 ms`; En Garde activation `~300–360 ms`; hold loop `~1.6–2.4 s` at low rate.
- The decisive contact/peak lands within roughly `50–100 ms`. Tail frames are interruptible.
- One atlas frame is the authored color layer. Optional additive duplicates/glints are runtime
  layers using the same texture; do not bake new soft bloom into the PNGs.
- Grade/size juice should scale, duplicate, tint, shake, and time the same source family rather
  than inventing inconsistent replacement art. Perfect may get the full additive/fragment layer;
  lower grades remove layers/scale, never change the answer timing.
- Light < Heavy < Crush is a strict footprint/fragment/camera-response ladder.
- En Garde hold idles near zero cost: one low-rate sprite loop, no permanent particle emitter.
- The AnswerChannel, timing nail/gate, and next incoming shape remain unobscured. Clamp or relocate
  theater FX rather than washing over the dashboard.
- GL Compatibility/WebGL2 path only: painted trail frames replace unsupported native particle
  trails; sprite layering replaces HDR 2D. No compute, backbuffer dependency, or required blur.

## C7 + `tempo-art` boundary

C7 owns the reusable flipbook player/pool, deterministic prep, manifests/pivots, event binding,
effect budget, additive layering, and the already-audited 13/13 `tempo-art` hunk transplant. Apply
the two recorded fixes: null `_post` on HUD clear and gate `finisher` wash to the player. Plain
strike hit-stop remains forbidden because it would disturb the rhythm reference; signature/local
contact freezes stay presentation-only and cannot touch AnswerChannel truth.

No new image generation, repainting, or silent substitutions are authorized inside C7. If a sheet
cannot be registered or a required state is genuinely absent, stop and ask Bill with the exact
source need before handing another request to Codex.

## Generation provenance

Built-in Codex image generation used the approved SUNPRINT CEL component board and the accepted
Parry/Dodge sheets as style references. Each prompt specified exact frame count/order, gameplay
silhouette, a flat `#ff00ff` removable field, crisp opaque cel edges, no baked fog/bloom, no text,
and fast negative-space-preserving tails. The production set is authored art; Godot supplies live
timing, placement, intensity, pooling, additive modulation, camera response, and interruption.
