# Continue here — Misprint Duelist animation rework

Date: 2026-07-15

Branch: `codex/misprint-dodge-test` (experimental, unmerged)

This is the restart point for another computer or a fresh chat. Read
`AGENTS.md` and `MASTER-PLAN.md` first, then use this file as the decision
record for the current art task.

## 2026-07-16 continuation amendment — latest verdict wins

Bill accepted the slower GOOD dodge as the proof-of-concept win and explicitly
superseded the stop-parry instruction below. GREAT/PERFECT and other dodge grades
remain parked. The current experiment now includes a four-pose parry runtime
study plus a compact timing-centered dashboard layout.

Bill then rejected the dark-fantasy test background/style. The current visual
direction is the bright editorial screenprint blend documented in
`background_round_02/` and `ui_round_01/`: `mainStyle.png` is the primary
reference, `secondaryStyle.png` contributes only restrained poster geometry.
Environment and HUD are deliberately separate images. The environment uses
maintained, infrastructure-integrated biocooling plants—no arbitrary pots and no
abandoned overgrowth. The HUD sheet is a modular component target; live timing,
fills, text, cooldowns, and state remain code-drawn. Stop for Bill's verdict on
these two new images before cutting/replacing the existing runtime HUD assets.

## Approved now

The current character/READY anchor is:

`dodge_round_01/user_refs/newSwordGaurd.png`

SHA-256:

`5654c49255a5d2acfdb522974fbcd909f961ba0b6776d04a44acec3a94feded4`

The current approved GOOD-dodge pose gate is:

`dodge_round_01/good_duck_four_pose_gate_v2_sword_foreground.png`

SHA-256:

`84cd3720e93d772bf66ec9ad88a7ddeb1fd978dc28a004eb69085ed457cf5dab`

Bill's verdict after the panel 2/3 sword-layer correction was **“looks
great.”** V2 is therefore the approved source gate. The earlier
`good_duck_four_pose_gate.png` remains only as an audit source.

The four active authored poses, read left-to-right and top-to-bottom, are:

1. COMPRESS
2. DEEPEST CLEARANCE
3. LOW SETTLE / OVERSHOOT
4. NEAR-READY RECOVERY

The READY anchor is shared separately and is not one of those four poses.

## Completed isolated task

The branch now productionizes **only this approved GOOD dodge**:

1. Four transparent, fixed-canvas production cards derive from the approved V2
   gate while keeping the selected READY anchor consistent.
2. Preserve the single slender sword, brass cup guard, closed/gloved hands,
   outfit, proportions, ponytail, and the corrected foreground sword layering.
3. Bill's first Windows pass found the six-tick sequence jerky and too fast to
   read as a duck. The revised active holds are **2 / 4 / 2 / 2 ticks**, then
   return to READY: ten ticks / 333 ms total, with DEEPEST CLEARANCE held for
   four ticks / 133 ms.
4. Root motion remains Godot-owned at **30 display pixels**, rather than baked
   into the cards. Tick ownership is unchanged; a render-only 50 ms sine ease
   softens the visible translation.
5. The proof remains isolated and default-off. It does not replace the playable actor,
   change combat/gameplay, change protocol, or merge this branch to `main`.
6. The isolated wrapper now defaults to stage-only `VIEW: CLEAN`, hiding all
   combat HUD children and verdict overlays so no panel crosses the actor.
   Its small test controls remain available; `VIEW: FULL HUD` restores the
   complete play surface.

Initial implementation commit: `dc5dedb`; readability revision: `f0bc5a2`;
live motion lab: `987e1cf`.
The source cards are under
`dodge_round_01/production_cards/`; the byte-identical runtime copies are under
`godot/prototypes/misprint_dodge/frames_good_v2/`. The exact build and
verification record is in `godot/prototypes/misprint_dodge/README.md`.

## Live motion lab — tune here next

The isolated wrapper defaults to an intentionally excessive `MOTION: PUSHED`
pass and provides live EASE, TRAILS, SPREAD, OPACITY, and BLUR sliders. Use
`MOTION: BASELINE` for an instant comparison; neither side changes the fixed
2/4/2/2 tick pose cadence. Slider changes affect the active actor without a
fight restart. The exaggerated defaults are 120 ms / 4 / 1.00× / 1.00× / 6 px.

An early implementation bug placed the effect children at negative z, behind
the stage environment. Commit `987e1cf` fixes the actor-local stack and the
non-headless tour visibly confirms all four direction-aware trails. The next
useful verdict is the five slider values at the best midpoint.

## Stop here — Bill's tuned verdict next

Do **not** add a smear frame yet. Do **not** begin GREAT, PERFECT, or parry art
until Bill has tuned and judged this slower, uncluttered GOOD-only runtime pass.
Do not merge this branch to `main`. The next action is an interactive/visual
verdict on the 333 ms clean-view revision plus the chosen motion-lab values:
does the deep duck now read clearly and move smoothly enough before expanding
the animation set?

The display result `GOOD` maps to the existing internal
`StrikeRes.Grade.GOOD`; this task does not change grading logic.

## Historical proof — do not mistake it for the new gate

The older six-frame executable proof remains under:

`godot/prototypes/misprint_dodge/`

Its source cards are under `dodge_test/`. It established that fixed-card swaps,
root travel, and echo sprites work in the real HUD, but it predates the selected
cup-guard character and the approved four-pose gate. Keep it as a reference;
do not overwrite its source frames or treat them as the new production art.

## Start on the other computer

If the feature branch does not exist locally yet:

```bash
git fetch origin
git worktree add ../wow-misprint-dodge-test \
  -b codex/misprint-dodge-test origin/codex/misprint-dodge-test
cd ../wow-misprint-dodge-test
```

If that branch/worktree already exists there:

```bash
git fetch origin
cd ../wow-misprint-dodge-test
git pull --ff-only
```

Before stopping on either computer, commit and push the feature branch. Before
starting on the other, fetch and pull it. Do not work on this feature from both
computers simultaneously without first pushing one side.

## Fresh-chat prompt

> Work in the `codex/misprint-dodge-test` worktree. Read `AGENTS.md`,
> `MASTER-PLAN.md`, and
> `art_prototypes/misprint/2026-07-15/CONTINUE-HERE.md` first. Continue only the
> approved GOOD-dodge runtime verdict described there: four transparent
> fixed-canvas active cards from the V2 pose gate, 2/4/2/2 ticks at 30 Hz,
> shared READY anchor, eased 30 px Godot-owned root motion, stage-only CLEAN
> view by default, and the isolated live motion sliders. Ask Bill for the five
> selected values before promoting any treatment; keep it isolated/default-off.
> Do not start GREAT/PERFECT/parry, change gameplay, replace production art, or
> merge to main. Claim the work in the Coordination Log before editing.
