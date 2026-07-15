# Misprint Duelist — focused defensive-guard revision

Date: 2026-07-15

Status: static approval concept only. No animation/runtime/default decision.

Authoritative character/hands reference: `user_refs/goodhands.png`.

Authoritative sword/arm-length reference: `user_refs/goodsword.png`.

Latest composite candidate: `duelist_defensive_guard_v6_authoritative_composite.png`.

The built-in image-generation tool combined Round-2 A's angular high ponytail
and simple cropped costume with Round-2 B's cleaner circular-guard rapier and
flatter construction. The final prompt asked for an adult athletic woman with a
clearly feminine, fuller-bust silhouette under a modest closed jacket; exactly
one rapier; a planted, knees-flexed defensive ready guard with a bent weapon arm
rather than a rest, lunge, dodge, attack, or parry contact; two broad coral
panels; and no extra clothing layers.

The first output satisfied the design/stance brief but drew internal finger and
knuckle lines. A targeted edit changed only the two gloves into smooth solid
closed mitten/fist silhouettes while preserving the character, pose, sword,
flat palette, framing, and background. The first output was discarded.

References: Round-2 A and B plus the selected Misprint gameplay screen.

## Geometry correction

V3 correctly made the rapier blade/tang one axis through the geometric center of
the circular guard, but misread “her right arm” and lengthened the viewer-right
sword arm. V4 preserves the corrected sword axis, restores the sword arm's
balanced bend, and modestly lengthens the correct limb: her anatomical right,
the viewer-left non-sword shoulder→elbow→wrist chain. The solid fingerless
mitten/fist treatment remains intact. V2 stays alongside it as the locked
hand-shape comparison source; V3 is retained as the side-interpretation audit.

V4 fixed the correct arm but was derived from the geometry pass, so its fists
drifted away from the approved rounded solid-mitten treatment. V5 restarts from
v2 as the locked edit target, keeps its smooth featureless hand design, redraws
the blade through the center of the guard, and modestly lengthens the viewer-left
non-sword arm. V4 remains only as a correction-history artifact.

## Authoritative user-reference composite

Bill rejected the v2/v5 “featureless mitten” interpretation and supplied the
actual source pair. `user_refs/goodhands.png` is now the locked source for the
character and both detailed closed gloves: curled finger groups, knuckles,
thumbs, outlines, and shading all remain visible. `user_refs/goodsword.png` is
only the reference for the rapier's blade→guard-center→grip axis and the modestly
longer anatomical-right / viewer-left non-sword arm.

V6 combines those requirements. Both arms retain the defensive bent-elbow pose;
the viewer-left fist stays beside the belt rather than hanging down; and the one
straight rapier crosses the geometric center of its circular gold guard. The two
user references are byte-identical copies of the Downloads attachments:

- `goodhands.png`: SHA-256
  `47f39cf7b1018350d188d46762d78a0f1230726e5c81bdf65ce64489f30cd1c2`
- `goodsword.png`: SHA-256
  `5b5a2c620dc9063f4c44720c34b6dd6516945d21ec6e35330a43718c24b93c59`

V2–V5 remain only as generation/correction history; none supersedes the two
explicit user references or V6 as the current approval candidate.
