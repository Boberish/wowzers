# Art direction and animation prototype handoff

Date: 2026-07-15

Status: exploration selected for an in-engine proof; not approved as a full-game
replacement yet.

## Read this first

The player selected **Misprint Masquerade**, especially the middle-ground full
gameplay screenshot, as the direction worth testing. The goal is not to make
conventional fantasy art and add paper grain afterward. The goal is to use an
intentional hand-pulled screenprint language that makes whole-pose animation,
limited in-betweens, and small registration errors look authored rather than
cheap.

Keep the existing playable art and current direction intact until the isolated
Godot proof is accepted. This bundle is additive and experimental.

Last known project context before this exploration was main commit `af1bca6`
(I4 documented/closed and C7 next) with source-art commit `2baf3fe`. Treat those
hashes only as historical orientation: verify the current branch because other
Claude work and background tests may have advanced it.

## Decisions made in this exploration

- Overall game tone should be brighter, happier, and more playful, while still
  detailed. Dark dungeons can exist, but darkness is not the default identity.
- Scenes must remain modular: outdoor areas, data-center spaces, dungeons, and
  other backgrounds should all work behind the same character/UI language.
- Avoid the polished generic-AI-fantasy look. Visible print constraints and
  unusual shape language are desirable.
- The **Dodge Tank/Duelist is now a woman**: athletic, practical, agile, and not
  sexualized.
- The **healer is now a man**: tall or normally proportioned, not fat and not a
  bodybuilder.
- The Duelist uses **one weapon only**: a single slender parrying/fencing sword
  similar to a rapier. No dagger, shield, second sword, or magical duplicate.
- The chosen animation test is a **duck/side-step dodge**, not a parry or attack.
- Misprint animation uses complete pose cards plus Godot transforms and brief
  colored echo sprites. It does not require Spine or another runtime library.

## Selected visual target

The favored screen is:

`screenshots/misprint_gameplay_02_middle_selected.png`

It is more energetic and handmade than the restrained option, but it keeps the
screen readable and implementable. The other two screens remain useful bounds:

- `misprint_gameplay_01_restrained.png`: broadest appeal and least visual noise.
- `misprint_gameplay_03_full_commitment.png`: strongest print identity and most
  aggressive asymmetry/misregistration.

The direction board is:

`concepts/misprint_masquerade_direction.png`

## UI requirements carried forward

The current UI hierarchy remains gameplay-first:

- The rhythm/timing lane and exact bullseye are the main focal point.
- Timing markers must retain their precise center/strike indicators; large
  silhouettes alone are not accurate enough.
- Real attacks use the yellow diamond, silver hexagon, and bronze circle forms.
- Fake attacks can use purple variants of any of those three forms.
- Do not use a skull for the unavoidable/cannot-act state.
- WIND belongs centrally above the five combo points.
- Player HEALTH and AGGRO are bars flanking that central resource cluster.
- Enemy health and cast information stay visible without covering the actors.
- The compact ability row is modular; a sixth button may be added later.
- Party health/debuff components were deliberately omitted from the latest
  visual test and are not part of this animation proof.

The game is a fast UI/rhythm game. Character action is supporting feedback; it
must never obscure or compete with the timing target.

## Dodge proof assets

The current proof contains six fixed-canvas, transparent PNG pose cards:

1. `dodge_frame_01.png` — ready stance.
2. `dodge_frame_02.png` — compression/duck.
3. `dodge_frame_03.png` — sharp lateral weight shift.
4. `dodge_frame_04.png` — deepest clearance silhouette.
5. `dodge_frame_05.png` — low settle/overshoot.
6. `dodge_frame_06.png` — controlled return toward ready.

All frames are 553x466 and share the same canvas/baseline. They are prototype
art, not final production sprites. The full generated 3x2 magenta source sheet
is `dodge_pose_sheet_source.png`. The warm-paper looping preview is
`dodge_animation_preview.gif`.

The GIF is **not Godot output**. It only proves that the pose sequence reads. Its
approximate cadence is:

| Pose | Preview time | Approximate 30 Hz ticks |
| --- | ---: | ---: |
| Ready | 300 ms | 9 |
| Duck | 30 ms | 1 |
| Shift | 30 ms | 1 |
| Clearance | 70 ms | 2 |
| Settle | 70 ms | 2 |
| Recover | 130 ms | 4 |

The active dodge after input is therefore about ten ticks/330 ms; the long ready
hold exists only to make the looping GIF legible.

## Next task: isolated Godot proof

Follow the repository's coordinator/master-plan workflow before editing. Update
the plan before and after the task as required by the project instructions.

Create an isolated prototype scene; do not replace current player art and do not
couple the test to a production encounter until it works.

Recommended implementation:

1. Import the six transparent PNGs without resizing their canvases.
2. Use one `Sprite2D` and swap textures from the real combat tick, or use an
   `AnimatedSprite2D` only if its frame changes are explicitly synchronized to
   the 30 Hz simulation.
3. On a successful dodge input, show poses 02–06 for approximately 1, 1, 2, 2,
   and 4 ticks, then return to pose 01.
4. Translate the character root sideways during the action. Start around 70–100
   display pixels and tune against the real camera scale; do not bake all screen
   travel into the frame art.
5. Add two short-lived duplicate sprites behind the active pose: one coral and
   one cobalt, offset roughly 5–10 pixels in opposite directions. They should
   last one or two ticks and appear only at departure/clearance.
6. Keep all VFX compact. The timing lane and bullseye must remain unobstructed.
7. Test against a visible Mistral attack line in the actual HUD composition.
8. Test both normal cadence and the fastest expected Twin Fang/high-flow cadence.
9. Keep the prototype browser/WebGL-safe: texture swaps, basic transforms,
   modulated duplicate sprites, and simple particles only.

No Spine runtime, skeletal rig, deformation library, or new graphics package is
needed for this proof.

## Acceptance questions

- Does the first tick feel immediate when the input succeeds?
- Does the abrupt pose change look intentional rather than broken?
- Is the woman's head clearly below or beside the incoming attack line?
- Is the single sword readable without resembling an extra limb?
- Do the coat tails improve direction/speed without hiding the legs?
- Does the pose remain readable behind the actual UI?
- Do the coral/cobalt echoes add speed without making the hit timing ambiguous?
- Does the sequence remain coherent during high-flow repeated attacks?
- Are the six generated poses consistent enough to justify this production
  pipeline, or would each animation require excessive manual redraw?

## Suggested Claude task prompt

> Read the coordinator document, project instructions, and master plan first,
> and update the plan before/after work exactly as required. Add the Misprint
> dodge assets as an isolated art prototype without replacing any current
> playable assets. Build a small Godot scene that drives the six transparent
> pose cards from the real 30 Hz combat tick using the timing in this handoff.
> Add a small sideways root translation and one-tick coral/cobalt echo sprites.
> Display the test behind the real Dodge Tank HUD and a representative Mistral
> attack. Include normal and high-flow replay controls. Keep it WebGL-safe. Do
> not merge it into production encounters or deprecate the current character
> renderer. Report screenshots/video, import settings, measured cadence, and any
> pose-alignment problems. If new generated art is needed, stop and ask Bill.

## Repository placement recommendation

When importing this bundle into Wowzers, keep it clearly separated, for example:

```text
art_prototypes/misprint/2026-07-15/
  concepts/
  screenshots/
  dodge_test/
  tools/
docs/art/ART_HANDOFF_2026-07-15.md
```

Suggested commit message:

```text
art: add Misprint direction and dodge animation proof
```

