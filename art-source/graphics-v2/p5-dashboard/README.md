# P5 Duelist Dashboard · I3-B Production Sources

Bill approved the I3-A material family and revision-2 hierarchy on 2026-07-13. These sheets are
the production-source handoff for Claude's C6B trim/slice/import/binding work. They are not a
baked HUD and must remain outside `res://` until C6B prepares the selected runtime pieces.

## Source files

| Sheet | Alpha production source | Contents / order |
|---|---|---|
| Wide shells | `alpha/wide-components-alpha-v1.png` | answer frame · boss/cast frame · reusable horizontal resource shell · first-pass utility sample |
| Compact controls | `alpha/compact-components-alpha-v1.png` | repeatable party row · ability slot · combo socket · debuff/status socket |
| Answer icons | `alpha/answer-icons-alpha-v1.png` | gold diamond · steel hexagon · bronze spiked octagon · grey barred-disc BRACE · purple diamond · purple hexagon · purple spiked octagon |
| Utility tab | `alpha/utility-tab-alpha-v1.png` | corrected empty live-data window + decorative expand chevron |

The matching `chroma/*-chroma-v1.png` files are the untouched generation outputs. Alpha files
were produced with the installed Codex imagegen `remove_chroma_key.py` helper using border-key
sampling, soft matte, threshold `12..220`, and despill. All four alpha PNGs were visually checked
after conversion; their outer background and intended interior openings are transparent.

**Use the dedicated `utility-tab-alpha-v1.png`, not the utility sample embedded at the bottom of
the wide sheet.** The wide-sheet sample contains a baked decorative graph left by generation;
the dedicated correction has a clean transparent data window so live meter truth stays in code.

## Runtime preparation contract (C6B)

- Detect/crop pieces from alpha coverage; preserve padding until the crop tour proves no edge loss.
- Prefer 9-slice/style-box treatment for the wide frames and reusable resource shell. Do not
  stretch ornaments, end caps, portrait rings, or the boss medallion.
- The single party row is repeated for four seats. Its openings are, in order: portrait/role,
  HP, class resource, thin cast/progress, and three status/debuff sockets.
- The resource shell is shared visual material; HP, Wind, and Flow/Aggro keep distinct live fills,
  labels, values, and warnings supplied by Godot.
- The combo socket repeats exactly five times. The ability slot must remain repeatable from four
  through six buttons without changing the approved dashboard rectangle.
- Purple alone means feint. Use all three purple pressable shapes; never create a purple BRACE.
- Replace the current skull/X presentation with the grey barred-disc BRACE token only in the V2
  dashboard path. Keep missing-asset fallback and legacy/default-off behavior intact.

## Never bake from these sources

Text, names, numbers, values, bar fills, HP state, resource state, cast progress, cooldowns,
timing gates/nails, 30% Flow lock position, answer motion, grading, target arrows, and live utility
graph data remain code-owned. The icon-sheet timing nails are the approved visual guides, but
their exact runtime alignment still follows the live AnswerChannel geometry.

If a required crop, cap, or state cannot be produced from these approved sheets without repainting
or inventing art, stop and ask Bill. C6B is authorized for trim, crop, scale, slice, metadata,
import, binding, fallback, and tests—not new image generation or redesign.

## Generation provenance

Built-in Codex image generation was used with the approved I3-A board as the strict style
reference. The prompt set requested: (1) four isolated wide empty shells, (2) four isolated compact
reusable controls, (3) the seven exact normal/feint/BRACE icons, and (4) a corrected isolated
utility tab with an empty live-data window. Every source was generated on a flat `#00ff00` field
with no cast shadow or backdrop, then converted locally to alpha as described above.
