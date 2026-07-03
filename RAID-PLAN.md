# RAID-PLAN — Project Rift goes co-op (M2 reborn)

The game's original fantasy — MMO trinity combat, live, multiple real players on one boss,
shared timers, taunts, cross-class interplay — was always the destination. The solo game we
built is not a detour: it is the **Trials** (each class's boss gauntlet = the exam that earns
your raid seat), and the pure-reducer architecture rule existed precisely so that one shared
`CombatCore.update()` could run on an authoritative server with four humans connected.

**Product shape (locked)** *(AMENDED 2026-07-03 — RAID-ONLY lock, see MASTER-PLAN §GAME SHAPE:
the parallel solo campaign is retired as a product surface; "Solo Trials" survives only as an
unlock-inert PROVING GROUNDS practice card, and the 15 exam bosses redeploy INSIDE the raid as
personal GATE nodes / owned adds / split phases)*:
- **Solo Trials** — the current game, unchanged. Per-class gauntlets, map/meta layer, earns
  base resources (essences, reagents, Embers, Sigils). *(Economy vocabulary SUPERSEDED
  2026-07-03 — no material economy; see `PROGRESSION-PLAN.md`: trials unlock loot-table
  rows via kills/armed feats instead.)*
- **The Rift (raid mode)** — live 4-seat fights vs raid-only bosses. Humans + AI backfill for
  empty seats (solo-playable, as always dreamed). Your solo-built loadout carries in. Drops
  raid-exclusive top-tier materials (**Riftcores**) required for Sigil T3 / capstone crafts.
  *(SUPERSEDED 2026-07-03 — raid exclusivity is now structural: raid bosses own loot tables
  that drop nowhere else, deep rows gated by Seal feats/versions; see `PROGRESSION-PLAN.md`.)*

## Engine readiness audit (2026-07-02)

The reducer is already almost entirely seat-parameterized:
- `perform(s, seat, action)` takes the acting seat explicitly; input queue entries are
  `{tick, seat, action}` — **multiple full-fidelity seats can act on the same tick today**.
- Per-seat GCD/cooldowns/defense timers/kits/vars. One `ClassKit` per **seat**, not per state.
- `observe(s, seat)` is already seat-relative and multi-seat-correct (`targets_me`, per-beat
  `mine`/`answered`/`grade`).
- Telegraphs already aim at a specific seat (`Telegraph.target`); only the targeted seat's
  press eats the swing (correct raid semantics). AoE strike-string beats already let any seat
  answer.
- Group-damage line sums all seats; full-fidelity seats deal via kits (`dps=0`) — safe for N.

Single-player assumptions cluster in five places (all fixed in R0):
1. **Healer credit routing** — `_healer(s)` = first healer; absorb-eaten damage credits it,
   not the ward's caster; HoTs store no caster.
2. **No threat/aggro** — boss targeting is role-based (first living tank soaks everything).
3. **Loss semantics** — `loss_mode "raid"` assumes the healer IS the player and exactly one
   tank/one healer.
4. **Diagnostics/events** — `s.diag` counts only the `is_player` seat; events carry a single
   `"player"` bool (raid HUDs need a seat id).
5. **Drivers** — `combat_controller.gd` / HUDs / sims pin `seats[0]` as the human.

## Non-negotiables (inherited + new)

- All CombatCore determinism rules apply to raid content unchanged (30 Hz ticks, one seeded
  RNG advanced in fixed order, tick-stamped inputs, no wall clock, no mutable globals).
- **Every engine change is guarded**: after every R0 step, all six existing sims
  (`sim_runner`, bulwark, mender, twinfang, voidcaller, bloomweaver) must produce
  **byte-identical output** vs the pre-change baseline. Threat/taunt is gated by a state flag
  (`s.threat_enabled`) that no solo content sets.
- The server runs the same `update()` as the client and the sims. No server-only logic inside
  the reducer.

## R0 — Multi-seat raid combat, all-AI, headless (de-risk everything, zero netcode)

Engine generalization:
- [ ] **Caster attribution**: HoTs gain an optional `caster` ref (fallback `_healer(s)`);
      `seat.absorb_owner` set by whoever grants a ward; `on_absorb`/HoT-tick credit routes to
      the owner/caster. Mender/Bloomweaver kits set themselves as caster (behavior-identical
      solo). Known R0 limit: one absorb pool per seat → last ward-caster owns the pool
      (per-ward stacking is a later refinement).
- [ ] **Threat + taunt** (guarded by `s.threat_enabled`): threat table on `BossState`
      (seat index → float). Accrual: boss damage via `damage_boss` (× per-kit `threat_mult()`,
      tanks high), effective healing × factor. No decay. `_tank_target()` under the flag →
      taunt override, else highest threat among targetable seats (deterministic tie-break:
      lowest index). `CombatCore.taunt(s, seat, dur)` helper: forces target + bumps threat to
      top ×1.1. Healers stay untargetable in R0 (healer-aggro is a future realism knob).
- [ ] **Loss rules**: `"raid"` branch generalized to role-extinction (no living tank / no
      living healer / no living dps → wipe). Identical outcomes for all existing content
      (single tank, single healer). A dead human with living AI allies = spectate, not loss.
- [ ] **Per-seat diagnostics**: `seat.diag` counted for every full-fidelity seat; `s.diag`
      stays as the `is_player` mirror (sims unchanged).
- [ ] **Events carry `seat` index** (additive key next to the existing `player` bool).

Raid proof-of-model:
- [ ] `data/raid/` — first raid encounter: party of four FULL-fidelity seats with their real
      kits (Bulwark tank / Mender healer / Twinfang + Voidcaller dps) vs one ensemble boss.
      Boss exam covers every verb at once: melee chip + parry-check heavy on the threat
      target (tank), dodge-check bolt at a random dps (personal responsibility),
      interruptible cast (the Voidcaller's job), AoE nuke (the Mender's job), threat as a
      real constraint (a dps that out-threats the tank gets eaten; tank gets a raid-only
      **Challenge** taunt ability), enrage timer to force pace.
- [ ] Policies gain raid-awareness where needed (defend only when `targets_me`; tank policy
      uses Challenge on aggro loss). Policy RNG stays per-policy `DetRng`, never `state.rng`.
- [ ] `sim/raid_sim.gd` — determinism check (checksum trace ×2), win-rate bands by mixed
      skill tiers, wipe-cause diagnostics (tank_death / heal_fail / enrage / threat_kill).
- [ ] Regression gate re-run: six baseline sims byte-identical.

## R1 — Playable raid: 1 human + 3 AI — **DONE v1 (tank seat, verified 2026-07-02)**

- [x] `CombatController.human_seat_index` — `begin(state, human_index)` picks the human's
      seat; `human()`/`player()` route by it. Default 0 → all five solo HUDs untouched
      (all five UI smokes re-run green).
- [x] `game/raid_hud.gd` + `raid_main.tscn` — THE RIFT: BossSelect (Warden/Juggernaut) →
      live raid combat (Bulwark band + **Challenge rune (T)**, party frames down the left
      with the gold-lit frame = boss's current victim, aggro-lost warning banner, dial
      shows off-target swings as "Swing → Victim", full event juice incl. taunt/threat_drop)
      → end screens. Human tanks; Twinfang/Voidcaller/Mender AI raiders at good-tier
      latency with per-run seeded read-streams.
- [x] Menu: sixth emblem card ("THE RIFT — RAID, FOUR AS ONE"); `--autostart=raid[:aspect]`.
- [x] Verified: `sim/ui_smoke_raid.gd` (all screens + 40s live driven combat + juice) green;
      live WSLg runs clean (raid fight + six-card menu).
- [x] **v2 — pick ANY seat (done, verified 2026-07-02).** The select screen's toggle is
      now the four SEATS (Bulwark/Twinfang/Voidcaller/Mender); each builds its faithful
      class band inside the shared raid grammar: tank = orbs/SpecGauge/Challenge;
      blade = RhythmBar + TwinfangGauge + energy orb (strike rune ignites in the green,
      Flow-loss/rupture/coup pops); caster = PlayerCastBar + VoidcallerGauge + focus orb
      (dial shows the clean-zone KICK window, interrupt/overload/pushback pops);
      healer = full Mender click-cast (hover-target frames + mouse chords via
      MenderBinds + 1-6/Q/E/7, CastChannel, SpecStrip, telegraph damage prediction +
      cast heal-ghost on the frames, mana orb). Aggro banners per seat: tank "CHALLENGE
      IT BACK", dps "IT'S HUNTING YOU", healer none.
      Verified: `sim/ui_smoke_raid.gd` drives live raid in every seat with scripted
      class-correct input + every class juice event; live WSLg runs (blade/healer/caster)
      render clean.
- [x] **v3 — per-seat ASPECT choice (done, verified 2026-07-02).** Seat pick →
      AspectCard ceremony (both Aspects per seat, playstyle blurbs) → pull. All 8
      seat:aspect combos live: Warden/Juggernaut (verb PARRY↔DODGE, Vindicate↔Avalanche),
      Tempo/Venomancer, Disruptor/Silencer, Tidecaller/Brinkwarden (SpecStrip
      RESERVOIR↔NERVE + bloodied counter, signature surge↔laststand). The human's
      aspect overrides only their seat (`RaidContent.make_state` aspects dict); AI
      raiders keep the verified comp. Verified: 8-combo UI smoke (600 ticks live each,
      aspect-correct loadouts) + WSLg runs (juggernaut/tempo/brinkwarden + menu) clean.
      Debug: `--autostart=raid[:seat[:aspect]]` e.g. `raid:blade:tempo`.

## R2 — Netcode — **DONE (verified end-to-end 2026-07-02)**

Everything below was built as designed and proven by `sim/net_smoke.gd` (real server +
two real WebSocket clients in one headless process at 5× timescale): full lobby flow,
a complete 1841-tick fight with **identical checksums on server and both replicas**,
zero desyncs, then a mid-fight hard-disconnect → in-frame AI takeover → clean win at
the server's exact checksum. The HUD gained PLAY ONLINE → connect (remembered in
`user://rift_net.cfg`, `--server=` override) → room lobby (claim/aspect/ready/host
PULL) → combat indistinguishable from offline. Deploy kit in `server/` (one-command
local script; identical docker-compose for desktop → LAN → OVH; wss fronting notes).
Implementation gotchas that are now law: checksums cross the wire AS STRINGS (63-bit
ints don't survive JSON floats); wire actions are pure data (`target_i` seat index,
restored in `RaidNet.step`); never name a Node method `_input(...)` with a custom
signature; set the client phase before sending the join.
Remaining for later: favor-the-presser tick grace, mid-fight join, accounts.

**R2.5 — clients everywhere (done 2026-07-02):** `tools/windows/` ships the native
4.7-stable Windows engine + `play-windows.bat`/`serve-windows.bat` (root). **Cross-OS
lockstep PROVEN** via `sim/net_probe.gd` (scripted online client): Windows client +
Linux client + WSL server, full fight, identical checksum `5135844657370172727` on
all three. **Browser pipeline**: `server/build-web.sh` (WASM export, no-threads →
any static host) + `server/serve-web.py` (COOP/COEP + no-cache) + web client
auto-defaults its server URL to the serving host (ws/wss by page scheme) — send
`http://host:8000`, friend plays, no install. Browser float determinism guarded by
the per-fight checksums (a desync aborts loudly). WSL is NAT-mode: Windows-side
browser/clients use the WSL eth0 IP, not localhost.

### Original design (implemented as written)

**Model: server-paced deterministic lockstep.** The engine is a pure seeded reducer with
tick-stamped inputs and a running checksum — so the server does NOT stream state; it
streams **inputs**. Everyone (server + every client) builds the identical fight from
`(seed, encounter, seat/aspect/ai spec)` and steps the identical `RaidNet.step()`
(policies act → `CombatCore.update`). The server's only authority is the CLOCK and the
INPUT ORDER: it ticks 30 Hz, bundles the inputs that arrived, and broadcasts
`frame {n, inputs}`; clients apply frames in order. AI seats run identically on every
machine (seeded per-run `DetRng` policies — the backfill is free). Bandwidth ≈ 30 tiny
JSON frames/s; the server is thin; combat code online == offline.

- **Transport**: WebSocket (`WebSocketMultiplayerPeer`) — browser WASM + native both work.
  JSON text frames v1 (debuggable; payloads are tiny).
- **Desync defense**: every 30th frame carries `state.checksum`; a client mismatch =
  desync → abort to lobby with a log line (ignored once `state.over` — the last tick can
  legitimately diverge on view-only paths). `is_player` is per-machine (your seat) —
  audited: it feeds only diag/events (not checksummed); `_primary_target` is unreachable
  in raid mode while the fight is live.
- **Input latency** = RTT + one frame (~35-80ms local/EU VPS vs 200-450ms answer windows).
  Favor-the-presser grace (server honoring the client's tick stamp) is a v2 refinement if
  feel demands it — it requires ordered-rewind, incompatible with plain lockstep.
- **Rooms**: join by room code; 4 seats, claim + aspect + ready; first joiner is host and
  presses PULL; unclaimed seats are AI. Fight end → back to lobby, re-pull with a new seed.
- **Disconnect = AI takeover**: the server broadcasts `ai: [seat]` inside a frame; every
  replica attaches the standard seeded policy at the same tick — deterministic, seamless.
  Mid-fight JOIN is v2 (needs full-state serialization; lockstep punts it).
- **Files**: `godot/net/` — `net_protocol.gd` (msg schema/version), `raid_net.gd`
  (shared: spec→state builder + the lockstep `step()` + policy factory),
  `net_server.gd` (rooms/lobby/tick loop; pure Node, embeddable in tests, `time_scale`
  for fast headless soak), `server_main.gd` (headless entry:
  `godot --headless --path godot --script res://net/server_main.gd -- --port=9077`),
  `net_client.gd` (connection + lobby), `net_combat_controller.gd` (extends
  CombatController: same `state`/`human()`/`player()` surface, frame-driven — the HUD
  can't tell it from the offline one).
- **Verification**: `sim/net_smoke.gd` — ONE headless process runs the real server +
  two real WebSocket clients over loopback at 4× time-scale: lobby → claim/aspects →
  full fight with scripted human tank+healer → assert zero desyncs + all three
  checksums agree + same outcome; then a disconnect mid-fight → AI takeover → clean
  finish. Plus live: local server + two WSLg windows.
- **Deploy story (the "easy OVH swap")**: `server/` at repo root — `Dockerfile`
  (official Godot headless + the project), `docker-compose.yml`, `serve-local.sh`
  (no Docker, runs your installed godot), README with the three moves: local box →
  LAN → any VPS (`scp` the folder, `docker compose up -d`, point the client's server
  field at it). `wss://` for browser builds via Cloudflare Tunnel or Caddy in front —
  compose has a commented tunnel service. Client remembers the last server URL in
  `user://rift_net.cfg`; `--server=ws://...` overrides.
- Anti-flail: server drops inputs from seatless peers, clamps to 1 input/seat/tick,
  protocol version handshake rejects mismatched builds.

## R3 — Raid content + raid economy

**First tranche LANDED (branch `raid-seals`, 2026-07-02): the Machine Seals** — see
MASTER-PLAN §RAID SEALS. Three new raid bosses (MISTRAL-7B easy / GEMINI ULTRA mid /
CLAUDE MYTHOS finale) on three guarded engine additions:
- **Add waves** (`AddRes` + `EncounterRes.adds`, `BossState.add_i/add_hp`): the boss
  withdraws between swings; damage routes to the add; main timers freeze; `HEAL_BOSS`
  still heals the withdrawn main body (the Opus medic add). Checksum gains `+add_hp`
  (0 solo → byte-identical).
- **Cast chains** (`AbilityRes.chain`): the next verse starts on resolve OR kick — a kick
  skips ONE verse; a live silence kills the litany. This delivers the "kick rotation"
  R3 line from the OTHER side: one kicker (cd 5s) cannot cover a 3×2s-verse chain — the
  Twinfang's kick must join.
- **Random personal beats** (`StrikeRes.rand_target`): victims rolled at cast start,
  healer included (pierces untargetability); only the victim can answer.
Boss picks flow through the fight spec (`enc`) + a lobby host toggle (protocol v2).
Verified: `sim/raid_probe.gd` (mechanics), `sim/raid_sim.gd` all four Seals
(per-Seal determinism PASS, riftmaw checksums unchanged), regression gate, all smokes.
NOTE for raid-healer design: in RAID the Mender's own frame joins its triage list
(threat_enabled-guarded) — the AI healer self-heals, matching the human HUD.

Still open for later R3:
- Ensemble bosses that REQUIRE the trinity: tank-swap taunt mechanics (needs 2-tank comps),
  healer dispels mid-telegraph, feints aimed at a random non-tank, marks that must be
  bloomed/warded pre-emptively.
- ~~**Riftcores**: raid-only material, deterministic drop per raid boss kill; required for
  Sigil T3 and the sealed Ledger page. Solo trials farm essences; raids prove loadouts.~~
  *(SUPERSEDED 2026-07-03 by `PROGRESSION-PLAN.md` — materials CUT; raids own exclusive
  loot tables + Seal-gated feat rows instead. "The sealed Ledger page" survives as the raid
  capstone collectible in the Ledger.)*
- Difficulty tiers = Depth applied to raids; higher Depth → richer drop-rarity weights and
  Depth-gated table rows (per `PROGRESSION-PLAN.md` RANK track), not materials.

## Known future work (tracked, not R0)

- Per-ward absorb ownership (two shield-source classes stacking on one target).
- Healer targetability / healer aggro as a raid-realism knob.
- Boss scheduler still resolves one telegraph per tick (inherited, faithful) — raid bosses
  with parallel pressure should use strike-strings/AoE + melee chip, not parallel telegraphs.
- `BossState.exposed` is single-player-framed; raid Expose should become per-seat or
  boss-global explicitly.
- Kit-side event emissions gain seat ids opportunistically (needed fully by R1 HUD).

## Status

- **R0 — DONE (engine + first raid boss, verified 2026-07-02).**
  - **Regression gate PASS:** all six solo sims (m0/bulwark/mender/twinfang/voidcaller/
    bloomweaver, 300–400 seeds) byte-identical original-engine vs R0-engine, proven in
    two frozen project snapshots (only diff: each sim printing its own CSV path). The
    old mender ObjectDB leak-risk from Seat↔Seat refs avoided by index-based ownership.
  - **300-seed raid verification:** determinism PASS; bands expert/good/sloppy =
    100/100/97% (sloppy losses = tank_death ×9); TTK 55/60/73s vs enrage 75;
    taunts 1.4–2.0/run (every Baleful Curse answered); threat gate probe: taunt OFF →
    0.30 dps deaths/run vs 0.00 ON.
  - Engine (all guarded, index-based — no Seat↔Seat refs, no RefCounted cycles):
    threat table/taunt on `BossState` (`threat`, `taunt_seat_i`), `CombatCore.taunt()`,
    `_threat_target()` (taunt override → highest threat → deterministic tie-break),
    accrual in `damage_boss` (tank ×`threat_tank_mult`)/`heal_unit`/group damage;
    `Effect.THREAT_DROP`; absorb `absorb_owner_i` + HoT `caster_i` credit routing;
    role-extinction raid loss; per-seat `seat.diag`; events carry `seat`;
    `observe()` gains `aggro_me` under threat. Bulwark gains **Challenge** (off-GCD
    taunt, raid-only, `challenge_cd 8`); `RaidTankPolicy` presses it on aggro loss.
  - Content: `data/raid/raid_content.gd` — **Vorathek, the Riftmaw** (13500 HP,
    enrage 75s, melee 30–42@1.1s, Crush/Talon parry exam, Devouring Chant 450 kick
    exam, Cataclysm + Riftrot + Void Volley healer exams, Baleful Curse threat-drop
    taunt exam). Party: Bulwark(warden) + Twinfang(venomancer) + Voidcaller(disruptor)
    + Mender(tidecaller), ALL full-fidelity, one CombatState.
  - Verified (40-seed dev pass; 300-seed run pending): determinism PASS with four
    mixed-class full-fidelity seats + threat live; bands 100/100/92.5 (sloppy loses
    via tank_death); taunts ~1.4–2.0/run answering every Curse; threat gate probe:
    taunt OFF → 0.35 dps deaths/run vs 0.00 ON.
  - Findings: (1) two kickers (Twinfang kick + Voidcaller interrupt) lock out any
    single interruptible cast under the one-telegraph scheduler — boss-healed stays 0
    at every tier; interrupt pressure in raids needs parallel cast sources or comp
    limits (R3 design note). (2) A concurrent work session retuning solo content
    mid-regression produced false regression diffs — byte-identical gates must run
    against a FROZEN project snapshot (copy `godot/` to a scratch dir, run both
    engine states there).
