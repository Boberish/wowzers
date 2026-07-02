# Project Rift — Godot project (`res://`)

Godot 4.7, GDScript, **GL Compatibility** renderer. See `../PORT-PLAN.md` for the
roadmap and `../CLAUDE.md` for the architecture rules.

## Layout
```
core/            the pure, deterministic engine (no rendering / clock / unseeded RNG)
  rng.gd           DetRng — seeded mulberry32 (the ONLY randomness allowed in the sim)
  combat_state.gd  CombatState — the whole mutable fight (a data bag)
  combat_core.gd   CombatCore — static reducer: update(state), perform(), boss AI, damage
  seat.gd          Seat — a participant (human / AI ally / sim agent are interchangeable)
  boss_state.gd    BossState, telegraph.gd Telegraph, policy.gd Policy (base)
data/            authored content as Resources (.tres-ready schema)
  tuning_config.gd every balance number (swept by the sim)
  encounter_res.gd / ability_res.gd / phase_res.gd   data-driven bosses
  aspect_res.gd / upgrade_res.gd                     roguelite schema (used from M1)
  m0_content.gd    the M0 dummy boss + party, built in code
sim/
  sim_runner.gd    headless batch sim -> CSV + win-rate bands
  policies/tank_policy.gd   a minimal tank AI (same Policy a human adapter will use)
out/             sim CSV output
```

## Run the headless balance sim
```bash
# from the repo root (/home/bill/projects/Wowzers)
godot --headless --path godot --script res://sim/sim_runner.gd -- --seeds=400
# args after `--`:  --seeds=N   --out=res://out/sim_results.csv (or an absolute path)
```
It prints a determinism check + a win-rate sweep and writes `out/sim_results.csv`.
Analyse the CSV in Python/pandas (generation is in-engine = single source of truth;
analysis is wherever you like).

**First run on a fresh checkout:** build the global-class cache once, or the
`--script` run won't resolve `class_name`s:
```bash
godot --headless --path godot --import
```

## Open the editor (GUI, via WSLg)
```bash
godot --path godot --editor        # opens the Godot editor window on Windows
# if the window fails to create under WSLg, force the GL driver:
godot --path godot --editor --rendering-driver opengl3
```

## Determinism contract (do not break — see CLAUDE.md)
Fixed 30 Hz tick · integer `tick` is truth · one seeded `DetRng` in state, advanced
only in `update()` · tick-stamped input queue · all constants in `TuningConfig` ·
no mutable module-level globals. `sim_runner` asserts same-seed reproducibility on
every run.
