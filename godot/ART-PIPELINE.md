# Art Pipeline — replacing the placeholder actors with YOUR art

Every fighter on a 2D stage (duel or raid) is an **Actor2D** built by
`Actor2D.make(id, aspect)`. The factory checks for your art FIRST:

> **Drop a scene at `res://game/art/actors/<id>.tscn` and it replaces the
> placeholder puppet for that actor. No code changes.**

Actor ids: `bulwark` · `twinfang` · `voidcaller` · `mender` · `riftmaw` · `executioner`

## Authoring an actor scene

Any node tree (Sprite2D layers, AnimatedSprite2D, Skeleton2D cutout — your call),
plus **one AnimationPlayer named `anim`**. Author the actor **facing RIGHT (+X)**
with its **feet at the scene origin (y=0)**; bosses get flipped by the stage.
Rough placeholder sizes to match: raiders ~300px tall, bosses ~520–620px.

## The animation-name contract

The wrapper (`SpriteActor2D`) maps game moments to animation names. Everything is
OPTIONAL — missing animations fall back gracefully (worst case the actor just
stands in `idle`). Add them as your art grows.

| Animation | Played when | Notes |
|---|---|---|
| `idle` | always, looping | make it breathe / bounce |
| `windup_light/heavy/crush` | a swing telegraphs | **SCRUBBED, not played** — see below |
| `windup_channel` | boss heal-cast / your own cast bar | scrubbed |
| `windup_curse`, `windup_nova` | pointed curse / raid-wide blast | scrubbed |
| `windup_cut_hi`, `windup_cut_lo` | combo-string beats (alternating) | scrubbed |
| `swing_<same kinds>` | the wind-up releases | fast + violent |
| `curse` | the curse fires | |
| `act_<ability id>` | that ability commits (e.g. `act_cleave`, `act_kick`) | fallback: `act` |
| `act_strike_perfect` | a Perfect strike (Twinfang) | fallback: `act_strike` |
| `evade` | the class defensive verb answers (parry/dodge/KICK) | |
| `hop`, `graze`, `stumble`, `brace` | universal-dodge grades (good/graze/BAITED/READ) | |
| `hit`, `hit_big` | taking damage | |
| `slump` | resource collapse (Flow lost) | |
| `cast_<spell id>` | healer/caster spell fires | fallback: `cast` |
| `stagger` | interrupted / kicked | |
| `death`, `victory` | fight ends | `death` should HOLD its last frame |

### Wind-ups are scrubbed — this is the important one

A telegraph's length varies per cast and per phase speed. The stage does NOT
play your wind-up animation — it **pauses it and drags the playhead** so that
`animation position = telegraph progress × animation length`. Author ONE
anticipation animation at any length you like (0.5s is fine); in game it will
always land its final frame exactly when the swing lands. Put the scariest
frame last.

Everything else (`act_*`, `hit`, `evade`, …) plays normally at authored speed.

## Testing your art

- Duel: `godot --path godot --script res://sim/stage2d_tour.gd --resolution 1920x1080 -- --out=/tmp/shots`
- Raid: `godot --path godot --script res://sim/raid_stage_tour.gd --resolution 1920x1080 -- --out=/tmp/shots`
- Or just play: `godot --path godot -- --autostart=raid:blade:tempo`

The tours drive real AI fights and screenshot them — flip through the PNGs to
see your actor acting.

## Placeholders

The code puppets live in `game/stage2d/*_rig_2d.gd` (PoseRig2D subclasses).
They implement the same Actor2D contract, so anything they do, your art can do.
Delete nothing — they remain the fallback for any actor without an art scene.
